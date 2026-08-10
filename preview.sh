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
# Set when an unexplained question about updating would interrupt something.
SKIP_UPDATE_CHECK="${SKIP_UPDATE_CHECK:-false}"
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
    --no-update-check) SKIP_UPDATE_CHECK="true"; shift ;;
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
  echo "  --port N                           Serve the preview on port N (default 8081; 8081-8084 available)"
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
    --port)
      if [[ $# -lt 2 ]]; then echo "❌ --port requires a value"; exit 1; fi
      PREVIEW_PORT="$2"
      shift
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

# The chosen port must be one the container publishes.
if ! [[ "$PREVIEW_PORT" =~ ^808[1-4]$ ]]; then
  echo "❌ --port must be between 8081 and 8084."
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
# ---- One container per working folder --------------------------------
# The container's name is derived from THIS folder, so two working folders
# (this year's courses and last year's, say) each get their own container
# and never repoint each other's mounts. The same derivation is used by
# the macOS app; the trailing newline from pwd is part of the hashed
# input, so keep `pwd -P | shasum` exactly as written.
WORKDIR_ID="$(pwd -P | shasum -a 256 | cut -c1-8)"
CONTAINER_NAME="teaching-quartz-${WORKDIR_ID}"
# Each preview serves on its own port, so several can run at once — one
# per window in the app. The container publishes the whole range.
# The flag parser above may already have chosen a port; keep it.
PREVIEW_PORT="${PREVIEW_PORT:-8081}"
PREVIEW_PORT_RANGE="8081-8084"
# Each preview also uses a live-reload websocket on port + 1000.
PREVIEW_WS_RANGE="9081-9084"
HOST_COURSES="$(pwd)/courses"  # desired host mount for this run

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
CURRENT_CONTEXT=$(docker context show 2>/dev/null || echo "unknown")
HOST_ARCH=$(docker info --format '{{.Architecture}}' 2>/dev/null || echo "unknown")
HOST_OS=$(docker info --format '{{.OSType}}' 2>/dev/null || echo "unknown")
echo "🔌 Docker context: ${CURRENT_CONTEXT}"
echo "🧭 Host detected by Docker: ${HOST_OS}/${HOST_ARCH}"
echo "🖼️  Using image: ${IMAGE}"
# ====================================================================

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

# -------------------- Offer a newer version, if one exists --------------------
# An image already on the machine was never checked again, so a teacher kept
# whatever they first downloaded and fixes never reached them.
registry_digest_of() {
  docker buildx imagetools inspect "$1" --format '{{.Manifest.Digest}}' 2>/dev/null || true
}

installed_digest_of() {
  # Only a digest belonging to THIS repository says anything about whether the
  # local image came from it. A locally built image often carries a digest for
  # some other repository, and comparing that guarantees a false "newer
  # version available" — which, answered yes, replaces a newer local build
  # with an older published one.
  local ref="$1"
  local repo="${ref%%:*}"
  local entries
  entries=$(docker image inspect "$ref" --format '{{range .RepoDigests}}{{println .}}{{end}}' 2>/dev/null || true)
  while IFS= read -r entry; do
    if [[ -z "$entry" ]]; then
      continue
    fi
    if [[ "${entry%@*}" == "$repo" ]]; then
      echo "${entry#*@}"
      return 0
    fi
  done <<< "$entries"
  echo ""
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

  # A different digest does not mean an older one. If the registry has never
  # heard of the installed digest, this is a locally built image, and
  # "updating" it would replace it with something older.
  if ! docker buildx imagetools inspect "${ref%%:*}@${installed}" >/dev/null 2>&1; then
    return 0
  fi

  echo "🆕 A newer version of the website builder is available."
  if [[ ! -t 0 ]]; then
    echo "   Run '${SELF_CMD} --update-image' when you would like to install it."
    return 0
  fi
  # A failed read means end-of-input — nobody is there to answer. Pressing
  # Return, by contrast, succeeds with an empty answer and takes the default.
  # Without this distinction an automated run silently accepts the update.
  if ! read -r -p "   Update the website builder now? (y/n) [Default: y]: " answer; then
    echo
    echo "   No answer given, so the version you have is being kept."
    return 0
  fi
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

if [[ "$SKIP_PULL" != "true" && "$FORCE_UPDATE_IMAGE" != "true" && "$SKIP_UPDATE_CHECK" != "true" && "$IMAGE_PRESENT" == "true" ]]; then
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



# Finds a free block of host ports for this container: four site ports and
# their four live-reload websocket ports. Different working folders get
# different blocks, which is what lets their previews run at the same time.
find_free_port_block() {
  local base offset
  for base in 8081 8091 8101 8111 8121 8131; do
    local all_free=true
    for offset in 0 1 2 3; do
      if lsof -nP -iTCP:$((base + offset)) -sTCP:LISTEN >/dev/null 2>&1; then all_free=false; break; fi
      if lsof -nP -iTCP:$((base + 1000 + offset)) -sTCP:LISTEN >/dev/null 2>&1; then all_free=false; break; fi
    done
    if [[ "$all_free" == "true" ]]; then
      echo "$base"
      return 0
    fi
  done
  return 1
}

# The one shared container from before working folders each had their own.
# Superseded: it holds no content (everything lives on the host), and left
# running it would shadow the per-folder containers' ports.
retire_legacy_container() {
  if docker ps -a --format '{{.Names}}' | grep -Eq '^teaching-quartz$'; then
    echo "♻️  Retiring the old shared workspace container…"
    docker rm -f teaching-quartz >/dev/null 2>&1 || true
  fi
}

run_container_with_mount() {
  retire_legacy_container
  local HOST_BASE
  HOST_BASE=$(find_free_port_block) || {
    echo "❌ Could not find free ports for this folder's previews."
    echo "   Stop another preview (or another app using ports 8081+), then try again."
    exit 1
  }
  echo "🔗 Binding host courses to container: $HOST_COURSES ➜ /teaching/courses"
  docker run -dit \
    --name "$CONTAINER_NAME" \
    -v "$HOST_COURSES":/teaching/courses \
    -p ${HOST_BASE}-$((HOST_BASE + 3)):8081-8084 \
    -p $((HOST_BASE + 1000))-$((HOST_BASE + 1003)):9081-9084 \
    "$IMAGE" \
    tail -f /dev/null
}

# A container keeps running the version it was created from, so an update
# only takes effect once the container itself is recreated.
DESIRED_IMAGE_ID=$(docker image inspect --format '{{.Id}}' "$IMAGE" 2>/dev/null || echo "")
RUNNING_IMAGE_ID=$(docker inspect -f '{{.Image}}' "$CONTAINER_NAME" 2>/dev/null || echo "")

echo "🚀 Starting container if needed..."
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
  elif [[ -n "$DESIRED_IMAGE_ID" && -n "$RUNNING_IMAGE_ID" && "$RUNNING_IMAGE_ID" != "$DESIRED_IMAGE_ID" ]]; then
    echo "♻️  Your workspace was built from an older version; rebuilding it so the update takes effect…"
    if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then docker stop "$CONTAINER_NAME" >/dev/null; fi
    docker rm "$CONTAINER_NAME" >/dev/null || true
    run_container_with_mount
  elif ! docker inspect -f '{{json .HostConfig.PortBindings}}' "$CONTAINER_NAME" 2>/dev/null | grep -q '9084/tcp'; then
    # An older container publishes only 8081, and published ports cannot
    # be changed after creation — recreating is the only way to add them.
    echo "♻️  Rebuilding your workspace so several previews can run at once…"
    if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then docker stop "$CONTAINER_NAME" >/dev/null; fi
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

# The container port maps to a host port block chosen for this folder, so
# the address to open is resolved from the container rather than assumed.
HOST_PREVIEW_PORT=$(docker port "$CONTAINER_NAME" "${PREVIEW_PORT}/tcp" 2>/dev/null | head -1 | sed 's/.*://')
if [[ -z "$HOST_PREVIEW_PORT" ]]; then
  HOST_PREVIEW_PORT="$PREVIEW_PORT"
fi
if [[ -z "$BUILD_ONLY" ]]; then
  echo "🌐 Preview will be available at: http://localhost:${HOST_PREVIEW_PORT}/"
fi

docker exec -it "$CONTAINER_NAME" python3 /opt/scripts/build_site.py \
  --host-os "$_PREVIEW_HOST_OS" \
  --course="$COURSE" \
  --section="$SECTION" \
  $INCLUDE_SOCIAL \
  $FORCE_NPM_INSTALL \
  $FULL_REBUILD \
  --port "$PREVIEW_PORT" \
  $MODE_FLAG
