#!/usr/bin/env bash
# Setup for gandalf-3080: Ubuntu 24.04, RTX 3080, NVIDIA driver 595 (CUDA 13.2).
# Run as your normal user, not with sudo: bash setup-gandalf.sh
# Safe to re-run. Does not touch the NVIDIA driver or the second NVMe drive.
set -euo pipefail

CMAKE_VERSION=3.30.0
CUDA_VERSION=13.2
CUDA_PKG=cuda-toolkit-13-2
ROS_APT_VERSION=1.3.0
NVM_VERSION=v0.40.8
ML_VENV="$HOME/venvs/ml"

if [ "$(id -u)" -eq 0 ]; then
    echo "Run this as your normal user; it calls sudo when needed." >&2
    exit 1
fi

step() { printf '\n==== %s ====\n' "$1"; }
add_line() { grep -qxF "$2" "$1" || echo "$2" >> "$1"; }
add_to_shells() { add_line "$HOME/.bashrc" "$1"; add_line "$HOME/.zshrc" "$1"; }

export DEBIAN_FRONTEND=noninteractive
sudo -v
sudo install -d -m 0755 /etc/apt/keyrings

step "Updating Ubuntu and installing base tools"
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install build-essential ninja-build pkg-config gdb \
    git curl wget unzip htop nvtop jq gh ca-certificates gnupg lsb-release \
    software-properties-common python3-venv python3-pip zsh fonts-powerline \
    fonts-noto-color-emoji fonts-firacode

step "Setting up zsh with Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
        | RUNZSH=no CHSH=no sh
fi
ZSH_PLUGINS="$HOME/.oh-my-zsh/custom/plugins"
[ -d "$ZSH_PLUGINS/zsh-autosuggestions" ] || \
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS/zsh-autosuggestions"
[ -d "$ZSH_PLUGINS/zsh-syntax-highlighting" ] || \
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGINS/zsh-syntax-highlighting"
# Custom apple theme: penguin instead of the Apple logo, plus user@host
mkdir -p "$HOME/.oh-my-zsh/custom/themes"
sed -e 's/\xEF\xA3\xBF/🐧/' \
    -e 's/\$(toon)%{\$reset_color%} %~\//$(toon)%{$reset_color%} %K{238}%F{252} %n@%m %~\/ %f%k/' \
    "$HOME/.oh-my-zsh/themes/apple.zsh-theme" > "$HOME/.oh-my-zsh/custom/themes/apple.zsh-theme"
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="apple"/' "$HOME/.zshrc"
# zsh-syntax-highlighting has to stay last in this list
sed -i 's/^plugins=(.*/plugins=(git docker docker-compose sudo z zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
add_line "$HOME/.zshrc" 'export PATH=$HOME/.local/bin:$PATH'
add_line "$HOME/.zshrc" '# Sober command colours for zsh-syntax-highlighting'
for style in command builtin alias function precommand; do
    add_line "$HOME/.zshrc" "ZSH_HIGHLIGHT_STYLES[$style]='fg=110'"
done
add_line "$HOME/.zshrc" "ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=174'"
sudo chsh -s "$(command -v zsh)" "$USER"

# Fira Code 12 in the default GNOME Terminal profile, skipped without a desktop
profile="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'" || true)"
if [ -n "$profile" ]; then
    schema="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/"
    gsettings set "$schema" font 'Fira Code 12'
    gsettings set "$schema" use-system-font false
fi

step "Adding CMake from /opt to bash and zsh"
add_to_shells "export cmake_version=${CMAKE_VERSION}"
add_to_shells 'export PATH=/opt/cmake/${cmake_version}/bin:$PATH'

step "Adding package repositories"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/nvidia-container-toolkit.gpg
echo "deb [signed-by=/etc/apt/keyrings/nvidia-container-toolkit.gpg] https://nvidia.github.io/libnvidia-container/stable/deb/\$(ARCH) /" \
    | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/3bf863cc.pub \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/nvidia-cuda.gpg
echo "deb [signed-by=/etc/apt/keyrings/nvidia-cuda.gpg] https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/ /" \
    | sudo tee /etc/apt/sources.list.d/nvidia-cuda.list > /dev/null

sudo add-apt-repository -y ppa:kicad/kicad-10.0-releases

