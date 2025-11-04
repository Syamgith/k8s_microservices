# GCP Deployment Guide

This guide walks you through deploying the microservices observability stack on Google Cloud Platform (GCP).

## Why GCP?

- ✅ Works perfectly with x86_64 images (no ARM64 issues)
- ✅ Google's microservices-demo is optimized for GKE
- ✅ Auto-scaling and managed Kubernetes
- ✅ Easy LoadBalancer setup

## Prerequisites

### 1. Install gcloud CLI

**macOS:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL  # Restart shell
```

**Linux:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

**Or download installer:**
https://cloud.google.com/sdk/docs/install

### 2. Authenticate

```bash
gcloud auth login
```

### 3. Create/Select GCP Project

```bash
# List projects
gcloud projects list

# Create new project (optional)
gcloud projects create microservices-demo-12345

# Set active project
gcloud config set project YOUR_PROJECT_ID
```

### 4. Enable Billing

- Go to: https://console.cloud.google.com/billing
- Link billing account to your project
- **Required** for creating GKE clusters

## Quick Start

### Step 1: Create GKE Cluster

```bash
./scripts/setup-gke-cluster.sh
```

This will:
- ✅ Enable required APIs
- ✅ Create 3-node GKE cluster (e2-standard-4)
- ✅ Configure kubectl
- ✅ Create namespaces

**Time:** ~5-10 minutes

### Step 2: Deploy Signoz

```bash
./scripts/deploy-signoz.sh
```

**Time:** ~5-10 minutes

### Step 3: Deploy Microservices

```bash
./scripts/deploy-all.sh
```

**Time:** ~5-10 minutes

### Step 4: Access Services

Check service external IPs:

```bash
kubectl get svc -n microservices-demo frontend-external
kubectl get svc -n signoz signoz-frontend
kubectl get svc -n locust locust-master
```

Or use port-forwarding (works immediately):

```bash
# Signoz
kubectl port-forward -n signoz svc/signoz-frontend 9090:3301

# Application
kubectl port-forward -n microservices-demo svc/frontend-external 9080:80

# Locust
kubectl port-forward -n locust svc/locust-master 9089:8089
```

## Cost Estimate

**Cluster Configuration:**
- Machine Type: e2-standard-4 (4 vCPUs, 16 GB RAM)
- Nodes: 3
- Region: us-central1

**Estimated Costs:**
- **Per Hour:** ~$0.30-0.40
- **Per Day (24h):** ~$7-10
- **Per Week:** ~$50-70

**Cost Breakdown:**
- Compute: $0.27/hour (3 nodes × $0.09/hour)
- Disk: $0.02/hour (150 GB × ~$0.04/GB/month)
- Network: Minimal for demo purposes

💡 **Tip:** Delete cluster when not in use to save costs!

## Accessing Services

### Option 1: LoadBalancer (GCP Native)

GKE automatically provisions external IPs for LoadBalancer services.

```bash
# Get external IPs
kubectl get svc --all-namespaces | grep LoadBalancer

# Access via external IP
# Example: http://34.71.123.456:80
```

### Option 2: Port Forwarding (Recommended for Dev)

```bash
# Signoz (in terminal 1)
kubectl port-forward -n signoz svc/signoz-frontend 9090:3301

# Application (in terminal 2)
kubectl port-forward -n microservices-demo svc/frontend-external 9080:80

# Locust (in terminal 3)
kubectl port-forward -n locust svc/locust-master 9089:8089
```

Then access:
- Signoz: http://localhost:9090
- Application: http://localhost:9080
- Locust: http://localhost:9089

### Option 3: Ingress (Optional, Production-like)

For a more production-like setup, you can configure Ingress with a domain name.

## Monitoring and Verification

### Check Cluster Status

```bash
# Nodes
kubectl get nodes

# All pods
kubectl get pods --all-namespaces

# Services
kubectl get svc --all-namespaces
```

### Check Signoz

```bash
kubectl get pods -n signoz
# All should be Running or Completed
```

### Check Microservices

```bash
kubectl get pods -n microservices-demo
# All should be Running (except init containers)
```

### View Logs

```bash
# Signoz
kubectl logs -n signoz deployment/signoz-otel-collector

