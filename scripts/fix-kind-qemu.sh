#!/bin/bash

set -e

echo "=========================================="
echo "  Fixing QEMU Support in Kind Cluster"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}Installing QEMU emulation inside the Kind node...${NC}"

# Copy QEMU binaries into the Kind node
echo "Step 1: Installing binfmt-support in Kind node..."
docker exec microservices-demo-control-plane sh -c "apt-get update && apt-get install -y binfmt-support qemu-user-static" 2>/dev/null || true

# Register binfmt handlers
echo "Step 2: Registering x86_64 binary format handlers..."
docker exec microservices-demo-control-plane sh -c "update-binfmts --enable qemu-x86_64" 2>/dev/null || true

# Verify
echo "Step 3: Verifying x86_64 support in cluster..."
kubectl run test-x86-verify --image=alpine --restart=Never --rm -i -- uname -m > /tmp/test-arch.txt 2>&1 || true

RESULT=$(cat /tmp/test-arch.txt | grep -E "x86_64|aarch64" || echo "unknown")
echo "Result: $RESULT"

if [[ "$RESULT" == "x86_64" ]]; then
    echo -e "${GREEN}✓ x86_64 emulation working in cluster!${NC}"
else
    echo -e "${RED}✗ x86_64 emulation not working yet${NC}"
    echo ""
    echo -e "${YELLOW}Alternative solution needed. The Kind node doesn't support runtime QEMU injection.${NC}"
    echo ""
    echo -e "${BLUE}Recommendation:${NC}"
    echo "Use a cloud provider or native x86_64 system for this demo."
    echo ""
    echo "Or try a simplified ARM64-native demo instead."
fi

rm -f /tmp/test-arch.txt
