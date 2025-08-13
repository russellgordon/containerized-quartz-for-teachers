#!/usr/bin/env bash
set -euo pipefail

# ==================== Defaults ====================
HUB_USER_DEFAULT="rwhgrwhg"                 # hardcoded default; can override with --hub-user
IMAGE_DEFAULT="teaching-quartz"
PLATFORMS_DEFAULT="linux/amd64,linux/arm64"
DOCKERFILE_DEFAULT="Dockerfile"
CONTEXT_DEFAULT="."
NO_CACHE_DEFAULT="--no-cache"               # use --allow-cache to disable --no-cache

# ==================== Config (from flags) ====================
HUB_USER="$HUB_USER_DEFAULT"
IMAGE="$IMAGE_DEFAULT"
PLATFORMS="$PLATFORMS_DEFAULT"
DOCKERFILE="$DOCKERFILE_DEFAULT"
CONTEXT="$CONTEXT_DEFAULT"
NO_CACHE="$NO_CACHE_DEFAULT"
VERSION=""                                   # if empty, auto-generate vYYYY.MM.DD and -bN as needed

print_help() {
  cat <<EOF
Usage: ./publish.sh [options]

Build and push a multi-arch image to Docker Hub with smart date-based versioning.

Options:
  --hub-user NAME       Docker Hub username to push under (default: ${HUB_USER_DEFAULT})
  --image NAME          Image name/repo (default: ${IMAGE_DEFAULT})
  --version TAG         Explicit version tag (skips auto -bN logic)
  --platforms LIST      Platforms to build (default: ${PLATFORMS_DEFAULT})
  --file PATH           Dockerfile path (default: ${DOCKERFILE_DEFAULT})
  --context PATH        Build context directory (default: .)
  --allow-cache         Allow build cache (omit --no-cache)
  --help                Show this help and exit

Behavior:
- If --version is not provided, the script uses vYYYY.MM.DD.
  If that tag already exists on Docker Hub, it appends -b2, -b3, ... automatically.
- Also pushes the 'latest' tag to point to the newly built version.

Examples:
  ./publish.sh
  ./publish.sh --version v2025.08.13-b2
  ./publish.sh --hub-user myorg --image tq --file Dockerfile --context .
  ./publish.sh --platforms linux/amd64,linux/arm64
  ./publish.sh --allow-cache
EOF
}

# -------------------- Parse flags --------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      print_help; exit 0;;
    --hub-user)
      [[ $# -ge 2 ]] || { echo "❌ --hub-user requires a value"; exit 1; }
      HUB_USER="$2"; shift 2;;
    --image)
      [[ $# -ge 2 ]] || { echo "❌ --image requires a value"; exit 1; }
      IMAGE="$2"; shift 2;;
    --version)
      [[ $# -ge 2 ]] || { echo "❌ --version requires a value"; exit 1; }
      VERSION="$2"; shift 2;;
    --platforms)
      [[ $# -ge 2 ]] || { echo "❌ --platforms requires a value"; exit 1; }
      PLATFORMS="$2"; shift 2;;
    --file)
      [[ $# -ge 2 ]] || { echo "❌ --file requires a value"; exit 1; }
      DOCKERFILE="$2"; shift 2;;
    --context)
      [[ $# -ge 2 ]] || { echo "❌ --context requires a value"; exit 1; }
      CONTEXT="$2"; shift 2;;
    --allow-cache)
      NO_CACHE=""; shift;;
    *)
      echo "❌ Unknown option: $1"; echo; print_help; exit 1;;
  esac
done

# Resolve absolute paths for clarity in logs (best-effort)
abs_path() {
  # Portable realpath-ish
  python3 - <<PY 2>/dev/null || echo "$1"
import os,sys
p=os.path.abspath(sys.argv[1])
print(p)
PY
}

DOCKERFILE_ABS=$(abs_path "$DOCKERFILE")
CONTEXT_ABS=$(abs_path "$CONTEXT")

IMAGE_REF_BASE="$HUB_USER/$IMAGE"

# ==================== Login & Buildx ====================
echo "🔐 Logging into Docker Hub (skip if already logged in)…"
docker login

echo "🧱 Ensuring buildx is ready…"
docker buildx inspect >/dev/null 2>&1 || docker buildx create --use --name multi
docker buildx inspect --bootstrap >/dev/null

# ==================== Version auto-increment (vYYYY.MM.DD[-bN]) ====================
if [[ -z "$VERSION" ]]; then
  BASE="v$(date +%Y.%m.%d)"
  CANDIDATE="$BASE"
  # Check if tag exists remotely; if yes, append -b2, -b3, ...
  n=2
  while docker buildx imagetools inspect "${IMAGE_REF_BASE}:${CANDIDATE}" >/dev/null 2>&1; do
    CANDIDATE="${BASE}-b${n}"
    n=$((n+1))
    [[ $n -le 99 ]] || { echo "❌ Too many builds today; please specify --version."; exit 1; }
  done
  VERSION="$CANDIDATE"
fi

# ==================== Build Summary ====================
CACHE_MODE=$([[ -z "$NO_CACHE" ]] && echo "cache allowed" || echo "no-cache")
echo "📝 Build summary:"
echo "   • Dockerfile:  $DOCKERFILE_ABS"
echo "   • Context:     $CONTEXT_ABS"
echo "   • Platforms:   $PLATFORMS"
echo "   • Image base:  $IMAGE_REF_BASE"
echo "   • Version tag: $VERSION"
echo "   • Latest tag:  ${IMAGE_REF_BASE}:latest"
echo "   • Cache:       $CACHE_MODE"
echo

# ==================== Build & Push ====================
echo "🚀 Building and pushing multi-arch image…"
docker buildx build \
  --platform "$PLATFORMS" \
  $NO_CACHE \
  -f "$DOCKERFILE" \
  -t "${IMAGE_REF_BASE}:${VERSION}" \
  -t "${IMAGE_REF_BASE}:latest" \
  --push \
  "$CONTEXT"

# ==================== Verify Manifests ====================
echo "🔎 Verifying manifest for :${VERSION}…"
docker buildx imagetools inspect "${IMAGE_REF_BASE}:${VERSION}" | sed -n '1,80p'
echo
echo "🔎 Verifying manifest for :latest…"
docker buildx imagetools inspect "${IMAGE_REF_BASE}:latest" | sed -n '1,80p'

echo
echo "✅ Done. Pushed:"
echo " - ${IMAGE_REF_BASE}:${VERSION}"
echo " - ${IMAGE_REF_BASE}:latest"
