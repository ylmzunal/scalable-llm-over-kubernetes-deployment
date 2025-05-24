#!/bin/sh

# Docker entrypoint script for React frontend
# This script injects environment variables at runtime

set -e

# Define the configuration template
CONFIG_TEMPLATE='window._env_ = {
  REACT_APP_API_URL: "{{API_URL}}",
  REACT_APP_WS_URL: "{{WS_URL}}",
  REACT_APP_ENVIRONMENT: "{{ENVIRONMENT}}"
};'

# Get environment variables with defaults
API_URL=${REACT_APP_API_URL:-"/api"}
WS_URL=""  # Always empty - let React app build the URL
ENVIRONMENT=${REACT_APP_ENVIRONMENT:-"production"}
BACKEND_SERVICE=${BACKEND_SERVICE_NAME:-"llm-chatbot-backend-service.default.svc.cluster.local:80"}

echo "🚀 Configuring frontend with:"
echo "  API_URL: $API_URL"
echo "  WS_URL: $WS_URL"
echo "  ENVIRONMENT: $ENVIRONMENT"
echo "  BACKEND_SERVICE: $BACKEND_SERVICE"

# Configure nginx with the correct backend service
sed "s|BACKEND_SERVICE_NAME|$BACKEND_SERVICE|g" /etc/nginx/conf.d/default.conf > /tmp/nginx.conf
cp /tmp/nginx.conf /etc/nginx/conf.d/default.conf

# Replace placeholders in the configuration template
CONFIG_JS=$(echo "$CONFIG_TEMPLATE" | \
    sed "s|{{API_URL}}|$API_URL|g" | \
    sed "s|{{WS_URL}}|$WS_URL|g" | \
    sed "s|{{ENVIRONMENT}}|$ENVIRONMENT|g")

# Write the configuration to a JavaScript file
echo "$CONFIG_JS" > /tmp/config.js
cp /tmp/config.js /usr/share/nginx/html/config.js || chmod u+w /usr/share/nginx/html && cp /tmp/config.js /usr/share/nginx/html/config.js

# Create a simple health check page
cat > /tmp/health << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Health Check</title></head>
<body>
<h1>Frontend Health: OK</h1>
<p>Environment: $ENVIRONMENT</p>
<p>API URL: $API_URL</p>
<p>Timestamp: $(date)</p>
</body>
</html>
EOF

# Replace variables in health check
sed -i "s|\$ENVIRONMENT|$ENVIRONMENT|g" /tmp/health
sed -i "s|\$API_URL|$API_URL|g" /tmp/health
sed -i "s|\$(date)|$(date)|g" /tmp/health
cp /tmp/health /usr/share/nginx/html/health || chmod u+w /usr/share/nginx/html && cp /tmp/health /usr/share/nginx/html/health

echo "✅ Frontend configuration complete"

# Ensure proper ownership of files
chown nginx:nginx /usr/share/nginx/html/config.js || true
chown nginx:nginx /usr/share/nginx/html/health || true

# Execute the command passed to the script
exec "$@" 