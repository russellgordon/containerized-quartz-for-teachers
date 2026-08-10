#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# verify.sh — end-to-end verification of local toolchain changes (maintainer use)
#
# Builds a fresh local image (quartz-teacher:dev-test) from this repository,
# checks that everything baked into it matches the working tree, then drives
# the real launcher scripts against it so you can confirm that host-side and
# image-side changes work together before publishing with ./publish.sh.
#
# What it does, in order:
#   1. Ensures the container runtime is up (shares an already-running Colima;
#      never stops it — safe to run alongside other Colima-based toolchains).
#   2. docker build -t quartz-teacher:dev-test .
#   3. Verifies 'export-scripts' emits launchers identical to the repo copies
#      (and that Windows launchers were converted to CRLF).
#   4. Verifies the Python scripts and Quartz patches baked into the image
#      match the working tree.
#   5. Removes this folder's existing container, then runs
#      ./preview.sh EXC2O 1 --image quartz-teacher:dev-test --full-rebuild --build-only
#      so the container is recreated FROM THE DEV-TEST IMAGE and a full static
#      build of the Example Course runs through the real launcher.
#   6. Confirms the built site exists and the running container uses the
#      dev-test image, then prints a PASS/FAIL summary.
#
# Usage:
#   ./verify.sh [--no-cache] [--skip-build]
#
#   --no-cache     Build the image without Docker's layer cache.
#   --skip-build   Reuse an existing quartz-teacher:dev-test image (faster when
#                  only host-side scripts changed).
#
# Requires: courses/EXC2O (the Example Course) in this folder as the build
# fixture. courses/ is gitignored, so on a fresh clone install it first via
# ./setup.sh (answer 'y' to the Example Course prompt).
# ==============================================================================

cd "$(dirname "$0")"

DEV_TEST_IMAGE="quartz-teacher:dev-test"
# The launchers name their container after the working folder.
CONTAINER_NAME="teaching-quartz-$(pwd -P | shasum -a 256 | cut -c1-8)"
NO_CACHE=""
SKIP_BUILD="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-cache)   NO_CACHE="--no-cache"; shift ;;
    --skip-build) SKIP_BUILD="true"; shift ;;
    --help|-h)
      sed -n '4,36p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "❌ Unknown option: $1 (see --help)"; exit 1 ;;
  esac
done

# -------------------- Result bookkeeping --------------------
RESULTS=()
FAILED="false"
pass() { RESULTS+=("✅ PASS  $1"); echo "✅ PASS  $1"; }
fail() { RESULTS+=("❌ FAIL  $1"); echo "❌ FAIL  $1"; FAILED="true"; }

# -------------------- 0. A real terminal is required --------------------
# The launchers run the toolchain with `docker exec -it`, which refuses to
# start without a terminal on stdin. Say so now rather than failing several
# minutes in with a Docker error about attaching stdin.
if [[ ! -t 0 ]]; then
  echo "❌ verify.sh must be run from a terminal."
  echo "   The launchers use 'docker exec -it', which needs a TTY on stdin."
  echo "   To run it from a script or CI, give it one:"
  echo "     script -q /dev/null ./verify.sh"
  exit 1
fi

# -------------------- 1. Container runtime (shared Colima) --------------------
# Maintainer variant: assumes Colima and the Docker CLI are installed (the
# teacher-facing launchers handle installation). Never stops a running VM.
if ! docker info >/dev/null 2>&1; then
  if ! command -v colima >/dev/null 2>&1; then
    echo "❌ No running Docker engine and Colima is not installed."
    echo "   Install with: brew install colima docker"
    exit 1
  fi
  echo "▶️  Starting Colima…"
  colima start
  for _ in $(seq 1 30); do
    docker info >/dev/null 2>&1 && break
    sleep 2
  done
fi
if docker info >/dev/null 2>&1; then
  pass "Container runtime is up (context: $(docker context show 2>/dev/null || echo '?'))"
else
  fail "Container runtime did not become ready"
  echo "   Try: colima status && colima stop --force && colima start"
  exit 1
fi

# -------------------- Preconditions --------------------
if [[ ! -d "courses/EXC2O" || ! -f "courses/EXC2O/course_config.json" ]]; then
  fail "Test fixture courses/EXC2O is missing"
  echo "   The Example Course is required. Install it via ./setup.sh (answer 'y'"
  echo "   to the Example Course prompt) or copy support/example_course/EXC2O to courses/."
  exit 1
fi

# -------------------- 2. Build the dev-test image --------------------
if [[ "$SKIP_BUILD" == "true" ]] && docker image inspect "$DEV_TEST_IMAGE" >/dev/null 2>&1; then
  pass "Reusing existing image $DEV_TEST_IMAGE (--skip-build)"
else
  echo ""
  echo "🧱 Building $DEV_TEST_IMAGE from ./Dockerfile ${NO_CACHE:+(no cache)}…"
  # The Dockerfile uses a BuildKit heredoc (RUN cat <<'EOF'), which the legacy
  # builder silently mishandles (it produced an EMPTY export-scripts file).
  # publish.sh builds with buildx, so verify must too, to stay representative.
  if docker buildx version >/dev/null 2>&1; then
    BUILD_CMD=(docker buildx build --load)
  else
    BUILD_CMD=(env DOCKER_BUILDKIT=1 docker build)
  fi
  if "${BUILD_CMD[@]}" $NO_CACHE -t "$DEV_TEST_IMAGE" .; then
    pass "Image built: $DEV_TEST_IMAGE (BuildKit)"
  else
    fail "docker build failed"
    exit 1
  fi
