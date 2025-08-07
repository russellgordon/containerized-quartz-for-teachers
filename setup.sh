#!/bin/bash

# Ensure we're in the same directory as this script
cd "$(dirname "$0")"

echo "📚 Running setup_course.py inside the Docker container..."

docker start teaching-quartz >/dev/null 2>&1 || {
  echo "🚀 Creating a new container named teaching-quartz..."
  docker run -dit \
    --name teaching-quartz \
    -v "$(pwd)/courses":/teaching/courses \
    -p 8081:8081 \
    teaching-quartz \
    tail -f /dev/null
}

docker exec -it teaching-quartz python3 /opt/scripts/setup_course.py
