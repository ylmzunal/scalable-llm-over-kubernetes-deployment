#!/bin/bash

# Deploy LLM Chatbot to Existing GKE Cluster
# Project: scalable-llm-chatbot
# Cluster: llm-chatbot-cluster (us-central1-a)

set -e

echo "🚀 Deploying LLM Chatbot to existing GKE cluster..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

PROJECT_ID="scalable-llm-chatbot"
CLUSTER_NAME="llm-chatbot-cluster"
ZONE="us-central1-a"
IMAGE_NAME="llm-chatbot-backend"

# Ensure we're connected to the right cluster
print_status "Connecting to cluster..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE

# Configure Docker for GCR
print_status "Configuring Docker for Google Container Registry..."
gcloud auth configure-docker

# Build and push the Docker image
print_status "Building Docker image..."
docker build -t gcr.io/$PROJECT_ID/$IMAGE_NAME:latest .

print_status "Pushing image to Google Container Registry..."
docker push gcr.io/$PROJECT_ID/$IMAGE_NAME:latest

# Update the cloud deployment file with correct project ID
print_status "Updating deployment configuration..."
sed "s/PROJECT_ID/$PROJECT_ID/g" k8s/backend-deployment-cloud.yaml > /tmp/backend-deployment-cloud.yaml

# Apply Kubernetes resources
print_status "Applying Kubernetes resources..."

# Apply basic resources
kubectl apply -f k8s/rbac.yaml

# Apply cloud-specific configurations
kubectl apply -f k8s/configmap-cloud.yaml

# Create secrets (will be empty for now, can be updated later)
kubectl create secret generic llm-chatbot-secrets \
    --from-literal=hf_api_token="" \
    --dry-run=client -o yaml | kubectl apply -f -

# Apply deployment and services
kubectl apply -f /tmp/backend-deployment-cloud.yaml
kubectl apply -f k8s/backend-service-cloud.yaml
kubectl apply -f k8s/hpa-cloud.yaml

# Wait for deployment
print_status "Waiting for deployment to be ready..."
kubectl rollout status deployment/llm-chatbot-backend --timeout=300s

# Get cluster info
print_status "Getting cluster information..."
kubectl get pods,services,hpa -l app=llm-chatbot

# Get external IP (may take a few minutes)
print_status "Getting external IP address..."
echo "External IP assignment may take 2-5 minutes..."
kubectl get service llm-chatbot-backend-service

print_success "=== Deployment Complete! ==="
echo ""
print_status "Next steps:"
echo "1. Wait for external IP to be assigned"
echo "2. Configure GitHub secrets for automated deployment"
echo "3. Test the deployment"
echo ""
print_status "To check external IP: kubectl get service llm-chatbot-backend-service"
print_status "To view logs: kubectl logs -f -l app=llm-chatbot"
echo ""

# Check if external IP is assigned
external_ip=$(kubectl get service llm-chatbot-backend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -n "$external_ip" ] && [ "$external_ip" != "null" ]; then
    print_success "🌟 Your LLM Chatbot is accessible at: http://$external_ip"
    print_status "API Documentation: http://$external_ip/docs"
    print_status "Health Check: http://$external_ip/health"
else
    print_warning "External IP is being assigned. Check status with:"
    echo "kubectl get service llm-chatbot-backend-service -w"
fi 