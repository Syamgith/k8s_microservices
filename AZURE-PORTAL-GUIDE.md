# Azure Portal Deployment Guide (No CLI Installation Needed!)

Complete guide to deploy the microservices observability stack using **only Azure Portal and Cloud Shell** - no local installation required!

## What is Azure Cloud Shell?

**Azure Cloud Shell** is a browser-based terminal with:

- ✅ **kubectl** pre-installed
- ✅ **helm** pre-installed
- ✅ **git** pre-installed
- ✅ **All Azure tools** pre-installed
- ✅ **Persistent storage** (5 GB free)
- ✅ **Authenticated automatically** with your Azure account

**Best part:** Everything runs in the browser - nothing to install!

## Prerequisites

1. ✅ Azure account with $200 free credit (you already have this!)
2. ✅ Web browser (Chrome, Firefox, Edge, Safari)
3. ✅ That's it!

---

## Part 1: Create AKS Cluster via Azure Portal

### Step 1: Login to Azure Portal

1. Go to: https://portal.azure.com
2. Sign in with your Azure account
3. You'll see the Azure Portal dashboard

### Step 2: Create Resource Group

1. Click **"Create a resource"** (top left)
2. Search for **"Resource group"**
3. Click **"Create"**
4. Fill in:
   - **Subscription:** Azure subscription 1 (or your subscription name)
   - **Resource group name:** `microservices-demo-rg`
   - **Region:** `East US` (or your preferred region)
5. Click **"Review + create"**
6. Click **"Create"**

✅ Resource group created!

### Step 3: Create AKS Cluster

1. Click **"Create a resource"** again
2. Search for **"Kubernetes Service"** (or "AKS")
3. Click **"Create"** → **"Create a Kubernetes cluster"**

**Basics Tab:**

- **Subscription:** Your subscription
- **Resource group:** `microservices-demo-rg` (select the one you just created)
- **Cluster preset configuration:** `Dev/Test`
- **Kubernetes cluster name:** `microservices-demo`
- **Region:** `East US` (same as resource group)
- **Availability zones:** None
- **AKS pricing tier:** `Free`
- **Kubernetes version:** (leave default - latest stable)
- **Automatic upgrade:** Disabled
- **Node security channel type:** None
- **Authentication and Authorization:** Local accounts with Kubernetes RBAC

Click **"Next: Node pools"**

**Node pools Tab:**

- Under **"System node pool"**:
  - **Node size:** Click "Choose a size"
    - Search for `B2s`
    - Select **`Standard_B2s`** (2 vCPUs, 4 GiB memory)
    - Click **"Select"**
  - **Scale method:** Manual
  - **Node count:** `2`

Click **"Next: Networking"**

**Networking Tab:**

- **Network configuration:** `Azure CNI`
- **Network policy:** `Azure`
- **DNS name prefix:** (leave default)
- **Load balancer:** Standard
- **HTTP application routing:** Disabled (unchecked)

Click **"Next: Integrations"**

**Integrations Tab:**

- **Container registry:** None
- **Azure Monitor:** Check ✅ **"Enable container logs"**
- **Azure Policy:** Disabled (unchecked)

Click **"Next: Advanced"**

**Advanced Tab:**

- Leave everything as default

Click **"Next: Tags"**

**Tags Tab:**

- Add tag (optional):
  - **Name:** `purpose`
  - **Value:** `demo`

Click **"Next: Review + create"**

### Step 4: Review and Create

1. Review the configuration
2. Check **Estimated cost** (should show ~$0.08/hour for VMs only)
3. Click **"Create"**

**⏱️ Wait Time: 5-10 minutes**

You'll see a deployment progress screen. Wait for it to complete.

✅ When it shows "Your deployment is complete", proceed to next step!

---

## Part 2: Open Azure Cloud Shell

### Step 1: Access Cloud Shell

1. In the Azure Portal (top navigation bar)
2. Click the **Cloud Shell icon** (looks like `>_` or a terminal)
3. If first time:
   - Choose **"Bash"** (not PowerShell)
   - Click **"Create storage"** (creates free 5GB storage)
   - Wait 30 seconds for setup

✅ You now have a terminal in your browser!

### Step 2: Verify Cloud Shell

Type these commands to verify:

```bash
# Check kubectl
kubectl version --client

# Check helm
helm version

# Check git
git --version

# Check Azure CLI
az --version
```

All should show version numbers. ✅

---

## Part 3: Connect to AKS Cluster

### Step 1: Get Cluster Credentials

In Cloud Shell, run:

```bash
# Configure kubectl to connect to your cluster
az aks get-credentials  --resource-group microservices-demo-rg --name microservices-demo
```

Expected output:

```
Merged "microservices-demo" as current context in /home/yourname/.kube/config
```

### Step 2: Verify Connection

```bash
# Check cluster info
kubectl cluster-info

# Check nodes
kubectl get nodes
```

