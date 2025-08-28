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
import urllib.parse
import hashlib
import unicodedata
from pathlib import Path
from collections import Counter

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

COURSES_ROOT = Path("/teaching/courses")
# New, hidden, less enticing global secrets root
GLOBAL_SECRETS_ROOT = COURSES_ROOT / ".internal"
# Legacy path (for migration)
OLD_GLOBAL_SECRETS_ROOT = COURSES_ROOT / "_secrets"

def _profile_path() -> Path:
    return GLOBAL_SECRETS_ROOT / "profile.json"

def _ensure_courses_gitignore():
    """
    Ensure /teaching/courses/.gitignore exists and ignores:
      - /.internal/ (new hidden store)
      - /_backups/  (backups should never be committed)
    Idempotent: only adds missing lines.
    """
    try:
        COURSES_ROOT.mkdir(parents=True, exist_ok=True)
        gi_path = COURSES_ROOT / ".gitignore"
        to_add = [
            "# Dockerized Quartz for Teachers (auto-ignore)",
            "/.internal/",
            "/_backups/",
            "",  # trailing newline
        ]
        existing = []
        if gi_path.exists():
            try:
                existing = gi_path.read_text(encoding="utf-8").splitlines()
            except Exception:
                existing = []
        # Build new content preserving existing lines
        new_lines = existing[:]
        def ensure(line: str):
            if line not in new_lines:
                new_lines.append(line)
        for line in to_add:
            ensure(line)
        gi_path.write_text("\n".join(new_lines) + ("\n" if not new_lines or new_lines[-1] != "" else ""), encoding="utf-8")
    except Exception:
        # Non-fatal: continue silently if we cannot write .gitignore
        pass

def _ensure_global_secrets_dir():
    _ensure_courses_gitignore()
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
    raw = input("👋 First time setup... what is your last name? (letters only): ").strip()
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
#   GLOBAL token storage (obfuscated, hidden dotfolder)
#   Location: /teaching/courses/.internal/{.key,tokens.json}
#   (migrates from legacy /teaching/courses/_secrets)
# =========================================================

def _global_secrets_paths() -> tuple[Path, Path]:
    """
    Returns (key_path, tokens_path) under the global secrets root.
    """
    key_path = GLOBAL_SECRETS_ROOT / ".key"
    tokens_path = GLOBAL_SECRETS_ROOT / "tokens.json"
    return key_path, tokens_path

