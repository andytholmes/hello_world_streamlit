#!/bin/bash

# Azure Credentials Setup Script for GitHub Actions
# This script helps you create an Azure Service Principal and configure it for GitHub Actions

set -e

echo "=========================================="
echo "Azure Credentials Setup for GitHub Actions"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Ask for resource group name
echo "Enter the Azure Resource Group name where your App Services are/will be located:"
read -p "Resource Group name (e.g., rg-hello-world-streamlit): " RESOURCE_GROUP

if [ -z "$RESOURCE_GROUP" ]; then
    echo -e "${YELLOW}Warning: No resource group specified.${NC}"
    echo "You can create one later with:"
    echo "  az group create --name <resource-group-name> --location <location>"
    echo ""
    read -p "Continue anyway? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        exit 0
    fi
    SCOPE="/subscriptions/$SUBSCRIPTION_ID"
else
    # Check if resource group exists
    if az group show --name "$RESOURCE_GROUP" &>/dev/null; then
        echo -e "${GREEN}✓${NC} Resource group '$RESOURCE_GROUP' exists"
        SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
    else
        echo -e "${YELLOW}⚠${NC} Resource group '$RESOURCE_GROUP' does not exist yet"
        echo "The service principal will be created with scope on the subscription."
        echo "You can assign it to the resource group later."
        SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
    fi
fi

echo ""

# Service principal name
SP_NAME="github-actions-hello-world-streamlit"

echo "Creating Azure Service Principal..."
echo "   Name: $SP_NAME"
echo "   Scope: $SCOPE"
echo "   Role: Contributor"
echo ""

# Create service principal
CREDENTIALS=$(az ad sp create-for-rbac \
    --name "$SP_NAME" \
    --role contributor \
    --scopes "$SCOPE" \
    --sdk-auth \
    2>&1)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Service Principal created successfully!"
    echo ""
    echo "=========================================="
    echo "Azure Credentials (JSON)"
    echo "=========================================="
    echo "$CREDENTIALS"
    echo ""
    echo "=========================================="
    echo "Next Steps"
    echo "=========================================="
    echo ""
    echo "1. Copy the JSON above (everything between the { and })"
    echo ""
    echo "2. Go to your GitHub repository:"
    echo "   https://github.com/andytholmes/hello_world_streamlit/settings/secrets/actions"
    echo ""
    echo "3. Click 'New repository secret' and add:"
    echo "   Name: AZURE_CREDENTIALS"
    echo "   Value: [paste the entire JSON output above]"
    echo ""
    echo "4. Also ensure these secrets are set:"
    echo "   - AZURE_APP_SERVICE_UAT (e.g., hello-world-streamlit-uat)"
    echo "   - AZURE_APP_SERVICE_PRODUCTION (e.g., hello-world-streamlit-prod)"
    echo "   - AZURE_RESOURCE_GROUP (e.g., $RESOURCE_GROUP)"
    echo ""
    echo "5. Save the clientSecret from the JSON output above - you won't see it again!"
    echo ""
    echo "=========================================="
    
    # Save to file for reference (optional)
    read -p "Save credentials to azure-credentials.json? (y/n): " SAVE_FILE
    if [ "$SAVE_FILE" == "y" ]; then
        echo "$CREDENTIALS" > azure-credentials.json
        echo -e "${GREEN}✓${NC} Saved to azure-credentials.json"
        echo -e "${YELLOW}⚠${NC} WARNING: This file contains sensitive credentials!"
        echo "   Add it to .gitignore and delete it after adding to GitHub secrets."
    fi
else
    echo -e "${RED}Error creating service principal:${NC}"
    echo "$CREDENTIALS"
    echo ""
    echo "Common issues:"
    echo "  - Service principal name already exists. Try a different name."
    echo "  - Insufficient permissions. You may need to be a subscription owner."
    exit 1
fi
