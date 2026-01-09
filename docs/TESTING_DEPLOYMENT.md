# Testing the Deployment Pipeline

This guide walks you through testing your CI/CD pipeline after Azure resources have been created.

## Prerequisites Checklist

Before testing, ensure you have:

- ✅ **Azure resources created** (Resource Group, App Service Plan, UAT and Production App Services)
- ✅ **GitHub Secrets configured** (see below)
- ✅ **Service Principal created** with proper permissions
- ✅ **Code committed** to your repository

## Step 1: Verify GitHub Secrets

The pipeline requires these secrets to be configured in GitHub:

1. Go to: https://github.com/andytholmes/hello_world_streamlit/settings/secrets/actions

2. Verify these secrets exist:
   - ✅ `AZURE_CREDENTIALS` - JSON credentials from service principal
   - ✅ `AZURE_RESOURCE_GROUP` - Your resource group name (e.g., `rg-hello-world-streamlit`)
   - ✅ `AZURE_APP_SERVICE_UAT` - Your UAT app service name (e.g., `hello-world-streamlit-uat`)
   - ✅ `AZURE_APP_SERVICE_PRODUCTION` - Your production app service name (e.g., `hello-world-streamlit-prod`)
   - ⚠️ `CODECOV_TOKEN` - Optional (can skip if not using Codecov)

**If secrets are missing**, run:
```bash
./scripts/setup-azure-credentials.sh
```
Then add the secrets to GitHub as shown in the script output.

## Step 2: Verify Current Branch

The pipeline triggers on pushes to `develop` and `main` branches.

```bash
# Check current branch
git branch --show-current

# If not on develop, switch to it
git checkout develop
```

## Step 3: Make a Test Change

Make a small, safe change to trigger the pipeline:

```bash
# Option 1: Update a comment or documentation
echo "# Test deployment - $(date)" >> README.md
git add README.md
git commit -m "test: Trigger deployment pipeline"
git push origin develop
```

**Or** make a small code change:

```bash
# Option 2: Add a comment to app.py
# Edit app.py and add a comment, then:
git add app.py
git commit -m "test: Trigger deployment pipeline"
git push origin develop
```

## Step 4: Monitor the Pipeline

### View in GitHub Actions

1. Go to: https://github.com/andytholmes/hello_world_streamlit/actions

2. You should see a new workflow run with:
   - **Workflow**: "CI/CD Pipeline"
   - **Trigger**: "push" to develop branch
   - **Status**: Running (yellow) → Success (green) or Failed (red)

3. Click on the workflow run to see detailed logs

### Expected Workflow Steps

The pipeline runs these jobs in sequence:

1. **Continuous Integration (CI)**
   - ✅ Checkout code
   - ✅ Set up Python 3.10
   - ✅ Install dependencies
   - ✅ Run linting (ruff check)
   - ✅ Check code formatting (ruff format)
   - ✅ Run unit tests (pytest)
   - ✅ Upload coverage (optional)

2. **Deploy to UAT** (runs after CI succeeds)
   - ✅ Checkout code
   - ✅ Set up Python
   - ✅ Azure Login
   - ✅ Install Azure CLI
   - ✅ Create deployment package
   - ✅ Deploy to Azure App Service (UAT)
   - ✅ Configure startup command
   - ✅ Set environment variables

### What to Watch For

**✅ Success Indicators:**
- All steps show green checkmarks
- "Deploy to UAT" job completes successfully
- No error messages in logs

**❌ Common Issues:**

1. **Azure Login fails**
   - Check `AZURE_CREDENTIALS` secret is correct
   - Verify service principal has Contributor role on resource group

2. **Deployment fails**
   - Check `AZURE_APP_SERVICE_UAT` secret matches actual app service name
   - Verify app service exists in Azure

3. **Tests fail**
   - Run tests locally: `pytest`
   - Check for linting errors: `ruff check .`

## Step 5: Verify Deployment

After the pipeline succeeds, verify the app is deployed:

### Check Azure Portal

1. Go to: https://portal.azure.com
2. Navigate to: **App Services** → Your UAT app service
3. Check:
   - **Status**: Running
   - **Deployment Center**: Should show recent deployment
   - **Configuration**: Verify environment variables are set

### Test the Application

1. Get the app URL:
   ```bash
   az webapp show \
     --name <your-uat-app-name> \
     --resource-group <your-resource-group> \
     --query defaultHostName -o tsv
   ```

2. Open in browser:
   ```
   https://<your-uat-app-name>.azurewebsites.net
   ```

3. Verify:
   - ✅ App loads without errors
   - ✅ Shows "Hello World Streamlit" interface
   - ✅ Environment shows as "UAT" (if your app displays this)

### Check Logs

```bash
# Stream live logs
az webapp log tail \
  --name <your-uat-app-name> \
  --resource-group <your-resource-group>

# Or view in Azure Portal:
# App Service → Monitoring → Log stream
```

## Step 6: Test Production Deployment

To test production deployment:

```bash
# Switch to main branch
git checkout main

# Merge develop into main (or create a PR)
git merge develop

# Push to main
git push origin main
```

**Note:** Production deployment only triggers on pushes to `main` branch.

## Troubleshooting

### Pipeline Not Triggering

**Issue:** No workflow run appears after push

**Solutions:**
- Verify workflow file exists: `.github/workflows/ci-cd.yml`
- Check you're pushing to `develop` or `main` branch
- Ensure workflow file is committed and pushed
- Check GitHub Actions is enabled for your repository

### Deployment Succeeds but App Doesn't Work

**Check:**
1. App Service logs for errors
2. Startup command is correct: `streamlit run app.py --server.port=8000 --server.address=0.0.0.0`
3. Port is set correctly: `WEBSITES_PORT=8000`
4. Dependencies are in `requirements.txt`

### View Detailed Logs

In GitHub Actions:
- Click on the failed step
- Expand the step to see detailed output
- Look for error messages

In Azure:
```bash
# View application logs
az webapp log download \
  --name <app-name> \
  --resource-group <resource-group> \
  --log-file app-logs.zip
```

## Quick Test Commands

```bash
# 1. Verify secrets are set (check manually in GitHub)
# Go to: Settings → Secrets and variables → Actions

# 2. Make a test commit
echo "# Deployment test $(date)" >> README.md
git add README.md
git commit -m "test: Trigger CI/CD pipeline"
git push origin develop

# 3. Watch the workflow
# Go to: https://github.com/andytholmes/hello_world_streamlit/actions

# 4. After success, test the app
az webapp browse \
  --name <your-uat-app-name> \
  --resource-group <your-resource-group>
```

## Success Criteria

Your deployment pipeline is working correctly if:

- ✅ CI job completes successfully (all tests pass)
- ✅ UAT deployment job completes successfully
- ✅ App is accessible at `https://<app-name>.azurewebsites.net`
- ✅ App displays correctly in browser
- ✅ No errors in application logs

## Next Steps

Once UAT deployment is verified:

1. **Test production deployment** by merging to `main`
2. **Set up monitoring** (optional):
   - Azure Application Insights
   - GitHub Actions status badges
3. **Configure branch protection** (optional):
   - Require CI to pass before merging
   - Require reviews for production deployments

---

**Need Help?**
- Check workflow logs in GitHub Actions
- Review Azure App Service logs
- See [AZURE_SETUP.md](AZURE_SETUP.md) for credential issues
- See [FIX_AZURE_CREDENTIALS.md](FIX_AZURE_CREDENTIALS.md) for credential errors
- See `.github/DEPLOYMENT.md` for deployment details
