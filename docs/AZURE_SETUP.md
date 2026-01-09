# Azure Credentials Setup Guide

This guide will help you set up Azure credentials for your GitHub Actions workflow with **segregated environments** for security and isolation.

## Architecture Overview

The Azure setup uses **separate resource groups and service principals** for UAT and Production environments:

- **UAT Environment:**
  - Resource Group: `rg-hello-world-streamlit-uat`
  - Service Principal: `github-actions-hello-world-streamlit-uat`
  - Role: **Contributor** (read/write access)
  - Used for: Development, testing, and UAT deployments

- **Production Environment:**
  - Resource Group: `rg-hello-world-streamlit-prod`
  - Service Principal: `github-actions-hello-world-streamlit-prod`
  - Role: **Reader** (read-only access)
  - Used for: Production monitoring and read-only operations

This segregation ensures that:
- UAT deployments have full control over the UAT environment
- Production is protected with read-only access
- Environments are completely isolated at the resource group level

## Quick Start (Complete Setup)

If you're starting from scratch, follow these steps in order:

1. **Create Azure Resources** (if they don't exist):
   ```bash
   ./scripts/create-azure-resources.sh
   ```

2. **Create Azure Service Principals**:
   ```bash
   ./scripts/setup-azure-credentials.sh
   ```

3. **Add secrets to GitHub**:
   - Go to: https://github.com/andytholmes/hello_world_streamlit/settings/secrets/actions
   - Add the secrets as shown in the script output

4. **Test the workflow**:
   - Push to `develop` branch to trigger deployment

---

## Prerequisites: Create Azure Resources First

**Important:** If your App Services don't exist yet, you must create them before setting up credentials.

### Option 1: Automated Resource Creation (Recommended)

Run the automated script to create all necessary Azure resources:

```bash
./scripts/create-azure-resources.sh
```

This script will:
1. Create **separate Resource Groups** for UAT and Production
2. Create **separate App Service Plans** for each environment
3. Create UAT and Production App Services in their respective resource groups
4. Configure them with the correct settings (Python 3.10, startup command, etc.)

### Option 2: Manual Resource Creation

If you prefer to create resources manually, see the [DEPLOYMENT.md](../.github/DEPLOYMENT.md) guide or use Azure Portal/CLI.

---

## Quick Setup (Recommended)

Run the automated setup script:

```bash
./scripts/setup-azure-credentials.sh
```

This script will:
1. Verify you're logged into Azure
2. Create **two separate Service Principals**:
   - UAT: Contributor role (read/write) on UAT resource group
   - Production: Reader role (read-only) on Production resource group
3. Output both sets of credentials in the format needed for GitHub Actions
4. Guide you through adding them to GitHub

## Manual Setup

If you prefer to set up manually:

### Step 1: Login to Azure

```bash
az login
```

### Step 2: Get Your Subscription Info

```bash
# Get subscription ID
az account show --query id -o tsv

# List resource groups
az group list --query "[].name" -o table
```

### Step 3: Create Resource Groups (if they don't exist)

```bash
# Create UAT resource group
az group create \
  --name rg-hello-world-streamlit-uat \
  --location eastus

# Create Production resource group
az group create \
  --name rg-hello-world-streamlit-prod \
  --location eastus
```

### Step 4: Create UAT Service Principal (Contributor - Read/Write)

Replace `<subscription-id>` with your subscription ID:

```bash
az ad sp create-for-rbac \
  --name "github-actions-hello-world-streamlit-uat" \
  --role contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/rg-hello-world-streamlit-uat \
  --sdk-auth
```

This will output JSON credentials. **Save this output!** This is your UAT credentials.

### Step 5: Create Production Service Principal (Reader - Read-Only)

```bash
az ad sp create-for-rbac \
  --name "github-actions-hello-world-streamlit-prod" \
  --role reader \
  --scopes /subscriptions/<subscription-id>/resourceGroups/rg-hello-world-streamlit-prod \
  --sdk-auth
```

This will output JSON credentials. **Save this output!** This is your Production credentials.

Both JSON outputs will look like:

```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

### Step 6: Add Credentials to GitHub Secrets

1. Go to your repository settings:
   ```
   https://github.com/andytholmes/hello_world_streamlit/settings/secrets/actions
   ```

2. Click **"New repository secret"** and add the following secrets:

   **Secret 1: AZURE_CREDENTIALS_UAT**
   - Name: `AZURE_CREDENTIALS_UAT`
   - Value: Paste the **entire JSON output** from Step 4 (UAT credentials)

   **Secret 2: AZURE_CREDENTIALS_PRODUCTION**
   - Name: `AZURE_CREDENTIALS_PRODUCTION`
   - Value: Paste the **entire JSON output** from Step 5 (Production credentials)

   **Secret 3: AZURE_RESOURCE_GROUP_UAT**
   - Name: `AZURE_RESOURCE_GROUP_UAT`
   - Value: `rg-hello-world-streamlit-uat`

   **Secret 4: AZURE_RESOURCE_GROUP_PRODUCTION**
   - Name: `AZURE_RESOURCE_GROUP_PRODUCTION`
   - Value: `rg-hello-world-streamlit-prod`

   **Secret 5: AZURE_APP_SERVICE_UAT**
   - Name: `AZURE_APP_SERVICE_UAT`
   - Value: Your UAT App Service name (e.g., `hello-world-streamlit-uat`)

   **Secret 6: AZURE_APP_SERVICE_PRODUCTION**
   - Name: `AZURE_APP_SERVICE_PRODUCTION`
   - Value: Your Production App Service name (e.g., `hello-world-streamlit-prod`)

### Step 7: Verify Azure Resources Exist

**⚠️ If you haven't created the App Services yet, do that first using the script above or manually.**

Verify your App Services and Resource Groups exist:

```bash
# Check UAT resource group
az group show --name rg-hello-world-streamlit-uat

# Check Production resource group
az group show --name rg-hello-world-streamlit-prod

# List app services in UAT resource group
az webapp list --resource-group rg-hello-world-streamlit-uat --query "[].{name:name, state:state}" -o table

# List app services in Production resource group
az webapp list --resource-group rg-hello-world-streamlit-prod --query "[].{name:name, state:state}" -o table
```

If they don't exist:
- Run: `./scripts/create-azure-resources.sh`
- Or see the [DEPLOYMENT.md](../.github/DEPLOYMENT.md) guide for manual creation

### Step 6: Test the Workflow

After adding the secrets:

1. Make a small commit to the `develop` branch
2. Push to trigger the workflow
3. Check the GitHub Actions page to see if the deployment succeeds

## Troubleshooting

### Error: "AADSTS700016: Application not found in the directory"

The service principal wasn't created properly. Try:
- Wait a few minutes for Azure AD to propagate
- Verify the JSON credentials are correct
- Try creating a new service principal with a different name

### Error: "Authorization failed"

The service principal doesn't have the right permissions. Verify and fix:

```bash
# For UAT - Grant Contributor role
az role assignment create \
  --assignee <uat-clientId-from-credentials> \
  --role "Contributor" \
  --scope /subscriptions/<subscription-id>/resourceGroups/rg-hello-world-streamlit-uat

# For Production - Grant Reader role
az role assignment create \
  --assignee <prod-clientId-from-credentials> \
  --role "Reader" \
  --scope /subscriptions/<subscription-id>/resourceGroups/rg-hello-world-streamlit-prod
```

### Error: "Resource group not found"

Ensure:
- Both resource groups exist in Azure (UAT and Production)
- The `AZURE_RESOURCE_GROUP_UAT` and `AZURE_RESOURCE_GROUP_PRODUCTION` secrets match the actual names exactly
- The service principals have permissions on their respective resource groups

### Verify Service Principal Permissions

```bash
# List role assignments for UAT resource group
az role assignment list \
  --resource-group rg-hello-world-streamlit-uat \
  --query "[].{principalName:principalName, roleDefinitionName:roleDefinitionName}" \
  -o table

# List role assignments for Production resource group
az role assignment list \
  --resource-group rg-hello-world-streamlit-prod \
  --query "[].{principalName:principalName, roleDefinitionName:roleDefinitionName}" \
  -o table
```

## Current Azure Information

From your current Azure login:

- **Subscription ID**: `b334b062-a5b8-4daf-a05e-260d3f0df661`
- **Tenant ID**: `3418410e-af28-44b7-a020-aabf9886a9c1`
- **Subscription Name**: Visual Studio Premium with MSDN

Use these values when creating the service principal.

## Security Notes

- ⚠️ **Never commit** credential files (`azure-credentials-*.json`) to git
- ⚠️ The `clientSecret` values are only shown once - save them immediately
- ✅ The credentials are stored securely in GitHub Secrets
- ✅ Rotate credentials periodically (create new service principals and update the secrets)
- ✅ **Environment Segregation**: UAT and Production are completely isolated with separate resource groups
- ✅ **Principle of Least Privilege**: Production service principal has read-only access
- ✅ **Separate Service Principals**: Each environment has its own service principal for better security and auditability

## Architecture Benefits

The segregated architecture provides:

1. **Security Isolation**: Production resources cannot be accidentally modified from UAT workflows
2. **Access Control**: Different permission levels (read/write for UAT, read-only for Production)
3. **Audit Trail**: Separate service principals make it easier to track which environment was accessed
4. **Resource Management**: Separate resource groups allow independent lifecycle management
5. **Compliance**: Better alignment with security best practices and compliance requirements
