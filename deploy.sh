#!/usr/bin/env bash
set -euo pipefail

# Ensure we're in the same directory as this script
cd "$(dirname "$0")"

CONTAINER_NAME="teaching-quartz"

usage() {
  cat <<'USAGE'
🧰 Usage:
  ./deploy.sh <COURSE_CODE> <SECTION_NUMBER> [--owner <github-user-or-org>] [--repo <repo-name>] [--no-create-remote] [--private]

Examples:
  ./deploy.sh ICS3U 1
  ./deploy.sh ICS3U 1 --owner my-org --private
  ./deploy.sh ICS3U 2 --repo ICS3U-S2-2025 --no-create-remote

Notes:
- Deploys from /teaching/courses/<COURSE_CODE>/.merged_output/section<SECTION_NUMBER> inside the container.
- You will be prompted for a GitHub Personal Access Token (PAT) when needed.
- Host timezone offset is detected and passed to the container for accurate timestamps.
USAGE
}

if [[ $# -lt 2 ]]; then
  usage; exit 1
fi

COURSE_CODE="$1"; shift
SECTION_NUM="$1"; shift

# Host-side paths (bind-mounted into the container at /teaching/courses)
COURSE_DIR_HOST="$(pwd)/courses/${COURSE_CODE}"
MERGED_DIR_HOST="${COURSE_DIR_HOST}/.merged_output"
SECTION_DIR_HOST="${MERGED_DIR_HOST}/section${SECTION_NUM}"

# Detect host timezone offset in ±HHMM format (e.g., -0400, +0130)
HOST_TZ_OFFSET="$(date +%z)"
echo "🕒 Host timezone offset: $HOST_TZ_OFFSET"

# Friendly preflight: ensure the merged output for this section exists
if [[ ! -d "${SECTION_DIR_HOST}" ]]; then
  echo "❌ Section directory not found on host:"
  echo "   ${SECTION_DIR_HOST}"
  echo
  echo "👉 You likely need to build the merged output first:"
  echo "   ./preview.sh ${COURSE_CODE} ${SECTION_NUM}"
  # If there are any existing section folders, list them to help the teacher
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

docker exec -it \
  -e HOST_TZ_OFFSET="${HOST_TZ_OFFSET}" \
  "${CONTAINER_NAME}" \
  python /opt/scripts/deploy.py \
    --course "${COURSE_CODE}" \
    --section "${SECTION_NUM}" \
    "$@"
