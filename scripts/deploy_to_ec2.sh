#!/bin/bash

EC2_IP=$1
IMAGE_NAME=$2
TAG=$3

ssh -o StrictHostKeyChecking=no ubuntu@$EC2_IP << EOF

# Pull latest image
docker pull $IMAGE_NAME:$TAG

# Stop old container (if exists)
docker stop flask-app || true

# Remove old container
docker rm flask-app || true

# Run new container
docker run -d \
  --name flask-app \
    -p 5000:5000 \
      --restart unless-stopped \
  $IMAGE_NAME:$TAG

EOF
