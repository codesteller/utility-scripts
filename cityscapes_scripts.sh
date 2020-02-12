
# Save current working directory
cwd=$(pwd)

# Running cityscapes scripts

# Assuming Anaconda is installed
# cityscapes uses PyQt4 hence python 3.5 is to be used, doesn't work with 3.6 and 3.7
# Setup Environment
conda create -n py35dev python=3.5
conda activate py35dev
conda install -c anaconda pyqt=4.11.4

# Get Cityscapes Scripts
git clone https://github.com/mcordts/cityscapesScripts.git
cd cityscapesScripts-master

pip install -e .

# Add cityscapes dataset root directory here
export CITYSCAPES_DATASET=/home/codesteller/datasets/cityscapes/cityscapes

python cityscapesscripts/annotation/cityscapesLabelTool.py

 