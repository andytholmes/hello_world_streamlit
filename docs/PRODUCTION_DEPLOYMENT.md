# Production Deployment Guide

This guide explains how to deploy code from UAT to Production.

## Overview

Your CI/CD pipeline is configured as follows:
- **Push to `develop` branch** → Deploys to **UAT** environment
- **Push to `main` branch** → Deploys to **Production** environment

To deploy UAT to Production, you need to merge `develop` into `main` and push.

## Prerequisites

Before deploying to Production:

1. ✅ **UAT deployment is working correctly**
   - App is accessible and functioning
   - No critical bugs or issues
   - Tested thoroughly in UAT environment

2. ✅ **All code is committed and pushed to `develop`**
   - All changes are in the `develop` branch
   - CI/CD pipeline has passed for `develop`

3. ✅ **Production secrets are configured**
   - `AZURE_APP_SERVICE_PRODUCTION` secret exists in GitHub
   - Production App Service exists in Azure

## Deployment Methods

### Method 1: Direct Merge (Recommended for Small Teams)

This method directly merges `develop` into `main`:

```bash
# 1. Ensure you're on develop and up to date
git checkout develop
git pull origin develop

# 2. Switch to main branch
git checkout main
git pull origin main

# 3. Merge develop into main
git merge develop

# 4. Push to main (this triggers production deployment)
git push origin main
```

**What happens:**
- GitHub Actions detects the push to `main`
- Runs CI (linting, tests)
- If CI passes, automatically deploys to Production

### Method 2: Pull Request (Recommended for Larger Teams)

This method uses a Pull Request for code review before production:

```bash
# 1. Ensure develop is up to date
git checkout develop
git pull origin develop

# 2. Push develop to ensure it's up to date on GitHub
git push origin develop
```

Then on GitHub:
1. Go to: https://github.com/andytholmes/hello_world_streamlit
2. Click **"Pull requests"** → **"New pull request"**
3. Set:
   - **Base branch:** `main`
   - **Compare branch:** `develop`
4. Create the pull request
5. Review the changes
6. Merge the PR (this will trigger production deployment)

**What happens:**
- PR creates visibility and allows review
- CI runs on the PR to validate changes
- When merged, GitHub pushes to `main`
- This triggers production deployment

## Monitor the Deployment

After pushing/merging to `main`:

1. **Check GitHub Actions:**
   - Go to: https://github.com/andytholmes/hello_world_streamlit/actions
   - Find the latest workflow run
   - Watch for:
     - ✅ CI job to pass
     - ✅ "Deploy to Production" job to start and complete

2. **Verify Production App:**
   ```bash
   # Get production app URL
   az webapp show \
     --name <your-production-app-name> \
     --resource-group <your-resource-group> \
     --query defaultHostName -o tsv
   
   # Or open in browser
   az webapp browse \
     --name <your-production-app-name> \
     --resource-group <your-resource-group>
   ```

3. **Check Logs:**
   ```bash
   # Stream production logs
   az webapp log tail \
     --name <your-production-app-name> \
     --resource-group <your-resource-group>
   ```

## Rollback Procedure

If something goes wrong in Production:

### Option 1: Revert the Merge

```bash
# 1. Find the commit that merged develop into main
git log --oneline main | head -5

# 2. Revert the merge commit
git revert -m 1 <merge-commit-hash>

# 3. Push the revert
git push origin main
```

This will trigger a new deployment with the previous version.

### Option 2: Deploy Previous Version

```bash
# 1. Find the commit hash of the previous working version
git log --oneline main

# 2. Reset main to that commit (be careful!)
git checkout main
git reset --hard <previous-commit-hash>

# 3. Force push (only if necessary and safe)
# git push origin main --force
```

**⚠️ Warning:** Force pushing rewrites history. Only use if absolutely necessary.

### Option 3: Manual Azure Rollback

If you have deployment history in Azure:

```bash
# List deployment history
az webapp deployment list-publishing-profiles \
  --name <your-production-app-name> \
  --resource-group <your-resource-group>

# Restore a previous deployment (if available)
az webapp deployment source sync \
  --name <your-production-app-name> \
  --resource-group <your-resource-group>
```

## Best Practices

### Before Production Deployment

- [ ] UAT testing completed and signed off
- [ ] All tests passing in CI
- [ ] No critical bugs or issues
- [ ] Code review completed (if using PRs)
- [ ] Documentation updated (if needed)
- [ ] Team notified of deployment

### During Deployment

- [ ] Monitor GitHub Actions for deployment status
- [ ] Watch for any errors in the deployment logs
- [ ] Verify the production app starts correctly

### After Deployment

- [ ] Verify production app is accessible
- [ ] Test critical functionality
- [ ] Monitor application logs for errors
- [ ] Monitor application metrics (if configured)
- [ ] Notify stakeholders of successful deployment

## Troubleshooting

### Production Deployment Fails

**Check:**
1. GitHub Actions logs for specific errors
2. Azure App Service logs
3. Verify `AZURE_APP_SERVICE_PRODUCTION` secret is correct
4. Verify production App Service exists in Azure
5. Check service principal has permissions on production resources

### Production App Not Starting

**Check:**
1. Application logs: `az webapp log tail`
2. Startup command is correct
3. Environment variables are set correctly
4. Dependencies are in `requirements.txt`
5. Python version matches (3.10)

### Deployment Succeeds but App Doesn't Work

**Check:**
1. App Service configuration
2. Environment variables (`ENVIRONMENT=production`)
3. Application logs for runtime errors
4. Network/firewall settings

## Quick Reference

```bash
# Deploy to Production (direct method)
git checkout main
git merge develop
git push origin main

# Check deployment status
# https://github.com/andytholmes/hello_world_streamlit/actions

# Verify production app
az webapp browse \
  --name <production-app-name> \
  --resource-group <resource-group>
```

---

**Remember:** Production deployments should be done carefully and only after thorough testing in UAT!
