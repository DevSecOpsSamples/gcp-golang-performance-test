# API/Load Balancer performance test with the golang echo server on GKE

[![Build](https://github.com/DevSecOpsSamples/gcp-golang-performance-test/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/DevSecOpsSamples/gcp-golang-performance-test/actions/workflows/build.yml)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=DevSecOpsSamples_gcp-golang-performance-test&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=DevSecOpsSamples_gcp-golang-performance-test) [![Lines of Code](https://sonarcloud.io/api/project_badges/measure?project=DevSecOpsSamples_gcp-golang-performance-test&metric=ncloc)](https://sonarcloud.io/summary/new_code?id=DevSecOpsSamples_gcp-golang-performance-test)

Performance testing with https://echo.labstack.com application on GKE.


## Table of Contents

- [Step1: Create a GKE cluster and namespaces](#1-create-a-gke-cluster)
- [Step2: Build and push to GCR](#2-build-and-push-to-gcr)
- [Step3: Ingress with Network Endpoint Group (NEG)](#3-ingress-with-network-endpoint-groupneg)
    - Manifest
    - Deploy ingress-neg-api
    - Screenshots
- [Step4: LoadBalancer Type with NodePort](#4-loadbalancer-type-with-nodeport)
    - Manifest
    - Deploy loadbalancer-type-api
    - Screenshots
- [Step5: NodePort Type](#5-nodeport-type)
    - Manifest
    - Deploy nodeport-type-api
    - Create a firewall rule for the node port
- [Cleanup](#6-cleanup)

---

## Prerequisites

### Installation

- [Install the gcloud CLI](https://cloud.google.com/sdk/docs/install)
- [Install kubectl and configure cluster access](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl)
- [Installing and Upgrading for the Taurus ](https://gettaurus.org/install/Installation/)

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

Build and push to GCR:

```bash
cd app
docker build -t go-echo-api . --platform linux/amd64
docker tag go-echo-api:latest gcr.io/${PROJECT_ID}/go-echo-api:latest

gcloud auth configure-docker
docker push gcr.io/${PROJECT_ID}/go-echo-api:latest
```

```bash
kubectl get namespaces

kubectl create namespace echo-test
```

Two ddeployments may take around 5 minutes to create a load balancer, including health checking.

## 3. Deploy for performance of one Pod

To check request per seconds(RPS) WITHOUT scaling, create and deploy K8s Deployment, Service, HorizontalPodAutoscaler, Ingress, and GKE BackendConfig using the [go-echo-api-onepod-template.yaml](app/go-echo-api-onepod-template.yaml) template file:

```bash
sed -e "s|<project-id>|${PROJECT_ID}|g" go-echo-api-onepod-template.yaml > go-echo-api-onepod.yaml
cat go-echo-api-onepod.yaml

kubectl get namespaces
kubectl apply -f go-echo-api-onepod.yaml -n echo-test --dry-run=client
```

Confirm that pod configuration and logs after deployment:

```bash
kubectl logs -l app=go-echo-api-onepod -n echo-test

kubectl describe pods -n echo-test

kubectl get ingress go-echo-api-onepod-ingress -n echo-test
```

## 4. Deploy for Scaling Test

To check request per seconds(RPS) with scaling, create and deploy K8s Deployment, Service, HorizontalPodAutoscaler, Ingress, and GKE BackendConfig using the [go-echo-api-template.yaml](app/go-echo-api-template.yaml) template file:

```bash
sed -e "s|<project-id>|${PROJECT_ID}|g" go-echo-api-template.yaml > go-echo-api.yaml
cat go-echo-api.yaml

kubectl apply -f go-echo-api.yaml -n echo-test --dry-run=client
```

```bash
kubectl apply -f go-echo-api.yaml -n echo-test
```

Confirm that pod configuration and logs after deployment:

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

## 5. Performance Testing

### 5.1. Performance of one Pod

```bash
cd test
bzt echo-bzt.yaml
```

[test/echo-bzt.yaml](./test/echo-bzt.yaml)

```bash
kubectl describe hpa go-echo-api-onepod-hpa -n echo-test

kubectl get hpa go-echo-api-onepod-hpa -n echo-test -w
```


### 5.2. Scaling test

https://gettaurus.org/install/Installation/

```bash
sudo apt-get update -y
sudo apt-get install python3 default-jre-headless python3-tk python3-pip python3-dev libxml2-dev libxslt-dev zlib1g-dev net-tools  -y
sudo python3 -m pip install bzt
sudo apt-get install htop -y
```

```bash
cd test
bzt echo-bzt.yaml
```

```bash
kubectl describe hpa go-echo-api-hpa -n echo-test

kubectl get hpa go-echo-api-hpa -n echo-test -w
```

```bash
kubectl scale deployment go-echo-api -n echo-test --replicas=0
```

## Cleanup

```bash
kubectl scale deployment go-echo-api-onepod -n echo-test --replicas=0
kubectl scale deployment go-echo-api -n echo-test --replicas=0

kubectl delete -f app/go-echo-api-onepod.yaml -n echo-test
kubectl delete -f app/go-echo-api.yaml -n echo-test
```

## References

- https://echo.labstack.com

- [Cloud SDK > Documentation > Reference > gcloud container clusters](https://cloud.google.com/sdk/gcloud/reference/container/clusters)

- [Google Kubernetes Engine (GKE) > Documentation > Guides > GKE Ingress for HTTP(S) Load Balancing](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress)
