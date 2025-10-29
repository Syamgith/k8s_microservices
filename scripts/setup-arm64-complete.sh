#!/bin/bash

set -e

echo "=========================================="
echo "  Complete ARM64 Setup with Emulation"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if we're on ARM64
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    echo -e "${RED}This script is for ARM64 systems only.${NC}"
    echo "You're on $ARCH - use ./scripts/deploy-all.sh instead"
    exit 1
fi

echo -e "${BLUE}This will:${NC}"
echo "1. Enable QEMU emulation for x86_64 images"
echo "2. Delete existing cluster (if any)"
echo "3. Create fresh Kubernetes cluster"
echo "4. Deploy Signoz"
echo "5. Deploy microservices with emulation"
echo ""
echo -e "${YELLOW}Note: This takes ~15-20 minutes and uses QEMU emulation${NC}"
echo -e "${YELLOW}Performance will be ~50-70% of native (acceptable for dev)${NC}"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 1/5: Enabling QEMU Emulation${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
./scripts/enable-qemu-emulation.sh

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 2/5: Cleaning Up Existing Cluster${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
kind delete cluster --name microservices-demo 2>/dev/null || echo "No existing cluster"
sleep 3

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 3/5: Creating Fresh Kubernetes Cluster${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
./scripts/setup-cluster.sh

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 4/5: Deploying Signoz (5-10 minutes)${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
./scripts/deploy-signoz.sh

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 5/5: Deploying Microservices (5-10 minutes)${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Clean up microservices namespace first
kubectl delete deployment --all -n microservices-demo 2>/dev/null || true
kubectl delete svc --all -n microservices-demo 2>/dev/null || true
sleep 5

# Download fresh manifests
TEMP_DIR="/tmp/microservices-demo-emulated"
rm -rf "$TEMP_DIR"
git clone --depth 1 https://github.com/GoogleCloudPlatform/microservices-demo.git "$TEMP_DIR"

# Apply manifests
kubectl apply -f "$TEMP_DIR/release/kubernetes-manifests.yaml" -n microservices-demo

# Deploy OTEL collector
kubectl apply -f kubernetes/otel-collector/deployment.yaml

# Deploy Locust with reduced resources
kubectl apply -f kubernetes/locust/deployment.yaml

echo ""
echo "Waiting for services to start (emulation is slower)..."
sleep 60

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Current Status:"
echo ""
echo "Signoz:"
kubectl get pods -n signoz | grep -E "NAME|signoz-0|otel-collector"
echo ""
echo "Microservices (may still be starting):"
kubectl get pods -n microservices-demo | head -n 6

echo ""
echo -e "${YELLOW}Note: Pods may take 5-10 minutes to fully start with emulation${NC}"
echo ""
echo "Monitor with: kubectl get pods -n microservices-demo -w"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Access URLs:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "📊 Signoz: kubectl port-forward -n signoz svc/signoz-frontend 9090:3301"
echo "   http://localhost:9090"
echo ""
echo "🛍️  App: kubectl port-forward -n microservices-demo svc/frontend-external 9080:80"
echo "   http://localhost:9080"
echo ""
echo "🔥 Locust: kubectl port-forward -n locust svc/locust-master 9089:8089"
echo "   http://localhost:9089"
echo ""
#