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
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:${IMAGE_TAG}
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
docker push ${IMAGE_NAME}:${IMAGE_TAG}
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
terraform apply -auto-approve -var="image_name=${IMAGE_NAME}" -var="image_tag=${IMAGE_TAG}"
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

        stage('Health Check via ALB') {
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
    }

    post {
        always {
            sh 'docker logout || true'
        }
        success {
            echo "Build, infra apply, and deployment successful: ${IMAGE_NAME}:${IMAGE_TAG} via ${ALB_DNS}"
        }
        failure {
            echo 'Pipeline failed. Check Docker build/push, Terraform apply, ALB health, or instance bootstrap.'
        }
    }
}
