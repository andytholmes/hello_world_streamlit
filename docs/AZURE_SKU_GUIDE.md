# Azure App Service Plan SKU Guide

This guide explains the different Azure App Service Plan SKU (Stock Keeping Unit) values and helps you choose the right one for your Streamlit application.

## SKU Tiers Overview

Azure App Service Plans come in several tiers, each with different capabilities, resources, and pricing:

| Tier | Name | Use Case | Cost |
|------|------|----------|------|
| **F1** | Free | Development/Testing | Free (with limitations) |
| **B1** | Basic | Low-traffic apps, development | ~$13-55/month |
| **S1** | Standard | Production apps, auto-scale | ~$73-300/month |
| **P1v2** | Premium V2 | High-performance apps | ~$146-600/month |
| **I1** | Isolated | High security/performance | ~$500+/month |

## Detailed SKU Breakdown

### Free Tier (F1)

**Best for:** Local testing, learning, non-critical demos

**Specifications:**
- CPU: Shared (60 CPU minutes/day)
- RAM: 1 GB
- Storage: 1 GB
- Custom domains: ❌ No
- SSL certificates: ❌ No
- Auto-scale: ❌ No
- Deployment slots: ❌ No
- SLA: ❌ No (99.95% uptime not guaranteed)

**Limitations:**
- Apps go to sleep after 20 minutes of inactivity
- Very limited resources
- Not suitable for production
- Custom domains not supported

**⚠️ Not Recommended for:** Production, UAT, or any app that needs to stay running

---

### Basic Tier (B1, B2, B3)

**Best for:** Small production apps, low-to-medium traffic, cost-effective hosting

**Specifications:**
- **B1**: 1 CPU core, 1.75 GB RAM, 10 GB storage - ~$13-55/month
- **B2**: 2 CPU cores, 3.5 GB RAM, 50 GB storage - ~$26-110/month
- **B3**: 4 CPU cores, 7 GB RAM, 250 GB storage - ~$52-220/month

**Features:**
- ✅ Dedicated CPU and RAM
- ✅ Custom domains
- ✅ SSL certificates (manual)
- ✅ Always on (no sleep)
- ✅ Manual scaling (can scale to B2, B3)
- ✅ Deployment slots: ❌ No
- ✅ Auto-scale: ❌ No
- ✅ SLA: 99.95%

**✅ Recommended for:** Your Streamlit app (start with B1)

**When to upgrade:**
- B1 → B2: If you experience slow performance or memory issues
- B2 → B3: High traffic or computationally intensive operations

---

### Standard Tier (S1, S2, S3)

**Best for:** Production apps with traffic spikes, need auto-scaling

**Specifications:**
- **S1**: 1 CPU core, 1.75 GB RAM, 50 GB storage - ~$73-300/month
- **S2**: 2 CPU cores, 3.5 GB RAM, 50 GB storage - ~$146-600/month
- **S3**: 4 CPU cores, 7 GB RAM, 50 GB storage - ~$292-1200/month

**Features:**
- ✅ All Basic features, plus:
- ✅ Auto-scale (scale out based on metrics)
- ✅ Up to 10 deployment slots
- ✅ Automated backups
- ✅ Traffic Manager integration
- ✅ Staging slots for zero-downtime deployments
- ✅ SSL certificates (free managed)
- ✅ SLA: 99.95%

**When to upgrade from Basic:**
- Need auto-scaling for variable traffic
- Want deployment slots for staging
- Need automated backups
- Expecting traffic spikes

---

### Premium V2 Tier (P1v2, P2v2, P3v2)

**Best for:** High-performance apps, enterprise workloads

**Specifications:**
- **P1v2**: 1 CPU core, 3.5 GB RAM, 250 GB storage - ~$146-600/month
- **P2v2**: 2 CPU cores, 7 GB RAM, 250 GB storage - ~$292-1200/month
- **P3v2**: 4 CPU cores, 14 GB RAM, 250 GB storage - ~$584-2400/month

**Features:**
- ✅ All Standard features, plus:
- ✅ More RAM per CPU
- ✅ Better performance
- ✅ Up to 20 deployment slots
- ✅ Better network isolation
- ✅ More storage

**When to upgrade:**
- Enterprise applications
- High-performance requirements
- Need more deployment slots
- Better network performance needed

---

### Isolated Tier (I1, I2, I3)

**Best for:** High-security, compliance requirements, dedicated infrastructure

