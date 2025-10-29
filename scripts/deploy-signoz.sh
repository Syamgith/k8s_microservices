#!/bin/bash

set -e

echo "Deploying Signoz to Kubernetes..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${RED}Error: helm is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed.${NC}"
    exit 1
fi

# Verify cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Kubernetes cluster is not running.${NC}"
    echo "Please run ./scripts/setup-cluster.sh first."
    exit 1
fi

# Add Signoz Helm repository
echo -e "${GREEN}Adding Signoz Helm repository...${NC}"
helm repo add signoz https://charts.signoz.io
helm repo update

# Create signoz namespace if it doesn't exist
kubectl create namespace signoz --dry-run=client -o yaml | kubectl apply -f -

# Install or upgrade Signoz
echo -e "${GREEN}Installing Signoz (this may take a few minutes)...${NC}"
helm upgrade --install signoz signoz/signoz \
  --namespace signoz \
  --values kubernetes/signoz/values.yaml \
  --wait \
  --timeout 10m

# Wait for all pods to be ready
echo -e "${GREEN}Waiting for Signoz pods to be ready...${NC}"
kubectl wait --for=condition=ready pod \
  --all \
  --namespace=signoz \
  --timeout=300s

# Get pod status
echo -e "${GREEN}✓ Signoz deployed successfully!${NC}"
echo ""
echo "Pod Status:"
kubectl get pods -n signoz
echo ""
echo "Services:"
kubectl get svc -n signoz

# Display access information
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Signoz UI Access Information:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Signoz UI is accessible at: http://localhost:30000"
echo ""
echo "To access the UI, keep this terminal open or run in another terminal:"
echo "  kubectl port-forward -n signoz svc/signoz-frontend 3301:3301"
echo ""
echo "Then access Signoz at: http://localhost:3301"
echo ""
echo "OpenTelemetry Collector endpoints:"
echo "  - OTLP gRPC: signoz-otel-collector.signoz.svc.cluster.local:4317"
echo "  - OTLP HTTP: signoz-otel-collector.signoz.svc.cluster.local:4318"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
