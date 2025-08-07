#!/bin/bash

# Ensure we're in the same directory as this script
cd "$(dirname "$0")"

# Arguments
COURSE="$1"
SECTION="$2"

# Shift COURSE and SECTION out of the way
shift 2

# Initialize flags
RESET_FLAG=""
INCLUDE_SOCIAL=""

# Parse optional flags
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --reset-hidden)
      RESET_FLAG="--reset-hidden"
      ;;
    --include-social-media-previews)
      INCLUDE_SOCIAL="--include-social-media-previews"
      ;;
    *)
      echo "❌ Unknown option: $1"
      echo "Usage: ./run.sh <COURSE_CODE> <SECTION_NUMBER> [--reset-hidden] [--include-social-media-previews]"
      exit 1
      ;;
  esac
  shift
done

# Validate course and section
if [ -z "$COURSE" ] || [ -z "$SECTION" ]; then
  echo "❌ Usage: ./run.sh <COURSE_CODE> <SECTION_NUMBER> [--reset-hidden] [--include-social-media-previews]"
  exit 1
fi

echo "🚀 Starting container if needed..."
docker start teaching-quartz >/dev/null 2>&1 || {
  echo "🚀 Creating new container named teaching-quartz..."
  docker run -dit \
    --name teaching-quartz \
    -v "$(pwd)/courses":/teaching/courses \
    -p 8081:8081 \
    teaching-quartz \
    tail -f /dev/null
}

echo "🔧 Building site for $COURSE, section $SECTION..."

docker exec -it teaching-quartz python3 /opt/scripts/build_site.py \
  --course="$COURSE" \
  --section="$SECTION" \
  $RESET_FLAG \
  $INCLUDE_SOCIAL
