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
# Test Docker setup
sudo docker run --rm ubuntu:latest bash -c "uname -a"
