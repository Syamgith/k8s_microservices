#!/bin/bash

echo "==========================================="
echo "  Verifying OpenTelemetry Data Flow"
echo "==========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}1. Checking OTEL Collector in microservices-demo namespace...${NC}"
COLLECTOR_POD=$(kubectl get pods -n microservices-demo -l app.kubernetes.io/component=opentelemetry-collector -o name 2>/dev/null | head -1)

if [ -n "$COLLECTOR_POD" ]; then
    echo -e "${GREEN}✓ OTEL Collector found: $COLLECTOR_POD${NC}"
    echo ""
    echo "Recent collector logs (looking for received spans/metrics):"
    kubectl logs -n microservices-demo $COLLECTOR_POD --tail=50 | grep -E "(Span|Metric|trace|metric)" || echo "  No telemetry data found in logs"
else
    echo -e "${YELLOW}⚠ No OTEL Collector found in microservices-demo namespace${NC}"
    echo "  Telemetry will go directly to Signoz collector"
fi

echo ""
echo -e "${BLUE}2. Checking Signoz OTEL Collector...${NC}"
echo "Recent Signoz collector logs (looking for received data):"
kubectl logs -n signoz deployment/signoz-otel-collector --tail=100 | grep -E "(Span|Metric|Log|trace|metric)" | tail -20 || echo "  No telemetry data found"

echo ""
echo -e "${BLUE}3. Checking a frontend pod for OTEL instrumentation...${NC}"
FRONTEND_POD=$(kubectl get pods -n microservices-demo -l app=frontend -o name | head -1)

if [ -n "$FRONTEND_POD" ]; then
    echo "Pod: $FRONTEND_POD"
    echo ""
    echo "Checking for OTEL environment variables:"
    kubectl exec -n microservices-demo $FRONTEND_POD -- env | grep OTEL || echo "  No OTEL env vars found"

    echo ""
    echo "Checking pod annotations:"
    kubectl get -n microservices-demo $FRONTEND_POD -o jsonpath='{.metadata.annotations}' | grep instrumentation || echo "  No instrumentation annotations found"

    echo ""
    echo "Checking for init containers (sign of auto-instrumentation):"
    kubectl get -n microservices-demo $FRONTEND_POD -o jsonpath='{.spec.initContainers[*].name}' || echo "  No init containers"
    echo ""
fi

echo ""
echo -e "${BLUE}4. Testing OTLP endpoint connectivity...${NC}"
echo "Testing from frontend pod to OTEL collector:"
kubectl exec -n microservices-demo $FRONTEND_POD -- sh -c "command -v telnet >/dev/null 2>&1 && telnet -v signoz-otel-collector.signoz.svc.cluster.local 4317 </dev/null 2>&1 | head -3 || echo 'telnet not available - trying curl...'; command -v curl >/dev/null 2>&1 && curl -v telnet://signoz-otel-collector.signoz.svc.cluster.local:4317 2>&1 | head -5 || echo 'Neither telnet nor curl available in container'" 2>/dev/null || echo "Could not test connectivity"

echo ""
echo -e "${BLUE}5. Checking OpenTelemetry Operator status...${NC}"
if kubectl get namespace opentelemetry-operator-system &>/dev/null; then
    echo -e "${GREEN}✓ OpenTelemetry Operator namespace exists${NC}"
    kubectl get deployment -n opentelemetry-operator-system
    echo ""
    echo "Instrumentation resources:"
    kubectl get instrumentation -n microservices-demo
else
    echo -e "${YELLOW}⚠ OpenTelemetry Operator not installed${NC}"
fi

echo ""
echo -e "${BLUE}6. Summary of services and their languages:${NC}"
echo "────────────────────────────────────────────────────"
echo "Service                  | Language  | Status"
echo "────────────────────────────────────────────────────"
echo "frontend                 | Go        | $(kubectl get deployment frontend -n microservices-demo -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo 0)/1"
echo "checkoutservice          | Go        | $(kubectl get deployment checkoutservice -n microservices-demo -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo 0)/1"
echo "cartservice              | .NET      | $(kubectl get deployment cartservice -n microservices-demo -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo 0)/1"
echo "productcatalogservice    | Go        | $(kubectl get deployment productcatalogservice -n microservices-demo -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo 0)/1"
echo "paymentservice           | Node.js   | $(kubectl get deployment paymentservice -n microservices-demo -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo 0)/1"
echo "shippingservice          | Go        | $(kubectl get deployment shippingservice -n microservices-demo -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo 0)/1"
echo "currencyservice          | Node.js   | $(kubectl get deployment currencyservice -n microservices-demo -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo 0)/1"
echo "adservice                | Java      | $(kubectl get deployment adservice -n microservices-demo -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo 0)/1"
echo "────────────────────────────────────────────────────"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Verification Complete${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
