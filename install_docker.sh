#!/bin/bash
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common 
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker --version

# Check Installation
sudo systemctl start docker
sudo systemctl enable docker

docker --version

sudo systemctl restart docker

# Add to sudoer's list
sudo groupadd docker
sudo usermod -aG docker $USER

# Test Docker
sudo docker run --rm ubuntu:latest uname -a

# # NVIDIA Docker for Ubuntu 22.04, Debian Buster
# Add the package repositories
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit

# Restart Docker
sudo systemctl restart docker

# Test nvidia-smi with the latest official CUDA image
sudo docker run --gpus all nvcr.io/nvidia/cuda:latest nvidia-smi

