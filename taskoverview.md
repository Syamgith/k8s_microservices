### **Task Details:**

1. Implement Google's well-known [microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo) project using Kubernetes. You may choose any cloud provider or a self-hosted solution. Generate simulated traffic, and visualize the associated logs and metrics using either Grafana or Signoz.
2. (Bonus) Add **custom application instrumentation** to one service (for example, expose a new metric or trace using Prometheus/OpenTelemetry) and ensure it appears in your dashboard.

### **Evaluation Criteria:**

- Visibility of a dashboard displaying application and Kubernetes metrics.
- Visibility of application logs.
- Inclusion of application traces
- Demonstration of custom instrumentation integrated into the dashboard

### **Helpful Hints:**

We advocate for the use of open-source infrastructure and technologies rather than building custom solutions.

- Consider using popular libraries like Locust / k6s for traffic simulation.
- For Grafana, Prometheus and Loki are convenient storage options for metrics and logs, respectively.
- Signoz is an open-source APM tool that supports sending metrics, logs, and traces.
- Share a link to your Grafana dashboard or Signoz setup in the README.md file.
