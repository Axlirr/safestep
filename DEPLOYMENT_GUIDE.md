# SafeStep Google Cloud Deployment Guide

This guide will help you deploy your SafeStep application to Google Cloud Platform while keeping Supabase as your database.

## Prerequisites

1. **Google Cloud Account** with billing enabled
2. **Google Cloud CLI** installed locally
3. **GitHub repository** with your SafeStep code
4. **Supabase project** (already configured)

## Step 1: Install Google Cloud CLI

### Windows
```powershell
# Download and install from: https://cloud.google.com/sdk/docs/install
# Or use PowerShell:
Invoke-WebRequest -Uri "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe" -OutFile "GoogleCloudSDKInstaller.exe"
.\GoogleCloudSDKInstaller.exe
```

### Verify Installation
```bash
gcloud --version
```

## Step 2: Set Up Google Cloud Project

### 2.1 Login and Create Project
```bash
# Login to Google Cloud
gcloud auth login

# Create new project (replace 'safestep-app-123' with your unique project ID)
gcloud projects create safestep-app-123 --name="SafeStep Application"

# Set as active project
gcloud config set project safestep-app-123

# Enable billing (required for Cloud Run)
# Go to: https://console.cloud.google.com/billing
```

### 2.2 Enable Required APIs
```bash
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

## Step 3: Store Secrets in Google Secret Manager

```bash
# Store your Supabase URL
echo -n "https://hduukqxhrebuifafooxv.supabase.co" | gcloud secrets create supabase-url --data-file=-

# Store your Supabase Key (replace with your actual key)
echo -n "your-actual-supabase-key" | gcloud secrets create supabase-key --data-file=-

# Store your Gemini API Key (replace with your actual key)
echo -n "your-actual-gemini-api-key" | gcloud secrets create gemini-api-key --data-file=-

# Store your Flask Secret Key (generate a secure random key)
echo -n "your-secure-flask-secret-key" | gcloud secrets create flask-secret-key --data-file=-

# Store your Database URL (your Supabase PostgreSQL URL)
echo -n "postgresql://postgres:your-password@db.hduukqxhrebuifafooxv.supabase.co:5432/postgres" | gcloud secrets create database-url --data-file=-
```

## Step 4: Set Up GitHub Repository Secrets

### 4.1 Create Service Account
```bash
# Create service account for GitHub Actions
gcloud iam service-accounts create github-actions \
    --display-name="GitHub Actions Service Account"

# Grant necessary permissions
gcloud projects add-iam-policy-binding safestep-app-123 \
    --member="serviceAccount:github-actions@safestep-app-123.iam.gserviceaccount.com" \
    --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding safestep-app-123 \
    --member="serviceAccount:github-actions@safestep-app-123.iam.gserviceaccount.com" \
    --role="roles/run.developer"

gcloud projects add-iam-policy-binding safestep-app-123 \
    --member="serviceAccount:github-actions@safestep-app-123.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Create and download service account key
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions@safestep-app-123.iam.gserviceaccount.com
```

### 4.2 Add Secrets to GitHub

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Add the following secrets:

   - **GCP_PROJECT_ID**: `safestep-app-123` (your project ID)
   - **GCP_SA_KEY**: Copy the entire contents of `github-actions-key.json`

## Step 5: Update Your Application for Production

### 5.1 Update .gitignore
Add these lines to your `.gitignore`:
```
# Environment files
.env
.env.local
.env.production
*.json

# Google Cloud
github-actions-key.json
```

### 5.2 Update app.py for Production
Add this to your `app.py` (if not already present):
```python
# Load production environment
if os.environ.get('FLASK_ENV') == 'production':
    load_dotenv('.env.production')
else:
    load_dotenv('.env')
```

## Step 6: Deploy Your Application

### 6.1 Manual Deployment (First Time)
```bash
# Navigate to your project directory
cd path/to/your/safestep/project

# Build and deploy manually
gcloud builds submit --config cloudbuild.yaml

# Check deployment status
gcloud run services list --region=us-central1

# Get your application URL
gcloud run services describe safestep-app --region=us-central1 --format="value(status.url)"
```

### 6.2 Automatic Deployment via GitHub
1. Push your code to the `main` branch
2. GitHub Actions will automatically build and deploy
3. Monitor progress in the **Actions** tab of your GitHub repository

## Step 7: Configure Custom Domain (Optional)

```bash
# Map custom domain (replace with your domain)
gcloud run domain-mappings create \
    --service safestep-app \
    --domain your-domain.com \
    --region us-central1

# Follow the DNS configuration instructions provided
```

## Step 8: Monitor Your Application

### View Logs
```bash
# View recent logs
gcloud run services logs read safestep-app --region=us-central1 --limit=50

# Follow logs in real-time
gcloud run services logs tail safestep-app --region=us-central1
```

### Monitor Performance
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to **Cloud Run** → **safestep-app**
3. Check the **Metrics** tab for performance data

## Step 9: Update Secrets (When Needed)

```bash
# Update a secret (example: Supabase key)
echo -n "new-supabase-key" | gcloud secrets versions add supabase-key --data-file=-

# The application will automatically use the latest version
```

## Step 10: Scale Your Application

```bash
# Update scaling settings
gcloud run services update safestep-app \
    --region=us-central1 \
    --min-instances=1 \
    --max-instances=20 \
    --cpu=2 \
    --memory=2Gi
```

## Troubleshooting

### Common Issues

1. **Build Fails**
   ```bash
   # Check build logs
   gcloud builds list --limit=5
   gcloud builds log [BUILD_ID]
   ```

2. **Service Won't Start**
   ```bash
   # Check service logs
   gcloud run services logs read safestep-app --region=us-central1
   ```

3. **Secrets Not Loading**
   ```bash
   # Verify secrets exist
   gcloud secrets list
   
   # Check secret access permissions
   gcloud secrets get-iam-policy [SECRET_NAME]
   ```

### Cost Optimization Tips

1. **Set minimum instances to 0** for development
2. **Use appropriate CPU and memory** settings
3. **Monitor usage** with billing alerts
4. **Use Supabase free tier** when possible

## Security Best Practices

1. ✅ **Never commit secrets** to your repository
2. ✅ **Use IAM roles** with minimal required permissions
3. ✅ **Regularly rotate** API keys and secrets
4. ✅ **Monitor access logs** for suspicious activity
5. ✅ **Keep dependencies updated** for security patches

## Support

If you encounter issues:
1. Check the [Google Cloud Run documentation](https://cloud.google.com/run/docs)
2. Review your application logs
3. Verify all secrets are properly configured
4. Ensure your Supabase project is accessible

---

**Your SafeStep application will be accessible at the Cloud Run URL provided after deployment!** 🚀