# Multi-Model Support Guide 🤖

Your scalable LLM chatbot now supports **multiple free AI models** from different providers! Users can choose between local privacy-focused models and cloud-based free APIs.

## 🎯 Available Free Models

### 🖥️ Local Models (Ollama) - Privacy First

Run entirely on your MacBook Pro M3 with GPU acceleration:

| Model | Provider | Size | Specialty | Privacy |
|-------|----------|------|-----------|---------|
| **Phi-2** | Microsoft | 2.7B | General chat | 🔒 100% Local |
| **Llama 2** | Meta | 7B | General purpose | 🔒 100% Local |
| **DeepSeek Coder** | DeepSeek | 6.7B | **Code generation** | 🔒 100% Local |
| **Code Llama** | Meta | 7B | **Programming** | 🔒 100% Local |
| **Mistral 7B** | Mistral AI | 7B | Efficient chat | 🔒 100% Local |
| **Neural Chat** | Intel | 7B | Conversational | 🔒 100% Local |

### ☁️ Cloud Models (Hugging Face) - Free API

Use free Hugging Face Inference API:

| Model | Provider | Size | Specialty | Rate Limit |
|-------|----------|------|-----------|------------|
| **DialoGPT Large** | Microsoft | Large | Conversational | Free tier |
| **FLAN-T5 Large** | Google | Large | **Question answering** | Free tier |
| **DialoGPT Medium** | Microsoft | Medium | Chat | Free tier |
| **DeepSeek Coder 1.3B** | DeepSeek | 1.3B | **Coding assistance** | Free tier |

## 🚀 Quick Start

### 1. Setup Additional Models

```bash
# Download all free Ollama models
./scripts/setup-models.sh
```

### 2. Deploy with Multi-Model Support

```bash
# Deploy to Kubernetes
./scripts/deploy-local.sh

# Start frontend
cd frontend && npm start
```

### 3. Switch Models in UI

1. Open the chatbot at `http://localhost:3000`
2. Click the ⚙️ settings icon in the top bar
3. Choose from available models:
   - **Local models**: Run on your machine (privacy-focused)
   - **Cloud models**: Use free Hugging Face API

## 🔧 Configuration

### Environment Variables

```bash
# Set default model provider
export LLM_MODEL_PROVIDER="ollama"        # ollama, huggingface, mock
export LLM_MODEL_NAME="phi"               # Model name within provider

# Optional: Hugging Face token for higher rate limits
export HF_API_TOKEN="your_token_here"     # Optional
```

### Kubernetes ConfigMap

Update `k8s/configmap.yaml`:

```yaml
data:
  model_provider: "ollama"     # Default provider
  model_name: "phi"           # Default model
```

## 📊 Model Comparison

### Performance & Resources

| Model Type | Latency | Privacy | GPU Usage | Internet |
|------------|---------|---------|-----------|----------|
| **Local (Ollama)** | Low | 🔒 Full | High | ❌ Not needed |
| **Cloud (HF)** | Medium | ⚠️ Shared | None | ✅ Required |

### Use Cases

#### 🔒 **Choose Local Models When:**
- Privacy is critical
- Sensitive data
- Offline development
- Consistent performance
- No API costs

#### ☁️ **Choose Cloud Models When:**
- Quick testing
- Limited local resources
- Experimenting with different models
- Don't mind data sharing

## 🎛️ API Endpoints

### Get Available Models
```bash
curl http://localhost:8000/models
```

### Switch Model
```bash
curl -X POST http://localhost:8000/models/switch \
  -H "Content-Type: application/json" \
  -d '{"provider": "ollama", "model_name": "deepseek-coder"}'
```

### Current Model Status
```bash
curl http://localhost:8000/models/current
```

## 🛠️ Advanced Usage

### Adding New Models

#### Ollama Models

```bash
# Add any Ollama-compatible model
ollama pull model-name
```

#### Hugging Face Models

Update `app/llm_service.py`:

```python
AVAILABLE_MODELS = {
    "huggingface": {
        "your-model": {
            "name": "your-model", 
            "display_name": "Your Model", 
            "size": "Size"
        }
    }
}
```

### Model-Specific Optimizations

#### DeepSeek Coder
```python
# Optimized for code generation
prompt = f"```python\n# {user_request}\n"
```

#### FLAN-T5
```python
# Optimized for questions
prompt = f"Question: {user_question}\nAnswer:"
```

## 🚨 Troubleshooting

### Common Issues

1. **Ollama Model Not Found**
   ```bash
   ollama pull model-name
   ```

2. **Hugging Face Rate Limits**
   - Set `HF_API_TOKEN` for higher limits
   - Switch to local models

3. **Model Switch Failed**
   - Check logs: `kubectl logs deployment/llm-chatbot-backend`
   - Verify model exists

### Performance Tips

1. **For Coding Tasks**: Use DeepSeek Coder or Code Llama
2. **For Quick Responses**: Use smaller models (Phi-2)
3. **For Quality**: Use larger models (Llama 2, Mistral)
4. **For Privacy**: Always use local Ollama models

## 🎯 Production Considerations

### Scaling Strategy

```yaml
# Different HPA for different model types
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: llm-chatbot-local-hpa
spec:
  minReplicas: 1  # Local models need fewer replicas
  maxReplicas: 5  # GPU memory constraints
```

### Security

- **Local models**: Zero data leakage
- **Cloud models**: Review Hugging Face privacy policy
- **Secrets**: Store HF tokens in Kubernetes secrets

### Monitoring

```bash
# Monitor model performance
kubectl top pods
watch -n 1 'kubectl get pods'

# Check model metrics
curl http://localhost:8000/metrics
```

## 🌟 Best Practices

### Model Selection Guidelines

1. **Start with Phi-2** (local, small, fast)
2. **Use DeepSeek Coder** for programming tasks
3. **Try Hugging Face models** for experimentation
4. **Scale up to Llama 2** for complex conversations
5. **Monitor resource usage** and adjust accordingly

### Development Workflow

```bash
# Development
export LLM_MODEL_PROVIDER="mock"  # Fast testing

# Local testing
export LLM_MODEL_PROVIDER="ollama"
export LLM_MODEL_NAME="phi"

# Production
# Use ConfigMap and secrets for configuration
```

## 🎉 What's Next?

Your multi-model chatbot now supports:

✅ **6 Free Local Models** (Ollama)  
✅ **4 Free Cloud Models** (Hugging Face)  
✅ **Real-time Model Switching**  
✅ **Kubernetes Auto-scaling**  
✅ **Modern React UI**  
✅ **Production-ready Architecture**  

### Future Enhancements

- [ ] Model performance comparison
- [ ] Automatic model recommendation
- [ ] Custom model fine-tuning
- [ ] Multi-model conversations
- [ ] Model-specific prompt optimization

---

**Ready to explore the power of multiple AI models!** 🚀

Start with `./scripts/setup-models.sh` and enjoy your new multi-model capabilities! 