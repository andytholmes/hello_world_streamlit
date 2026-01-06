# Deployment Guide

This document describes the deployment setup for the Hello World Streamlit application.

## GitHub Secrets Configuration

The following secrets must be configured in GitHub repository settings (Settings → Secrets and variables → Actions):

### Required Secrets

1. **AZURE_CREDENTIALS**
   - Description: Azure Service Principal credentials in JSON format
   - Format: JSON object with `clientId`, `clientSecret`, `subscriptionId`, and `tenantId`
   - Example:
     ```json
     {
       "clientId": "your-client-id",
       "clientSecret": "your-client-secret",
       "subscriptionId": "your-subscription-id",
       "tenantId": "your-tenant-id"
     }
     ```

2. **AZURE_APP_SERVICE_UAT**
   - Description: Name of the Azure App Service for UAT environment
   - Example: `hello-world-streamlit-uat`

3. **AZURE_APP_SERVICE_PRODUCTION**
   - Description: Name of the Azure App Service for Production environment
   - Example: `hello-world-streamlit-prod`

4. **AZURE_RESOURCE_GROUP**
   - Description: Name of the Azure Resource Group containing the App Services
   - Example: `rg-hello-world-streamlit`

5. **CODECOV_TOKEN** (Optional)
   - Description: Codecov token for coverage reporting
   - Note: This is optional and can be omitted if you don't use Codecov

## Azure Service Principal Setup

### Step 1: Create Service Principal

```bash
az ad sp create-for-rbac --name "github-actions-hello-world-streamlit" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} \
  --sdk-auth
```

### Step 2: Copy Output

The command will output JSON credentials. Copy this entire JSON object and paste it as the `AZURE_CREDENTIALS` secret in GitHub.

### Step 3: Verify Permissions

Ensure the Service Principal has:
- **Contributor** role on the Resource Group containing the App Services
- **App Service Contributor** role (if needed for deployment)

## Azure App Service Configuration

### Startup Command

The App Service must be configured with the following startup command:

```bash
streamlit run app.py --server.port=8000 --server.address=0.0.0.0
```

### Application Settings

The following application settings are configured automatically by the CI/CD pipeline:

**UAT Environment:**
- `ENVIRONMENT=uat`
- `APP_NAME=Hello World Streamlit (UAT)`

**Production Environment:**
- `ENVIRONMENT=production`
- `APP_NAME=Hello World Streamlit`

### Runtime Configuration

- **OS**: Linux
- **Runtime Stack**: Python 3.10
- **Port**: 8000 (internal), exposed via Azure App Service

## Manual Deployment (Alternative)

If CI/CD is not available, you can deploy manually using Azure CLI:

```bash
# Login to Azure
az login

# Deploy to UAT
az webapp deployment source config-zip \
  --resource-group {resource-group-name} \
  --name {app-service-name-uat} \
  --src app.zip

# Deploy to Production
az webapp deployment source config-zip \
  --resource-group {resource-group-name} \
  --name {app-service-name-prod} \
  --src app.zip
```

## Troubleshooting

### Deployment Fails

1. Verify Azure credentials are correct
2. Check Service Principal has necessary permissions
3. Ensure App Service names match the secrets
4. Verify startup command is configured correctly

### Application Not Starting

1. Check App Service logs: `az webapp log tail --name {app-name} --resource-group {rg-name}`
2. Verify Python version matches (3.10)
3. Check that all dependencies are in `requirements.txt`
4. Verify startup command is correct

### CI Pipeline Fails

1. Check GitHub Actions logs for specific error messages
2. Verify all dependencies are listed in `requirements.txt` and `requirements-dev.txt`
3. Ensure Python version matches (3.10)
4. Check that linting and tests pass locally
