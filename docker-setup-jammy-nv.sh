# Save current working directory
cwd=$(pwd)

sudo apt update
sudo apt -y upgrade

# Install packages to allow apt to use a repository over HTTPS
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y

# Install Docker CE
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
apt-cache policy docker-ce
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# # NVIDIA Docker for Ubuntu 22.04, Debian Buster
# Add the package repositories
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit

# Check Installation
sudo systemctl start docker
sudo systemctl enable docker

docker --version

### Restart docker service, else following error may come
## docker: Error response from daemon: could not select device driver "" with capabilities: [[gpu]].
## ERRO[0028] error waiting for container: context canceled
sudo systemctl restart docker

# Add to sudoer's list
sudo groupadd docker
sudo usermod -aG docker $USER

#### Test nvidia-smi with the latest official CUDA image
sudo docker run --gpus all nvcr.io/nvidia/cuda:11.8.0-devel-ubuntu20.04 nvidia-smi
