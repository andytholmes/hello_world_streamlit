#!/bin/bash

# Azure Credentials Setup Script for GitHub Actions
# This script creates separate service principals for UAT (read/write) and Production (read-only)
# with segregated resource groups for security and isolation

set -e

echo "=========================================="
echo "Azure Credentials Setup for GitHub Actions"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get current subscription info
echo "Checking Azure login status..."
if ! az account show &>/dev/null; then
    echo -e "${RED}Error: Not logged into Azure. Please run 'az login' first.${NC}"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

echo -e "${GREEN}✓${NC} Logged in to Azure"
echo "   Subscription: $SUBSCRIPTION_NAME"
echo "   Subscription ID: $SUBSCRIPTION_ID"
echo "   Tenant ID: $TENANT_ID"
echo ""

# Ask for resource group names
echo "Enter the Azure Resource Group names (press Enter for defaults):"
read -p "UAT Resource Group name [default: rg-hello-world-streamlit-uat]: " RESOURCE_GROUP_UAT
RESOURCE_GROUP_UAT=${RESOURCE_GROUP_UAT:-rg-hello-world-streamlit-uat}

read -p "Production Resource Group name [default: rg-hello-world-streamlit-prod]: " RESOURCE_GROUP_PROD
RESOURCE_GROUP_PROD=${RESOURCE_GROUP_PROD:-rg-hello-world-streamlit-prod}

echo ""
echo "Verifying resource groups..."

# Check if resource groups exist
UAT_EXISTS=false
PROD_EXISTS=false

if az group show --name "$RESOURCE_GROUP_UAT" &>/dev/null; then
    echo -e "${GREEN}✓${NC} UAT Resource group '$RESOURCE_GROUP_UAT' exists"
    UAT_EXISTS=true
else
    echo -e "${YELLOW}⚠${NC} UAT Resource group '$RESOURCE_GROUP_UAT' does not exist yet"
    echo "   The service principal will be created, but you'll need to create the resource group first."
fi

if az group show --name "$RESOURCE_GROUP_PROD" &>/dev/null; then
    echo -e "${GREEN}✓${NC} Production Resource group '$RESOURCE_GROUP_PROD' exists"
    PROD_EXISTS=true
else
    echo -e "${YELLOW}⚠${NC} Production Resource group '$RESOURCE_GROUP_PROD' does not exist yet"
    echo "   The service principal will be created, but you'll need to create the resource group first."
fi

echo ""
echo "=========================================="
echo "Creating Service Principals"
echo "=========================================="
echo ""

# Service principal names
SP_NAME_UAT="github-actions-hello-world-streamlit-uat"
SP_NAME_PROD="github-actions-hello-world-streamlit-prod"

# Create UAT Service Principal (Contributor role - read/write)
echo -e "${BLUE}Creating UAT Service Principal...${NC}"
echo "   Name: $SP_NAME_UAT"
echo "   Scope: /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_UAT"
echo "   Role: Contributor (read/write access)"
echo ""

CREDENTIALS_UAT=$(az ad sp create-for-rbac \
    --name "$SP_NAME_UAT" \
    --role contributor \
    --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_UAT" \
    --sdk-auth \
    2>&1)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} UAT Service Principal created successfully!"
else
    echo -e "${RED}Error creating UAT service principal:${NC}"
    echo "$CREDENTIALS_UAT"
    echo ""
    echo "Common issues:"
    echo "  - Service principal name already exists. Delete it first or use a different name."
    echo "  - Insufficient permissions. You may need to be a subscription owner."
    exit 1
fi

echo ""

# Create Production Service Principal (Reader role - read-only)
echo -e "${BLUE}Creating Production Service Principal...${NC}"
echo "   Name: $SP_NAME_PROD"
echo "   Scope: /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_PROD"
echo "   Role: Reader (read-only access)"
echo ""

CREDENTIALS_PROD=$(az ad sp create-for-rbac \
    --name "$SP_NAME_PROD" \
    --role reader \
    --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_PROD" \
    --sdk-auth \
    2>&1)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Production Service Principal created successfully!"
else
    echo -e "${RED}Error creating Production service principal:${NC}"
    echo "$CREDENTIALS_PROD"
    echo ""
    echo "Common issues:"
    echo "  - Service principal name already exists. Delete it first or use a different name."
    echo "  - Insufficient permissions. You may need to be a subscription owner."
    exit 1
fi

echo ""
echo "=========================================="
echo "UAT Azure Credentials (JSON)"
echo "=========================================="
echo "$CREDENTIALS_UAT"
echo ""
echo "=========================================="
echo "Production Azure Credentials (JSON)"
echo "=========================================="
echo "$CREDENTIALS_PROD"
echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Copy BOTH JSON outputs above (UAT and Production)"
echo ""
echo "2. Go to your GitHub repository:"
echo "   https://github.com/andytholmes/hello_world_streamlit/settings/secrets/actions"
echo ""
echo "3. Click 'New repository secret' and add the following secrets:"
echo ""
echo "   Secret 1: AZURE_CREDENTIALS_UAT"
echo "   - Name: AZURE_CREDENTIALS_UAT"
echo "   - Value: [paste the UAT JSON output above]"
echo ""
echo "   Secret 2: AZURE_CREDENTIALS_PRODUCTION"
echo "   - Name: AZURE_CREDENTIALS_PRODUCTION"
echo "   - Value: [paste the Production JSON output above]"
echo ""
echo "   Secret 3: AZURE_RESOURCE_GROUP_UAT"
echo "   - Name: AZURE_RESOURCE_GROUP_UAT"
echo "   - Value: $RESOURCE_GROUP_UAT"
echo ""
echo "   Secret 4: AZURE_RESOURCE_GROUP_PRODUCTION"
echo "   - Name: AZURE_RESOURCE_GROUP_PRODUCTION"
echo "   - Value: $RESOURCE_GROUP_PROD"
echo ""
echo "   Secret 5: AZURE_APP_SERVICE_UAT"
echo "   - Name: AZURE_APP_SERVICE_UAT"
echo "   - Value: [your UAT app service name, e.g., hello-world-streamlit-uat]"
echo ""
echo "   Secret 6: AZURE_APP_SERVICE_PRODUCTION"
echo "   - Name: AZURE_APP_SERVICE_PRODUCTION"
echo "   - Value: [your Production app service name, e.g., hello-world-streamlit-prod]"
echo ""
echo "4. ⚠️  IMPORTANT: Save the clientSecret values from BOTH JSON outputs!"
echo "   You won't see them again after this."
echo ""
echo "=========================================="
echo ""
echo "Security Notes:"
echo "  - UAT Service Principal: Contributor role (read/write) on UAT resource group"
echo "  - Production Service Principal: Reader role (read-only) on Production resource group"
echo "  - Environments are fully segregated with separate resource groups"
echo ""
# Save to file for reference (optional)
read -p "Save credentials to files for reference? (y/n): " SAVE_FILE
if [ "$SAVE_FILE" == "y" ]; then
    echo "$CREDENTIALS_UAT" > azure-credentials-uat.json
    echo "$CREDENTIALS_PROD" > azure-credentials-prod.json
    echo -e "${GREEN}✓${NC} Saved to:"
    echo "   - azure-credentials-uat.json"
    echo "   - azure-credentials-prod.json"
    echo -e "${YELLOW}⚠${NC} WARNING: These files contain sensitive credentials!"
    echo "   Add them to .gitignore and delete them after adding to GitHub secrets."
fi
