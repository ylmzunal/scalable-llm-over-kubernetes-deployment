#!/bin/bash

# Setup script for downloading additional free AI models
# This script downloads various free models for the multi-model chatbot

echo "🚀 Setting up additional AI models for the Multi-Model LLM Chatbot"
echo "=================================================================="

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama is not installed. Please install it first:"
    echo "   brew install ollama"
    exit 1
fi

# Start Ollama server if not running
echo "🔧 Starting Ollama server..."
export OLLAMA_HOST=0.0.0.0:11434
ollama serve &
OLLAMA_PID=$!
sleep 5

echo "📥 Downloading free AI models..."

# Download Ollama models
echo "⬇️  Downloading Phi-2 (Microsoft) - 2.7B parameters..."
ollama pull phi

echo "⬇️  Downloading Llama 2 - 7B parameters..."
ollama pull llama2

echo "⬇️  Downloading DeepSeek Coder - 6.7B parameters..."
ollama pull deepseek-coder:6.7b

echo "⬇️  Downloading Code Llama - 7B parameters..."
ollama pull codellama

echo "⬇️  Downloading Mistral - 7B parameters..."
ollama pull mistral

echo "⬇️  Downloading Neural Chat (Intel) - 7B parameters..."
ollama pull neural-chat

echo "✅ Successfully downloaded all Ollama models!"

# List downloaded models
echo "📋 Available Ollama models:"
ollama list

echo ""
echo "🌐 Hugging Face models are available via free API (no download needed):"
echo "   • DialoGPT Large (Microsoft)"
echo "   • FLAN-T5 Large (Google)"
echo "   • DialoGPT Medium (Microsoft)"
echo "   • DeepSeek Coder 1.3B (DeepSeek)"

echo ""
echo "🎉 Setup complete! You can now:"
echo "   1. Start your Kubernetes cluster: minikube start"
echo "   2. Deploy the application: ./scripts/deploy-local.sh"
echo "   3. Start the frontend: cd frontend && npm start"
echo "   4. Use the model selector in the UI to switch between models"

echo ""
echo "💡 Model Information:"
echo "   🖥️  Local Models (Privacy-focused):"
echo "      • Run entirely on your machine"
echo "      • No data sent to external servers"
echo "      • Requires GPU/CPU resources"
echo ""
echo "   ☁️  Cloud Models (Free APIs):"
echo "      • Use Hugging Face Inference API"
echo "      • Free tier with rate limits"
echo "      • No local resources needed"

# Clean up
kill $OLLAMA_PID 2>/dev/null || true

echo ""
echo "✨ Ready to use your multi-model AI chatbot!" 