pipeline {
    agent any

    environment {
        IMAGE_NAME = 'rajugsk20/devops-flask-app'
        IMAGE_TAG  = "${BUILD_NUMBER}"
    }

    stages {

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f app/Dockerfile app'
            }
        }

        stage('Login to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'DockerHub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh 'docker push ${IMAGE_NAME}:${IMAGE_TAG}'
            }
        }

        stage('Get EC2 Public IP') {
            steps {
                script {
                    env.EC2_HOST = sh(
                        script: 'cd terraform && terraform output -raw instance_public_ip',
                        returnStdout: true
                    ).trim()

                    echo "EC2 IP: ${env.EC2_HOST}"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh 'chmod +x ./scripts/deploy_to_ec2.sh'
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
            echo "Deployment successful on ${EC2_HOST}"
        }
    }
}
