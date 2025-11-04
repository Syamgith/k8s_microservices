#!/bin/bash

set -e

echo "=========================================="
echo "  Cleaning up Azure AKS Resources"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CLUSTER_NAME="microservices-demo"
RESOURCE_GROUP="microservices-demo-rg"

echo -e "${YELLOW}This will delete:${NC}"
echo "  - AKS Cluster: $CLUSTER_NAME"
echo "  - Resource Group: $RESOURCE_GROUP"
echo "  - All associated resources (Load Balancers, Disks, Network, etc.)"
echo ""
echo -e "${RED}This action cannot be undone!${NC}"
echo ""
read -p "Are you sure? (type 'yes' to confirm): " -r
echo

if [[ ! $REPLY == "yes" ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}Deleting resource group (this deletes everything)...${NC}"
echo "This may take 3-5 minutes..."

az group delete \
  --name "$RESOURCE_GROUP" \
  --yes \
  --no-wait

echo ""
echo -e "${GREEN}✓ Deletion initiated!${NC}"
echo ""
echo "The resource group and all resources are being deleted in the background."
echo ""
echo "To check deletion status:"
echo "  az group show --name $RESOURCE_GROUP"
echo ""
echo "Or visit Azure Portal:"
echo "  https://portal.azure.com/#blade/HubsExtension/BrowseResourceGroups"
echo ""
echo -e "${GREEN}💰 Your Azure credits have been conserved!${NC}"
echo "Check remaining balance: https://www.microsoftazuresponsorships.com/Balance"
echo ""
