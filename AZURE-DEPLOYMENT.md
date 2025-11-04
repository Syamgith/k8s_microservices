## Azure Free Trial Deployment Guide

Complete guide for deploying the microservices observability stack on Azure using your **$200 free credit**.

## What You Have

Based on your Azure welcome email:
- ✅ **$200 USD credit**
- ✅ **12 months of free services**
- ✅ **No automatic charges** after credit expires

## Why Azure is Great for This Demo

| Feature | Azure | AWS | GCP |
|---------|-------|-----|-----|
| **Free Credit** | $200 | None for K8s | $300 |
| **Credit Duration** | 30 days | N/A | 90 days |
| **K8s Control Plane** | **FREE** ✅ | $0.10/hour | Included |
| **Demo Cost** | **~$0.40** | ~$5-6 | ~$1-2 |
| **12 Months Free Services** | Yes | Limited | No |

**Azure Advantage:** AKS (Azure Kubernetes Service) control plane is **completely FREE!**

## Prerequisites

### 1. Install Azure CLI

**macOS:**
```bash
brew install azure-cli
```

**Linux:**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Windows:**
Download from: https://aka.ms/installazurecliwindows

**Verify:**
```bash
az --version
```

### 2. Install kubectl (if not already installed)

```bash
az aks install-cli
```

### 3. Login to Azure

```bash
az login
```

This opens a browser for authentication.

## Quick Start

### Step 1: Create AKS Cluster

```bash
./scripts/setup-aks-cluster.sh
```

**What it does:**
- ✅ Creates resource group
- ✅ Creates AKS cluster (5-10 minutes)
- ✅ Configures kubectl
- ✅ Creates namespaces

**Time:** ~10 minutes

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

**Option 1: Port Forward (Immediate)**
```bash
# Terminal 1: Signoz
kubectl port-forward -n signoz svc/signoz-frontend 9090:3301

# Terminal 2: Application
kubectl port-forward -n microservices-demo svc/frontend-external 9080:80

# Terminal 3: Locust
kubectl port-forward -n locust svc/locust-master 9089:8089
```

Then open:
- Signoz: http://localhost:9090
- Application: http://localhost:9080
- Locust: http://localhost:9089

**Option 2: Load Balancer (Takes 2-3 minutes)**
```bash
# Get external IPs
kubectl get svc --all-namespaces | grep LoadBalancer

# Access via external IP
# Example: http://20.242.123.45
```

### Step 5: Cleanup (IMPORTANT!)

```bash
./scripts/cleanup-aks.sh
```

This deletes everything and stops charges to your credit!

## Cost Breakdown

### Detailed Costs

**AKS Control Plane:**
- Cost: **$0** (FREE!)
- This is Azure's big advantage

**VM Nodes (2x Standard_B2s):**
- Per node: $0.0416/hour
- Total: $0.08/hour
- Per day: ~$1.92
- Per week: ~$13.44

**Storage (Premium SSD):**
- ~$0.01/hour for 50GB
- Negligible

**Load Balancer:**
- Basic tier: FREE
- Data processing: minimal

**Total Estimate:**
| Duration | Cost from $200 Credit | Remaining |
|----------|----------------------|-----------|
| 1 hour | $0.08 | $199.92 |
| 5 hours (demo) | $0.40 | $199.60 |
| 1 day | $1.92 | $198.08 |
| 1 week | $13.44 | $186.56 |

**For This Demo:** Complete in 5-6 hours = **$0.40-0.48** of your $200!

## Monitoring Your Credits

### Check Credit Balance

Visit: https://www.microsoftazuresponsorships.com/Balance

### Cost Analysis

1. Go to Azure Portal: https://portal.azure.com
2. Navigate to: **Cost Management + Billing**
3. Click: **Cost analysis**
4. View: Current spend from your $200 credit

### Set Budget Alerts

```bash
# Via CLI
az consumption budget create \
  --budget-name demo-budget \
  --amount 10 \
  --time-grain Monthly \
  --start-date $(date +%Y-%m-01) \
  --end-date $(date -d "+1 month" +%Y-%m-01)
```

Or via portal:
1. Cost Management → Budgets
2. Add budget: $10
3. Set alert at 80% ($8)

## Troubleshooting

### "Subscription not found"

**Solution:**
```bash
# List subscriptions
az account list --output table

# Set active subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### "Quota exceeded"

**Problem:** Not enough quota for Standard_B2s VMs.

**Solution:**
```bash
# Try different region
# Edit scripts/setup-aks-cluster.sh
LOCATION="westus2"  # or "westeurope"
```

Or request quota increase:
- Portal → Subscriptions → Usage + quotas
- Search: "Standard BSv2 Family vCPUs"
- Request increase to 8

### "Credit card verification failed"

**Solution:**
- Ensure card has sufficient funds ($1 hold)
- Enable international transactions
- Try different card
- Wait 24 hours and retry

### Pods Pending

**Check node status:**
```bash
kubectl get nodes
kubectl describe nodes
```

**If nodes not ready:**
```bash
# Check AKS status
az aks show --resource-group microservices-demo-rg --name microservices-demo

