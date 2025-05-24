#!/bin/bash

# Script to temporarily disable GitHub Actions deployment
echo "🚫 Disabling GitHub Actions deployment..."

# Rename the workflow file to disable it
if [ -f ".github/workflows/deploy.yml" ]; then
    mv .github/workflows/deploy.yml .github/workflows/deploy.yml.disabled
    echo "✅ GitHub Actions deployment disabled"
    echo "📁 Workflow moved to: .github/workflows/deploy.yml.disabled"
else
    echo "⚠️  GitHub Actions workflow not found or already disabled"
fi

echo ""
echo "🛠️  Use manual deployment instead:"
echo "   export GCP_PROJECT_ID=your-project-id"
echo "   ./manual-cloud-deploy.sh"
echo ""
echo "🔄 To re-enable later:"
echo "   mv .github/workflows/deploy.yml.disabled .github/workflows/deploy.yml" 