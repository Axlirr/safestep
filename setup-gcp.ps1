# SafeStep Google Cloud Setup Script (PowerShell)
# This script helps automate the initial Google Cloud setup on Windows

Write-Host "🚀 SafeStep Google Cloud Setup" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# Check if gcloud is installed
try {
    $gcloudVersion = gcloud --version 2>$null
    if (-not $gcloudVersion) {
        throw "gcloud not found"
    }
} catch {
    Write-Host "❌ Google Cloud CLI is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    exit 1
}

# Get project ID from user
$PROJECT_ID = Read-Host "Enter your Google Cloud Project ID (e.g., safestep-app-123)"

if ([string]::IsNullOrWhiteSpace($PROJECT_ID)) {
    Write-Host "❌ Project ID cannot be empty" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Setting up project: $PROJECT_ID" -ForegroundColor Blue

# Set the project
Write-Host "🔧 Setting active project..." -ForegroundColor Yellow
gcloud config set project $PROJECT_ID

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to set project. Make sure the project exists and you have access." -ForegroundColor Red
    exit 1
}

# Enable required APIs
Write-Host "🔌 Enabling required APIs..." -ForegroundColor Yellow
$apis = @(
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "containerregistry.googleapis.com"
)

foreach ($api in $apis) {
    Write-Host "   Enabling $api..." -ForegroundColor Gray
    gcloud services enable $api
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to enable $api" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ APIs enabled successfully!" -ForegroundColor Green

# Create service account for GitHub Actions
Write-Host "👤 Creating GitHub Actions service account..." -ForegroundColor Yellow
gcloud iam service-accounts create github-actions `
    --display-name="GitHub Actions Service Account" `
    --description="Service account for GitHub Actions CI/CD"

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Service account might already exist, continuing..." -ForegroundColor Yellow
}

# Grant necessary permissions
Write-Host "🔐 Granting permissions..." -ForegroundColor Yellow
$roles = @(
    "roles/cloudbuild.builds.editor",
    "roles/run.developer",
    "roles/storage.admin"
)

foreach ($role in $roles) {
    Write-Host "   Granting $role..." -ForegroundColor Gray
    gcloud projects add-iam-policy-binding $PROJECT_ID `
        --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" `
        --role="$role"
}

# Create service account key
Write-Host "🔑 Creating service account key..." -ForegroundColor Yellow
gcloud iam service-accounts keys create github-actions-key.json `
    --iam-account=github-actions@$PROJECT_ID.iam.gserviceaccount.com

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Service account setup complete!" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to create service account key" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Add the following secrets to your GitHub repository:" -ForegroundColor White
Write-Host "   - GCP_PROJECT_ID: $PROJECT_ID" -ForegroundColor Gray
Write-Host "   - GCP_SA_KEY: (contents of github-actions-key.json)" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Set up your secrets in Google Secret Manager:" -ForegroundColor White
Write-Host "   .\setup-secrets.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Push your code to trigger deployment!" -ForegroundColor White
Write-Host ""
Write-Host "🔒 IMPORTANT: Keep github-actions-key.json secure and don't commit it to git!" -ForegroundColor Red

Write-Host "🎉 Google Cloud setup complete!" -ForegroundColor Green