pipeline {
    agent any

    environment {
        IMAGE_NAME = 'rajugsk20/devops-flask-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        EC2_HOST  = '18.171.164.82'
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

        stage('Deploy to EC2') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh './scripts/deploy_to_ec2.sh ${EC2_HOST} ${IMAGE_NAME} ${IMAGE_TAG}'
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
        success {
            echo "Build, push, and EC2 deployment successful: ${IMAGE_NAME}:${IMAGE_TAG}"
        }
    }
}
