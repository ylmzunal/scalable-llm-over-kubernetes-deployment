# Scalable LLM over Kubernetes Infrastructure - Google Cloud Deployment

Deployment Link : http://askllm.net/

## 🚀 Production-Ready LLM Chatbot on Google Cloud

This repository contains a **production-ready, scalable LLM chatbot** infrastructure designed specifically for Google Cloud deployment. The system features a complete frontend and backend deployment to Google Kubernetes Engine (GKE) with locally downloaded LLM models accessible through a public web interface.

## 🏗️ Architecture Overview

- **Frontend**: React + Material-UI served by nginx (publicly accessible via LoadBalancer)
- **Backend**: FastAPI + Ollama with TinyLlama model (internal service with auto-scaling)
- **Models**: TinyLlama (1.1B parameters) pre-loaded in Docker image
- **Infrastructure**: Google Kubernetes Engine with horizontal pod autoscaling
- **Registry**: Google Artifact Registry for container images
- **Access**: Public internet access via GKE LoadBalancer with optional SSL

## 📋 Prerequisites

- **Google Cloud Account** with billing enabled
- **Docker Desktop** installed and running
- **gcloud CLI** installed and configured
- **kubectl** installed
- **Git** for repository management

## 🚀 Quick Deployment

### 1. Initial Setup

```bash
# Clone this repository
git clone <your-repo-url>
cd scalable-llm-over-kubernetes-deployment

# Run the quick setup script
./quick-setup.sh
```

The setup script will:
- Authenticate with Google Cloud
- Set up your project
- Enable required APIs
- Configure Docker for Artifact Registry

### 2. Deploy to Google Cloud

```bash
# Set your project ID (if not already set by quick-setup.sh)
export GCP_PROJECT_ID=your-project-id

# Deploy the complete infrastructure
./deploy-gke.sh
```

The deployment script will:
- Create GKE cluster (if needed)
- Build custom Ollama image with TinyLlama pre-loaded
- Build and push container images
- Deploy backend with instant LLM availability
- Deploy frontend with public access
- Set up auto-scaling

### 3. Access Your Chatbot

After deployment completes, you'll see:
```
🎉 DEPLOYMENT SUCCESSFUL! 🎉
Your LLM chatbot is now available at: http://EXTERNAL-IP
Backend API documentation: http://EXTERNAL-IP/api/docs
Health check: http://EXTERNAL-IP/api/health
```

## 📁 Project Structure

```
├── app/                    # FastAPI backend application
├── frontend/              # React frontend application
├── k8s/                   # Kubernetes manifests (cloud-optimized)
├── scripts/               # Deployment and utility scripts
├── deploy-gke.sh          # Main deployment script
├── quick-setup.sh         # Initial setup script
└── README.md              # This file
```

## 🔑 Key Features

- **Instant LLM Availability**: TinyLlama model pre-loaded in Docker image (no download time)
- **Scalable Backend**: Auto-scaling based on CPU/memory usage with HPA
- **Lightweight Model**: TinyLlama (1.1B parameters) optimized for fast inference
- **WebSocket Support**: Real-time chat interface with persistent connections
- **Health Monitoring**: Comprehensive Kubernetes health checks and monitoring
- **Resource Optimization**: Efficient resource allocation for cost-effective operation
- **Production Ready**: Proper security contexts, resource limits, and graceful shutdowns
- **Fast Deployment**: No runtime model downloads - ready to chat immediately

## 📊 Resource Requirements

| Component | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-----------|-------------|----------------|-----------|--------------|
| **Backend (FastAPI)** | 200m | 256Mi | 500m | 512Mi |
| **Ollama (TinyLlama)** | 500m | 1Gi | 1000m | 2Gi |
| **Frontend** | 50m | 64Mi | 100m | 128Mi |

**Estimated Monthly Cost**: ~$75-100 USD (reduced due to TinyLlama efficiency)

## 🔧 Configuration

### Environment Variables

The deployment uses these key environment variables:

- `GCP_PROJECT_ID`: Your Google Cloud Project ID
- `GKE_CLUSTER`: Cluster name (default: llm-chatbot-cluster)
- `GKE_ZONE`: Deployment zone (default: us-central1-a)
- `GKE_REGION`: Deployment region (default: us-central1)

### LLM Models

The system uses TinyLlama (1.1B parameters):
- **Lightweight**: Only 1.1B parameters for fast inference
- **Pre-loaded**: Embedded in Docker image during build
- **Instant availability**: No download time required
- **Cost-effective**: Reduced compute requirements
- **Production ready**: Optimized for cloud deployment

The model is automatically available upon pod startup - no initialization time required.

## 🔍 Monitoring & Troubleshooting

### Check Deployment Status
```bash
kubectl get pods,services,hpa -l app=llm-chatbot
```

### Monitor TinyLlama Model
```bash
kubectl logs -f deployment/llm-chatbot-backend -c ollama
```

### Check Backend Logs
```bash
kubectl logs -f deployment/llm-chatbot-backend -c backend
```

### Test TinyLlama Model
```bash
kubectl exec -it deployment/llm-chatbot-backend -c ollama -- ollama list
kubectl exec -it deployment/llm-chatbot-backend -c ollama -- ollama run tinyllama "Hello, how are you?"
```

### Scale Manually
```bash
kubectl scale deployment llm-chatbot-backend --replicas=2
```

## 🛡️ Security Features

- **RBAC**: Proper Kubernetes role-based access control
- **Security Contexts**: Non-root containers where possible
- **Resource Limits**: Prevents resource exhaustion
- **Health Checks**: Comprehensive liveness and readiness probes
- **Network Policies**: Secure internal communication

## 🌐 Production Considerations

### SSL/TLS Setup
The deployment includes optional SSL certificate management via Google Managed Certificates. Update the domain in `k8s/frontend-deployment-cloud.yaml`.

### Scaling
- **Frontend**: Auto-scales 2-10 replicas based on CPU
- **Backend**: Starts with 1 replica, can be manually scaled
- **Cluster**: Auto-scales nodes 1-4 based on resource demands

### Cost Optimization
- Uses preemptible nodes where possible
- Efficient resource requests and limits
- Automatic scaling down during low usage

## 📞 Support

For issues or questions:
1. Check the deployment logs
2. Verify your Google Cloud quotas
3. Ensure all prerequisites are met
4. Review the troubleshooting section

## 📝 License

This project is created for educational and production use. Please ensure compliance with your organization's policies and Google Cloud terms of service. 
