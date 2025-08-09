# --------------------------------------------------------------------------------
#               USER DEFINED PATHS, VARIABLES & FUNCTIONS
# --------------------------------------------------------------------------------

# ---------------- PATHS & VARS ----------------------------

# ROCM
export PATH=$PATH:/opt/rocm-6.4.2/bin
export LD_LIBRARY_PATH=/opt/rocm-6.4.2/lib
export HSA_OVERRIDE_GFX_VERSION=10.3.0
# export PYTORCH_ROCM_ARCH="gfx1031"
# export HSA_OVERRIDE_GFX_VERSION=10.3.1
# export HIP_VISIBLE_DEVICES=0
# export ROCM_PATH=/opt/rocm

function clear_deb_error()  {
    sudo chown -Rv _apt:root /var/cache/apt/archives/partial/
    sudo chmod -Rv 700 /var/cache/apt/archives/partial/
}

# CMAKE
export cmake_version=3.30.0
export PATH=/opt/cmake/${cmake_version}/bin:$PATH

# ---------------- FUNCTIONS ----------------------------

cvdev_flag=0
function cvdev()    {
    if [ $cvdev_flag -eq 0 ]
    then
        mamba activate cvdev
        cvdev_flag=1
    fi
}

ros_flag=0
function rosdev()  {
    if [ $ros_flag -eq 0 ]
    then
        source /opt/ros/jazzy/setup.bash
        ros_flag=1
        PS1=[ROS2]$PS1
    fi
}

mmwave_flag=0
function mmwave_dev()   {
    if [ $mmwave_flag -eq 0 ]
    then
        sudo chmod 666 /dev/ttyACM0
        sudo chmod 666 /dev/ttyACM1
        MMWAVE_ROOT=${HOME}/ti/mmwave_sdk_03_06_02_00-LTS/packages/scripts/unix/
        cwd=${PWD}
        cd $MMWAVE_ROOT
        source setenv.sh
        cd ${cwd}
        PS1=[mmWave]$PS1
        mmwave_flag=1
    fi
}

function usb_info() {
    lsusb
    echo "----------------------------------------------------------------------"
    ls /dev/ttyUSB*
    echo "----------------------------------------------------------------------"
    ls /dev/ttyACM*
    echo "----------------------------------------------------------------------"
    ls /dev/ttyS*
}

function dev_info() {
    echo "----------------------------------------------------------------------"
    udevadm info -a -p $(udevadm info -q path -n /dev/ttyACM$1) | grep manufacturer
    echo "----------------------------------------------------------------------"

}

function getin_avdocker()   {
    docker exec -it gahanai_drwigbot bash
}


# --------------------- ALIAS --------------------------------
alias run_pytorch_docker="docker run -it --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
                            --device=/dev/kfd --device=/dev/dri --group-add video \
                            -v ${HOME}/Workspace/rocm_pytorch:/workspace -w /workspace \
                            -p 9000:8888 -p 6006:6006 \
                            --ipc=host --shm-size 8G rocm/pytorch:latest"
