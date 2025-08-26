#!/usr/bin/env python3
import argparse
import base64
import datetime as dt
import io
import json
import os
import re
import shutil
import sys
import tempfile
import urllib.request
import urllib.error
import uuid
import zipfile
from pathlib import Path

# ---------- Netlify name sanitizer ----------

def sanitize_netlify_name(name: str) -> str:
    """
    Produce a Netlify-safe subdomain from a repo or site name.
    Lowercase, convert spaces/underscores to hyphens, and strip invalid chars.
    """
    name = name.lower().replace(" ", "-").replace("_", "-")
    name = re.sub(r"[^a-z0-9-]", "-", name)
    # collapse repeated dashes and strip from ends
    name = re.sub(r"-{2,}", "-", name).strip("-")
    return name or "site"

# ---------- Teacher profile (unchanged) ----------

GLOBAL_SECRETS_ROOT = Path("/teaching/courses/_secrets")

def _profile_path() -> Path:
    return GLOBAL_SECRETS_ROOT / "profile.json"

def _ensure_global_secrets_dir():
    GLOBAL_SECRETS_ROOT.mkdir(parents=True, exist_ok=True)
    try:
        os.chmod(GLOBAL_SECRETS_ROOT, 0o700)
    except Exception:
        pass

def sanitize_last_name(name: str) -> str:
    """Lowercase and keep letters only; e.g., 'Mc-Donald ' -> 'mcdonald'."""
    return re.sub(r"[^a-z]", "", name.strip().lower())

def load_teacher_last_name() -> str | None:
    path = _profile_path()
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        ln = (data or {}).get("teacher_last_name")
        if ln:
            return sanitize_last_name(ln)
    except Exception:
        return None
    return None

def save_teacher_last_name(last_name: str):
    _ensure_global_secrets_dir()
    data = {"teacher_last_name": sanitize_last_name(last_name)}
    path = _profile_path()
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")
    try:
        os.chmod(path, 0o600)
    except Exception:
        pass

def get_or_prompt_teacher_last_name() -> str:
    ln = load_teacher_last_name()
    if ln:
        return ln
    # First run under this /teaching/courses folder
    raw = input("👋 First time setup: What is your last name? (letters only) ").strip()
    ln = sanitize_last_name(raw)
    while not ln:
        raw = input("Please enter letters only for your last name (e.g., 'Gordon'): ").strip()
        ln = sanitize_last_name(raw)
    save_teacher_last_name(ln)
    print(f"📝 Saved teacher last name for future deploys: {ln}")
    return ln

# ---------- Timezone helpers ----------

def parse_host_tz() -> dt.tzinfo:
    """
    Parse HOST_TZ_OFFSET from env in ±HHMM form (e.g., -0400, +0530).
    Fallback: system local timezone (as a last resort UTC if unknown).
    """
    raw = os.getenv("HOST_TZ_OFFSET", "").strip()
    if re.fullmatch(r"[+-]\d{4}", raw):
        sign = 1 if raw[0] == "+" else -1
        hours = int(raw[1:3])
        minutes = int(raw[3:5])
        offset = dt.timedelta(hours=sign * hours, minutes=sign * minutes)
        return dt.timezone(offset)
    try:
        return dt.datetime.now().astimezone().tzinfo or dt.timezone.utc
    except Exception:
        return dt.timezone.utc

TZ = parse_host_tz()
NOW = dt.datetime.now(TZ)

def prompt(text: str, default: str | None = None) -> str:
    if default is not None and default != "":
        resp = input(f"{text} [{default}]: ").strip()
        return resp or default
    return input(f"{text}: ").strip()

# =========================================================
#            GLOBAL token storage (obfuscated)
#   Location: /teaching/courses/_secrets/{.key,tokens.json}
# =========================================================

