#!/usr/bin/env bash
set -euo pipefail

# Ensure we're in the same directory as this script
cd "$(dirname "$0")"

CONTAINER_NAME="teaching-quartz"

# Image resolution (same rules as setup.sh and preview.sh). Without this,
# creating a container here used the bare name "teaching-quartz", which
# Docker reads as an official library image that does not exist — so a
# machine with no container yet could not publish at all.
HUB_USER="${HUB_USER:-rwhgrwhg}"
DEFAULT_TAG="${DEFAULT_TAG:-latest}"
IMAGE_NAME="${IMAGE_NAME:-teaching-quartz}"
DEV_IMAGE="${DEV_IMAGE:-quartz-teacher:dev}"
TAG="${TAG:-$DEFAULT_TAG}"
USE_LOCAL_DEV="false"
OVERRIDE_IMAGE="${OVERRIDE_IMAGE:-}"

# Defaults so help can expand under `set -u` before OS detection
SELF_CMD="./deploy.sh"
PREVIEW_CMD="./preview.sh"

usage() {
  cat <<USAGE
🧰 Usage:
  ${SELF_CMD} <COURSE_CODE> <SECTION_NUMBER> [--diagnose] [--team <TEAM_SLUG>] [--reset-token|--logout] [--image REF] [--dev]

Examples:
  ${SELF_CMD} ICS3U 1
  ${SELF_CMD} ICS3U 1 --diagnose
  ${SELF_CMD} ICS3U 1 --team my-org-slug

Notes:
- Deploys from /teaching/courses/<COURSE>/.merged_output/section<SECTION> inside the container.
- You must build first (the static site goes to 'public/' in that section folder).
- The Netlify Personal Access Token (PAT) is stored in the macOS Keychain and injected securely at runtime.
- Use --reset-token (or --logout) to remove the saved PAT and re-link on next run.
- --image REF publishes using a particular build; --dev uses the local ${DEV_IMAGE}.
  Both matter only when no container exists yet, since an existing one is reused.
- If your course code ends with '0' (zero), you'll be prompted to correct it to 'O' for Open-level courses.
USAGE
}

# ---- Determine host OS for help text ---------------------------------
_detect_host_os() {
  local u
  u="$(uname -s 2>/dev/null || echo "")"
  case "$u" in
    Darwin) echo mac ;;
    MINGW*|MSYS*|CYGWIN*) echo windows ;;
    *) echo linux ;;
  esac
}
_DEPLOY_HOST_OS="$(_detect_host_os)"
if [[ "$_DEPLOY_HOST_OS" == "windows" ]]; then
  SELF_CMD=".\\deploy.bat"
  PREVIEW_CMD=".\\preview.bat"
else
  SELF_CMD="./deploy.sh"
  PREVIEW_CMD="./preview.sh"
fi
# ----------------------------------------------------------------------

if [[ $# -lt 2 ]]; then usage; exit 1; fi

COURSE_CODE="$1"; shift
SECTION_NUM="$1"; shift

# Normalize course code to uppercase
COURSE_CODE="$(printf '%s' "$COURSE_CODE" | tr '[:lower:]' '[:upper:]')"

# Friendly guard: 'Open' course code ended with zero
if [[ "$COURSE_CODE" =~ ^[A-Z]{3}[0-9]0$ ]]; then
  SUGGESTED="${COURSE_CODE%0}O"
  echo ""
  echo " It looks like you entered '${COURSE_CODE}' (ends with zero)."
  echo " Ontario 'Open' level course codes end with the LETTER 'O' (oh)."
  if [[ -f "courses/$SUGGESTED/course_config.json" && ! -f "courses/$COURSE_CODE/course_config.json" ]]; then
    echo " I see setup data for '$SUGGESTED' on disk."
  fi
  read -rp " Fix course code to '$SUGGESTED'? [Y/n]: " _ans
  _ans="${_ans:-Y}"
  if [[ "$_ans" =~ ^[Yy]$ ]]; then
    COURSE_CODE="$SUGGESTED"
    echo "✅ Using corrected course code: $COURSE_CODE"
  else
    echo "ℹ️ Continuing with: $COURSE_CODE"
  fi
  echo ""
fi

# Parse flags
DIAGNOSE=""
TEAM_SLUG=""
RESET_TOKEN="false"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --diagnose) DIAGNOSE="--diagnose" ;;
    --team|--team-slug)
      if [[ $# -lt 2 ]]; then echo "❌ Missing value for $1"; echo; usage; exit 1; fi
      TEAM_SLUG="$2"; shift ;;
    --team=*|--team-slug=*)
      TEAM_SLUG="${1#*=}" ;;
    --reset-token|--logout)
      RESET_TOKEN="true" ;;
    --image)
      if [[ $# -lt 2 ]]; then echo "❌ Missing value for $1"; echo; usage; exit 1; fi
      OVERRIDE_IMAGE="$2"; shift ;;
    --image=*)
      OVERRIDE_IMAGE="${1#*=}" ;;
    --dev|--local-dev)
      USE_LOCAL_DEV="true" ;;
    --help|-h)
      usage; exit 0 ;;
    *)
      echo "❌ Unknown option: $1"; echo; usage; exit 1 ;;
  esac
  shift
