pipeline {
    agent any
    
    environment {
        IMAGE_NAME = "devops-mini-app"
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKERHUB_USER = "adi070903"
        KIND_CLUSTER = "devops-cluster"
        FULL_IMAGE_NAME = "${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                echo '📦 Checking out code from repository...'
                git branch: 'master', url: 'https://github.com/aditya-0508/devops_mini_project.git'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo "🔨 Building Docker image: ${FULL_IMAGE_NAME}"
                sh """
                    docker build -t ${FULL_IMAGE_NAME} .
                    docker tag ${FULL_IMAGE_NAME} ${DOCKERHUB_USER}/${IMAGE_NAME}:latest
                """
            }
        }
        stage('Login to DockerHub') {
            steps {
                echo '🔐 Logging in to DockerHub...'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh 'echo $PASS | docker login -u $USER --password-stdin'
                }
            }
        }
        
        stage('Push to DockerHub') {
            steps {
                echo "📤 Pushing image to DockerHub: ${FULL_IMAGE_NAME}"
                sh """
                    docker push ${FULL_IMAGE_NAME}
                    docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:latest
                """
            }
        }
        
        stage('Load Image to KIND') {
            steps {
                echo "📦 Loading image to KIND cluster: ${KIND_CLUSTER}"
                script {
                    sh """
                        # Check if KIND cluster exists
                        if ! kind get clusters | grep -q ${KIND_CLUSTER}; then
                            echo "❌ KIND cluster '${KIND_CLUSTER}' not found!"
                            echo "Available clusters:"
                            kind get clusters
                            exit 1
                        fi
                        
                        # Load image to KIND
                        echo "Loading ${FULL_IMAGE_NAME} to KIND..."
                        kind load docker-image ${FULL_IMAGE_NAME} --name ${KIND_CLUSTER}
                        
                        # Also load the latest tag
                        kind load docker-image ${DOCKERHUB_USER}/${IMAGE_NAME}:latest --name ${KIND_CLUSTER}
                        
                        echo "✓ Image loaded to KIND cluster"
                    """
                }
            }
        }
        
stage('Deploy to Kubernetes') {
    steps {
        echo '☸️ Deploying to Kubernetes cluster...'
        sh """
            # Ensure namespace objects exist
            kubectl apply -f kubernetes/deployment.yaml
            kubectl apply -f kubernetes/service.yaml

            # Now update image
            kubectl set image deployment/devops-deployment \
                devops-app=${FULL_IMAGE_NAME}

            # Wait rollout
            kubectl rollout status deployment/devops-deployment --timeout=180s
        """
    }
}
        
        stage('Verify Deployment') {
            steps {
                echo '✅ Verifying deployment...'
                script {
                    sh """
                        echo "=================================="
                        echo "Deployment Status:"
                        kubectl get deployment devops-deployment
                        
                        echo ""
                        echo "Pod Status:"
                        kubectl get pods -l app=devops-app
                        
                        echo ""
                        echo "Service Status:"
                        kubectl get service devops-service
                        
                        echo ""
                        echo "Recent Rollout History:"
                        kubectl rollout history deployment/devops-deployment
                        
                        echo ""
                        echo "=================================="
                        echo "✅ Application deployed successfully!"
                        echo "🌐 Access at: http://localhost:30007"
                        echo "=================================="
                    """
                }
            }
        }
        
        stage('Cleanup Old Images') {
            steps {
                echo '🧹 Cleaning up old Docker images...'
                sh """
                    # Remove test containers if any
                    docker ps -a | grep test- | awk '{print \$1}' | xargs -r docker rm -f || true
                    
                    # Remove dangling images
                    docker image prune -f
                    
                    # Keep last 5 builds, remove older ones
                    docker images ${DOCKERHUB_USER}/${IMAGE_NAME} --format "{{.Tag}}" | \
                        grep -E '^[0-9]+\$' | sort -rn | tail -n +6 | \
                        xargs -I {} docker rmi ${DOCKERHUB_USER}/${IMAGE_NAME}:{} || true
                    
                    echo "✓ Cleanup complete"
                """
            }
        }
    }
    
    post {
        success {
            echo '========================================='
            echo '✅ Pipeline completed successfully!'
            echo '========================================='
            echo "Image: ${FULL_IMAGE_NAME}"
            echo "Pushed to DockerHub: ✓"
            echo "Deployed to Kubernetes: ✓"
            echo "Access URL: http://localhost:30007"
            echo '========================================='
        }
        
        failure {
            echo '========================================='
            echo '❌ Pipeline failed!'
            echo '========================================='
            echo 'Check the logs above for error details'
            
            // Show recent pod logs for debugging
            sh """
                echo "Last pod logs (for debugging):"
                kubectl logs -l app=devops-app --tail=50 || true
            """ 
        }
        
        always {
            echo '🧹 Final cleanup...'
            sh """
                # Remove any hanging test containers
                docker ps -a | grep test-${BUILD_NUMBER} && docker rm -f test-${BUILD_NUMBER} || true
            """
        }
    }
}