def _global_secrets_paths() -> tuple[Path, Path]:
    """
    Returns (key_path, tokens_path) under the global secrets root.
    """
    key_path = GLOBAL_SECRETS_ROOT / ".key"
    tokens_path = GLOBAL_SECRETS_ROOT / "tokens.json"
    return key_path, tokens_path

def _load_or_create_key_global() -> bytes:
    key_path, _ = _global_secrets_paths()
    if key_path.exists():
        k = key_path.read_bytes()
        if k:
            return k
    _ensure_global_secrets_dir()
    k = os.urandom(32)
    key_path.write_bytes(k)
    try:
        os.chmod(key_path, 0o600)
    except Exception:
        pass
    return k

def _xor(data: bytes, key: bytes) -> bytes:
    return bytes([b ^ key[i % len(key)] for i, b in enumerate(data)])

def _save_token_global(label: str, token: str):
    _ensure_global_secrets_dir()
    key = _load_or_create_key_global()
    _, tokens_path = _global_secrets_paths()
    obf = base64.b64encode(_xor(token.encode("utf-8"), key)).decode("ascii")
    data = {}
    if tokens_path.exists():
        try:
            data = json.loads(tokens_path.read_text(encoding="utf-8"))
        except Exception:
            data = {}
    if "tokens" not in data:
        data["tokens"] = {}
    data["tokens"][label] = {
        "obf": obf,
        "ts": NOW.isoformat(timespec="seconds"),
        "scope": "global",
        "note": "xor+base64 obfuscated"
    }
    tokens_path.write_text(json.dumps(data, indent=2), encoding="utf-8")
    try:
        os.chmod(tokens_path, 0o600)
    except Exception:
        pass

def _load_token_global(label: str) -> str | None:
    key_path, tokens_path = _global_secrets_paths()
    if not tokens_path.exists() or not key_path.exists():
        return None
    try:
        data = json.loads(tokens_path.read_text(encoding="utf-8"))
        entry = (data.get("tokens") or {}).get(label)
        if not entry:
            return None
        obf_b = base64.b64decode(entry["obf"])
        key = key_path.read_bytes()
        return _xor(obf_b, key).decode("utf-8")
    except Exception:
        return None

# --------- Back-compat: per-course token support (migrate) ---------

def _course_secrets_paths(course_dir: Path) -> tuple[Path, Path, Path]:
    secrets_dir = course_dir / ".secrets"
    key_path = secrets_dir / ".key"
    tokens_path = secrets_dir / "tokens.json"
    return secrets_dir, key_path, tokens_path

def _load_token_course(course_dir: Path, label: str) -> str | None:
    secrets_dir, key_path, tokens_path = _course_secrets_paths(course_dir)
    if not tokens_path.exists() or not key_path.exists():
        return None
    try:
        data = json.loads(tokens_path.read_text(encoding="utf-8"))
        entry = (data.get("tokens") or {}).get(label)
        if not entry:
            return None
        obf_b = base64.b64decode(entry["obf"])
        key = key_path.read_bytes()
        return _xor(obf_b, key).decode("utf-8")
    except Exception:
        return None

def _maybe_migrate_course_tokens_to_global(course_dir: Path):
    """
    If old per-course tokens exist and no global token yet, copy them into global store.
    """
    migrated = []
    for label in ("github", "netlify"):
        if _load_token_global(label) is None:
            t = _load_token_course(course_dir, label)
            if t:
                _save_token_global(label, t)
                migrated.append(label)
    if migrated:
        print(f"🔁 Migrated per-course tokens to global store: {', '.join(migrated)}")

# ---------- Netlify helpers ----------

def read_netlify_token_secure() -> str:
    import getpass
    print("\n🔐 A Netlify Personal Access Token is required.")
    print("   Where to create it:")
    print("   • Netlify → User settings → Applications → Personal access tokens → New access token")
    print("   • Recommended: set **No expiration** so you won’t be prompted again across courses/years.")
    return getpass.getpass("NETLIFY_PERSONAL_ACCESS_TOKEN (hidden as you type): ").strip()

