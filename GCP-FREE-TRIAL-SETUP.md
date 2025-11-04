# GCP Free Trial Setup Guide

## What You Get

Google Cloud Platform offers **$300 in free credits** valid for **90 days** for new users.

### Key Points:
- ✅ **$300 credit** - More than enough for this demo
- ✅ **90 days** - Plenty of time
- ✅ **No automatic charges** - Won't be charged after credits expire
- ✅ **Credit card required** - But only for verification, not charged
- ✅ This demo uses approximately **$1-2** of your $300 credit

## Step-by-Step Setup

### 1. Sign Up for GCP Free Trial

Visit: https://cloud.google.com/free

**Requirements:**
- Valid email address (Gmail recommended)
- Credit card (for verification only)
- Phone number for verification

**What happens:**
- You'll create a Google account (if you don't have one)
- Verify your identity with credit card
- Receive $300 credits automatically
- Credits are applied to all GCP services

**Important:**
- ✅ You will NOT be charged during free trial
- ✅ You will NOT be auto-charged after trial ends
- ✅ You must manually upgrade to paid account to continue after trial
- ❌ You cannot create multiple free trials with same credit card

### 2. Complete Account Setup

After signing up:

1. **Verify your account** via email
2. **Enable billing** (uses free credits, doesn't charge card)
3. **Create a project** (or use the default project)

### 3. Install gcloud CLI

**macOS:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

**Linux:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install google-cloud-sdk
```

**Verify installation:**
```bash
gcloud --version
```

### 4. Authenticate

```bash
gcloud auth login
```

This opens a browser window:
1. Select your Google account
2. Allow gcloud to access your account
3. Close browser and return to terminal

### 5. Set Your Project

```bash
# List projects
gcloud projects list

# Set active project
gcloud config set project YOUR_PROJECT_ID
```

**Find your project ID:**
- Go to: https://console.cloud.google.com
- Look at the top bar → Project name dropdown
- Project ID is shown next to project name

### 6. Verify Free Trial Status

Check your free trial credits:

```bash
# Via browser
# Visit: https://console.cloud.google.com/billing
```

You should see:
- **Free trial status:** Active
- **Credits remaining:** $300 (or close to it)
- **Days remaining:** ~90

## Running the Demo

### Cost Breakdown for This Demo

**Cluster Configuration (Optimized):**
- Machine Type: e2-medium (2 vCPUs, 4 GB RAM)
- Number of Nodes: 3
- Region: us-central1

**Estimated Costs:**
| Duration | Credit Usage | Remaining |
|----------|-------------|-----------|
| 1 hour | ~$0.15-0.20 | $299.80 |
| 5 hours | ~$0.75-1.00 | $299.00 |
| 24 hours | ~$3.60-4.80 | $295.20 |
| 1 week | ~$25-35 | $265-275 |

**Recommendation:** Complete the demo in one session (4-6 hours) and delete the cluster. This uses only **$1-2** of your $300 credit!

### Deploy the Demo

```bash
# 1. Create cluster (optimized for free trial)
./scripts/setup-gke-cluster.sh

# 2. Deploy Signoz
./scripts/deploy-signoz.sh

# 3. Deploy microservices
./scripts/deploy-all.sh

# 4. Access and explore
kubectl port-forward -n signoz svc/signoz-frontend 9090:3301
# Open: http://localhost:9090
```

### Monitor Your Credit Usage

**Real-time monitoring:**
```bash
# Check running resources
gcloud compute instances list
gcloud container clusters list

# Estimate costs
# Visit: https://console.cloud.google.com/billing/reports
```

**Set up budget alerts (optional but recommended):**
1. Go to: https://console.cloud.google.com/billing/budgets
2. Create budget alert at $10 (you'll be notified if you approach this)
3. Set email notification

### Cleanup (IMPORTANT!)

When done, **always delete the cluster** to stop credit usage:

```bash
./scripts/cleanup-gke.sh
```

Or manually:
```bash
gcloud container clusters delete microservices-demo --zone=us-central1-a --quiet
```

**Verify cleanup:**
```bash
gcloud container clusters list
# Should show: Listed 0 items.
```

## Troubleshooting

### "Billing must be enabled"

**Problem:** You see an error about billing when creating cluster.

**Solution:**
1. Go to: https://console.cloud.google.com/billing
2. Click "Link a billing account"
3. Select your free trial billing account
4. Confirm (this uses free credits, doesn't charge card)

### "Quota exceeded"

**Problem:** Not enough quota for e2-medium machines.

**Solution:**
Try a different zone:
```bash
# Edit scripts/setup-gke-cluster.sh
# Change ZONE="us-central1-a" to:
ZONE="us-west1-a"  # or us-east1-b
```

### "Credit card declined"

**Problem:** Your card is declined during free trial signup.

**Solution:**
- Ensure card has international transactions enabled
- Try a different card
- Contact your bank
- Use a debit card instead of credit card

### "Free trial not available"

**Problem:** You don't see free trial option.

**Possible reasons:**
- You already used free trial with this card
- Your country doesn't support free trial
- You have an existing GCP account

**Solution:**
- Check: https://cloud.google.com/free/docs/free-cloud-features#free-trial
- Use Always Free tier (very limited) or pay-as-you-go

## Free Trial Terms

### What's Included:
- ✅ $300 credit for 90 days
- ✅ Access to all GCP services
- ✅ No automatic charges after trial

### What's NOT Included:
- ❌ Cannot be combined with other promotions
- ❌ One free trial per person/card
- ❌ Some services have usage limits even with credits

### After Free Trial Ends:

**Option 1: Do nothing**
- Services stop
- Data preserved for 30 days
- No charges

**Option 2: Upgrade to paid**
- Manually upgrade
- Continue using GCP
- Pay only for what you use

## Cost Optimization Tips

### 1. Delete Resources When Done
```bash
# Always delete cluster immediately after demo
./scripts/cleanup-gke.sh
```

### 2. Use Smaller Cluster
Already optimized in our script:
- e2-medium instead of e2-standard-4
- 3 nodes (minimum for redundancy)

### 3. Shut Down During Breaks
```bash
# Stop cluster (keeps data)
gcloud container clusters resize microservices-demo \
  --num-nodes=0 \
  --zone=us-central1-a

# Resume later
gcloud container clusters resize microservices-demo \
  --num-nodes=3 \
  --zone=us-central1-a
```

### 4. Monitor Usage
Check regularly:
- https://console.cloud.google.com/billing/reports
- Set budget alerts at $10, $25, $50

### 5. Complete Demo in One Session
- Don't leave cluster running overnight
- Complete in 4-6 hours
- Delete immediately after

## Frequently Asked Questions

**Q: Will I be charged after $300 runs out?**
A: No. Services stop automatically. You must manually upgrade to continue.

**Q: Can I get another free trial?**
A: No. One free trial per person/credit card.

**Q: What happens to my data after trial?**
A: Preserved for 30 days, then deleted. Export before trial ends if needed.

**Q: Do I need to cancel anything?**
A: No. Free trial ends automatically. Just delete your resources to conserve credits.

**Q: Can I use my university/work credit card?**
A: Yes, as long as it's a valid Visa/Mastercard/Amex.

**Q: Is free trial available in my country?**
A: Most countries. Check: https://cloud.google.com/free/docs/free-cloud-features#free-trial

## Summary

✅ **Sign up:** https://cloud.google.com/free
✅ **Get $300 credits** for 90 days
✅ **Enable billing** (uses free credits)
✅ **Run the demo** (~$1-2 of credits)
✅ **Delete cluster** when done
✅ **Keep $298+** for other learning!

**No risk, no charges, just learning!** 🎉

## Ready to Start?

1. Sign up for free trial: https://cloud.google.com/free
2. Complete account setup
3. Install gcloud CLI
4. Run: `./scripts/setup-gke-cluster.sh`
5. Enjoy your demo! 🚀
