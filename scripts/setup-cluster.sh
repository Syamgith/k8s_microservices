#!/bin/bash

set -e

echo "Setting up Kubernetes cluster for microservices observability demo..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo -e "${RED}Error: kind is not installed. Please install it first.${NC}"
    echo "Visit: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed. Please install it first.${NC}"
    exit 1
fi

# Cluster name
CLUSTER_NAME="microservices-demo"

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}Cluster '${CLUSTER_NAME}' already exists.${NC}"
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting existing cluster..."
        kind delete cluster --name "${CLUSTER_NAME}"
    else
        echo "Using existing cluster."
        kubectl cluster-info --context "kind-${CLUSTER_NAME}"
        exit 0
    fi
fi

# Create Kind cluster with config
echo -e "${GREEN}Creating Kind cluster '${CLUSTER_NAME}'...${NC}"
cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
  - containerPort: 30443
    hostPort: 30443
    protocol: TCP
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
  - containerPort: 30001
    hostPort: 30001
    protocol: TCP
  - containerPort: 30002
    hostPort: 30002
    protocol: TCP
EOF

# Wait for cluster to be ready
echo -e "${GREEN}Waiting for cluster to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=120s

# Create namespaces
echo -e "${GREEN}Creating namespaces...${NC}"
kubectl create namespace signoz || true
kubectl create namespace microservices-demo || true
kubectl create namespace locust || true

echo -e "${GREEN}✓ Cluster setup complete!${NC}"
echo ""
echo "Cluster info:"
kubectl cluster-info --context "kind-${CLUSTER_NAME}"
echo ""
echo "Namespaces:"
kubectl get namespaces
