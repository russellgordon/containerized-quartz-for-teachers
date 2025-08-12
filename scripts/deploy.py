#!/usr/bin/env python3
import argparse
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

# ---------- GitHub API ----------

def read_token_secure() -> str:
    import getpass
    print("\n🔐 A GitHub Personal Access Token (PAT) is required to create a repo and push.")
    print("   Where to generate a PAT in GitHub:")
    print("   • GitHub → your avatar (top-right) → Settings")
    print("   • Left sidebar → Developer settings → Personal access tokens")
    print("   • Choose “Tokens (classic)” → Generate new token (classic)")
    print("   • Scope: ‘repo’,‘workflow’.")
    print("   • Create by pressing the green ‘Generate token’ button at the bottom.")
    print("   Tip: Add a note like 'Access for deploy script for COURSE S# YEAR'.")
    print("   Tip: Keep the token private; you can revoke it anytime.")
    print("   Tip: Consider ‘No expiration’ or at least through the school year.")
    return getpass.getpass("GITHUB_TOKEN (token will not be shown when you paste it in): ").strip()

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
            askpass_path.write_text("#!/usr/bin/env bash\necho \"$GITHUB_TOKEN\"\n", encoding="utf-8")
            os.chmod(askpass_path, 0o700)
            env["GIT_ASKPASS"] = str(askpass_path)
            env["GITHUB_TOKEN"] = token
            env["GIT_USERNAME"] = "x-oauth-basic"
        print("⬆️  Pushing to origin/main...")
        subprocess.run(["git", "push", "-u", "origin", "main"], cwd=cwd, check=True, env=env)
    finally:
        if askpass_path and askpass_path.exists():
            try: askpass_path.unlink()
            except: pass

def needs_pat_for_url(url: str | None) -> bool:
    return bool(url and url.startswith("https://github.com"))

# ---------- Netlify helpers ----------

def read_netlify_token_secure() -> str:
    import getpass
    print("\n🔐 A Netlify Personal Access Token is required to create the site via API.")
    print("   Where to create it:")
    print("   • Netlify → User settings → Applications → Personal access tokens → New access token")
    print("   (You’ll copy the token once. Keep it private.)")
    # Docs: Get started with the Netlify API (Authentication → Personal access tokens)
    # https://docs.netlify.com/api-and-cli-guides/api-guides/get-started-with-api/
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
        raise RuntimeError(f"Netlify API error {e.code}: {msg}") from e

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

def maybe_create_netlify_site(owner: str, repo: str, branch: str, token: str, team_slug: str | None = None) -> dict:
    """
    Create a Netlify site linked to a GitHub repo.
    Uses POST /api/v1/sites (or /api/v1/accounts/{team_slug}/sites) with a repo block.
    Returns the site object on success.
    """
    payload = {
        # null name -> Netlify assigns a random subdomain; teachers can rename later
        "name": None,
        "repo": {
            "provider": "github",
            "repo": f"{owner}/{repo}",
            "branch": branch,
            "cmd": "npx quartz build",
            "dir": "public",
            "private": True,  # ok even for public repos; affects linking workflow only
        }
    }
    path = f"/accounts/{team_slug}/sites" if team_slug else "/sites"
    site = netlify_api("POST", path, token, payload)
    return site

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
        "url": site_obj.get("url") or site_obj.get("ssl_url"),
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

    print(f"📁 Deploying from: {section_dir}")
    print(f"🕒 Timestamp TZ offset: {NOW.strftime('%z')}")

    ensure_git_repo(section_dir)

    # Determine whether we need to create/replace remote
    current_origin = git_remote_url(section_dir, "origin")
    needs_new_remote = (current_origin is None) or (current_origin == QUARTZ_UPSTREAM)

    git_url = None
    token_for_push = None

    if needs_new_remote:
        repo_name = args.repo or suggest_repo_name(args.course, args.section)
        print(f"💡 Suggested repo name: {repo_name}")
        if not args.repo:
            repo_name = prompt("Enter repo name to use", default=repo_name)

        if args.no_create_remote:
            owner = args.owner or prompt("GitHub owner (user/org) for existing repo")
            git_url = f"https://github.com/{owner}/{repo_name}.git"
        else:
            token_for_push = read_token_secure()
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

    # If we don't yet have a token and the origin uses HTTPS to GitHub, prompt now
    origin_after = git_remote_url(section_dir, "origin")
    if token_for_push is None and needs_pat_for_url(origin_after):
        token_for_push = read_token_secure()

    # Commit & push (initial or subsequent)
    commit_and_push(section_dir, token_for_push)

    # ---------- Default: set up Netlify (first time only) ----------
    # Skip if marker exists
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
    print("\n📎 Netlify + GitHub prerequisites (one-time):")
    print("   1) Install the Netlify GitHub App and grant it access to this repo (or your org).")
    print("      • Netlify UI → Site overview (or Team settings) → “Install the Netlify GitHub App”.")
    print("      • If you don’t see it, check Netlify docs: “Repository permissions and linking”.")  # docs citation in chat
    print("   2) Create a Netlify Personal Access Token (PAT):")
    print("      • Netlify → User settings → Applications → Personal access tokens → New access token.")  # docs citation in chat
    print("")

    netlify_token = read_netlify_token_secure()
    team_slug = prompt("Netlify Team slug (optional; Enter to use your personal team)", default="").strip() or None

    try:
        site = maybe_create_netlify_site(gh_owner, gh_repo, branch="main", token=netlify_token, team_slug=team_slug)
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
        # (Docs citations about API & permissions are in the chat above.)

    print("\n✅ Deploy complete.")

if __name__ == "__main__":
    main()
