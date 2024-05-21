locale  # check for UTF-8

sudo apt update && sudo apt install locales -y
sudo locale-gen en_IN en_IN.UTF-8
sudo update-locale LC_ALL=en_IN.UTF-8 LANG=en_IN.UTF-8
export LANG=en_IN.UTF-8

locale  # verify settings

sudo apt install software-properties-common build-essential -y 
sudo add-apt-repository universe -y 

sudo apt update && sudo apt install curl -y
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
sudo apt update
sudo apt install ros-humble-desktop-full ros-dev-tools -y
sudo apt install python3-colcon-devtools -y
sudo apt install python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool -y

# ROSDEP
sudo rosdep init
rosdep update

# Optional
sudo apt install ros-humble-depthai-examples ros-humble-depthai-ros ros-humble-ublox 
sudo apt install ros-humble-velodyne 

# ros2 launch ublox_gps ublox_gps_node-composed-launch.py
echo "function rosdev()    {\n    source /opt/ros/humble/setup.bash\n}" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
