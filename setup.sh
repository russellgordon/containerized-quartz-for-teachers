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
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker is not installed or not on PATH. Please install Docker Desktop first."
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker daemon not reachable.
Please open Docker Desktop and try again."
  exit 1
fi
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
    echo "⬇️  --update-image passed: pulling latest for $IMAGE…"
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
