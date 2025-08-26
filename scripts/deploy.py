#!/usr/bin/env python3
import argparse
import base64
import datetime as dt
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.request
import urllib.error
from pathlib import Path

QUARTZ_UPSTREAM = "https://github.com/jackyzha0/quartz.git"

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

# ---------- Teacher profile (NEW) ----------

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

# ---------- Shell / git helpers ----------

def sh(cmd, cwd=None, check=True, capture=False):
    if capture:
        return subprocess.run(
            cmd, cwd=cwd, check=check, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT
        ).stdout
    subprocess.run(cmd, cwd=cwd, check=check)

def git_remote_exists(cwd: Path, name: str) -> bool:
    try:
        out = sh(["git", "remote"], cwd=cwd, capture=True)
        return name in [r.strip() for r in out.splitlines()]
    except subprocess.CalledProcessError:
        return False

def git_remote_url(cwd: Path, name: str) -> str | None:
    if not git_remote_exists(cwd, name):
        return None
    try:
        out = sh(["git", "remote", "get-url", name], cwd=cwd, capture=True).strip()
        return out or None
    except subprocess.CalledProcessError:
        return None

def git_branch_exists(cwd: Path, name: str) -> bool:
    try:
        out = sh(["git", "branch", "--list", name], cwd=cwd, capture=True)
        return name in out
    except subprocess.CalledProcessError:
        return False

def ensure_git_repo(cwd: Path, main_branch: str = "main"):
    if not (cwd / ".git").exists():
        print("📦 Initializing new git repo...")
        sh(["git", "init"], cwd=cwd)
    if not git_branch_exists(cwd, main_branch):
        sh(["git", "checkout", "-B", main_branch], cwd=cwd)
    else:
        sh(["git", "checkout", main_branch], cwd=cwd)
    # Minimal identity if missing
    try:
        _ = sh(["git", "config", "user.email"], cwd=cwd, capture=True).strip()
        _ = sh(["git", "config", "user.name"], cwd=cwd, capture=True).strip()
    except subprocess.CalledProcessError:
        print("👤 Setting placeholder git identity (change later with git config).")
        sh(["git", "config", "user.email", "teacher@example.com"], cwd=cwd)
        sh(["git", "config", "user.name", "Teacher"], cwd=cwd)

def suggest_repo_name(course_code: str, section_num: str) -> str:
    year = str(NOW.year)
    section_label = f"S{section_num}"
    return f"{course_code}-{section_label}-{year}"

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

# ---------- GitHub API ----------

def read_token_secure() -> str:
    import getpass
    print("\n🔐 A GitHub Personal Access Token (PAT) is required to create a repo and push.")
    print("   Where to generate a PAT in GitHub:")
    print("   • GitHub → your avatar (top-right) → Settings")
    print("   • Left sidebar → Developer settings → Personal access tokens")
    print("   • Choose “Tokens (classic)” → Generate new token (classic)")
    print("   • Scope: ‘repo’, ‘workflow’.")
    print("   • STRONGLY RECOMMENDED: set **No expiration** so you won’t be prompted again across courses/years.")
    print("   Tip: Add a note like 'Access for deploy script'. You can revoke anytime.")
    return getpass.getpass("GITHUB_TOKEN (hidden as you type): ").strip()

def github_api(method: str, url: str, token: str, payload: dict | None = None) -> dict:
    req = urllib.request.Request(url, method=method)
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("Authorization", f"Bearer {token}")
    body = None
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, data=body) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        msg = e.read().decode("utf-8", errors="ignore")
        raise RuntimeError(f"GitHub API error {e.code}: {msg}") from e

def create_repo(owner: str | None, name: str, private: bool, token: str) -> str:
    """
    Returns HTTPS git URL, e.g. https://github.com/owner/name.git
    If owner is None -> create under the authenticated user.
    If owner is an org -> create under that org.
    """
    if owner:
        print(f"📡 Creating repo in org/user '{owner}' named '{name}'...")
        api = f"https://api.github.com/orgs/{owner}/repos"
        payload = {"name": name, "private": private, "auto_init": False}
        github_api("POST", api, token, payload)
        return f"https://github.com/{owner}/{name}.git"
    else:
        print(f"📡 Creating repo in your user account named '{name}'...")
        api = "https://api.github.com/user/repos"
        payload = {"name": name, "private": private, "auto_init": False}
        github_api("POST", api, token, payload)
        me = github_api("GET", "https://api.github.com/user", token, None)
        login = me.get("login")
        return f"https://github.com/{login}/{name}.git"

