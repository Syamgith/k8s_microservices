# Quick Start: Azure Portal (No CLI Installation!)

**Everything in your browser - No installation needed!**

## Step-by-Step Checklist

### ☑️ Part 1: Create Cluster (10 minutes)

1. **Go to:** https://portal.azure.com
2. **Create Resource Group:**
   - Click "Create a resource"
   - Search "Resource group"
   - Name: `microservices-demo-rg`
   - Region: `East US`
   - Click "Create"

3. **Create AKS Cluster:**
   - Click "Create a resource"
   - Search "Kubernetes Service"
   - Fill in:
     - **Name:** `microservices-demo`
     - **Resource group:** `microservices-demo-rg`
     - **Region:** `East US`
     - **Pricing tier:** `Free`
     - **Node size:** `Standard_B2s` (2 vCPU, 4GB)
     - **Node count:** `2`
   - Click through tabs and "Create"
   - ⏱️ Wait 5-10 minutes

### ☑️ Part 2: Open Cloud Shell

1. Click **Cloud Shell icon** (>_) at top of Azure Portal
2. Choose **"Bash"**
3. Click **"Create storage"** (if first time)
4. ✅ Terminal ready in browser!

### ☑️ Part 3: Connect to Cluster

```bash
az aks get-credentials \
  --resource-group microservices-demo-rg \
  --name microservices-demo

kubectl get nodes
```

### ☑️ Part 4: Create Namespaces

```bash
kubectl create namespace signoz
kubectl create namespace microservices-demo
kubectl create namespace locust
```

### ☑️ Part 5: Deploy Signoz (10 minutes)

```bash
# Add Helm repo
helm repo add signoz https://charts.signoz.io
helm repo update

# Create values
cat > signoz-values.yaml <<'EOF'
frontend:
  service:
    type: LoadBalancer
clickhouse:
  replicas: 1
otelCollector:
  replicas: 1
kafka:
  enabled: false
EOF

# Install
helm upgrade --install signoz signoz/signoz \
  --namespace signoz \
  --values signoz-values.yaml \
  --wait \
  --timeout 15m
```

### ☑️ Part 6: Deploy Microservices (10 minutes)

```bash
# Download manifests
git clone --depth 1 https://github.com/GoogleCloudPlatform/microservices-demo.git /tmp/ms-demo

# Deploy
kubectl apply -f /tmp/ms-demo/release/kubernetes-manifests.yaml -n microservices-demo

# Wait 2 minutes
sleep 120

# Check status
kubectl get pods -n microservices-demo
```

### ☑️ Part 7: Get Public URLs (2-3 minutes)

```bash
# Expose services
kubectl patch svc signoz-frontend -n signoz -p '{"spec": {"type": "LoadBalancer"}}'
kubectl patch svc frontend-external -n microservices-demo -p '{"spec": {"type": "LoadBalancer"}}'

# Wait for IPs
sleep 120

# Get URLs
echo "Signoz: http://$(kubectl get svc signoz-frontend -n signoz -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):3301"
echo "App: http://$(kubectl get svc frontend-external -n microservices-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
```

### ☑️ Part 8: Access & Demo!

Open the URLs in your browser:
- 📊 **Signoz UI** - View metrics, traces, logs
- 🛍️ **Application** - Browse the online store
- Share URLs with anyone!

### ☑️ Part 9: Cleanup

```bash
# Delete everything
az group delete --name microservices-demo-rg --yes --no-wait
```

Or via Portal:
- Go to "Resource groups"
- Select `microservices-demo-rg`
- Click "Delete resource group"

---

## Full Guide

See **[AZURE-PORTAL-GUIDE.md](AZURE-PORTAL-GUIDE.md)** for detailed instructions with screenshots and troubleshooting.

---

## Cost

- **Your credit:** $200
- **This demo:** ~$0.40 (5 hours)
- **Remaining:** $199.60

---

## Need Help?

Check **[AZURE-PORTAL-GUIDE.md](AZURE-PORTAL-GUIDE.md)** for:
- Detailed steps
- Screenshots
- Troubleshooting
- Tips & tricks

**Total Time: ~30-40 minutes** ⏱️

**No installation required!** 🎉