# Scale nodes
az aks scale \
  --resource-group microservices-demo-rg \
  --name microservices-demo \
  --node-count 3
```

### LoadBalancer Pending

**Azure takes 2-3 minutes to provision public IPs.**

```bash
# Check service status
kubectl describe svc frontend-external -n microservices-demo

# Check Azure LB
az network lb list --resource-group MC_microservices-demo-rg_microservices-demo_eastus
```

## Advanced Configuration

### Scale Cluster

**Manual scaling:**
```bash
az aks scale \
  --resource-group microservices-demo-rg \
  --name microservices-demo \
  --node-count 3
```

**Enable autoscaling:**
```bash
az aks update \
  --resource-group microservices-demo-rg \
  --name microservices-demo \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 4
```

### Use Spot VMs (Cheaper)

Create node pool with Spot instances (80% cheaper):
```bash
az aks nodepool add \
  --resource-group microservices-demo-rg \
  --cluster-name microservices-demo \
  --name spotpool \
  --priority Spot \
  --eviction-policy Delete \
  --spot-max-price -1 \
  --node-count 2 \
  --node-vm-size Standard_B2s
```

### Enable Monitoring

**Azure Monitor (included):**
```bash
# Already enabled via --enable-addons monitoring

# View metrics in portal
az aks browse --resource-group microservices-demo-rg --name microservices-demo
```

## Security Best Practices

### Enable Azure AD Integration

```bash
az aks update \
  --resource-group microservices-demo-rg \
  --name microservices-demo \
  --enable-aad \
  --enable-azure-rbac
```

### Network Policies

Already enabled via `--network-policy azure`

### Private Cluster (Optional)

For production, create private cluster:
```bash
az aks create \
  ... \
  --enable-private-cluster
```

## Cost Optimization Tips

### 1. Delete When Not Using
```bash
./scripts/cleanup-aks.sh
```

### 2. Stop Cluster (Alternative)
```bash
# Stop cluster (preview feature)
az aks stop --resource-group microservices-demo-rg --name microservices-demo

# Start when needed
az aks start --resource-group microservices-demo-rg --name microservices-demo
```

### 3. Use Azure Reserved Instances
For longer-term usage (not needed for this demo)

### 4. Deallocate VMs at Night
```bash
# Scale to 0 at night
az aks scale --node-count 0 ...

# Scale back up in morning
az aks scale --node-count 2 ...
```

### 5. Use Tags for Cost Tracking
```bash
az aks update \
  --resource-group microservices-demo-rg \
  --name microservices-demo \
  --tags environment=demo purpose=learning
```

## Verification Checklist

After deployment, verify:

### ✅ Cluster Health
```bash
kubectl get nodes
# All should be Ready

kubectl get pods --all-namespaces
# Check for Running/Completed status
```

### ✅ Signoz
```bash
kubectl get pods -n signoz
# All pods Running or Completed
```

### ✅ Microservices
```bash
kubectl get pods -n microservices-demo
# Most pods Running (frontend, cart, checkout, etc.)
```

### ✅ Services
```bash
kubectl get svc --all-namespaces | grep LoadBalancer
# External IPs assigned (or pending)
```

### ✅ Access
- Signoz UI: http://localhost:9090 ✓
- Application: http://localhost:9080 ✓
- Locust: http://localhost:9089 ✓

## Next Steps After Demo

### Export Data (Optional)
```bash
# Export Signoz dashboards
kubectl exec -n signoz signoz-0 -- signoz-cli export

# Download to local
kubectl cp signoz/signoz-0:/export ./signoz-backup
```

### Document Learnings
Take screenshots of:
- Signoz dashboards
- Service topology
- Trace details
- Custom metrics

### Cleanup
```bash
./scripts/cleanup-aks.sh
```

### Check Final Cost
Visit: https://www.microsoftazuresponsorships.com/Balance

You should have ~$199.50+ remaining!

## Additional Resources

- **AKS Documentation:** https://docs.microsoft.com/en-us/azure/aks/
- **Azure CLI Reference:** https://docs.microsoft.com/en-us/cli/azure/
- **Cost Calculator:** https://azure.microsoft.com/en-us/pricing/calculator/
- **Signoz Documentation:** https://signoz.io/docs/

## Support

**Azure Support:**
- Portal → Help + support
- Free tier includes basic support

**Community:**
- Stack Overflow: [azure-aks] tag
- GitHub Issues (this project)

## Summary

✅ **Azure is perfect for this demo:**
- $200 credit (plenty!)
- AKS control plane FREE
- Demo costs ~$0.40
- Easy to use
- Good documentation

🎯 **Complete the demo in 5-6 hours and you'll have ~$199.60 remaining for other learning!**

## Ready to Start?

```bash
./scripts/setup-aks-cluster.sh
```

Let's go! 🚀
