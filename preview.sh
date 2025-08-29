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
  echo "  ./preview.sh <COURSE_CODE> <SECTION_NUMBER> [options]"
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
  --course="$COURSE" \
  --section="$SECTION" \
  $INCLUDE_SOCIAL \
  $FORCE_NPM_INSTALL \
  $FULL_REBUILD \
  $MODE_FLAG
