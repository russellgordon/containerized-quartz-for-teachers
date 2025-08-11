#!/bin/bash

# Ensure we're in the same directory as this script
cd "$(dirname "$0")"

# Ensure the host-side courses folder exists and is writable
if [ ! -d "courses" ]; then
  echo "📁 Creating 'courses' directory on host..."
  mkdir -p courses
fi

# Also ensure a writable backups folder (backups live inside courses/_backups)
if [ ! -d "courses/_backups" ]; then
  echo "📦 Creating 'courses/_backups' directory on host..."
  mkdir -p courses/_backups
fi

# Make sure they're writable (necessary for Docker container access on macOS)
chmod a+rwx courses
chmod a+rwx courses/_backups

CONTAINER_NAME="teaching-quartz"

# Check if the container exists
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
  # Container exists
  if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
    echo "🛑 Stopping running container $CONTAINER_NAME to refresh volume mount..."
    docker stop "$CONTAINER_NAME" >/dev/null
  fi
  echo "🚀 Starting existing container $CONTAINER_NAME..."
  docker start "$CONTAINER_NAME" >/dev/null
else
  echo "🚀 Creating a new container named $CONTAINER_NAME..."
  docker run -dit \
    --name "$CONTAINER_NAME" \
    -v "$(pwd)/courses":/teaching/courses \
    -p 8081:8081 \
    teaching-quartz \
    tail -f /dev/null
fi

# Detect host timezone offset in ±HHMM format
HOST_TZ_OFFSET=$(date +%z)
echo "🕒 Detected host timezone offset: $HOST_TZ_OFFSET"
echo "🛟 Backups will be written to: $(pwd)/courses/_backups"

# If the user passed --no-backup, require confirmation
if printf '%s\n' "$@" | grep -q -- "--no-backup"; then
  echo "⚠️  You are running with --no-backup."
  echo "    This will skip creating a safety ZIP before modifying course folders."
  read -p "❓ Are you sure you want to proceed without a backup? (yes/no) " CONFIRM
  case "$CONFIRM" in
    yes|y|Y)
      echo "Proceeding without backup..."
      ;;
    *)
      echo "❌ Cancelled."
      exit 1
      ;;
  esac
fi

# Run the setup script inside the container, passing the timezone offset
# Forward any flags/args provided to this script (e.g., --no-backup)
echo "📚 Running setup_course.py inside the Docker container..."
docker exec -e HOST_TZ_OFFSET="$HOST_TZ_OFFSET" -it "$CONTAINER_NAME" \
  python3 /opt/scripts/setup_course.py "$@"
