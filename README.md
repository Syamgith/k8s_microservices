# Microservices Observability with Signoz

A complete implementation of Google's microservices-demo with full observability using Signoz for metrics, logs, and distributed tracing. Includes custom instrumentation and automated traffic generation.

## Overview

This project demonstrates production-ready observability for a microservices application by:
- Deploying Google's microservices-demo (Online Boutique) on local Kubernetes
- Implementing full-stack observability with Signoz (metrics, logs, traces)
- Adding custom OpenTelemetry instrumentation to the Checkout Service
- Generating realistic traffic patterns using Locust
- Creating comprehensive dashboards for monitoring

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
│                                                              │
│  ┌──────────────────┐      ┌─────────────────┐             │
│  │  Microservices   │      │     Signoz      │             │
│  │  - Frontend      │─────▶│  - Collector    │             │
│  │  - Checkout*     │      │  - ClickHouse   │             │
│  │  - Cart          │      │  - Query Service│             │
│  │  - Payment       │      │  - Frontend UI  │             │
│  │  - ...           │      └─────────────────┘             │
│  └──────────────────┘               │                       │
│         ▲                            │                       │
│         │                            ▼                       │
│  ┌──────────────┐          ┌─────────────────┐             │
│  │    Locust    │          │   Dashboards    │             │
│  │  - Master    │          │  - Metrics      │             │
│  │  - Workers   │          │  - Traces       │             │
│  └──────────────┘          │  - Logs         │             │
│                            └─────────────────┘             │
└─────────────────────────────────────────────────────────────┘

* Checkout Service includes custom instrumentation
```

## Features

### ✅ Completed Implementation

- [x] Local Kubernetes cluster setup (Kind)
- [x] Signoz deployment with optimized configuration
- [x] Microservices demo with OpenTelemetry integration
- [x] Custom instrumentation in Checkout Service:
  - Order rate and value metrics
  - Payment method distribution
  - Processing duration tracking
  - Custom trace spans for key operations
- [x] Automated traffic generation with Locust
- [x] Pre-configured dashboards and queries
- [x] Full metrics, logs, and traces collection

## Prerequisites

Before starting, ensure you have:
- Docker Desktop (or equivalent)
- kubectl
- Kind (Kubernetes in Docker)
- Helm 3
- Minimum 8GB RAM (16GB recommended)

See [PREREQUISITES.md](PREREQUISITES.md) for detailed installation instructions.

## Quick Start

### Option 1: Automated Deployment (Recommended)

Deploy everything in one command:

```bash
# 1. Setup Kubernetes cluster
./scripts/setup-cluster.sh

# 2. Deploy Signoz
./scripts/deploy-signoz.sh

# 3. Deploy microservices
# For x86_64/amd64:
./scripts/deploy-all.sh