def netlify_api(method: str, path: str, token: str, payload: dict | None = None, headers: dict | None = None, data: bytes | None = None) -> dict:
    base = "https://api.netlify.com/api/v1"
    url = f"{base}{path}"
    req = urllib.request.Request(url, method=method)
    req.add_header("Accept", "application/json")
    req.add_header("Authorization", f"Bearer {token}")
    if headers:
        for k, v in headers.items():
            req.add_header(k, v)
    body = None
    if data is not None:
        body = data
    elif payload is not None:
        body = json.dumps(payload).encode("utf-8")
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, data=body) as resp:
            raw = resp.read()
            if not raw:
                return {}
            return json.loads(raw.decode("utf-8"))
    except urllib.error.HTTPError as e:
        msg = e.read().decode("utf-8", errors="ignore")
        raise RuntimeError(f"Netlify API error {e.code}: {msg}") from e

def _extract_json_from_error(err: Exception) -> dict | None:
    s = str(err).strip()
    idx = s.rfind("{")
    if idx == -1:
        return None
    candidate = s[idx:]
    try:
        return json.loads(candidate)
    except Exception:
        return None

def _is_netlify_name_conflict(err: Exception) -> bool:
    s = str(err).lower()
    if "422" in s and ("unique" in s or "already" in s or "taken" in s or "exists" in s):
        return True
    data = _extract_json_from_error(err)
    if isinstance(data, dict):
        errs = data.get("errors")
        if isinstance(errs, dict):
            for _, messages in errs.items():
                if isinstance(messages, list):
                    for m in messages:
                        lm = (m or "").lower()
                        if any(x in lm for x in ["unique", "already", "taken", "exists"]):
                            return True
    return False

def suggest_site_base(course_code: str, section: str, teacher_last_name: str) -> str:
    """
    Example: ICD2O + 1 + gordon -> icd2o-s1-2025-gordon
    """
    course = (course_code or "").lower()
    sec = f"s{section}"
    base = f"{course}-{sec}-{NOW.year}-{teacher_last_name}"
    return sanitize_netlify_name(base)

def maybe_create_netlify_site_simple(token: str,
                                     team_slug: str | None,
                                     course_code: str | None,
                                     section: str | None,
                                     teacher_last_name: str | None) -> dict:
    """
    Create a Netlify site WITHOUT linking to a Git provider.
    POST /api/v1/sites  (or /api/v1/accounts/{team_slug}/sites)
    If the chosen name is taken, prompt for a different one.
    """
    if teacher_last_name and course_code and section:
        base = suggest_site_base(course_code, section, teacher_last_name)
    else:
        base = sanitize_netlify_name(f"{course_code or 'course'}-s{section or '1'}-{NOW.year}")

    site_name = prompt("Enter Netlify site name", default=base).strip() or base
    path = f"/accounts/{team_slug}/sites" if team_slug else "/sites"

    attempt = 0
    while True:
        payload = {
            "name": site_name,
            # Optional metadata fields supported by docs/guides
            "created_via": "Dockerized Quartz for Teachers",
        }
        try:
            site = netlify_api("POST", path, token, payload)
            return site
        except RuntimeError as e:
            if _is_netlify_name_conflict(e):
                attempt += 1
                suggestion = f"{base}-{attempt:02d}"
                print(f"⚠️  Netlify site name '{site_name}' is not available (already in use).")
                print("    Tip: names must be globally unique across Netlify and use letters, numbers, and hyphens.")
                new_name = prompt("Choose a different Netlify site name (or 'q' to cancel)", default=suggestion).strip()
                if new_name.lower() in {"q", "quit", "exit"}:
                    raise RuntimeError("User cancelled Netlify site creation after name conflict.") from e
                site_name = sanitize_netlify_name(new_name) or suggestion
                continue
            raise

