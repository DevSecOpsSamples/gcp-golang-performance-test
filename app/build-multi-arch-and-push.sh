#!/bin/bash
set -e

# gcloud config set project <PROJECT_ID>
PROJECT_ID=$(gcloud config get-value project)
echo "PROJECT_ID: ${PROJECT_ID}"

# Set your repository name
RESPOSITORY="docker"

docker buildx ls

docker buildx rm builder || true
docker buildx create --name builder --use

gcloud auth configure-docker us-docker.pkg.dev
time docker buildx build -t us-docker.pkg.dev/${PROJECT_ID}/${RESPOSITORY}/go-echo-api:latest . --platform linux/amd64,linux/arm/v7 --push
