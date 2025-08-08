#!/bin/bash
set -e

echo "=== Updating system ==="
sudo apt update

echo "=== Installing dependencies ==="
sudo apt install -y unzip wget curl openjdk-17-jdk git

echo "=== Installing Flutter SDK ==="
cd ~
FLUTTER_VERSION="3.24.1"
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
tar xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
rm flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

# Add Flutter to PATH
if ! grep -q 'flutter/bin' ~/.bashrc; then
  echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
fi
export PATH="$PATH:$HOME/flutter/bin"

echo "=== Installing Android Command Line Tools ==="
mkdir -p ~/Android/cmdline-tools
cd ~/Android/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip -q commandlinetools-linux-*.zip
rm commandlinetools-linux-*.zip
mv cmdline-tools latest

# Set environment variables
if ! grep -q 'ANDROID_HOME' ~/.bashrc; then
  echo 'export ANDROID_HOME=$HOME/Android' >> ~/.bashrc
  echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools' >> ~/.bashrc
fi
export ANDROID_HOME=$HOME/Android
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

echo "=== Installing Android SDK Packages ==="
yes | sdkmanager --sdk_root=${ANDROID_HOME} --licenses
sdkmanager --install "platform-tools" "platforms;android-34" "build-tools;34.0.0" "emulator" "system-images;android-34;google_apis;x86_64"

echo "=== Creating Android Emulator (Pixel_API_34) ==="
echo "no" | avdmanager create avd -n Pixel_API_34 -k "system-images;android-34;google_apis;x86_64" --device "pixel"

echo "=== Running Flutter Doctor ==="
flutter doctor

echo
echo "=== Setup Complete ==="
echo "Restart your terminal or run: source ~/.bashrc"
echo "To start the emulator: emulator -avd Pixel_API_34"