def load_netlify_marker(section_dir: Path) -> dict | None:
    marker = section_dir / ".netlify_site.json"
    if marker.exists():
        try:
            return json.loads(marker.read_text(encoding="utf-8"))
        except Exception:
            return None
    return None

def save_netlify_marker(section_dir: Path, site_obj: dict):
    marker = section_dir / ".netlify_site.json"
    keep = {
        "id": site_obj.get("id"),
        "name": site_obj.get("name"),
        "url": site_obj.get("ssl_url") or site_obj.get("url"),
        "admin_url": site_obj.get("admin_url"),
    }
    marker.write_text(json.dumps(keep, indent=2), encoding="utf-8")

# ---------- Build API: zip + upload to production ----------

def _zip_folder_to_bytes(root: Path) -> bytes:
    """
    Zip contents of 'root' so that files sit at archive top-level.
    Returns zip file bytes.
    """
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for p in sorted(root.rglob("*")):
            if p.is_file():
                arcname = str(p.relative_to(root)).replace("\\", "/")
                zf.write(p, arcname)
    return buf.getvalue()

def _encode_multipart(fields: dict[str, str], files: dict[str, tuple[str, bytes, str]]) -> tuple[bytes, str]:
    """
    Build a multipart/form-data payload.
    files: { field_name: (filename, bytes, content_type) }
    Returns (body_bytes, content_type_header_value).
    """
    boundary = "----NetlifyBoundary" + uuid.uuid4().hex
    CRLF = b"\r\n"
    body = io.BytesIO()

    for name, value in fields.items():
        body.write(b"--" + boundary.encode("ascii") + CRLF)
        body.write(f'Content-Disposition: form-data; name="{name}"'.encode("utf-8") + CRLF)
        body.write(b"" + CRLF)
        body.write(value.encode("utf-8") + CRLF)

    for name, (filename, file_bytes, content_type) in files.items():
        body.write(b"--" + boundary.encode("ascii") + CRLF)
        disp = f'Content-Disposition: form-data; name="{name}"; filename="{filename}"'
        body.write(disp.encode("utf-8") + CRLF)
        body.write(f"Content-Type: {content_type}".encode("utf-8") + CRLF)
        body.write(b"" + CRLF)
        body.write(file_bytes + CRLF)

    body.write(b"--" + boundary.encode("ascii") + b"--" + CRLF)
    content_type = f"multipart/form-data; boundary={boundary}"
    return body.getvalue(), content_type

def upload_zip_build_to_netlify(site_id: str, token: str, zip_bytes: bytes, title: str | None = None) -> dict:
    """
    POST /api/v1/sites/<site_id>/builds with multipart fields:
      - title (optional)
      - zip (application/zip)
    This triggers a production deploy. (Netlify Build API guide)
    """
    fields = {}
    if title:
        fields["title"] = title
    files = {"zip": ("site.zip", zip_bytes, "application/zip")}
    body, content_type = _encode_multipart(fields, files)
    headers = {"Content-Type": content_type}
    return netlify_api("POST", f"/sites/{site_id}/builds", token, headers=headers, data=body)

# ---------- Main ----------