def maybe_set_remote(cwd: Path, desired_url: str):
    """
    Only remove 'origin' if it currently points to QUARTZ_UPSTREAM.
    - If 'origin' doesn't exist: add it with desired_url.
    - If 'origin' == QUARTZ_UPSTREAM: remove and add desired_url.
    - Otherwise: keep existing 'origin' as-is.
    """
    current = git_remote_url(cwd, "origin")
    if current is None:
        print(f"🔗 Setting 'origin' -> {desired_url}")
        sh(["git", "remote", "add", "origin", desired_url], cwd=cwd)
        return "set"
    if current == QUARTZ_UPSTREAM:
        print("🧹 Removing existing 'origin' pointing to Quartz upstream (first deploy)...")
        sh(["git", "remote", "remove", "origin"], cwd=cwd)
        print(f"🔗 Setting 'origin' -> {desired_url}")
        sh(["git", "remote", "add", "origin", desired_url], cwd=cwd)
        return "replaced"
    print(f"✅ Keeping existing 'origin' -> {current}")
    return "kept"

# ---------- Project tweaks: Media + netlify.toml ----------

def copy_media_if_symlink(section_dir: Path):
    # In the merged output, Media could be under ./content/Media or ./Media.
    candidates = [section_dir / "content" / "Media", section_dir / "Media"]
    for media in candidates:
        if not media.exists():
            continue
        if media.is_symlink():
            print("🖼️ Replacing Media symlink with a real copy for deploy...")
            target = media.resolve()
            tmp_dest = media.parent / "_Media_deploy_copy"
            if tmp_dest.exists():
                shutil.rmtree(tmp_dest)
            shutil.copytree(target, tmp_dest)
            media.unlink()
            tmp_dest.rename(media)
            return
        else:
            print("🖼️ Media is already a real folder — nothing to do.")
            return

def ensure_netlify_toml(section_dir: Path):
    """
    Ensure a minimal netlify.toml so the site can build with Quartz defaults.
    Teachers can edit later in GitHub if needed.
    """
    toml_path = section_dir / "netlify.toml"
    if toml_path.exists():
        return
    print("🧩 Creating a basic netlify.toml (build command + publish dir)...")
    toml = (
        "# Auto-generated by deploy.py — adjust as needed.\n"
        "[build]\n"
        '  command = "npx quartz build"\n'
        '  publish = "public"\n'
    )
    toml_path.write_text(toml, encoding="utf-8")

# ---------- Commit & push ----------

def commit_and_push(cwd: Path, token: str | None):
    sh(["git", "add", "-A"], cwd=cwd)
    msg = f"Changes as of {NOW.strftime('%Y-%m-%d %H:%M:%S %z')}"
    sh(["git", "commit", "--allow-empty", "-m", msg], cwd=cwd)
    env = os.environ.copy()
    askpass_path = None
    try:
        if token:
            askpass_path = cwd / ".git_askpass_tmp.sh"
            askpass_path.write_text('#!/usr/bin/env bash\necho "$GITHUB_TOKEN"\n', encoding="utf-8")
            os.chmod(askpass_path, 0o700)
            env["GIT_ASKPASS"] = str(askpass_path)
            env["GITHUB_TOKEN"] = token
            env["GIT_USERNAME"] = "x-oauth-basic"
        print("⬆️  Pushing to origin/main...")
        subprocess.run(["git", "push", "-u", "origin", "main"], cwd=cwd, check=True, env=env)
    finally:
        if askpass_path and askpass_path.exists():
            try:
                askpass_path.unlink()
            except Exception:
                pass

def needs_pat_for_url(url: str | None) -> bool:
    return bool(url and url.startswith("https://github.com"))

# ---------- Netlify helpers ----------

def read_netlify_token_secure() -> str:
    import getpass
    print("\n🔐 A Netlify Personal Access Token is required to create the site via API.")
    print("   Where to create it:")
    print("   • Netlify → User settings → Applications → Personal access tokens → New access token")
    print("   • STRONGLY RECOMMENDED: set **No expiration** so you won’t be prompted again across courses/years.")
    print("   (You’ll copy the token once. Keep it private.)")
    return getpass.getpass("NETLIFY_PERSONAL_ACCESS_TOKEN (hidden as you type): ").strip()