fi

# -------------------- 3. export-scripts fidelity --------------------
# NOTE: must live under $HOME — Colima's VM only shares the home directory,
# so a /var/folders/... temp dir would silently arrive empty in the container.
EXPORT_TMP="$(mktemp -d "$(pwd)/.verify-export.XXXXXX")"
echo ""
echo "📤 Testing 'export-scripts' → $EXPORT_TMP"
if docker run --rm -v "$EXPORT_TMP:/out" "$DEV_TEST_IMAGE" export-scripts >/dev/null; then
  EXPORT_OK="true"
  for f in setup.sh preview.sh deploy.sh; do
    if ! cmp -s "$f" "$EXPORT_TMP/$f"; then
      EXPORT_OK="false"
      fail "Exported $f differs from repo copy (stale image?)"
    fi
  done
  for f in setup.bat preview.bat deploy.bat setup.ps1 preview.ps1 deploy.ps1; do
    if [[ ! -f "$EXPORT_TMP/$f" ]]; then
      EXPORT_OK="false"
      fail "Exported $f is missing"
    elif ! grep -q $'\r' "$EXPORT_TMP/$f"; then
      EXPORT_OK="false"
      fail "Exported $f lacks CRLF line endings (unix2dos step broken?)"
    fi
  done
  [[ "$EXPORT_OK" == "true" ]] && pass "export-scripts emits current launchers (CRLF intact on Windows files)"
else
  fail "export-scripts did not run"
fi
rm -rf "$EXPORT_TMP"

# -------------------- 4. Baked files match the working tree --------------------
echo ""
echo "🔬 Comparing files baked into the image against the working tree…"
BAKED_OK="true"
check_baked() {
  local repo_path="$1" image_path="$2"
  if ! docker run --rm -v "$(pwd):/repo:ro" "$DEV_TEST_IMAGE" cmp -s "/repo/$repo_path" "$image_path"; then
    BAKED_OK="false"
    fail "Image file $image_path differs from repo $repo_path"
  fi
}
check_baked scripts/setup_course.py       /opt/scripts/setup_course.py
check_baked scripts/build_site.py         /opt/scripts/build_site.py
check_baked scripts/deploy.py             /opt/scripts/deploy.py
check_baked patches/Explorer.tsx          /opt/quartz/quartz/components/Explorer.tsx
check_baked patches/FolderContent.tsx     /opt/quartz/quartz/components/pages/FolderContent.tsx
check_baked patches/explorer.inline.ts    /opt/quartz/quartz/components/scripts/explorer.inline.ts
check_baked support/Backlinks.tsx         /opt/support/Backlinks.tsx
check_baked support/colour_schemes.json   /opt/support/colour_schemes.json
[[ "$BAKED_OK" == "true" ]] && pass "Baked scripts, patches, and support files match the working tree"

# -------------------- 5. Drive the real launcher against the image --------------------
echo ""
echo "🧹 Removing existing '$CONTAINER_NAME' container so the launcher recreates it"
echo "   from ${DEV_TEST_IMAGE}…"
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

STAMP_FILE="$(mktemp -t cq4t-stamp)"
echo ""
echo "🚦 Running: ./preview.sh EXC2O 1 --image $DEV_TEST_IMAGE --full-rebuild --build-only"
echo "   (full rebuild ensures the Quartz scaffold comes from the dev-test image)"
echo ""
if ./preview.sh EXC2O 1 --image "$DEV_TEST_IMAGE" --full-rebuild --build-only; then
  pass "preview.sh completed against $DEV_TEST_IMAGE"
else
  fail "preview.sh exited non-zero"
fi

# -------------------- 6. Post-flight checks --------------------
SITE_INDEX="courses/EXC2O/.merged_output/section1/public/index.html"
if [[ -f "$SITE_INDEX" && "$SITE_INDEX" -nt "$STAMP_FILE" ]]; then
  pass "Built site is present and freshly generated ($SITE_INDEX)"
else
  fail "Built site missing or stale at $SITE_INDEX"
fi
rm -f "$STAMP_FILE"

RUNNING_IMAGE="$(docker inspect -f '{{.Config.Image}}' "$CONTAINER_NAME" 2>/dev/null || echo '(none)')"
if [[ "$RUNNING_IMAGE" == "$DEV_TEST_IMAGE" ]]; then
  pass "Container '$CONTAINER_NAME' is running from $DEV_TEST_IMAGE"
else
  fail "Container '$CONTAINER_NAME' is running from '$RUNNING_IMAGE', not $DEV_TEST_IMAGE"
fi

# -------------------- Summary --------------------
echo ""
echo "==================== verify.sh summary ===================="
for line in "${RESULTS[@]}"; do echo "$line"; done
echo "==========================================================="
if [[ "$FAILED" == "true" ]]; then
  echo "❌ Verification FAILED — see items above."
  exit 1
fi
echo "✅ All checks passed."
echo ""
echo "ℹ️  Notes:"
echo "   • The '$CONTAINER_NAME' container was left running from $DEV_TEST_IMAGE"
echo "     so you can poke at it (e.g., ./preview.sh EXC2O 1 --image $DEV_TEST_IMAGE)."
echo "   • To return to the published image, run:  docker rm -f $CONTAINER_NAME"
echo "     (the next ./setup.sh or ./preview.sh run recreates it automatically)."
echo "   • Colima was left exactly as it was found — never stopped by this script."
