#!/bin/bash
sudo apt update && sudo apt -y upgrade

# Download and Install CMake
cmake_version=3.29.9
wget "https://github.com/Kitware/CMake/releases/download/v${cmake_version}/cmake-${cmake_version}-linux-$(uname -m).tar.gz"
tar -xvf cmake-${cmake_version}-linux-x86_64.tar.gz
mkdir cmake && mv cmake-${cmake_version}-linux-x86_64 cmake/${cmake_version}
sudo mv -f cmake /opt/
echo 'export cmake_version=3.27.0' >> ~/.bashrc 
echo 'export PATH=/opt/cmake/${cmake_version}/bin:$PATH' >> ~/.bashrc 

# TO use CH40 drivers for Arduino and other US drivers, it is 
# good idea to remove britty (Unless you are using a braille display)
sudo apt remove brltty -y

# Base Python
sudo apt install -y python3-dev python3-pip python3-venv

# Install Mamba/Conda Python
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh -b -p "${HOME}/Apsoft/miniforge3"
### Add path to bashrc
echo "function env_conda()  {" | tee -a ~/.bashrc > /dev/null
echo '    source "${HOME}/Apsoft/miniforge3/etc/profile.d/conda.sh"' | tee -a ~/.bashrc > /dev/null
echo '    source "${HOME}/Apsoft/miniforge3/etc/profile.d/mamba.sh"' | tee -a ~/.bashrc > /dev/null
echo '    mamba activate' | tee -a ~/.bashrc > /dev/null
echo '} ' | tee -a ~/.bashrc > /dev/null

# Dev Utilities
sudo apt install terminator tmux neofetch neovim openssh-server -y
sudo snap install sublime-text --classic
sudo snap install code --classic
sudo snap install btop
