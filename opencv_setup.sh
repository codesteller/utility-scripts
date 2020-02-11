
# Save current working directory
cwd=$(pwd)

sudo apt -y update
sudo apt -y upgrade

# Install Dependencies
## Install dependencies
sudo apt -y install build-essential checkinstall cmake pkg-config yasm
sudo apt -y install git gfortran
sudo apt -y install libjpeg8-dev libpng-dev
 
sudo apt -y install software-properties-common
sudo add-apt-repository "deb http://security.ubuntu.com/ubuntu xenial-security main"
sudo apt -y update
 
sudo apt -y install libjasper1
sudo apt -y install libtiff-dev
 
sudo apt -y install libavcodec-dev libavformat-dev libswscale-dev libdc1394-22-dev
sudo apt -y install libxine2-dev libv4l-dev
cd /usr/include/linux
sudo ln -s -f ../libv4l1-videodev.h videodev.h
cd "$cwd"
 
sudo apt -y install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
sudo apt -y install libgtk2.0-dev libtbb-dev qt5-default
sudo apt -y install libatlas-base-dev
sudo apt -y install libfaac-dev libmp3lame-dev libtheora-dev
sudo apt -y install libvorbis-dev libxvidcore-dev
sudo apt -y install libopencore-amrnb-dev libopencore-amrwb-dev
sudo apt -y install libavresample-dev
sudo apt -y install x264 v4l-utils
 
# Optional dependencies
sudo apt -y install libprotobuf-dev protobuf-compiler
sudo apt -y install libgoogle-glog-dev libgflags-dev
sudo apt -y install libgphoto2-dev libeigen3-dev libhdf5-dev doxygen

# Setup Opencv

git clone https://github.com/opencv/opencv.git
cd opencv
git checkout 4.1.1
cd ..

cd "$cwd"
 
git clone https://github.com/opencv/opencv_contrib.git
cd opencv_contrib 
git checkout 4.1.1
cd ..

cd "$cwd"

cd opencv
mkdir build
cd build

cmake -DCMAKE_BUILD_TYPE=RELEASE -DENABLE_PRECOMPILED_HEADERS=OFF -DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules -DBUILD_EXAMPLES=ON -DWITH_CUDA=ON -DCMAKE_INSTALL_PREFIX=../../../install/ ..
make -j$(nproc)
make install

# Now Add the Paths
# export LD_LIBRARY_PATH=$HOME/apsoft/mlstack/opencv/install/lib:$LD_LIBRARY_PATH
# export PYTHONPATH="$HOME/apsoft/mlstack/opencv/install/lib/python3.6/site-packages:$PYTHONPATH"
