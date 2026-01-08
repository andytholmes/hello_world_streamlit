#!/bin/bash

# Quick Fix Script for Azure Credentials
# This script helps regenerate Azure credentials with clear instructions

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

echo -e "${GREEN}✓${NC} Logged in to Azure"
echo "   Subscription ID: $SUBSCRIPTION_ID"
echo ""

# Get resource group
read -p "Enter your Resource Group name [default: rg-hello-world-streamlit]: " RESOURCE_GROUP
RESOURCE_GROUP=${RESOURCE_GROUP:-rg-hello-world-streamlit}

# Verify resource group exists
if ! az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    echo -e "${RED}Error: Resource group '$RESOURCE_GROUP' not found.${NC}"
    echo "Available resource groups:"
    az group list --query "[].name" -o table
    exit 1
fi

echo -e "${GREEN}✓${NC} Resource group found: $RESOURCE_GROUP"
echo ""

# Check if service principal exists
SP_NAME="github-actions-hello-world-streamlit"
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
    else
        echo "Skipping deletion. Creating new credentials with new secret..."
        echo ""
    fi
fi

# Create service principal
SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

echo "Creating/Updating Service Principal..."
echo "   Name: $SP_NAME"
echo "   Scope: $SCOPE"
echo "   Role: Contributor"
echo ""

# Create or reset service principal
if [ -z "$EXISTING_SP" ] || [ "$DELETE_SP" == "y" ]; then
    CREDENTIALS=$(az ad sp create-for-rbac \
        --name "$SP_NAME" \
        --role contributor \
        --scopes "$SCOPE" \
        --sdk-auth \
        2>&1)
else
    # Reset password for existing SP
    echo "Resetting password for existing service principal..."
    NEW_PASSWORD=$(az ad sp credential reset --id "$EXISTING_SP" --query password -o tsv)
    
    # Get other details
    TENANT_ID=$(az account show --query tenantId -o tsv)
    CLIENT_ID="$EXISTING_SP"
    
    # Construct JSON manually
    CREDENTIALS=$(cat <<EOF
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
)
fi

if [ $? -eq 0 ] || [ -n "$CREDENTIALS" ]; then
    echo ""
    echo "=========================================="
    echo -e "${GREEN}✓ Azure Credentials Generated${NC}"
    echo "=========================================="
    echo ""
    echo -e "${YELLOW}IMPORTANT: Copy the ENTIRE JSON below (everything from { to })${NC}"
    echo ""
    echo "----------------------------------------"
    echo "$CREDENTIALS"
    echo "----------------------------------------"
    echo ""
    echo "=========================================="
    echo "Next Steps:"
    echo "=========================================="
    echo ""
    echo "1. Copy the ENTIRE JSON above (select all, copy)"
    echo ""
    echo "2. Go to GitHub:"
    echo "   https://github.com/andytholmes/hello_world_streamlit/settings/secrets/actions"
    echo ""
    echo "3. Find 'AZURE_CREDENTIALS' secret and click 'Update'"
    echo "   (or delete it and create a new one)"
    echo ""
    echo "4. Paste the ENTIRE JSON into the value field"
    echo "   - Make sure all fields are included"
    echo "   - Don't add extra quotes or escaping"
    echo ""
    echo "5. Click 'Update secret'"
    echo ""
    echo "6. Re-run your GitHub Actions workflow"
    echo ""
    echo "=========================================="
    echo ""
    
    # Optionally save to file
    read -p "Save credentials to file for reference? (y/n): " SAVE_FILE
    if [ "$SAVE_FILE" == "y" ]; then
        CRED_FILE="azure-credentials-$(date +%Y%m%d-%H%M%S).json"
        echo "$CREDENTIALS" > "$CRED_FILE"
        echo -e "${GREEN}✓${NC} Saved to: $CRED_FILE"
        echo -e "${YELLOW}⚠${NC} WARNING: Delete this file after adding to GitHub Secrets!"
        echo "   rm $CRED_FILE"
    fi
else
    echo -e "${RED}Error generating credentials${NC}"
    echo "$CREDENTIALS"
    exit 1
fi
