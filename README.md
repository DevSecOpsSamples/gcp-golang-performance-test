# GCP performance test with golang echo server



## Prerequisites

### Installation

- [Install the gcloud CLI](https://cloud.google.com/sdk/docs/install)
- [Install kubectl and configure cluster access](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl)

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

## Create a GKE cluster

Create an Autopilot GKE cluster. It may take around 9 minutes.

```bash
gcloud container clusters create-auto sample-cluster --region=${COMPUTE_ZONE}
gcloud container clusters get-credentials sample-cluster
```

## Deploy go-echo-api

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

Create and deploy K8s Deployment, Service, HorizontalPodAutoscaler, Ingress, and GKE BackendConfig using the [go-echo-api-template.yaml](app/go-echo-api-template.yaml) template file.

```bash
sed -e "s|<project-id>|${PROJECT_ID}|g" go-echo-api-template.yaml > go-echo-api.yaml
cat go-echo-api.yaml

kubectl apply -f go-echo-api.yaml -n echo-test --dry-run=client
```

```bash
kubectl apply -f go-echo-api.yaml -n echo-test
```

It may take around 5 minutes to create a load balancer, including health checking.

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

## Performance Testing

```bash
cd test
bzt echo-bzt.yaml
```

```bash
# $JMETER_HOME/bin
./jmeter -t gpu-api.jmx -n  -j ../log/jmeter.log
```

[test/gpu-api.jmx](./test/gpu-api.jmx)

![prom-dcgm-metric](./screenshots/prom-dcgm-metric.png?raw=true)

![scalingtest-taurus.png](./screenshots/scalingtest-taurus.png?raw=true)

```bash
kubectl describe hpa gpu-api-hpa
```

## References

- [Cloud SDK > Documentation > Reference > gcloud container clusters](https://cloud.google.com/sdk/gcloud/reference/container/clusters)

- [Google Kubernetes Engine (GKE) > Documentation > Guides > GKE Ingress for HTTP(S) Load Balancing](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress)
