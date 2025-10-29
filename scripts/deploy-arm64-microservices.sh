#!/bin/bash

set -e

echo "Deploying ARM64-compatible microservices demo..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Cleaning up existing deployments...${NC}"
kubectl delete deployment --all -n microservices-demo 2>/dev/null || true
kubectl delete svc --all -n microservices-demo 2>/dev/null || true
sleep 5

echo -e "${YELLOW}Downloading microservices-demo manifests...${NC}"
TEMP_DIR="/tmp/microservices-demo-arm"
rm -rf "$TEMP_DIR"
git clone --depth 1 https://github.com/GoogleCloudPlatform/microservices-demo.git "$TEMP_DIR"

echo -e "${YELLOW}Applying manifests (Google provides multi-arch images since v0.8.0)...${NC}"
# The latest release should have multi-arch support
kubectl apply -f "$TEMP_DIR/release/kubernetes-manifests.yaml" -n microservices-demo

echo -e "${YELLOW}Waiting for pods to initialize (this may take a few minutes)...${NC}"
sleep 20

echo ""
echo "Checking pod status:"
kubectl get pods -n microservices-demo

echo ""
echo -e "${GREEN}If you still see 'exec format error', we need to use a different approach.${NC}"
echo -e "${YELLOW}Run this to check: kubectl logs -n microservices-demo <pod-name>${NC}"
