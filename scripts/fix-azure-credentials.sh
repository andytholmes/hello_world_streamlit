#!/bin/bash

# Quick Fix Script for Azure Credentials
# This script helps regenerate Azure credentials for both UAT and Production environments
# with segregated service principals and resource groups

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Fix Azure Credentials for GitHub Actions"
echo "=========================================="
echo ""

# Check Azure login
if ! az account show &>/dev/null; then
    echo -e "${RED}Error: Not logged into Azure. Please run 'az login' first.${NC}"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo -e "${GREEN}✓${NC} Logged in to Azure"
echo "   Subscription ID: $SUBSCRIPTION_ID"
echo ""

# Get resource groups
read -p "Enter UAT Resource Group name [default: rg-hello-world-streamlit-uat]: " RESOURCE_GROUP_UAT
RESOURCE_GROUP_UAT=${RESOURCE_GROUP_UAT:-rg-hello-world-streamlit-uat}

read -p "Enter Production Resource Group name [default: rg-hello-world-streamlit-prod]: " RESOURCE_GROUP_PROD
RESOURCE_GROUP_PROD=${RESOURCE_GROUP_PROD:-rg-hello-world-streamlit-prod}

# Verify resource groups exist
UAT_EXISTS=false
PROD_EXISTS=false

if az group show --name "$RESOURCE_GROUP_UAT" &>/dev/null; then
    echo -e "${GREEN}✓${NC} UAT Resource group found: $RESOURCE_GROUP_UAT"
    UAT_EXISTS=true
else
    echo -e "${YELLOW}⚠${NC} UAT Resource group '$RESOURCE_GROUP_UAT' not found"
fi

if az group show --name "$RESOURCE_GROUP_PROD" &>/dev/null; then
    echo -e "${GREEN}✓${NC} Production Resource group found: $RESOURCE_GROUP_PROD"
    PROD_EXISTS=true
else
    echo -e "${YELLOW}⚠${NC} Production Resource group '$RESOURCE_GROUP_PROD' not found"
fi

if [ "$UAT_EXISTS" = false ] && [ "$PROD_EXISTS" = false ]; then
    echo -e "${RED}Error: Neither resource group found.${NC}"
    echo "Available resource groups:"
    az group list --query "[].name" -o table
    exit 1
fi

echo ""

# Service principal names
SP_NAME_UAT="github-actions-hello-world-streamlit-uat"
SP_NAME_PROD="github-actions-hello-world-streamlit-prod"