done

# Resolve IMAGE (same rules as setup.sh and preview.sh)
if [[ "$USE_LOCAL_DEV" == "true" ]]; then
  IMAGE="$DEV_IMAGE"
elif [[ -n "$OVERRIDE_IMAGE" ]]; then
  IMAGE="$OVERRIDE_IMAGE"
else
  IMAGE="${HUB_USER}/${IMAGE_NAME}:${TAG}"
fi

# Host-side paths (bind-mounted into the container at /teaching/courses)
COURSE_DIR_HOST="$(pwd)/courses/${COURSE_CODE}"
MERGED_DIR_HOST="${COURSE_DIR_HOST}/.merged_output"
SECTION_DIR_HOST="${MERGED_DIR_HOST}/section${SECTION_NUM}"
PUBLIC_DIR_HOST="${SECTION_DIR_HOST}/public"

# Detect host timezone offset in ±HHMM format
HOST_TZ_OFFSET="$(date +%z)"
echo "🕒 Host timezone offset: $HOST_TZ_OFFSET"

# Preflight checks
if [[ ! -d "${COURSE_DIR_HOST}" ]]; then
  echo "❌ Course folder not found on host:"
  echo " ${COURSE_DIR_HOST}"
  echo
  echo " Make sure you've run the course setup and/or preview steps."
  echo " Try: ${PREVIEW_CMD} ${COURSE_CODE} ${SECTION_NUM}"
  if [[ -d "$(pwd)/courses" ]]; then
    echo
    echo " Available course folders:"
    ls -1 "$(pwd)/courses" | sed 's/^/ - /'
  fi
  exit 1
fi

if [[ ! -d "${SECTION_DIR_HOST}" ]]; then
  echo "❌ Section directory not found on host:"
  echo " ${SECTION_DIR_HOST}"
  echo
  echo " You likely need to build the merged output first:"
  echo " ${PREVIEW_CMD} ${COURSE_CODE} ${SECTION_NUM}"
  if [[ -d "${MERGED_DIR_HOST}" ]]; then
    EXISTING_SECTIONS=$(ls -1d "${MERGED_DIR_HOST}"/section* 2>/dev/null | xargs -n1 basename || true)
    if [[ -n "${EXISTING_SECTIONS:-}" ]]; then
      echo
      echo " Existing merged sections for ${COURSE_CODE}:"
      echo "${EXISTING_SECTIONS}" | sed 's/^/ - /'
    fi
  fi
  exit 1
fi

if [[ ! -d "${PUBLIC_DIR_HOST}" || -z "$(ls -A "${PUBLIC_DIR_HOST}" 2>/dev/null || true)" ]]; then
  echo "❌ Built site not found at:"
  echo " ${PUBLIC_DIR_HOST}"
  echo
  echo " Build first:"
  echo " ${PREVIEW_CMD} ${COURSE_CODE} ${SECTION_NUM} --build-only"
  exit 1
fi

# -------------------- macOS Keychain token handling --------------------
if [[ "$_DEPLOY_HOST_OS" != "mac" ]]; then
  echo "❌ This script targets macOS. On Windows, use: .\\deploy.ps1"
  exit 1
fi

KEYCHAIN_SERVICE="containerized-quartz-netlify"
TOKENS_FILE="courses/.internal/tokens.json"
KEY_FILE="courses/.internal/.key"

