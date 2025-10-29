#!/bin/bash

set -e

echo "=========================================="
echo "  Deploying Complete Observability Stack"
echo "=========================================="
echo ""

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

# Verify cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Kubernetes cluster is not running.${NC}"
    echo "Please run ./scripts/setup-cluster.sh first."
    exit 1
fi

# Check if Signoz is running
echo -e "${BLUE}Step 1/4: Checking Signoz deployment...${NC}"
if ! kubectl get namespace signoz &> /dev/null; then
    echo -e "${RED}Error: Signoz namespace not found.${NC}"
    echo "Please run ./scripts/deploy-signoz.sh first."
    exit 1
fi

SIGNOZ_READY=$(kubectl get pods -n signoz -l app.kubernetes.io/component=signoz --no-headers 2>/dev/null | grep -c "Running" || echo "0")
if [ "$SIGNOZ_READY" -eq "0" ]; then
    echo -e "${YELLOW}Warning: Signoz may not be fully ready yet.${NC}"
    echo "Continuing anyway..."
fi
echo -e "${GREEN}✓ Signoz is deployed${NC}"
echo ""

# Step 2: Deploy Custom OTEL Collector
echo -e "${BLUE}Step 2/4: Deploying Custom OpenTelemetry Collector...${NC}"
kubectl apply -f kubernetes/otel-collector/deployment.yaml

echo "Waiting for OTEL Collector to be ready..."
kubectl wait --for=condition=available --timeout=120s \
  deployment/otel-collector \
  -n microservices-demo 2>/dev/null || echo "Timeout waiting for OTEL collector, but continuing..."

echo -e "${GREEN}✓ Custom OTEL Collector deployed${NC}"
echo ""

# Step 3: Deploy Microservices Demo
echo -e "${BLUE}Step 3/4: Deploying Microservices Demo...${NC}"

# Download the original manifests if not already present
TEMP_DIR="/tmp/microservices-demo"
if [ ! -d "$TEMP_DIR" ]; then
    echo "Downloading microservices-demo manifests..."
    git clone --depth 1 https://github.com/GoogleCloudPlatform/microservices-demo.git "$TEMP_DIR"
fi

# Apply the base manifests
echo "Applying microservices manifests..."
kubectl apply -f "$TEMP_DIR/release/kubernetes-manifests.yaml" -n microservices-demo

# Apply OpenTelemetry configuration
echo "Applying OpenTelemetry configuration..."
kubectl apply -f kubernetes/microservices-demo/otel-configmap.yaml -n microservices-demo

# Patch deployments with OTEL environment variables
echo "Patching services with OpenTelemetry configuration..."

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

# Wait a moment for deployments to exist
sleep 5

for service in "${SERVICES[@]}"; do
    echo "  Patching $service..."

    # Check if deployment exists
    if kubectl get deployment "$service" -n microservices-demo &>/dev/null; then
        # Add OTEL environment variables
        kubectl set env deployment/"$service" \
          OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.microservices-demo.svc.cluster.local:4317 \
          OTEL_EXPORTER_OTLP_INSECURE=true \
          OTEL_SERVICE_NAME="$service" \
          OTEL_RESOURCE_ATTRIBUTES=service.namespace=microservices-demo \
          -n microservices-demo 2>/dev/null || echo "    Warning: Could not patch $service"
    else
        echo "    Warning: Deployment $service not found, skipping"
    fi
done

echo "Waiting for microservices to be ready (this may take a few minutes)..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/frontend \
  -n microservices-demo 2>/dev/null || echo "Some services may still be starting..."

echo -e "${GREEN}✓ Microservices Demo deployed${NC}"
echo ""

# Step 4: Deploy Locust
echo -e "${BLUE}Step 4/4: Deploying Locust Traffic Generator...${NC}"
kubectl apply -f kubernetes/locust/deployment.yaml

echo "Waiting for Locust to be ready..."
kubectl wait --for=condition=available --timeout=120s \
  deployment/locust-master \
  -n locust 2>/dev/null || echo "Locust is still starting..."

kubectl wait --for=condition=available --timeout=120s \
  deployment/locust-worker \
  -n locust 2>/dev/null || echo "Locust workers are still starting..."

echo -e "${GREEN}✓ Locust deployed${NC}"
echo ""

# Display summary
echo ""
echo -e "${GREEN}=========================================="
echo "  Deployment Complete!"
echo -e "==========================================${NC}"
echo ""
echo "Pod Status:"
echo ""
echo "Signoz:"
kubectl get pods -n signoz | head -n 1
kubectl get pods -n signoz | grep -E "signoz-otel|signoz-0|clickhouse-cluster" | head -n 5
echo ""
echo "Microservices:"
kubectl get pods -n microservices-demo | head -n 1
kubectl get pods -n microservices-demo | grep -E "frontend|checkout|cart" | head -n 5
echo "  ... and $(kubectl get pods -n microservices-demo --no-headers | wc -l) more pods"
echo ""
echo "Locust:"
kubectl get pods -n locust
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Access Information:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "📊 Signoz UI (Observability Dashboard):"
echo "   kubectl port-forward -n signoz svc/signoz-frontend 9090:3301"
echo "   Then open: http://localhost:9090"
echo ""
echo "🛍️  Online Boutique (Application Frontend):"
echo "   kubectl port-forward -n microservices-demo svc/frontend-external 9080:80"
echo "   Then open: http://localhost:9080"
echo ""
echo "🔥 Locust UI (Traffic Generator):"
echo "   kubectl port-forward -n locust svc/locust-master 9089:8089"
echo "   Then open: http://localhost:9089"
echo ""
echo -e "${YELLOW}Quick Start Guide:${NC}"
echo "1. Open Signoz UI to see dashboards (may take a minute to populate)"
echo "2. Open Locust UI and start a load test:"
echo "   - Number of users: 20"
echo "   - Spawn rate: 2"
echo "   - Click 'Start swarming'"
echo "3. Return to Signoz to see metrics, traces, and logs flowing in"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "💡 Tip: Run these port-forwards in separate terminals to access all UIs"
echo ""
