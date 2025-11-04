#!/bin/bash

set -e

echo "========================================================="
echo "  Deploying Microservices (Optimized for Limited CPU)"
echo "========================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed.${NC}"
    exit 1
fi

# Check if Signoz is deployed
if ! kubectl get namespace signoz &> /dev/null; then
    echo -e "${RED}Error: Signoz namespace not found.${NC}"
    echo "Please run ./scripts/deploy-signoz.sh first."
    exit 1
fi

echo -e "${YELLOW}This will delete and recreate the microservices-demo namespace.${NC}"
echo -e "${YELLOW}Services will be deployed with reduced resource requests to fit in 2 nodes.${NC}"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Delete existing namespace
echo -e "${GREEN}Cleaning up existing deployment...${NC}"
kubectl delete namespace microservices-demo --ignore-not-found=true
sleep 5

# Create namespace
kubectl create namespace microservices-demo

# Download manifests
TEMP_DIR="/tmp/microservices-demo"
if [ ! -d "$TEMP_DIR" ]; then
    echo -e "${GREEN}Downloading microservices-demo manifests...${NC}"
    git clone --depth 1 https://github.com/GoogleCloudPlatform/microservices-demo.git "$TEMP_DIR"
fi

# Download and modify manifests to reduce resources
echo -e "${GREEN}Preparing optimized manifests...${NC}"
MANIFEST_FILE="/tmp/microservices-optimized.yaml"
cp "$TEMP_DIR/release/kubernetes-manifests.yaml" "$MANIFEST_FILE"

# Use sed to reduce CPU/memory in the manifest before applying
# This is faster than patching after deployment
sed -i.bak 's/cpu: 100m/cpu: 50m/g' "$MANIFEST_FILE" 2>/dev/null || sed -i '' 's/cpu: 100m/cpu: 50m/g' "$MANIFEST_FILE"
sed -i.bak 's/cpu: 200m/cpu: 50m/g' "$MANIFEST_FILE" 2>/dev/null || sed -i '' 's/cpu: 200m/cpu: 50m/g' "$MANIFEST_FILE"
sed -i.bak 's/memory: 180Mi/memory: 100Mi/g' "$MANIFEST_FILE" 2>/dev/null || sed -i '' 's/memory: 180Mi/memory: 100Mi/g' "$MANIFEST_FILE"
sed -i.bak 's/memory: 256Mi/memory: 128Mi/g' "$MANIFEST_FILE" 2>/dev/null || sed -i '' 's/memory: 256Mi/memory: 128Mi/g' "$MANIFEST_FILE"

# Apply optimized manifests
echo -e "${GREEN}Applying optimized microservices manifests...${NC}"
kubectl apply -f "$MANIFEST_FILE" -n microservices-demo

# Wait for initial deployment
echo -e "${GREEN}Waiting for initial deployment (30 seconds)...${NC}"
sleep 30

# Scale to 1 replica and disable loadgenerator
echo -e "${GREEN}Scaling to 1 replica per service...${NC}"
SERVICES=(
  "emailservice" "checkoutservice" "recommendationservice"
  "frontend" "paymentservice" "productcatalogservice"
  "cartservice" "currencyservice" "shippingservice" "adservice"
)

for service in "${SERVICES[@]}"; do
    kubectl scale deployment "$service" --replicas=1 -n microservices-demo 2>/dev/null || echo "Skipped $service"
done

# Disable loadgenerator (we'll use Locust instead)
kubectl scale deployment loadgenerator --replicas=0 -n microservices-demo 2>/dev/null || echo "No loadgenerator"

# Patch with OTEL config
echo -e "${GREEN}Adding OpenTelemetry configuration...${NC}"
for service in "${SERVICES[@]}"; do
    echo "Configuring OTEL for $service..."
    kubectl set env deployment/$service \
      OTEL_EXPORTER_OTLP_ENDPOINT=http://signoz-otel-collector.signoz.svc.cluster.local:4317 \
      OTEL_EXPORTER_OTLP_INSECURE=true \
      OTEL_RESOURCE_ATTRIBUTES=service.namespace=microservices-demo \
      -n microservices-demo 2>/dev/null || echo "Warning: Could not configure $service"
done

# Wait for rolling update
echo -e "${GREEN}Waiting for rolling update (45 seconds)...${NC}"
sleep 45

# Clean up old ReplicaSets (ones with READY=0)
echo -e "${GREEN}Cleaning up old ReplicaSets...${NC}"
sleep 10

# Loop through and delete ReplicaSets with 0 ready replicas
kubectl get replicasets -n microservices-demo --no-headers | while read name desired current ready age; do
  if [ "$ready" == "0" ]; then
    echo "  Deleting: $name"
    kubectl delete replicaset "$name" -n microservices-demo 2>/dev/null || true
  fi
done

# Wait for cleanup
sleep 10

# Delete any remaining pending pods
echo -e "${GREEN}Cleaning up pending pods...${NC}"
kubectl delete pod --field-selector status.phase=Pending -n microservices-demo 2>/dev/null || true

# Final status check
echo ""
echo -e "${GREEN}✓ Optimized deployment complete!${NC}"
echo ""
echo "Pod Status:"
kubectl get pods -n microservices-demo
echo ""
echo "Resource Requests Per Service:"
kubectl get deployments -n microservices-demo -o custom-columns=NAME:.metadata.name,REPLICAS:.spec.replicas,CPU:.spec.template.spec.containers[0].resources.requests.cpu,MEMORY:.spec.template.spec.containers[0].resources.requests.memory

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Resource Optimization:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}✅ CPU per service: 50m (down from 100-200m)${NC}"
echo -e "${BLUE}✅ Memory per service: 100-128Mi (down from 180-256Mi)${NC}"
echo -e "${BLUE}✅ Total CPU saved: ~50% reduction${NC}"
echo -e "${BLUE}✅ This leaves room for Locust!${NC}"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Next Steps:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. Deploy Locust:"
echo "   ./scripts/deploy-locust.sh"
echo ""
echo "2. Expose services publicly:"
echo "   ./scripts/expose-services-public.sh"
echo ""
