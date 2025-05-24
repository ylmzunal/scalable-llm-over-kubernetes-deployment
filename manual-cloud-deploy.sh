#!/bin/bash

# Manual Cloud Deployment Script
# Use this to deploy directly to GKE without GitHub Actions

set -e

echo "🚀 Manual Cloud Deployment for LLM Chatbot"
echo "=========================================="

# Configuration
PROJECT_ID="${GCP_PROJECT_ID:-your-project-id}"
GKE_CLUSTER="llm-chatbot-cluster"
GKE_ZONE="us-central1-a"
BACKEND_IMAGE="llm-chatbot-backend"
FRONTEND_IMAGE="llm-chatbot-frontend"
REGISTRY_URL="us-central1-docker.pkg.dev"

# Validate configuration
if [ "$PROJECT_ID" = "your-project-id" ]; then
    echo "❌ Please set GCP_PROJECT_ID environment variable"
    echo "   export GCP_PROJECT_ID=your-actual-project-id"
    exit 1
fi

# Connect to GKE cluster
echo "🔗 Connecting to GKE cluster..."
gcloud container clusters get-credentials "$GKE_CLUSTER" --zone "$GKE_ZONE" --project "$PROJECT_ID"

# Build and push backend image
echo "🏗️  Building backend Docker image..."
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
docker build \
  --tag "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$BACKEND_IMAGE:manual-$TIMESTAMP" \
  --tag "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$BACKEND_IMAGE:latest" \
  .

echo "📤 Pushing backend image to Artifact Registry..."
docker push "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$BACKEND_IMAGE:manual-$TIMESTAMP"
docker push "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$BACKEND_IMAGE:latest"

# Build and push frontend image
echo "🏗️  Building frontend Docker image..."
docker build \
  --tag "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$FRONTEND_IMAGE:manual-$TIMESTAMP" \
  --tag "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$FRONTEND_IMAGE:latest" \
  frontend/

echo "📤 Pushing frontend image to Artifact Registry..."
docker push "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$FRONTEND_IMAGE:manual-$TIMESTAMP"
docker push "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$FRONTEND_IMAGE:latest"

# Deploy to Kubernetes
echo "🚀 Deploying to Kubernetes..."

# Apply basic resources
kubectl apply -f k8s/rbac.yaml

# Apply cloud configurations
kubectl apply -f k8s/configmap-cloud.yaml

# Create secrets if they don't exist
kubectl create secret generic llm-chatbot-secrets \
  --from-literal=placeholder="none" \
  --dry-run=client -o yaml | kubectl apply -f -

# Update backend deployment with correct image
sed "s|gcr.io/PROJECT_ID/llm-chatbot-backend:latest|$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$BACKEND_IMAGE:latest|g" \
  k8s/backend-deployment-cloud-simple.yaml > /tmp/backend-deployment.yaml
kubectl apply -f /tmp/backend-deployment.yaml

# Update frontend deployment with correct image
sed "s|gcr.io/PROJECT_ID/llm-chatbot-frontend:latest|$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$FRONTEND_IMAGE:latest|g" \
  k8s/frontend-deployment-cloud.yaml > /tmp/frontend-deployment.yaml
kubectl apply -f /tmp/frontend-deployment.yaml

# Apply services and scaling
kubectl apply -f k8s/backend-service-cloud.yaml
kubectl apply -f k8s/hpa-cloud.yaml
kubectl apply -f k8s/frontend-hpa-cloud.yaml

# Wait for deployments
echo "⏳ Waiting for deployments to be ready..."
kubectl rollout status deployment/llm-chatbot-backend --timeout=300s
kubectl rollout status deployment/llm-chatbot-frontend --timeout=300s

# Show deployment status
echo "✅ Deployment completed!"
echo ""
echo "📊 Current status:"
kubectl get pods,services,hpa -l app=llm-chatbot

echo ""
echo "🌐 Frontend Service:"
kubectl get service llm-chatbot-frontend-service

echo ""
echo "🎉 Your live demo should be accessible at the EXTERNAL-IP shown above!"
echo "💡 If EXTERNAL-IP shows <pending>, wait a few minutes for Google Cloud to assign an IP" 