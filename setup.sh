#!/bin/bash

# Ensure we're in the same directory as this script
cd "$(dirname "$0")"

# Ensure the host-side courses folder exists and is writable
if [ ! -d "courses" ]; then
  echo "📁 Creating 'courses' directory on host..."
  mkdir -p courses
fi

# Make sure it's writable (necessary for Docker container access on macOS)
chmod a+rwx courses

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

# Run the setup script inside the container, passing the timezone offset
echo "📚 Running setup_course.py inside the Docker container..."
docker exec -e HOST_TZ_OFFSET="$HOST_TZ_OFFSET" -it "$CONTAINER_NAME" python3 /opt/scripts/setup_course.py
