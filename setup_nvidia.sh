#!/bin/bash
set -e
#
# NVIDIA Drivers + CUDA installation script for Ubuntu
# Based on: https://docs.nvidia.com/cuda/cuda-installation-guide-linux/
#
echo ">>> Checking for NVIDIA GPU..."
if ! lspci  -nn | grep -i 10de; then
  echo "❌ No NVIDIA GPU detected. Exiting."
  exit 1
fi

echo ">>> Updating system..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo ">>> Installing prerequisites..."
sudo apt-get install -y build-essential dkms \
    software-properties-common apt-transport-https \
    ca-certificates curl gnupg lsb-release
    
echo ">>> Adding NVIDIA CUDA repository..."
# Add NVIDIA package repository key
curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu$(lsb_release -sr | sed -e 's/\.//')/x86_64/3bf863cc.pub | sudo gpg --dearmor -o /usr/share/keyrings/cuda-archive-keyring.gpg

# Add CUDA repository (adjust for Ubuntu version, e.g., 2204 for 22.04, 2004 for 20.04)
UBUNTU_VERSION=$(lsb_release -sr | sed -e 's/\.//')
echo "deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_VERSION}/x86_64/ /" | sudo tee /etc/apt/sources.list.d/cuda.list

echo ">>> Updating package index again..."
sudo apt-get update -y

echo ">>> Installing NVIDIA drivers and CUDA..."
# This installs both the driver + CUDA toolkit
sudo apt-get -y install cuda

echo "############# DOCKER INSTALLATION COMPLETED SUCCESSFULLY #############"
echo ">>> Reboot required to load NVIDIA drivers."
echo ">>> Run 'nvidia-smi' after reboot to confirm."