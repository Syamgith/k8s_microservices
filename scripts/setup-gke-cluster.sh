#!/bin/bash

set -e

echo "=========================================="
echo "  Setting up GKE Cluster"
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
ZONE="us-central1-a"
MACHINE_TYPE="e2-medium"  # Smaller for free trial (2 vCPUs, 4 GB RAM)
NUM_NODES="3"
PROJECT_ID=""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed.${NC}"
    echo ""
    echo "Install gcloud CLI:"
    echo "  macOS/Linux: curl https://sdk.cloud.google.com | bash"
    echo "  Or visit: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo -e "${YELLOW}Not authenticated with GCP. Running authentication...${NC}"
    gcloud auth login
fi

# Get or set project ID
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [ -z "$CURRENT_PROJECT" ]; then
    echo -e "${YELLOW}No GCP project configured.${NC}"
    echo "Enter your GCP Project ID:"
    read -r PROJECT_ID
    gcloud config set project "$PROJECT_ID"
else
    echo -e "${BLUE}Current GCP Project: $CURRENT_PROJECT${NC}"
    read -p "Use this project? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Enter your GCP Project ID:"
        read -r PROJECT_ID
        gcloud config set project "$PROJECT_ID"
    else
        PROJECT_ID=$CURRENT_PROJECT
    fi
fi

echo ""
echo -e "${BLUE}Cluster Configuration (Optimized for Free Trial):${NC}"
echo "  Name: $CLUSTER_NAME"
echo "  Zone: $ZONE"
echo "  Machine Type: $MACHINE_TYPE (2 vCPUs, 4 GB RAM per node)"
echo "  Nodes: $NUM_NODES"
echo "  Total Resources: 6 vCPUs, 12 GB RAM"
echo ""
echo -e "${GREEN}💰 FREE TRIAL INFO:${NC}"
echo -e "${GREEN}  • GCP offers \$300 free credits for 90 days${NC}"
echo -e "${GREEN}  • Estimated usage: ~\$0.15-0.20/hour (~\$3-5/day)${NC}"
echo -e "${GREEN}  • This demo uses ~\$1-2 of your \$300 credit (if completed in 5-6 hours)${NC}"
echo ""
echo -e "${YELLOW}⚠️  You MUST enable billing, but you won't be charged:${NC}"
echo -e "${YELLOW}  • Charges come from your \$300 free credit${NC}"
echo -e "${YELLOW}  • You won't be auto-charged after credits run out${NC}"
echo -e "${YELLOW}  • Remember to delete the cluster when done to conserve credits!${NC}"
echo ""
echo "Sign up for free trial: https://cloud.google.com/free"
echo ""
read -p "Continue with cluster creation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Enable required APIs
echo ""
echo -e "${BLUE}Step 1: Enabling required GCP APIs...${NC}"
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com

# Check if cluster already exists
if gcloud container clusters describe "$CLUSTER_NAME" --zone="$ZONE" &> /dev/null; then
    echo -e "${YELLOW}Cluster '$CLUSTER_NAME' already exists.${NC}"
    read -p "Delete and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting existing cluster..."
        gcloud container clusters delete "$CLUSTER_NAME" --zone="$ZONE" --quiet
    else
        echo "Using existing cluster."
        gcloud container clusters get-credentials "$CLUSTER_NAME" --zone="$ZONE"
        kubectl config current-context
        exit 0
    fi
fi

# Create GKE cluster
echo ""
echo -e "${BLUE}Step 2: Creating GKE cluster (this takes 5-10 minutes)...${NC}"
gcloud container clusters create "$CLUSTER_NAME" \
  --zone="$ZONE" \
  --machine-type="$MACHINE_TYPE" \
  --num-nodes="$NUM_NODES" \
  --disk-size=50 \
  --disk-type=pd-standard \
  --enable-autoscaling \
  --min-nodes=2 \
  --max-nodes=5 \
  --enable-autorepair \
  --enable-autoupgrade \
  --no-enable-ip-alias \
  --scopes=https://www.googleapis.com/auth/cloud-platform

# Get credentials
echo ""
echo -e "${BLUE}Step 3: Configuring kubectl...${NC}"
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone="$ZONE"

# Create namespaces
echo ""
echo -e "${BLUE}Step 4: Creating namespaces...${NC}"
kubectl create namespace signoz
kubectl create namespace microservices-demo
kubectl create namespace locust

# Verify
echo ""
echo -e "${GREEN}✓ GKE Cluster setup complete!${NC}"
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
echo "3. Access services (LoadBalancer IPs will be assigned automatically)"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Delete cluster when done to avoid charges:${NC}"
echo "   gcloud container clusters delete $CLUSTER_NAME --zone=$ZONE"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
