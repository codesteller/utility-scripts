#!/bin/bash
# Versions
cmake_version=3.31.5

sudo apt update && sudo apt upgrade -y
sudo apt install build-essential software-properties-common git curl wget apt-transport-https -y

# Download and Install CMake
wget https://github.com/Kitware/CMake/releases/download/v${cmake_version}/cmake-${cmake_version}-linux-x86_64.tar.gz
tar -xvf cmake-${cmake_version}-linux-x86_64.tar.gz
mkdir cmake && mv cmake-${cmake_version}-linux-x86_64 cmake/${cmake_version}
sudo mv -f cmake /opt/
echo 'export cmake_version=3.31.5' >> ~/.bashrc 
echo 'export PATH=/opt/cmake/${cmake_version}/bin:$PATH' >> ~/.bashrc 

# TO use CH40 drivers for Arduino and other US drivers, it is 
# good idea to remove britty (Unless you are using a braille display)
sudo apt remove brltty -y

# Dev Utilities
sudo apt install terminator tmux neofetch neovim tmux openssh-server -y
sudo snap install sublime-text --classic
sudo snap install code --classic
sudo snap install btop 

# Base Python
sudo apt install -y python3-dev python3-pip python3-venv

# Audio & Video Utils
sudo apt install -y v4l-utils ffmpeg 

# Install ROS Humble
curl -sL https://raw.githubusercontent.com/codesteller/utility-scripts/refs/heads/master/install-ros-humble-jammy.sh | bash

# Install Docker
curl -sL https://raw.githubusercontent.com/codesteller/utility-scripts/refs/heads/master/docker_setup_jammy.sh | bash

# Change the Boot Screen 
curl -sL https://raw.githubusercontent.com/codesteller/utility-scripts/refs/heads/master/change_boot_screen.sh | bash
