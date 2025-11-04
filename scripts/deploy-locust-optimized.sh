#!/bin/bash

set -e

echo "Deploying Locust (Optimized for Limited CPU)..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed.${NC}"
    exit 1
fi

# Check if microservices-demo is deployed
if ! kubectl get namespace microservices-demo &> /dev/null; then
    echo -e "${RED}Error: microservices-demo namespace not found.${NC}"
    echo "Please deploy microservices first."
    exit 1
fi

# Create locust namespace
kubectl create namespace locust --dry-run=client -o yaml | kubectl apply -f -

# Apply optimized Locust deployment
echo -e "${GREEN}Deploying Locust with reduced resources...${NC}"
kubectl apply -f kubernetes/locust/deployment-optimized.yaml

# Wait for deployments
echo -e "${GREEN}Waiting for Locust to be ready...${NC}"
kubectl wait --for=condition=available --timeout=120s \
  deployment/locust-master \
  -n locust 2>/dev/null || echo "Master may still be starting..."

kubectl wait --for=condition=available --timeout=120s \
  deployment/locust-worker \
  -n locust 2>/dev/null || echo "Worker may still be starting..."

# Get pod status
echo ""
echo -e "${GREEN}✓ Locust deployed successfully!${NC}"
echo ""
echo "Pod Status:"
kubectl get pods -n locust

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Resource Optimization:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}✅ Master: 50m CPU, 100Mi memory (down from 100m CPU, 128Mi)${NC}"
echo -e "${BLUE}✅ Worker: 1 replica only (down from 2)${NC}"
echo -e "${BLUE}✅ Worker: 50m CPU, 100Mi memory (down from 100m CPU, 128Mi)${NC}"
echo -e "${BLUE}✅ Total CPU: 100m (down from 300m) - 67% reduction!${NC}"
echo ""

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Locust Web UI Access:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Locust UI: http://localhost:30001 (NodePort)"
echo ""
echo "Or use port-forward:"
echo "  kubectl port-forward -n locust svc/locust-master 9089:8089"
echo "  Then visit: http://localhost:9089"
echo ""
echo -e "${YELLOW}Usage Instructions:${NC}"
echo "1. Open Locust UI in browser"
echo "2. Set users: 10-15 (start small with limited resources)"
echo "3. Set spawn rate: 1-2 per second"
echo "4. Click 'Start swarming'"
echo ""
echo -e "${YELLOW}Note:${NC} With 1 worker, limit concurrent users to ~15-20"
echo "      This is plenty for demo purposes!"
echo ""
