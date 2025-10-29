#!/bin/bash

set -e

echo "Deploying Google Microservices Demo..."

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

# Check if Signoz is deployed
if ! kubectl get namespace signoz &> /dev/null; then
    echo -e "${YELLOW}Warning: Signoz namespace not found.${NC}"
    echo "Please run ./scripts/deploy-signoz.sh first."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create microservices-demo namespace if it doesn't exist
kubectl create namespace microservices-demo --dry-run=client -o yaml | kubectl apply -f -

# Download the original manifests if not already present
TEMP_DIR="/tmp/microservices-demo"
if [ ! -d "$TEMP_DIR" ]; then
    echo -e "${GREEN}Downloading microservices-demo manifests...${NC}"
    git clone --depth 1 https://github.com/GoogleCloudPlatform/microservices-demo.git "$TEMP_DIR"
fi

# Apply the base manifests with namespace override
echo -e "${GREEN}Applying base microservices manifests...${NC}"
kubectl apply -f "$TEMP_DIR/release/kubernetes-manifests.yaml" -n microservices-demo

# Apply OpenTelemetry configuration patches
echo -e "${GREEN}Applying OpenTelemetry configuration...${NC}"
kubectl apply -f kubernetes/microservices-demo/otel-configmap.yaml -n microservices-demo

# Patch deployments to include OpenTelemetry environment variables
echo -e "${GREEN}Patching services with OpenTelemetry configuration...${NC}"

# List of services to patch
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

# OpenTelemetry environment variables
OTEL_VARS='
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "server",
            "env": [
              {
                "name": "OTEL_EXPORTER_OTLP_ENDPOINT",
                "value": "http://signoz-otel-collector.signoz.svc.cluster.local:4317"
              },
              {
                "name": "OTEL_EXPORTER_OTLP_INSECURE",
                "value": "true"
              },
              {
                "name": "OTEL_SERVICE_NAME",
                "valueFrom": {
                  "fieldRef": {
                    "fieldPath": "metadata.labels['\''app'\'']"
                  }
                }
              },
              {
                "name": "OTEL_RESOURCE_ATTRIBUTES",
                "value": "service.namespace=microservices-demo"
              }
            ]
          }
        ]
      }
    }
  }
}
'

for service in "${SERVICES[@]}"; do
    echo "Patching $service..."
    kubectl patch deployment "$service" -n microservices-demo --type='strategic' --patch "$OTEL_VARS" || echo "Warning: Could not patch $service"
done

# Wait for deployments to be ready
echo -e "${GREEN}Waiting for services to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s \
  deployment/frontend \
  -n microservices-demo || echo "Warning: Some services may not be ready yet"

# Get pod status
echo -e "${GREEN}✓ Microservices demo deployed successfully!${NC}"
echo ""
echo "Pod Status:"
kubectl get pods -n microservices-demo
echo ""
echo "Services:"
kubectl get svc -n microservices-demo

# Display access information
FRONTEND_PORT=$(kubectl get svc frontend-external -n microservices-demo -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Application Access Information:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Frontend UI: http://localhost:30080"
echo ""
echo "To access the application:"
echo "  kubectl port-forward -n microservices-demo svc/frontend-external 8080:80"
echo ""
echo "Then visit: http://localhost:8080"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
