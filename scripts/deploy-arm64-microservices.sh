#!/bin/bash

set -e

echo "=========================================="
echo "  Deploying ARM64-Compatible Microservices"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check architecture
ARCH=$(uname -m)
echo -e "${BLUE}Detected architecture: $ARCH${NC}"
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    echo -e "${YELLOW}Warning: This script is optimized for ARM64. You're on $ARCH${NC}"
    echo -e "${YELLOW}Consider using ./scripts/deploy-all.sh instead${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

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

echo ""
echo -e "${YELLOW}Step 1: Cleaning up existing deployments...${NC}"
# Delete existing deployments in microservices-demo namespace
kubectl delete deployment --all -n microservices-demo 2>/dev/null || true
kubectl delete svc --all -n microservices-demo 2>/dev/null || true
kubectl delete configmap --all -n microservices-demo 2>/dev/null || true

echo "Waiting for cleanup..."
sleep 5

echo ""
echo -e "${YELLOW}Step 2: Downloading microservices-demo...${NC}"
TEMP_DIR="/tmp/microservices-demo-arm64"
rm -rf "$TEMP_DIR"
git clone --depth 1 https://github.com/GoogleCloudPlatform/microservices-demo.git "$TEMP_DIR"

echo ""
echo -e "${YELLOW}Step 3: Applying base manifests...${NC}"
echo "Note: Recent versions of microservices-demo include multi-arch images"
kubectl apply -f "$TEMP_DIR/release/kubernetes-manifests.yaml" -n microservices-demo

echo ""
echo -e "${YELLOW}Step 4: Deploying custom OTEL collector...${NC}"
kubectl apply -f kubernetes/otel-collector/deployment.yaml

echo ""
echo -e "${YELLOW}Step 5: Waiting for pods to initialize...${NC}"
echo "This may take 2-3 minutes for ARM64 images..."
sleep 30

echo ""
echo -e "${GREEN}Deployment initiated!${NC}"
echo ""
echo "Checking pod status..."
kubectl get pods -n microservices-demo

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Verification Steps:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. Monitor pod status (wait for all to be Running):"
echo "   kubectl get pods -n microservices-demo -w"
echo ""
echo "2. If you see 'exec format error' or 'CrashLoopBackOff':"
echo "   kubectl logs -n microservices-demo <pod-name>"
echo ""
echo "3. Check image architecture:"
echo "   kubectl get deployment frontend -n microservices-demo -o yaml | grep image:"
echo ""
echo -e "${YELLOW}Common Issues on ARM64:${NC}"
echo ""
echo "• If images don't support ARM64, you'll see 'exec format error'"
echo "• Solution 1: Wait for Google to update images (check their GitHub)"
echo "• Solution 2: Enable QEMU emulation (slower but works):"
echo "    docker run --privileged --rm tonistiigi/binfmt --install all"
echo "    Then restart the cluster"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Tip: Give it 2-3 minutes, then check status again${NC}"
echo ""
