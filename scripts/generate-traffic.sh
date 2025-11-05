#!/bin/bash

echo "==========================================="
echo "  Generating Traffic to All Services"
echo "==========================================="
echo ""

APP_URL="http://4.187.134.143"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Sending requests to trigger all microservices...${NC}"
echo ""

# Function to make a request
make_request() {
    local path=$1
    local description=$2
    echo -e "${YELLOW}→${NC} $description"
    curl -s -o /dev/null -w "  Status: %{http_code}, Time: %{time_total}s\n" "$APP_URL$path"
    sleep 1
}

echo "Running traffic generation loop (press Ctrl+C to stop)..."
echo ""

count=0
while true; do
    count=$((count + 1))
    echo -e "${GREEN}=== Request Cycle $count ===${NC}"

    # Homepage - triggers: frontend, productcatalogservice, currencyservice, adservice
    make_request "/" "Homepage (frontend + catalog + currency + ads)"

    # Product page - triggers: frontend, productcatalogservice, currencyservice
    make_request "/product/OLJCESPC7Z" "Product page (Vintage Typewriter)"

    # Another product
    make_request "/product/66VCHSJNUP" "Product page (Vintage Camera Lens)"

    # Add to cart - triggers: cartservice
    make_request "/cart" "View cart (cartservice + shipping)"

    # Checkout - triggers: checkoutservice, paymentservice, shippingservice, emailservice
    # Note: This is a GET to checkout page, not actual purchase
    make_request "/checkout" "Checkout page (all services)"

    echo ""
    echo "Waiting 10 seconds before next cycle..."
    echo ""
    sleep 10
done
