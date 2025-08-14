#!/bin/bash

# SafeStep Secrets Setup Script
# This script helps you set up secrets in Google Secret Manager

set -e

echo "🔐 SafeStep Secrets Setup"
echo "========================"

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud CLI is not installed. Please install it first."
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ You are not authenticated with Google Cloud. Please run 'gcloud auth login' first."
    exit 1
fi

echo "📋 This script will help you set up secrets for your SafeStep application."
echo "⚠️  Make sure you have your credentials ready!"
echo ""

# Get current project
PROJECT_ID=$(gcloud config get-value project)
echo "🏗️  Current project: $PROJECT_ID"
echo ""

# Function to create secret
create_secret() {
    local secret_name=$1
    local secret_description=$2
    local secret_value
    
    echo "🔑 Setting up: $secret_name"
    echo "   Description: $secret_description"
    read -s -p "   Enter value: " secret_value
    echo ""
    
    if [ -z "$secret_value" ]; then
        echo "   ⚠️  Skipping empty value for $secret_name"
        return
    fi
    
    # Create or update secret
    if gcloud secrets describe $secret_name &>/dev/null; then
        echo "   📝 Updating existing secret..."
        echo -n "$secret_value" | gcloud secrets versions add $secret_name --data-file=-
    else
        echo "   ✨ Creating new secret..."
        echo -n "$secret_value" | gcloud secrets create $secret_name --data-file=-
    fi
    
    echo "   ✅ $secret_name configured successfully!"
    echo ""
}

# Set up all required secrets
echo "🚀 Setting up SafeStep secrets..."
echo ""

create_secret "supabase-url" "Supabase project URL (e.g., https://xxx.supabase.co)"
create_secret "supabase-key" "Supabase anon/public key"
create_secret "database-url" "PostgreSQL database URL from Supabase"
create_secret "gemini-api-key" "Google Gemini API key for AI features"
create_secret "flask-secret-key" "Flask secret key for sessions (generate a random string)"

echo "🎉 All secrets have been configured!"
echo ""
echo "📋 Summary of created secrets:"
gcloud secrets list --filter="name~(supabase|database|gemini|flask)" --format="table(name,createTime)"
echo ""
echo "✅ Your SafeStep application is now ready for deployment!"
echo "🚀 Push your code to GitHub to trigger automatic deployment."
echo ""
echo "📖 For more information, see DEPLOYMENT_GUIDE.md"