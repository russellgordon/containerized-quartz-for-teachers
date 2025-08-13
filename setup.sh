#!/bin/bash
set -euo pipefail

# -------------------- Defaults --------------------
HUB_USER="rwhgrwhg"
DEFAULT_TAG="latest"
IMAGE_NAME="teaching-quartz"
CONTAINER_NAME="teaching-quartz"
HOST_PORT=8081
CONTAINER_PORT=8081

# -------------------- Config (from flags) --------------------
TAG="$DEFAULT_TAG"
FORCE_UPDATE_IMAGE="false"
PASSTHRU_ARGS=()
PULL_STATUS=""

# -------------------- Help text --------------------
print_help() {
  cat <<EOF
Usage: ./setup.sh [options] [-- <args passed to setup_course.py>]

Options:
  --tag TAG            Use a specific tag instead of 'latest'
                       Default: ${DEFAULT_TAG}
  --update-image       Force pulling the image and recreating the container to use it.
  --no-backup          (Pass-through to setup_course.py) Skip creating a backup ZIP — you will be asked to confirm.
  --help               Show this help and exit.

Notes:
- This script will always pull from the public Docker Hub image:
    ${HUB_USER}/${IMAGE_NAME}
  Tag defaults to 'latest' unless overridden with --tag.
- Because the repo is public, no Docker Hub account is needed.
- Any arguments after a literal “--” are forwarded directly to setup_course.py.

Examples:
  ./setup.sh
  ./setup.sh --tag v2025.08.13
  ./setup.sh --update-image
  ./setup.sh -- --no-backup
EOF
}

# -------------------- Arg parsing --------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      print_help
      exit 0
      ;;
    --tag)
      if [[ $# -lt 2 ]]; then
        echo "❌ --tag requires a value" >&2
        exit 1
      fi
      TAG="$2"
      shift 2
      ;;
    --update-image)
      FORCE_UPDATE_IMAGE="true"
      shift
      ;;
    --)
      shift
      PASSTHRU_ARGS+=("$@")
      break
      ;;
    *)
      PASSTHRU_ARGS+=("$1")
      shift
      ;;
  esac
done

IMAGE="${HUB_USER}/${IMAGE_NAME}:${TAG}"

# -------------------- Pre-flight checks --------------------
cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker is not installed or not on PATH. Please install Docker Desktop first."
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker daemon not reachable. Please open Docker Desktop and try again."
  exit 1
fi

HOST_ARCH=$(docker info --format '{{.Architecture}}' 2>/dev/null || echo "unknown")
HOST_OS=$(docker info --format '{{.OSType}}' 2>/dev/null || echo "unknown")
echo "🧭 Host detected by Docker: ${HOST_OS}/${HOST_ARCH}"
echo "🖼️  Using image: ${IMAGE}"

# -------------------- Folders & permissions --------------------
if [ ! -d "courses" ]; then
  echo "📁 Creating 'courses' directory on host..."
  mkdir -p courses
fi
if [ ! -d "courses/_backups" ]; then
  echo "📦 Creating 'courses/_backups' directory on host..."
  mkdir -p courses/_backups
fi
chmod a+rwx courses
chmod a+rwx courses/_backups

# -------------------- Pull image if needed --------------------
IMAGE_PRESENT="false"
if docker image inspect "$IMAGE" >/dev/null 2>&1; then
  IMAGE_PRESENT="true"
fi

if [[ "$FORCE_UPDATE_IMAGE" == "true" ]]; then
  echo "🔄 --update-image passed: pulling latest for $IMAGE…"
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

# -------------------- Create/start container --------------------
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
  CURRENT_IMAGE=$(docker inspect -f '{{.Config.Image}}' "$CONTAINER_NAME" || echo "")
  if [[ "$FORCE_UPDATE_IMAGE" == "true" || "$CURRENT_IMAGE" != "$IMAGE" ]]; then
    echo "♻️  Recreating container $CONTAINER_NAME to use image: $IMAGE"
    if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
      docker stop "$CONTAINER_NAME" >/dev/null
    fi
    docker rm "$CONTAINER_NAME" >/dev/null || true
    docker run -dit \
      --name "$CONTAINER_NAME" \
      -v "$(pwd)/courses":/teaching/courses \
      -p ${HOST_PORT}:${CONTAINER_PORT} \
      "$IMAGE" \
      tail -f /dev/null
  else
    if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
      echo "🛑 Stopping running container $CONTAINER_NAME to refresh volume mount..."
      docker stop "$CONTAINER_NAME" >/dev/null
    fi
    echo "🚀 Starting existing container $CONTAINER_NAME..."
    docker start "$CONTAINER_NAME" >/dev/null
  fi
else
  echo "🚀 Creating a new container named $CONTAINER_NAME (image: $IMAGE)…"
  docker run -dit \
    --name "$CONTAINER_NAME" \
    -v "$(pwd)/courses":/teaching/courses \
    -p ${HOST_PORT}:${CONTAINER_PORT} \
    "$IMAGE" \
    tail -f /dev/null
fi

# -------------------- Backup confirmation (pass-through option) --------------------
HOST_TZ_OFFSET=$(date +%z)
echo "🕒 Detected host timezone offset: $HOST_TZ_OFFSET"
echo "🛟 Backups will be written to: $(pwd)/courses/_backups"

if printf '%s\n' "${PASSTHRU_ARGS[@]}" | grep -q -- "--no-backup"; then
  echo "⚠️  You are running with --no-backup."
  echo "    This will skip creating a safety ZIP before modifying course folders."
  read -p "❓ Are you sure you want to proceed without a backup? (yes/no) " CONFIRM
  case "$CONFIRM" in
    yes|y|Y) echo "Proceeding without backup...";;
    *) echo "❌ Cancelled."; exit 1;;
  esac
fi

# -------------------- Run setup inside container --------------------
echo "📚 Running setup_course.py inside the Docker container..."
docker exec -e HOST_TZ_OFFSET="$HOST_TZ_OFFSET" -it "$CONTAINER_NAME" \
  python3 /opt/scripts/setup_course.py "${PASSTHRU_ARGS[@]}"
