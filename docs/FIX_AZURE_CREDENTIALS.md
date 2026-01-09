# Fix Azure Credentials Error

## The Error

```
Error: AADSTS7000215: Invalid client secret provided. 
Ensure the secret being sent in the request is the client secret value, 
not the client secret ID, for a secret added to app '***'.
```

This means the `AZURE_CREDENTIALS` secret in GitHub is incorrect.

## Quick Fix Steps

### Step 1: Create a New Service Principal

Run the setup script to generate fresh credentials:

```bash
./scripts/setup-azure-credentials.sh
```

**OR** create manually:

```bash
# First, get your resource group name (use the one you created earlier)
RESOURCE_GROUP="rg-hello-world-streamlit"  # Replace with your actual resource group

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-hello-world-streamlit" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth
```

### Step 2: Copy the ENTIRE JSON Output

The command will output JSON that looks like this:

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

**⚠️ IMPORTANT:** 
- Copy **EVERYTHING** from `{` to `}`
- Include all fields (don't skip any)
- Copy it as a **single line** or keep it as formatted JSON (both work)
- Make sure no characters are missing

### Step 3: Update GitHub Secret

1. Go to: https://github.com/andytholmes/hello_world_streamlit/settings/secrets/actions

2. Find the `AZURE_CREDENTIALS` secret and click **"Update"** (or delete and recreate)

3. Paste the **entire JSON** you copied in Step 2

4. Click **"Update secret"**

### Step 4: Test Again

After updating the secret, trigger the workflow again:

```bash
# Make a small commit
echo "# Test credentials fix - $(date)" >> README.md
git add README.md
git commit -m "test: Verify Azure credentials fix"
git push origin develop
```

Then check: https://github.com/andytholmes/hello_world_streamlit/actions

## Common Mistakes to Avoid

### ❌ Wrong: Only copying part of the JSON
```json
{
  "clientId": "...",
  "clientSecret": "..."
}
```
This is incomplete - GitHub Actions needs all fields.

### ❌ Wrong: Using the client secret ID instead of value
- The `clientSecret` should be a long random string
- NOT a GUID (UUID) format
- If it looks like `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`, that's wrong

### ❌ Wrong: Adding extra quotes or escaping
- Don't wrap the JSON in extra quotes
- Don't escape the JSON
- Just paste it as-is

### ✅ Correct: Copy the entire JSON exactly as shown
The entire output from `az ad sp create-for-rbac --sdk-auth` should be pasted.

## Alternative: Check Existing Service Principal

If you want to keep the same service principal but reset its secret:

```bash
# Get the service principal ID
SP_APP_ID=$(az ad sp list --display-name "github-actions-hello-world-streamlit" --query "[0].appId" -o tsv)

# Delete the old secret (if needed)
# Then create a new secret
az ad sp credential reset --id $SP_APP_ID --append

# This will output a new password/secret
# But note: This won't give you the full SDK-auth JSON format
# You'll need to manually construct it or recreate the service principal
```

**Recommendation:** It's easier to just recreate the service principal using the script.

## Verify Credentials Locally (Optional)

You can test if the credentials work locally:

```bash
# Save credentials to a temporary file (DON'T COMMIT THIS!)
cat > /tmp/test-azure-creds.json << 'EOF'
{
  "clientId": "...",
  "clientSecret": "...",
  "subscriptionId": "...",
  "tenantId": "..."
}
EOF

# Test login
az login --service-principal \
  --username $(jq -r .clientId /tmp/test-azure-creds.json) \
  --password $(jq -r .clientSecret /tmp/test-azure-creds.json) \
  --tenant $(jq -r .tenantId /tmp/test-azure-creds.json)

# If successful, you're logged in
az account show

# Clean up
rm /tmp/test-azure-creds.json
```

## Still Having Issues?

1. **Verify the service principal exists:**
   ```bash
   az ad sp list --display-name "github-actions-hello-world-streamlit"
   ```

2. **Check permissions:**
   ```bash
   RESOURCE_GROUP="rg-hello-world-streamlit"  # Your resource group
   SP_APP_ID=$(az ad sp list --display-name "github-actions-hello-world-streamlit" --query "[0].appId" -o tsv)
   
   az role assignment list \
     --assignee $SP_APP_ID \
     --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP
   ```

3. **Delete and recreate the service principal:**
   ```bash
   # Delete existing
   az ad sp delete --id $(az ad sp list --display-name "github-actions-hello-world-streamlit" --query "[0].id" -o tsv)
   
   # Then run the setup script again
   ./scripts/setup-azure-credentials.sh
   ```

---

**After fixing, the workflow should succeed!** ✅
