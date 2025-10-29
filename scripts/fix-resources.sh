#!/bin/bash

set -e

echo "Fixing resource constraints..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Reducing resource requests to fit in constrained environment...${NC}"

# Scale down Locust workers to 1
echo "Scaling Locust workers to 1..."
kubectl scale deployment/locust-worker --replicas=1 -n locust

# Reduce resource requests for Locust
echo "Patching Locust resource requests..."
kubectl set resources deployment/locust-master -n locust \
  --requests=cpu=50m,memory=64Mi \
  --limits=cpu=200m,memory=256Mi

kubectl set resources deployment/locust-worker -n locust \
  --requests=cpu=50m,memory=64Mi \
  --limits=cpu=200m,memory=128Mi

# Scale down non-essential microservices
echo "Scaling down non-essential services..."
kubectl scale deployment/recommendationservice --replicas=0 -n microservices-demo || true
kubectl scale deployment/adservice --replicas=0 -n microservices-demo || true

# Wait a bit for changes to apply
echo "Waiting for changes to apply..."
sleep 10

echo -e "${GREEN}Resource optimization complete!${NC}"
echo ""
echo "Checking pod status..."
echo ""
echo "Locust:"
kubectl get pods -n locust
echo ""
echo "Microservices (key services):"
kubectl get pods -n microservices-demo | grep -E "NAME|frontend|checkout|cart|payment|product"
echo ""
echo -e "${YELLOW}Note: Some microservices may still be starting. This is normal.${NC}"
echo -e "${YELLOW}Run 'kubectl get pods -n microservices-demo' to check full status.${NC}"
