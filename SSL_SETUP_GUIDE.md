# SSL Certificate Setup Guide for askllm.net

This guide provides comprehensive instructions for setting up SSL/TLS certificates for your LLM chatbot domain `askllm.net` on Google Kubernetes Engine.

## 🔒 Overview

We'll implement **Google Managed SSL Certificates** which provide:
- Automatic certificate provisioning and renewal
- Integration with Google Cloud Load Balancer
- Support for multiple domains (askllm.net and www.askllm.net)
- Free SSL certificates with 90-day auto-renewal

## 📋 Prerequisites

### 1. Domain Ownership
- You must own the domain `askllm.net`
- Access to DNS management for the domain

### 2. GKE Cluster
- Running GKE cluster with the LLM chatbot deployed
- kubectl configured to access the cluster
- gcloud CLI authenticated

### 3. Environment Setup
```bash
export GCP_PROJECT_ID=your-project-id
export GKE_CLUSTER=llm-chatbot-cluster
export GKE_REGION=us-central1
```

## 🚀 Quick SSL Setup

### Option 1: Automated Setup (Recommended)
```bash
# Run the automated SSL setup script
./scripts/setup-ssl-askllm.sh
```

### Option 2: Manual Setup
Follow the step-by-step instructions below.

## 📝 Step-by-Step Manual Setup

### Step 1: Reserve Static IP Address

```bash
# Reserve a global static IP
gcloud compute addresses create askllm-static-ip \
    --global \
    --project=$GCP_PROJECT_ID

# Get the IP address
STATIC_IP=$(gcloud compute addresses describe askllm-static-ip \
    --global \
    --project=$GCP_PROJECT_ID \
    --format="value(address)")

echo "Static IP: $STATIC_IP"
```

### Step 2: Configure DNS Records

Configure the following DNS records with your domain provider:

#### A Records
```
Type: A
Name: @
Value: [STATIC_IP from Step 1]
TTL: 300

Type: A  
Name: www
Value: [STATIC_IP from Step 1]
TTL: 300
```

#### Alternative CNAME for www
```
Type: CNAME
Name: www
Value: askllm.net
TTL: 300
```

### Step 3: Deploy SSL Certificate

```bash
# Update the SSL configuration with your static IP
sed "s|loadBalancerIP: \"\"|loadBalancerIP: \"$STATIC_IP\"|g" \
    k8s/ssl-certificate-askllm.yaml > /tmp/ssl-certificate-askllm.yaml

# Apply the SSL certificate configuration
kubectl apply -f /tmp/ssl-certificate-askllm.yaml
```

### Step 4: Monitor Certificate Provisioning

```bash
# Check managed certificate status
kubectl get managedcertificate askllm-ssl-cert -w

# Detailed certificate information
kubectl describe managedcertificate askllm-ssl-cert

# Check ingress status
kubectl get ingress askllm-ingress -o wide
```

## 🔍 SSL Certificate Status

### Certificate States
- **Provisioning**: Certificate is being created (can take 10-60 minutes)
- **FailedNotVisible**: DNS not configured or not propagated
- **Failed**: Configuration error
- **Active**: Certificate is ready and working

### Common Status Messages
```bash
# Check certificate status
kubectl get managedcertificate askllm-ssl-cert -o yaml

# Expected output when ready:
# status:
#   certificateName: mcrt-xxxxx
#   certificateStatus: Active
#   domainStatus:
#   - domain: askllm.net
#     status: Active
#   - domain: www.askllm.net
#     status: Active
```

## 🌐 DNS Configuration Examples

### Cloudflare
```
Type: A
Name: @
IPv4 address: [STATIC_IP]
Proxy status: DNS only (gray cloud)
TTL: Auto

Type: A
Name: www
IPv4 address: [STATIC_IP]
Proxy status: DNS only (gray cloud)
TTL: Auto
```

### Google Domains
```
Host name: @
Type: A
TTL: 300
Data: [STATIC_IP]

Host name: www
Type: A
TTL: 300
Data: [STATIC_IP]
```

### Namecheap
```
Type: A Record
Host: @
Value: [STATIC_IP]
TTL: 300

Type: A Record
Host: www
Value: [STATIC_IP]
TTL: 300
```

## 🔧 Frontend HTTPS Configuration

The setup automatically configures the frontend with HTTPS-specific settings:

### Security Headers
- Strict-Transport-Security (HSTS)
- Content Security Policy (CSP)
- X-Frame-Options
- X-Content-Type-Options

### WebSocket over HTTPS (WSS)
- Automatic upgrade from ws:// to wss://
- Proper proxy headers for secure WebSocket connections

## 🧪 Testing SSL Configuration

### 1. DNS Propagation Test
```bash
# Check DNS propagation
nslookup askllm.net
nslookup www.askllm.net

# Alternative using dig
dig askllm.net A
dig www.askllm.net A
```

