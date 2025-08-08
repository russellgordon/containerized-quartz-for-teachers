#!/bin/bash

# Ensure we're in the same directory as this script
cd "$(dirname "$0")"

# Arguments
COURSE="$1"
SECTION="$2"

# Shift COURSE and SECTION out of the way
shift 2

# Initialize flags
INCLUDE_SOCIAL=""
FORCE_NPM_INSTALL=""

# Display help text if requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo ""
  echo "🧰 Usage:"
  echo "  ./run.sh <COURSE_CODE> <SECTION_NUMBER> [options]"
  echo ""
  echo "📘 Required arguments:"
  echo "  <COURSE_CODE>               The course code (e.g., ICS3U)"
  echo "  <SECTION_NUMBER>           The section number (e.g., 1)"
  echo ""
  echo "⚙️ Optional flags:"
  echo "  --include-social-media-previews    Enable Quartz CustomOgImages emitter"
  echo "  --force-npm-install                Force npm install even if dependencies are present"
  echo "  --help, -h                         Show this help message"
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
    *)
      echo "❌ Unknown option: $1"
      echo "Use './run.sh --help' to see usage instructions."
      exit 1
      ;;
  esac
  shift
done

# Validate course and section
if [ -z "$COURSE" ] || [ -z "$SECTION" ]; then
  echo "❌ Missing required arguments."
  echo "Use './run.sh --help' to see usage instructions."
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
  $INCLUDE_SOCIAL \
  $FORCE_NPM_INSTALL
