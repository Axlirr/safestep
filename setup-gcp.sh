#!/bin/bash

# SafeStep Google Cloud Setup Script
# This script helps automate the initial Google Cloud setup

set -e

echo "🚀 SafeStep Google Cloud Setup"
echo "================================"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud CLI is not installed. Please install it first:"
    echo "   https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Get project ID from user
read -p "Enter your Google Cloud Project ID (e.g., safestep-app-123): " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Project ID cannot be empty"
    exit 1
fi

echo "📋 Setting up project: $PROJECT_ID"

# Set the project
echo "🔧 Setting active project..."
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "🔌 Enabling required APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable containerregistry.googleapis.com

echo "✅ APIs enabled successfully!"

# Create service account for GitHub Actions
echo "👤 Creating GitHub Actions service account..."
gcloud iam service-accounts create github-actions \
    --display-name="GitHub Actions Service Account" \
    --description="Service account for GitHub Actions CI/CD"

# Grant necessary permissions
echo "🔐 Granting permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/run.developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Create service account key
echo "🔑 Creating service account key..."
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions@$PROJECT_ID.iam.gserviceaccount.com

echo "✅ Service account setup complete!"
echo ""
echo "📝 Next Steps:"
echo "1. Add the following secrets to your GitHub repository:"
echo "   - GCP_PROJECT_ID: $PROJECT_ID"
echo "   - GCP_SA_KEY: (contents of github-actions-key.json)"
echo ""
echo "2. Set up your secrets in Google Secret Manager:"
echo "   ./setup-secrets.sh"
echo ""
echo "3. Push your code to trigger deployment!"
echo ""
echo "🔒 IMPORTANT: Keep github-actions-key.json secure and don't commit it to git!"

echo "🎉 Google Cloud setup complete!"