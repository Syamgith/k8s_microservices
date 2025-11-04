#!/bin/bash

set -e

echo "==========================================="
echo "  Configuring OpenTelemetry for Microservices"
echo "==========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Configuring services to send telemetry to Signoz...${NC}"
echo ""

# Configure each service
echo "1/8 Configuring frontend..."
kubectl set env deployment/frontend \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_EXPORTER_OTLP_INSECURE=true \
  -n microservices-demo

echo "2/8 Configuring checkoutservice..."
kubectl set env deployment/checkoutservice \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_EXPORTER_OTLP_INSECURE=true \
  -n microservices-demo

echo "3/8 Configuring cartservice..."
kubectl set env deployment/cartservice \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_EXPORTER_OTLP_INSECURE=true \
  -n microservices-demo

echo "4/8 Configuring productcatalogservice..."
kubectl set env deployment/productcatalogservice \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_EXPORTER_OTLP_INSECURE=true \
  -n microservices-demo

echo "5/8 Configuring paymentservice..."
kubectl set env deployment/paymentservice \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_EXPORTER_OTLP_INSECURE=true \
  -n microservices-demo

echo "6/8 Configuring shippingservice..."
kubectl set env deployment/shippingservice \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_EXPORTER_OTLP_INSECURE=true \
  -n microservices-demo

echo "7/8 Configuring currencyservice..."
kubectl set env deployment/currencyservice \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_EXPORTER_OTLP_INSECURE=true \
  -n microservices-demo

echo "8/8 Configuring adservice..."
kubectl set env deployment/adservice \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://signoz-otel-collector.signoz.svc.cluster.local:4317 \
  OTEL_EXPORTER_OTLP_INSECURE=true \
  -n microservices-demo

echo ""
echo -e "${GREEN}✓ All services configured!${NC}"
echo ""
echo "Waiting 60 seconds for pods to restart..."
sleep 60

echo ""
echo "Current pod status:"
kubectl get pods -n microservices-demo

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Next Steps:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. Browse the application to generate traffic:"
echo "   http://4.187.134.143"
echo ""
echo "2. Wait 2 minutes for data to appear in Signoz"
echo ""
echo "3. Open Signoz and click 'Services':"
echo "   http://4.187.154.189:8080"
echo ""
echo "4. You should see all your microservices with metrics!"
echo ""