def main():
    p = argparse.ArgumentParser(description="Deploy a built section site directly to Netlify (no GitHub required).")
    p.add_argument("--course", required=True, help="Course code, e.g., ICS3U")
    p.add_argument("--section", required=True, help="Section number, e.g., 1")
    args = p.parse_args()

    # Path: /teaching/courses/<COURSE>/.merged_output/section<NUM>
    section_dir = Path(f"/teaching/courses/{args.course}/.merged_output/section{args.section}").resolve()
    if not section_dir.exists():
        print(f"❌ Section directory not found: {section_dir}")
        print(f"👉 Please run the preview/build first:")
        print(f"   ./preview.sh {args.course} {args.section}")
        sys.exit(1)

    # Require the built site (public/)
    public_dir = section_dir / "public"
    if not public_dir.exists() or not any(public_dir.iterdir()):
        print(f"❌ Built site not found at: {public_dir}")
        print(f"👉 Please build before deploying. For example:")
        print(f"   ./preview.sh {args.course} {args.section} --build")
        sys.exit(1)

    # Determine course dir (for back-compat token migration)
    course_dir = section_dir.parent.parent  # .../<COURSE>/.merged_output/section#
    _maybe_migrate_course_tokens_to_global(course_dir)

    # Capture teacher last name for naming
    try:
        teacher_last_name = get_or_prompt_teacher_last_name()
    except Exception:
        teacher_last_name = None

    print(f"📁 Deploying from local build: {public_dir}")
    print(f"🕒 Timestamp TZ offset: {NOW.strftime('%z')}")

    # Load or prompt for Netlify token (GLOBAL)
    netlify_token = _load_token_global("netlify")
    if netlify_token:
        print("🔐 Using saved Netlify token (global).")
    else:
        netlify_token = read_netlify_token_secure()
        if not netlify_token:
            print("❌ No token provided.")
            sys.exit(1)
        _save_token_global("netlify", netlify_token)
        print("💾 Saved Netlify token for future deploys (GLOBAL for all courses).")

    # Discover or create the Netlify site (no repo link)
    site_marker = load_netlify_marker(section_dir)
    if site_marker:
        site_id = site_marker.get("id")
        site_url = site_marker.get("url") or site_marker.get("admin_url")
        print("🌐 Using existing Netlify site for this section.")
        if site_url:
            print(f"   Site: {site_url}")
    else:
        team_slug = prompt("Netlify Team slug (optional; Enter to use your personal team)", default="").strip() or None
        try:
            site = maybe_create_netlify_site_simple(
                token=netlify_token,
                team_slug=team_slug,
                course_code=args.course,
                section=str(args.section),
                teacher_last_name=teacher_last_name
            )
            save_netlify_marker(section_dir, site)
            site_id = site.get("id")
            site_url = site.get("ssl_url") or site.get("url")
            admin_url = site.get("admin_url")
            print("🎉 Netlify site created.")
            if site_url:
                print(f"   Live URL: {site_url}")
            if admin_url:
                print(f"   Admin:    {admin_url}")
        except Exception as e:
            print("❌ Failed to create Netlify site.")
            print(f"   Details: {e}")
            sys.exit(1)

    if not site_id:
        print("❌ Could not determine Netlify site ID.")
        sys.exit(1)

    # Zip the built site and upload via Build API
    print("📦 Zipping built site (public/)...")
    zip_bytes = _zip_folder_to_bytes(public_dir)
    title = f"{args.course}-S{args.section} deploy {NOW.strftime('%Y-%m-%d %H:%M:%S %z')}"

    print("⬆️  Uploading zip to Netlify Build API (production deploy)...")
    try:
        deploy_resp = upload_zip_build_to_netlify(site_id, netlify_token, zip_bytes, title=title)
        # deploy_resp often includes deploy/build metadata; show a friendly summary
        dep_url = (deploy_resp or {}).get("deploy_ssl_url") or (deploy_resp or {}).get("deploy_url") or site_url
        state = (deploy_resp or {}).get("state")
        deploy_id = (deploy_resp or {}).get("id") or (deploy_resp or {}).get("deploy_id")
        print("✅ Deploy request accepted by Netlify.")
        if deploy_id:
            print(f"   Deploy ID: {deploy_id}")
        if state:
            print(f"   State:     {state}")
        if dep_url:
            print(f"   Live URL:  {dep_url}")
        else:
            print(f"   Site URL:  {site_url}")
    except Exception as e:
        print("❌ Deploy failed.")
        print(f"   Details: {e}")
        print("   Tip: Ensure your token has access to the chosen team/site, and that 'public/' contains your built site.")
        sys.exit(1)

    print("\n✅ Deploy complete.")

if __name__ == "__main__":
    main()
