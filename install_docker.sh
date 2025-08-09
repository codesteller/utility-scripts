#!/bin/bash
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
apt-cache policy docker-ce
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
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt update && sudo apt install nvidia-docker2

# Restart Docker
sudo systemctl restart docker
sudo service docker restart

sudo docker info | grep Runtime

# Test nvidia-smi with the latest official CUDA image
sudo docker run --gpus all nvcr.io/nvidia/cuda:latest nvidia-smi

