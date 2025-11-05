#!/bin/bash

set -e

echo "==========================================="
echo "  Fixing Google Microservices Demo OTEL"
echo "==========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Root cause found:${NC}"
echo "  ❌ We set wrong env vars (OTEL_EXPORTER_OTLP_ENDPOINT)"
echo "  ✅ Google's demo needs: ENABLE_TRACING + COLLECTOR_SERVICE_ADDR"
echo ""

# Step 1: Clean up the broken auto-instrumentation
echo -e "${BLUE}Step 1/4: Removing broken auto-instrumentation...${NC}"

# Delete the crashing OTEL collector
kubectl delete opentelemetrycollector otel-collector -n microservices-demo 2>/dev/null || echo "  (already removed)"

# Delete the instrumentation resource
kubectl delete instrumentation otel-instrumentation -n microservices-demo 2>/dev/null || echo "  (already removed)"

# Remove auto-instrumentation annotations from all services
SERVICES="frontend checkoutservice cartservice productcatalogservice paymentservice shippingservice currencyservice adservice"

for service in $SERVICES; do
  echo "  Removing annotations from $service..."
  kubectl patch deployment $service -n microservices-demo --type=json -p='[
    {"op": "remove", "path": "/spec/template/metadata/annotations/instrumentation.opentelemetry.io~1inject-go"},
    {"op": "remove", "path": "/spec/template/metadata/annotations/instrumentation.opentelemetry.io~1inject-nodejs"},
    {"op": "remove", "path": "/spec/template/metadata/annotations/instrumentation.opentelemetry.io~1inject-java"},
    {"op": "remove", "path": "/spec/template/metadata/annotations/instrumentation.opentelemetry.io~1inject-dotnet"},
    {"op": "remove", "path": "/spec/template/metadata/annotations/instrumentation.opentelemetry.io~1otel-go-auto-target-exe"}
  ]' 2>/dev/null || echo "  (no annotations to remove)"
done

echo ""
echo -e "${GREEN}✓ Cleanup complete${NC}"

# Step 2: Set the CORRECT environment variables
echo ""
echo -e "${BLUE}Step 2/4: Setting Google demo's required OTEL env vars...${NC}"
echo ""

# These are the env vars Google's demo actually uses:
# - ENABLE_TRACING=1
# - COLLECTOR_SERVICE_ADDR=<host>:4317
# - OTEL_SERVICE_NAME=<service-name>

echo "1/8 Configuring frontend..."
kubectl set env deployment/frontend -n microservices-demo \
  ENABLE_TRACING=1 \
  COLLECTOR_SERVICE_ADDR=signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_SERVICE_NAME=frontend

echo "2/8 Configuring checkoutservice..."
kubectl set env deployment/checkoutservice -n microservices-demo \
  ENABLE_TRACING=1 \
  COLLECTOR_SERVICE_ADDR=signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_SERVICE_NAME=checkoutservice

echo "3/8 Configuring cartservice..."
kubectl set env deployment/cartservice -n microservices-demo \
  ENABLE_TRACING=1 \
  COLLECTOR_SERVICE_ADDR=signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_SERVICE_NAME=cartservice

echo "4/8 Configuring productcatalogservice..."
kubectl set env deployment/productcatalogservice -n microservices-demo \
  ENABLE_TRACING=1 \
  COLLECTOR_SERVICE_ADDR=signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_SERVICE_NAME=productcatalogservice

echo "5/8 Configuring paymentservice..."
kubectl set env deployment/paymentservice -n microservices-demo \
  ENABLE_TRACING=1 \
  COLLECTOR_SERVICE_ADDR=signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_SERVICE_NAME=paymentservice

echo "6/8 Configuring shippingservice..."
kubectl set env deployment/shippingservice -n microservices-demo \
  ENABLE_TRACING=1 \
  COLLECTOR_SERVICE_ADDR=signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_SERVICE_NAME=shippingservice

echo "7/8 Configuring currencyservice..."
kubectl set env deployment/currencyservice -n microservices-demo \
  ENABLE_TRACING=1 \
  COLLECTOR_SERVICE_ADDR=signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_SERVICE_NAME=currencyservice

echo "8/8 Configuring adservice..."
kubectl set env deployment/adservice -n microservices-demo \
  ENABLE_TRACING=1 \
  COLLECTOR_SERVICE_ADDR=signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_SERVICE_NAME=adservice

echo ""
echo -e "${GREEN}✓ All services configured with correct env vars!${NC}"

# Step 3: Clean up old pods
echo ""
echo -e "${BLUE}Step 3/4: Cleaning up duplicate/old pods...${NC}"

# Wait for new pods to start
echo "Waiting 60 seconds for new pods to start..."
sleep 60

# Delete any old replica sets that are still hanging around
echo "Cleaning up old ReplicaSets..."
kubectl get rs -n microservices-demo -o json | \
  jq -r '.items[] | select(.spec.replicas==0) | .metadata.name' | \
  xargs -I {} kubectl delete rs {} -n microservices-demo 2>/dev/null || echo "  (no old ReplicaSets)"

echo ""
echo -e "${GREEN}✓ Cleanup complete${NC}"

# Step 4: Verify
echo ""
echo -e "${BLUE}Step 4/4: Verifying pod status...${NC}"
echo ""
kubectl get pods -n microservices-demo

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Fix Applied Successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "What was fixed:"
echo "  ✅ Removed broken auto-instrumentation"
echo "  ✅ Removed crashing intermediate OTEL collector"
echo "  ✅ Set ENABLE_TRACING=1 (Google's demo requirement)"
echo "  ✅ Set COLLECTOR_SERVICE_ADDR to Signoz collector"
echo "  ✅ Set OTEL_SERVICE_NAME for each service"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Wait 2-3 minutes for all pods to stabilize"
echo ""
echo "2. Generate traffic by browsing:"
echo "   http://4.187.134.143"
echo ""
echo "3. Check Signoz for traces (should appear in 2-3 minutes):"
echo "   http://4.187.154.189:8080"
echo ""
echo "4. If still no data, check service logs:"
echo "   kubectl logs -n microservices-demo deployment/frontend --tail=50"
echo ""
echo "5. Check Signoz collector for incoming traces:"
echo "   kubectl logs -n signoz deployment/signoz-otel-collector --tail=50 | grep -i span"
echo ""
