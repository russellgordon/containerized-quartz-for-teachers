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
from zoneinfo import ZoneInfo
from pathlib import Path
from collections import Counter

# ---- Host OS signaling & example command helper -----------------------------
_HOST_OS = "unknown"

def _is_windows(host_os: str) -> bool:
    return (host_os or "").lower() == "windows"

def _cmd_example(script_base: str, course, section, host_os: str) -> str:
    return (f".\\{script_base}.bat {course} {section}") if _is_windows(host_os) else (f"./{script_base}.sh {course} {section}")
# ----------------------------------------------------------------------------

# ---------- Rate-limit helpers (NEW) ----------
def _parse_http_date(s: str) -> dt.datetime | None:
    """Parse an RFC1123 HTTP-date string to a timezone-aware UTC datetime."""
    try:
        # Example: 'Wed, 21 Oct 2015 07:28:00 GMT'
        return dt.datetime.strptime(s, "%a, %d %b %Y %H:%M:%S GMT").replace(tzinfo=dt.timezone.utc)
    except Exception:
        return None

def _format_rate_limit_guidance(headers) -> str:
    """
    Build minimal guidance from rate-limit headers for user-facing output.
    Shows only:
      - the current local time, and
      - "Window resets at ..." (derived from X-RateLimit-Reset)
    Omits Retry-After and limit/remaining to avoid confusing or vendor-specific values.
    """
    try:
        greset = headers.get("X-RateLimit-Reset")

        # Determine local timezone from script context; fallback to UTC.
        try:
            local_tz = TZ  # set by parse_host_tz()
        except NameError:
            try:
                local_tz = parse_host_tz()
            except Exception:
                import datetime as _dt
                local_tz = _dt.timezone.utc

        import datetime as _dt
        now_local = _dt.datetime.now(_dt.timezone.utc).astimezone(local_tz)
        lines = [f"Now: {now_local.strftime('%Y-%m-%d %H:%M:%S %Z')}"]

        # Parse X-RateLimit-Reset: epoch seconds or HTTP-date
        reset_dt = None
        if greset:
            try:
                reset_dt = _dt.datetime.fromtimestamp(int(greset), tz=_dt.timezone.utc)
            except Exception:
                reset_dt = _parse_http_date(greset)

        if reset_dt is not None:
            reset_dt_local = reset_dt.astimezone(local_tz)
            secs = max(0, int((reset_dt - _dt.datetime.now(_dt.timezone.utc)).total_seconds()))
            lines.append(f"Window resets at: {reset_dt_local.strftime('%Y-%m-%d %H:%M:%S %Z')} (in ~{secs}s).")

        return "\n".join(lines)
    except Exception:
        return ""

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
# Hidden global store for non-secret preferences (e.g., teacher profile)
GLOBAL_SECRETS_ROOT = COURSES_ROOT / ".internal"
# Legacy path (kept only to migrate profile.json, not tokens)
OLD_GLOBAL_SECRETS_ROOT = COURSES_ROOT / "_secrets"

def _profile_path() -> Path:
    return GLOBAL_SECRETS_ROOT / "profile.json"

