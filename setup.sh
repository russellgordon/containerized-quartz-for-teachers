#!/bin/bash
set -euo pipefail

# -------------------- Defaults --------------------
# The container publishes a small range so several previews can run at
# once — one per window in the app, each on its own port.
PREVIEW_PORT_RANGE="8081-8084"
# Each preview also uses a live-reload websocket on port + 1000.
PREVIEW_WS_RANGE="9081-9084"
# -------------------- Config (from flags) --------------------
declare -a PASSTHRU_ARGS=()      # ensure array is declared even on older bash
OVERRIDE_IMAGE=""                # full image override (mostly for verify.sh)
DOCKER_CONTEXT_OVERRIDE=""       # optional docker context override

# -------------------- Help text --------------------
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
_SETUP_HOST_OS="$(_detect_host_os)"
if [[ "$_SETUP_HOST_OS" == "windows" ]]; then
  SELF_CMD=".\\setup.bat"
else
  SELF_CMD="./setup.sh"
fi
# ----------------------------------------------------------------------
print_help() {
  cat <<EOF
Usage: ${SELF_CMD} [options] [-- <args passed to setup_course.py>]

Options:
  --image REF          Use a specific already-built image instead of building
                       from this folder's recipe (used by verify.sh).
  --context NAME       Use a specific Docker context (sets DOCKER_CONTEXT=NAME for this run).
  --no-backup          (Pass-through to setup_course.py) Skip creating a backup ZIP — you will be asked to confirm.
  --help               Show this help and exit.

Notes:
- The website builder image is built LOCALLY from this folder's recipe
  (.toolchain/, or the Dockerfile in a repository copy). The image tag is a
  hash of the recipe, so an updated recipe rebuilds automatically. The first
  build needs an internet connection and takes a few minutes; after that it
  is cached.
- Any arguments after a literal “--” are forwarded directly to setup_course.py.

Examples:
  ${SELF_CMD}
  ${SELF_CMD} --image quartz-teacher:dev-test
  ${SELF_CMD} -- --no-backup
EOF
}