def _legacy_global_secrets_paths() -> tuple[Path, Path]:
    """
    Legacy: /teaching/courses/_secrets
    """
    key_path = OLD_GLOBAL_SECRETS_ROOT / ".key"
    tokens_path = OLD_GLOBAL_SECRETS_ROOT / "tokens.json"
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
    # NOTE: omit "note" field entirely
    data["tokens"][label] = {
        "obf": obf,
        "ts": NOW.isoformat(timespec="seconds"),
        "scope": "global"
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

def _maybe_migrate_global_from_legacy():
    """
    If legacy global secrets exist at /teaching/courses/_secrets and the new hidden
    store doesn't yet have content, migrate tokens (re-obfuscating without 'note')
    and copy the teacher profile. Then delete the legacy folder.
    """
    _ensure_courses_gitignore()
    old_key_path, old_tokens_path = _legacy_global_secrets_paths()
    new_key_path, new_tokens_path = _global_secrets_paths()

    migrated_any = False

    # Migrate teacher profile.json if present and missing in new store
    try:
        old_profile = OLD_GLOBAL_SECRETS_ROOT / "profile.json"
        new_profile = GLOBAL_SECRETS_ROOT / "profile.json"
        if old_profile.exists() and not new_profile.exists():
            _ensure_global_secrets_dir()
            new_profile.write_text(old_profile.read_text(encoding="utf-8"), encoding="utf-8")
            try:
                os.chmod(new_profile, 0o600)
            except Exception:
                pass
            migrated_any = True
    except Exception:
        pass

    # Migrate tokens by *decoding* with old key and *re-saving* with new key (no 'note')
    try:
        if old_key_path.exists() and old_tokens_path.exists():
            with old_tokens_path.open("r", encoding="utf-8") as f:
                old_data = json.load(f)
            old_key = old_key_path.read_bytes()
            old_tokens = (old_data.get("tokens") or {})
            for label, entry in old_tokens.items():
                try:
                    obf_b = base64.b64decode(entry.get("obf", ""))
                    token_plain = _xor(obf_b, old_key).decode("utf-8")
                    # Save into new store if missing
                    if _load_token_global(label) is None:
                        _save_token_global(label, token_plain)
                        migrated_any = True
                except Exception:
                    continue
    except Exception:
        pass

    # Remove legacy folder if it exists
    removed_legacy = False
    try:
        if OLD_GLOBAL_SECRETS_ROOT.exists():
            shutil.rmtree(OLD_GLOBAL_SECRETS_ROOT)
            removed_legacy = True
    except Exception as e:
        print(f"ℹ️ Couldn't remove legacy /_secrets: {e}")

    if migrated_any or removed_legacy:
        if removed_legacy:
            print("🔁 Migrated global secrets to hidden store at /.internal and removed legacy /_secrets folder.")
        else:
            print("🔁 Migrated global secrets to hidden store at /.internal.")

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
    if "422" in s and ("unique" in s or "already" in s or "taken" in s or "exists"):

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

# ---------- Stable site marker (new) + migration from legacy ----------

def _stable_marker_dir(course_dir: Path) -> Path:
    return course_dir / ".netlify_sites"

def _stable_marker_path(course_dir: Path, section: str | int) -> Path:
    return _stable_marker_dir(course_dir) / f"section{section}.json"

def _legacy_marker_path(section_dir: Path) -> Path:
    return section_dir / ".netlify_site.json"

def load_netlify_marker(course_dir: Path, section_dir: Path, section: str | int) -> dict | None:
    """
    Prefer stable marker at <COURSE>/.netlify_sites/section<N>.json.
    If not found, migrate legacy marker from <SECTION_DIR>/.netlify_site.json.
    """
    # Try stable path
    stable_path = _stable_marker_path(course_dir, section)
    if stable_path.exists():
        try:
            return json.loads(stable_path.read_text(encoding="utf-8"))
        except Exception:
            pass

    # Migrate legacy marker if present
    legacy = _legacy_marker_path(section_dir)
    if legacy.exists():
        try:
            data = json.loads(legacy.read_text(encoding="utf-8"))
        except Exception:
            data = None
        if isinstance(data, dict):
            save_netlify_marker(course_dir, section, data)
            try:
                legacy.unlink()
                print("🔁 Migrated Netlify site marker to stable location and removed legacy file.")
            except Exception:
                print("ℹ️ Migrated Netlify site marker; couldn't remove legacy file.")
            return data

    return None

def save_netlify_marker(course_dir: Path, section: str | int, site_obj: dict):
    _stable_marker_dir(course_dir).mkdir(parents=True, exist_ok=True)
    keep = {
        "id": site_obj.get("id"),
        "name": site_obj.get("name"),
        "url": site_obj.get("ssl_url") or site_obj.get("url"),
        "admin_url": site_obj.get("admin_url"),
    }
    _stable_marker_path(course_dir, section).write_text(json.dumps(keep, indent=2), encoding="utf-8")

# ---------- Shared path filters ----------

_IGNORED_BASENAMES = {".DS_Store", "Thumbs.db"}

def _normalize_rel(rel: str) -> str:
    # Normalize to NFC, ensure POSIX separators
    rel = rel.replace("\\", "/")
    rel = unicodedata.normalize("NFC", rel)
    return rel

def _should_skip_rel(rel: str) -> bool:
    # Skip macOS AppleDouble files and .git artifacts and control chars in paths
    parts = rel.split("/")
    if any(part.startswith("._") for part in parts):
        return True
    if parts and parts[0].startswith(".git"):
        return True
    if parts and parts[-1] in _IGNORED_BASENAMES:
        return True
    if any(ord(c) < 32 for c in rel):  # control chars
        return True
    return False

# ---------- Delta deploy (file digest API) ----------

def _sha1_file(path: Path, chunk_size: int = 1024 * 1024) -> str:
    h = hashlib.sha1()
    with path.open("rb") as f:
        while True:
            b = f.read(chunk_size)
            if not b:
                break
            h.update(b)
    return h.hexdigest()

def _build_files_manifest(root: Path):
    """
    Build:
      - files_map:  { "/remote/path": "sha1hex", ... }
      - sha_to_pairs: { "sha1hex": [ ("/remote/path", "local/rel"), ... ] }
    Remote paths are NFC-normalized and start with "/".
    """
    files_map: dict[str, str] = {}
    sha_to_pairs: dict[str, list[tuple[str, str]]] = {}
    for p in sorted(root.rglob("*")):
        if not p.is_file():
            continue
        local_rel = str(p.relative_to(root))
        local_rel = _normalize_rel(local_rel)
        if _should_skip_rel(local_rel):
            continue
        remote_key = "/" + local_rel  # Netlify expects leading slash
        sha = _sha1_file(p)
        files_map[remote_key] = sha
        sha_to_pairs.setdefault(sha, []).append((remote_key, local_rel))
    return files_map, sha_to_pairs

def create_delta_deploy(site_id: str, token: str, root: Path, draft: bool = False, async_req: bool = False) -> dict:
    """
    Step 1: POST /sites/{site_id}/deploys with manifest {"files":{...}, "draft":bool?, "async":bool?}
    Returns deploy object: includes "id" and "required".
    """
    files_map, sha_to_pairs = _build_files_manifest(root)
    payload = {"files": files_map}
    if draft:
        payload["draft"] = True
    if async_req:
        payload["async"] = True
    deploy = netlify_api("POST", f"/sites/{site_id}/deploys", token, payload=payload)
    deploy["_sha_to_pairs"] = sha_to_pairs  # carry through for upload/diagnostics
    return deploy

def _upload_required_files(deploy_id: str, token: str, root: Path, required_shas: list[str], sha_to_pairs: dict[str, list[tuple[str, str]]]):
    """
    Step 2: PUT each required file to /deploys/{deploy_id}/files/<remote/path>
    Only one path per required digest is necessary.
    """
    if not required_shas:
        print("📦 No file uploads needed (all content already present on Netlify).")
        return

    uploaded = 0
    for sha in required_shas:
        pairs = sha_to_pairs.get(sha) or []
        if not pairs:
            print(f"⚠️  Netlify requested unknown digest {sha[:8]}…; skipping.")
            continue
        remote_path, local_rel = pairs[0]
        local_file = root / local_rel
        if not local_file.exists():
            print(f"⚠️  Missing local file for {remote_path}; skipping.")
            continue

        # Encode remote path for URL; escape reserved chars safely
        encoded_path = urllib.parse.quote(remote_path.lstrip("/"), safe="/")
        with local_file.open("rb") as f:
            data = f.read()
        headers = {"Content-Type": "application/octet-stream"}
        netlify_api("PUT", f"/deploys/{deploy_id}/files/{encoded_path}", token, headers=headers, data=data)
        uploaded += 1
        if uploaded % 25 == 0:
            print(f"   …uploaded {uploaded}/{len(required_shas)} required files")

    print(f"⬆️  Uploaded {uploaded} file(s) required by Netlify.")

# ---------- Diagnostics (new) ----------

_IMG_EXT = {"jpg","jpeg","png","gif","webp","svg","bmp","tiff","ico","avif"}
_FONT_EXT = {"woff","woff2","ttf","otf","eot"}
_SCRIPT_EXT = {"js","mjs"}
_STYLE_EXT = {"css"}
_HTML_EXT = {"html","htm"}
_DATA_EXT = {"json","xml","txt","map","csv"}
_MEDIA_EXT = {"mp4","mp3","wav","ogg","webm","m4a"}

def _category_for(rel: str) -> str:
    ext = rel.rsplit(".", 1)[-1].lower() if "." in rel else ""
    if ext in _IMG_EXT: return "images"
    if ext in _FONT_EXT: return "fonts"
    if ext in _SCRIPT_EXT: return "scripts"
    if ext in _STYLE_EXT: return "styles"
    if ext in _HTML_EXT: return "html"
    if ext in _DATA_EXT: return "data"
    if ext in _MEDIA_EXT: return "media"
    return "other"

def print_required_diagnostics(required_shas: list[str], sha_to_pairs: dict[str, list[tuple[str, str]]], public_dir: Path):
    """
    Summarize and persist the 'required' list from Netlify.
    Writes full, ordered list to: public/_required_last_deploy.txt
    """
    items: list[tuple[str,str,str]] = []  # (sha, remote_path, local_rel)
    for sha in required_shas:
        pairs = sha_to_pairs.get(sha) or []
        if not pairs:  # shouldn't happen
            items.append((sha, "<unknown>", "<unknown>"))
        else:
            items.append((sha, pairs[0][0], pairs[0][1]))

    # Counts by category
    cat = Counter(_category_for(rel) for _, _, rel in items)
    total = len(items)

    print("\n🔎 Diagnostics: Breakdown of 'required' files")
    for k in ("html","styles","scripts","data","images","fonts","media","other"):
        if cat.get(k):
            print(f"  • {k:7s}: {cat[k]}")
    print(f"  • total  : {total}")

    # Show a small sample (up to 30)
    print("\n🧾 Sample (first up to 30 paths Netlify requested):")
    for sha, _, rel in items[:30]:
        print(f"   - {rel}  [{sha[:8]}…]")

    # Persist full list
    out = public_dir / "_required_last_deploy.txt"
    try:
        with out.open("w", encoding="utf-8") as f:
            f.write(f"Required files for last deploy — generated {NOW.isoformat(timespec='seconds')}\n")
            f.write(f"Public root: {public_dir}\n\n")
            f.write("Count by category:\n")
            for k in ("html","styles","scripts","data","images","fonts","media","other"):
                if cat.get(k):
                    f.write(f"  - {k:7s}: {cat[k]}\n")
            f.write(f"  - total  : {total}\n\n")
            f.write("Full list (sha  remote_path  local_rel):\n")
            for sha, remote, rel in items:
                f.write(f"{sha}  {remote}  {rel}\n")
        print(f"\n📝 Wrote full list to: {out}")
    except Exception as e:
        print(f"⚠️ Could not write diagnostics file: {e}")

# ---------- Main ----------

def main():
    p = argparse.ArgumentParser(description="Deploy a built section site directly to Netlify using delta (file-digest) uploads only.")
    p.add_argument("--course", required=True, help="Course code, e.g., ICS3U")
    p.add_argument("--section", required=True, help="Section number, e.g., 1")
    p.add_argument("--diagnose", action="store_true", help="Print a breakdown of required files and save list to _required_last_deploy.txt")
    # NEW: optional team slug flag (advanced users only)
    p.add_argument("--team", "--team-slug", dest="team", default=None,
                   help="Netlify team slug (advanced). If omitted, your personal team is used.")
    args = p.parse_args()

    # Ensure ignores and migrate legacy global secrets early
    _ensure_courses_gitignore()
    _maybe_migrate_global_from_legacy()

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
        print(f"   ./preview.sh {args.course} {args.section}")
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

    # Load or prompt for Netlify token (GLOBAL). Also respect env var if present.
    netlify_token = os.getenv("NETLIFY_AUTH_TOKEN") or _load_token_global("netlify")
    if netlify_token:
        print("🔐 Using Netlify token (env or saved global).")
    else:
        netlify_token = read_netlify_token_secure()
        if not netlify_token:
            print("❌ No token provided.")
            sys.exit(1)
        _save_token_global("netlify", netlify_token)
        print("💾 Saved Netlify token for future deploys (GLOBAL for all courses).")

    # Discover or create the Netlify site (no repo link)
    site_marker = load_netlify_marker(course_dir, section_dir, args.section)
    site_id = None
    site_url = None
    if site_marker:
        site_id = site_marker.get("id")
        site_url = site_marker.get("url") or site_marker.get("admin_url")
        print("🌐 Using existing Netlify site for this section.")
        if site_url:
            print(f"   Site: {site_url}")
    else:
        team_slug = args.team  # <-- use CLI flag; no interactive prompt
        if team_slug:
            print(f"👥 Using Netlify team: {team_slug}")
        try:
            site = maybe_create_netlify_site_simple(
                token=netlify_token,
                team_slug=team_slug,
                course_code=args.course,
                section=str(args.section),
                teacher_last_name=teacher_last_name
            )
            save_netlify_marker(course_dir, args.section, site)
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

    # Always delta deploy to PRODUCTION (as requested)
    print("🧮 Preparing delta deploy manifest…")
    try:
        manifest_resp = create_delta_deploy(site_id, netlify_token, public_dir, draft=False, async_req=False)
        deploy_id = manifest_resp.get("id")
        required = manifest_resp.get("required") or []
        sha_to_pairs = manifest_resp.get("_sha_to_pairs") or {}
        print(f"📋 Netlify requires {len(required)} file(s) for this deploy.")
        if args.diagnose:
            print_required_diagnostics(required, sha_to_pairs, public_dir)
        _upload_required_files(deploy_id, netlify_token, public_dir, required, sha_to_pairs)
        print("✅ Delta deploy created (production).")
        if deploy_id:
            print(f"   Deploy ID: {deploy_id}")
        if site_url:
            print(f"   Site URL:  {site_url}")
    except Exception as e:
        print("❌ Delta deploy failed.")
        print(f"   Details: {e}")
        print("   Tip: Check for unusual filenames (control chars) and ensure your token has access to this team/site.")
        sys.exit(1)

    print("\n✅ Deploy complete.")

if __name__ == "__main__":
    main()