ros_deb="$(mktemp --suffix=.deb)"
curl -fsSL -o "$ros_deb" \
    "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_VERSION}/ros2-apt-source_${ROS_APT_VERSION}.noble_all.deb"
chmod 644 "$ros_deb"
sudo apt-get -y install "$ros_deb"
rm -f "$ros_deb"

sudo apt-get update

step "Installing CUDA ${CUDA_VERSION} toolkit (matches driver 595, driver left as is)"
sudo apt-get -y install --no-install-recommends "$CUDA_PKG"
add_to_shells "export PATH=/usr/local/cuda-${CUDA_VERSION}/bin:\$PATH"
add_to_shells "export LD_LIBRARY_PATH=/usr/local/cuda-${CUDA_VERSION}/lib64:\${LD_LIBRARY_PATH:-}"

step "Installing Docker with GPU support"
sudo apt-get -y install docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl enable docker
sudo systemctl restart docker
sudo usermod -aG docker "$USER"

step "Installing ROS 2 Jazzy, OpenCV and KiCad"
sudo apt-get -y install ros-jazzy-desktop ros-dev-tools libopencv-dev python3-opencv
add_line "$HOME/.bashrc" "source /opt/ros/jazzy/setup.bash"
add_line "$HOME/.zshrc" "source /opt/ros/jazzy/setup.zsh"
sudo apt-get -y install kicad

step "Installing Node.js LTS with nvm"
export PROFILE="$HOME/.bashrc"
curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
export NVM_DIR="$HOME/.nvm"
# nvm's scripts use unset variables, so strict mode stays off around them
set +u
. "$NVM_DIR/nvm.sh"
nvm install --lts
set -u
add_line "$HOME/.zshrc" 'export NVM_DIR="$HOME/.nvm"'
add_line "$HOME/.zshrc" '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'

step "Creating Python ML environment at ${ML_VENV}"
UV="$(command -v uv || echo "$HOME/.local/bin/uv")"
if [ ! -x "$UV" ]; then
    curl -fsSL https://astral.sh/uv/install.sh | sh
fi
"$UV" venv --allow-existing --python 3.12 "$ML_VENV"
"$UV" pip install --python "$ML_VENV/bin/python" \
    torch torchvision tensorrt onnx opencv-python-headless numpy jupyterlab

step "Enabling SSH, reachable only through Tailscale"
sudo systemctl enable --now ssh
sudo ufw allow in on tailscale0 to any port 22 proto tcp comment 'SSH over Tailscale'
sudo ufw --force enable

step "Checking the result"
fail=0
check() {
    local name="$1"; shift
    if "$@" > /dev/null 2>&1; then echo "OK    $name"; else echo "FAIL  $name"; fail=1; fi
}
check "zsh default shell"    test "$(getent passwd "$USER" | cut -d: -f7)" = "$(command -v zsh)"
check "Oh My Zsh"            test -f "$HOME/.oh-my-zsh/oh-my-zsh.sh"
check "Powerline font"       dpkg -s fonts-powerline
check "Custom zsh prompt"    grep -q '🐧' "$HOME/.oh-my-zsh/custom/themes/apple.zsh-theme"
check "uv"                   test -x "$UV"
check "CMake in /opt"      test -x "/opt/cmake/${CMAKE_VERSION}/bin/cmake"
check "CUDA compiler"      test -x "/usr/local/cuda-${CUDA_VERSION}/bin/nvcc"
check "Docker GPU access"    sudo docker run --rm --gpus all ubuntu:24.04 nvidia-smi
check "ROS 2 Jazzy"          test -f /opt/ros/jazzy/setup.bash
check "OpenCV"               python3 -c "import cv2"
check "KiCad"                command -v kicad
check "PyTorch sees GPU"     "$ML_VENV/bin/python" -c "import torch; assert torch.cuda.is_available()"
check "TensorRT"             "$ML_VENV/bin/python" -c "import tensorrt"
check "SSH running"          systemctl is-active --quiet ssh

echo
if [ "$fail" -eq 0 ]; then
    echo "All done. Log out and back in so the docker group and PATH changes apply."
else
    echo "Finished with failures, listed above."
    exit 1
fi
