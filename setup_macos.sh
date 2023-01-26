#!/bin/bash

# Setup Brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Sublime, VSCode, Tabby
brew install --cask sublime-text
brew install --cask tabby
brew install --cask visual-studio-code
brew install imagemagick
brew install cmake 
brew install wget
brew install zlib zlib-ng

# Install Mambaforge Python -
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
bash Mambaforge-$(uname)-$(uname -m).sh

# now create a new environment
mamba create -n ros_env python=3.9
conda activate ros_env

# this adds the conda-forge channel to the new created environment configuration 
conda config --env --add channels conda-forge
# and the robostack channels
conda config --env --add channels robostack
conda config --env --add channels robostack-experimental
conda config --env --add channels robostack-humble

# Install the version of ROS you are interested in:
mamba install ros-humble-desktop  # (or "mamba install ros-noetic-desktop" or "mamba install ros-galactic-desktop")

# optionally, install some compiler packages if you want to e.g. build packages in a colcon_ws:
mamba install compilers cmake pkg-config make ninja colcon-common-extensions

# Add Rosdep
conda deactivate
conda activate ros_env

# if you want to use rosdep, also do:
mamba install rosdep
rosdep init  # note: do not use sudo!
rosdep update
