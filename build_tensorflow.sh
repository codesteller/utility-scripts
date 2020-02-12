
# Save current working directory
cwd=$(pwd)

sudo apt install python-dev python-pip python3-dev python3-pip

pip install -U --user pip six numpy wheel setuptools mock 'future>=0.17.1'
pip install -U --user keras_applications --no-deps
pip install -U --user keras_preprocessing --no-deps

# Prerequisites
# 1. install bazel - 
# tensorflow_gpu-1.14.0 requires Bazel 0.24.1 & tensorflow_gpu-1.12.0 requires Bazel 0.15.1

sudo apt install g++ unzip zip
sudo apt-get install openjdk-11-jdk

# wget https://github.com/bazelbuild/bazel/releases/download/0.24.1/bazel-0.24.1-installer-linux-x86_64.sh
#chmod +x bazel-0.24.1-installer-linux-x86_64.sh 
#./bazel-0.24.1-installer-linux-x86_64.sh --user

export PATH="$PATH:$HOME/bin"

# Build Tensorflow

git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
git checkout r1.14

./configure
bazel build --config=mkl --config=noignite --config=nokafka --config=nonccl --config=opt --config=cuda //tensorflow/tools/pip_package:build_pip_package
./bazel-bin/tensorflow/tools/pip_package/build_pip_package ./pip_package/tensorflow_pkg --gpu