# For ARM64/aarch64 (Apple Silicon, Raspberry Pi, etc.):
./scripts/deploy-arm64-microservices.sh
```

**⚠️ ARM64 Users:** Check your architecture with `uname -m`. If it shows `aarch64` or `arm64`, use the ARM64 script to avoid "exec format error".

That's it! The script will handle the rest automatically.

### Option 2: Step-by-Step Deployment

Follow these steps to deploy components individually:

#### 1. Setup Kubernetes Cluster

```bash
./scripts/setup-cluster.sh
```

This creates a Kind cluster named `microservices-demo` with required port mappings.

#### 2. Deploy Signoz

```bash
./scripts/deploy-signoz.sh
```

This deploys Signoz using Helm with optimized settings for local development.

**Access Signoz UI:** http://localhost:30000 or use port-forward:
```bash
kubectl port-forward -n signoz svc/signoz-frontend 9090:3301
```
Then visit: http://localhost:9090

#### 3. Deploy Microservices Demo

```bash
./scripts/deploy-microservices-demo.sh
```

This downloads Google's microservices-demo and deploys it with OpenTelemetry configuration to send data to Signoz.

**Access Application:**
```bash
kubectl port-forward -n microservices-demo svc/frontend-external 9080:80
```
Then visit: http://localhost:9080

#### 4. Deploy Traffic Generator

```bash
./scripts/deploy-locust.sh
```

This deploys Locust with pre-configured test scenarios.

**Access Locust UI:** http://localhost:30001 or use port-forward:
```bash
kubectl port-forward -n locust svc/locust-master 9089:8089
```
Then visit: http://localhost:9089

**Start Traffic:**
1. Open Locust UI in browser
2. Set users: 20
3. Set spawn rate: 2
4. Click "Start swarming"

#### 5. View Dashboards

Open Signoz UI (http://localhost:9090) and explore:
- **Metrics:** Real-time application and custom metrics
- **Traces:** Distributed traces across services
- **Logs:** Aggregated logs from all services
- **Service Map:** Visual service dependency graph

## Custom Instrumentation

The Checkout Service includes custom OpenTelemetry instrumentation demonstrating:

### Custom Metrics
- `checkout.orders.total` - Total orders processed
- `checkout.order.value` - Order value distribution
- `checkout.payment_method.total` - Payment method breakdown
- `checkout.processing.duration` - Order processing time
- `checkout.cart.items` - Items per order
- `checkout.active` - Active checkout sessions

### Custom Traces
- `ValidateOrder` - Order validation span
- `ProcessPayment` - Payment processing span
- `ChargeCard` - Card charging operation
- `SendConfirmationEmail` - Email notification span
- `CheckInventory` - Inventory verification span

### Implementation Details

See [custom-instrumentation/README.md](custom-instrumentation/README.md) for:
- Full source code examples
- Integration instructions
- Build and deployment guide

**Note:** The custom instrumentation is provided as example code. To see it in action, you would need to build a custom Docker image with the modifications.

## Dashboard Configuration

Pre-configured dashboards are available in the `dashboards/` directory:

### Main Dashboard Panels
1. **Order Rate** - Orders per second
2. **Order Value Distribution** - P50, P95, P99 order values
3. **Payment Methods** - Pie chart of payment types
4. **Processing Duration** - Latency percentiles
5. **Active Sessions** - Current checkout sessions
6. **Error Rate** - Failed orders
7. **Trace Latency** - Service operation timings
8. **Custom Spans** - Custom instrumentation metrics

See [dashboards/README.md](dashboards/README.md) for:
- Dashboard setup instructions
- Query examples
- Alert configurations
- Tips for effective monitoring

## Key Queries

### Metrics Queries
```promql
# Order rate
rate(checkout_orders_total[5m])

# P95 processing duration
histogram_quantile(0.95, rate(checkout_processing_duration_bucket[5m]))

# Average order value
avg(checkout_order_value)
```

### Trace Queries
```
# Find slow checkouts
service.name = "checkoutservice" AND duration > 2000000000

# Find high-value orders
service.name = "checkoutservice" AND order.value > 100

# Find failed orders
service.name = "checkoutservice" AND status.code = "ERROR"
```

### Log Queries
```
# Checkout errors
service="checkoutservice" AND level="error"

