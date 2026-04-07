#!/bin/bash
set -e

EC2_HOST=$1
IMAGE_NAME=$2
IMAGE_TAG=$3

ssh -o StrictHostKeyChecking=no ubuntu@"$EC2_HOST" << EOF
  sudo docker rm -f flask-app || true
  sudo docker pull ${IMAGE_NAME}:${IMAGE_TAG}
  sudo docker run -d -p 5000:5000 --name flask-app ${IMAGE_NAME}:${IMAGE_TAG}
EOF
