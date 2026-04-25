#!/bin/bash
set -euo pipefail

EC2_IP="$1"
IMAGE_NAME="$2"
IMAGE_TAG="$3"
COLOR="${4:-blue}"

CONTAINER_NAME="flask-app-${COLOR}"

echo "Deploying ${IMAGE_NAME}:${IMAGE_TAG} to ${EC2_IP} (${COLOR})"

ssh -o BatchMode=yes -o StrictHostKeyChecking=no "ubuntu@${EC2_IP}" /bin/bash <<EOF
set -euo pipefail

echo "Connected to \$(hostname)"

echo "Updating packages..."
sudo apt update -y

echo "Installing Docker if not present..."
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

echo "Installing Nginx if not present..."
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

echo "Stopping old container if exists..."
sudo docker stop ${CONTAINER_NAME} || true
sudo docker rm ${CONTAINER_NAME} || true

echo "Pulling image..."
sudo docker pull ${IMAGE_NAME}:${IMAGE_TAG}

echo "Running container..."
sudo docker run -d \
  --name ${CONTAINER_NAME} \
  --restart unless-stopped \
  -p 5000:5000 \
  ${IMAGE_NAME}:${IMAGE_TAG}

echo "Writing Nginx reverse proxy config..."
sudo tee /etc/nginx/sites-available/default > /dev/null <<'EONGINX'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EONGINX

echo "Validating Nginx config..."
sudo nginx -t

echo "Restarting Nginx..."
sudo systemctl restart nginx

echo "Checking local container health..."
curl -fsS http://127.0.0.1:5000 >/dev/null

echo "Checking local Nginx health..."
curl -fsS http://127.0.0.1 >/dev/null

echo "Deployment completed successfully for ${CONTAINER_NAME}"
EOF
