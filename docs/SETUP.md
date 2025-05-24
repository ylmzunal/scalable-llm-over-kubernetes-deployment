# Setup Guide - Scalable LLM Deployment on Kubernetes

This guide will help you set up and deploy the Scalable LLM Chatbot project both locally and on Google Cloud Platform.

## Prerequisites

### For MacBook Pro M3

1. **Docker Desktop**: `brew install --cask docker`
2. **Minikube**: `brew install minikube`
3. **kubectl**: `brew install kubectl`
4. **Node.js**: `brew install node`
5. **Python 3.11**: `brew install python@3.11`

## Local Development

### Quick Start

1. **Clone the repository**
```bash
git clone <your-repo-url>
cd scalable-llm-over-kubernetes
```

2. **Deploy to Minikube**
```bash
chmod +x scripts/deploy-local.sh
./scripts/deploy-local.sh
```

3. **Start Frontend**
```bash
cd frontend
npm install
npm start
```

Access the application at http://localhost:3000

### Manual Setup

If you prefer to run components separately:

1. **Backend Setup**
```bash
pip install -r requirements.txt
export LLM_MODEL_TYPE=mock
python -m uvicorn app.main:app --reload
```

2. **Frontend Setup**
```bash
cd frontend
npm install
npm start
```

## Cloud Deployment

### Google Cloud Setup

1. **Create GCP Project and enable APIs**
```bash
gcloud projects create your-project-id
gcloud config set project your-project-id
gcloud services enable container.googleapis.com
```

2. **Create GKE Cluster (Free Tier)**
```bash
gcloud container clusters create llm-chatbot-cluster \
  --zone=us-central1-a \
  --machine-type=e2-small \
  --num-nodes=2 \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=3
```

3. **Setup GitHub Actions**
- Add `GCP_PROJECT_ID` and `GCP_SA_KEY` to repository secrets
- Push to main branch to trigger deployment

## Configuration

### LLM Models

- **Mock Mode** (Default): No external dependencies
- **OpenAI**: Set `OPENAI_API_KEY` secret
- **Ollama**: Local model support

### Scaling

Adjust in `k8s/hpa.yaml`:
- Min replicas: 2
- Max replicas: 10
- CPU threshold: 70%

## Troubleshooting

**Check status**: `kubectl get pods,services,hpa -l app=llm-chatbot`
**View logs**: `kubectl logs -f -l app=llm-chatbot`
**Test health**: `curl http://localhost:8000/health`

## Cost Optimization

- Use free tier resources
- Set appropriate resource limits
- Monitor usage with `kubectl top`
- Clean up when not needed 