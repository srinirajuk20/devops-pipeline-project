#!/bin/bash

EC2_IP=$1
IMAGE_NAME=$2
IMAGE_TAG=$3

echo "Deploying to EC2: $EC2_IP"

ssh -o StrictHostKeyChecking=no ubuntu@$EC2_IP << EOF

echo "Updating packages..."
sudo apt update -y

echo "Installing Docker if not present..."
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

echo "Installing Nginx..."
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

echo "Stopping old container if exists..."
sudo docker rm -f flask-app || true

echo "Pulling latest image..."
sudo docker pull $IMAGE_NAME:$IMAGE_TAG

echo "Running container..."
sudo docker run -d -p 5000:5000 --name flask-app $IMAGE_NAME:$IMAGE_TAG

echo "Configuring Nginx reverse proxy..."

sudo -n tee /etc/nginx/sites-available/default > /dev/null <<'EONGINX'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EONGINX

echo "Restarting Nginx..."
sudo systemctl restart nginx

echo "Deployment completed!"

EOF
