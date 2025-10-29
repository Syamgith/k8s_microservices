#!/bin/bash

set -e

echo "Deploying Locust for traffic generation..."

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
    echo "Please run ./scripts/setup-cluster.sh first."
    exit 1
fi

# Check if microservices-demo is deployed
if ! kubectl get namespace microservices-demo &> /dev/null; then
    echo -e "${YELLOW}Warning: microservices-demo namespace not found.${NC}"
    echo "Please run ./scripts/deploy-microservices-demo.sh first."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create locust namespace if it doesn't exist
kubectl create namespace locust --dry-run=client -o yaml | kubectl apply -f -

# Apply Locust deployment
echo -e "${GREEN}Deploying Locust master and workers...${NC}"
kubectl apply -f kubernetes/locust/deployment.yaml

# Wait for deployments to be ready
echo -e "${GREEN}Waiting for Locust to be ready...${NC}"
kubectl wait --for=condition=available --timeout=120s \
  deployment/locust-master \
  -n locust

kubectl wait --for=condition=available --timeout=120s \
  deployment/locust-worker \
  -n locust

# Get pod status
echo -e "${GREEN}✓ Locust deployed successfully!${NC}"
echo ""
echo "Pod Status:"
kubectl get pods -n locust
echo ""
echo "Services:"
kubectl get svc -n locust

# Display access information
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Locust Web UI Access Information:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Locust UI is accessible at: http://localhost:30001"
echo ""
echo "Alternative access using port-forward:"
echo "  kubectl port-forward -n locust svc/locust-master 8089:8089"
echo ""
echo "Then visit: http://localhost:8089"
echo ""
echo "Usage Instructions:"
echo "1. Open the Locust UI in your browser"
echo "2. Set number of users (start with 10-20 for testing)"
echo "3. Set spawn rate (2-5 users per second)"
echo "4. The target host is pre-configured"
echo "5. Click 'Start swarming' to begin load testing"
echo ""
echo "Configuration:"
echo "  - Master: 1 replica"
echo "  - Workers: 2 replicas (can be scaled with kubectl scale)"
echo "  - Target: http://frontend-external.microservices-demo.svc.cluster.local"
echo ""
echo "To scale workers:"
echo "  kubectl scale deployment/locust-worker --replicas=5 -n locust"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
