#!/bin/bash

set -e

echo "Cleaning up and redeploying microservices..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Step 1: Delete all microservices deployments
echo -e "${YELLOW}Step 1: Cleaning up existing deployments...${NC}"
kubectl delete deployment --all -n microservices-demo
kubectl delete svc --all -n microservices-demo
kubectl delete configmap --all -n microservices-demo

# Wait for cleanup
echo "Waiting for cleanup to complete..."
sleep 5

# Step 2: Download fresh manifests
echo -e "${YELLOW}Step 2: Downloading fresh microservices-demo manifests...${NC}"
TEMP_DIR="/tmp/microservices-demo-clean"
rm -rf "$TEMP_DIR"
git clone --depth 1 https://github.com/GoogleCloudPlatform/microservices-demo.git "$TEMP_DIR"

# Step 3: Apply base manifests
echo -e "${YELLOW}Step 3: Applying base manifests...${NC}"
kubectl apply -f "$TEMP_DIR/release/kubernetes-manifests.yaml" -n microservices-demo

# Step 4: Wait for pods to start
echo -e "${YELLOW}Step 4: Waiting for pods to initialize...${NC}"
sleep 15

# Step 5: Check status
echo -e "${GREEN}Deployment complete!${NC}"
echo ""
echo "Pod Status:"
kubectl get pods -n microservices-demo

echo ""
echo -e "${YELLOW}Note: If pods are still crashing with 'exec format error', run:${NC}"
echo "kubectl get deployment frontend -n microservices-demo -o yaml | grep image:"
echo "This will show us which image is being used."