# Microservices
kubectl logs -n microservices-demo deployment/frontend

# Locust
kubectl logs -n locust deployment/locust-master
```

## Troubleshooting

### Pods Pending

```bash
# Check events
kubectl get events -n microservices-demo --sort-by='.lastTimestamp'

# Check node resources
kubectl describe nodes

# Solution: Scale up nodes
gcloud container clusters resize microservices-demo \
  --num-nodes=4 \
  --zone=us-central1-a
```

### LoadBalancer Pending

```bash
# Check service
kubectl describe svc frontend-external -n microservices-demo

# GCP may take 2-3 minutes to provision LoadBalancer
```

### Connection Issues

```bash
# Check firewall rules
gcloud compute firewall-rules list

# GKE automatically creates firewall rules for LoadBalancers
```

## Cleanup

### Delete Everything

```bash
./scripts/cleanup-gke.sh
```

Or manually:

```bash
# Delete cluster (also deletes LoadBalancers, Disks, etc.)
gcloud container clusters delete microservices-demo --zone=us-central1-a

# Verify cleanup
gcloud compute disks list
gcloud compute addresses list
```

### Partial Cleanup (Keep Cluster)

```bash
# Delete only applications
kubectl delete namespace microservices-demo
kubectl delete namespace locust

# Keep Signoz for other demos
```

## Advanced Configuration

### Scale Cluster

```bash
# Manual scaling
gcloud container clusters resize microservices-demo \
  --num-nodes=5 \
  --zone=us-central1-a

# Auto-scaling is enabled by default (2-5 nodes)
```

### Change Machine Type

```bash
# Create new node pool with different machine type
gcloud container node-pools create high-cpu-pool \
  --cluster=microservices-demo \
  --machine-type=c2-standard-4 \
  --num-nodes=2 \
  --zone=us-central1-a

# Migrate workloads and delete old pool
```

### Enable Monitoring

```bash
# GKE comes with Cloud Monitoring
# View in GCP Console: Kubernetes Engine → Observability

# Or use Signoz for unified observability!
```

## Cost Optimization

### 1. Use Preemptible Nodes (60-80% cheaper)

```bash
gcloud container node-pools create preemptible-pool \
  --cluster=microservices-demo \
  --machine-type=e2-standard-4 \
  --num-nodes=3 \
  --preemptible \
  --zone=us-central1-a
```

**Note:** Preemptible nodes can be terminated anytime. Good for dev/testing.

### 2. Auto-scale Down

```bash
# Enabled by default with --enable-autoscaling
# Scales down to min-nodes when idle
```

### 3. Schedule Cluster Start/Stop

Use Cloud Scheduler to:
- Delete cluster at night
- Recreate in morning
- Or use GKE Autopilot (pay per pod)

### 4. Use Spot VMs

Similar to preemptible but more reliable:

```bash
gcloud container node-pools create spot-pool \
  --cluster=microservices-demo \
  --machine-type=e2-standard-4 \
  --num-nodes=3 \
  --spot \
  --zone=us-central1-a
```

## Security Best Practices

1. **Enable Workload Identity** (for service accounts)
2. **Use Private Cluster** (nodes without public IPs)
3. **Enable Binary Authorization** (verify image signatures)
4. **Network Policies** (restrict pod-to-pod communication)

For this demo, default security is sufficient.

## Next Steps

After deployment:

1. ✅ Access Signoz UI and explore dashboards
2. ✅ Open Locust and generate traffic
3. ✅ View metrics, traces, and logs in Signoz
4. ✅ Test custom instrumentation
5. ✅ **Delete cluster** when done to avoid charges

## Support

- GKE Documentation: https://cloud.google.com/kubernetes-engine/docs
- Signoz Documentation: https://signoz.io/docs/
- Cost Calculator: https://cloud.google.com/products/calculator

## Summary

GCP deployment advantages:
- ✅ No ARM64 architecture issues
- ✅ Automatic LoadBalancers
- ✅ Integrated monitoring
- ✅ Auto-scaling
- ✅ Managed Kubernetes

Perfect for demos, testing, and production workloads!
