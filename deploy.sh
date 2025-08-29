#!/usr/bin/env bash
set -euo pipefail

# Ensure we're in the same directory as this script
cd "$(dirname "$0")"

CONTAINER_NAME="teaching-quartz"

usage() {
  cat <<'USAGE'
🧰 Usage:
  ./deploy.sh <COURSE_CODE> <SECTION_NUMBER> [--diagnose] [--team <TEAM_SLUG>]

Examples:
  ./deploy.sh ICS3U 1
  ./deploy.sh ICS3U 1 --diagnose
  ./deploy.sh ICS3U 1 --team my-org-slug

Notes:
- Deploys from /teaching/courses/<COURSE>/.merged_output/section<SECTION> inside the container.
- You must build first (the static site goes to 'public/' in that section folder).
- You'll be prompted for a Netlify Personal Access Token on first deploy; it will be saved globally.
- The --team/--team-slug option is advanced; omit it to use your personal team.
- If your course code ends with '0' (zero), you'll be prompted to correct it to 'O' for Open-level courses.
USAGE
}

if [[ $# -lt 2 ]]; then
  usage; exit 1
fi

COURSE_CODE="$1"; shift
SECTION_NUM="$1"; shift

# Normalize course code to uppercase (handles lowercase 'o' -> 'O')
COURSE_CODE="$(printf '%s' "$COURSE_CODE" | tr '[:lower:]' '[:upper:]')"

# Friendly guard: catch 'Open' course codes mistyped with trailing zero (e.g., ICD20)
# Ontario course codes: 3 letters + digit + level letter (U/C/M/E/O). Open is 'O' (oh), not zero.
if [[ "$COURSE_CODE" =~ ^[A-Z]{3}[0-9]0$ ]]; then
  SUGGESTED="${COURSE_CODE%0}O"
  echo ""
  echo "🤔 It looks like you entered '${COURSE_CODE}' (ends with zero)."
  echo "   Ontario 'Open' level course codes end with the LETTER 'O' (oh)."
  # If a correctly named course already exists on disk, mention it
  if [[ -f "courses/$SUGGESTED/course_config.json" && ! -f "courses/$COURSE_CODE/course_config.json" ]]; then
    echo "   I see setup data for '$SUGGESTED' on disk."
  fi
  read -rp "   Fix course code to '$SUGGESTED'? [Y/n]: " _ans
  _ans="${_ans:-Y}"
  if [[ "$_ans" =~ ^[Yy]$ ]]; then
    COURSE_CODE="$SUGGESTED"
    echo "✅ Using corrected course code: $COURSE_CODE"
  else
    echo "ℹ️  Continuing with: $COURSE_CODE"
  fi
  echo ""
fi

# Parse optional flags: --diagnose and --team/--team-slug
DIAGNOSE=""
TEAM_SLUG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --diagnose)
      DIAGNOSE="--diagnose"
      ;;
    --team|--team-slug)
      if [[ $# -lt 2 ]]; then
        echo "❌ Missing value for $1"; echo; usage; exit 1
      fi
      TEAM_SLUG="$2"
      shift
      ;;
    --team=*|--team-slug=*)
      TEAM_SLUG="${1#*=}"
      ;;
    --help|-h)
      usage; exit 0
      ;;
    *)
      echo "❌ Unknown option: $1"; echo; usage; exit 1
      ;;
  esac
  shift
done

# Host-side paths (bind-mounted into the container at /teaching/courses)
COURSE_DIR_HOST="$(pwd)/courses/${COURSE_CODE}"
MERGED_DIR_HOST="${COURSE_DIR_HOST}/.merged_output"
SECTION_DIR_HOST="${MERGED_DIR_HOST}/section${SECTION_NUM}"
PUBLIC_DIR_HOST="${SECTION_DIR_HOST}/public"

# Detect host timezone offset in ±HHMM format (e.g., -0400, +0130)
HOST_TZ_OFFSET="$(date +%z)"
echo "🕒 Host timezone offset: $HOST_TZ_OFFSET"

# Preflight: ensure the course folder exists
if [[ ! -d "${COURSE_DIR_HOST}" ]]; then
  echo "❌ Course folder not found on host:"
  echo "   ${COURSE_DIR_HOST}"
  echo
  echo "👉 Make sure you've run the course setup and/or preview steps."
  echo "   Try: ./preview.sh ${COURSE_CODE} ${SECTION_NUM}"
  if [[ -d "$(pwd)/courses" ]]; then
    echo
    echo "📚 Available course folders:"
    ls -1 "$(pwd)/courses" | sed 's/^/   - /'
  fi
  exit 1
fi

# Preflight: ensure the merged output for this section exists
if [[ ! -d "${SECTION_DIR_HOST}" ]]; then
  echo "❌ Section directory not found on host:"
  echo "   ${SECTION_DIR_HOST}"
  echo
  echo "👉 You likely need to build the merged output first:"
  echo "   ./preview.sh ${COURSE_CODE} ${SECTION_NUM}"
  if [[ -d "${MERGED_DIR_HOST}" ]]; then
    EXISTING_SECTIONS=$(ls -1d "${MERGED_DIR_HOST}"/section* 2>/dev/null | xargs -n1 basename || true)
    if [[ -n "${EXISTING_SECTIONS:-}" ]]; then
      echo
      echo "📂 Existing merged sections for ${COURSE_CODE}:"
      echo "${EXISTING_SECTIONS}" | sed 's/^/   - /'
    fi
  fi
  exit 1
fi

# Preflight: ensure the static output exists
if [[ ! -d "${PUBLIC_DIR_HOST}" || -z "$(ls -A "${PUBLIC_DIR_HOST}" 2>/dev/null || true)" ]]; then
  echo "❌ Built site not found at:"
  echo "   ${PUBLIC_DIR_HOST}"
  echo
  echo "👉 Build first:"
  echo "   ./preview.sh ${COURSE_CODE} ${SECTION_NUM} --build-only"
  exit 1
fi

# -------------------- Mount-aware container handling --------------------
HOST_COURSES="$(pwd)/courses"  # desired host mount for this run

run_container_with_mount() {
  echo "🔗 Binding host courses to container: $HOST_COURSES ➜ /teaching/courses"
  docker run -dit \
    --name "$CONTAINER_NAME" \
    -v "$HOST_COURSES":/teaching/courses \
    -p 8081:8081 \
    teaching-quartz \
    tail -f /dev/null
}

echo "🚀 Ensuring container is running with the correct mount..."
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
  echo "🐳 Creating new container named $CONTAINER_NAME with correct mount…"
  run_container_with_mount
fi

SECTION_DIR_IN_CONTAINER="/teaching/courses/${COURSE_CODE}/.merged_output/section${SECTION_NUM}"
echo "🚀 Deploying ${COURSE_CODE} S${SECTION_NUM} from: ${SECTION_DIR_IN_CONTAINER}"

if [[ -n "${TEAM_SLUG}" ]]; then
  docker exec -it \
    -e HOST_TZ_OFFSET="${HOST_TZ_OFFSET}" \
    "${CONTAINER_NAME}" \
    python3 /opt/scripts/deploy.py \
      --course "${COURSE_CODE}" \
      --section "${SECTION_NUM}" \
      ${DIAGNOSE} \
      --team "${TEAM_SLUG}"
else
  docker exec -it \
    -e HOST_TZ_OFFSET="${HOST_TZ_OFFSET}" \
    "${CONTAINER_NAME}" \
    python3 /opt/scripts/deploy.py \
      --course "${COURSE_CODE}" \
      --section "${SECTION_NUM}" \
      ${DIAGNOSE}
fi
