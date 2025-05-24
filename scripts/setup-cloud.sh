#!/bin/bash

# Scalable LLM Chatbot - Google Cloud Setup Script
# This script helps set up Google Cloud and GitHub for deployment

set -e

echo "🚀 Setting up Google Cloud for LLM Chatbot deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
PROJECT_ID=""
CLUSTER_NAME="llm-chatbot-cluster"
ZONE="us-central1-a"
REGION="us-central1"

# Prompt for project ID if not set
if [ -z "$PROJECT_ID" ]; then
    echo "Please enter your Google Cloud Project ID:"
    read -r PROJECT_ID
fi

if [ -z "$PROJECT_ID" ]; then
    print_error "Project ID is required. Exiting."
    exit 1
fi

print_status "Using Project ID: $PROJECT_ID"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed. Please install it first:"
    echo "https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Login to gcloud
print_status "Authenticating with Google Cloud..."
gcloud auth login

# Set project
print_status "Setting project to $PROJECT_ID..."
gcloud config set project $PROJECT_ID

# Enable required APIs
print_status "Enabling required Google Cloud APIs..."
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# Create GKE cluster if it doesn't exist
print_status "Checking if GKE cluster exists..."
if ! gcloud container clusters describe $CLUSTER_NAME --zone $ZONE &> /dev/null; then
    print_status "Creating GKE cluster: $CLUSTER_NAME..."
    gcloud container clusters create $CLUSTER_NAME \
        --zone $ZONE \
        --machine-type e2-small \
        --num-nodes 2 \
        --disk-size 20GB \
        --enable-autoscaling \
        --min-nodes 1 \
        --max-nodes 3 \
        --enable-autorepair \
        --enable-autoupgrade \
        --preemptible
    print_success "GKE cluster created successfully"
else
    print_success "GKE cluster already exists"
fi

# Get cluster credentials
print_status "Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE

# Create service account for GitHub Actions
print_status "Creating service account for GitHub Actions..."
SA_NAME="github-actions-sa"
SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

if ! gcloud iam service-accounts describe $SA_EMAIL &> /dev/null; then
    gcloud iam service-accounts create $SA_NAME \
        --display-name "GitHub Actions Service Account"
    print_success "Service account created"
else
    print_success "Service account already exists"
fi

# Grant necessary roles
print_status "Granting roles to service account..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/container.developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/storage.admin"

# Create and download service account key
print_status "Creating service account key..."
KEY_FILE="$HOME/gcp-sa-key.json"
gcloud iam service-accounts keys create $KEY_FILE \
    --iam-account $SA_EMAIL

print_success "Service account key created at: $KEY_FILE"

# Test cluster access
print_status "Testing cluster access..."
kubectl get nodes

print_success "=== Setup Complete ==="
echo ""
print_status "Next steps:"
echo "1. Add the following secrets to your GitHub repository:"
echo "   - GCP_PROJECT_ID: $PROJECT_ID"
echo "   - GCP_SA_KEY: (content of $KEY_FILE)"
echo "   - HF_API_TOKEN: (optional, get from https://huggingface.co/settings/tokens)"
echo ""
echo "2. Update your repository secrets at:"
echo "   https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions"
echo ""
echo "3. Push to main branch to trigger deployment"
echo ""
print_warning "Security Note: Please delete the service account key file after adding it to GitHub:"
echo "rm $KEY_FILE"
echo ""
print_status "Cluster endpoint: $(gcloud container clusters describe $CLUSTER_NAME --zone $ZONE --format='value(endpoint)')"
print_status "Cluster location: $ZONE" 