#!/bin/bash

set -e

IMAGE_NAME=$1
IMAGE_TAG=$2
CLUSTER_NAME="devops-cluster"

echo "Deploying ${IMAGE_NAME}:${IMAGE_TAG}"

# Load image into Kind
kind load docker-image ${IMAGE_NAME}:${IMAGE_TAG} --name ${CLUSTER_NAME}

# Update deployment
kubectl set image deployment/devops-deployment devops-app=${IMAGE_NAME}:${IMAGE_TAG}

# Wait for rollout
kubectl rollout status deployment/devops-deployment

echo "Deployment successful!"
