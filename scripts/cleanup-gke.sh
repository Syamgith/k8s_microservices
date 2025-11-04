#!/bin/bash

set -e

echo "=========================================="
echo "  Cleaning up GKE Resources"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CLUSTER_NAME="microservices-demo"
ZONE="us-central1-a"

echo -e "${YELLOW}This will delete:${NC}"
echo "  - GKE Cluster: $CLUSTER_NAME"
echo "  - All associated resources (LoadBalancers, Disks, etc.)"
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
echo -e "${YELLOW}Deleting GKE cluster...${NC}"
gcloud container clusters delete "$CLUSTER_NAME" \
  --zone="$ZONE" \
  --quiet

echo ""
echo -e "${GREEN}✓ Cleanup complete!${NC}"
echo ""
echo "Remaining resources to check:"
echo "  - gcloud compute disks list"
echo "  - gcloud compute addresses list"
echo ""
