#!/usr/bin/bash
# Save current working directory
cwd=$(pwd)

sudo apt -y update
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
sudo apt-get install docker-ce


# Uninstall Docker
# sudo apt-get remove docker docker-engine docker.io
