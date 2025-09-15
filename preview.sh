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
_PREVIEW_HOST_OS="$(_detect_host_os)"
if [[ "$_PREVIEW_HOST_OS" == "windows" ]]; then
  SELF_CMD=".\\preview.bat"
else
  SELF_CMD="./preview.sh"
fi
# ----------------------------------------------------------------------
#!/bin/bash

# Ensure we're in the same directory as this script
cd "$(dirname "$0")"

# Arguments
COURSE="$1"
SECTION="$2"

# Shift COURSE and SECTION out of the way
shift 2


# -------------------- Image selection & options (parity with setup.sh) --------------------
HUB_USER="${HUB_USER:-rwhgrwhg}"
DEFAULT_TAG="${DEFAULT_TAG:-latest}"
IMAGE_NAME="${IMAGE_NAME:-teaching-quartz}"
DEV_IMAGE="${DEV_IMAGE:-quartz-teacher:dev}"

TAG="${TAG:-$DEFAULT_TAG}"
FORCE_UPDATE_IMAGE="${FORCE_UPDATE_IMAGE:-false}"
OVERRIDE_IMAGE="${OVERRIDE_IMAGE:-}"
USE_LOCAL_DEV="${USE_LOCAL_DEV:-false}"
SKIP_PULL="${SKIP_PULL:-false}"
PULL_STATUS=""

# Parse image-related flags only; leave other flags for later parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)        OVERRIDE_IMAGE="$2"; shift 2 ;;
    --tag)          TAG="$2"; shift 2 ;;
    --update-image) FORCE_UPDATE_IMAGE="true"; shift ;;
    --local-dev)    USE_LOCAL_DEV="true"; SKIP_PULL="true"; shift ;;
    --) shift; break ;;
    -*|*) break ;;
  esac
done

# Resolve IMAGE (same rules as setup.sh)
if [[ "$USE_LOCAL_DEV" == "true" ]]; then
  IMAGE="$DEV_IMAGE"
elif [[ -n "$OVERRIDE_IMAGE" ]]; then
  IMAGE="$OVERRIDE_IMAGE"
else
  IMAGE="${HUB_USER}/${IMAGE_NAME}:${TAG}"
fi


# Initialize flags
INCLUDE_SOCIAL=""
FORCE_NPM_INSTALL=""
FULL_REBUILD=""
BUILD_ONLY=""   # NEW: replaces --no-preview

# Normalize COURSE to uppercase (avoid 'o' vs 'O' issues)
COURSE="$(printf '%s' "$COURSE" | tr '[:lower:]' '[:upper:]')"

# Guardrail: catch 'Open' course codes mistyped with trailing zero (e.g., ICD20)
# Ontario course codes are 3 letters + digit + level letter (U/C/M/E/O). Open ends in 'O' (oh), not zero.
if [[ "$COURSE" =~ ^[A-Z]{3}[0-9]0$ ]]; then
  SUGGESTED="${COURSE%0}O"
  echo ""
  echo "🤔 It looks like you entered '${COURSE}' (ends with zero)."
  echo "   Ontario 'Open' level course codes end with the LETTER 'O' (oh)."
  # If a correctly-named course already exists, mention it to build confidence
  if [[ -f "courses/$SUGGESTED/course_config.json" && ! -f "courses/$COURSE/course_config.json" ]]; then
    echo "   I see setup data for '$SUGGESTED' on disk."
  fi
  read -rp "   Fix course code to '$SUGGESTED'? [Y/n]: " _ans
  _ans="${_ans:-Y}"
  if [[ "$_ans" =~ ^[Yy]$ ]]; then
    COURSE="$SUGGESTED"
    echo "✅ Using corrected course code: $COURSE"
  else
    echo "ℹ️  Continuing with: $COURSE"
  fi
  echo ""
fi

# Display help text if requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo ""
  echo "🧰 Usage:"
  echo "  $SELF_CMD <COURSE_CODE> <SECTION_NUMBER> [options]"
  echo ""
  echo "📘 Required arguments:"
  echo "  <COURSE_CODE>               The course code (e.g., ICS3U)"
  echo "  <SECTION_NUMBER>            The TIMETABLE section number (e.g., 1, 3, 4)"
  echo ""
  echo "⚙️ Optional flags:"
  echo "  --include-social-media-previews    Enable Quartz CustomOgImages emitter"
  echo "  --force-npm-install                Force npm install even if dependencies are present"
  echo "  --full-rebuild                     Clear entire output folder and re-copy Quartz scaffold"
  echo "  --build-only                       Build the static site only (no local preview server)"
  echo "  --help, -h                         Show this help message"
  echo ""
  echo "📂 Output location (hidden in Obsidian Files pane):"
  echo "  courses/<COURSE_CODE>/.merged_output/section<SECTION_NUMBER>"
  echo ""
  echo "📝 Notes:"
  echo "  • Default behavior is to build-and-serve once via Quartz (no double build)."
  echo "  • Use --build-only if you only want the static 'public/' output without serving."
  echo "  • If your course code ends with '0' (zero), you'll be prompted to correct it to 'O' for Open-level courses."
  echo ""
  exit 0
