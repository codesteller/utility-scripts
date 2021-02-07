
# Save current working directory
cwd=$(pwd)

sudo apt update
sudo apt -y upgrade

# Install packages to allow apt to use a repository over HTTPS
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Verify that you now have the key with the fingerprint
sudo apt-key fingerprint 0EBFCD88

# Get Docker CE for Ubuntu
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io


# Uninstall Docker
# sudo apt-get remove docker docker-engine docker.io

# NVIDIA Docker for Ubuntu 16.04/18.04, Debian Jessie/Stretch/Buster
# Add the package repositories
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
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
sudo docker run --gpus all nvidia/cuda:10.2-base nvidia-smi

