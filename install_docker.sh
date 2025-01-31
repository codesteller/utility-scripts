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
