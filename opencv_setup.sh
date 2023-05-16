
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
git checkout 4.5.3
cd ..

cd "$cwd"
 
git clone https://github.com/opencv/opencv_contrib.git
cd opencv_contrib 
git checkout 4.5.3
cd ..

cd "$cwd"

cd opencv
mkdir build
cd build

# Mention -DPYTHON3_EXECUTABLE=/home/codesteller/apsoft/anaconda3/envs/py35dev/bin/python when multiple python3 present
# cmake -DCMAKE_BUILD_TYPE=RELEASE -DENABLE_PRECOMPILED_HEADERS=OFF -DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules -DBUILD_EXAMPLES=ON -DWITH_CUDA=ON -DCMAKE_INSTALL_PREFIX=../../install/ ..
# cmake -DCMAKE_BUILD_TYPE=RELEASE -DENABLE_PRECOMPILED_HEADERS=OFF -DWITH_QT=ON -DWITH_OPENGL=ON -DWITH_TBB=ON -DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules -DBUILD_EXAMPLES=ON -DWITH_CUDA=ON -DCMAKE_INSTALL_PREFIX=../../install/ -D PYTHON3_EXECUTABLE=/home/codesteller/apsoft/anaconda3/envs/py35dev/bin/python ..
cmake \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=../../cv2_4.6 \
    -D INSTALL_PYTHON_EXAMPLES=ON \
    -D INSTALL_C_EXAMPLES=ON \
    -D WITH_TBB=ON \
    -D WITH_CUDA=ON \
    -D BUILD_opencv_cudacodec=ON \
    -D ENABLE_FAST_MATH=1 \
    -D CUDA_FAST_MATH=1 \
    -D WITH_CUBLAS=1 \
    -D WITH_V4L=ON \
    -D WITH_QT=ON \
    -D WITH_OPENGL=ON \
    -D WITH_GSTREAMER=ON \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D OPENCV_PC_FILE_NAME=opencv.pc \
    -D OPENCV_ENABLE_NONFREE=ON \
    -D BUILD_opencv_python3=ON \
    -D OPENCV_PYTHON3_INSTALL_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
    -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
    -D PYTHON_EXECUTABLE=$(which python3) \
    -D BUILD_EXAMPLES=ON ..


make -j$(nproc)
make install

# Now Add the Paths
# export LD_LIBRARY_PATH=$HOME/apsoft/mlstack/opencv/install/lib:$LD_LIBRARY_PATH
# export PYTHONPATH="$HOME/apsoft/mlstack/opencv/install/lib/python3.6/site-packages:$PYTHONPATH"
