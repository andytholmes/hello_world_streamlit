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
read -p "UAT Resource Group name [default: rg-hello-world-streamlit-uat]: " RESOURCE_GROUP_UAT
RESOURCE_GROUP_UAT=${RESOURCE_GROUP_UAT:-rg-hello-world-streamlit-uat}

read -p "Production Resource Group name [default: rg-hello-world-streamlit-prod]: " RESOURCE_GROUP_PROD
RESOURCE_GROUP_PROD=${RESOURCE_GROUP_PROD:-rg-hello-world-streamlit-prod}

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
echo "UAT Resource Group: $RESOURCE_GROUP_UAT"
echo "Production Resource Group: $RESOURCE_GROUP_PROD"
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

# Create UAT Resource Group
echo ""
echo -e "${BLUE}Step 1: Creating UAT Resource Group...${NC}"
if az group show --name "$RESOURCE_GROUP_UAT" &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} Resource group '$RESOURCE_GROUP_UAT' already exists"
else
    az group create --name "$RESOURCE_GROUP_UAT" --location "$LOCATION"
    echo -e "${GREEN}✓${NC} UAT Resource group created"
fi

# Create Production Resource Group
echo ""
echo -e "${BLUE}Step 2: Creating Production Resource Group...${NC}"
if az group show --name "$RESOURCE_GROUP_PROD" &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} Resource group '$RESOURCE_GROUP_PROD' already exists"
else
    az group create --name "$RESOURCE_GROUP_PROD" --location "$LOCATION"
    echo -e "${GREEN}✓${NC} Production Resource group created"
fi

# Create UAT App Service Plan
APP_SERVICE_PLAN_UAT="${RESOURCE_GROUP_UAT}-plan"
echo ""
echo -e "${BLUE}Step 3: Creating UAT App Service Plan...${NC}"
if az appservice plan show --name "$APP_SERVICE_PLAN_UAT" --resource-group "$RESOURCE_GROUP_UAT" &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} App Service Plan '$APP_SERVICE_PLAN_UAT' already exists"
else
    az appservice plan create \
        --name "$APP_SERVICE_PLAN_UAT" \
        --resource-group "$RESOURCE_GROUP_UAT" \
        --location "$LOCATION" \
        --sku "$SKU" \
        --is-linux
    echo -e "${GREEN}✓${NC} UAT App Service Plan created"
fi

# Create Production App Service Plan
APP_SERVICE_PLAN_PROD="${RESOURCE_GROUP_PROD}-plan"
echo ""
echo -e "${BLUE}Step 4: Creating Production App Service Plan...${NC}"
if az appservice plan show --name "$APP_SERVICE_PLAN_PROD" --resource-group "$RESOURCE_GROUP_PROD" &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} App Service Plan '$APP_SERVICE_PLAN_PROD' already exists"
else
    az appservice plan create \
        --name "$APP_SERVICE_PLAN_PROD" \
        --resource-group "$RESOURCE_GROUP_PROD" \
        --location "$LOCATION" \
        --sku "$SKU" \
        --is-linux
    echo -e "${GREEN}✓${NC} Production App Service Plan created"
fi

# Create UAT App Service
echo ""
echo -e "${BLUE}Step 5: Creating UAT App Service...${NC}"
if az webapp show --name "$APP_SERVICE_UAT" --resource-group "$RESOURCE_GROUP_UAT" &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} App Service '$APP_SERVICE_UAT' already exists"
else
    az webapp create \
        --name "$APP_SERVICE_UAT" \
        --resource-group "$RESOURCE_GROUP_UAT" \
        --plan "$APP_SERVICE_PLAN_UAT" \
        --runtime "PYTHON:3.10"
    
    # Configure startup command
    az webapp config set \
        --name "$APP_SERVICE_UAT" \
        --resource-group "$RESOURCE_GROUP_UAT" \
        --startup-file "streamlit run app.py --server.port=8000 --server.address=0.0.0.0"
    
    # Set environment variables
    az webapp config appsettings set \
        --name "$APP_SERVICE_UAT" \
        --resource-group "$RESOURCE_GROUP_UAT" \
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
echo -e "${BLUE}Step 6: Creating Production App Service...${NC}"
if az webapp show --name "$APP_SERVICE_PROD" --resource-group "$RESOURCE_GROUP_PROD" &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} App Service '$APP_SERVICE_PROD' already exists"
else
    az webapp create \
        --name "$APP_SERVICE_PROD" \
        --resource-group "$RESOURCE_GROUP_PROD" \
        --plan "$APP_SERVICE_PLAN_PROD" \
        --runtime "PYTHON:3.10"
    
    # Configure startup command
    az webapp config set \
        --name "$APP_SERVICE_PROD" \
        --resource-group "$RESOURCE_GROUP_PROD" \
        --startup-file "streamlit run app.py --server.port=8000 --server.address=0.0.0.0"
    
    # Set environment variables
    az webapp config appsettings set \
        --name "$APP_SERVICE_PROD" \
        --resource-group "$RESOURCE_GROUP_PROD" \
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
echo "  UAT Environment:"
echo "    - Resource Group: $RESOURCE_GROUP_UAT"
echo "    - App Service Plan: $APP_SERVICE_PLAN_UAT"
echo "    - App Service: $APP_SERVICE_UAT"
echo ""
echo "  Production Environment:"
echo "    - Resource Group: $RESOURCE_GROUP_PROD"
echo "    - App Service Plan: $APP_SERVICE_PLAN_PROD"
echo "    - App Service: $APP_SERVICE_PROD"
echo ""
echo "Next Steps:"
echo "1. Run the Azure credentials setup script:"
echo "   ./scripts/setup-azure-credentials.sh"
echo ""
echo "2. Use these values when setting up GitHub Secrets:"
echo "   AZURE_RESOURCE_GROUP_UAT = $RESOURCE_GROUP_UAT"
echo "   AZURE_RESOURCE_GROUP_PRODUCTION = $RESOURCE_GROUP_PROD"
echo "   AZURE_APP_SERVICE_UAT = $APP_SERVICE_UAT"
echo "   AZURE_APP_SERVICE_PRODUCTION = $APP_SERVICE_PROD"
echo ""
echo "3. After adding secrets, push to the develop branch to trigger deployment"
echo ""
