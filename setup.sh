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

# If container exists and is running, stop it to re-bind mount cleanly
if docker ps -q -f name=teaching-quartz >/dev/null; then
  echo "🛑 Stopping running container teaching-quartz to refresh volume mount..."
  docker stop teaching-quartz >/dev/null
fi

# Start container (create if needed)
if docker ps -a -q -f name=teaching-quartz >/dev/null; then
  echo "🚀 Starting existing container teaching-quartz..."
  docker start teaching-quartz >/dev/null
else
  echo "🚀 Creating a new container named teaching-quartz..."
  docker run -dit \
    --name teaching-quartz \
    -v "$(pwd)/courses":/teaching/courses \
    -p 8081:8081 \
    teaching-quartz \
    tail -f /dev/null
fi

# Run the setup script inside the container
echo "📚 Running setup_course.py inside the Docker container..."
docker exec -it teaching-quartz python3 /opt/scripts/setup_course.py
