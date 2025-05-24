#!/bin/bash

# Test script for LLM Chatbot deployment
# Tests both local and cloud deployments

set -e

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

# Function to test endpoint
test_endpoint() {
    local url=$1
    local name=$2
    
    print_status "Testing $name at $url"
    
    if curl -s -f "$url/health" > /dev/null; then
        print_success "$name is responding"
        
        # Test a simple chat
        print_status "Testing chat functionality..."
        response=$(curl -s -X POST "$url/chat" \
            -H "Content-Type: application/json" \
            -d '{"message": "Hello, how are you?", "session_id": "test"}' || echo "")
        
        if [ -n "$response" ]; then
            print_success "Chat endpoint working"
            echo "Response preview: $(echo "$response" | head -c 100)..."
        else
            print_warning "Chat endpoint may have issues"
        fi
    else
        print_error "$name is not responding"
        return 1
    fi
}

# Test local deployment
test_local() {
    print_status "=== Testing Local Deployment ==="
    
    # Check if Ollama is running
    if curl -s http://localhost:11434/api/version > /dev/null; then
        print_success "Ollama is running"
        
        # List available models
        print_status "Available Ollama models:"
        curl -s http://localhost:11434/api/tags | jq -r '.models[].name' 2>/dev/null || echo "No models found or jq not installed"
    else
        print_warning "Ollama is not running"
    fi
    
    # Check if Minikube is running
    if minikube status | grep -q "host: Running"; then
        print_success "Minikube is running"
        
        # Check backend
        if kubectl get pods -l app=llm-chatbot | grep -q "Running"; then
            print_success "Backend pods are running"
            test_endpoint "http://localhost:8000" "Local Backend"
        else
            print_error "Backend pods are not running"
        fi
    else
        print_warning "Minikube is not running"
    fi
    
    # Check frontend
    if curl -s -f http://localhost:3000 > /dev/null; then
        print_success "Frontend is accessible"
    else
        print_warning "Frontend is not accessible"
    fi
}

# Test cloud deployment
test_cloud() {
    print_status "=== Testing Cloud Deployment ==="
    
    # Check if kubectl can connect to GKE
    if kubectl cluster-info | grep -q "Kubernetes control plane"; then
        print_success "Connected to Kubernetes cluster"
        
        # Check if pods are running
        if kubectl get pods -l app=llm-chatbot | grep -q "Running"; then
            print_success "Cloud backend pods are running"
            
            # Get external IP
            external_ip=$(kubectl get service llm-chatbot-backend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
            
            if [ -n "$external_ip" ] && [ "$external_ip" != "null" ]; then
                print_success "External IP: $external_ip"
                test_endpoint "http://$external_ip" "Cloud Backend"
            else
                print_warning "External IP not yet assigned or pending"
                print_status "You can check with: kubectl get services -w"
            fi
        else
            print_error "Cloud backend pods are not running"
        fi
        
        # Check HPA
        if kubectl get hpa llm-chatbot-backend-hpa > /dev/null 2>&1; then
            print_success "HPA is configured"
            kubectl get hpa llm-chatbot-backend-hpa
        else
            print_warning "HPA not found"
        fi
        
    else
        print_warning "Not connected to a Kubernetes cluster"
    fi
}

# Test GitHub Actions (if in GitHub environment)
test_github_actions() {
    if [ -n "$GITHUB_ACTIONS" ]; then
        print_status "=== Testing in GitHub Actions ==="
        print_status "GitHub Actions environment detected"
        
        # Test deployment health
        kubectl wait --for=condition=ready pod -l app=llm-chatbot --timeout=300s
        kubectl get pods,services,hpa -l app=llm-chatbot
        
        # Test with curl pod
        kubectl run test-curl --image=curlimages/curl:latest --rm -i --restart=Never -- \
            curl -f http://llm-chatbot-backend-service/health
            
        print_success "GitHub Actions test completed"
    fi
}

# Main execution
main() {
    echo "🧪 LLM Chatbot Deployment Test Suite"
    echo "====================================="
    
    case "${1:-all}" in
        "local")
            test_local
            ;;
        "cloud")
            test_cloud
            ;;
        "github")
            test_github_actions
            ;;
        "all")
            test_local
            echo ""
            test_cloud
            test_github_actions
            ;;
        *)
            echo "Usage: $0 [local|cloud|github|all]"
            echo "  local  - Test local Minikube deployment"
            echo "  cloud  - Test cloud GKE deployment"
            echo "  github - Test in GitHub Actions environment"
            echo "  all    - Test all environments (default)"
            exit 1
            ;;
    esac
    
    echo ""
    print_status "Test suite completed!"
}

# Run main function with all arguments
main "$@" 