def netlify_api(method: str, path: str, token: str, payload: dict | None = None) -> dict:
    base = "https://api.netlify.com/api/v1"
    url = f"{base}{path}"
    req = urllib.request.Request(url, method=method)
    req.add_header("Accept", "application/json")
    req.add_header("Authorization", f"Bearer {token}")
    body = None
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, data=body) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        msg = e.read().decode("utf-8", errors="ignore")
        # keep original behavior: raise RuntimeError with message body
        raise RuntimeError(f"Netlify API error {e.code}: {msg}") from e

def _extract_json_from_error(err: Exception) -> dict | None:
    """
    Best-effort: pull trailing JSON object from an exception's string repr.
    """
    s = str(err).strip()
    # Find last '{' and try to parse JSON from there
    idx = s.rfind("{")
    if idx == -1:
        return None
    candidate = s[idx:]
    try:
        return json.loads(candidate)
    except Exception:
        return None

def _is_netlify_name_conflict(err: Exception) -> bool:
    """
    Returns True when the error indicates the site subdomain is not unique.
    Handles messages like:
      {"errors":{"subdomain":["must be unique"]}}
      {"errors":{"name":["is already taken"]}}
    And generic phrasing like "already exists"/"taken"/"unique".
    """
    s = str(err).lower()
    if "422" in s and ("unique" in s or "already" in s or "taken" in s or "exists" in s):
        return True
    data = _extract_json_from_error(err)
    if isinstance(data, dict):
        errs = data.get("errors")
        if isinstance(errs, dict):
            for key, messages in errs.items():
                if isinstance(messages, list):
                    for m in messages:
                        lm = (m or "").lower()
                        if any(x in lm for x in ["unique", "already", "taken", "exists"]):
                            return True
    return False

def parse_github_owner_repo(remote_url: str | None) -> tuple[str | None, str | None]:
    """
    Supports:
      - https://github.com/owner/repo.git
      - https://github.com/owner/repo
      - git@github.com:owner/repo.git
    """
    if not remote_url:
        return (None, None)
    m = re.match(r"^https://github\.com/([^/]+)/([^/]+?)(?:\.git)?$", remote_url)
    if m:
        return (m.group(1), m.group(2))
    m = re.match(r"^git@github\.com:([^/]+)/([^/]+?)(?:\.git)?$", remote_url)
    if m:
        return (m.group(1), m.group(2))
    return (None, None)

def suggest_site_base(course_code: str, section: str, teacher_last_name: str) -> str:
    """
    Example: ICD2O + 1 + gordon -> icd2o-s1-2025-gordon
    """
    course = (course_code or "").lower()
    sec = f"s{section}"
    base = f"{course}-{sec}-{NOW.year}-{teacher_last_name}"
    return sanitize_netlify_name(base)

def maybe_create_netlify_site(owner: str, repo: str, branch: str, token: str,
                              team_slug: str | None = None,
                              course_code: str | None = None,
                              section: str | None = None,
                              teacher_last_name: str | None = None) -> dict:
    """
    Create a Netlify site linked to a GitHub repo.
    Uses POST /api/v1/sites (or /api/v1/accounts/{team_slug}/sites) with a repo block.
    If the chosen name is taken, we prompt and suggest alternatives until success.
    Returns the site object on success.
    """
    # Build a friendly, collision-resistant default
    if teacher_last_name and course_code and section:
        base = suggest_site_base(course_code, section, teacher_last_name)
    else:
        base = sanitize_netlify_name(repo)

    site_name = prompt("Enter Netlify site name", default=base).strip() or base

    attempt = 0
    path = f"/accounts/{team_slug}/sites" if team_slug else "/sites"

    while True:
        payload = {
            "name": site_name,
            "repo": {
                "provider": "github",
                "repo": f"{owner}/{repo}",
                "branch": branch,
                "cmd": "npx quartz build",
                "dir": "public",
                "private": True,
            }
        }
        try:
            site = netlify_api("POST", path, token, payload)
            return site
        except RuntimeError as e:
            # If the name is taken, suggest an alternative and re-prompt
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
            # Otherwise, bubble up
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
        # prefer ssl_url for canonical https URL
        "url": site_obj.get("ssl_url") or site_obj.get("url"),
        "admin_url": site_obj.get("admin_url"),
    }
    marker.write_text(json.dumps(keep, indent=2), encoding="utf-8")

