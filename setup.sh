#!/bin/bash

cmake_version=3.27.0

sudo apt update && sudo apt install locales -y
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

sudo apt update && sudo apt upgrade -y
sudo apt install build-essential software-properties-common git -y

# Download and Install CMake
wget https://github.com/Kitware/CMake/releases/download/v${cmake_version}/cmake-${cmake_version}-linux-x86_64.tar.gz
tar -xvf cmake-${cmake_version}-linux-x86_64.tar.gz
mkdir cmake && mv cmake-${cmake_version}-linux-x86_64 cmake/${cmake_version}
sudo mv cmake /opt/
echo 'export cmake_version=3.27.0' >> ~/.bashrc 
export PATH=$PATH:/opt/cmake/${cmake_version}/bin' >> ~/.bashrc 

# Audio & Video Utils
sudo apt install v4l-utils -y
sudo apt install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools \
  gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio -y

# Dev Utilities
sudo apt install terminator tmux neofetch neovim openssh-server -y
sudo snap install sublime-text --classic
sudo snap install code --classic
sudo snap install btop
