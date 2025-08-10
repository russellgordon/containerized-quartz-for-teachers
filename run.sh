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
FULL_REBUILD=""

# Display help text if requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo ""
  echo "🧰 Usage:"
  echo "  ./run.sh <COURSE_CODE> <SECTION_NUMBER> [options]"
  echo ""
  echo "📘 Required arguments:"
  echo "  <COURSE_CODE>               The course code (e.g., ICS3U)"
  echo "  <SECTION_NUMBER>            The section number (e.g., 1)"
  echo ""
  echo "⚙️ Optional flags:"
  echo "  --include-social-media-previews    Enable Quartz CustomOgImages emitter"
  echo "  --force-npm-install                Force npm install even if dependencies are present"
  echo "  --full-rebuild                     Clear entire output folder and re-copy Quartz scaffold"
  echo "  --help, -h                         Show this help message"
  echo ""
  echo "📂 Output location (hidden in Obsidian Files pane):"
  echo "  courses/<COURSE_CODE>/.merged_output/section<SECTION_NUMBER>"
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

# Preflight: nudge if quartz.layout.ts in the container wasn't initialized by setup.sh
echo "🔎 Preflight: checking Quartz sidebar anchor..."
if ! docker exec -i teaching-quartz bash -lc 'test -f /opt/quartz/quartz.layout.ts && grep -q "const omit = new Set" /opt/quartz/quartz.layout.ts'; then
  echo "⚠️  Sidebar omit anchor not found in container's Quartz layout."
  echo "   Did you run: ./setup.sh and complete setup for '$COURSE'?"
  echo "   (Continuing anyway; the build will attempt a safe fallback.)"
fi

echo "🔧 Building site for $COURSE, section $SECTION..."
echo "📂 Output will be written to: $OUTPUT_PATH"

docker exec -it teaching-quartz python3 /opt/scripts/build_site.py \
  --course="$COURSE" \
  --section="$SECTION" \
  $INCLUDE_SOCIAL \
  $FORCE_NPM_INSTALL \
  $FULL_REBUILD