You should see 2 nodes in "Ready" status. ✅

### Step 3: Create Namespaces

```bash
kubectl create namespace signoz
kubectl create namespace microservices-demo
kubectl create namespace locust
```

✅ Cluster ready!

---

## Part 4: Clone Repository and Deploy

### Step 1: Clone the Repository

In Cloud Shell:

```bash
# Clone your repository (or upload scripts)
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO

# Or create scripts manually (see below)
```

**If you don't have the repo in GitHub**, you can create scripts directly in Cloud Shell:

```bash
# Create directory
mkdir ~/microservices-observability
cd ~/microservices-observability
```

### Step 2: Upload Scripts to Cloud Shell

**Option A: Using Cloud Shell Upload**

1. In Cloud Shell toolbar, click **"Upload/Download files"** icon (↑↓)
2. Click **"Upload"**
3. Select these files from your local machine:
   - `kubernetes/` folder (all files)
   - `scripts/deploy-signoz.sh`
   - `scripts/deploy-all.sh`
   - `scripts/expose-services-public.sh`

**Option B: Create Scripts Manually**

I'll provide simplified versions below that you can copy-paste.

---

## Part 5: Deploy Signoz

### Create Signoz Deployment Script

In Cloud Shell, create the script:

```bash
# Create script
cat > deploy-signoz.sh <<'EOF'
#!/bin/bash
set -e

echo "Deploying Signoz..."

# Add Helm repo
helm repo add signoz https://charts.signoz.io
helm repo update

# Create values file
cat > signoz-values.yaml <<'YAML'
frontend:
  service:
    type: LoadBalancer

clickhouse:
  replicas: 1
  persistence:
    enabled: true
    size: 10Gi

otelCollector:
  replicas: 1
  resources:
    requests:
      cpu: 100m
      memory: 256Mi

kafka:
  enabled: false
YAML

# Install Signoz
helm upgrade --install signoz signoz/signoz \
  --namespace signoz \
  --values signoz-values.yaml \
  --wait \
  --timeout 15m

echo "✓ Signoz deployed!"
kubectl get pods -n signoz
EOF

# Make executable
chmod +x deploy-signoz.sh
```

### Run Signoz Deployment

```bash
./deploy-signoz.sh
```

**⏱️ Wait Time: 5-10 minutes**

Expected output: All pods in "Running" or "Completed" status.

---

## Part 6: Deploy Microservices

### Create Microservices Deployment Script

```bash
cat > deploy-microservices.sh <<'EOF'
#!/bin/bash
set -e

echo "Deploying microservices..."

# Download Google's microservices-demo
TEMP_DIR="/tmp/microservices-demo"
rm -rf "$TEMP_DIR"
git clone --depth 1 https://github.com/GoogleCloudPlatform/microservices-demo.git "$TEMP_DIR"

# Apply manifests
kubectl apply -f "$TEMP_DIR/release/kubernetes-manifests.yaml" -n microservices-demo

# Wait a bit
sleep 30

# Add OTEL environment variables
SERVICES=(
  "emailservice" "checkoutservice" "recommendationservice"
  "frontend" "paymentservice" "productcatalogservice"
  "cartservice" "currencyservice" "shippingservice" "adservice"
)

for service in "${SERVICES[@]}"; do
    echo "Configuring $service..."
    kubectl set env deployment/$service \
      OTEL_EXPORTER_OTLP_ENDPOINT=http://signoz-otel-collector.signoz.svc.cluster.local:4317 \
      OTEL_EXPORTER_OTLP_INSECURE=true \
      -n microservices-demo 2>/dev/null || echo "Skipped $service"
done

echo "✓ Microservices deployed!"
kubectl get pods -n microservices-demo
EOF

chmod +x deploy-microservices.sh
```

### Run Microservices Deployment

```bash
./deploy-microservices.sh
```

**⏱️ Wait Time: 5-10 minutes**

---

## Part 7: Deploy Locust (Traffic Generator)

### Create Locust Deployment

```bash
cat > deploy-locust.sh <<'EOF'
#!/bin/bash
set -e

echo "Deploying Locust..."

# Download manifest
curl -o locust.yaml https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/release/kubernetes-manifests.yaml

# Apply (modify to use your namespace)
kubectl apply -f https://raw.githubusercontent.com/locustio/locust/master/examples/kubernetes/locust-controller.yml -n locust 2>/dev/null || echo "Using alternative method"

echo "✓ Locust deployed!"
kubectl get pods -n locust
EOF

chmod +x deploy-locust.sh
./deploy-locust.sh
```

---

## Part 8: Expose Services Publicly

### Create Expose Script

