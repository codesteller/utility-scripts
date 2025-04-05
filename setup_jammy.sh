#!/bin/bash

sudo apt update && sudo apt upgrade -y

cmake_version=3.27.0

sudo apt update && sudo apt install locales -y
sudo locale-gen en_IN en_IN.UTF-8
sudo update-locale LC_ALL=en_IN.UTF-8 LANG=en_IN.UTF-8
export LANG=en_IN.UTF-8

sudo apt update && sudo apt upgrade -y
sudo apt install build-essential software-properties-common git -y

# Download and Install CMake
wget https://github.com/Kitware/CMake/releases/download/v${cmake_version}/cmake-${cmake_version}-linux-x86_64.tar.gz
tar -xvf cmake-${cmake_version}-linux-x86_64.tar.gz
mkdir cmake && mv cmake-${cmake_version}-linux-x86_64 cmake/${cmake_version}
sudo mv -f cmake /opt/
echo 'export cmake_version=3.27.0' >> ~/.bashrc 
echo 'export PATH=/opt/cmake/${cmake_version}/bin:$PATH' >> ~/.bashrc 

# TO use CH40 drivers for Arduino and other US drivers, it is 
# good idea to remove britty (Unless you are using a braille display)
sudo apt remove brltty -y

# Dev Utilities
sudo apt install terminator tmux neofetch neovim openssh-server -y
sudo snap install sublime-text --classic
sudo snap install code --classic
sudo snap install btop

# Base Python
sudo apt install -y python3-dev python3-pip python3-venv

# Install Python
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh -b -p "${HOME}/Apsoft/miniforge3"
### Add path to bashrc
echo "function env_conda()  {" | tee -a ~/.bashrc > /dev/null
echo '    source "${HOME}/Apsoft/miniforge3/etc/profile.d/conda.sh"' | tee -a ~/.bashrc > /dev/null
echo '    source "${HOME}/Apsoft/miniforge3/etc/profile.d/mamba.sh"' | tee -a ~/.bashrc > /dev/null
echo '    mamba activate' | tee -a ~/.bashrc > /dev/null
echo '} ' | tee -a ~/.bashrc > /dev/null

# Audio & Video Utils
sudo apt install -y v4l-utils ffmpeg
sudo apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools \
  gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio
