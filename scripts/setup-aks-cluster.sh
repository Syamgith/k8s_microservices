#!/bin/bash

set -e

echo "=========================================="
echo "  Setting up Azure AKS Cluster"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CLUSTER_NAME="microservices-demo"
RESOURCE_GROUP="microservices-demo-rg"
LOCATION="eastus"
NODE_COUNT="2"
NODE_SIZE="Standard_B2s"  # 2 vCPU, 4GB RAM - cost-effective

# Check if az CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed.${NC}"
    echo ""
    echo "Install Azure CLI:"
    echo "  macOS: brew install azure-cli"
    echo "  Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    echo "  Or visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed.${NC}"
    echo "Install: az aks install-cli"
    exit 1
fi

# Check Azure login
echo -e "${BLUE}Checking Azure authentication...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged into Azure. Logging in...${NC}"
    az login
fi

# Display account info
ACCOUNT_NAME=$(az account show --query user.name --output tsv)
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
SUBSCRIPTION_NAME=$(az account show --query name --output tsv)

echo ""
echo -e "${BLUE}Azure Account: $ACCOUNT_NAME${NC}"
echo -e "${BLUE}Subscription: $SUBSCRIPTION_NAME${NC}"
echo -e "${BLUE}Subscription ID: $SUBSCRIPTION_ID${NC}"
echo ""

# Check credit balance
echo -e "${BLUE}Checking your Azure credits...${NC}"
echo "Visit: https://www.microsoftazuresponsorships.com/Balance"
echo ""

echo -e "${BLUE}Cluster Configuration (Optimized for Free Trial):${NC}"
echo "  Name: $CLUSTER_NAME"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  Node Size: $NODE_SIZE (2 vCPUs, 4 GB RAM per node)"
echo "  Node Count: $NODE_COUNT"
echo "  Total Resources: 4 vCPUs, 8 GB RAM"
echo ""
echo -e "${GREEN}💰 AZURE FREE TRIAL INFO:${NC}"
echo -e "${GREEN}  • You have \$200 credit for 30 days${NC}"
echo -e "${GREEN}  • AKS Control Plane: FREE (no charge!)${NC}"
echo -e "${GREEN}  • VM Nodes: ~\$0.04/hour per node (~\$0.08/hour total)${NC}"
echo -e "${GREEN}  • Total Cost: ~\$0.08/hour (~\$2/day)${NC}"
echo -e "${GREEN}  • This demo (5 hours): ~\$0.40 of your \$200 credit${NC}"
echo ""
echo -e "${YELLOW}💡 IMPORTANT:${NC}"
echo -e "${YELLOW}  • Delete cluster when done: ./scripts/cleanup-aks.sh${NC}"
echo -e "${YELLOW}  • You'll have ~\$199.60 credit remaining!${NC}"
echo ""
read -p "Continue with cluster creation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Check if resource group exists
echo ""
echo -e "${BLUE}Step 1: Creating resource group...${NC}"
if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${YELLOW}Resource group '$RESOURCE_GROUP' already exists.${NC}"
else
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
    echo -e "${GREEN}✓ Resource group created${NC}"
fi

# Check if cluster exists
if az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" &> /dev/null; then
    echo -e "${YELLOW}Cluster '$CLUSTER_NAME' already exists.${NC}"
    read -p "Delete and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting existing cluster..."
        az aks delete --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --yes --no-wait
        echo "Waiting for deletion to complete..."
        sleep 30
    else
        echo "Using existing cluster."
        az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing
        kubectl config current-context
        exit 0
    fi
fi

# Create AKS cluster
echo ""
echo -e "${BLUE}Step 2: Creating AKS cluster (this takes 5-10 minutes)...${NC}"
echo "This creates:"
echo "  - AKS control plane (FREE!)"
echo "  - Virtual network"
echo "  - VM scale set with nodes"
echo "  - Load balancer"
echo ""

az aks create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CLUSTER_NAME" \
  --node-count $NODE_COUNT \
  --node-vm-size "$NODE_SIZE" \
  --enable-managed-identity \
  --generate-ssh-keys \
  --network-plugin azure \
  --network-policy azure \
  --enable-addons monitoring \
  --no-wait

echo ""
echo -e "${YELLOW}Cluster creation started. Waiting for completion...${NC}"
echo "This takes 5-10 minutes. Please be patient..."
echo ""

# Wait for cluster to be ready
while true; do
    STATUS=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --query provisioningState --output tsv 2>/dev/null || echo "Creating")
    if [ "$STATUS" == "Succeeded" ]; then
        break
    elif [ "$STATUS" == "Failed" ]; then
        echo -e "${RED}Cluster creation failed!${NC}"
        exit 1
    fi
    echo -n "."
    sleep 10
done

echo ""
echo -e "${GREEN}✓ Cluster created successfully!${NC}"

# Get credentials
echo ""
echo -e "${BLUE}Step 3: Configuring kubectl...${NC}"
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing

# Create namespaces
echo ""
echo -e "${BLUE}Step 4: Creating namespaces...${NC}"
kubectl create namespace signoz
kubectl create namespace microservices-demo
kubectl create namespace locust

# Wait for nodes to be ready
echo ""
echo -e "${BLUE}Step 5: Waiting for nodes to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Verify
echo ""
echo -e "${GREEN}✓ AKS Cluster setup complete!${NC}"
echo ""
echo "Cluster Info:"
kubectl cluster-info
echo ""
echo "Nodes:"
kubectl get nodes
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Next Steps:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. Deploy Signoz:"
echo "   ./scripts/deploy-signoz.sh"
echo ""
echo "2. Deploy Microservices:"
echo "   ./scripts/deploy-all.sh"
echo ""
echo "3. Access services (LoadBalancer will create Azure LB automatically)"
echo ""
echo -e "${RED}⚠️  IMPORTANT: Delete cluster when done to conserve credits:${NC}"
echo "   ./scripts/cleanup-aks.sh"
echo ""
echo -e "${YELLOW}💰 Cost Tracking:${NC}"
echo "   Azure Portal → Cost Management + Billing"
echo "   https://portal.azure.com/#blade/Microsoft_Azure_Billing/ModernBillingMenuBlade/Overview"
echo ""
echo "   Check credit balance:"
echo "   https://www.microsoftazuresponsorships.com/Balance"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
