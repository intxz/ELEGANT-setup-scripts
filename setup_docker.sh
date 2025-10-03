#!/bin/bash
set -e

#
# Docker installation script for Ubuntu
# Based on: https://docs.docker.com/engine/install/ubuntu/
#

echo ">>> Installing prerequisites..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release

echo ">>> Adding Docker’s official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

ARCH=$(dpkg --print-architecture)
CODENAME=$(lsb_release -cs)
echo "Architecture detected: $ARCH"
echo "Ubuntu codename detected: $CODENAME"

echo ">>> Adding Docker repository..."
echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo ">>> Updating package index..."
sudo apt-get update -y

echo ">>> Installing Docker Engine and plugins..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo ">>> Running test container..."
sudo docker run --rm hello-world

echo ">>> Adding current user to docker group (requires re-login)..."
sudo usermod -aG docker $USER

echo "############# DOCKER INSTALLATION COMPLETED SUCCESSFULLY #############"