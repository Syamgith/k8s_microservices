# Microservices Observability with Signoz on Azure

A production-ready observability demo using Google's microservices-demo with Signoz for distributed tracing, deployed on Azure Kubernetes Service (AKS).

## What You Get

- 🎯 8-service microservices application (Online Boutique e-commerce)
- 📊 Distributed tracing with Signoz
- ☁️ Deployed on Azure AKS (uses ~$1-2 of your $200 free credit)
- 🌐 Publicly accessible URLs
- ✅ 3 services instrumented with OpenTelemetry (frontend, checkoutservice, productcatalogservice)

## Prerequisites

- Azure account with free trial ($200 credit) - [Sign up here](https://azure.microsoft.com/free/)
- Azure Cloud Shell access (no local installation needed!)

## Quick Start

### 1. Access Azure Cloud Shell

1. Go to [portal.azure.com](https://portal.azure.com)
2. Click the `>_` icon (Cloud Shell) in the top menu
3. Select Bash

### 2. Clone and Deploy

```bash
# Clone the repository
git clone https://github.com/Syamgith/k8s_microservices.git
cd k8s_microservices

# Make scripts executable
chmod +x scripts/*.sh

# 1. Create AKS cluster (5-7 minutes)
./scripts/setup-aks-cluster.sh

# 2. Deploy Signoz observability platform (3-5 minutes)
./scripts/deploy-signoz.sh

# 3. Deploy microservices (2-3 minutes)
./scripts/deploy-microservices-optimized.sh

# 4. Enable OpenTelemetry tracing
./scripts/fix-google-demo-otel.sh

# 5. Expose services publicly (2-3 minutes for IPs)
./scripts/expose-services-public.sh
```

### 3. Access Your Deployment

After the scripts complete, you'll get 2 public URLs:

1. **Application (Online Boutique):** `http://<APP-IP>`
2. **Signoz Dashboard:** `http://<SIGNOZ-IP>:8080`

The URLs are displayed at the end of the expose script and saved to `public-urls.txt`.

### 4. Generate Traffic

```bash
# Generate traffic to see traces in Signoz
./scripts/generate-traffic.sh

# Let it run for 2-3 minutes, then press Ctrl+C
```

### 5. View Traces in Signoz

1. Open Signoz dashboard at `http://<SIGNOZ-IP>:8080`
2. Click **"Services"** tab
3. You should see 3 services:
   - `frontend`
   - `checkoutservice`
   - `productcatalogservice`
4. Click **"Traces"** tab to see distributed traces
5. Click any trace to see the request flow across services

## Architecture

```
Azure AKS Cluster
├── Microservices (namespace: microservices-demo)
│   ├── frontend (Go) ✅ instrumented
│   ├── checkoutservice (Go) ✅ instrumented
│   ├── productcatalogservice (Go) ✅ instrumented
│   ├── cartservice (.NET)
│   ├── paymentservice (Node.js)
│   ├── shippingservice (Go)
│   ├── currencyservice (Node.js)
│   └── adservice (Java)
│
└── Signoz (namespace: signoz)
    ├── OTEL Collector (receives traces on port 4317)
    ├── ClickHouse (stores trace data)
    ├── Query Service (processes queries)
    └── Frontend UI (dashboard on port 8080)
```

## What Each Script Does

| Script | Purpose | Duration |
|--------|---------|----------|
| `setup-aks-cluster.sh` | Creates 2-node AKS cluster (Standard_B2s) | 5-7 min |
| `deploy-signoz.sh` | Installs Signoz via Helm | 3-5 min |
| `deploy-microservices-optimized.sh` | Deploys Google's microservices demo | 2-3 min |
| `fix-google-demo-otel.sh` | Configures OpenTelemetry with correct env vars | 1-2 min |
| `expose-services-public.sh` | Creates LoadBalancers for public access | 2-3 min |
| `generate-traffic.sh` | Sends HTTP requests to trigger services | Continuous |
| `cleanup-all.sh` | Deletes entire resource group | 5-10 min |

## Cost Breakdown

**Azure Free Trial:** $200 credit (valid 30 days)

**This demo costs:**
- AKS control plane: **FREE** (Azure's advantage!)
- 2x Standard_B2s VMs: ~$0.08/hour
- 2x Public IPs: ~$0.01/hour
- Total: **~$0.10/hour** or **$2.40/day**

**Running for 5 hours = $0.50 of your $200 credit!**

## Troubleshooting

### Pods not starting
```bash
kubectl get pods -n microservices-demo
kubectl logs -n microservices-demo <pod-name>
```

### No traces in Signoz
```bash
# 1. Verify OTEL configuration
kubectl get deployment frontend -n microservices-demo -o jsonpath='{.spec.template.spec.containers[0].env}' | jq '.[] | select(.name=="ENABLE_TRACING")'

# 2. Check Signoz collector logs
kubectl logs -n signoz deployment/signoz-otel-collector --tail=50

# 3. Generate more traffic
./scripts/generate-traffic.sh
```

### Can't access public IPs
```bash
# Check if IPs are assigned
kubectl get svc --all-namespaces | grep LoadBalancer

# Wait 2-3 more minutes if still <pending>
```

## Cleanup

**IMPORTANT:** Delete resources when done to avoid charges!

```bash
./scripts/cleanup-all.sh
```

Or manually via Azure Portal:
1. Go to Resource Groups
2. Delete `microservices-demo-rg`

## Project Structure

```
.
├── scripts/
│   ├── setup-aks-cluster.sh          # Create AKS cluster
│   ├── deploy-signoz.sh              # Deploy Signoz
│   ├── deploy-microservices-optimized.sh  # Deploy microservices
│   ├── fix-google-demo-otel.sh       # Configure OpenTelemetry
│   ├── expose-services-public.sh     # Create public IPs
│   ├── generate-traffic.sh           # Traffic generator
│   └── cleanup-all.sh                # Complete cleanup
│
├── kubernetes/
│   └── microservices-demo/
│       └── redis-cart.yaml           # Redis configuration
│
├── README.md                         # This file
└── public-urls.txt                   # Generated URLs (created by expose script)
```

## Resources

- [Signoz Documentation](https://signoz.io/docs/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Google Microservices Demo](https://github.com/GoogleCloudPlatform/microservices-demo)
- [Azure Free Trial](https://azure.microsoft.com/free/)

## Notes

- **Why only 3 services?** Google's demo has OpenTelemetry built-in for only some services (frontend, checkout, productcatalog). Others (cart, ad) don't have tracing implemented yet.
- **Architecture compatible:** Works on any machine (x86_64, ARM64) since it runs on Azure.
- **Cost-effective:** Uses minimal resources optimized for Azure free tier.

---

**Total setup time:** ~15-20 minutes | **Cost:** ~$0.50 (5 hours)
