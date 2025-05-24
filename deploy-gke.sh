#!/bin/bash

# Scalable LLM over Kubernetes Infrastructure - Google Cloud Deployment
# Optimized for GKE deployment with LLM models

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_ID="${GCP_PROJECT_ID:-}"
CLUSTER_NAME="${GKE_CLUSTER:-llm-chatbot-cluster}"
ZONE="${GKE_ZONE:-us-central1}"
REGION="${GKE_REGION:-us-central1}"
REGISTRY_URL="us-central1-docker.pkg.dev"
BACKEND_IMAGE="llm-chatbot-backend"
FRONTEND_IMAGE="llm-chatbot-frontend"

# Function to print colored output
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Validate prerequisites
validate_prerequisites() {
    print_status "Validating prerequisites..."
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    # Validate project ID
    if [ -z "$PROJECT_ID" ]; then
        print_error "GCP_PROJECT_ID environment variable is not set."
        echo "Please set it with: export GCP_PROJECT_ID=your-project-id"
        exit 1
    fi
    
    print_success "Prerequisites validated"
}

# Setup Google Cloud authentication and project
setup_gcloud() {
    print_status "Setting up Google Cloud authentication..."
    
    # Set project
    gcloud config set project "$PROJECT_ID"
    
    # Enable required APIs
    print_status "Enabling required Google Cloud APIs..."
    gcloud services enable container.googleapis.com
    gcloud services enable artifactregistry.googleapis.com
    gcloud services enable cloudbuild.googleapis.com
    
    print_success "Google Cloud setup complete"
}

# Connect to GKE cluster
connect_to_cluster() {
    print_status "Connecting to existing GKE cluster: $CLUSTER_NAME..."
    
    # Check if cluster exists (regional cluster)
    if gcloud container clusters describe "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID" &> /dev/null; then
        print_success "Found existing regional cluster"
        gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"
    # Check if cluster exists (zonal cluster)
    elif gcloud container clusters describe "$CLUSTER_NAME" --zone "$ZONE" --project "$PROJECT_ID" &> /dev/null; then
        print_success "Found existing zonal cluster"
        gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE" --project "$PROJECT_ID"
    else
        print_error "GKE cluster '$CLUSTER_NAME' not found in region '$REGION' or zone '$ZONE'."
        print_status "Creating GKE cluster optimized for CPU quota..."
        
        gcloud container clusters create "$CLUSTER_NAME" \
            --zone "$ZONE" \
            --machine-type "e2-small" \
            --num-nodes 2 \
            --disk-size 30GB \
            --enable-autoscaling \
            --min-nodes 1 \
            --max-nodes 3 \
            --enable-autorepair \
            --enable-autoupgrade \
            --addons HorizontalPodAutoscaling,HttpLoadBalancing \
            --project "$PROJECT_ID"
            
        print_success "GKE cluster created successfully"
        gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE" --project "$PROJECT_ID"
    fi
    
    print_success "Connected to GKE cluster"
}

# Create Artifact Registry repository
setup_artifact_registry() {
    print_status "Setting up Artifact Registry..."
    
    REPO_NAME="llm-chatbot-repo"
    
    if ! gcloud artifacts repositories describe "$REPO_NAME" --location="$REGION" --project="$PROJECT_ID" &> /dev/null; then
        print_status "Creating Artifact Registry repository..."
        gcloud artifacts repositories create "$REPO_NAME" \
            --repository-format=docker \
            --location="$REGION" \
            --description="LLM Chatbot container images" \
            --project="$PROJECT_ID"
        print_success "Artifact Registry repository created"
    else
        print_success "Artifact Registry repository already exists"
    fi
    
    # Configure Docker to use gcloud as credential helper
    gcloud auth configure-docker "$REGISTRY_URL"
}

# Build and push container images
build_and_push_images() {
    print_status "Building and pushing container images..."
    
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    
    # Build custom Ollama image with TinyLlama pre-loaded
    print_status "Building custom Ollama image with TinyLlama..."
    docker build \
        -f ollama-tinyllama.Dockerfile \
        --tag "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/ollama-tinyllama:$TIMESTAMP" \
        --tag "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/ollama-tinyllama:latest" \
        .
    
    # Build backend image
    print_status "Building backend image..."
    docker build \
        --tag "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$BACKEND_IMAGE:$TIMESTAMP" \
        --tag "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$BACKEND_IMAGE:latest" \
        .
    
    # Build frontend image
    print_status "Building frontend image..."
    docker build \
        --tag "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$FRONTEND_IMAGE:$TIMESTAMP" \
        --tag "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$FRONTEND_IMAGE:latest" \
        frontend/
    
    # Push Ollama image with TinyLlama
    print_status "Pushing custom Ollama image..."
    docker push "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/ollama-tinyllama:$TIMESTAMP"
    docker push "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/ollama-tinyllama:latest"
    
    # Push backend image
    print_status "Pushing backend image..."
    docker push "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$BACKEND_IMAGE:$TIMESTAMP"
    docker push "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$BACKEND_IMAGE:latest"
    
    # Push frontend image
    print_status "Pushing frontend image..."
    docker push "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$FRONTEND_IMAGE:$TIMESTAMP"
    docker push "$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$FRONTEND_IMAGE:latest"
    
    print_success "Container images built and pushed successfully"
}

