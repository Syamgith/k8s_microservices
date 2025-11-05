#!/bin/bash

set -e

echo "==========================================="
echo "  Applying Auto-Instrumentation"
echo "==========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Annotating deployments for auto-instrumentation...${NC}"
echo ""

# Service-to-language mapping for Google microservices-demo
# Source: https://github.com/GoogleCloudPlatform/microservices-demo

echo "1/8 Instrumenting frontend (Go)..."
kubectl patch deployment frontend -n microservices-demo -p '{
  "spec": {
    "template": {
      "metadata": {
        "annotations": {
          "instrumentation.opentelemetry.io/inject-go": "true",
          "instrumentation.opentelemetry.io/otel-go-auto-target-exe": "/src/server"
        }
      }
    }
  }
}'

echo "2/8 Instrumenting checkoutservice (Go)..."
kubectl patch deployment checkoutservice -n microservices-demo -p '{
  "spec": {
    "template": {
      "metadata": {
        "annotations": {
          "instrumentation.opentelemetry.io/inject-go": "true",
          "instrumentation.opentelemetry.io/otel-go-auto-target-exe": "/src/checkoutservice"
        }
      }
    }
  }
}'

echo "3/8 Instrumenting cartservice (.NET)..."
kubectl patch deployment cartservice -n microservices-demo -p '{
  "spec": {
    "template": {
      "metadata": {
        "annotations": {
          "instrumentation.opentelemetry.io/inject-dotnet": "true"
        }
      }
    }
  }
}'

echo "4/8 Instrumenting productcatalogservice (Go)..."
kubectl patch deployment productcatalogservice -n microservices-demo -p '{
  "spec": {
    "template": {
      "metadata": {
        "annotations": {
          "instrumentation.opentelemetry.io/inject-go": "true",
          "instrumentation.opentelemetry.io/otel-go-auto-target-exe": "/src/server"
        }
      }
    }
  }
}'

echo "5/8 Instrumenting paymentservice (Node.js)..."
kubectl patch deployment paymentservice -n microservices-demo -p '{
  "spec": {
    "template": {
      "metadata": {
        "annotations": {
          "instrumentation.opentelemetry.io/inject-nodejs": "true"
        }
      }
    }
  }
}'

echo "6/8 Instrumenting shippingservice (Go)..."
kubectl patch deployment shippingservice -n microservices-demo -p '{
  "spec": {
    "template": {
      "metadata": {
        "annotations": {
          "instrumentation.opentelemetry.io/inject-go": "true",
          "instrumentation.opentelemetry.io/otel-go-auto-target-exe": "/src/shippingservice"
        }
      }
    }
  }
}'

echo "7/8 Instrumenting currencyservice (Node.js)..."
kubectl patch deployment currencyservice -n microservices-demo -p '{
  "spec": {
    "template": {
      "metadata": {
        "annotations": {
          "instrumentation.opentelemetry.io/inject-nodejs": "true"
        }
      }
    }
  }
}'

echo "8/8 Instrumenting adservice (Java)..."
kubectl patch deployment adservice -n microservices-demo -p '{
  "spec": {
    "template": {
      "metadata": {
        "annotations": {
          "instrumentation.opentelemetry.io/inject-java": "true"
        }
      }
    }
  }
}'

echo ""
echo -e "${GREEN}✓ All deployments annotated!${NC}"
echo ""
echo -e "${YELLOW}Waiting for pods to restart with instrumentation (90 seconds)...${NC}"
sleep 90

echo ""
echo "Pod status:"
kubectl get pods -n microservices-demo

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Auto-Instrumentation Applied!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "What was instrumented:"
echo "  ✅ frontend (Go)"
echo "  ✅ checkoutservice (Go)"
echo "  ✅ cartservice (.NET)"
echo "  ✅ productcatalogservice (Go)"
echo "  ✅ paymentservice (Node.js)"
echo "  ✅ shippingservice (Go)"
echo "  ✅ currencyservice (Node.js)"
echo "  ✅ adservice (Java)"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Generate traffic by browsing the application:"
echo "   http://4.187.134.143"
echo ""
echo "2. Wait 2-3 minutes for telemetry to flow"
echo ""
echo "3. Check Signoz for traces and metrics:"
echo "   http://4.187.154.189:8080"
echo ""
echo "4. Check intermediate OTEL collector logs:"
echo "   kubectl logs -n microservices-demo deployment/otel-collector-collector --tail=50"
echo ""
echo "5. If still no data, check a service for instrumentation:"
echo "   kubectl logs -n microservices-demo deployment/frontend --tail=100"
echo ""
