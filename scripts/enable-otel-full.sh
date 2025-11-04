#!/bin/bash

set -e

echo "==========================================="
echo "  Fully Enabling OpenTelemetry"
echo "==========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Enabling full OpenTelemetry configuration...${NC}"
echo ""

# List of services
SERVICES="frontend checkoutservice cartservice productcatalogservice paymentservice shippingservice currencyservice adservice"

for service in $SERVICES; do
  echo "Configuring $service..."
  kubectl set env deployment/$service \
    OTEL_SERVICE_NAME=$service \
    OTEL_EXPORTER_OTLP_ENDPOINT=http://signoz-otel-collector.signoz.svc.cluster.local:4317 \
    OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://signoz-otel-collector.signoz.svc.cluster.local:4317 \
    OTEL_EXPORTER_OTLP_METRICS_ENDPOINT=http://signoz-otel-collector.signoz.svc.cluster.local:4317 \
    OTEL_EXPORTER_OTLP_INSECURE=true \
    OTEL_TRACES_EXPORTER=otlp \
    OTEL_METRICS_EXPORTER=otlp \
    OTEL_LOGS_EXPORTER=otlp \
    OTEL_RESOURCE_ATTRIBUTES=service.namespace=microservices-demo,deployment.environment=production \
    -n microservices-demo 2>/dev/null || echo "  Warning: Could not configure $service"
done

echo ""
echo -e "${GREEN}✓ Full OTEL configuration applied!${NC}"
echo ""
echo "Waiting 60 seconds for pods to restart..."
sleep 60

echo ""
echo "Pod status:"
kubectl get pods -n microservices-demo

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Next Steps:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. Browse the application:"
echo "   http://4.187.134.143"
echo ""
echo "2. Wait 2 minutes"
echo ""
echo "3. Check Signoz Services tab:"
echo "   http://4.187.154.189:8080"
echo ""
echo "4. If still no data, check OTEL collector logs:"
echo "   kubectl logs -n signoz deployment/signoz-otel-collector --tail=100 | grep -i trace"
echo ""
