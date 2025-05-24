#!/bin/bash

# Monitor Kubernetes Auto-Scaling During Load Testing
# This script watches pod scaling, HPA metrics, and resource usage

echo "🔍 Starting Kubernetes Auto-Scaling Monitor"
echo "=================================================="

# Function to get current timestamp
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Function to monitor pods
monitor_pods() {
    echo "$(timestamp) - Pod Status:"
    kubectl get pods -l app=llm-chatbot -o wide --no-headers | \
    awk '{printf "  Pod: %-35s Status: %-10s Node: %-15s Age: %s\n", $1, $3, $7, $5}'
    echo
}

# Function to monitor HPA
monitor_hpa() {
    echo "$(timestamp) - Horizontal Pod Autoscaler:"
    kubectl get hpa llm-chatbot-hpa --no-headers | \
    awk '{printf "  Targets: %-20s Min/Max/Current: %s/%s/%s\n", $4, $5, $6, $7}'
    echo
}

# Function to monitor resource usage
monitor_resources() {
    echo "$(timestamp) - Resource Usage:"
    kubectl top pods -l app=llm-chatbot --no-headers 2>/dev/null | \
    awk '{printf "  Pod: %-35s CPU: %-10s Memory: %s\n", $1, $2, $3}' || \
    echo "  (Resource metrics not available - metrics-server may not be running)"
    echo
}

# Function to monitor service endpoints
monitor_endpoints() {
    echo "$(timestamp) - Service Endpoints:"
    kubectl get endpoints llm-chatbot-backend-service --no-headers | \
    awk '{print "  Active Endpoints: " $2}'
    echo
}

# Function to get deployment status
monitor_deployment() {
    echo "$(timestamp) - Deployment Status:"
    kubectl get deployment llm-chatbot-backend --no-headers | \
    awk '{printf "  Ready: %s  Up-to-date: %s  Available: %s\n", $2, $3, $4}'
    echo
}

# Function to check load testing connection
check_load_test_connectivity() {
    echo "$(timestamp) - Load Test Connectivity:"
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null)
    if [ "$response" = "200" ]; then
        echo "  ✅ Backend is accessible (HTTP $response)"
    else
        echo "  ❌ Backend connectivity issue (HTTP $response)"
    fi
    echo
}

# Main monitoring loop
echo "Starting continuous monitoring... (Press Ctrl+C to stop)"
echo

while true; do
    clear
    echo "🔍 Kubernetes Auto-Scaling Monitor - $(timestamp)"
    echo "=================================================="
    echo
    
    monitor_deployment
    monitor_pods
    monitor_hpa
    monitor_resources
    monitor_endpoints
    check_load_test_connectivity
    
    echo "Refreshing in 10 seconds..."
    echo "Press Ctrl+C to stop monitoring"
    
    sleep 10
done 