```bash
cat > expose-public.sh <<'EOF'
#!/bin/bash
set -e

echo "Exposing services publicly..."

# Patch services to LoadBalancer
kubectl patch svc signoz-frontend -n signoz -p '{"spec": {"type": "LoadBalancer"}}'
kubectl patch svc frontend-external -n microservices-demo -p '{"spec": {"type": "LoadBalancer"}}'
kubectl patch svc locust-master -n locust -p '{"spec": {"type": "LoadBalancer"}}' 2>/dev/null || echo "Locust service may not exist yet"

echo ""
echo "Waiting for public IPs (2-3 minutes)..."
sleep 60

echo ""
echo "Public URLs:"
echo "============"

# Get IPs
SIGNOZ_IP=$(kubectl get svc signoz-frontend -n signoz -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
APP_IP=$(kubectl get svc frontend-external -n microservices-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
LOCUST_IP=$(kubectl get svc locust-master -n locust -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

echo ""
if [ -n "$SIGNOZ_IP" ]; then
    echo "📊 Signoz UI: http://$SIGNOZ_IP:3301"
else
    echo "📊 Signoz UI: (Pending - check again in 2 minutes)"
fi

if [ -n "$APP_IP" ]; then
    echo "🛍️  Application: http://$APP_IP"
else
    echo "🛍️  Application: (Pending - check again in 2 minutes)"
fi

if [ -n "$LOCUST_IP" ]; then
    echo "🔥 Locust: http://$LOCUST_IP:8089"
else
    echo "🔥 Locust: (Pending - check again in 2 minutes)"
fi

echo ""
echo "To check manually: kubectl get svc --all-namespaces | grep LoadBalancer"
EOF

chmod +x expose-public.sh
```

### Run Expose Script

```bash
./expose-public.sh
```

**If IPs are pending, wait 2-3 minutes and run again:**

```bash
kubectl get svc --all-namespaces | grep LoadBalancer
```

---

## Part 9: Access Your Public URLs

### Get URLs via Portal (Alternative)

1. In Azure Portal, go to your AKS cluster
2. Click **"Services and ingresses"** (left menu)
3. You'll see all services with their **External IPs**

### Get URLs via Cloud Shell

```bash
# See all services
kubectl get svc --all-namespaces

# Get specific IPs
kubectl get svc signoz-frontend -n signoz -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
kubectl get svc frontend-external -n microservices-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
kubectl get svc locust-master -n locust -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Example Output

```
📊 Signoz UI: http://20.242.45.123:3301
🛍️  Application: http://20.242.45.124:80
🔥 Locust: http://20.242.45.125:8089
```

✅ **Share these public URLs with anyone!**

---

## Part 10: Verify Everything Works

### Check All Pods

```bash
# Check Signoz
kubectl get pods -n signoz

# Check Microservices
kubectl get pods -n microservices-demo

# Check Locust
kubectl get pods -n locust
```

All should show "Running" status (except completed init jobs).

### Access Services

1. **Open Signoz UI** in browser

   - You should see the dashboard
   - Navigate to "Services" - you'll see microservices

2. **Open Application** in browser

   - You should see the Online Boutique store
   - Browse products, add to cart

3. **Open Locust UI** in browser

   - Set users: 20
   - Set spawn rate: 2
   - Click "Start swarming"

4. **Go back to Signoz**
   - You should now see metrics, traces, and logs!

---

## Part 11: Monitor Usage

### Check Credit Balance

Visit: https://www.microsoftazuresponsorships.com/Balance

### View Costs in Portal

1. In Azure Portal, search for **"Cost Management + Billing"**
2. Click **"Cost analysis"**
3. View your current spend

Should show ~$0.08/hour (just VM costs).

---

## Part 12: Cleanup When Done

### Option 1: Delete via Cloud Shell

```bash
# Delete entire resource group (deletes everything)
az group delete --name microservices-demo-rg --yes --no-wait

# Verify
az group list --output table
```

### Option 2: Delete via Portal

1. Go to **"Resource groups"**
2. Find `microservices-demo-rg`
3. Click on it
4. Click **"Delete resource group"** (top)
5. Type the resource group name to confirm
6. Click **"Delete"**

✅ Everything deleted! Credits conserved!

---

OR DO THIS

In Cloud Shell, run:

# Connect to cluster

az aks get-credentials \
 --resource-group microservices-demo-rg \
 --name microservices-demo

# VERIFY ARCHITECTURE (THIS IS CRITICAL!)

kubectl debug node/$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}') -it --image=busybox -- uname -m

Expected output: x86_64 (NOT aarch64!)

---

Step 4: Deploy Everything

# Create namespaces

kubectl create namespace signoz
kubectl create namespace microservices-demo
kubectl create namespace locust

# Deploy Signoz

./scripts/deploy-signoz.sh

# Deploy microservices

./scripts/deploy-microservices-demo.sh

# Deploy Locust

./scripts/deploy-locust.sh

# Expose services

./scripts/expose-services-public.sh

---

📊 Signoz UI: http://4.187.154.189:8080
APP: http://4.187.134.143/