# Order completions
service="checkoutservice" AND message contains "Order placed"
```

## Project Structure

```
.
├── README.md                          # This file
├── PREREQUISITES.md                    # Installation requirements
├── taskoverview.md                     # Original task description
├── rules.md                            # Coding rules
├── scripts/                            # Deployment scripts
│   ├── setup-cluster.sh               # Kubernetes cluster setup
│   ├── deploy-signoz.sh               # Signoz deployment
│   ├── deploy-microservices-demo.sh   # App deployment
│   └── deploy-locust.sh               # Traffic generator deployment
├── kubernetes/                         # Kubernetes manifests
│   ├── signoz/                        # Signoz configuration
│   │   └── values.yaml
│   ├── microservices-demo/            # App configuration
│   │   ├── otel-configmap.yaml
│   │   └── kustomization.yaml
│   ├── otel-collector/                # OpenTelemetry collector
│   │   └── deployment.yaml
│   └── locust/                        # Load testing
│       ├── locustfile.py
│       └── deployment.yaml
├── custom-instrumentation/             # Custom OTEL code
│   ├── README.md
│   ├── instrumentation.go
│   ├── metrics.go
│   ├── tracing.go
│   └── main_patch.go
├── dashboards/                         # Dashboard configs
│   ├── README.md
│   └── checkout-service-dashboard.json
└── ai_changes_log.md                  # Change history
```

## Verification Checklist

After deployment, verify all evaluation criteria:

### ✅ Dashboard with Metrics
- [ ] Open Signoz UI at http://localhost:3301
- [ ] Navigate to "Metrics" section
- [ ] Search for `checkout_` metrics
- [ ] Verify metrics are being collected

### ✅ Application Logs
- [ ] Navigate to "Logs" section in Signoz
- [ ] Filter by `service="checkoutservice"`
- [ ] Verify logs are streaming

### ✅ Application Traces
- [ ] Navigate to "Traces" section
- [ ] Filter by `service.name = "checkoutservice"`
- [ ] Click on a trace to see distributed tracing
- [ ] Verify custom spans appear (ValidateOrder, ProcessPayment)

### ✅ Custom Instrumentation
- [ ] In Metrics, search for custom metrics:
  - `checkout.orders.total`
  - `checkout.order.value`
  - `checkout.payment_method.total`
- [ ] In Traces, look for custom span attributes:
  - `order.value`
  - `payment.method`
  - `cart.items`

## Troubleshooting

### Pods Not Starting
```bash
# Check pod status
kubectl get pods -A

# Check specific pod logs
kubectl logs -n signoz <pod-name>
kubectl logs -n microservices-demo <pod-name>
```

### Signoz Not Receiving Data
```bash
# Check OTEL collector status
kubectl get pods -n signoz | grep otel-collector
kubectl logs -n signoz <otel-collector-pod>

# Verify service endpoints
kubectl get svc -n signoz
```

### No Metrics/Traces Appearing
```bash
# Verify app environment variables
kubectl get deployment checkoutservice -n microservices-demo -o yaml | grep OTEL

# Check if traffic is being generated
kubectl logs -n locust deployment/locust-master
```

### Out of Resources
```bash
# Check cluster resources
kubectl top nodes
kubectl top pods -A

# Scale down if needed
kubectl scale deployment/locust-worker --replicas=1 -n locust
```

## Cleanup

To remove everything and free up resources:

```bash
# Delete the entire cluster
kind delete cluster --name microservices-demo

# Or delete individual components
kubectl delete namespace signoz
kubectl delete namespace microservices-demo
kubectl delete namespace locust
```

## Technologies Used

- **Kubernetes:** Container orchestration (Kind for local)
- **Signoz:** Open-source APM and observability platform
- **OpenTelemetry:** Instrumentation and telemetry collection
- **Locust:** Load testing and traffic generation
- **Helm:** Kubernetes package manager
- **Google Microservices Demo:** Sample microservices application
- **Go:** Checkout service language (for custom instrumentation)

## Links & Resources

- **Signoz Dashboard:** http://localhost:9090 (via port-forward)
- **Application Frontend:** http://localhost:9080 (via port-forward)
- **Locust UI:** http://localhost:9089 (via port-forward) or http://localhost:30001 (NodePort)
- [Signoz Documentation](https://signoz.io/docs/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Google Microservices Demo](https://github.com/GoogleCloudPlatform/microservices-demo)
- [Locust Documentation](https://docs.locust.io/)

## Future Enhancements

Potential improvements for production:
- Add Prometheus for long-term metrics storage
- Implement alerting with AlertManager
- Add log aggregation with Loki
- Set up CI/CD pipeline for custom instrumentation
- Add more custom business metrics
- Implement distributed tracing correlation with logs
- Add performance testing scenarios
- Configure auto-scaling based on metrics

## License

This project is for educational and demonstration purposes. The Google microservices-demo is licensed under Apache 2.0.

## Author

Generated as part of a microservices observability implementation task.

---

For questions or issues, please refer to the troubleshooting section or check individual component README files.
