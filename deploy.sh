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
USAGE
}

if [[ $# -lt 2 ]]; then
  usage; exit 1
fi

COURSE_CODE="$1"; shift
SECTION_NUM="$1"; shift

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

# Ensure the container exists
if ! docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
  echo "❌ Docker container '${CONTAINER_NAME}' not found."
  echo "   Please run ./setup.sh first to create and start the container."
  exit 1
fi

# Start container if it exists but isn't running
if ! docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
  echo "🐳 Starting container ${CONTAINER_NAME}..."
  docker start "${CONTAINER_NAME}" >/dev/null
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
