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

echo "📚 Running setup_course.py inside the Docker container..."

# Start existing container or create a new one
docker start teaching-quartz >/dev/null 2>&1 || {
  echo "🚀 Creating a new container named teaching-quartz..."
  docker run -dit \
    --name teaching-quartz \
    -v "$(pwd)/courses":/teaching/courses \
    -p 8081:8081 \
    teaching-quartz \
    tail -f /dev/null
}

# Run the setup script inside the container
docker exec -it teaching-quartz python3 /opt/scripts/setup_course.py
