#!/bin/bash
set -euxo pipefail

EC2_IP="$1"
IMAGE_NAME="$2"
TAG="$3"
KEY_PATH="$4"

ssh -i "$KEY_PATH" -tt -o StrictHostKeyChecking=no "ubuntu@${EC2_IP}" <<EOF
set -euxo pipefail
echo "Connected to \$(hostname)"
sudo systemctl start docker
sudo docker pull ${IMAGE_NAME}:${TAG}
sudo docker images
sudo docker stop flask-app || true
sudo docker rm flask-app || true
sudo docker run -d --name flask-app -p 5000:5000 --restart unless-stopped ${IMAGE_NAME}:${TAG}
sudo docker ps -a
EOF
