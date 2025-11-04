#!/bin/bash

set -e

echo "=========================================="
echo "  Exposing Services with Public IPs"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Converting services to LoadBalancer type...${NC}"
echo ""

# Patch Signoz frontend to LoadBalancer
echo "1. Exposing Signoz UI..."
kubectl patch svc signoz -n signoz -p '{"spec": {"type": "LoadBalancer"}}'

# Patch microservices frontend to LoadBalancer (already should be LoadBalancer)
echo "2. Exposing Application Frontend..."
kubectl patch svc frontend-external -n microservices-demo -p '{"spec": {"type": "LoadBalancer"}}'

# Patch Locust master to LoadBalancer
echo "3. Exposing Locust UI..."
kubectl patch svc locust-master -n locust -p '{"spec": {"type": "LoadBalancer"}}'

echo ""
echo -e "${YELLOW}Waiting for LoadBalancers to provision (this takes 2-3 minutes)...${NC}"
echo "Azure/GCP/AWS are creating public IPs and load balancers..."
echo ""

# Wait for external IPs
sleep 10

# Function to wait for external IP
wait_for_ip() {
    local namespace=$1
    local service=$2
    local max_wait=180
    local elapsed=0

    echo -n "Waiting for $service in $namespace..."
    while [ $elapsed -lt $max_wait ]; do
        IP=$(kubectl get svc $service -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        if [ -n "$IP" ] && [ "$IP" != "null" ]; then
            echo " ✓"
            return 0
        fi
        echo -n "."
        sleep 5
        elapsed=$((elapsed + 5))
    done
    echo " (still pending)"
    return 1
}

# Wait for each service
wait_for_ip "signoz" "signoz"
wait_for_ip "microservices-demo" "frontend-external"
wait_for_ip "locust" "locust-master"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Public Access URLs:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Get Signoz IP
SIGNOZ_IP=$(kubectl get svc signoz -n signoz -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
# Signoz UI is on port 3301 (frontend UI port)
SIGNOZ_PORT="3301"

if [ -n "$SIGNOZ_IP" ] && [ "$SIGNOZ_IP" != "null" ]; then
    echo -e "${BLUE}📊 Signoz UI:${NC}"
    echo "   http://$SIGNOZ_IP:$SIGNOZ_PORT"
    echo ""
else
    echo -e "${YELLOW}📊 Signoz UI: (Pending - check again in 1-2 minutes)${NC}"
    echo "   kubectl get svc signoz -n signoz"
    echo ""
fi

# Get App IP
APP_IP=$(kubectl get svc frontend-external -n microservices-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
APP_PORT=$(kubectl get svc frontend-external -n microservices-demo -o jsonpath='{.spec.ports[0].port}')
# If port is empty, default to 80
if [ -z "$APP_PORT" ]; then
    APP_PORT="80"
fi

if [ -n "$APP_IP" ] && [ "$APP_IP" != "null" ]; then
    echo -e "${BLUE}🛍️  Online Boutique (Application):${NC}"
    if [ "$APP_PORT" == "80" ]; then
        echo "   http://$APP_IP"
    else
        echo "   http://$APP_IP:$APP_PORT"
    fi
    echo ""
else
    echo -e "${YELLOW}🛍️  Application: (Pending - check again in 1-2 minutes)${NC}"
    echo "   kubectl get svc frontend-external -n microservices-demo"
    echo ""
fi

# Get Locust IP
LOCUST_IP=$(kubectl get svc locust-master -n locust -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
LOCUST_PORT=$(kubectl get svc locust-master -n locust -o jsonpath='{.spec.ports[0].port}')
# If port is empty, default to 8089
if [ -z "$LOCUST_PORT" ]; then
    LOCUST_PORT="8089"
fi

if [ -n "$LOCUST_IP" ] && [ "$LOCUST_IP" != "null" ]; then
    echo -e "${BLUE}🔥 Locust UI:${NC}"
    echo "   http://$LOCUST_IP:$LOCUST_PORT"
    echo ""
else
    echo -e "${YELLOW}🔥 Locust UI: (Pending - check again in 1-2 minutes)${NC}"
    echo "   kubectl get svc locust-master -n locust"
    echo ""
fi

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "  • These are PUBLIC URLs - share them with anyone!"
echo "  • LoadBalancers may take 2-3 minutes to fully provision"
echo "  • If still pending, run: kubectl get svc --all-namespaces"
echo "  • Don't forget to cleanup when done: ./scripts/cleanup-aks.sh"
echo ""
echo -e "${YELLOW}⚠️  Security Note:${NC}"
echo "  • These URLs are accessible to anyone on the internet"
echo "  • For production, add authentication or IP restrictions"
echo "  • This is fine for temporary demos"
echo ""

# Create a summary file
APP_URL="http://$APP_IP"
if [ "$APP_PORT" != "80" ]; then
    APP_URL="http://$APP_IP:$APP_PORT"
fi

cat > public-urls.txt <<EOF
Microservices Observability Demo - Public URLs
================================================

📊 Signoz UI (Observability Dashboard):
   http://$SIGNOZ_IP:$SIGNOZ_PORT

🛍️  Online Boutique (Application Frontend):
   $APP_URL

🔥 Locust UI (Traffic Generator):
   http://$LOCUST_IP:$LOCUST_PORT

Generated: $(date)

Note: If IPs show as empty, run this command to check:
  kubectl get svc --all-namespaces | grep LoadBalancer

Cleanup when done:
  ./scripts/cleanup-aks.sh
EOF

echo -e "${GREEN}✓ URLs saved to: public-urls.txt${NC}"
echo ""
