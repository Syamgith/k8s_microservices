#!/bin/bash

set -e

echo "==========================================="
echo "  Complete Cleanup"
echo "==========================================="
echo ""

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${YELLOW}This will delete:${NC}"
echo "  • AKS cluster (microservices-demo-cluster)"
echo "  • Resource group (microservices-demo-rg)"
echo "  • All public IPs and load balancers"
echo ""
echo -e "${RED}This action cannot be undone!${NC}"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Deleting resource group..."
az group delete --name microservices-demo-rg --yes --no-wait

echo ""
echo -e "${GREEN}✓ Cleanup initiated${NC}"
echo ""
echo "Azure is deleting resources in the background."
echo "This will take 5-10 minutes to complete."
echo ""
echo "To check status:"
echo "  az group show --name microservices-demo-rg"
echo ""