get_token_keychain() {
  /usr/bin/security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$USER" -w 2>/dev/null || true
}
set_token_keychain() {
  /usr/bin/security add-generic-password -U -s "$KEYCHAIN_SERVICE" -a "$USER" -w "$1" >/dev/null
}
delete_token_keychain() {
  /usr/bin/security delete-generic-password -s "$KEYCHAIN_SERVICE" -a "$USER" >/dev/null 2>&1 || true
}
validate_token() {
  curl -fsS -H "Authorization: Bearer $1" https://api.netlify.com/api/v1/user >/dev/null
}

# ---- Legacy token readers/migration helpers --------------------------

# Try to decode the XOR+base64 obfuscated token using the per-user key file
read_legacy_token_xor() {
  [[ -f "$TOKENS_FILE" && -f "$KEY_FILE" ]] || return 1
  python3 - "$TOKENS_FILE" "$KEY_FILE" <<'PY'
import sys, json, base64, pathlib
tokens_path = pathlib.Path(sys.argv[1])
key_path    = pathlib.Path(sys.argv[2])
try:
    data = json.loads(tokens_path.read_text(encoding="utf-8"))
    entry = (data.get("tokens") or {}).get("netlify") or {}
    obf = entry.get("obf")
    if not obf:
        sys.exit(2)
    key = key_path.read_bytes()
    raw = base64.b64decode(obf)
    plain = bytes(b ^ key[i % len(key)] for i, b in enumerate(raw)).decode("utf-8")
    print(plain, end="")
except Exception:
    sys.exit(1)
PY
}

# Simple/older formats: pick any value under a key that mentions netlify/token
read_legacy_token_plain() {
  [[ -f "$TOKENS_FILE" ]] || return 1
  local line
  line="$(grep -Eoi '"[^"]*netlify[^"]*"[[:space:]]*:[[:space:]]*"[^"]+"' "$TOKENS_FILE" | head -n1 || true)"
  if [[ -z "$line" ]]; then
    line="$(grep -Eo '"(NETLIFY_AUTH_TOKEN|netlify_token|token)"[[:space:]]*:[[:space:]]*"[^"]+"' "$TOKENS_FILE" | head -n1 || true)"
  fi
  [[ -n "$line" ]] || return 1
  echo "$line" | sed -E 's/.*:[[:space:]]*"([^"]*)".*/\1/'
}

# After migrating, remove just the 'netlify' entry from tokens.json (delete file if empty)
prune_legacy_netlify_entry() {
  [[ -f "$TOKENS_FILE" ]] || return 0
  python3 - "$TOKENS_FILE" <<'PY'
import sys, json, pathlib
p = pathlib.Path(sys.argv[1])
try:
    data = json.loads(p.read_text(encoding="utf-8"))
    tokens = data.get("tokens") or {}
    if "netlify" in tokens:
        tokens.pop("netlify", None)
        if tokens:
            data["tokens"] = tokens
            p.write_text(json.dumps(data, indent=2), encoding="utf-8")
        else:
            p.unlink()
except Exception:
    pass
PY
}

if [[ "${RESET_TOKEN}" == "true" ]]; then
  echo "🔒 Clearing saved Netlify token from Keychain…"
  delete_token_keychain
  if [[ -f "$TOKENS_FILE" ]]; then
    echo "🧹 Removing legacy Netlify entry from: $TOKENS_FILE"
    prune_legacy_netlify_entry
  fi
  echo "Done. Next run will prompt to create/paste a new token."
  exit 0
fi

TOKEN="$(get_token_keychain || true)"

# If legacy file exists, try to migrate it (XOR+base64 scheme first)
if [[ -f "$TOKENS_FILE" ]]; then
  migrated="false"

  if [[ -z "$TOKEN" ]]; then
    if decoded="$(read_legacy_token_xor || true)"; then
      if [[ -n "${decoded:-}" ]] && validate_token "$decoded"; then
        set_token_keychain "$decoded"
        TOKEN="$decoded"
        echo "🔐 Migrated Netlify token (obfuscated) into macOS Keychain."
        prune_legacy_netlify_entry
        migrated="true"
      fi
    fi
  fi

  # Fallback: plain legacy heuristics
  if [[ "$migrated" != "true" && -z "$TOKEN" ]]; then
    legacy_plain="$(read_legacy_token_plain || true)"
    if [[ -n "${legacy_plain:-}" ]] && validate_token "$legacy_plain"; then
      set_token_keychain "$legacy_plain"
      TOKEN="$legacy_plain"
      echo "🔐 Migrated Netlify token into macOS Keychain."
      prune_legacy_netlify_entry
    elif [[ -z "${legacy_plain:-}" ]]; then
      echo "ℹ️ Legacy tokens file found, but no Netlify token key detected."
    else
      echo "⚠️ Legacy token value found, but it is invalid."
    fi
  fi
fi

# If still no token, prompt user to create one (quote-safe via here-doc)
if [[ -z "$TOKEN" ]]; then
  cat <<'MSG'

You need a Netlify Personal Access Token (PAT) to deploy.
1) Open this page: https://app.netlify.com/user/applications#personal-access-tokens
2) Create a new token.
   TIPS:
   a. Name it something like 'For class website deploys'
   b. Set the expiration time to 'No expiration'
