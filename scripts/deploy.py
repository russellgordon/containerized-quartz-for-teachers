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
    if default:
        resp = input(f"{text} [{default}]: ").strip()
        return resp or default
    return input(f"{text}: ").strip()

def read_token_secure() -> str:
    import getpass
    print("\n🔐 A GitHub Personal Access Token (PAT) is required to create a repo and push.")
    print("   Where to generate a PAT in GitHub:")
    print("   • GitHub → your avatar (top-right) → Settings")
    print("   • Left sidebar → Developer settings → Personal access tokens")
    print("   • Choose “Tokens (classic)” → Generate new token (classic)")
    print("   • Scope: ‘repo’,‘workflow’.")
    print("   • Create by pressing green ‘Generate token’ button at bottom of page.")
    print("   Tip: Add a note to identify the token, something along the lines of 'Access for deploy script for EXC2O S1 2025'.")
    print("   Tip: Keep the token private; you can revoke it anytime in the same place.")
    print("   Tip: Select `No expiration` to avoid future loss of access to this repository by this script.")
    print("        Alternatively, use an expiration date at least one year into the future to avoid loss of access during the current school year.")
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

def main():
    p = argparse.ArgumentParser(description="Deploy a merged section folder to GitHub.")
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

    # Ensure Media is copied (not symlinked)
    copy_media_if_symlink(section_dir)

    # If we don't yet have a token and the origin uses HTTPS to GitHub, prompt now
    origin_after = git_remote_url(section_dir, "origin")
    if token_for_push is None and needs_pat_for_url(origin_after):
        token_for_push = read_token_secure()

    # Commit & push
    commit_and_push(section_dir, token_for_push)

    print("🎉 Deploy complete.")

if __name__ == "__main__":
    main()
