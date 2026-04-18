pipeline {
    agent any

    environment {
        IMAGE_NAME = "devops-mini-app"
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKERHUB_USER = "adi070903"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git 'https://github.com/aditya-0508/devops_mini_project.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Login to DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh "echo $PASS | docker login -u $USER --password-stdin"
                }
            }
        }

        stage('Push Image') {
            steps {
                sh "docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
        stage('Deploy to Kubernetes') {
    steps {
        sh """
        chmod +x deploy-to-k8s.sh
        ./deploy-to-k8s.sh ${DOCKERHUB_USER}/${IMAGE_NAME} ${IMAGE_TAG}
        """
    }
}
        stage('Cleanup') {
            steps {
                sh "docker system prune -af"
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
