#!/bin/bash
# deploy-to-k8s.sh
# This script handles Kubernetes deployment from Jenkins in WSL environment

set -e  # Exit on any error

IMAGE_NAME=$1
IMAGE_TAG=$2

if [ -z "$IMAGE_NAME" ] || [ -z "$IMAGE_TAG" ]; then
    echo "Usage: ./deploy-to-k8s.sh <image-name> <image-tag>"
    exit 1
fi

echo "========================================="
echo "Deploying to Kubernetes"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "========================================="

# Check if minikube is running
echo "✓ Checking Minikube status..."
if ! minikube status > /dev/null 2>&1; then
    echo "❌ Minikube is not running!"
    echo "Please start Minikube: minikube start"
    exit 1
fi
echo "✓ Minikube is running"

# Load image to Minikube
echo ""
echo "📦 Loading Docker image to Minikube..."
minikube image load ${IMAGE_NAME}:${IMAGE_TAG}
echo "✓ Image loaded successfully"

# Verify image is in Minikube
echo ""
echo "🔍 Verifying image in Minikube..."
if minikube image ls | grep -q "${IMAGE_NAME}:${IMAGE_TAG}"; then
    echo "✓ Image verified in Minikube"
else
    echo "❌ Image not found in Minikube!"
    exit 1
fi

# Update deployment
echo ""
echo "🚀 Updating Kubernetes deployment..."
kubectl set image deployment/devops-deployment devops-app=${IMAGE_NAME}:${IMAGE_TAG} --record

# Wait for rollout
echo ""
echo "⏳ Waiting for rollout to complete..."
if kubectl rollout status deployment/devops-deployment --timeout=180s; then
    echo "✓ Rollout completed successfully"
else
    echo "❌ Rollout failed!"
    kubectl rollout undo deployment/devops-deployment
    echo "⚠️  Rolled back to previous version"
    exit 1
fi

# Get pod status
echo ""
echo "📊 Current pod status:"
kubectl get pods -l app=devops-app

# Get service URL
echo ""
echo "🌐 Service URL:"
minikube service devops-service --url

echo ""
echo "========================================="
echo "✅ Deployment completed successfully!"
echo "========================================="