### 2. HTTP to HTTPS Redirect Test
```bash
# Should return 301 redirect to HTTPS
curl -I http://askllm.net
curl -I http://www.askllm.net
```

### 3. HTTPS Connectivity Test
```bash
# Should return 200 OK
curl -I https://askllm.net
curl -I https://www.askllm.net
```

### 4. SSL Certificate Test
```bash
# Check certificate details
openssl s_client -connect askllm.net:443 -servername askllm.net

# Check certificate expiration
echo | openssl s_client -connect askllm.net:443 -servername askllm.net 2>/dev/null | openssl x509 -noout -dates
```

### 5. WebSocket over HTTPS Test
```bash
# Install wscat if not available
npm install -g wscat

# Test WebSocket connection
wscat -c wss://askllm.net/ws
```

## 🛠️ Troubleshooting

### Certificate Stuck in "Provisioning"
```bash
# Check DNS configuration
kubectl describe managedcertificate askllm-ssl-cert

# Common issues:
# 1. DNS not pointing to correct IP
# 2. DNS not propagated (wait 5-60 minutes)
# 3. Domain not accessible from Google's validation servers
```

### Certificate Status "FailedNotVisible"
```bash
# Verify DNS records
nslookup askllm.net 8.8.8.8
nslookup www.askllm.net 8.8.8.8

# Check if domain resolves to static IP
RESOLVED_IP=$(nslookup askllm.net 8.8.8.8 | grep "Address:" | tail -1 | awk '{print $2}')
echo "Resolved IP: $RESOLVED_IP"
echo "Static IP: $STATIC_IP"
```

### Ingress Not Getting IP
```bash
# Check ingress events
kubectl describe ingress askllm-ingress

# Check service status
kubectl get service askllm-static-ip -o wide

# Verify static IP reservation
gcloud compute addresses list --global
```

### WebSocket Connection Issues
```bash
# Check backend service
kubectl get service llm-chatbot-backend-service

# Test backend connectivity
kubectl port-forward service/llm-chatbot-backend-service 8080:80
curl http://localhost:8080/health
```

## 🔄 Certificate Renewal

Google Managed Certificates automatically renew:
- Renewal starts 30 days before expiration
- No manual intervention required
- Monitor with: `kubectl get managedcertificate askllm-ssl-cert`

## 🚨 Emergency Procedures

### Rollback SSL Configuration
```bash
# Remove SSL ingress
kubectl delete ingress askllm-ingress

# Use original LoadBalancer service
kubectl get service llm-chatbot-frontend-service
```

### Force Certificate Recreation
```bash
# Delete and recreate certificate
kubectl delete managedcertificate askllm-ssl-cert
kubectl apply -f k8s/ssl-certificate-askllm.yaml
```

## 📊 Monitoring and Alerts

### Certificate Expiration Monitoring
```bash
# Check certificate expiration
kubectl get managedcertificate askllm-ssl-cert -o jsonpath='{.status.expireTime}'

# Set up monitoring (example with curl)
curl -s https://askllm.net | openssl x509 -noout -dates
```

### Health Check Endpoints
- `https://askllm.net/health` - Frontend health
- `https://askllm.net/api/health` - Backend health
- `https://askllm.net/api/docs` - API documentation

## 🔐 Security Best Practices

### 1. HSTS Configuration
The setup includes Strict-Transport-Security headers:
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

### 2. Content Security Policy
Configured to allow necessary resources while blocking XSS:
```
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'; ...
```

### 3. Regular Security Audits
```bash
# SSL Labs test (online)
# Visit: https://www.ssllabs.com/ssltest/analyze.html?d=askllm.net

# Local security scan
nmap --script ssl-enum-ciphers -p 443 askllm.net
```

## 💰 Cost Considerations

### Google Managed Certificates
- **Free** SSL certificates
- No additional charges for certificate management
- Included in GKE/Load Balancer costs

### Static IP Address
- **$0.01/hour** when attached to running resource
- **$0.01/hour** when reserved but unattached
- ~**$7.30/month** total cost

## 📞 Support and Resources

### Google Cloud Documentation
- [Managed Certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs)
- [Ingress for GKE](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress)

### Debugging Commands
```bash
# Complete status check
kubectl get managedcertificate,ingress,service -l app=llm-chatbot

# Detailed troubleshooting
kubectl describe managedcertificate askllm-ssl-cert
kubectl describe ingress askllm-ingress
kubectl logs -l app=llm-chatbot
```

---

## 🎉 Success Checklist

- [ ] Static IP reserved and configured
- [ ] DNS records pointing to static IP
- [ ] DNS propagation completed (5-60 minutes)
- [ ] Managed certificate status: "Active"
- [ ] HTTPS accessible: `https://askllm.net`
- [ ] HTTP redirects to HTTPS
- [ ] WebSocket over HTTPS working: `wss://askllm.net/ws`
- [ ] SSL certificate valid and trusted
- [ ] Security headers present

**Your LLM chatbot is now securely accessible at `https://askllm.net`!** 