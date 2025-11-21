#!/bin/bash
# Download Images
pip install gdown
export PATH=$PATH:${HOME}/.local/bin
gdown https://drive.google.com/drive/folders/1SyNYq2J4UcWcQg5hOEGaQh5LxB8ylY7c?usp=drive_link -O ~/Pictures/ --folder

# Convert Images to size
sudo apt-get install imagemagick
cd ${HOME}/Pictures/images_logo
convert  -resize 420x420 whitelogo-removebg-preview.png ubuntu_small.png
convert  -resize 640x640 Logo_BG_Removed.png ubuntu_big.png

# BackUp bootscreens
cd /usr/share/plymouth
sudo mv ubuntu.png ubuntu.png.bak
if [ ! -f themes/spinner/bgrt-fallback.png.bak ]; then
    sudo mv themes/spinner/bgrt-fallback.png themes/spinner/bgrt-fallback.png.bak
fi
if [ ! -f themes/spinner/watermark.png.bak ]; then
    sudo mv themes/spinner/watermark.png themes/spinner/watermark.png.bak
fi

sudo cp ${HOME}/Pictures/images_logo/ubuntu_small.png ./
sudo cp ${HOME}/Pictures/images_logo/ubuntu_big.png ./

# Make New Bootscreens
sudo cp ubuntu_big.png themes/spinner/bgrt-fallback.png 
sudo cp ubuntu_small.png themes/spinner/watermark.png
