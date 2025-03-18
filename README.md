# Performance testing on GKE using labstack echo application

[![Build](https://github.com/DevSecOpsSamples/gcp-golang-performance-test/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/DevSecOpsSamples/gcp-golang-performance-test/actions/workflows/build.yml)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=DevSecOpsSamples_gcp-golang-performance-test&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=DevSecOpsSamples_gcp-golang-performance-test) [![Lines of Code](https://sonarcloud.io/api/project_badges/measure?project=DevSecOpsSamples_gcp-golang-performance-test&metric=ncloc)](https://sonarcloud.io/summary/new_code?id=DevSecOpsSamples_gcp-golang-performance-test)

Performance testing on GKE using the <https://echo.labstack.com> application.

## Table of Contents

- [1. Create a GKE cluster](#1-create-a-gke-cluster)
- [2. Deploy two applications for checking the performance per Pod and scaling](#2-deploy-two-applications-for-checking-the-performance-per-pod-and-scaling)
  - [2.1. Deploy for performance of one Pod](#21-deploy-for-performance-of-one-pod)
  - [2.2. Deploy for Scaling Test](#22-deploy-for-scaling-test)
- [3. Performance Testing](#3-performance-testing)
  - [3.1. Install the Taurus](#31-install-the-taurus)
  - [3.2. Test for performance of one Pod](#32-test-for-performance-of-one-pod)
  - [3.3. Test with auto scaling](#33-test-with-auto-scaling)
- [Cleanup](#6-cleanup)

---

## Prerequisites

### Installation

- [Install the gcloud CLI](https://cloud.google.com/sdk/docs/install)
- [Install kubectl and configure cluster access](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl)
- [Installing and Upgrading for the Taurus](https://gettaurus.org/install/Installation/)

### Set environment variables

```bash
COMPUTE_ZONE="us-central1"
# replace with your project
PROJECT_ID="sample-project"
```

### Set GCP project

```bash
gcloud config set project ${PROJECT_ID}
gcloud config set compute/zone ${COMPUTE_ZONE}
```

---

## 1. Create a GKE cluster

Create an Autopilot GKE cluster. It may take around 9 minutes.

```bash
gcloud container clusters create-auto sample-cluster --region=${COMPUTE_ZONE}
gcloud container clusters get-credentials sample-cluster
```

## 2. Deploy two applications for checking the performance per Pod and scaling

Build and push to GAR:

```bash
gcloud auth login
gcloud auth configure-docker us-docker.pkg.dev

cd app
docker build -t go-echo-api . --platform linux/amd64
docker tag go-echo-api:latest us-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/go-echo-api:latest
docker push us-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/go-echo-api:latest
```

[build-and-push.sh](app/build-and-push.sh)

```bash
kubectl get ns

kubectl create ns echo-test
```

Two deployments may take around 5 minutes to create a load balancer, including health checking.

## 2.1. Deploy for performance of one Pod

To check request per seconds(RPS) WITHOUT scaling, create and deploy K8s Deployment, Service, HorizontalPodAutoscaler, Ingress, and GKE BackendConfig using the [go-echo-api-onepod-template.yaml](app/go-echo-api-onepod-template.yaml) template file:

```bash
sed -e "s|<project-id>|${PROJECT_ID}|g" go-echo-api-onepod-template.yaml > go-echo-api-onepod.yaml
cat go-echo-api-onepod.yaml

kubectl get namespaces
kubectl apply -f go-echo-api-onepod.yaml -n echo-test --dry-run=client
```

Confirm Pod logs and configuration after deployment:

```bash
kubectl logs -l app=go-echo-api-onepod -n echo-test

kubectl describe pods -n echo-test

kubectl get ingress go-echo-api-onepod-ingress -n echo-test
```

## 2.2. Deploy for Scaling Test

To check request per seconds(RPS) with scaling, create and deploy K8s Deployment, Service, HorizontalPodAutoscaler, Ingress, and GKE BackendConfig using the [go-echo-api-template.yaml](app/go-echo-api-template.yaml) template file:

```bash
sed -e "s|<project-id>|${PROJECT_ID}|g" go-echo-api-template.yaml > go-echo-api.yaml
cat go-echo-api.yaml

kubectl apply -f go-echo-api.yaml -n echo-test --dry-run=client
```

```bash
kubectl apply -f go-echo-api.yaml -n echo-test
```

Confirm Pod logs and configuration after deployment:

```bash
kubectl logs -l app=go-echo-api -n echo-test

kubectl describe pods -n echo-test

kubectl get ingress go-echo-api-ingress -n echo-test
```

Confirm that response of `/` API.

```bash
LB_IP_ADDRESS=$(gcloud compute forwarding-rules list | grep go-echo-api | awk '{ print $2 }')
echo ${LB_IP_ADDRESS}
```

```bash
curl http://${LB_IP_ADDRESS}/
```

## 3. Performance Testing

### 3.1. Install the Taurus

<https://gettaurus.org/install/Installation/>

```bash
sudo apt-get update -y
sudo apt-get install python3 default-jre-headless python3-tk python3-pip python3-dev libxml2-dev libxslt-dev zlib1g-dev net-tools  -y
sudo python3 -m pip install bzt
sudo apt-get install htop -y
```

### 3.2. Test for performance of one Pod

```bash
cd test
# test with 300 threads and connection:close option
bzt echo-bzt-onepod.yaml
```

[test/echo-bzt-onepod.yaml](./test/echo-bzt-onepod.yaml)

```bash
kubectl describe hpa go-echo-api-onepod-hpa -n echo-test

kubectl get hpa go-echo-api-onepod-hpa -n echo-test -w
```

### 3.3. Test with auto scaling

```bash
cd test
# test with 2000 threads and connection:close option
bzt echo-bzt.yaml
```

[test/echo-bzt.yaml](./test/echo-bzt.yaml)

```bash
kubectl describe hpa go-echo-api-hpa -n echo-test

kubectl get hpa go-echo-api-hpa -n echo-test -w
```

## Cleanup

```bash
kubectl scale deployment go-echo-api-onepod -n echo-test --replicas=0
kubectl scale deployment go-echo-api -n echo-test --replicas=0

kubectl delete -f app/go-echo-api-onepod.yaml -n echo-test
kubectl delete -f app/go-echo-api.yaml -n echo-test
kubectl delete namespace echo-test
```

## References

- <https://echo.labstack.com>

- [Cloud SDK > Documentation > Reference > gcloud container clusters](https://cloud.google.com/sdk/gcloud/reference/container/clusters)

- [Google Kubernetes Engine (GKE) > Documentation > Guides > GKE Ingress for HTTP(S) Load Balancing](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress)
