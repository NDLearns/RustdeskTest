#!/bin/bash
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (e.g., using sudo)"
  exit 1
fi

echo "=========================================="
echo "  Updating system packages..."
echo "=========================================="
apt-get update -y && apt-get upgrade -y

echo "=========================================="
echo "  Installing prerequisites..."
echo "=========================================="
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg2 \
  lsb-release \
  software-properties-common

echo "=========================================="
echo "  Adding Docker’s official GPG key and repository..."
echo "=========================================="
# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | apt-key add -

# Set up the Docker repository. Adjust the repository URL if necessary.
DOCKER_REPO="deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") $(lsb_release -cs) stable"
add-apt-repository "$DOCKER_REPO"

echo "=========================================="
echo "  Installing Docker Engine..."
echo "=========================================="
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

echo "=========================================="
echo "  Enabling and starting Docker service..."
echo "=========================================="
systemctl enable docker
systemctl start docker

echo "=========================================="
echo "  Pulling the latest Portainer image..."
echo "=========================================="
docker pull portainer/portainer-ce:latest

echo "=========================================="
echo "  Creating a Docker volume for Portainer data..."
echo "=========================================="
docker volume create portainer_data

echo "=========================================="
echo "  Deploying Portainer container..."
echo "=========================================="
docker run -d \
  -p 8000:8000 \
  -p 9443:9443 \
  --name portainer \
  --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

echo "=========================================="
echo "Installation complete!"
echo "Access Portainer via your browser at: https://<your-container-IP>:9443"
