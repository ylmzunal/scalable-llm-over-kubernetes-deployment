#!/bin/bash

# SSL Certificate Setup Script for askllm.net
# This script sets up Google Managed SSL certificates for the LLM chatbot

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
DOMAIN="askllm.net"
PROJECT_ID="${GCP_PROJECT_ID:-}"
STATIC_IP_NAME="askllm-static-ip"
REGION="${GKE_REGION:-us-central1}"

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
    
    # Validate project ID
    if [ -z "$PROJECT_ID" ]; then
        print_error "GCP_PROJECT_ID environment variable is not set."
        echo "Please set it with: export GCP_PROJECT_ID=your-project-id"
        exit 1
    fi
    
    # Check if connected to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Not connected to a Kubernetes cluster."
        echo "Please connect to your GKE cluster first."
        exit 1
    fi
    
    print_success "Prerequisites validated"
}

# Reserve static IP address
reserve_static_ip() {
    print_status "Reserving static IP address for $DOMAIN..."
    
    # Check if IP already exists
    if gcloud compute addresses describe "$STATIC_IP_NAME" --global --project="$PROJECT_ID" &> /dev/null; then
        print_warning "Static IP '$STATIC_IP_NAME' already exists"
        STATIC_IP=$(gcloud compute addresses describe "$STATIC_IP_NAME" --global --project="$PROJECT_ID" --format="value(address)")
        print_status "Existing static IP: $STATIC_IP"
    else
        print_status "Creating new static IP address..."
        gcloud compute addresses create "$STATIC_IP_NAME" \
            --global \
            --project="$PROJECT_ID"
        
        STATIC_IP=$(gcloud compute addresses describe "$STATIC_IP_NAME" --global --project="$PROJECT_ID" --format="value(address)")
        print_success "Static IP created: $STATIC_IP"
    fi
    
    echo "STATIC_IP=$STATIC_IP" > /tmp/askllm-ip.env
}

# Update SSL configuration with static IP
update_ssl_config() {
    print_status "Updating SSL configuration with static IP..."
    
    # Create temporary SSL config with static IP
    sed "s|loadBalancerIP: \"\"|loadBalancerIP: \"$STATIC_IP\"|g" \
        k8s/ssl-certificate-askllm.yaml > /tmp/ssl-certificate-askllm.yaml
    
    print_success "SSL configuration updated"
}

# Deploy SSL certificate and ingress
deploy_ssl_certificate() {
    print_status "Deploying SSL certificate and ingress..."
    
    # Apply the SSL certificate configuration
    kubectl apply -f /tmp/ssl-certificate-askllm.yaml
    
    print_success "SSL certificate and ingress deployed"
}

# Check certificate status
check_certificate_status() {
    print_status "Checking SSL certificate status..."
    
    # Wait a moment for resources to be created
    sleep 10
    
    # Check managed certificate status
    echo ""
    print_status "Managed Certificate Status:"
    kubectl get managedcertificate askllm-ssl-cert -o wide || print_warning "Certificate not found yet"
    
    echo ""
    print_status "Ingress Status:"
    kubectl get ingress askllm-ingress -o wide || print_warning "Ingress not found yet"
    
    echo ""
    print_status "Service Status:"
    kubectl get service askllm-static-ip -o wide || print_warning "Service not found yet"
}

# Display DNS configuration instructions
show_dns_instructions() {
    print_status "DNS Configuration Instructions"
    echo ""
    echo "🌐 Configure your DNS records for $DOMAIN:"
    echo ""
    echo "   Record Type: A"
    echo "   Name: @"
    echo "   Value: $STATIC_IP"
    echo "   TTL: 300 (or your provider's minimum)"
    echo ""
    echo "   Record Type: A"
    echo "   Name: www"
    echo "   Value: $STATIC_IP"
    echo "   TTL: 300 (or your provider's minimum)"
    echo ""
    echo "📋 Alternative CNAME configuration for www:"
    echo "   Record Type: CNAME"
    echo "   Name: www"
    echo "   Value: $DOMAIN"
    echo "   TTL: 300"
    echo ""
    print_warning "DNS propagation can take 5-60 minutes"
    print_warning "SSL certificate provisioning will start after DNS is configured"
}

