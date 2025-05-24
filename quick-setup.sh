#!/bin/bash

# Quick Setup for Scalable LLM over Kubernetes Infrastructure
# This script prepares your environment for Google Cloud deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🚀 Quick Setup for Scalable LLM over Kubernetes Infrastructure"
echo "============================================================="

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed."
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    echo "Then run this script again."
    exit 1
fi

# Authenticate with Google Cloud
print_status "Authenticating with Google Cloud..."
gcloud auth login

# List available projects
print_status "Available Google Cloud projects:"
gcloud projects list --format="table(projectId,name,projectNumber)"

echo ""
print_status "Please enter your Google Cloud Project ID:"
read -r PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    print_error "Project ID cannot be empty"
    exit 1
fi

# Verify project exists
if ! gcloud projects describe "$PROJECT_ID" &> /dev/null; then
    print_error "Project '$PROJECT_ID' not found or you don't have access"
    exit 1
fi

# Set default project
gcloud config set project "$PROJECT_ID"
print_success "Project set to: $PROJECT_ID"

# Export environment variable
export GCP_PROJECT_ID="$PROJECT_ID"
echo "export GCP_PROJECT_ID=\"$PROJECT_ID\"" >> ~/.bashrc
echo "export GCP_PROJECT_ID=\"$PROJECT_ID\"" >> ~/.zshrc

# Enable required APIs
print_status "Enabling required Google Cloud APIs..."
gcloud services enable container.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable compute.googleapis.com

print_success "APIs enabled successfully"

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_warning "Docker is not running. Please start Docker Desktop and run this script again."
    exit 1
fi

print_success "Docker is running"

# Configure Docker for Artifact Registry
print_status "Configuring Docker for Artifact Registry..."
gcloud auth configure-docker us-central1-docker.pkg.dev

print_success "✅ Setup completed successfully!"
echo ""
print_status "Environment configured:"
echo "  - Google Cloud Project: $PROJECT_ID"
echo "  - GCP_PROJECT_ID environment variable set"
echo "  - Required APIs enabled"
echo "  - Docker configured for Artifact Registry"
echo ""
print_status "Next steps:"
echo "  1. Run the deployment script: ./deploy-gke.sh"
echo "  2. Or if you want to create the cluster manually first:"
echo "     gcloud container clusters create llm-chatbot-cluster --zone us-central1-a --machine-type e2-standard-4 --num-nodes 2"
echo ""
print_warning "Note: Make sure you're in the project directory when running deployment scripts." 