3) Copy the generated token and paste it here.

MSG
  command -v open >/dev/null 2>&1 && open "https://app.netlify.com/user/applications#personal-access-tokens" || true
  echo ""
  read -rsp "Paste Netlify token: " pasted; echo
  if ! validate_token "$pasted"; then
    echo "❌ Token invalid (Netlify rejected it). Please try again."
    exit 1
  fi
  set_token_keychain "$pasted"
  TOKEN="$pasted"
  echo "✅ Saved token to macOS Keychain (service: ${KEYCHAIN_SERVICE})."
fi

# ==================== Container runtime (Colima) ====================
# Docker Desktop is no longer required. This script uses Colima
# (https://github.com/abiosoft/colima), a free, open-source container
# runtime for macOS, and installs/starts it automatically as needed.
# Any already-working Docker engine (including Docker Desktop) is used as-is.

_wait_for_docker() {
  local tries="${1:-30}"
  local i
  for ((i=0; i<tries; i++)); do
    docker info >/dev/null 2>&1 && return 0
    sleep 2
  done
  return 1
}

_install_brew_formula() {
  local formula="$1" cmd="$2" label="$3"
  local log; log="$(mktemp -t cq4t-brew)"
  echo "📦 Installing ${label}…"
  echo "   (quiet — this can take a minute, longer if Homebrew updates itself)"
  if ! HOMEBREW_NO_ASK=1 HOMEBREW_NO_ENV_HINTS=1 brew install --quiet "$formula" >"$log" 2>&1; then
    echo "❌ Could not install ${label}. Homebrew said:"
    sed 's/^/   /' "$log"
    rm -f "$log"
    echo "   Check your internet connection and re-run this script — it is safe to re-run."
    exit 1
  fi
  rm -f "$log"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ ${label} was installed, but the '${cmd}' command is not available in this Terminal."
    echo "   Close this Terminal window, open a new one, and re-run this script."
    exit 1
  fi
  echo "✅ ${label} installed."
}

ensure_container_runtime() {
  # Fast path: any working Docker daemon means there is nothing to do.
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    return 0
  fi

  echo "🐳 No running container runtime detected — using Colima…"

  if ! command -v brew >/dev/null 2>&1; then
    echo "❌ Homebrew is required to install Colima but is not installed."
    echo "   Install it by pasting this into Terminal, then re-run this script:"
    echo '   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
  fi

  command -v colima >/dev/null 2>&1 || _install_brew_formula colima colima "Colima (container runtime)"
  command -v docker >/dev/null 2>&1 || _install_brew_formula docker docker "Docker CLI"

  if [[ ! -d "$HOME/.colima/default" ]]; then
    echo "🚀 First start: building the Colima virtual machine (2 CPUs · 4 GB RAM)."
    echo "   The VM image (~600 MB) is downloaded once; this can take several minutes."
    colima start --cpu 2 --memory 4
  else
    echo "▶️  Starting Colima…"
    colima start
  fi

  echo "⏳ Waiting for the container runtime to be ready…"
  _wait_for_docker 30 && return 0

  # Colima can report the VM as running while its Docker daemon is dead
  # (common after sleep or an unclean shutdown); a plain start no-ops in
  # that state. Force a clean restart and wait again.
  echo "🔁 Docker isn't responding yet — restarting Colima…"
  echo "   (Colima is shared by any other Colima-based toolchains on this Mac;"
  echo "    their containers restart automatically afterwards if configured to.)"
  colima stop --force >/dev/null 2>&1 || true
  colima start >/dev/null 2>&1 || true
  _wait_for_docker 60 && return 0

  echo "❌ Colima did not become ready."
  echo "   Try running 'colima stop --force && colima start' by hand, then re-run this script."
  exit 1
}

ensure_container_runtime
# ====================================================================

