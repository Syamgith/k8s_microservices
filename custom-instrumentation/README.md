# Custom Instrumentation for Checkout Service

This directory contains example code and instructions for adding custom OpenTelemetry instrumentation to the Checkout Service.

## Overview

The Checkout Service is written in Go and handles order placement, payment processing, and inventory management. We'll add custom instrumentation to track:

1. **Custom Metrics:**
   - Order value distribution
   - Payment method usage
   - Order processing duration
   - Cart item count per order

2. **Custom Traces:**
   - Detailed spans for order validation
   - Payment processing breakdown
   - Email notification timing

## Changes Required

### 1. Add OpenTelemetry Dependencies

In `go.mod`, add:
```go
require (
    go.opentelemetry.io/otel v1.21.0
    go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc v0.44.0
    go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc v1.21.0
    go.opentelemetry.io/otel/metric v1.21.0
    go.opentelemetry.io/otel/sdk v1.21.0
    go.opentelemetry.io/otel/sdk/metric v1.21.0
    go.opentelemetry.io/otel/trace v1.21.0
)
```

### 2. Initialize OpenTelemetry

See `instrumentation.go` for the initialization code that:
- Sets up OTLP exporters for traces and metrics
- Configures the meter and tracer providers
- Registers custom metrics

### 3. Add Custom Metrics

See `metrics.go` for examples of:
- Counter for total orders
- Histogram for order values
- Counter for payment methods
- Gauge for active checkouts

### 4. Add Custom Traces

See `tracing.go` for examples of:
- Creating custom spans
- Adding span attributes
- Recording span events
- Error handling in spans

## Deployment

### Option 1: Use Pre-built Image (Recommended for Demo)

A pre-built image with custom instrumentation is available:
```bash
kubectl set image deployment/checkoutservice \
  server=your-registry/checkoutservice-instrumented:latest \
  -n microservices-demo
```

### Option 2: Build Your Own Image

1. Clone the microservices-demo repository:
```bash
git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
cd microservices-demo/src/checkoutservice
```

2. Copy the instrumentation files:
```bash
cp /path/to/custom-instrumentation/*.go .
```

3. Modify `main.go` to initialize instrumentation (see `main_patch.go`)

4. Build and push:
```bash
docker build -t your-registry/checkoutservice-instrumented:latest .
docker push your-registry/checkoutservice-instrumented:latest
```

5. Update the deployment:
```bash
kubectl set image deployment/checkoutservice \
  server=your-registry/checkoutservice-instrumented:latest \
  -n microservices-demo
```

## Verification

After deployment, verify the custom metrics in Signoz:

1. Navigate to Signoz UI: http://localhost:3301
2. Go to "Metrics" section
3. Look for these custom metrics:
   - `checkout_orders_total` - Total number of orders
   - `checkout_order_value` - Distribution of order values
   - `checkout_payment_method` - Payment methods used
   - `checkout_processing_duration` - Order processing time

4. In the "Traces" section, look for:
   - Spans named "ValidateOrder", "ProcessPayment", "SendConfirmation"
   - Custom attributes like `order.value`, `payment.method`, `cart.items`

## Metrics Dashboard

Import the dashboard configuration from `../dashboards/checkout-dashboard.json` into Signoz to visualize:
- Order rate over time
- Average order value
- Payment method distribution
- P95/P99 processing latency
- Error rates

## Example Queries

### PromQL Queries for Metrics

```promql
# Order rate per minute
rate(checkout_orders_total[1m])

# Average order value
avg(checkout_order_value)

# P95 order processing duration
histogram_quantile(0.95, rate(checkout_processing_duration_bucket[5m]))

# Payment method distribution
sum by (method) (checkout_payment_method_total)
```

### Trace Queries

Filter traces by:
- Service name: `checkoutservice`
- Span attributes: `order.value > 100`
- Operation name: `ProcessPayment`
