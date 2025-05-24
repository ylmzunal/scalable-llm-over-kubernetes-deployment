# 🔐 GitHub Secrets Setup Guide

This guide helps you configure GitHub secrets for automated deployment to your existing GKE cluster.

## 📋 Your Cluster Information

- **Project ID**: `scalable-llm-chatbot`
- **Cluster Name**: `llm-chatbot-cluster`
- **Zone**: `us-central1-a`
- **Machine Type**: `e2-small` (cost-optimized)
- **Nodes**: 2

## 🔑 Required GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** and add these secrets:

### 1. GCP_PROJECT_ID
```
scalable-llm-chatbot
```

### 2. GCP_SA_KEY
You need to create a service account key. Run this command:

```bash
# Create service account
gcloud iam service-accounts create github-actions-sa \
    --display-name "GitHub Actions Service Account"

# Grant necessary roles
gcloud projects add-iam-policy-binding scalable-llm-chatbot \
    --member="serviceAccount:github-actions-sa@scalable-llm-chatbot.iam.gserviceaccount.com" \
    --role="roles/container.developer"

gcloud projects add-iam-policy-binding scalable-llm-chatbot \
    --member="serviceAccount:github-actions-sa@scalable-llm-chatbot.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Create and download key
gcloud iam service-accounts keys create ~/gcp-sa-key.json \
    --iam-account github-actions-sa@scalable-llm-chatbot.iam.gserviceaccount.com

# Copy the entire content of the JSON file
cat ~/gcp-sa-key.json
```

Copy the **entire JSON content** and paste it as the `GCP_SA_KEY` secret.

### 3. HF_API_TOKEN (Optional but Recommended)
- Go to [Hugging Face Settings](https://huggingface.co/settings/tokens)
- Create a new token (Read access is sufficient)
- Add it as `HF_API_TOKEN` secret

## 🚀 Deployment Options

### Option 1: Deploy Immediately
Run the deployment script to deploy now:

```bash
./scripts/deploy-to-existing-cluster.sh
```

### Option 2: Set up GitHub Actions
After adding the secrets above, push to the main branch:

```bash
git add .
git commit -m "Configure for existing cluster deployment"
git push origin main
```

## 🔧 Manual Deployment Commands

If you prefer to deploy manually:

```bash
# 1. Connect to cluster
gcloud container clusters get-credentials llm-chatbot-cluster --zone us-central1-a

# 2. Build and push image
docker build -t gcr.io/scalable-llm-chatbot/llm-chatbot-backend:latest .
docker push gcr.io/scalable-llm-chatbot/llm-chatbot-backend:latest

# 3. Deploy to cluster
kubectl apply -f k8s/rbac.yaml
kubectl apply -f k8s/configmap-cloud.yaml
sed "s/PROJECT_ID/scalable-llm-chatbot/g" k8s/backend-deployment-cloud.yaml | kubectl apply -f -
kubectl apply -f k8s/backend-service-cloud.yaml
kubectl apply -f k8s/hpa-cloud.yaml

# 4. Check status
kubectl get pods,services,hpa -l app=llm-chatbot
```

## 📊 Monitoring Commands

```bash
# Check pod status
kubectl get pods -l app=llm-chatbot

# View logs
kubectl logs -f -l app=llm-chatbot

# Check external IP
kubectl get service llm-chatbot-backend-service

# Monitor scaling
kubectl get hpa -w

# Check resource usage
kubectl top pods
```

## 💰 Cost Management

Your current setup is optimized for cost:
- **2 x e2-small nodes**: ~$25-30/month
- **External LoadBalancer**: ~$18/month
- **Storage**: Minimal (~$1/month)

**Total estimated cost**: ~$45-50/month

### Cost Optimization Tips:
1. **Use preemptible nodes** (60-91% savings):
   ```bash
   gcloud container node-pools create preemptible-pool \
       --cluster=llm-chatbot-cluster \
       --zone=us-central1-a \
       --machine-type=e2-small \
       --preemptible \
       --num-nodes=2
   ```

2. **Scale down during off-hours**:
   ```bash
   kubectl scale deployment llm-chatbot-backend --replicas=0
   ```

3. **Use NodePort instead of LoadBalancer** (saves $18/month):
   ```bash
   kubectl patch service llm-chatbot-backend-service -p '{"spec":{"type":"NodePort"}}'
   ```

## 🔒 Security Notes

- **Delete the service account key** after adding to GitHub:
  ```bash
  rm ~/gcp-sa-key.json
  ```

- **Rotate keys regularly** (every 90 days)

- **Monitor access** in Google Cloud Console → IAM

## 🧪 Testing

Test your deployment:

```bash
# Test locally
./scripts/test-deployment.sh cloud

# Test from internet (once external IP is assigned)
curl http://EXTERNAL_IP/health
curl http://EXTERNAL_IP/docs
```

## 📞 Support

If you encounter issues:

1. **Check cluster status**: `kubectl get nodes`
2. **Check pod logs**: `kubectl logs -f -l app=llm-chatbot`
3. **Check service status**: `kubectl describe service llm-chatbot-backend-service`
4. **Check GitHub Actions logs** in your repository

## 🎯 Quick Verification

After setup, verify everything works:

```bash
# 1. Cluster connectivity
kubectl cluster-info

# 2. Nodes ready
kubectl get nodes

# 3. Deployment ready
kubectl get deployment llm-chatbot-backend

# 4. Service accessible
kubectl get service llm-chatbot-backend-service

# 5. External access (after IP assigned)
curl http://$(kubectl get service llm-chatbot-backend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/health
```

Happy deploying! 🚀 