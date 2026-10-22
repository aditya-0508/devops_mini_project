
pipeline {
    agent any

    environment {
        IMAGE_NAME     = "devops-mini-app"
        DOCKERHUB_USER = "adi070903"
        KIND_CLUSTER   = "devops-cluster"
        IMAGE_TAG      = "${BUILD_NUMBER}"
        FULL_IMAGE_NAME = "${DOCKERHUB_USER}/${IMAGE_NAME}:${BUILD_NUMBER}"
        LATEST_IMAGE   = "${DOCKERHUB_USER}/${IMAGE_NAME}:latest"
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building ${FULL_IMAGE_NAME}"

                sh '''
                    set -eu
                    docker build -t "$FULL_IMAGE_NAME" .
                    docker tag "$FULL_IMAGE_NAME" "$LATEST_IMAGE"
                '''
            }
        }

        stage('Login to DockerHub') {
            steps {
                echo 'Logging in to Docker Hub...'

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        set +x
                        printf '%s' "$DOCKER_PASS" |
                            docker login -u "$DOCKER_USER" --password-stdin
                    '''
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                echo "Pushing ${FULL_IMAGE_NAME}"

                sh '''
                    set -eu
                    docker push "$FULL_IMAGE_NAME"
                    docker push "$LATEST_IMAGE"
                '''
            }
        }

        stage('Validate KIND and Kubernetes') {
            steps {
                echo 'Checking KIND and Kubernetes connectivity...'

                sh '''
                    set -eu
                    command -v kind
                    command -v kubectl

                    kind get clusters

                    kind get clusters |
                        grep -Fx "$KIND_CLUSTER"

                    kubectl get nodes
                '''
            }
        }

        stage('Load Image to KIND') {
            steps {
                echo "Loading images into ${KIND_CLUSTER}..."

                sh '''
                    set -eu

                    kind load docker-image "$FULL_IMAGE_NAME" \
                        --name "$KIND_CLUSTER"

                    kind load docker-image "$LATEST_IMAGE" \
                        --name "$KIND_CLUSTER"
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying ${FULL_IMAGE_NAME}..."

                sh '''
                    set -eu

                    kubectl apply -f kubernetes/deployment.yaml
                    kubectl apply -f kubernetes/service.yaml

                    kubectl set image deployment/devops-deployment \
                        devops-app="$FULL_IMAGE_NAME"

                    kubectl rollout status deployment/devops-deployment \
                        --timeout=180s
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo 'Verifying application deployment...'

                sh '''
                    set -eu

                    echo "=== Deployment ==="
                    kubectl get deployment devops-deployment

                    echo "=== Pods ==="
                    kubectl get pods -l app=devops-app -o wide

                    echo "=== Service ==="
                    kubectl get service devops-service

                    echo "=== Rollout History ==="
                    kubectl rollout history deployment/devops-deployment
                '''
            }
        }

        stage('Cleanup Old Images') {
            steps {
                echo 'Cleaning up dangling Docker images...'

                sh '''
                    docker image prune -f
                '''
            }
        }
    }

    post {
        success {
            echo '========================================='
            echo 'Pipeline completed successfully!'
            echo "Image: ${FULL_IMAGE_NAME}"
            echo 'Docker Hub push: SUCCESS'
            echo 'Kubernetes deployment: SUCCESS'
            echo '========================================='
        }

        failure {
            echo 'Pipeline failed. Check the first failing stage.'

            sh '''
                echo "=== Kubernetes resources ==="
                kubectl get pods -l app=devops-app -o wide || true

                echo "=== Recent pod events ==="
                kubectl get events --sort-by=.metadata.creationTimestamp \
                    | tail -n 25 || true

                echo "=== Recent application logs ==="
                kubectl logs -l app=devops-app \
                    --all-containers=true --tail=50 || true
            '''
        }

        always {
            echo "Build ${BUILD_NUMBER} finished."
        }
    }
}
