# Save current working directory
cv2_dir=${HOME}/Apsoft/cv2/
mkdir "$cv2_dir"
cd $cv2_dir
cv_version="4.8.1"

cwd=$(pwd)

sudo apt -y update
sudo apt -y upgrade

## Install dependencies
sudo apt -y install build-essential checkinstall cmake pkg-config yasm
sudo apt -y install git gfortran
sudo apt -y install libjpeg8-dev libpng-dev
 
sudo apt -y install software-properties-common
sudo apt -y update

sudo apt -y install libtiff-dev
sudo apt -y install libomp-dev
sudo apt -y install libavcodec-dev libavformat-dev libswscale-dev libdc1394-dev
sudo apt -y install libxine2-dev libv4l-dev
cd /usr/include/linux
sudo ln -s -f ../libv4l1-videodev.h videodev.h
cd "$cwd"
 
sudo apt -y install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
sudo apt -y install libgtk2.0-dev libtbb-dev qtcreator qtbase5-dev qt5-qmake
sudo apt -y install libatlas-base-dev
sudo apt -y install libfaac-dev libmp3lame-dev libtheora-dev
sudo apt -y install libvorbis-dev libxvidcore-dev
sudo apt -y install libopencore-amrnb-dev libopencore-amrwb-dev
sudo apt -y install libavcodec-dev libavcodec-extra
sudo apt -y install x264 v4l-utils
 
# Optional dependencies
sudo apt -y install libprotobuf-dev protobuf-compiler
sudo apt -y install libgoogle-glog-dev libgflags-dev
sudo apt -y install libgphoto2-dev libeigen3-dev libhdf5-dev doxygen

# Install Java
sudo apt -y install default-jre default-jdk 
# Setup Opencv

git clone https://github.com/opencv/opencv.git
cd opencv
git checkout $cv_version
cd ..

cd "$cwd"
 
git clone https://github.com/opencv/opencv_contrib.git
cd opencv_contrib 
git checkout $cv_version
cd ..

# Version 4.7 onwards the cuda build is failing due to Problem building OpenCV with FP16 CUDA support from source files with Cmake (Python)
# For that change the source files region.hpp and normalize.hpp as descripbed by @Zacrain in Link below
# https://github.com/opencv/opencv/issues/23893#issuecomment-1631143736


# Build Opencv
cd "$cwd"

cd opencv
mkdir build
cd build

# If Building with conda environment please activate the environment now; 
# Make sure numpy is installed in the environment
cmake \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/opt/opencv/4.8.1 \
    -D INSTALL_PYTHON_EXAMPLES=ON \
    -D INSTALL_C_EXAMPLES=ON \
    -D WITH_TBB=ON \
    -D WITH_OPENMP=ON \
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
    -D PYTHON_INCLUDE_DIR=$(python3 -c "import sysconfig; print(sysconfig.get_path('include'))")  \
    -D PYTHON_LIBRARY=$(python3 -c "import sysconfig; print(sysconfig.get_config_var('LIBDIR'))") \
    -D OPENCV_PYTHON3_INSTALL_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
    -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
    -D PYTHON_EXECUTABLE=$(which python3) \
    -D BUILD_EXAMPLES=ON ..

make -j$(nproc)
sudo make install

# Now Add the Paths
# export LD_LIBRARY_PATH=/opt/opencv/4.8.1/install/lib:$LD_LIBRARY_PATH
# export PYTHONPATH=/optopencv/4.8.1/install/lib/python3.x/site-packages:$PYTHONPATH"
