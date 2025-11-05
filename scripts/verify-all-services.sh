#!/bin/bash

echo "==========================================="
echo "  Verifying All Services Configuration"
echo "==========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SERVICES="frontend checkoutservice cartservice productcatalogservice paymentservice shippingservice currencyservice adservice"

echo -e "${BLUE}Checking OTEL configuration for all services...${NC}"
echo ""
echo "────────────────────────────────────────────────────────────"

for service in $SERVICES; do
    echo -e "${YELLOW}Service: $service${NC}"

    # Check if deployment exists
    if ! kubectl get deployment $service -n microservices-demo &>/dev/null; then
        echo -e "  ${RED}✗ Deployment not found${NC}"
        echo ""
        continue
    fi

    # Check pod status
    READY=$(kubectl get deployment $service -n microservices-demo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    DESIRED=$(kubectl get deployment $service -n microservices-demo -o jsonpath='{.spec.replicas}')

    if [ "$READY" == "$DESIRED" ]; then
        echo -e "  ${GREEN}✓ Pod Status: $READY/$DESIRED Running${NC}"
    else
        echo -e "  ${RED}✗ Pod Status: $READY/$DESIRED Running${NC}"
    fi

    # Check OTEL env vars
    ENABLE_TRACING=$(kubectl get deployment $service -n microservices-demo -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="ENABLE_TRACING")].value}' 2>/dev/null)
    COLLECTOR_ADDR=$(kubectl get deployment $service -n microservices-demo -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="COLLECTOR_SERVICE_ADDR")].value}' 2>/dev/null)
    OTEL_SERVICE_NAME=$(kubectl get deployment $service -n microservices-demo -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="OTEL_SERVICE_NAME")].value}' 2>/dev/null)

    if [ "$ENABLE_TRACING" == "1" ]; then
        echo -e "  ${GREEN}✓ ENABLE_TRACING: $ENABLE_TRACING${NC}"
    else
        echo -e "  ${RED}✗ ENABLE_TRACING: $ENABLE_TRACING (should be 1)${NC}"
    fi

    if [ -n "$COLLECTOR_ADDR" ]; then
        echo -e "  ${GREEN}✓ COLLECTOR_SERVICE_ADDR: $COLLECTOR_ADDR${NC}"
    else
        echo -e "  ${RED}✗ COLLECTOR_SERVICE_ADDR: not set${NC}"
    fi

    if [ -n "$OTEL_SERVICE_NAME" ]; then
        echo -e "  ${GREEN}✓ OTEL_SERVICE_NAME: $OTEL_SERVICE_NAME${NC}"
    else
        echo -e "  ${YELLOW}⚠ OTEL_SERVICE_NAME: not set${NC}"
    fi

    echo "────────────────────────────────────────────────────────────"
done

echo ""
echo -e "${BLUE}Checking Signoz collector for recent trace data...${NC}"
echo ""
kubectl logs -n signoz deployment/signoz-otel-collector --tail=20 --since=2m | grep -i "trace\|span" | tail -5 || echo "No recent trace data in last 2 minutes"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Summary${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Services currently in Signoz:"
echo "  • frontend"
echo "  • checkoutservice"
echo "  • productcatalogservice"
echo ""
echo "To see other services, they need to receive traffic!"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run traffic generator: ./scripts/generate-traffic.sh"
echo "2. Browse the app manually: http://4.187.134.143"
echo "3. Add items to cart and complete checkout"
echo "4. Check Signoz UI: http://4.187.154.189:8080"
echo ""
