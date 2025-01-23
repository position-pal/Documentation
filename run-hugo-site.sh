#!/bin/bash

command_exists() {
    command -v "$1" &> /dev/null
}

if command_exists hugo; then
    echo "`hugo` found on device. Starting Hugo server..."
    hugo server -D
    # If Hugo command fails, fallback to Docker Compose
    if [ $? -ne 0 ]; then
        echo "Hugo server failed. Falling back to Docker Compose..."
        docker compose up
    fi
else
    echo "Hugo not found. Starting Docker Compose..."
    $DOCKER_CMD up
fi