fi

# Parse optional flags
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --include-social-media-previews)
      INCLUDE_SOCIAL="--include-social-media-previews"
      ;;
    --force-npm-install)
      FORCE_NPM_INSTALL="--force-npm-install"
      ;;
    --full-rebuild)
      FULL_REBUILD="--full-rebuild"
      ;;
    --build-only)
      BUILD_ONLY="--build-only"
      ;;
    *)
      echo "❌ Unknown option: $1"
      echo "Use './preview.sh --help' to see usage instructions."
      exit 1
      ;;
  esac
  shift
done

# Validate course and section
if [ -z "$COURSE" ] || [ -z "$SECTION" ]; then
  echo "❌ Missing required arguments."
  echo "Use './preview.sh --help' to see usage instructions."
  exit 1
fi

# Ensure SECTION looks like a positive integer
if ! [[ "$SECTION" =~ ^[0-9]+$ ]]; then
  echo "❌ SECTION must be a positive integer (the timetable section number)."
  exit 1
fi

OUTPUT_PATH="courses/$COURSE/.merged_output/section$SECTION"

# Preflight: ensure this course has been set up (host-side)
COURSE_CFG="courses/$COURSE/course_config.json"
if [[ ! -f "$COURSE_CFG" ]]; then
  echo "⚠️  $COURSE_CFG not found."
  echo "   It looks like you haven't completed setup for '$COURSE' yet."
  echo "   Run: ./setup.sh"
  echo "   (Then select or create the course '$COURSE' when prompted.)"
  exit 1
fi

# Preflight: the section folder should exist (setup_course.py creates 'section<N>')
if [[ ! -d "courses/$COURSE/section$SECTION" ]]; then
  echo "⚠️  courses/$COURSE/section$SECTION does not exist."
  echo "   If this is one of your timetable sections, run './setup.sh' again and include section $SECTION."
  echo "   Otherwise, choose one of YOUR assigned sections when running this command."
  # don't exit here yet; we'll validate against section_numbers below
fi

# -------------------- Mount-aware container handling --------------------
CONTAINER_NAME="teaching-quartz"
HOST_PORT=8081
CONTAINER_PORT=8081
HOST_COURSES="$(pwd)/courses"  # desired host mount for this run
# -------------------- Pull or verify image presence --------------------
IMAGE_PRESENT="false"
if docker image inspect "$IMAGE" >/dev/null 2>&1; then
  IMAGE_PRESENT="true"
fi
# If not present by exact ref, try to discover close matches (helps with local naming quirks)
if [[ "$IMAGE_PRESENT" == "false" ]]; then
  REPO="${IMAGE%%:*}"
  TAG_PART="${IMAGE#*:}"
  CANDIDATES=$(docker image ls --format '{{.Repository}}:{{.Tag}}' "$REPO" 2>/dev/null | grep -i "${TAG_PART}" || true)
  if [[ -n "$CANDIDATES" ]]; then
    echo "ℹ️  Found local candidates for '$IMAGE' in context '${CURRENT_CONTEXT}':"
    echo "$CANDIDATES" | sed 's/^/   • /'
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


run_container_with_mount() {
  echo "🔗 Binding host courses to container: $HOST_COURSES ➜ /teaching/courses"
  docker run -dit \
    --name "$CONTAINER_NAME" \
    -v "$HOST_COURSES":/teaching/courses \
    -p ${HOST_PORT}:${CONTAINER_PORT} \
    "$IMAGE" \
    tail -f /dev/null
}

echo "🚀 Starting container if needed..."
# -------------------- Pre-flight checks & context --------------------
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker is not installed or not on PATH. Please install Docker Desktop first."
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker daemon not reachable."
  echo "   - On macOS/Windows, open Docker Desktop and wait for it to start."
  echo "   - On Linux, ensure the Docker service is running."
  exit 1
