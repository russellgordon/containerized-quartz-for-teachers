#!/bin/bash

# Ensure we're in the same directory as this script
cd "$(dirname "$0")"

# Arguments
COURSE="$1"
SECTION="$2"
RESET_FLAG="$3"

if [ -z "$COURSE" ] || [ -z "$SECTION" ]; then
  echo "❌ Usage: ./run.sh <COURSE_CODE> <SECTION_NUMBER> [--reset-hidden]"
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

if [ "$RESET_FLAG" == "--reset-hidden" ]; then
  docker exec -it teaching-quartz python3 /opt/scripts/build_site.py --course="$COURSE" --section="$SECTION" --reset-hidden
else
  docker exec -it teaching-quartz python3 /opt/scripts/build_site.py --course="$COURSE" --section="$SECTION"
fi
