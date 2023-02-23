#!/bin/bash
set -e

echo "PROJECT_ID: ${PROJECT_ID}"

docker build -t go-echo-api . --platform linux/amd64
docker tag go-echo-api:latest gcr.io/${PROJECT_ID}/go-echo-api:latest
docker push gcr.io/${PROJECT_ID}/go-echo-api:latest

# docker run -it -p 8000:8000 go-echo-api:latest

# docker run -it -p 8000:8000 gcr.io/${PROJECT_ID}/go-echo-api:latest