#!/bin/bash

set -e

echo "Deploying Google Microservices Demo (Clean Version)..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed.${NC}"
    exit 1
fi

# Verify cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Kubernetes cluster is not running.${NC}"
    exit 1
fi

# Check if Signoz is deployed
if ! kubectl get namespace signoz &> /dev/null; then
    echo -e "${YELLOW}Warning: Signoz namespace not found.${NC}"
    echo "Please run ./scripts/deploy-signoz.sh first."
    exit 1
fi

echo -e "${YELLOW}This will delete and recreate the microservices-demo namespace.${NC}"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Delete existing namespace to start fresh
echo -e "${GREEN}Cleaning up existing deployment...${NC}"
kubectl delete namespace microservices-demo --ignore-not-found=true
sleep 5

# Create namespace
kubectl create namespace microservices-demo

# Download the original manifests
TEMP_DIR="/tmp/microservices-demo"
if [ ! -d "$TEMP_DIR" ]; then
    echo -e "${GREEN}Downloading microservices-demo manifests...${NC}"
    git clone --depth 1 https://github.com/GoogleCloudPlatform/microservices-demo.git "$TEMP_DIR"
fi

# Apply the base manifests
echo -e "${GREEN}Applying base microservices manifests...${NC}"
kubectl apply -f "$TEMP_DIR/release/kubernetes-manifests.yaml" -n microservices-demo

# Wait for initial deployment
echo -e "${GREEN}Waiting for initial deployment (30 seconds)...${NC}"
sleep 30

# Scale all deployments to 1 replica
echo -e "${GREEN}Scaling deployments to 1 replica...${NC}"
SERVICES=(
  "emailservice"
  "checkoutservice"
  "recommendationservice"
  "frontend"
  "paymentservice"
  "productcatalogservice"
  "cartservice"
  "currencyservice"
  "shippingservice"
  "adservice"
)

for service in "${SERVICES[@]}"; do
    kubectl scale deployment "$service" --replicas=1 -n microservices-demo 2>/dev/null || echo "Skipped $service"
done

# Disable loadgenerator (we'll use Locust)
kubectl scale deployment loadgenerator --replicas=0 -n microservices-demo 2>/dev/null || echo "No loadgenerator found"

# Patch deployments with OTEL config
echo -e "${GREEN}Patching services with OpenTelemetry configuration...${NC}"

for service in "${SERVICES[@]}"; do
    echo "Patching $service..."
    kubectl set env deployment/$service \
      OTEL_EXPORTER_OTLP_ENDPOINT=http://signoz-otel-collector.signoz.svc.cluster.local:4317 \
      OTEL_EXPORTER_OTLP_INSECURE=true \
      OTEL_RESOURCE_ATTRIBUTES=service.namespace=microservices-demo \
      -n microservices-demo 2>/dev/null || echo "Warning: Could not patch $service"
done

# Wait for rolling update
echo -e "${GREEN}Waiting for rolling update (60 seconds)...${NC}"
sleep 60

# Clean up old ReplicaSets
echo -e "${GREEN}Cleaning up old ReplicaSets...${NC}"

# Get all ReplicaSets and delete ones with 0 ready replicas
kubectl get replicasets -n microservices-demo --no-headers | while read name desired current ready age; do
  if [ "$ready" == "0" ]; then
    echo "Deleting old ReplicaSet: $name (ready=$ready)"
    kubectl delete replicaset "$name" -n microservices-demo 2>/dev/null || echo "Already deleted"
  fi
done

# Wait a moment for cleanup
sleep 10

# Force scale again to ensure only 1 replica
echo -e "${GREEN}Final scaling to 1 replica...${NC}"
for service in "${SERVICES[@]}"; do
    kubectl scale deployment "$service" --replicas=1 -n microservices-demo 2>/dev/null
done

# Wait for deployments
echo -e "${GREEN}Waiting for services to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s \
  deployment/frontend \
  -n microservices-demo || echo "Warning: Some services may not be ready yet"

# Get pod status
echo ""
echo -e "${GREEN}✓ Microservices demo deployed successfully!${NC}"
echo ""
echo "Pod Status:"
kubectl get pods -n microservices-demo
echo ""
echo "ReplicaSets:"
kubectl get replicasets -n microservices-demo

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Next Steps:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. Deploy Locust: ./scripts/deploy-locust.sh"
echo "2. Expose services: ./scripts/expose-services-public.sh"
echo ""