def _ensure_courses_gitignore():
    """
    Ensure /teaching/courses/.gitignore exists and ignores:
      - /.internal/ (hidden store for small prefs)
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
    raw = input(" First time setup... what is your last name? (letters only): ").strip()
    ln = sanitize_last_name(raw)
    while not ln:
        raw = input("Please enter letters only for your last name (e.g., 'Gordon'): ").strip()
        ln = sanitize_last_name(raw)
    save_teacher_last_name(ln)
    print(f" Saved teacher last name for future deploys: {ln}")
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

# ---------- Netlify API helpers ----------
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
        # NEW: enrich 429 errors (and others) with rate-limit guidance
        guidance = _format_rate_limit_guidance(getattr(e, "headers", {}))
        suffix = f"\n{guidance}" if guidance else ""
        raise RuntimeError(f"Netlify API error {e.code}: {msg}{suffix}") from e

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
    """Example: ICD2O + 1 + gordon -> icd2o-s1-2025-gordon"""
    course = (course_code or "").lower()
    sec = f"s{section}"
    base = f"{course}-{sec}-{NOW.year}-{teacher_last_name}"
    return sanitize_netlify_name(base)

def maybe_create_netlify_site_simple(token: str, team_slug: str | None, course_code: str | None, section: str | None, teacher_last_name: str | None) -> dict:
    """
    Create a Netlify site WITHOUT linking to a Git provider.
    POST /api/v1/sites (or /api/v1/accounts/{team_slug}/sites)
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
                print(f"⚠️ Netlify site name '{site_name}' is not available (already in use).")
                print(" Tip: names must be globally unique across Netlify and use letters, numbers, and hyphens.")
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
    Prefer stable marker at /.netlify_sites/section.json.
    If not found, migrate legacy marker from /.netlify_site.json.
    """
    stable = _stable_marker_path(course_dir, section)
    if stable.exists():
        try:
            return json.loads(stable.read_text(encoding="utf-8"))
        except Exception:
            pass
    legacy = _legacy_marker_path(section_dir)
    if legacy.exists():
        try:
            data = json.loads(legacy.read_text(encoding="utf-8"))
            # migrate
            _stable_marker_dir(course_dir).mkdir(parents=True, exist_ok=True)
            stable.write_text(json.dumps(data, indent=2), encoding="utf-8")
            try:
                os.chmod(stable, 0o600)
            except Exception:
                pass
            try:
                legacy.unlink()
            except Exception:
                pass
            print(" Migrated Netlify site marker to stable location.")
            return data
        except Exception:
            return None
    return None

def save_netlify_marker(course_dir: Path, section: str | int, site: dict):
    _stable_marker_dir(course_dir).mkdir(parents=True, exist_ok=True)
    p = _stable_marker_path(course_dir, section)
    p.write_text(json.dumps(site, indent=2), encoding="utf-8")
    try:
        os.chmod(p, 0o600)
    except Exception:
        pass

# ---------- Delta deploy helpers ----------
def _sha1_bytes(data: bytes) -> str:
    h = hashlib.sha1()
    h.update(data)
    return h.hexdigest()

def _sha1_file(path: Path, bufsize: int = 1024 * 1024) -> str:
    h = hashlib.sha1()
    with path.open("rb") as f:
        while True:
            b = f.read(bufsize)
            if not b:
                break
            h.update(b)
    return h.hexdigest()

def _iter_public_files(root: Path):
    for p in sorted(root.rglob("*")):
        if p.is_file():
            # skip obvious junk
            name = p.name.lower()
            if name in {".ds_store"}:
                continue
            yield p

def _remote_path_for(root: Path, file_path: Path) -> str:
    rel = file_path.relative_to(root).as_posix()
    return "/" + rel  # Netlify expects leading slash

def _build_files_manifest(root: Path) -> tuple[dict, dict]:
    """
    Return:
      - files_map: { "/path/on/site": "sha1digest" }
      - sha_to_pairs: { "sha1": [(remote_path, relative_local_path), ...] }
    """
    files_map: dict[str, str] = {}
    sha_to_pairs: dict[str, list[tuple[str, str]]] = {}
    for f in _iter_public_files(root):
        remote = _remote_path_for(root, f)
        digest = _sha1_file(f)
        files_map[remote] = digest
        sha_to_pairs.setdefault(digest, []).append((remote, f.relative_to(root).as_posix()))
    return files_map, sha_to_pairs

def create_delta_deploy(site_id: str, token: str, root: Path, draft: bool = False, async_req: bool = False) -> dict:
    """
    Step 1: POST /sites/{site_id}/deploys with {"files": { "/path": "sha1", ... }}
    Returns a list of "required" digests to upload via PUTs.
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
    Step 2: PUT each required file to /deploys/{deploy_id}/files/<path>
    Only one path per required digest is necessary.
    """
    if not required_shas:
        print(" No file uploads needed (all content already present on Netlify).")
        return
    uploaded = 0
    for sha in required_shas:
        pairs = sha_to_pairs.get(sha) or []
        if not pairs:
            print(f"⚠️ Netlify requested unknown digest {sha[:8]}…; skipping.")
            continue
        remote_path, local_rel = pairs[0]
        local_file = root / local_rel
        if not local_file.exists():
            print(f"⚠️ Missing local file for {remote_path}; skipping.")
            continue
        # Encode remote path for URL; escape reserved chars safely
        encoded_path = urllib.parse.quote(remote_path.lstrip("/"), safe="/")
        with local_file.open("rb") as f:
            data = f.read()
        headers = {"Content-Type": "application/octet-stream"}
        netlify_api("PUT", f"/deploys/{deploy_id}/files/{encoded_path}", token, headers=headers, data=data)
        uploaded += 1
        if uploaded % 25 == 0:
            print(f" …uploaded {uploaded}/{len(required_shas)} required files")
    print(f"⬆️ Uploaded {uploaded} file(s) required by Netlify.")

# ---------- Diagnostics (new) ----------
_IMG_EXT  = {"jpg","jpeg","png","gif","webp","svg","bmp","tiff","ico","avif"}
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
            items.append((sha, "", ""))
        else:
            items.append((sha, pairs[0][0], pairs[0][1]))

    # Counts by category
    cat = Counter(_category_for(rel) for _, _, rel in items)
    total = len(items)
    print("\n Diagnostics: Breakdown of 'required' files")
    for k in ("html","styles","scripts","data","images","fonts","media","other"):
        if cat.get(k):
            print(f" • {k:7s}: {cat[k]}")
    print(f" • total : {total}")

    # Show a small sample (up to 30)
    print("\n Sample (first up to 30 paths Netlify requested):")
    for sha, _, rel in items[:30]:
        print(f" - {rel} [{sha[:8]}…]")

    # Persist full list
    out = public_dir / "_required_last_deploy.txt"
    try:
        with out.open("w", encoding="utf-8") as f:
            f.write(f"Required files for last deploy — generated {NOW.isoformat(timespec='seconds')}\n")
            f.write(f"Public root: {public_dir}\n\n")
            f.write("Count by category:\n")
            for k in ("html","styles","scripts","data","images","fonts","media","other"):
                if cat.get(k):
                    f.write(f" - {k:7s}: {cat[k]}\n")
            f.write(f" - total : {total}\n\n")
            f.write("Full list (sha remote_path local_rel):\n")
            for sha, remote, rel in items:
                f.write(f"{sha} {remote} {rel}\n")
        print(f"\n Wrote full list to: {out}")
    except Exception as e:
        print(f"⚠️ Could not write diagnostics file: {e}")

# ---------- Main ----------
def main():
    p = argparse.ArgumentParser(
        description="Deploy a built section site directly to Netlify using delta (file-digest) uploads only."
    )
    p.add_argument("--host-os", choices=["windows","mac","linux","unknown"], default="unknown",
                   help="Host OS passed by deploy launchers")
    p.add_argument("--course", required=True, help="Course code, e.g., ICS3U")
    p.add_argument("--section", required=True, help="Section number, e.g., 1")
    p.add_argument("--diagnose", action="store_true",
                   help="Print a breakdown of required files and save list to _required_last_deploy.txt")
    # optional team slug flag (advanced users only)
    p.add_argument("--team", "--team-slug", dest="team", default=None,
                   help="Netlify team slug (advanced). If omitted, your personal team is used.")
    args = p.parse_args()

    global _HOST_OS
    _HOST_OS = getattr(args, 'host_os', 'unknown')

    # Keep .gitignore hygiene and migrate *profile only* from legacy if present.
    _ensure_courses_gitignore()
    # (Do NOT migrate or touch any token stores here; host launcher handles that.)

    # Path: /teaching/courses/<COURSE>/.merged_output/section<SECTION>
    section_dir = Path(f"/teaching/courses/{args.course}/.merged_output/section{args.section}").resolve()
    if not section_dir.exists():
        print(f"❌ Section directory not found: {section_dir}")
        print(f" Please run the preview/build first:")
        print(f"{_cmd_example('preview', args.course, args.section, _HOST_OS)}")
        sys.exit(1)

    # Require the built site (public/)
    public_dir = section_dir / "public"
    if not public_dir.exists() or not any(public_dir.iterdir()):
        print(f"❌ Built site not found at: {public_dir}")
        print(f" Please build before deploying.\n For example:")
        print(f"{_cmd_example('preview', args.course, args.section, _HOST_OS)}")
        sys.exit(1)

    # Determine course dir (for stable marker)
    course_dir = section_dir.parent.parent  # .../<COURSE>/.merged_output/section#

    # Capture teacher last name for naming
    try:
        teacher_last_name = get_or_prompt_teacher_last_name()
    except Exception:
        teacher_last_name = None

    print(f" Deploying from local build: {public_dir}")
    print(f" Timestamp TZ offset: {NOW.strftime('%z')}")

    # --- Token handling (new, simplified) ---
    # Only read from environment; host launcher (deploy.sh/.ps1) must inject it.
    netlify_token = os.getenv("NETLIFY_AUTH_TOKEN")
    if not netlify_token:
        print("❌ Netlify token missing.")
        print(" This script now expects the token to be passed via environment by the host launcher.")
        print(" If you ran this directly, create a Personal Access Token here:")
        print("   https://app.netlify.com/user/applications#personal-access-tokens")
        print(" Then set it as NETLIFY_AUTH_TOKEN and re-run via your platform launcher:")
        print(f"   {_cmd_example('deploy', args.course, args.section, _HOST_OS)}")
        sys.exit(1)

    # Discover or create the Netlify site (no repo link)
    site_marker = load_netlify_marker(course_dir, section_dir, args.section)
    site_id = None
    site_url = None
    if site_marker:
        site_id = site_marker.get("id")
        site_url = site_marker.get("url") or site_marker.get("admin_url")
        print(" Using existing Netlify site for this section.")
        if site_url:
            print(f" Site: {site_url}")
    else:
        team_slug = args.team  # <-- use CLI flag; no interactive prompt
        if team_slug:
            print(f" Using Netlify team: {team_slug}")
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
            print(" Netlify site created.")
            if site_url:
                print(f" Live URL: {site_url}")
            if admin_url:
                print(f" Admin: {admin_url}")
        except Exception as e:
            print("❌ Failed to create Netlify site.")
            print(f" Details: {e}")
            sys.exit(1)

    if not site_id:
        print("❌ Could not determine Netlify site ID.")
        sys.exit(1)

    # Always delta deploy to PRODUCTION (as requested)
    print(" Preparing delta deploy manifest…")
    try:
        manifest_resp = create_delta_deploy(site_id, netlify_token, public_dir, draft=False, async_req=False)
        deploy_id = manifest_resp.get("id")
        required = manifest_resp.get("required") or []
        sha_to_pairs = manifest_resp.get("_sha_to_pairs") or {}
        print(f" Netlify requires {len(required)} file(s) for this deploy.")
        if args.diagnose:
            print_required_diagnostics(required, sha_to_pairs, public_dir)
        _upload_required_files(deploy_id, netlify_token, public_dir, required, sha_to_pairs)
        print("✅ Delta deploy created (production).")
        if deploy_id:
            print(f" Deploy ID: {deploy_id}")
        if site_url:
            print(f" Site URL: {site_url}")
    except Exception as e:
        print("❌ Delta deploy failed.")
        print(f" Details: {e}")
        print(" Tip: Check for unusual filenames (control chars) and ensure your token has access to this team/site.")
        sys.exit(1)

    print("\n✅ Deploy complete.")

if __name__ == "__main__":
    main()
