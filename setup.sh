#!/bin/bash
set -euo pipefail

# -------------------- Defaults --------------------
HUB_USER="rwhgrwhg"
DEFAULT_TAG="latest"
IMAGE_NAME="teaching-quartz"
CONTAINER_NAME="teaching-quartz"
HOST_PORT=8081
CONTAINER_PORT=8081
DEV_IMAGE="quartz-teacher:dev"   # convenient local dev image

# -------------------- Config (from flags) --------------------
TAG="$DEFAULT_TAG"
FORCE_UPDATE_IMAGE="false"
declare -a PASSTHRU_ARGS=()      # ensure array is declared even on older bash
PULL_STATUS=""
OVERRIDE_IMAGE=""                # full image override
USE_LOCAL_DEV="false"            # toggle for local dev image
SKIP_PULL="false"                # skip pulling when using local images
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
  --tag TAG            Use a specific tag instead of 'latest' (default: ${DEFAULT_TAG})
  --update-image       Force pulling the image and recreating the container to use it.
  --image REF          Use a specific image reference (overrides Docker Hub default).
                       Examples: ghcr.io/me/teaching-quartz:main | ${DEV_IMAGE}
                       Note: If REF has no '/', it's treated as a local image and won't be pulled.
  --local-dev          Shortcut for --image "${DEV_IMAGE}" and skipping docker pull
                       (use after building locally with: docker build -t ${DEV_IMAGE} .)
  --context NAME       Use a specific Docker context (sets DOCKER_CONTEXT=NAME for this run).
  --no-backup          (Pass-through to setup_course.py) Skip creating a backup ZIP — you will be asked to confirm.
  --help               Show this help and exit.

Notes:
- By default this script pulls from the public Docker Hub image: ${HUB_USER}/${IMAGE_NAME}
  Tag defaults to 'latest' unless overridden with --tag.
- Use --local-dev to test your locally built image (${DEV_IMAGE}) without pulling.
- Any arguments after a literal “--” are forwarded directly to setup_course.py.

Examples:
  ${SELF_CMD}
  ${SELF_CMD} --tag v2025.08.13
  ${SELF_CMD} --update-image
  ${SELF_CMD} --image ghcr.io/acme/teaching-quartz:edge
  ${SELF_CMD} --local-dev
  ${SELF_CMD} --context desktop-linux --local-dev
  ${SELF_CMD} -- --no-backup
EOF
}

