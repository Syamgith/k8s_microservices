#!/bin/bash

set -e

echo "==========================================="
echo "  Restarting Services to Apply Config"
echo "==========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Problem identified:${NC}"
echo "  • currencyservice is using a 9-hour-old pod (before config fix)"
echo "  • paymentservice has duplicate pods with restarts"
echo "  • These services need to be restarted to pick up ENABLE_TRACING=1"
echo ""

# Step 1: Delete old ReplicaSets
echo -e "${BLUE}Step 1/3: Cleaning up old ReplicaSets...${NC}"
kubectl delete rs currencyservice-6c4f9c7f54 -n microservices-demo 2>/dev/null && echo "  ✓ Deleted old currencyservice ReplicaSet" || echo "  (already deleted)"
kubectl delete rs paymentservice-7bccf6d7ff -n microservices-demo 2>/dev/null && echo "  ✓ Deleted old paymentservice ReplicaSet" || echo "  (already deleted)"

# Clean up any other zero-replica ReplicaSets
echo "Cleaning up all zero-replica ReplicaSets..."
kubectl get rs -n microservices-demo -o json | \
  jq -r '.items[] | select(.spec.replicas==0) | .metadata.name' | \
  xargs -I {} kubectl delete rs {} -n microservices-demo 2>/dev/null || echo "  (no old ReplicaSets)"

echo ""
echo -e "${GREEN}✓ Cleanup complete${NC}"

# Step 2: Force restart deployments that aren't sending traces
echo ""
echo -e "${BLUE}Step 2/3: Force restarting services...${NC}"
echo ""

# Services that should send traces but aren't appearing in Signoz
SERVICES_TO_RESTART="currencyservice paymentservice shippingservice"

for service in $SERVICES_TO_RESTART; do
  echo "Restarting $service..."
  kubectl rollout restart deployment/$service -n microservices-demo
done

echo ""
echo -e "${GREEN}✓ Restart initiated for all services${NC}"

# Step 3: Wait and verify
echo ""
echo -e "${BLUE}Step 3/3: Waiting for pods to be ready (60 seconds)...${NC}"
sleep 60

echo ""
echo "Current pod status:"
kubectl get pods -n microservices-demo

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Services Restarted${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Restarted services:"
echo "  • currencyservice (Node.js) - converts currencies"
echo "  • paymentservice (Node.js) - processes payments"
echo "  • shippingservice (Go) - calculates shipping costs"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Wait 2-3 minutes for new pods to fully start"
echo "2. Generate traffic again: ./scripts/generate-traffic.sh"
echo "3. Check Signoz Services tab: http://4.187.154.189:8080"
echo "4. You should now see 6-7 services!"
echo ""
echo "Expected services in Signoz:"
echo "  ✓ frontend (already working)"
echo "  ✓ checkoutservice (already working)"
echo "  ✓ productcatalogservice (already working)"
echo "  ⏳ currencyservice (should appear after restart)"
echo "  ⏳ paymentservice (should appear after restart)"
echo "  ⏳ shippingservice (should appear after restart)"
echo "  ✗ cartservice (OTEL not implemented in this service)"
echo "  ✗ adservice (OTEL not implemented in this service)"
echo ""
