# Azure Quota Error - How to Fix

## The Problem

You're seeing this error when trying to create Azure App Service resources:

```
Operation cannot be completed without additional quota.
Current Limit (Free VMs): 0
Amount required for this deployment (Free VMs): 1
```

This means your Azure subscription doesn't have permission/quota to create virtual machines (VMs), which are required for App Service Plans.

## Why This Happens

Even though App Service Plans are "managed" services, they still run on VMs in the background. Your subscription has **0 quota** for creating VMs in the selected region.

Common reasons:
1. **New subscription** - Some Azure subscriptions start with zero quota
2. **Regional restriction** - Quota might be limited for certain regions
3. **Subscription type** - Some subscription types (like trials) have strict limits
4. **Manual quota limit** - Someone may have set limits intentionally

## Solutions

### Option 1: Request Quota Increase (Recommended)

**Via Azure Portal (Easiest):**

1. Go to: https://portal.azure.com
2. Navigate to: **Subscriptions** → Your subscription → **Usage + quotas**
3. Search for: **"Standard BS Series vCPUs"** or **"App Service"**
4. Click on the quota you want to increase
5. Click **"Request increase"**
6. Fill out the form:
   - **Region**: Select the region where you want to deploy (e.g., East US)
   - **Type**: Standard BS Series (for Basic/Standard App Service Plans)
   - **New limit**: Request at least **10-20 vCPUs** (to allow for multiple instances/scaling)
   - **Reason**: "Need to create App Service Plans for web application hosting"
7. Submit the request

**Via Azure CLI:**

```bash
# List current quotas
az vm list-usage --location eastus -o table

# For Visual Studio subscribers, you can sometimes increase via support
# But portal is usually easier
```

**Processing Time:**
- Usually processed within 24-48 hours
- Sometimes approved instantly for valid subscriptions
- You'll receive an email when approved

### Option 2: Try a Different Region

Some regions may have different quota availability:

```bash
# Try creating resources in a different region
./scripts/create-azure-resources.sh
# When prompted for location, try:
# - westus2
# - centralus
# - uksouth (if you're in UK)
# - westeurope
```

Different regions may have different quota limits available.

### Option 3: Check Subscription Status

Your subscription shows as "Enabled" which is good. However, verify:

```bash
# Check subscription details
az account show

# Check if you have spending limits or restrictions
az account list-locations --query "[].{name:name, displayName:displayName}" -o table
```

### Option 4: Use Azure Free Tier (If Available)

If you're on a free/trial subscription, you might have access to:
- **Free App Service** (F1 tier) - but this has limitations
- Check if free tier quotas are available

However, **Free tier (F1) is NOT recommended for production** as apps sleep after 20 minutes.

## What to Request

When requesting quota increase, request:

**For App Service Plans:**
- **Standard BS Series vCPUs**: Request **10-20 vCPUs**
  - This covers Basic and Standard tier App Service Plans
  - Allows for multiple instances and scaling

**Region-specific:**
- Request quota for the region where you plan to deploy
- Common regions: `eastus`, `westus2`, `uksouth`, `westeurope`

## Quick Check: Your Current Status

From your account:
- ✅ Subscription: **Enabled**
- ✅ Subscription Type: **Visual Studio Premium with MSDN**
- ⚠️ **Quota Issue**: 0 Free VMs in selected region

**Visual Studio subscriptions** typically come with Azure credits and should have quota available. This might be:
1. A new subscription that hasn't had quota approved yet
2. Regional restriction
3. Need to activate/enable compute resources

## Immediate Actions

1. **Request quota increase via Azure Portal** (fastest path)
   - Portal → Subscriptions → Usage + quotas → Request increase

2. **Try different region** while waiting
   - Some regions might have quota available immediately

3. **Contact Azure Support** (if urgent)
   - Visual Studio subscribers sometimes get priority support
   - They can often approve quota increases quickly

## After Quota is Approved

Once your quota is approved:

1. **Verify quota**:
   ```bash
   az vm list-usage --location <your-region> -o table
   ```

2. **Re-run resource creation**:
   ```bash
   ./scripts/create-azure-resources.sh
   ```

3. **Proceed with credential setup**:
   ```bash
   ./scripts/setup-azure-credentials.sh
   ```

## Alternative: Azure Container Apps (If Available)

If App Service quota is difficult to get, consider:
- **Azure Container Apps** (different quota limits)
- **Azure Static Web Apps** (if your app fits this model)
- But for Streamlit, App Service is usually the best fit

## Summary

**The Error Means:** Your subscription can't create VMs in that region (quota = 0)

**The Fix:** Request quota increase via Azure Portal

**Time:** Usually 24-48 hours (sometimes instant)

**Next Step:** Go to Azure Portal → Subscriptions → Usage + quotas → Request increase for "Standard BS Series vCPUs"

---

**Quick Link to Request Quota:**
https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade/newsupportrequest
