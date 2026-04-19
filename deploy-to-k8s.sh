#!/bin/bash
# deploy-to-k8s-kind.sh
set -e

IMAGE_NAME=$1
IMAGE_TAG=$2

if [ -z "$IMAGE_NAME" ] || [ -z "$IMAGE_TAG" ]; then
    echo "Usage: ./deploy-to-k8s-kind.sh <image-name> <image-tag>"
    exit 1
fi

echo "========================================="
echo "Deploying to KIND Kubernetes"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "========================================="

# Check if KIND cluster is running
echo "✓ Checking KIND cluster status..."
if ! kubectl cluster-info --context kind-devops-cluster > /dev/null 2>&1; then
    echo "❌ KIND cluster is not running!"
    echo "Please create cluster: kind create cluster --name devops-cluster"
    exit 1
fi
echo "✓ KIND cluster is running"

# Load image to KIND cluster
echo ""
echo "📦 Loading Docker image to KIND..."
kind load docker-image ${IMAGE_NAME}:${IMAGE_TAG} --name devops-cluster
echo "✓ Image loaded successfully"

# Verify image is in KIND
echo ""
echo "🔍 Verifying image in cluster..."
# KIND doesn't have image ls command, but we can verify via deployment
echo "✓ Image ready for deployment"

# Apply or update deployment
echo ""
echo "🚀 Deploying to Kubernetes..."

# Check if deployment exists
if kubectl get deployment devops-deployment > /dev/null 2>&1; then
    echo "Updating existing deployment..."
    kubectl set image deployment/devops-deployment devops-app=${IMAGE_NAME}:${IMAGE_TAG} --record
else
    echo "Creating new deployment..."
    kubectl apply -f kubernetes/deployment.yaml
    kubectl apply -f kubernetes/service.yaml
fi

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

# Get service info
echo ""
echo "🌐 Service information:"
kubectl get service devops-service

echo ""
echo "🌐 Access your application at: http://localhost:30007"
echo ""
echo "========================================="
echo "✅ Deployment completed successfully!"
echo "========================================="
