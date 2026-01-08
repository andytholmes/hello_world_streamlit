#!/bin/bash

# Azure Resources Creation Script
# This script creates the necessary Azure resources for the Streamlit application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Azure Resources Creation for Streamlit App"
echo "=========================================="
echo ""

# Check Azure login
echo "Checking Azure login status..."
if ! az account show &>/dev/null; then
    echo -e "${RED}Error: Not logged into Azure. Please run 'az login' first.${NC}"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

echo -e "${GREEN}✓${NC} Logged in to Azure"
echo "   Subscription: $SUBSCRIPTION_NAME"
echo "   Subscription ID: $SUBSCRIPTION_ID"
echo ""

# Configuration
echo "Enter configuration details (press Enter to use defaults):"
read -p "Resource Group name [default: rg-hello-world-streamlit]: " RESOURCE_GROUP
RESOURCE_GROUP=${RESOURCE_GROUP:-rg-hello-world-streamlit}

read -p "Location (e.g., eastus, westus2, uksouth) [default: eastus]: " LOCATION
LOCATION=${LOCATION:-eastus}

read -p "App Service Plan SKU (e.g., B1, S1, F1) [default: B1]: " SKU
SKU=${SKU:-B1}

read -p "UAT App Service name [default: hello-world-streamlit-uat]: " APP_SERVICE_UAT
APP_SERVICE_UAT=${APP_SERVICE_UAT:-hello-world-streamlit-uat}

read -p "Production App Service name [default: hello-world-streamlit-prod]: " APP_SERVICE_PROD
APP_SERVICE_PROD=${APP_SERVICE_PROD:-hello-world-streamlit-prod}

echo ""
echo "=========================================="
echo "Configuration Summary"
echo "=========================================="
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "App Service Plan SKU: $SKU"
echo "UAT App Service: $APP_SERVICE_UAT"
echo "Production App Service: $APP_SERVICE_PROD"
echo "=========================================="
echo ""

read -p "Continue with resource creation? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Aborted."
    exit 0
fi

# Create Resource Group
echo ""
echo -e "${BLUE}Step 1: Creating Resource Group...${NC}"
if az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} Resource group '$RESOURCE_GROUP' already exists"
else
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
    echo -e "${GREEN}✓${NC} Resource group created"
fi

# Create App Service Plan
APP_SERVICE_PLAN="${RESOURCE_GROUP}-plan"
echo ""
echo -e "${BLUE}Step 2: Creating App Service Plan...${NC}"
if az appservice plan show --name "$APP_SERVICE_PLAN" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} App Service Plan '$APP_SERVICE_PLAN' already exists"
else
    az appservice plan create \
        --name "$APP_SERVICE_PLAN" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku "$SKU" \
        --is-linux
    echo -e "${GREEN}✓${NC} App Service Plan created"
fi

# Create UAT App Service
echo ""
echo -e "${BLUE}Step 3: Creating UAT App Service...${NC}"
if az webapp show --name "$APP_SERVICE_UAT" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} App Service '$APP_SERVICE_UAT' already exists"
else
    az webapp create \
        --name "$APP_SERVICE_UAT" \
        --resource-group "$RESOURCE_GROUP" \
        --plan "$APP_SERVICE_PLAN" \
        --runtime "PYTHON:3.10"
    
    # Configure startup command
    az webapp config set \
        --name "$APP_SERVICE_UAT" \
        --resource-group "$RESOURCE_GROUP" \
        --startup-file "streamlit run app.py --server.port=8000 --server.address=0.0.0.0"
    
    # Set environment variables
    az webapp config appsettings set \
        --name "$APP_SERVICE_UAT" \
        --resource-group "$RESOURCE_GROUP" \
        --settings \
            ENVIRONMENT=uat \
            APP_NAME="Hello World Streamlit (UAT)" \
            SCM_DO_BUILD_DURING_DEPLOYMENT=true \
            WEBSITES_PORT=8000
    
    echo -e "${GREEN}✓${NC} UAT App Service created and configured"
    echo "   URL: https://${APP_SERVICE_UAT}.azurewebsites.net"
fi

# Create Production App Service
echo ""
echo -e "${BLUE}Step 4: Creating Production App Service...${NC}"
if az webapp show --name "$APP_SERVICE_PROD" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} App Service '$APP_SERVICE_PROD' already exists"
else
    az webapp create \
        --name "$APP_SERVICE_PROD" \
        --resource-group "$RESOURCE_GROUP" \
        --plan "$APP_SERVICE_PLAN" \
        --runtime "PYTHON:3.10"
    
    # Configure startup command
    az webapp config set \
        --name "$APP_SERVICE_PROD" \
        --resource-group "$RESOURCE_GROUP" \
        --startup-file "streamlit run app.py --server.port=8000 --server.address=0.0.0.0"
    
    # Set environment variables
    az webapp config appsettings set \
        --name "$APP_SERVICE_PROD" \
        --resource-group "$RESOURCE_GROUP" \
        --settings \
            ENVIRONMENT=production \
            APP_NAME="Hello World Streamlit" \
            SCM_DO_BUILD_DURING_DEPLOYMENT=true \
            WEBSITES_PORT=8000
    
    echo -e "${GREEN}✓${NC} Production App Service created and configured"
    echo "   URL: https://${APP_SERVICE_PROD}.azurewebsites.net"
fi

echo ""
echo "=========================================="
echo "✓ Resources Created Successfully!"
echo "=========================================="
echo ""
echo "Created Resources:"
echo "  - Resource Group: $RESOURCE_GROUP"
echo "  - App Service Plan: $APP_SERVICE_PLAN"
echo "  - UAT App Service: $APP_SERVICE_UAT"
echo "  - Production App Service: $APP_SERVICE_PROD"
echo ""
echo "Next Steps:"
echo "1. Run the Azure credentials setup script:"
echo "   ./scripts/setup-azure-credentials.sh"
echo ""
echo "2. Use these values when setting up GitHub Secrets:"
echo "   AZURE_RESOURCE_GROUP = $RESOURCE_GROUP"
echo "   AZURE_APP_SERVICE_UAT = $APP_SERVICE_UAT"
echo "   AZURE_APP_SERVICE_PRODUCTION = $APP_SERVICE_PROD"
echo ""
echo "3. After adding secrets, push to the develop branch to trigger deployment"
echo ""
