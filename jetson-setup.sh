echo "export PATH=/usr/src/tensorrt/bin:$PATH" >> $HOME/.bashrc
# TensorRT Samples stored in /opt


# Prepare Xavier for the JetPack and maximize the performance with:
sudo nvpmodel -m 0
sudo jetson_clocks

# Generate yolov3.onnx with the README shared in the /usr/src/tensorrt/samples/python/yolov3_onnx/.
# Run the yolov3.onnx with trtexec, which targets for the profiling.
/usr/src/tensorrt/bin/trtexec --onnx=./yolov3.onnx --workspace=26 --int8