# Deploy to Kubernetes
deploy_to_kubernetes() {
    print_status "Deploying to Kubernetes..."
    
    # Apply RBAC
    kubectl apply -f k8s/rbac.yaml
    
    # Apply cloud configurations
    kubectl apply -f k8s/configmap-cloud.yaml
    
    # Create secrets if they don't exist
    kubectl create secret generic llm-chatbot-secrets \
        --from-literal=placeholder="none" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Update deployment files with correct image references
    sed "s|gcr.io/PROJECT_ID/llm-chatbot-backend:latest|$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$BACKEND_IMAGE:latest|g" \
        k8s/backend-deployment-cloud.yaml > /tmp/backend-deployment.yaml
    
    sed "s|gcr.io/scalable-llm-chatbot/llm-chatbot-frontend:latest|$REGISTRY_URL/$PROJECT_ID/llm-chatbot-repo/$FRONTEND_IMAGE:latest|g" \
        k8s/frontend-deployment-cloud.yaml > /tmp/frontend-deployment.yaml
    
    # Apply deployments
    kubectl apply -f /tmp/backend-deployment.yaml
    kubectl apply -f /tmp/frontend-deployment.yaml
    
    # Apply services
    kubectl apply -f k8s/backend-service-cloud.yaml
    
    # Apply HPA for auto-scaling
    kubectl apply -f k8s/hpa-cloud.yaml
    kubectl apply -f k8s/frontend-hpa-cloud.yaml
    
    print_success "Kubernetes deployment complete"
}

# Wait for deployments and show status
wait_and_show_status() {
    print_status "Waiting for deployments to be ready..."
    
    # Wait for backend deployment (faster with pre-loaded model)
    kubectl rollout status deployment/llm-chatbot-backend --timeout=300s || {
        print_error "Backend deployment failed or timed out"
        kubectl describe deployment llm-chatbot-backend
        kubectl logs -l app=llm-chatbot,component=backend --tail=50
        exit 1
    }
    
    # Wait for frontend deployment
    kubectl rollout status deployment/llm-chatbot-frontend --timeout=300s || {
        print_error "Frontend deployment failed or timed out"
        kubectl describe deployment llm-chatbot-frontend
        exit 1
    }
    
    print_success "All deployments are ready!"
    
    # Show deployment status
    echo ""
    print_status "=== Deployment Status ==="
    kubectl get pods,services,hpa -l app=llm-chatbot
    
    echo ""
    print_status "=== Frontend Service ==="
    kubectl get service llm-chatbot-frontend-service
    
    echo ""
    print_status "=== Backend Service ==="
    kubectl get service llm-chatbot-backend-service
    
    # Get external IP
    echo ""
    print_status "Getting external IP address..."
    EXTERNAL_IP=""
    while [ -z $EXTERNAL_IP ]; do
        EXTERNAL_IP=$(kubectl get svc llm-chatbot-frontend-service --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
        if [ -z "$EXTERNAL_IP" ]; then
            print_status "Waiting for external IP... (this may take a few minutes)"
            sleep 30
        fi
    done
    
    echo ""
    print_success "=== 🎉 DEPLOYMENT SUCCESSFUL! 🎉 ==="
    print_success "Your LLM chatbot is now available at: http://$EXTERNAL_IP"
    print_success "Backend API documentation: http://$EXTERNAL_IP/api/docs"
    print_success "Health check: http://$EXTERNAL_IP/api/health"
    echo ""
    print_success "🤖 Model: TinyLlama (pre-loaded for instant availability)"
    print_status "✅ No model download required - ready to chat immediately!"
    echo ""
    print_status "You can monitor the system with:"
    echo "kubectl logs -f deployment/llm-chatbot-backend -c ollama"
    echo "kubectl logs -f deployment/llm-chatbot-backend -c backend"
}

# Main execution
main() {
    echo "🚀 Scalable LLM over Kubernetes Infrastructure - Google Cloud Deployment"
    echo "========================================================================"
    
    validate_prerequisites
    setup_gcloud
    connect_to_cluster
    setup_artifact_registry
    build_and_push_images
    deploy_to_kubernetes
    wait_and_show_status
    
    echo ""
    print_success "🎯 Deployment completed successfully!"
    print_status "Your scalable LLM infrastructure is now running on Google Cloud!"
}

# Run main function
main "$@" 