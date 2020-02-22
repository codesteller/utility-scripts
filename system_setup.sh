#
# Install CUDA Toolkit - 10.2
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin
sudo mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget http://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda-repo-ubuntu1804-10-2-local-10.2.89-440.33.01_1.0-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu1804-10-2-local-10.2.89-440.33.01_1.0-1_amd64.deb
sudo apt-key add /var/cuda-repo-10-2-local-10.2.89-440.33.01/7fa2af80.pub
sudo apt-get update
sudo apt-get -y install cuda

# Install GIT
sudo apt-get install git

# Install Bazel
wget https://github.com/bazelbuild/bazel/releases/download/0.24.1/bazel-0.24.1-installer-linux-x86_64.sh
chmod +x bazel-0.24.1-installer-linux-x86_64.sh 
./bazel-0.24.1-installer-linux-x86_64.sh --user

# Install CUDNN
# Download CUDNN - wget https://developer.download.nvidia.com/compute/machine-learning/cudnn/secure/7.6.5.32/Production/10.2_20191118/cudnn-10.2-linux-x64-v7.6.5.32.tgz?cYGns-qA6DjyhIGnobmyWYN4AatcWXgZ3QfwivlvD8DfvRZ5vjaPqcd-XKQ3LPwTbAZuyuLQXKEqZtSXNO8A8q1Mj-o6X601GsJPDL3hago2GU0sItU628KZ2MDGk-PrF5LOYCbqI4TqOxcZS85MVWdwA8TBqChYhrm-iiNnYnZ-QMVWJGb0RXPHch0o6GDexJGnPUpdgtKYUWIIMlH0VoQiuxy6zu-tyA
tar -xzvf cudnn-10.2-linux-x64-v7.6.5.32.tgz
sudo cp cuda/include/cudnn.h /usr/local/cuda/include
sudo cp cuda/lib64/libcudnn* /usr/local/cuda/lib64
sudo chmod a+r /usr/local/cuda/include/cudnn.h /usr/local/cuda/lib64/libcudnn*

# Install sublime
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
sudo add-apt-repository "deb https://download.sublimetext.com/ apt/stable/"
sudo apt-get update
sudo apt-get install sublime-text