**Specifications:**
- **I1**: 1 CPU core, 3.5 GB RAM, 250 GB storage - ~$500+/month
- **I2**: 2 CPU cores, 7 GB RAM, 250 GB storage - ~$1000+/month
- **I3**: 4 CPU cores, 14 GB RAM, 250 GB storage - ~$2000+/month

**Features:**
- ✅ Dedicated App Service Environment (ASE)
- ✅ Complete network isolation
- ✅ VNet integration
- ✅ Highest security and compliance
- ✅ All Premium features

**When to consider:**
- Compliance requirements (HIPAA, PCI-DSS, etc.)
- Need complete network isolation
- Enterprise security requirements

---

## Recommendations for Your Streamlit App

### For Development/UAT Environment

**Recommended: B1 (Basic)**

**Why:**
- ✅ Low cost (~$13-55/month)
- ✅ Always-on (no sleep)
- ✅ Sufficient for testing and UAT
- ✅ Can handle low-to-medium traffic
- ✅ Easy to upgrade if needed

**Alternative:** If budget is tight and downtime is acceptable, F1 (Free) for initial testing only.

---

### For Production Environment

**Recommended: Start with B1, upgrade as needed**

**Initial Choice: B1**
- ✅ Cost-effective for starting out
- ✅ Sufficient for low-to-medium traffic Streamlit apps
- ✅ Easy to scale up if traffic grows

**Upgrade to S1 if:**
- Traffic becomes variable/unpredictable (need auto-scaling)
- You want deployment slots for zero-downtime deployments
- You need automated backups
- You expect traffic spikes

**Upgrade to B2/B3 if:**
- App feels slow (CPU-bound)
- Memory issues occur (memory-bound)
- Traffic is steady but growing

---

## Cost Considerations

### Monthly Cost Estimates (approximate, varies by region)

| SKU | Monthly Cost (USD) | Best For |
|-----|-------------------|----------|
| F1 | $0 | Learning only |
| B1 | $13-55 | **Recommended start** |
| B2 | $26-110 | Growing apps |
| B3 | $52-220 | Medium traffic |
| S1 | $73-300 | Auto-scaling needed |
| S2 | $146-600 | Higher traffic |
| P1v2 | $146-600 | High performance |

**Note:** Prices vary significantly by:
- Azure region (e.g., East US vs West Europe)
- Whether you have Azure credits/discounts
- Reserved instances (1-3 year commitment = ~30-50% discount)

**💡 Cost Optimization Tips:**
1. Start with B1, monitor usage, upgrade only when needed
2. Use Azure cost calculator: https://azure.microsoft.com/pricing/calculator/
3. Consider reserved instances if you commit to 1-3 years
4. Use Azure credits if available (Visual Studio subscribers get monthly credits)

---

## Making Your Choice

### Quick Decision Tree

```
Do you need the app to always be running?
├─ No → F1 (Free) - for testing only
└─ Yes → Continue
    │
    Is this for production?
    ├─ No (UAT/Dev) → B1 (Basic)
    └─ Yes (Production) → Continue
        │
        Do you need auto-scaling?
        ├─ Yes → S1 (Standard)
        └─ No → B1 (Basic) - start here
            │
            Monitor for 1-2 weeks
            │
            Performance issues? → B2 or B3
            Traffic spikes? → S1 (Standard)
            Everything fine? → Stay on B1
```

---

## Upgrading/Downgrading

**Good news:** You can change SKUs anytime with minimal downtime (usually < 5 minutes)

```bash
# Upgrade/downgrade via Azure CLI
az appservice plan update \
  --name <plan-name> \
  --resource-group <resource-group> \
  --sku <new-sku>
```

**When to monitor after change:**
- First 24-48 hours after upgrade/downgrade
- Check performance, memory usage, CPU usage
- Monitor costs

---

## Your Project's Recommendation

Based on your architecture document, **B1 (Basic)** is recommended:

✅ **Initial Setup:**
- **UAT**: B1 (~$13-55/month)
- **Production**: B1 (~$13-55/month)
- **Total**: ~$26-110/month

✅ **Future Growth Path:**
- If traffic grows → Upgrade Production to S1 (auto-scale)
- If steady growth → Upgrade Production to B2 or B3
- Keep UAT on B1 unless needed

This aligns with your architecture document's goal of "cost optimization" while providing a production-ready environment.

---

## Additional Resources

- [Azure App Service Pricing](https://azure.microsoft.com/pricing/details/app-service/linux/)
- [App Service Plan Overview](https://docs.microsoft.com/azure/app-service/overview-hosting-plans)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Scale App Service](https://docs.microsoft.com/azure/app-service/manage-scale-up)
