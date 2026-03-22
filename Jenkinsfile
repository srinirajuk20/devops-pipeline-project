pipeline {
    agent any

    environment {
        IMAGE_NAME = 'rajugsk20/devops-flask-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f app/Dockerfile app'
            }
        }

        stage('Login to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'DockerHub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh 'docker push ${IMAGE_NAME}:${IMAGE_TAG}'
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
        success {
            echo "Image pushed successfully: ${IMAGE_NAME}:${IMAGE_TAG}"
        }
    }
}
