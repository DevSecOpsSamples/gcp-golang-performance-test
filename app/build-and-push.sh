#!/bin/bash
set -e

# gcloud config set project <PROJECT_ID>
PROJECT_ID=$(gcloud config get-value project)
echo "PROJECT_ID: ${PROJECT_ID}"

# Set your repository name
RESPOSITORY="docker"

# gcloud artifacts repositories create ${RESPOSITORY} --repository-format=docker --location=us --description="Docker repository for go-echo-api"

docker build -t go-echo-api . --platform linux/amd64
docker tag go-echo-api:latest us-docker.pkg.dev/${PROJECT_ID}/${RESPOSITORY}/go-echo-api:latest

gcloud auth configure-docker us-docker.pkg.dev
docker push us-docker.pkg.dev/${PROJECT_ID}/${RESPOSITORY}/go-echo-api:latest

# docker run -it -p 8080:8080 go-echo-api:latest

# docker run -it -p 8080:8080 us-docker.pkg.dev/${PROJECT_ID}/go-echo-api:latest
