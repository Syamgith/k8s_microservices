# Signoz Dashboard Configuration

This directory contains dashboard configurations and queries for monitoring the microservices demo application.

## Available Dashboards

### 1. Application Overview Dashboard
Shows high-level metrics across all microservices:
- Request rate (requests per second)
- Error rate (4xx, 5xx errors)
- Latency percentiles (P50, P95, P99)
- Service health status

### 2. Checkout Service Dashboard
Focuses on the checkout service with custom instrumentation:
- Order metrics (total orders, order rate)
- Order value distribution
- Payment method breakdown
- Processing duration
- Custom trace analysis

### 3. Kubernetes Metrics Dashboard
Infrastructure and resource monitoring:
- Pod CPU and memory usage
- Node resource utilization
- Pod restart counts
- Network traffic

## Dashboard Setup Instructions

### Method 1: Using Signoz UI (Recommended)

1. Access Signoz UI at http://localhost:3301
2. Navigate to "Dashboards" in the left menu
3. Click "Create Dashboard" or "Import Dashboard"
4. Use the queries and panels defined in this directory

### Method 2: API Import (Advanced)

```bash
# Export dashboard (if you already have one configured)
curl -X GET "http://localhost:3301/api/v1/dashboards/{dashboard-id}" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  > my-dashboard.json

# Import dashboard
curl -X POST "http://localhost:3301/api/v1/dashboards" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d @checkout-dashboard.json
```

## Key Queries

### Traces Queries

#### 1. Find All Checkout Service Traces
```
service.name = "checkoutservice"
```

#### 2. Find Failed Checkout Attempts
```
service.name = "checkoutservice" AND status.code = "ERROR"
```

#### 3. Find Slow Checkouts (>2 seconds)
```
service.name = "checkoutservice" AND duration > 2000000000
```

#### 4. Find High-Value Orders (Custom Instrumentation)
```
service.name = "checkoutservice" AND order.value > 100
```

### Metrics Queries

#### 1. Request Rate by Service
```promql
rate(http_server_requests_total[5m])
```

#### 2. Error Rate
```promql
rate(http_server_requests_total{status_code=~"5.."}[5m])
```

#### 3. P95 Latency
```promql
histogram_quantile(0.95, rate(http_server_request_duration_seconds_bucket[5m]))
```

#### 4. Custom: Order Rate (from custom instrumentation)
```promql
rate(checkout_orders_total[5m])
```

#### 5. Custom: Average Order Value
```promql
avg(checkout_order_value)
```

#### 6. Custom: P99 Processing Duration
```promql
histogram_quantile(0.99, rate(checkout_processing_duration_bucket[5m]))
```

#### 7. Custom: Payment Methods Distribution
```promql
sum by (method) (checkout_payment_method_total)
```

### Logs Queries

#### 1. All Checkout Service Logs
```
service="checkoutservice"
```

#### 2. Error Logs
```
service="checkoutservice" AND level="error"
```

#### 3. Order Completion Logs
```
service="checkoutservice" AND message contains "Order placed successfully"
```

## Dashboard Panels Configuration

### Panel 1: Request Rate
- **Type:** Time Series Graph
- **Query:** `rate(http_server_requests_total{service="checkoutservice"}[5m])`
- **Y-axis:** Requests/sec
- **Legend:** Service name

### Panel 2: Error Rate
- **Type:** Time Series Graph
- **Query:** `rate(http_server_requests_total{service="checkoutservice", status_code=~"5.."}[5m])`
- **Y-axis:** Errors/sec
- **Alert threshold:** > 0.1

### Panel 3: Latency Heatmap
- **Type:** Heatmap
- **Query:** `http_server_request_duration_seconds_bucket{service="checkoutservice"}`
- **Buckets:** Auto

### Panel 4: Order Value Distribution (Custom)
- **Type:** Histogram
- **Query:** `checkout_order_value`
- **Buckets:** [0, 50, 100, 200, 500]

### Panel 5: Payment Methods (Custom)
- **Type:** Pie Chart
- **Query:** `sum by (method) (checkout_payment_method_total)`
- **Colors:** Auto

### Panel 6: Active Checkouts (Custom)
- **Type:** Gauge
- **Query:** `checkout_active`
- **Thresholds:** Warning: 50, Critical: 100

### Panel 7: Service Map
- **Type:** Service Map/Topology
- **Filter:** `service.namespace="microservices-demo"`
- **Shows:** Service dependencies and call paths

## Alert Configurations

### Alert 1: High Error Rate
- **Condition:** Error rate > 5% for 5 minutes
- **Query:** `rate(http_server_requests_total{status_code=~"5.."}[5m]) / rate(http_server_requests_total[5m]) > 0.05`
- **Severity:** Critical

### Alert 2: High Latency
- **Condition:** P95 latency > 2 seconds
- **Query:** `histogram_quantile(0.95, rate(http_server_request_duration_seconds_bucket[5m])) > 2`
- **Severity:** Warning

### Alert 3: Service Down
- **Condition:** No requests in last 5 minutes
- **Query:** `rate(http_server_requests_total[5m]) == 0`
- **Severity:** Critical

## Viewing Real-time Data

After deploying everything and starting Locust traffic:

1. **Traces View:**
   - Go to Traces → Filter by `service.name = "checkoutservice"`
   - Click on any trace to see the full distributed trace
   - Look for custom spans: "ValidateOrder", "ProcessPayment", "SendConfirmationEmail"

2. **Metrics View:**
   - Go to Metrics → Search for `checkout_` to find custom metrics
   - Create graphs for order_rate, order_value, processing_duration

3. **Logs View:**
   - Go to Logs → Filter by service="checkoutservice"
   - Search for specific log patterns or error messages

4. **Service Map:**
   - Go to Service Map to see the full topology
   - Identify bottlenecks and slow services

## Tips for Effective Monitoring

1. **Correlation:** Use the "Go to related" feature in Signoz to jump from metrics to traces to logs for the same time period

2. **Time Range:** Start with 15-minute views, then zoom in on interesting patterns

3. **Sampling:** If data volume is high, adjust trace sampling in the OTEL collector config

4. **Custom Attributes:** Use trace attributes to filter and aggregate:
   - `order.value`
   - `payment.method`
   - `cart.items`

5. **Baseline:** Run load tests at different intensities to establish normal baselines for alerts
