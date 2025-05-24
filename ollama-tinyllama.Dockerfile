FROM ollama/ollama:latest

# Set environment variables for optimal performance
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_MODELS=/root/.ollama/models
ENV OLLAMA_NUM_PARALLEL=2
ENV OLLAMA_MAX_LOADED_MODELS=1

# Create ollama directory structure
RUN mkdir -p /root/.ollama/models && \
    chmod -R 755 /root/.ollama

# Download and embed TinyLlama model during build time
# TinyLlama is only 1.1B parameters - perfect for production and demos
RUN echo "Starting ollama server for model download..." && \
    nohup ollama serve > /tmp/ollama.log 2>&1 & \
    OLLAMA_PID=$! && \
    sleep 15 && \
    echo "Downloading TinyLlama model..." && \
    ollama pull tinyllama && \
    echo "Model downloaded successfully!" && \
    ollama list && \
    echo "Verifying model..." && \
    echo "Test prompt: Hello" | ollama run tinyllama && \
    echo "Stopping ollama server..." && \
    kill $OLLAMA_PID && \
    wait $OLLAMA_PID 2>/dev/null || true && \
    echo "TinyLlama embedding complete"

# Verify the model files are properly embedded
RUN echo "Verifying embedded model files:" && \
    ls -la /root/.ollama/models/ && \
    du -sh /root/.ollama/models/ && \
    echo "TinyLlama model successfully embedded in image"

# Expose ollama port
EXPOSE 11434

# Health check for ollama service
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:11434/api/version || exit 1

# Start ollama server with TinyLlama pre-loaded
ENTRYPOINT ["/bin/ollama"]
CMD ["serve"] 