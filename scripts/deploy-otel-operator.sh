#!/bin/bash

set -e

echo "==========================================="
echo "  Deploying OpenTelemetry Operator"
echo "==========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Step 1/3: Installing cert-manager (required by OTEL Operator)...${NC}"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

echo ""
echo -e "${YELLOW}Waiting for cert-manager to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s \
  deployment/cert-manager \
  deployment/cert-manager-webhook \
  deployment/cert-manager-cainjector \
  -n cert-manager

echo ""
echo -e "${GREEN}✓ cert-manager ready${NC}"

echo ""
echo -e "${BLUE}Step 2/3: Installing OpenTelemetry Operator...${NC}"
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml

echo ""
echo -e "${YELLOW}Waiting for OpenTelemetry Operator to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s \
  deployment/opentelemetry-operator-controller-manager \
  -n opentelemetry-operator-system

echo ""
echo -e "${GREEN}✓ OpenTelemetry Operator ready${NC}"

echo ""
echo -e "${BLUE}Step 3/3: Creating Instrumentation configuration...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-config
  namespace: microservices-demo
data:
  collector.yaml: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318

    processors:
      batch:
        timeout: 10s

      resource:
        attributes:
        - key: service.namespace
          value: microservices-demo
          action: insert

    exporters:
      otlp:
        endpoint: signoz-otel-collector.signoz.svc.cluster.local:4317
        tls:
          insecure: true

      logging:
        loglevel: debug

    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch, resource]
          exporters: [otlp, logging]
        metrics:
          receivers: [otlp]
          processors: [batch, resource]
          exporters: [otlp, logging]
        logs:
          receivers: [otlp]
          processors: [batch, resource]
          exporters: [otlp, logging]
---
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector
  namespace: microservices-demo
spec:
  mode: deployment
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318

    processors:
      batch:
        timeout: 10s

      resource:
        attributes:
        - key: service.namespace
          value: microservices-demo
          action: insert

    exporters:
      otlp:
        endpoint: signoz-otel-collector.signoz.svc.cluster.local:4317
        tls:
          insecure: true

      logging:
        loglevel: debug

    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch, resource]
          exporters: [otlp, logging]
        metrics:
          receivers: [otlp]
          processors: [batch, resource]
          exporters: [otlp, logging]
        logs:
          receivers: [otlp]
          processors: [batch, resource]
          exporters: [otlp, logging]
---
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: otel-instrumentation
  namespace: microservices-demo
spec:
  exporter:
    endpoint: http://otel-collector-collector.microservices-demo.svc.cluster.local:4317

  propagators:
    - tracecontext
    - baggage

  sampler:
    type: parentbased_traceidratio
    argument: "1.0"

  go:
    image: ghcr.io/open-telemetry/opentelemetry-go-instrumentation/autoinstrumentation-go:latest
    env:
      - name: OTEL_GO_AUTO_TARGET_EXE
        value: /app

  java:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:latest

  nodejs:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-nodejs:latest

  python:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-python:latest

  dotnet:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-dotnet:latest
EOF

echo ""
echo -e "${GREEN}✓ Instrumentation configuration created${NC}"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}OpenTelemetry Operator Deployed Successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Components deployed:"
echo "  ✅ cert-manager"
echo "  ✅ OpenTelemetry Operator"
echo "  ✅ OTEL Collector (in microservices-demo namespace)"
echo "  ✅ Instrumentation configuration"
echo ""
echo -e "${YELLOW}Next step: Apply instrumentation to deployments${NC}"
echo "Run: ./scripts/apply-auto-instrumentation.sh"
echo ""
