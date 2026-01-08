# Azure Credentials Setup Guide

This guide will help you fix the Azure credentials issue in your GitHub Actions workflow.

## Quick Start (Complete Setup)

If you're starting from scratch, follow these steps in order:

1. **Create Azure Resources** (if they don't exist):
   ```bash
   ./scripts/create-azure-resources.sh
   ```

2. **Create Azure Service Principal**:
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
1. Create a Resource Group
2. Create an App Service Plan
3. Create UAT and Production App Services
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
2. Create a Service Principal with the correct permissions
3. Output the credentials in the format needed for GitHub Actions
4. Guide you through adding them to GitHub

## Manual Setup

If you prefer to set up manually:

### Step 1: Login to Azure

```bash
az login
```

### Step 2: Get Your Subscription and Resource Group Info

```bash
# Get subscription ID
az account show --query id -o tsv

# List resource groups (if you have one)
az group list --query "[].name" -o table
```

### Step 3: Create Service Principal

Replace `<subscription-id>` and `<resource-group-name>` with your values:

```bash
az ad sp create-for-rbac \
  --name "github-actions-hello-world-streamlit" \
  --role contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group-name> \
  --sdk-auth
```

**Important:** If your resource group doesn't exist yet, you can use the subscription scope instead:

```bash
az ad sp create-for-rbac \
  --name "github-actions-hello-world-streamlit" \
  --role contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth
```

This will output JSON credentials. **Save this output!** It looks like:

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

### Step 4: Add Credentials to GitHub Secrets

1. Go to your repository settings:
   ```
   https://github.com/andytholmes/hello_world_streamlit/settings/secrets/actions
   ```

2. Click **"New repository secret"**

3. Add the following secrets:

   **Secret 1: AZURE_CREDENTIALS**
   - Name: `AZURE_CREDENTIALS`
   - Value: Paste the **entire JSON output** from Step 3 (all of it, as one string)

   **Secret 2: AZURE_RESOURCE_GROUP**
   - Name: `AZURE_RESOURCE_GROUP`
   - Value: Your resource group name (e.g., `rg-hello-world-streamlit`)

   **Secret 3: AZURE_APP_SERVICE_UAT**
   - Name: `AZURE_APP_SERVICE_UAT`
   - Value: Your UAT App Service name (e.g., `hello-world-streamlit-uat`)

   **Secret 4: AZURE_APP_SERVICE_PRODUCTION**
   - Name: `AZURE_APP_SERVICE_PRODUCTION`
   - Value: Your Production App Service name (e.g., `hello-world-streamlit-prod`)

### Step 5: Verify Azure Resources Exist

**⚠️ If you haven't created the App Services yet, do that first using the script above or manually.**

Verify your App Services and Resource Group exist:

```bash
# Check if resource group exists
az group show --name <resource-group-name>

# List app services in the resource group
az webapp list --resource-group <resource-group-name> --query "[].{name:name, state:state}" -o table
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

The service principal doesn't have the right permissions:
```bash
# Grant Contributor role on resource group
az role assignment create \
  --assignee <clientId-from-credentials> \
  --role "Contributor" \
  --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group-name>
```

### Error: "Resource group not found"

Ensure:
- The resource group exists in Azure
- The `AZURE_RESOURCE_GROUP` secret matches the actual name exactly
- The service principal has permissions on that resource group

### Verify Service Principal Permissions

```bash
# List role assignments for a resource group
az role assignment list \
  --resource-group <resource-group-name> \
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

- ⚠️ **Never commit** the `azure-credentials.json` file to git
- ⚠️ The `clientSecret` is only shown once - save it immediately
- ✅ The credentials are stored securely in GitHub Secrets
- ✅ Rotate credentials periodically (create a new service principal and update the secret)