# ---------- Main ----------

def main():
    p = argparse.ArgumentParser(description="Deploy a merged section folder to GitHub and (by default) set up Netlify.")
    p.add_argument("--course", required=True, help="Course code, e.g., ICS3U")
    p.add_argument("--section", required=True, help="Section number, e.g., 1")
    p.add_argument("--owner", help="GitHub user/org to own the repo (default: your user)")
    p.add_argument("--repo", help="Repository name (default: suggested)")
    p.add_argument("--no-create-remote", action="store_true", help="Do not create the remote; assume it already exists")
    p.add_argument("--private", action="store_true", help="Create the repo as private (default: public)")
    args = p.parse_args()

    # Path: /teaching/courses/<COURSE>/.merged_output/section<NUM>
    section_dir = Path(f"/teaching/courses/{args.course}/.merged_output/section{args.section}").resolve()
    if not section_dir.exists():
        print(f"❌ Section directory not found: {section_dir}")
        print(f"👉 Please run the preview first to build the merged output:")
        print(f"   ./preview.sh {args.course} {args.section}")
        sys.exit(1)

    # Determine course dir (for back-compat migration) and run migration
    course_dir = section_dir.parent.parent  # .../<COURSE>/.merged_output/section#
    _maybe_migrate_course_tokens_to_global(course_dir)

    # NEW: capture teacher last name once per /teaching/courses
    try:
        teacher_last_name = get_or_prompt_teacher_last_name()
    except Exception:
        # Non-interactive environments can skip; we'll just omit from suggestion
        teacher_last_name = None

    print(f"📁 Deploying from: {section_dir}")
    print(f"🕒 Timestamp TZ offset: {NOW.strftime('%z')}")

    ensure_git_repo(section_dir)

    # Determine whether we need to create/replace remote
    current_origin = git_remote_url(section_dir, "origin")
    needs_new_remote = (current_origin == QUARTZ_UPSTREAM)

    git_url = None
    token_for_push = None

    if needs_new_remote:
        # Prefer a saved GLOBAL GitHub token first
        token_for_push = _load_token_global("github")
        if token_for_push:
            print("🔐 Using saved GitHub token (global).")
        repo_name = args.repo or suggest_repo_name(args.course, args.section)
        print(f"💡 Suggested repo name: {repo_name}")
        if not args.repo:
            repo_name = prompt("Enter repo name to use", default=repo_name)

        if args.no_create_remote:
            owner = args.owner or prompt("GitHub owner (user/org) for existing repo")
            git_url = f"https://github.com/{owner}/{repo_name}.git"
        else:
            if not token_for_push:
                token_for_push = read_token_secure()
                _save_token_global("github", token_for_push)
                print("💾 Saved GitHub token for future deploys (GLOBAL for all courses).")
            try:
                git_url = create_repo(args.owner, repo_name, args.private, token_for_push)
                print(f"✅ Remote created: {git_url}")
            except Exception as e:
                print(f"⚠️ Could not create remote automatically:\n   {e}")
                print("You can create it manually, then press Enter to continue.")
                input("Press Enter when the repo exists on GitHub...")
                owner = args.owner or prompt("GitHub owner (user/org) for existing repo")
                git_url = f"https://github.com/{owner}/{repo_name}.git"

        # Apply the new remote (only remove if pointing at Quartz upstream)
        _state = maybe_set_remote(section_dir, git_url)
    else:
        print(f"🔗 Remote creation not needed — existing 'origin' will be used: {current_origin}")

    # Ensure Media is copied (not symlinked) and netlify.toml exists BEFORE the commit
    copy_media_if_symlink(section_dir)
    ensure_netlify_toml(section_dir)

    # If we don't yet have a token and the origin uses HTTPS to GitHub, load or prompt now
    origin_after = git_remote_url(section_dir, "origin")
    if needs_pat_for_url(origin_after):
        if token_for_push is None:
            token_for_push = _load_token_global("github")
            if token_for_push:
                print("🔐 Using saved GitHub token (global).")
        if token_for_push is None:
            token_for_push = read_token_secure()
            _save_token_global("github", token_for_push)
            print("💾 Saved GitHub token for future deploys (GLOBAL for all courses).")

    # Commit & push (initial or subsequent)
    try:
        commit_and_push(section_dir, token_for_push)
    except subprocess.CalledProcessError as e:
        # If push failed and we used a token, let teacher re-enter & save it (token might be expired/revoked)
        if token_for_push is not None:
            print("⚠️ Push failed. Your saved GitHub token may be invalid or expired.")
            token_for_push = read_token_secure()
            _save_token_global("github", token_for_push)
            print("💾 Updated saved GitHub token (global).")
            commit_and_push(section_dir, token_for_push)
        else:
            raise

    # ---------- Default: set up Netlify (first time only) ----------
    existing_netlify = load_netlify_marker(section_dir)
    if existing_netlify:
        print("🌐 Netlify site already recorded for this section (skipping setup).")
        print(f"   Site: {existing_netlify.get('url') or existing_netlify.get('admin_url')}")
        print("   Tip: future pushes will trigger Netlify automatically.")
        print()
        print("✅ Deploy complete.")
        return

    # Try to parse owner/repo from origin to link in Netlify
    gh_owner, gh_repo = parse_github_owner_repo(origin_after)
    if not gh_owner or not gh_repo:
        print("⚠️ Unable to parse GitHub owner/repo from 'origin'.")
        print("   Skipping automatic Netlify setup. You can link the repo in the Netlify UI.")
        print()
        print("✅ Deploy complete.")
        return

    # Offer Netlify setup now (default Yes)
    resp = prompt("Set up Netlify now so pushes auto-build your site? (Y/n)", default="Y").strip().lower()
    if resp.startswith("n"):
        print("ℹ️  Skipping Netlify setup for now. You can do it later in the Netlify UI.")
        print("✅ Deploy complete.")
        return

    # Teacher guidance for GitHub App + token
    print("\n📎 Netlify + GitHub prerequisites (one-time only!):")
    print("   1) Install the Netlify GitHub App and grant it access to the repo.")
    print("      • Netlify UI → Projects → Add new project → Import an existing project → “GitHub” → Authorize Netlify → If necessary, choose “Configure the Netlify app on GitHub” at bottom of screen → Select the repository you just created → Deploy")
    print("   2) Create a Netlify Personal Access Token (PAT):")
    print("      • Netlify avatar (bottom left) → User settings → Applications → Personal access tokens → New access token.")
    print("      • STRONGLY RECOMMENDED: set **No expiration** so you won’t be prompted again across courses/years.")
    print("")

    # Load or prompt for Netlify token (GLOBAL)
    netlify_token = _load_token_global("netlify")
    if netlify_token:
        print("🔐 Using saved Netlify token (global).")
    else:
        netlify_token = read_netlify_token_secure()
        _save_token_global("netlify", netlify_token)
        print("💾 Saved Netlify token for future deploys (GLOBAL for all courses).")

    team_slug = prompt("Netlify Team slug (optional; Enter to use your personal team)", default="").strip() or None

    try:
        site = maybe_create_netlify_site(
            gh_owner, gh_repo, branch="main", token=netlify_token, team_slug=team_slug,
            course_code=args.course, section=str(args.section), teacher_last_name=teacher_last_name
        )
        save_netlify_marker(section_dir, site)
        site_url = site.get("ssl_url") or site.get("url")
        admin_url = site.get("admin_url")
        print("🎉 Netlify site created & linked to your GitHub repo.")
        if site_url:
            print(f"   Live URL: {site_url}")
        if admin_url:
            print(f"   Admin:    {admin_url}")
        print("   Tip: future pushes to 'main' will trigger Netlify builds automatically.")
    except Exception as e:
        print("⚠️ Netlify setup did not complete via API.")
        print(f"   Details: {e}")
        print("   Common fixes:")
        print("   • Ensure the Netlify GitHub App is installed and has access to this repo/org.")
        print("   • If your school uses SSO, ensure the Netlify token is authorized for your Team.")
        print("   You can always finish setup in the Netlify UI (Add new site → Import from Git).")

    print("\n✅ Deploy complete.")

if __name__ == "__main__":
    main()