# Function to handle service principal creation/reset
create_or_reset_sp() {
    local SP_NAME=$1
    local SCOPE=$2
    local ROLE=$3
    local ENV_NAME=$4
    
    echo -e "${BLUE}Processing $ENV_NAME Service Principal...${NC}"
    
    EXISTING_SP=$(az ad sp list --display-name "$SP_NAME" --query "[0].appId" -o tsv 2>/dev/null || echo "")
    
    if [ -n "$EXISTING_SP" ]; then
        echo -e "${YELLOW}⚠${NC} Service Principal '$SP_NAME' already exists"
        echo "   App ID: $EXISTING_SP"
        echo ""
        read -p "Delete existing service principal and create a new one? (y/n): " DELETE_SP
        if [ "$DELETE_SP" == "y" ]; then
            echo "Deleting existing service principal..."
            SP_ID=$(az ad sp list --display-name "$SP_NAME" --query "[0].id" -o tsv)
            az ad sp delete --id "$SP_ID" 2>/dev/null || echo "Service principal deleted or already removed"
            echo -e "${GREEN}✓${NC} Old service principal deleted"
            echo ""
            # Create new
            az ad sp create-for-rbac \
                --name "$SP_NAME" \
                --role "$ROLE" \
                --scopes "$SCOPE" \
                --sdk-auth
        else
            # Reset password for existing SP
            echo "Resetting password for existing service principal..."
            NEW_PASSWORD=$(az ad sp credential reset --id "$EXISTING_SP" --query password -o tsv)
            CLIENT_ID="$EXISTING_SP"
            
            # Construct JSON manually
            cat <<EOF
{
  "clientId": "$CLIENT_ID",
  "clientSecret": "$NEW_PASSWORD",
  "subscriptionId": "$SUBSCRIPTION_ID",
  "tenantId": "$TENANT_ID",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
EOF
        fi
    else
        # Create new
        az ad sp create-for-rbac \
            --name "$SP_NAME" \
            --role "$ROLE" \
            --scopes "$SCOPE" \
            --sdk-auth
    fi
}

# Create/Reset UAT Service Principal
if [ "$UAT_EXISTS" = true ]; then
    echo "=========================================="
    echo "UAT Service Principal"
    echo "=========================================="
    SCOPE_UAT="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_UAT"
    CREDENTIALS_UAT=$(create_or_reset_sp "$SP_NAME_UAT" "$SCOPE_UAT" "contributor" "UAT")
    echo ""
fi

# Create/Reset Production Service Principal
if [ "$PROD_EXISTS" = true ]; then
    echo "=========================================="
    echo "Production Service Principal"
    echo "=========================================="
    SCOPE_PROD="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_PROD"
    CREDENTIALS_PROD=$(create_or_reset_sp "$SP_NAME_PROD" "$SCOPE_PROD" "contributor" "Production")
    echo ""
fi

# Display results
echo ""
echo "=========================================="
echo -e "${GREEN}✓ Azure Credentials Generated${NC}"
echo "=========================================="
echo ""

if [ "$UAT_EXISTS" = true ]; then
    echo -e "${YELLOW}UAT Credentials (JSON):${NC}"
    echo "----------------------------------------"
    echo "$CREDENTIALS_UAT"
    echo "----------------------------------------"
    echo ""
fi

if [ "$PROD_EXISTS" = true ]; then
    echo -e "${YELLOW}Production Credentials (JSON):${NC}"
    echo "----------------------------------------"
    echo "$CREDENTIALS_PROD"
    echo "----------------------------------------"
    echo ""
fi

echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. Copy BOTH JSON outputs above (UAT and Production)"
echo ""
echo "2. Go to GitHub:"
echo "   https://github.com/andytholmes/hello_world_streamlit/settings/secrets/actions"
echo ""
echo "3. Update the following secrets:"
echo ""
if [ "$UAT_EXISTS" = true ]; then
    echo "   - AZURE_CREDENTIALS_UAT: [paste UAT JSON]"
fi
if [ "$PROD_EXISTS" = true ]; then
    echo "   - AZURE_CREDENTIALS_PRODUCTION: [paste Production JSON]"
fi
echo ""
echo "4. Also ensure these secrets are set:"
echo "   - AZURE_RESOURCE_GROUP_UAT = $RESOURCE_GROUP_UAT"
echo "   - AZURE_RESOURCE_GROUP_PRODUCTION = $RESOURCE_GROUP_PROD"
echo ""
echo "5. ⚠️  IMPORTANT: Save the clientSecret values - you won't see them again!"
echo ""
echo "6. Re-run your GitHub Actions workflow"
echo ""
echo "=========================================="
echo ""
    
# Optionally save to file
read -p "Save credentials to files for reference? (y/n): " SAVE_FILE
if [ "$SAVE_FILE" == "y" ]; then
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    if [ "$UAT_EXISTS" = true ]; then
        echo "$CREDENTIALS_UAT" > "azure-credentials-uat-${TIMESTAMP}.json"
        echo -e "${GREEN}✓${NC} Saved UAT credentials to: azure-credentials-uat-${TIMESTAMP}.json"
    fi
    if [ "$PROD_EXISTS" = true ]; then
        echo "$CREDENTIALS_PROD" > "azure-credentials-prod-${TIMESTAMP}.json"
        echo -e "${GREEN}✓${NC} Saved Production credentials to: azure-credentials-prod-${TIMESTAMP}.json"
    fi
    echo -e "${YELLOW}⚠${NC} WARNING: Delete these files after adding to GitHub Secrets!"
fi
