#!/bin/bash
set -e

echo "PROJECT_ID: ${PROJECT_ID}"

docker buildx ls
docker buildx create --name builder --use builder
time docker buildx build -t gcr.io/${PROJECT_ID}/go-echo-api:latest . --platform linux/amd64,linux/arm/v7 --push