#!/bin/bash
set -euxo pipefail

EC2_IP="$1"
IMAGE_NAME="$2"
TAG="$3"

ssh -o BatchMode=yes -o StrictHostKeyChecking=no "ubuntu@${EC2_IP}" /bin/bash <<EOF
set -euxo pipefail
echo "Connected to \$(hostname)"
sudo -n systemctl start docker
sudo -n docker pull ${IMAGE_NAME}:${TAG}
sudo -n docker images
sudo -n docker stop flask-app || true
sudo -n docker rm flask-app || true
sudo -n docker run -d --name flask-app -p 5000:5000 --restart unless-stopped ${IMAGE_NAME}:${TAG}
sudo -n docker ps -a
EOF
