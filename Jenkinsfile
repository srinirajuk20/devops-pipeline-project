pipeline {
    agent any

    environment {
        IMAGE_NAME = 'rajugsk20/devops-flask-app'
        IMAGE_TAG  = "${BUILD_NUMBER}"
        AWS_DEFAULT_REGION = 'eu-west-2'
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

        stage('Check AWS Access') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-creds'
                ]]) {
                    sh 'aws sts get-caller-identity'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-creds'
                ]]) {
                    sh 'cd terraform && terraform init -reconfigure'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-creds'
                ]]) {
                    sh 'cd terraform && terraform apply -auto-approve'
                }
            }
        }

        stage('Get EC2 Public IP') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-creds'
                ]]) {
                    script {
                        env.EC2_HOST = sh(
                            script: '''
                                set -e
                                cd terraform
                                IP=$(terraform output -raw instance_public_ip 2>/dev/null || true)
                                if [ -z "$IP" ]; then
                                  echo "ERROR: Terraform output instance_public_ip is empty"
                                  exit 1
                                fi
                                echo "$IP"
                            ''',
                            returnStdout: true
                        ).trim()

                        echo "EC2_HOST: ${env.EC2_HOST}"
                    }
                }
            }
        }

        stage('Wait for EC2 SSH') {
            steps {
                sh '''
                    set -e
                    echo "Waiting for EC2 SSH on ${EC2_HOST}..."
                    for i in $(seq 1 18); do
                      if nc -z ${EC2_HOST} 22; then
                        echo "EC2 SSH is ready"
                        exit 0
                      fi
                      echo "Retry $i/18: SSH not ready yet, sleeping 10s..."
                      sleep 10
                    done
                    echo "EC2 SSH did not become ready in time"
                    exit 1
                '''
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
            echo "Build, infra apply, and deployment successful: ${IMAGE_NAME}:${IMAGE_TAG} on ${EC2_HOST}"
        }
        failure {
            echo 'Pipeline failed. Check Terraform apply/output, AWS credentials, SSH credentials, or deploy script logs.'
        }
    }
}
