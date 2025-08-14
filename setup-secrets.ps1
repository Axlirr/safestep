# SafeStep Secrets Setup Script (PowerShell)
# This script helps you set up secrets in Google Secret Manager on Windows

Write-Host "🔐 SafeStep Secrets Setup" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green

# Check if gcloud is installed and authenticated
try {
    $gcloudVersion = gcloud --version 2>$null
    if (-not $gcloudVersion) {
        throw "gcloud not found"
    }
} catch {
    Write-Host "❌ Google Cloud CLI is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check if user is authenticated
try {
    $activeAccount = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
    if ([string]::IsNullOrWhiteSpace($activeAccount)) {
        throw "Not authenticated"
    }
} catch {
    Write-Host "❌ You are not authenticated with Google Cloud. Please run 'gcloud auth login' first." -ForegroundColor Red
    exit 1
}

Write-Host "📋 This script will help you set up secrets for your SafeStep application." -ForegroundColor Blue
Write-Host "⚠️  Make sure you have your credentials ready!" -ForegroundColor Yellow
Write-Host ""

# Get current project
$PROJECT_ID = gcloud config get-value project 2>$null
Write-Host "🏗️  Current project: $PROJECT_ID" -ForegroundColor Blue
Write-Host ""

# Function to create secret
function Create-Secret {
    param(
        [string]$SecretName,
        [string]$SecretDescription
    )
    
    Write-Host "🔑 Setting up: $SecretName" -ForegroundColor Yellow
    Write-Host "   Description: $SecretDescription" -ForegroundColor Gray
    
    $SecretValue = Read-Host "   Enter value" -AsSecureString
    $PlainTextValue = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecretValue))
    
    if ([string]::IsNullOrWhiteSpace($PlainTextValue)) {
        Write-Host "   ⚠️  Skipping empty value for $SecretName" -ForegroundColor Yellow
        return
    }
    
    # Check if secret exists
    $secretExists = $false
    try {
        gcloud secrets describe $SecretName 2>$null | Out-Null
        $secretExists = ($LASTEXITCODE -eq 0)
    } catch {
        $secretExists = $false
    }
    
    if ($secretExists) {
        Write-Host "   📝 Updating existing secret..." -ForegroundColor Gray
        $PlainTextValue | gcloud secrets versions add $SecretName --data-file=-
    } else {
        Write-Host "   ✨ Creating new secret..." -ForegroundColor Gray
        $PlainTextValue | gcloud secrets create $SecretName --data-file=-
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ $SecretName configured successfully!" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Failed to configure $SecretName" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Set up all required secrets
Write-Host "🚀 Setting up SafeStep secrets..." -ForegroundColor Green
Write-Host ""

Create-Secret "supabase-url" "Supabase project URL (e.g., https://xxx.supabase.co)"
Create-Secret "supabase-key" "Supabase anon/public key"
Create-Secret "database-url" "PostgreSQL database URL from Supabase"
Create-Secret "gemini-api-key" "Google Gemini API key for AI features"
Create-Secret "flask-secret-key" "Flask secret key for sessions (generate a random string)"

Write-Host "🎉 All secrets have been configured!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Summary of created secrets:" -ForegroundColor Blue
try {
    gcloud secrets list --filter="name~(supabase|database|gemini|flask)" --format="table(name,createTime)"
} catch {
    Write-Host "   Unable to list secrets, but they should be created." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "✅ Your SafeStep application is now ready for deployment!" -ForegroundColor Green
Write-Host "🚀 Push your code to GitHub to trigger automatic deployment." -ForegroundColor Cyan
Write-Host ""
Write-Host "📖 For more information, see DEPLOYMENT_GUIDE.md" -ForegroundColor Blue