# -------------------- Mount-aware container handling --------------------
HOST_COURSES="$(pwd)/courses"

ensure_image_present() {
  if docker image inspect "$IMAGE" >/dev/null 2>&1; then
    return 0
  fi
  # A reference without a "/" is a local build, so there is nowhere to get it.
  case "$IMAGE" in
    */*)
      echo "⬇️  Getting what your websites are built with ($IMAGE)…"
      docker pull "$IMAGE"
      ;;
    *)
      echo "❌ No local image named '$IMAGE'."
      echo "   Run ./setup.sh first, or build it with: docker build -t $IMAGE ."
      exit 1
      ;;
  esac
}

run_container_with_mount() {
  ensure_image_present
  echo " Binding host courses to container: $HOST_COURSES ➜ /teaching/courses"
  docker run -dit \
    --name "$CONTAINER_NAME" \
    -v "$HOST_COURSES":/teaching/courses \
    -p 8081:8081 \
    "$IMAGE" \
    tail -f /dev/null
}

probe_container_write() {
  docker exec "$CONTAINER_NAME" sh -lc 'mkdir -p /teaching/courses &&
    echo ok >/teaching/courses/.write_probe &&
    rm -f /teaching/courses/.write_probe'
}

echo " Ensuring container is running with the correct, writable mount..."
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
  CURRENT_MOUNT_SRC=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/teaching/courses"}}{{.Source}}{{end}}{{end}}' "$CONTAINER_NAME" 2>/dev/null || echo "")
  if [[ -z "$CURRENT_MOUNT_SRC" ]]; then
    echo " Existing container has no /teaching/courses mount; recreating with correct mount…"
    if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then docker stop "$CONTAINER_NAME" >/dev/null; fi
    docker rm "$CONTAINER_NAME" >/dev/null || true
    run_container_with_mount
  elif [[ "$CURRENT_MOUNT_SRC" != "$HOST_COURSES" ]]; then
    echo " Detected different working directory:"
    echo " • Existing mount: $CURRENT_MOUNT_SRC"
    echo " • Desired mount: $HOST_COURSES"
    echo "♻️ Recreating container '$CONTAINER_NAME' to point at the new folder…"
    if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then docker stop "$CONTAINER_NAME" >/dev/null; fi
    docker rm "$CONTAINER_NAME" >/dev/null || true
    run_container_with_mount
  else
    if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
      if ! probe_container_write; then
        echo " 🛑 Mounted 'courses/' is not writable from the container — recreating it…"
        docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
        run_container_with_mount
      else
        echo "✅ Container $CONTAINER_NAME is already running with correct, writable mount."
      fi
    else
      echo " Starting existing container $CONTAINER_NAME..."
      docker start "$CONTAINER_NAME" >/dev/null
      if ! probe_container_write; then
        echo " 🛑 Mounted 'courses/' is not writable from the container after start — recreating it…"
        docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
        run_container_with_mount
      fi
    fi
  fi
else
  echo " Creating new container named $CONTAINER_NAME with correct mount…"
  run_container_with_mount
fi

SECTION_DIR_IN_CONTAINER="/teaching/courses/${COURSE_CODE}/.merged_output/section${SECTION_NUM}"
echo "🚀 Deploying ${COURSE_CODE} S${SECTION_NUM} from: ${SECTION_DIR_IN_CONTAINER}"

# --- Securely inject token into container without exposing on host CLI ---
printf %s "$TOKEN" | docker exec -i "$CONTAINER_NAME" sh -lc 'umask 077; cat > /tmp/netlify_pat'

# Pass options via env to avoid fragile mixed quoting in sh -lc
docker exec -it \
  -e HOST_TZ_OFFSET="${HOST_TZ_OFFSET}" \
  -e DIAGNOSE="${DIAGNOSE}" \
  -e TEAM_SLUG="${TEAM_SLUG}" \
  "$CONTAINER_NAME" \
  sh -lc '
    tok=$(cat /tmp/netlify_pat); rm -f /tmp/netlify_pat;
    opts="";
    [ -n "$DIAGNOSE" ]  && opts="$opts $DIAGNOSE";
    [ -n "$TEAM_SLUG" ] && opts="$opts --team $TEAM_SLUG";
    NETLIFY_AUTH_TOKEN="$tok" \
      python3 /opt/scripts/deploy.py --host-os mac --course '"$COURSE_CODE"' --section '"$SECTION_NUM"' $opts
  '