fi
CURRENT_CONTEXT=$(docker context show 2>/dev/null || echo "unknown")
HOST_ARCH=$(docker info --format '{{.Architecture}}' 2>/dev/null || echo "unknown")
HOST_OS=$(docker info --format '{{.OSType}}' 2>/dev/null || echo "unknown")
echo "🔌 Docker context: ${CURRENT_CONTEXT}"
echo "🧭 Host detected by Docker: ${HOST_OS}/${HOST_ARCH}"
echo "🖼️  Using image: ${IMAGE}"
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
  # Container exists — check its current /teaching/courses mount
  CURRENT_MOUNT_SRC=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/teaching/courses"}}{{.Source}}{{end}}{{end}}' "$CONTAINER_NAME" 2>/dev/null || echo "")
  if [[ -z "$CURRENT_MOUNT_SRC" ]]; then
    echo "🧩 Existing container has no /teaching/courses mount; recreating with correct mount…"
    if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
      docker stop "$CONTAINER_NAME" >/dev/null
    fi
    docker rm "$CONTAINER_NAME" >/dev/null || true
    run_container_with_mount
  elif [[ "$CURRENT_MOUNT_SRC" != "$HOST_COURSES" ]]; then
    echo "🔄 Detected different working directory:"
    echo "   • Existing mount: $CURRENT_MOUNT_SRC"
    echo "   • Desired mount:  $HOST_COURSES"
    echo "♻️  Recreating container '$CONTAINER_NAME' to point at the new folder…"
    if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
      docker stop "$CONTAINER_NAME" >/dev/null
    fi
    docker rm "$CONTAINER_NAME" >/dev/null || true
    run_container_with_mount
  else
    # Mounts match; only start if not already running
    if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
      echo "✅ Container $CONTAINER_NAME is already running with correct mount."
    else
      echo "🚀 Starting existing container $CONTAINER_NAME..."
    docker start "$CONTAINER_NAME" >/dev/null
    fi
  fi
else
  echo "🚀 Creating new container named $CONTAINER_NAME..."
  run_container_with_mount
fi

# Preflight: nudge if quartz.layout.ts in the container wasn't initialized by setup.sh
echo "🔎 Preflight: checking Quartz sidebar anchor..."
if ! docker exec -i "$CONTAINER_NAME" bash -lc 'test -f /opt/quartz/quartz.layout.ts && grep -q "const omit = new Set" /opt/quartz/quartz.layout.ts'; then
  echo "⚠️  Sidebar omit anchor not found in container's Quartz layout."
  echo "   Did you run: ./setup.sh and complete setup for '$COURSE'?"
  echo "   (Continuing anyway; the build will attempt a safe fallback.)"
fi

# Validate that SECTION is one of the allowed timetable sections for this course
echo "📋 Checking allowed timetable sections for $COURSE..."
ALLOWED_SECTIONS="$(docker exec -e COURSE="$COURSE" "$CONTAINER_NAME" python3 - <<'PY'
import os, json, sys
course = os.environ.get("COURSE")
p = f"/teaching/courses/{course}/course_config.json"
try:
    with open(p, "r", encoding="utf-8") as f:
        cfg = json.load(f)
    secs = cfg.get("section_numbers")
    if isinstance(secs, list) and secs:
        print(",".join(str(int(x)) for x in secs))
    else:
        n = int(cfg.get("num_sections", 1))
        print(",".join(str(i) for i in range(1, n+1)))
except Exception as e:
    print("")
PY
)"

if [[ -n "$ALLOWED_SECTIONS" ]]; then
  echo "   Allowed sections: $ALLOWED_SECTIONS"
  IFS=',' read -ra ARR <<< "$ALLOWED_SECTIONS"
  FOUND=0
  for s in "${ARR[@]}"; do
    if [[ "$s" == "$SECTION" ]]; then
      FOUND=1
      break
    fi
  done
  if [[ "$FOUND" -ne 1 ]]; then
    echo "❌ Section $SECTION is not one of YOUR timetable sections for $COURSE."
    echo "   Choose one of: $ALLOWED_SECTIONS"
    exit 1
  fi
else
  echo "ℹ️ Could not read allowed sections from course_config.json (continuing)."
fi

echo "🔧 Building site for $COURSE, section $SECTION..."
echo "📂 Output will be written to: $OUTPUT_PATH"

# With the new build_site.py:
# - default (no flag) = serve once (no double build)
# - --build-only = build static site only
MODE_FLAG="$BUILD_ONLY"

docker exec -it "$CONTAINER_NAME" python3 /opt/scripts/build_site.py \
  --host-os mac \
  --course="$COURSE" \
  --section="$SECTION" \
  $INCLUDE_SOCIAL \
  $FORCE_NPM_INSTALL \
  $FULL_REBUILD \
  $MODE_FLAG