# Monitor certificate provisioning
monitor_certificate() {
    print_status "Monitoring SSL certificate provisioning..."
    echo ""
    print_status "This process can take 10-60 minutes after DNS is configured"
    print_status "You can monitor progress with:"
    echo ""
    echo "   kubectl get managedcertificate askllm-ssl-cert -w"
    echo "   kubectl describe managedcertificate askllm-ssl-cert"
    echo ""
    print_status "Certificate status will change from 'Provisioning' to 'Active'"
}

# Update frontend configuration for HTTPS
update_frontend_config() {
    print_status "Updating frontend configuration for HTTPS..."
    
    # Create updated frontend deployment with HTTPS configuration
    cat > /tmp/frontend-https-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: askllm-frontend-config
  namespace: default
data:
  nginx.conf: |
    server {
        listen 8080;
        server_name _;
        root /usr/share/nginx/html;
        index index.html;
        
        # Security headers for HTTPS
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; connect-src 'self' wss://$DOMAIN https://$DOMAIN" always;
        
        # Gzip compression
        gzip on;
        gzip_vary on;
        gzip_min_length 1024;
        gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
        
        # Handle static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            try_files \$uri =404;
        }
        
        # Proxy API calls to backend
        location /api/ {
            proxy_pass http://llm-chatbot-backend-service.default.svc.cluster.local:80/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            
            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            
            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 180s;
            proxy_read_timeout 180s;
        }
        
        # Proxy WebSocket connections
        location /ws/ {
            proxy_pass http://llm-chatbot-backend-service.default.svc.cluster.local:80;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            
            # WebSocket specific timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 300s;
        }
        
        # Serve React app
        location / {
            try_files \$uri \$uri/ /index.html;
            
            # Cache control for HTML files
            location ~* \.(html)$ {
                add_header Cache-Control "no-cache, no-store, must-revalidate";
                add_header Pragma "no-cache";
                add_header Expires "0";
            }
        }
        
        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
        
        # Error pages
        error_page 404 /index.html;
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }
    }
EOF
    
    kubectl apply -f /tmp/frontend-https-config.yaml
    print_success "Frontend HTTPS configuration applied"
}

# Test SSL configuration
test_ssl_configuration() {
    print_status "SSL Configuration Test Commands"
    echo ""
    echo "🧪 After DNS propagation and certificate provisioning, test with:"
    echo ""
    echo "   # Test HTTP redirect"
    echo "   curl -I http://$DOMAIN"
    echo ""
    echo "   # Test HTTPS"
    echo "   curl -I https://$DOMAIN"
    echo ""
    echo "   # Test SSL certificate"
    echo "   openssl s_client -connect $DOMAIN:443 -servername $DOMAIN"
    echo ""
    echo "   # Test WebSocket over HTTPS"
    echo "   wscat -c wss://$DOMAIN/ws"
    echo ""
}

# Cleanup function
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -f /tmp/ssl-certificate-askllm.yaml
    rm -f /tmp/frontend-https-config.yaml
    rm -f /tmp/askllm-ip.env
}

# Main function
main() {
    echo "🔒 SSL Certificate Setup for $DOMAIN"
    echo "=============================================="
    
    # Validate prerequisites
    validate_prerequisites
    
    # Reserve static IP
    reserve_static_ip
    
    # Update SSL configuration
    update_ssl_config
    
    # Deploy SSL certificate
    deploy_ssl_certificate
    
    # Update frontend configuration
    update_frontend_config
    
    # Check initial status
    check_certificate_status
    
    # Show DNS instructions
    show_dns_instructions
    
    # Show monitoring instructions
    monitor_certificate
    
    # Show test commands
    test_ssl_configuration
    
    # Cleanup
    cleanup
    
    echo ""
    print_success "🎉 SSL setup initiated for $DOMAIN!"
    echo ""
    print_status "Next steps:"
    echo "1. Configure DNS records as shown above"
    echo "2. Wait for DNS propagation (5-60 minutes)"
    echo "3. Monitor certificate provisioning"
    echo "4. Test HTTPS access"
    echo ""
    print_status "Your chatbot will be available at: https://$DOMAIN"
    print_status "Static IP address: $STATIC_IP"
}

# Run main function
main "$@" 