# -------------------- Arg parsing --------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) print_help; exit 0 ;;
    --image)
      if [[ $# -lt 2 ]]; then echo "❌ --image requires a value" >&2; exit 1; fi
      OVERRIDE_IMAGE="$2"; shift 2 ;;
    --context)
      if [[ $# -lt 2 ]]; then echo "❌ --context requires a value (e.g., desktop-linux, default, colima)" >&2; exit 1; fi
      DOCKER_CONTEXT_OVERRIDE="$2"; shift 2 ;;
    --) shift; PASSTHRU_ARGS+=("$@"); break ;;
    *) PASSTHRU_ARGS+=("$1"); shift ;;
  esac
done

# -------------------- Pre-flight: context --------------------
if [[ -n "$DOCKER_CONTEXT_OVERRIDE" ]]; then
  export DOCKER_CONTEXT="$DOCKER_CONTEXT_OVERRIDE"
fi

# -------------------- Pre-flight checks --------------------
cd "$(dirname "$0")"

# ---- One container per working folder --------------------------------
# The container's name is derived from THIS folder, so two working folders
# (this year's courses and last year's, say) each get their own container
# and never repoint each other's mounts. The same derivation is used by
# the macOS app; the trailing newline from pwd is part of the hashed
# input, so keep `pwd -P | shasum` exactly as written.
WORKDIR_ID="$(pwd -P | shasum -a 256 | cut -c1-8)"
CONTAINER_NAME="teaching-quartz-${WORKDIR_ID}"

# ---- The image is built HERE, from this folder's own recipe ----------
# The tag is a hash of the recipe's contents: a changed recipe means a new
# tag, a fresh local build, and a recreated container. No registry, no
# account — the recipe travels with the app (or the repository).
resolve_build_context() {
  if [[ -f "./Dockerfile" ]]; then
    echo "."
  elif [[ -f "./.toolchain/Dockerfile" ]]; then
    echo "./.toolchain"
  else
    return 1
  fi
}

toolchain_hash() {
  local context="$1"
  (cd "$context" && find . -type f -not -path './.git/*' -not -name '.DS_Store' \
    | LC_ALL=C sort \
    | while IFS= read -r file; do shasum -a 256 "$file"; done \
    | shasum -a 256 | cut -c1-8)
}

BUILD_CONTEXT=""
if [[ -n "$OVERRIDE_IMAGE" ]]; then
  IMAGE="$OVERRIDE_IMAGE"
else
  BUILD_CONTEXT=$(resolve_build_context) || {
    echo "❌ This folder is missing the toolchain's build recipe."
    echo "   Open the folder in the app once to refresh it, or run from a"
    echo "   copy of the repository."
    exit 1
  }
  IMAGE="teaching-quartz:src-$(toolchain_hash "$BUILD_CONTEXT")"
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

CURRENT_CONTEXT=$(docker context show 2>/dev/null || echo "unknown")
HOST_ARCH=$(docker info --format '{{.Architecture}}' 2>/dev/null || echo "unknown")
HOST_OS=$(docker info --format '{{.OSType}}' 2>/dev/null || echo "unknown")
echo "🔌 Docker context: ${CURRENT_CONTEXT}"
echo "🧭 Host detected by Docker: ${HOST_OS}/${HOST_ARCH}"
echo "🖼️  Using image: ${IMAGE}"

# -------------------- Folders & permissions --------------------
CREATED_COURSES_DIR="false"
if [[ ! -d "courses" ]]; then
  echo "📁 Creating 'courses' directory on host..."
  mkdir -p courses
  CREATED_COURSES_DIR="true"
fi
if [[ ! -d "courses/_backups" ]]; then
  echo "📦 Creating 'courses/_backups' directory on host..."
  mkdir -p courses/_backups
fi
# Relax perms so container user can write even if UID/GID differ; strip odd ACLs on macOS (no-op elsewhere)
chmod -R u+rwX,go+rwX courses || true
chmod -R -N courses 2>/dev/null || true

# Compute the desired host mount path for this run
HOST_COURSES="$(pwd)/courses"

# -------------------- Build the image when it is missing --------------------
build_image_if_missing() {
  if docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "✅ Website builder is ready."
    return 0
  fi
  if [[ -z "$BUILD_CONTEXT" ]]; then
    echo "❌ Image '$IMAGE' is not on this machine."
    echo "   Build it first, e.g.: docker buildx build --load -t $IMAGE ."
    exit 1
  fi
  echo "🧱 Building your website builder — the first time takes a few minutes…"
  local build_cmd=(docker buildx build --load)
  if ! docker buildx version >/dev/null 2>&1; then
    # BuildKit either way: the legacy builder silently mangles the
    # export-scripts layer.
    build_cmd=(env DOCKER_BUILDKIT=1 docker build)
  fi
  if "${build_cmd[@]}" --progress=plain -t "$IMAGE" "$BUILD_CONTEXT"; then
    echo "✅ Website builder built."
  else
    echo "❌ Could not build the website builder."
    echo "   The first build needs an internet connection — try again once online."
    exit 1
  fi
}
build_image_if_missing

# -------------------- Writability probe helper --------------------
probe_container_write() {
  # Returns 0 if we can create & delete a file inside /teaching/courses
  docker exec "$CONTAINER_NAME" sh -lc \
    'mkdir -p /teaching/courses &&
     echo ok >/teaching/courses/.write_probe &&
     rm -f /teaching/courses/.write_probe'
}

# A container keeps running the version it was created from, so an update
# only takes effect once the container itself is recreated.
DESIRED_IMAGE_ID=$(docker image inspect --format '{{.Id}}' "$IMAGE" 2>/dev/null || echo "")
RUNNING_IMAGE_ID=$(docker inspect -f '{{.Image}}' "$CONTAINER_NAME" 2>/dev/null || echo "")

# -------------------- Create/start container (mount-aware, with refresh-on-new-courses) --------------------
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
  # Container exists. Check its current /teaching/courses mount.
  CURRENT_MOUNT_SRC=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/teaching/courses"}}{{.Source}}{{end}}{{end}}' "$CONTAINER_NAME" 2>/dev/null || echo "")
  if [[ -z "$CURRENT_MOUNT_SRC" ]]; then
    echo "🧯 Existing container has no /teaching/courses mount; recreating with correct mount…"
    if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then docker stop "$CONTAINER_NAME" >/dev/null; fi
    docker rm "$CONTAINER_NAME" >/dev/null || true
    run_container_with_mount
  elif [[ "$CURRENT_MOUNT_SRC" != "$HOST_COURSES" ]]; then
    echo "🔀 Detected different working directory:"
    echo "   • Existing mount: $CURRENT_MOUNT_SRC"
    echo "   • Desired mount:  $HOST_COURSES"
    echo "♻️  Recreating container '$CONTAINER_NAME' to point at the new folder…"
    if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then docker stop "$CONTAINER_NAME" >/dev/null; fi
    docker rm "$CONTAINER_NAME" >/dev/null || true
    run_container_with_mount
  elif [[ -n "$DESIRED_IMAGE_ID" && -n "$RUNNING_IMAGE_ID" && "$RUNNING_IMAGE_ID" != "$DESIRED_IMAGE_ID" ]]; then
    echo "♻️  Your workspace was built from an older version; rebuilding it so the update takes effect…"
    if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then docker stop "$CONTAINER_NAME" >/dev/null; fi
    docker rm "$CONTAINER_NAME" >/dev/null || true
    run_container_with_mount
  elif ! docker inspect -f '{{json .HostConfig.PortBindings}}' "$CONTAINER_NAME" 2>/dev/null | grep -q '9084/tcp'; then
    # An older container publishes only 8081; published ports cannot be
    # changed after creation, so recreating is how the range arrives.
    echo "♻️  Rebuilding your workspace so several previews can run at once…"
    if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then docker stop "$CONTAINER_NAME" >/dev/null; fi
    docker rm "$CONTAINER_NAME" >/dev/null || true
    run_container_with_mount
  else
    # Mounts match; only start if not already running
    if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
      # If courses/ was freshly created, refresh to ensure a clean, writable mount
      if [[ "$CREATED_COURSES_DIR" == "true" ]]; then
        echo "🔁 'courses/' was created just now; refreshing container to ensure a clean, writable mount…"
        docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
        run_container_with_mount
      else
        # Probe writability; if not writable, recreate
        if ! probe_container_write; then
          echo "🛑 Mounted 'courses/' is not writable from the container — recreating it…"
          docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
          run_container_with_mount
        else
          echo "✅ Container $CONTAINER_NAME is already running with correct, writable mount."
        fi
      fi
    else
      echo "▶️  Starting existing container $CONTAINER_NAME..."
      docker start "$CONTAINER_NAME" >/dev/null
      # After start, probe writability just in case
      if ! probe_container_write; then
        echo "🛑 Mounted 'courses/' is not writable from the container after start — recreating it…"
        docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
        run_container_with_mount
      fi
    fi
  fi
else
  echo "🆕 Creating a new container named $CONTAINER_NAME (image: $IMAGE)…"
  run_container_with_mount
fi

# -------------------- Backup confirmation (pass-through option) --------------------
HOST_TZ_OFFSET=$(date +%z)
echo "🕒 Detected host timezone offset: $HOST_TZ_OFFSET"
echo "🛟 Backups will be written to: $(pwd)/courses/_backups"

# Only test for --no-backup if there are any passthrough args
if ((${#PASSTHRU_ARGS[@]})) && printf '%s\n' "${PASSTHRU_ARGS[@]}" | grep -q -- "--no-backup"; then
  echo "⚠️ You are running with --no-backup."
  echo "   This will skip creating a safety ZIP before modifying course folders."
  read -p "❓ Are you sure you want to proceed without a backup? (yes/no) " CONFIRM
  case "$CONFIRM" in
    yes|y|Y) echo "Proceeding without backup...";;
    *) echo "❌ Cancelled."; exit 1;;
  esac
fi

# -------------------- Run setup inside container --------------------
echo "📚 Running setup_course.py inside the Docker container..."
# Ensure the container knows the host OS (mac). Users never need to pass this.
# If someone did pass --host-os already, strip it and override to mac.
if ((${#PASSTHRU_ARGS[@]})); then
  _cleaned=()
  _skip_next=0
  for _a in "${PASSTHRU_ARGS[@]}"; do
    if (( _skip_next )); then _skip_next=0; continue; fi
    if [[ "$_a" == "--host-os" ]]; then _skip_next=1; continue; fi
    if [[ "$_a" == --host-os=* ]]; then continue; fi
    _cleaned+=("$_a")
  done
  PASSTHRU_ARGS=("${_cleaned[@]}")
fi
PASSTHRU_ARGS+=("--host-os" "mac")

docker exec -e HOST_TZ_OFFSET="$HOST_TZ_OFFSET" -it "$CONTAINER_NAME" \
  python3 /opt/scripts/setup_course.py ${PASSTHRU_ARGS+"${PASSTHRU_ARGS[@]}"}
