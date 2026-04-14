pipeline {
    agent any

    environment {
        IMAGE_NAME         = 'rajugsk20/devops-flask-app'
        IMAGE_TAG          = "${BUILD_NUMBER}"
        AWS_DEFAULT_REGION = 'eu-west-2'
        TERRAFORM_DIR      = 'terraform'
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '15'))
    }

    stages {
        stage('Build Docker Image') {
            steps {
                sh '''#!/bin/bash
set -euxo pipefail
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f app/Dockerfile app
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
'''
            }
        }

        stage('Login to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'DockerHub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''#!/bin/bash
set -euxo pipefail
echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
'''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''#!/bin/bash
set -euxo pipefail
docker push ${IMAGE_NAME}:${IMAGE_TAG}
docker push ${IMAGE_NAME}:latest
'''
            }
        }

        stage('Check AWS Access') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-creds'
                ]]) {
                    sh '''#!/bin/bash
set -euxo pipefail
aws sts get-caller-identity
'''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-creds'
                ]]) {
                    sh '''#!/bin/bash
set -euxo pipefail
cd ${TERRAFORM_DIR}
terraform init -reconfigure
'''
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-creds'
                ]]) {
                    sh '''#!/bin/bash
set -euxo pipefail
cd ${TERRAFORM_DIR}
terraform validate
'''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-creds'
                ]]) {
                    sh '''#!/bin/bash
set -euxo pipefail
cd ${TERRAFORM_DIR}
terraform apply -auto-approve
'''
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
                            script: '''#!/bin/bash
set -euo pipefail
cd ${TERRAFORM_DIR}
IP=$(terraform output -raw instance_public_ip 2>/dev/null || true)
if [ -z "$IP" ]; then
  echo "ERROR: instance_public_ip output is empty"
  exit 1
fi
echo "$IP"
''',
                            returnStdout: true
                        ).trim()

                        echo "EC2_HOST resolved to: ${env.EC2_HOST}"
                    }
                }
            }
        }

        stage('Wait for EC2 SSH') {
            steps {
                sh '''#!/bin/bash
set -euxo pipefail
echo "Waiting for SSH on ${EC2_HOST}..."
for i in $(seq 1 18); do
  if nc -z ${EC2_HOST} 22; then
    echo "SSH is ready on ${EC2_HOST}"
    exit 0
  fi
  echo "Attempt $i/18: SSH not ready yet, sleeping 10s..."
  sleep 10
done
echo "ERROR: EC2 SSH did not become ready in time"
exit 1
'''
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh '''#!/bin/bash
set -euxo pipefail
bash ./scripts/deploy_to_ec2.sh ${EC2_HOST} ${IMAGE_NAME} ${IMAGE_TAG}
'''
                }
            }
        }

stage('Get ALB DNS') {
    steps {
        withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws-jenkins-creds'
        ]]) {
            script {
                env.ALB_DNS = sh(
                    script: '''#!/bin/bash
set -euo pipefail
cd ${TERRAFORM_DIR}
DNS=$(terraform output -raw alb_dns_name 2>/dev/null || true)
if [ -z "$DNS" ]; then
  echo "ERROR: alb_dns_name output is empty"
  exit 1
fi
echo "$DNS"
''',
                    returnStdout: true
                ).trim()

                echo "ALB_DNS resolved to: ${env.ALB_DNS}"
            }
        }
    }
}

stage('Health Check') {
    steps {
        sh '''#!/bin/bash
set -euxo pipefail
for i in $(seq 1 18); do
  if curl -fsS http://${ALB_DNS} > /dev/null; then
    echo "Application is healthy through ALB"
    exit 0
  fi
  echo "Health check failed, retrying in 10s..."
  sleep 10
done
echo "ERROR: Application health check through ALB failed"
exit 1
'''
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
            echo 'Pipeline failed. Check Terraform, AWS credentials, SSH access, deploy script, or app health.'
        }
    }
}
}
