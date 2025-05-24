# 🚀 Google Cloud Deployment Guide

## Scalable LLM over Kubernetes Infrastructure

This guide provides step-by-step instructions for deploying your LLM chatbot infrastructure to Google Cloud.

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Google Cloud Account** with billing enabled
- [ ] **Docker Desktop** installed and running
- [ ] **gcloud CLI** installed ([Installation Guide](https://cloud.google.com/sdk/docs/install))
- [ ] **kubectl** installed ([Installation Guide](https://kubernetes.io/docs/tasks/tools/))
- [ ] **Git** for repository management
- [ ] **Project permissions** to create resources in Google Cloud

## 🎯 Step-by-Step Deployment

### Step 1: Initial Setup

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd scalable-llm-over-kubernetes-deployment
   ```

2. **Run the quick setup script**
   ```bash
   ./quick-setup.sh
   ```
   
   This script will:
   - Authenticate with Google Cloud
   - List your available projects
   - Set up your project
   - Enable required APIs
   - Configure Docker for Artifact Registry

3. **Verify setup**
   ```bash
   echo $GCP_PROJECT_ID  # Should show your project ID
   gcloud config get-value project  # Should match your project
   ```

### Step 2: Deploy Infrastructure

1. **Run the deployment script**
   ```bash
   ./deploy-gke.sh
   ```

2. **Monitor the deployment**
   The script will show progress for:
   - Creating GKE cluster (if needed)
   - Building container images
   - Pushing to Artifact Registry
   - Deploying to Kubernetes
   - Setting up auto-scaling

3. **Wait for completion**
   The deployment typically takes 8-12 minutes, including:
   - Cluster creation: 5-8 minutes
   - Image building: 3-5 minutes (including TinyLlama embedding)
   - Pod startup: 30-60 seconds (instant model availability)

### Step 3: Verify Deployment

1. **Check deployment status**
   ```bash
   kubectl get pods,services,hpa -l app=llm-chatbot
   ```

2. **Monitor TinyLlama availability**
   ```bash
   kubectl logs -f deployment/llm-chatbot-backend -c ollama
   ```

3. **Check backend health**
   ```bash
   kubectl logs -f deployment/llm-chatbot-backend -c backend
   ```

4. **Test TinyLlama model**
   ```bash
   kubectl exec -it deployment/llm-chatbot-backend -c ollama -- ollama list
   kubectl exec -it deployment/llm-chatbot-backend -c ollama -- ollama run tinyllama "Hello!"
   ```

5. **TinyLlama not responding**
   ```bash
   kubectl logs deployment/llm-chatbot-backend -c ollama
   kubectl exec -it deployment/llm-chatbot-backend -c ollama -- ollama list
   kubectl exec -it deployment/llm-chatbot-backend -c ollama -- ollama run tinyllama "test"
   ```

### Step 4: Access Your Application

1. **Get the external IP**
   ```bash
   kubectl get service llm-chatbot-frontend-service
   ```

2. **Access your chatbot**
   - **Frontend**: `http://EXTERNAL-IP`
   - **API Docs**: `http://EXTERNAL-IP/api/docs`
   - **Health Check**: `http://EXTERNAL-IP/api/health`

## 🔧 Configuration Options

### Environment Variables

You can customize the deployment by setting these environment variables:

```bash
export GCP_PROJECT_ID=your-project-id
export GKE_CLUSTER=llm-chatbot-cluster
export GKE_ZONE=us-central1-a
export GKE_REGION=us-central1
```

### Resource Scaling

**Manual scaling:**
```bash
# Scale backend
kubectl scale deployment llm-chatbot-backend --replicas=2

# Scale frontend
kubectl scale deployment llm-chatbot-frontend --replicas=3
```

**Auto-scaling configuration:**
- Backend: 1-3 replicas based on CPU (70% threshold)
- Frontend: 2-10 replicas based on CPU (70% threshold)

## 🔍 Troubleshooting

### Common Issues

1. **"Project not found" error**
   ```bash
   gcloud projects list
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **Docker authentication issues**
   ```bash
   gcloud auth configure-docker us-central1-docker.pkg.dev
   ```

3. **Cluster creation fails**
   - Check your Google Cloud quotas
   - Verify billing is enabled
   - Try a different zone

4. **Pods stuck in Pending**
   ```bash
   kubectl describe pod <pod-name>
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```

5. **TinyLlama not responding**
   ```bash
   kubectl logs deployment/llm-chatbot-backend -c ollama
   kubectl exec -it deployment/llm-chatbot-backend -c ollama -- ollama list
   kubectl exec -it deployment/llm-chatbot-backend -c ollama -- ollama run tinyllama "test"
   ```

### Debugging Commands

```bash
# Check cluster status
kubectl cluster-info

# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods

# Describe problematic pods
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check HPA status
kubectl get hpa
```

## 💰 Cost Management

### Estimated Costs (us-central1)

| Resource | Monthly Cost |
|----------|--------------|
| **GKE Cluster** | $60-80 |
| **Compute Nodes** | $40-65 |
| **Load Balancer** | $18 |
| **Artifact Registry** | $5-10 |
| **Total** | **$123-173** |

*Reduced costs due to TinyLlama's efficient resource usage*

### Cost Optimization Tips

1. **Use preemptible nodes**
   ```bash
   gcloud container clusters create llm-chatbot-cluster \
     --preemptible \
     --machine-type e2-standard-4
   ```

2. **Set up auto-scaling**
   - Cluster auto-scaling: 1-4 nodes
   - Pod auto-scaling: Based on CPU usage

3. **Monitor usage**
   ```bash
   kubectl top nodes
   kubectl top pods
   ```

4. **Clean up when not needed**
   ```bash
   gcloud container clusters delete llm-chatbot-cluster --zone us-central1-a
   ```

## 🛡️ Security Best Practices

### Network Security
- Use private GKE clusters for production
- Configure firewall rules appropriately
- Enable network policies

### Access Control
- Use Google Cloud IAM for access control
- Implement Kubernetes RBAC
- Regular security audits

### Data Protection
- Enable encryption at rest
- Use Google Cloud KMS for secrets
- Regular backups

## 🔄 Updates and Maintenance

### Updating the Application

1. **Build new images**
   ```bash
   ./deploy-gke.sh
   ```

2. **Rolling updates**
   ```bash
   kubectl rollout restart deployment/llm-chatbot-backend
   kubectl rollout restart deployment/llm-chatbot-frontend
   ```

3. **Check rollout status**
   ```bash
   kubectl rollout status deployment/llm-chatbot-backend
   ```

### Cluster Maintenance

1. **Update cluster**
   ```bash
   gcloud container clusters upgrade llm-chatbot-cluster --zone us-central1-a
   ```

2. **Update nodes**
   ```bash
   gcloud container clusters upgrade llm-chatbot-cluster --zone us-central1-a --node-pool default-pool
   ```

## 📞 Support

If you encounter issues:

1. **Check the logs** using the debugging commands above
2. **Verify prerequisites** are met
3. **Check Google Cloud quotas** and billing
4. **Review the troubleshooting section**
5. **Check Google Cloud Status** page for service issues

## 🎉 Success Checklist

After successful deployment, you should have:

- [ ] GKE cluster running with 2+ nodes
- [ ] Backend pod with Ollama and FastAPI containers
- [ ] Frontend pod serving the React application
- [ ] LoadBalancer service with external IP
- [ ] Auto-scaling configured for both components
- [ ] LLM models downloaded and ready
- [ ] Public access to your chatbot interface

Your scalable LLM infrastructure is now ready for production use! 🚀 