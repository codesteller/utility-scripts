sudo apt update && sudo apt upgrade -y
sudo apt install python3-dev python3-pip python3-venv
sudo -H pip3 install -U jetson-stats

################ REBOOT REQUIRED HERE ##############

echo "export PATH=/usr/src/tensorrt/bin:$PATH" >> $HOME/.bashrc
# TensorRT Samples stored in /opt


# Prepare Xavier for the JetPack and maximize the performance with:
sudo nvpmodel -m 0 # Add the power mode as needed. To more about the power modes refer manual
sudo jetson_clocks

# Generate yolov3.onnx with the README shared in the /usr/src/tensorrt/samples/python/yolov3_onnx/.
# Run the yolov3.onnx with trtexec, which targets for the profiling.
/usr/src/tensorrt/bin/trtexec --onnx=./yolov3.onnx --workspace=26 --int8
