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

        stage('Prepare Green (Blue stays live)') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-creds'
                ]]) {
                    sh """#!/bin/bash
set -euxo pipefail
cd ${TERRAFORM_DIR}

terraform apply -auto-approve \\
  -var="image_name=${IMAGE_NAME}" \\
  -var="image_tag=${IMAGE_TAG}" \\
  -var="active_color=blue" \\
  -var="blue_desired_capacity=1" \\
  -var="blue_min_size=1" \\
  -var="green_desired_capacity=1" \\
  -var="green_min_size=1"
"""
                }
            }
        }

        stage('Show Terraform Outputs') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-creds'
                ]]) {
                    sh '''#!/bin/bash
set -euxo pipefail
cd ${TERRAFORM_DIR}
terraform output
'''
                }
            }
        }

        stage('Get Green Target Group ARN') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-creds'
                ]]) {
                    script {
                        env.GREEN_TG_ARN = sh(
                            script: '''#!/bin/bash
set -euo pipefail
cd ${TERRAFORM_DIR}
terraform output -raw green_target_group_arn
''',
                            returnStdout: true
                        ).trim()
                        echo "GREEN_TG_ARN resolved to: ${env.GREEN_TG_ARN}"
                    }
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
terraform output -raw alb_dns_name
''',
                            returnStdout: true
                        ).trim()
                        echo "ALB_DNS resolved to: ${env.ALB_DNS}"
                    }
                }
            }
        }

        stage('Wait for Green Health') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-creds'
                ]]) {
                    sh '''#!/bin/bash
set -euxo pipefail

echo "Waiting for Green target group to become healthy..."

for i in $(seq 1 30); do
  HEALTHY_COUNT=$(aws elbv2 describe-target-health \
    --target-group-arn "${GREEN_TG_ARN}" \
    --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`]' \
    --output json | python3 -c 'import sys, json; print(len(json.load(sys.stdin)))')

  echo "Healthy Green targets: ${HEALTHY_COUNT}"

  if [ "${HEALTHY_COUNT}" -ge 1 ]; then
    echo "Green target group is healthy"
    exit 0
  fi

  echo "Green not healthy yet, retrying in 20 seconds..."
  sleep 20
done

echo "ERROR: Green target group did not become healthy in time"
exit 1
'''
                }
            }
        }

        stage('Switch Traffic to Green') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-creds'
                ]]) {
                    sh """#!/bin/bash
set -euxo pipefail
cd ${TERRAFORM_DIR}

terraform apply -auto-approve \\
  -var="image_name=${IMAGE_NAME}" \\
  -var="image_tag=${IMAGE_TAG}" \\
  -var="active_color=green" \\
  -var="blue_desired_capacity=1" \\
  -var="blue_min_size=1" \\
  -var="green_desired_capacity=1" \\
  -var="green_min_size=1"
"""
                }
            }
        }

        stage('Health Check via ALB') {
            steps {
                sh '''#!/bin/bash
set -euxo pipefail
for i in $(seq 1 24); do
  if curl -fsS http://${ALB_DNS} > /dev/null; then
    echo "Application is healthy through ALB"
    exit 0
  fi
  echo "ALB health check failed, retrying in 10s..."
  sleep 10
done
echo "ERROR: Application health check through ALB failed"
exit 1
'''
            }
        }

        stage('Scale Down Blue') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-creds'
                ]]) {
                    sh """#!/bin/bash
set -euxo pipefail
cd ${TERRAFORM_DIR}

terraform apply -auto-approve \\
  -var="image_name=${IMAGE_NAME}" \\
  -var="image_tag=${IMAGE_TAG}" \\
  -var="active_color=blue" \\
  -var="blue_desired_capacity=1" \\
  -var="blue_min_size=1" \\
  -var="blue_max_size=2" \\
  -var="green_desired_capacity=1" \\
  -var="green_min_size=1" \\
  -var="green_max_size=2" 
"""
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
        success {
            echo "Blue/Green deployment successful: ${IMAGE_NAME}:${IMAGE_TAG} live on green via ${ALB_DNS}. Blue scaled down."
        }
        failure {
            echo 'Pipeline failed safely. Blue should still remain live unless the failure happened after traffic switch.'
        }
    }
}