# -------------------- Arg parsing --------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) print_help; exit 0 ;;
    --tag)
      if [[ $# -lt 2 ]]; then echo "❌ --tag requires a value" >&2; exit 1; fi
      TAG="$2"; shift 2 ;;
    --update-image) FORCE_UPDATE_IMAGE="true"; shift ;;
    --image)
      if [[ $# -lt 2 ]]; then echo "❌ --image requires a value" >&2; exit 1; fi
      OVERRIDE_IMAGE="$2"; shift 2 ;;
    --local-dev) USE_LOCAL_DEV="true"; shift ;;
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

# -------------------- Resolve image to use --------------------
if [[ "$USE_LOCAL_DEV" == "true" ]]; then
  OVERRIDE_IMAGE="$DEV_IMAGE"
  SKIP_PULL="true"
fi
# If user overrides the image and it looks like a local ref (no registry/user prefix), skip pull by default.
if [[ -n "$OVERRIDE_IMAGE" && "$OVERRIDE_IMAGE" != */* ]]; then
  SKIP_PULL="true"
fi
if [[ -n "$OVERRIDE_IMAGE" ]]; then
  IMAGE="$OVERRIDE_IMAGE"
else
  IMAGE="${HUB_USER}/${IMAGE_NAME}:${TAG}"
fi

# -------------------- Pre-flight checks --------------------
cd "$(dirname "$0")"

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

# -------------------- Pull or verify image presence --------------------
IMAGE_PRESENT="false"
if docker image inspect "$IMAGE" >/dev/null 2>&1; then
  IMAGE_PRESENT="true"
fi
# If not present by exact ref, try to discover close matches (helps with local naming quirks)
if [[ "$IMAGE_PRESENT" == "false" ]]; then
  # Gather candidates like quartz-teacher:* if IMAGE is quartz-teacher:dev
  REPO="${IMAGE%%:*}"
  TAG_PART="${IMAGE#*:}"
  CANDIDATES=$(docker image ls --format '{{.Repository}}:{{.Tag}}' "$REPO" 2>/dev/null | grep -i "${TAG_PART}" || true)
  if [[ -n "$CANDIDATES" ]]; then
    echo "ℹ️  Found local candidates for '$IMAGE' in context '${CURRENT_CONTEXT}':"
    echo "$CANDIDATES" | sed 's/^/   • /'
    # If there is an exact case-insensitive match among candidates, use it
    MATCH=$(echo "$CANDIDATES" | awk -v want="$IMAGE" 'BEGIN{IGNORECASE=1} $0==want{print $0}')
    if [[ -n "$MATCH" ]]; then
      IMAGE_PRESENT="true"
      IMAGE="$MATCH"
      echo "✅ Using exact local match: $IMAGE"
    fi
  fi
fi

if [[ "$SKIP_PULL" == "true" ]]; then
  if [[ "$IMAGE_PRESENT" == "true" ]]; then
    echo "✅ Using local image: $IMAGE"
    PULL_STATUS="(local image)"
  else
    echo "❌ Local image '$IMAGE' not found in Docker context '${CURRENT_CONTEXT}'."
    echo "   Tips:"
    echo "   • If you built with buildx, make sure you used --load to import into the local engine:"
    echo "     docker buildx build --load -t $IMAGE ."
    echo "     (or use classic build:)"
    echo "     docker build -t $IMAGE ."
    echo "   • Verify your context matches where you built:"
    echo "     docker context ls"
    echo "     docker context show"
    echo "   • List matching local images:"
    echo "     docker image ls $REPO"
    exit 1
  fi
else
  if [[ "$FORCE_UPDATE_IMAGE" == "true" ]]; then
    echo "⬇️  --update-image passed: pulling latest for ${IMAGE}…"
    docker pull "$IMAGE"
    PULL_STATUS="(just pulled)"
  elif [[ "$IMAGE_PRESENT" == "false" ]]; then
    echo "⬇️  Image not found locally. Pulling $IMAGE …"
    docker pull "$IMAGE"
    PULL_STATUS="(just pulled)"
  else
    echo "✅ Image already present: $IMAGE"
    PULL_STATUS="(already on this machine)"
  fi
fi

# -------------------- Helper: (re)run container with desired mount --------------------
run_container_with_mount() {
  echo "🔗 Binding host courses to container: $HOST_COURSES ➜ /teaching/courses"
  docker run -dit \
    --name "$CONTAINER_NAME" \
    -v "$HOST_COURSES":/teaching/courses \
    -p ${HOST_PORT}:${CONTAINER_PORT} \
    "$IMAGE" \
    tail -f /dev/null
}

# -------------------- Offer a newer version, if one exists --------------------
# An image already on the machine was never checked again, so a teacher kept
# whatever they first downloaded and fixes never reached them.
registry_digest_of() {
  docker buildx imagetools inspect "$1" --format '{{.Manifest.Digest}}' 2>/dev/null || true
}

installed_digest_of() {
  local repo_digest
  repo_digest=$(docker image inspect "$1" --format '{{if .RepoDigests}}{{index .RepoDigests 0}}{{end}}' 2>/dev/null || true)
  echo "${repo_digest#*@}"
}

offer_newer_image() {
  local ref="$1"
  # A locally built image has no registry to ask about it.
  case "$ref" in */*) ;; *) return 0 ;; esac

  local available installed answer
  available="$(registry_digest_of "$ref")"
  installed="$(installed_digest_of "$ref")"
  # Offline, or nothing to compare: carry on with what is here.
  if [[ -z "$available" || -z "$installed" || "$available" == "$installed" ]]; then
    return 0
  fi

  echo "🆕 A newer version of the website builder is available."
  if [[ ! -t 0 ]]; then
    echo "   Run '${SELF_CMD} --update-image' when you would like to install it."
    return 0
  fi
  read -r -p "   Install it now? (y/n) [Default: y]: " answer || answer=""
  case "${answer:-y}" in
    [Nn]*)
      echo "   Keeping the version you have."
      return 0
      ;;
  esac
  echo "⬇️  Installing the newer version…"
  docker pull "$ref"
  PULL_STATUS="(just updated)"
}

if [[ "$SKIP_PULL" != "true" && "$FORCE_UPDATE_IMAGE" != "true" && "$IMAGE_PRESENT" == "true" ]]; then
  offer_newer_image "$IMAGE"
fi

# -------------------- Show image version/build info --------------------
show_image_info() {
  local img="$1"
  local ver created rev src title
  ver=$(docker image inspect "$img" --format '{{index .Config.Labels "org.opencontainers.image.version"}}' 2>/dev/null || true)
  created=$(docker image inspect "$img" --format '{{index .Config.Labels "org.opencontainers.image.created"}}' 2>/dev/null || true)
  rev=$(docker image inspect "$img" --format '{{index .Config.Labels "org.opencontainers.image.revision"}}' 2>/dev/null || true)
  src=$(docker image inspect "$img" --format '{{index .Config.Labels "org.opencontainers.image.source"}}' 2>/dev/null || true)
  title=$(docker image inspect "$img" --format '{{index .Config.Labels "org.opencontainers.image.title"}}' 2>/dev/null || true)
  if [[ -z "${ver}" ]]; then ver="(no version label)"; fi
  if [[ -z "${created}" ]]; then created=$(docker image inspect "$img" --format '{{.Created}}' 2>/dev/null || echo ""); fi
  if [[ -z "${rev}" ]]; then rev="(no revision label)"; fi
  if [[ -z "${title}" ]]; then title="$img"; fi
  local digests
  digests=$(docker image inspect "$img" --format '{{range .RepoDigests}}{{.}}{{"\n"}}{{end}}' 2>/dev/null || true)

  echo "ℹ️  Image info ${PULL_STATUS}:"
  echo "   • Title:      ${title}"
  echo "   • Version:    ${ver}"
  echo "   • Created:    ${created}"
  echo "   • Revision:   ${rev}"
  [[ -n "$src" ]] && echo "   • Source:     ${src}"
  if [[ -n "$digests" ]]; then
    echo "   • Digests:"
    echo "$digests" | sed 's/^/     - /'
  fi
}
show_image_info "$IMAGE"

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
