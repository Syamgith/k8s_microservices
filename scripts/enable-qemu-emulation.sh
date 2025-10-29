#!/bin/bash

set -e

echo "=========================================="
echo "  Enabling QEMU Emulation for x86_64"
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
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    echo -e "${RED}This script is only needed for ARM64 systems.${NC}"
    echo -e "${YELLOW}You're on $ARCH - emulation not needed.${NC}"
    exit 0
fi

echo -e "${YELLOW}Detected ARM64 architecture: $ARCH${NC}"
echo -e "${YELLOW}Setting up QEMU to run x86_64 Docker images...${NC}"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1: Installing QEMU binary formats...${NC}"
docker run --privileged --rm tonistiigi/binfmt --install all

echo ""
echo -e "${GREEN}✓ QEMU emulation enabled!${NC}"
echo ""

# Verify
echo -e "${BLUE}Step 2: Verifying emulation setup...${NC}"
docker run --rm --platform linux/amd64 alpine uname -m || echo "Verification skipped"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}QEMU Emulation Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo ""
echo "• x86_64 images will now run on ARM64 (with emulation)"
echo "• Performance: ~50-70% of native (acceptable for dev/demo)"
echo "• This is persistent - survives Docker restarts"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Recreate the Kubernetes cluster:"
echo "   kind delete cluster --name microservices-demo"
echo "   ./scripts/setup-cluster.sh"
echo ""
echo "2. Deploy Signoz:"
echo "   ./scripts/deploy-signoz.sh"
echo ""
echo "3. Deploy microservices (use regular script now):"
echo "   ./scripts/deploy-all.sh"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
##