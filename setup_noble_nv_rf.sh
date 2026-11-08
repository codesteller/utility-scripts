#!/usr/bin/env bash
# setup_noble_nv_rf.sh
# One-shot setup for any Ubuntu 24.04 (noble) x86_64 machine with an NVIDIA GPU.
# Replaces setup_noble.sh, setup-gandalf.sh and setup-gandalf-rf.sh.
#
# What it sets up:
#   Base      locale en_IN, build tools, CMake in /opt, dev utilities, snaps (Sublime,
#             VS Code, btop), Mono (TI radar tools), GStreamer/FFmpeg, fonts
#   Shell     zsh + Oh My Zsh with the penguin "apple" theme, Fira Code in GNOME Terminal
#   NVIDIA    CUDA toolkit matching the installed driver (driver is NOT touched),
#             Docker with GPU access (nvidia-container-toolkit)
#   ROS 2     Jazzy desktop, loaded on demand with the "ros" shell function
#   Apps      KiCad 10, OpenCV, Node.js LTS (nvm), uv
#   ML        Python env ~/venvs/ml: PyTorch, TensorRT, ONNX, OpenCV, JupyterLab
#   RF        openEMS + CSXCAD (from source), Python env ~/venvs/rf (EMerge, scikit-rf,
#             PyVISA, PyVista, gmsh, ...), Palace (Apptainer), gerber2ems (Docker),
#             gerbv, git-lfs, FreeCAD and Qucs-S AppImages, ParaView, KiKit
#   Remote    SSH, reachable only through Tailscale (ufw)
#   Share     Azure file share team-share mounted at /mnt/team-share (SMB 3.1.1);
#             asks for the storage account name and key once, at the start
#   Desktop   team images from Google Drive into ~/Pictures (gdown), profile picture
#             prof_pic.JPG, wallpaper GahanAI_Wallpaper.png, Yaru dark theme + accent
#
# Prerequisite: the NVIDIA driver is installed and nvidia-smi works. If not:
#   sudo ubuntu-drivers install && sudo reboot
#
# Usage (as your normal user, not with sudo):
#   bash setup_noble_nv_rf.sh [--no-ros] [--no-ml] [--no-rf] [--no-remote] [--no-share]
#                              [--no-desktop]
# Theme accent: THEME_ACCENT=prussiangreen (default) | bark (neutral) | red (maroon logo) | blue | ...
# Preset the storage account with AZ_STORAGE_ACCOUNT=<name> to skip that prompt.
# Override the CUDA toolkit with CUDA_VERSION=12.8 bash setup_noble_nv_rf.sh
# Safe to re-run: finished steps are detected and skipped.
set -euo pipefail

# ---- Options -------------------------------------------------------------------
DO_ROS=1 DO_ML=1 DO_RF=1 DO_REMOTE=1 DO_SHARE=1 DO_DESKTOP=1
for arg in "$@"; do
    case "$arg" in
        --no-ros)    DO_ROS=0 ;;
        --no-ml)     DO_ML=0 ;;
        --no-rf)     DO_RF=0 ;;
        --no-remote) DO_REMOTE=0 ;;
        --no-share)  DO_SHARE=0 ;;
        --no-desktop) DO_DESKTOP=0 ;;
        -h|--help)   sed -n '2,33p' "$0"; exit 0 ;;
        *) echo "Unknown option: $arg (see --help)" >&2; exit 1 ;;
    esac
done

# ---- Versions and paths --------------------------------------------------------
CMAKE_VERSION=3.31.12
CMAKE_DIR="/opt/cmake/${CMAKE_VERSION}"
ROS_APT_VERSION=1.3.0
NVM_VERSION=v0.40.8
OPENEMS_TAG=v0.37.0
RFSIM_TAG=v1.3.0
RFSIM_EMERGE_VERSION=2.8.9   # the EMerge version RFsim is tested with
FREECAD_TAG=1.1.1
QUCS_TAG=26.1.1
PARAVIEW_VERSION=6.0.1
PARAVIEW_DIR=/opt/paraview
PALACE_IMAGE="oras://ghcr.io/volkermuehlhaus/palace_0181:latest"   # community image, learning only

# Everything installed under home lives in ~/Apsoft; Python envs live in ~/venvs.
APSOFT="$HOME/Apsoft"
APPS="$APSOFT/Apps"            # AppImages (FreeCAD, Qucs-S)
SIF_DIR="$APSOFT/Sif"          # Apptainer images (Palace)
SRC="$APSOFT/Src"              # source checkouts (openEMS-Project, gerber2ems)
OPENEMS_PREFIX="$APSOFT/openEMS"
ML_VENV="$HOME/venvs/ml"
SHARE_NAME=team-share
SHARE_MNT=/mnt/team-share
SHARE_CRED_DIR=/etc/smbcredentials
AZ_ACCOUNT="${AZ_STORAGE_ACCOUNT:-}"
PICS_URL="https://drive.google.com/drive/folders/1SyNYq2J4UcWcQg5hOEGaQh5LxB8ylY7c?usp=drive_link"
PICS_DIR="$HOME/Pictures"
PROFILE_PIC_NAME=prof_pic.JPG
WALLPAPER_NAME=GahanAI_Wallpaper.png
THEME_ACCENT="${THEME_ACCENT:-prussiangreen}"   # Yaru accents: blue bark magenta olive prussiangreen purple red sage viridian
RF_VENV="$HOME/venvs/rf"
EMERGE_VENV="$HOME/venvs/rfsim-emerge"   # EMerge pinned for the RFsim plugin

# ---- Helpers -------------------------------------------------------------------
step() { printf '\n==== %s ====\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1" >&2; }
die()  { printf 'ERROR %s\n' "$1" >&2; exit 1; }
add_line() { touch "$1"; grep -qxF "$2" "$1" || echo "$2" >> "$1"; }
add_to_shells() { add_line "$HOME/.bashrc" "$1"; add_line "$HOME/.zshrc" "$1"; }
version_le() { [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n 1)" = "$1" ]; }

# Download URL of the first GitHub release asset whose name matches a regex.
gh_asset_url() {
    local repo="$1" tag="$2" pattern="$3"
    curl -fsSL "https://api.github.com/repos/${repo}/releases/tags/${tag}" 2>/dev/null \
        | jq -r --arg p "$pattern" '.assets[].browser_download_url | select(test($p))' \
        | head -n 1 || true
}

# ---- Preflight -----------------------------------------------------------------
[ "$(id -u)" -ne 0 ] || die "Run this as your normal user; it calls sudo when needed."
# shellcheck disable=SC1091
. /etc/os-release
[ "${VERSION_CODENAME:-}" = noble ] || die "This script is for Ubuntu 24.04 (noble); found ${PRETTY_NAME:-unknown}."
[ "$(uname -m)" = x86_64 ] || die "This script is for x86_64; found $(uname -m)."
command -v nvidia-smi > /dev/null && nvidia-smi > /dev/null 2>&1 \
    || die "nvidia-smi does not work. Install the driver first: sudo ubuntu-drivers install && sudo reboot"

GPU_NAME="$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n 1)"
DRIVER_VERSION="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1)"
DRIVER_CUDA="$(nvidia-smi | grep -oP 'CUDA Version: \K[0-9]+\.[0-9]+' | head -n 1)"
[ -n "$DRIVER_CUDA" ] || die "Could not read the CUDA version from nvidia-smi."
echo "Host:   $(hostname)"
echo "GPU:    $GPU_NAME (driver $DRIVER_VERSION, supports CUDA up to $DRIVER_CUDA)"
echo "Parts:  ROS=$DO_ROS ML=$DO_ML RF=$DO_RF REMOTE=$DO_REMOTE SHARE=$DO_SHARE DESKTOP=$DO_DESKTOP"

export DEBIAN_FRONTEND=noninteractive
export PATH="$CMAKE_DIR/bin:$HOME/.local/bin:$PATH"
sudo -v
# Keep sudo alive for the long builds; stopped when the script exits.
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
SUDO_KEEPALIVE=$!
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null || true' EXIT
sudo install -d -m 0755 /etc/apt/keyrings

# Azure file share credentials are asked for now, so the long run is unattended after this.
# The key goes straight into a root-only file (mode 600) and is not kept in the shell.
if [ "$DO_SHARE" -eq 1 ]; then
    fstab_acct="$(awk -v m="$SHARE_MNT" '$2 == m && $3 == "cifs" { split($1, a, "/"); split(a[3], b, "."); print b[1] }' /etc/fstab)"
    [ -n "$AZ_ACCOUNT" ] || AZ_ACCOUNT="$fstab_acct"
    if [ -z "$AZ_ACCOUNT" ]; then
        read -rp "Azure storage account name that holds '$SHARE_NAME': " AZ_ACCOUNT < /dev/tty
    fi
    [[ "$AZ_ACCOUNT" =~ ^[a-z0-9]{3,24}$ ]] || die "Storage account name must be 3-24 lowercase letters/digits."
    SHARE_CRED="$SHARE_CRED_DIR/$AZ_ACCOUNT.cred"
    if sudo test -s "$SHARE_CRED"; then
        echo "Share:  using saved credentials $SHARE_CRED"
    else
        read -rsp "Storage account key for '$AZ_ACCOUNT' (input hidden): " az_key < /dev/tty
        echo
        [ -n "$az_key" ] || die "No storage account key given (use --no-share to skip the share)."
        sudo install -d -m 0700 "$SHARE_CRED_DIR"
        printf 'username=%s\npassword=%s\n' "$AZ_ACCOUNT" "$az_key" \
            | sudo install -m 0600 /dev/stdin "$SHARE_CRED"
        unset az_key
        echo "Share:  credentials saved to $SHARE_CRED (root only)"
    fi
fi

# ==== 1. Base system ============================================================
step "Updating Ubuntu and installing base tools"
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install locales build-essential ninja-build pkg-config gdb clang \
    git curl wget unzip htop nvtop btop jq gh ca-certificates gnupg lsb-release \
    software-properties-common python3-dev python3-venv python3-pip \
    terminator tmux neovim neofetch openssh-server mesa-utils libgtk-3-dev \
    zsh fonts-powerline fonts-noto-color-emoji fonts-firacode fonts-roboto fonts-dejavu \
    v4l-utils ffmpeg mono-complete \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x \
    gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio

step "Setting locale to en_IN.UTF-8"
sudo locale-gen en_IN en_IN.UTF-8 > /dev/null
sudo update-locale LC_ALL=en_IN.UTF-8 LANG=en_IN.UTF-8

# brltty grabs CH340 USB-serial adapters (Arduino etc.); remove unless you use braille.
if dpkg -s brltty > /dev/null 2>&1; then
    step "Removing brltty (conflicts with CH340 USB-serial drivers)"
    sudo apt-get -y remove brltty
fi

step "Installing snaps: Sublime Text, VS Code"
snap list sublime-text > /dev/null 2>&1 || sudo snap install sublime-text --classic
snap list code > /dev/null 2>&1 || sudo snap install code --classic

step "Installing CMake ${CMAKE_VERSION} into ${CMAKE_DIR}"
if [ -x "$CMAKE_DIR/bin/cmake" ]; then
    echo "CMake ${CMAKE_VERSION} already installed."
else
    cmake_tmp="$(mktemp -d)"
    curl -fL -o "$cmake_tmp/cmake.tar.gz" \
        "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz"
    sudo mkdir -p "$CMAKE_DIR"
    sudo tar -xzf "$cmake_tmp/cmake.tar.gz" -C "$CMAKE_DIR" --strip-components=1
    rm -rf "$cmake_tmp"
fi
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$rc" ] && sed -i -E "/^export cmake_version=/{/=${CMAKE_VERSION}\$/!d}" "$rc"
done
add_to_shells "export cmake_version=${CMAKE_VERSION}"
add_to_shells 'export PATH=/opt/cmake/${cmake_version}/bin:$PATH'

# ==== 1b. Desktop: team images, profile picture, wallpaper, theme ===============
# find_pic <file name>: path of the file under ~/Pictures (gdown may add a subfolder).
find_pic() { find "$PICS_DIR" -type f -name "$1" -print -quit 2>/dev/null; }
if [ "$DO_DESKTOP" -eq 1 ]; then
    step "Downloading team images from Google Drive into $PICS_DIR"
    sudo apt-get -y install imagemagick gnome-tweaks gnome-shell-extension-manager
    UV="$(command -v uv || echo "$HOME/.local/bin/uv")"
    [ -x "$UV" ] || { curl -fsSL https://astral.sh/uv/install.sh | sh; UV="$HOME/.local/bin/uv"; }
    # Ubuntu 24.04 blocks "pip install" into the system Python, so gdown goes in as a uv tool.
    command -v gdown > /dev/null 2>&1 || "$UV" tool install gdown
    mkdir -p "$PICS_DIR"
    if [ -n "$(find_pic "$PROFILE_PIC_NAME")" ] && [ -n "$(find_pic "$WALLPAPER_NAME")" ]; then
        echo "Images already in $PICS_DIR; skipping download."
    else
        gdown "$PICS_URL" -O "$PICS_DIR/" --folder \
            || warn "Google Drive download failed (folder not shared publicly, or rate-limited); re-run later."
    fi
    PROFILE_PIC="$(find_pic "$PROFILE_PIC_NAME")"
    WALLPAPER="$(find_pic "$WALLPAPER_NAME")"

    step "Setting the profile picture"
    if [ -z "$PROFILE_PIC" ]; then
        warn "$PROFILE_PIC_NAME not found under $PICS_DIR; profile picture not set."
    else
        # Square 512x512 crop from the top (keeps the face in portrait photos); GNOME shows it in a circle.
        face="$(mktemp --suffix=.png)"
        convert "$PROFILE_PIC" -auto-orient -resize '512x512^' -gravity north -extent 512x512 "$face"
        sudo install -D -m 0644 "$face" "/var/lib/AccountsService/icons/$USER"
        install -m 0644 "$face" "$HOME/.face"
        rm -f "$face"
        sudo busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" \
            org.freedesktop.Accounts.User SetIconFile s "/var/lib/AccountsService/icons/$USER" \
            > /dev/null 2>&1 || {
            # Fallback: write the AccountsService user file directly.
            sudo install -d -m 0700 /var/lib/AccountsService/users
            ua="/var/lib/AccountsService/users/$USER"
            sudo touch "$ua"
            sudo grep -q '^\[User\]' "$ua" || echo '[User]' | sudo tee -a "$ua" > /dev/null
            sudo sed -i '/^Icon=/d' "$ua"
            sudo sed -i "/^\[User\]/a Icon=/var/lib/AccountsService/icons/$USER" "$ua"
        }
        echo "Profile picture set from $PROFILE_PIC"
    fi

    # gsettings needs your desktop session; skipped over plain SSH / without GNOME.
    if gsettings get org.gnome.desktop.interface color-scheme > /dev/null 2>&1 && [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
        step "Setting the wallpaper"
        if [ -z "$WALLPAPER" ]; then
            warn "$WALLPAPER_NAME not found under $PICS_DIR; wallpaper not set."
        else
            wp="$HOME/.local/share/backgrounds/$WALLPAPER_NAME"
            install -D -m 0644 "$WALLPAPER" "$wp"
            for key in org.gnome.desktop.background org.gnome.desktop.screensaver; do
                gsettings set "$key" picture-uri "file://$wp"
                gsettings set "$key" picture-options zoom
                gsettings set "$key" primary-color "#000000"
            done
            gsettings set org.gnome.desktop.background picture-uri-dark "file://$wp"
            echo "Wallpaper and lock screen set to $wp"
        fi

        step "Applying the theme: Yaru dark, ${THEME_ACCENT} accent"
        if [ -d "/usr/share/themes/Yaru-${THEME_ACCENT}-dark" ]; then
            gtk_theme="Yaru-${THEME_ACCENT}-dark" icon_theme="Yaru-${THEME_ACCENT}"
        else
            warn "Accent '${THEME_ACCENT}' not installed; using the default Yaru accent."
            gtk_theme="Yaru-dark" icon_theme="Yaru"
        fi
        gsettings set org.gnome.desktop.interface color-scheme prefer-dark
        gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
        gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
        gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Code 11'
        gsettings set org.gnome.desktop.interface show-battery-percentage true
        gsettings set org.gnome.desktop.interface clock-show-weekday true
        gsettings set org.gnome.desktop.interface enable-hot-corners false
        gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
        # Ubuntu Dock: left, full height, always shown, compact icons
        dock=org.gnome.shell.extensions.dash-to-dock
        if gsettings list-keys "$dock" > /dev/null 2>&1; then
            gsettings set "$dock" dock-position LEFT
            gsettings set "$dock" extend-height true
            gsettings set "$dock" dock-fixed true
            gsettings set "$dock" autohide true
            gsettings set "$dock" dash-max-icon-size 40
            gsettings set "$dock" show-mounts false
            gsettings set "$dock" show-trash false
        fi
    else
        warn "No GNOME desktop session found; wallpaper and theme skipped (re-run from the desktop)."
    fi
fi

# ==== 2. Shell ==================================================================
step "Setting up zsh with Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
        | RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh
fi
# Earlier steps already add lines to ~/.zshrc, so the installer keeps that file and
# never writes its own. Without "source $ZSH/oh-my-zsh.sh" nothing loads. Start from the
# Oh My Zsh template and append the lines that were there.
if ! grep -qF 'source $ZSH/oh-my-zsh.sh' "$HOME/.zshrc" 2>/dev/null; then
    zshrc_old="$(mktemp)"
    [ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "$HOME/.zshrc.bak-setup-noble" && cp "$HOME/.zshrc" "$zshrc_old"
    cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
    { echo; cat "$zshrc_old"; } >> "$HOME/.zshrc"
    rm -f "$zshrc_old"
fi
ZSH_PLUGINS="$HOME/.oh-my-zsh/custom/plugins"
[ -d "$ZSH_PLUGINS/zsh-autosuggestions" ] || \
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS/zsh-autosuggestions"
[ -d "$ZSH_PLUGINS/zsh-syntax-highlighting" ] || \
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGINS/zsh-syntax-highlighting"
# Custom apple theme: penguin instead of the Apple logo, then user@host: path/ > in
# Solarized colours (green user@host, blue path) on a Solarized base02 box.
mkdir -p "$HOME/.oh-my-zsh/custom/themes"
sed -e 's/\xEF\xA3\xBF/🐧/' \
    -e 's/\$(toon)%{\$reset_color%} %~\//$(toon)%{$reset_color%}%K{#073642} %F{#859900}%n@%m%F{#93a1a1}: %F{#268bd2}%~\/%F{#93a1a1} > %f%k/' \
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
[ "$(getent passwd "$USER" | cut -d: -f7)" = "$(command -v zsh)" ] || sudo chsh -s "$(command -v zsh)" "$USER"

# Fira Code 12 in the default GNOME Terminal profile, skipped without a desktop
profile="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'" || true)"
if [ -n "$profile" ]; then
    schema="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/"
    gsettings set "$schema" font 'Fira Code 12' || true
    gsettings set "$schema" use-system-font false || true
fi

# ==== 3. Package repositories ===================================================
step "Adding package repositories (Docker, NVIDIA, CUDA, KiCad, ROS 2)"
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

grep -rqs 'kicad/kicad-10.0-releases' /etc/apt/sources.list.d/ \
    || sudo add-apt-repository -y ppa:kicad/kicad-10.0-releases

if [ "$DO_ROS" -eq 1 ] && ! dpkg -s ros2-apt-source > /dev/null 2>&1; then
    ros_deb="$(mktemp --suffix=.deb)"
    curl -fsSL -o "$ros_deb" \
        "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_VERSION}/ros2-apt-source_${ROS_APT_VERSION}.noble_all.deb"
    chmod 644 "$ros_deb"
    sudo apt-get -y install "$ros_deb"
    rm -f "$ros_deb"
fi
sudo apt-get update

# ==== 4. CUDA toolkit ===========================================================
# Newest toolkit in the repo that the installed driver supports, unless CUDA_VERSION is set.
if [ -z "${CUDA_VERSION:-}" ]; then
    CUDA_VERSION=""
    while read -r pkg; do
        v="${pkg#cuda-toolkit-}"; v="${v/-/.}"
        if version_le "$v" "$DRIVER_CUDA"; then CUDA_VERSION="$v"; fi
    done < <(apt-cache pkgnames cuda-toolkit- | grep -E '^cuda-toolkit-[0-9]+-[0-9]+$' | sort -V)
    [ -n "$CUDA_VERSION" ] || die "No cuda-toolkit package in the repo works with driver CUDA $DRIVER_CUDA."
fi
CUDA_PKG="cuda-toolkit-${CUDA_VERSION/./-}"
step "Installing CUDA ${CUDA_VERSION} toolkit (${CUDA_PKG}; driver ${DRIVER_VERSION} left as is)"
sudo apt-get -y install --no-install-recommends "$CUDA_PKG"
# Point PATH at the toolkit picked this time (replaces lines from earlier runs).
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    sed -i -E '/^export (PATH|LD_LIBRARY_PATH)=\/usr\/local\/cuda-[0-9.]+\//d' "$rc"
done
add_to_shells "export PATH=/usr/local/cuda-${CUDA_VERSION}/bin:\$PATH"
add_to_shells "export LD_LIBRARY_PATH=/usr/local/cuda-${CUDA_VERSION}/lib64:\${LD_LIBRARY_PATH:-}"

# ==== 5. Docker with GPU ========================================================
step "Installing Docker with GPU support"
sudo apt-get -y install docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
# Rebuild the list of NVIDIA files passed into containers (CDI). Its refresh service
# only fires on driver/toolkit changes, so an upgraded NVIDIA library (e.g. egl-wayland)
# leaves it stale and every "docker run --gpus" fails until it is rebuilt.
sudo systemctl start nvidia-cdi-refresh.service 2>/dev/null \
    || sudo nvidia-ctk cdi generate --output=/var/run/cdi/nvidia.yaml
sudo systemctl enable docker
sudo systemctl restart docker
sudo usermod -aG docker "$USER"
# Until you log out and in, the docker group is not active in this shell.
if docker info > /dev/null 2>&1; then DOCKER=(docker); else DOCKER=(sudo docker); fi

# ==== 6. ROS 2, OpenCV, KiCad ===================================================
if [ "$DO_ROS" -eq 1 ]; then
    step "Installing ROS 2 Jazzy"
    sudo apt-get -y install ros-jazzy-desktop ros-dev-tools
fi

step "Installing OpenCV and KiCad"
sudo apt-get -y install libopencv-dev python3-opencv kicad

# ROS 2 leaks PYTHONPATH into venvs, so it is never sourced globally; use "ros".
step "Making ROS 2 load only on demand (shell function: ros)"
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$rc" ] || continue
    if grep -qE '^source /opt/ros/jazzy/setup\.(bash|zsh)$' "$rc"; then
        cp "$rc" "$rc.bak-setup-noble"
        sed -i -E '/^source \/opt\/ros\/jazzy\/setup\.(bash|zsh)$/d' "$rc"
        echo "Removed global ROS source line from $rc (backup: $rc.bak-setup-noble)"
    fi
    sed -i -E "/^alias ros='source \/opt\/ros\/jazzy\/setup\.(bash|zsh)'$/d" "$rc"
done

# add_ros_function <rc file> <bash|zsh>: append the "ros" function once. It sources
# ROS 2 Jazzy the first time it is called and prefixes the prompt with "(ROS) " once.
add_ros_function() {
    local rc="$1" ext="$2"
    touch "$rc"
    grep -qF '# >>> ros function (setup-rf.sh) >>>' "$rc" && return 0
    cat >> "$rc" << EOF

# >>> ros function (setup-rf.sh) >>>
# Load ROS 2 Jazzy on demand and mark the prompt. Safe to call more than once.
ros() {
    if [ -n "\${VIRTUAL_ENV:-}" ]; then
        echo "ros: note, a Python venv is active (\$VIRTUAL_ENV); ROS paths will mix into it." >&2
    fi
    if [ -z "\${_ROS_ON:-}" ]; then
        source /opt/ros/jazzy/setup.${ext} || return 1
        export _ROS_ON=1
    fi
    case "\$PS1" in
        "(ROS) "*) ;;
        *) PS1="(ROS) \$PS1" ;;
    esac
}
# <<< ros function (setup-rf.sh) <<<
EOF
}
if [ "$DO_ROS" -eq 1 ]; then
    add_ros_function "$HOME/.bashrc" bash
    add_ros_function "$HOME/.zshrc" zsh
fi

# ==== 7. Node.js and uv =========================================================
step "Installing Node.js LTS with nvm"
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    PROFILE="$HOME/.bashrc" bash -c \
        "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash"
fi
# nvm's scripts use unset variables, so strict mode stays off around them
set +u
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"
nvm install --lts
set -u
add_line "$HOME/.zshrc" 'export NVM_DIR="$HOME/.nvm"'
add_line "$HOME/.zshrc" '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'

step "Installing uv"
UV="$(command -v uv || echo "$HOME/.local/bin/uv")"
if [ ! -x "$UV" ]; then
    curl -fsSL https://astral.sh/uv/install.sh | sh
    UV="$HOME/.local/bin/uv"
fi
add_line "$HOME/.bashrc" 'export PATH=$HOME/.local/bin:$PATH'

# ==== 8. ML Python environment ==================================================
if [ "$DO_ML" -eq 1 ]; then
    step "Creating Python ML environment at ${ML_VENV}"
    "$UV" venv --allow-existing --python 3.12 "$ML_VENV"
    "$UV" pip install --python "$ML_VENV/bin/python" \
        torch torchvision tensorrt onnx opencv-python-headless numpy jupyterlab
    add_to_shells "alias ml='source $ML_VENV/bin/activate'"
fi

# ==== 9. RF / mmWave EM toolchain ===============================================
if [ "$DO_RF" -eq 1 ]; then
    mkdir -p "$SRC" "$SIF_DIR" "$APPS"

    step "Installing RF build dependencies, gerbv, git-lfs, pipx and Apptainer"
    sudo apt-get -y install libhdf5-dev libvtk9-dev libvtk9-qt-dev libboost-all-dev \
        libcgal-dev libtinyxml-dev qtbase5-dev qt6-5compat-dev cython3 python3-setuptools-scm python3-h5py python3-scikit-rf \
        gerbv git-lfs pipx libfuse2t64
    git lfs install
    if ! command -v apptainer > /dev/null 2>&1; then
        sudo add-apt-repository -y ppa:apptainer/ppa
        sudo apt-get update
        sudo apt-get -y install apptainer
    fi

    step "Creating Python RF environment at ${RF_VENV}"
    # --seed puts pip in the venv; openEMS's build script calls pip.
    "$UV" venv --allow-existing --seed --python 3.12 "$RF_VENV"

    step "Building openEMS ${OPENEMS_TAG} into ${OPENEMS_PREFIX}"
    OPENEMS_MARKER="$OPENEMS_PREFIX/.built-${OPENEMS_TAG}"
    if [ -f "$OPENEMS_MARKER" ] && \
       "$RF_VENV/bin/python" -c "import openEMS, CSXCAD" > /dev/null 2>&1; then
        echo "openEMS ${OPENEMS_TAG} already built; skipping (delete $OPENEMS_MARKER to rebuild)."
    else
        if [ ! -d "$SRC/openEMS-Project/.git" ]; then
            git clone --recursive https://github.com/thliebig/openEMS-Project.git "$SRC/openEMS-Project"
        fi
        git -C "$SRC/openEMS-Project" fetch --tags
        git -C "$SRC/openEMS-Project" checkout "$OPENEMS_TAG"
        git -C "$SRC/openEMS-Project" submodule update --init --recursive
        # With a venv active, update_openEMS.sh installs the Python modules into it.
        set +u
        # shellcheck disable=SC1091
        source "$RF_VENV/bin/activate"
        set -u
        (cd "$SRC/openEMS-Project" && ./update_openEMS.sh "$OPENEMS_PREFIX" --python)
        set +u
        deactivate
        set -u
        touch "$OPENEMS_MARKER"
    fi
    add_to_shells "export PATH=$OPENEMS_PREFIX/bin:\$PATH"

    step "Installing EMerge, scikit-rf and the rest of the RF Python stack"
    "$UV" pip install --python "$RF_VENV/bin/python" \
        emerge scikit-rf pyvisa pyvisa-py pyvista gmsh h5py numpy scipy matplotlib \
        jupyterlab black ruff pre-commit pytest
    add_to_shells "alias rf='source $RF_VENV/bin/activate'"

    step "Pulling Palace container image"
    # Community image (Volker Muehlhaus, IHP), built for x86-64-v3 (AVX2). Learning only;
    # build our own from the official Spack recipe before results feed a design decision.
    if ! grep -qw avx2 /proc/cpuinfo; then
        warn "CPU lacks AVX2 (x86-64-v3); skipping the Palace image."
    elif [ ! -f "$SIF_DIR/palace.sif" ]; then
        apptainer pull "$SIF_DIR/palace.sif" "$PALACE_IMAGE"
    else
        echo "Palace image already present."
    fi
    add_to_shells "alias palace='apptainer -q exec $SIF_DIR/palace.sif palace'"

    step "Building gerber2ems Docker image"
    # The image builds its own openEMS, so it never touches the install above.
    if [ ! -d "$SRC/gerber2ems/.git" ]; then
        git clone https://github.com/antmicro/gerber2ems.git "$SRC/gerber2ems"
    else
        git -C "$SRC/gerber2ems" pull --ff-only || warn "gerber2ems pull failed; using local copy"
    fi
    if ! "${DOCKER[@]}" image inspect gerber2ems > /dev/null 2>&1; then
        "${DOCKER[@]}" build -t gerber2ems "$SRC/gerber2ems"
    else
        echo "gerber2ems image already built (docker rmi gerber2ems to rebuild)."
    fi
    add_to_shells "alias gerber2ems='docker run --rm -w \"\$PWD\" --mount type=bind,source=\"\$PWD\",target=\"\$PWD\" gerber2ems'"

    step "Installing FreeCAD ${FREECAD_TAG} and Qucs-S ${QUCS_TAG} AppImages"
    install_appimage() {
        local name="$1" repo="$2" tag="$3" pattern="$4" target="$APPS/$1.AppImage" url
        if [ -x "$target" ]; then
            echo "$name already installed."
            return 0
        fi
        url="$(gh_asset_url "$repo" "$tag" "$pattern")"
        if [ -z "$url" ]; then
            warn "No $name AppImage found in $repo release $tag; install it by hand."
            return 0
        fi
        curl -fL -o "$target" "$url"
        chmod +x "$target"
        echo "$name installed: $target"
    }
    install_appimage FreeCAD FreeCAD/FreeCAD "$FREECAD_TAG" 'x86_64.*\.AppImage$'
    install_appimage Qucs-S ra3xdh/qucs_s "$QUCS_TAG" '\.AppImage$'
    add_to_shells "export PATH=$APPS:\$PATH"

    step "Installing ParaView ${PARAVIEW_VERSION} into ${PARAVIEW_DIR}"
    if [ -x "$PARAVIEW_DIR/bin/paraview" ]; then
        echo "ParaView already installed."
    else
        pv_series="${PARAVIEW_VERSION%.*}"
        pv_file="$(curl -fsSL "https://www.paraview.org/files/v${pv_series}/" \
            | grep -oE "ParaView-${PARAVIEW_VERSION}-MPI-Linux-Python3\.[0-9]+-x86_64\.tar\.gz" \
            | head -n 1 || true)"
        if [ -z "$pv_file" ]; then
            warn "ParaView ${PARAVIEW_VERSION} Linux tarball not found; download it from paraview.org/download."
        else
            pv_tmp="$(mktemp -d)"
            curl -fL -o "$pv_tmp/$pv_file" "https://www.paraview.org/files/v${pv_series}/$pv_file"
            sudo mkdir -p "$PARAVIEW_DIR"
            sudo tar -xzf "$pv_tmp/$pv_file" -C "$PARAVIEW_DIR" --strip-components=1
            rm -rf "$pv_tmp"
        fi
    fi
    add_to_shells "export PATH=$PARAVIEW_DIR/bin:\$PATH"

    step "Installing KiKit (needs KiCad's pcbnew module, so system site packages)"
    pipx ensurepath > /dev/null
    if ! pipx list --short 2>/dev/null | grep -q '^kikit '; then
        pipx install kikit --system-site-packages
    else
        pipx upgrade kikit || true
    fi

    # KiCad "Install from File" only unpacks a package zip into
    # ~/.local/share/kicad/<ver>/3rdparty/<kind>/<identifier with _ for .>, and adds
    # library packages to the library tables. These steps do the same.
    step "Installing KiCad plugins: KiKit (plugin + library) and RFsim ${RFSIM_TAG}"
    KICAD_MAJOR="$(kicad-cli version 2>/dev/null | cut -d. -f1)"
    KICAD_3RD="$HOME/.local/share/kicad/${KICAD_MAJOR}.0/3rdparty"
    KICAD_CFG="$HOME/.config/kicad/${KICAD_MAJOR}.0"
    KICAD_3RD_VAR="KICAD${KICAD_MAJOR}_3RD_PARTY"

    # pcm_install <zip>: install a KiCad package zip like "Install from File".
    pcm_install() {
        local tmp id dir kind
        tmp="$(mktemp -d)"
        unzip -q "$1" -d "$tmp"
        find "$tmp" -name __pycache__ -prune -exec rm -rf {} +   # stale bytecode from the author
        id="$(jq -r .identifier "$tmp/metadata.json")"
        dir="${id//./_}"
        for kind in plugins resources footprints symbols 3dmodels colors templates scripts; do
            [ -d "$tmp/$kind" ] || continue
            mkdir -p "$KICAD_3RD/$kind"
            rm -rf "${KICAD_3RD:?}/$kind/$dir"
            cp -r "$tmp/$kind" "$KICAD_3RD/$kind/$dir"
        done
        rm -rf "$tmp"
        echo "Installed KiCad package $id"
    }
    # add_lib <table file> <table type> <name> <uri>: add a library once.
    add_lib() {
        local table="$1" type="$2" name="$3" uri="$4"
        [ -f "$table" ] || printf '(%s\n\t(version 7)\n\t(lib (name "KiCad") (type "Table") (uri "/usr/share/kicad/template/%s") (options "") (descr "KiCad Default Libraries"))\n)\n' \
            "$type" "${type//_/-}" > "$table"
        grep -qF "(name \"$name\")" "$table" && return 0
        sed -i "\$i\\\\t(lib (name \"$name\") (type \"KiCad\") (uri \"$uri\") (options \"\") (descr \"Added by setup_noble_nv_rf.sh\"))" "$table"
    }

    if [ -z "$KICAD_MAJOR" ]; then
        warn "kicad-cli not found; KiCad plugins skipped."
    elif pgrep -x kicad > /dev/null || pgrep -x pcbnew > /dev/null; then
        warn "KiCad is running; close it and re-run to install the KiCad plugins (it rewrites its settings on exit)."
    else
        mkdir -p "$KICAD_3RD" "$KICAD_CFG"
        pcm_tmp="$(mktemp -d)"
        # KiKit: newest version in the official KiCad repository, checked against its SHA-256.
        pcm_index="$(curl -fsSL https://gitlab.com/kicad/addons/repository/-/raw/main/packages-v1.json || true)"
        for kid in com.github.yaqwsx.kikit com.github.yaqwsx.kikit-library; do
            read -r k_url k_sha < <(jq -r --arg id "$kid" \
                '.packages[] | select(.identifier == $id) | .versions[-1] | "\(.download_url) \(.download_sha256)"' \
                <<< "$pcm_index" 2>/dev/null || true)
            if [ -z "${k_url:-}" ]; then
                warn "$kid not found in the KiCad repository; install it from Plugin and Content Manager."
                continue
            fi
            curl -fsSL -o "$pcm_tmp/$kid.zip" "$k_url"
            if echo "$k_sha  $pcm_tmp/$kid.zip" | sha256sum -c --quiet -; then
                pcm_install "$pcm_tmp/$kid.zip"
            else
                warn "Checksum mismatch for $kid; not installed."
            fi
        done
        add_lib "$KICAD_CFG/sym-lib-table" sym_lib_table PCM_kikit \
            "\${$KICAD_3RD_VAR}/symbols/com_github_yaqwsx_kikit-library/kikit.kicad_sym"
        add_lib "$KICAD_CFG/fp-lib-table" fp_lib_table PCM_kikit \
            "\${$KICAD_3RD_VAR}/footprints/com_github_yaqwsx_kikit-library/kikit.pretty"

        # RFsim: its metadata lists Windows only, but the code supports Linux
        # (venv/bin/python, RFSIM_PYTHON); the GUI refuses it, unpacking works.
        rf_url="$(gh_asset_url NBalciunas/kicad-rfsim "$RFSIM_TAG" '\.zip$')"
        if [ -n "$rf_url" ]; then
            curl -fsSL -o "$pcm_tmp/rfsim.zip" "$rf_url"
            pcm_install "$pcm_tmp/rfsim.zip"
        else
            warn "RFsim ${RFSIM_TAG} release zip not found; install it by hand."
        fi
        rm -rf "$pcm_tmp"
    fi

    step "Pointing RFsim at the solvers"
    # openEMS runs in the RF env. EMerge gets its own env at the version RFsim is tested with.
    "$UV" venv --allow-existing --python 3.12 "$EMERGE_VENV"
    "$UV" pip install --python "$EMERGE_VENV/bin/python" "emerge==${RFSIM_EMERGE_VERSION}" h5py numpy
    # environment.d reaches apps started from the desktop (KiCad) after the next login.
    mkdir -p "$HOME/.config/environment.d"
    cat > "$HOME/.config/environment.d/60-rfsim.conf" << EOF
# Written by setup_noble_nv_rf.sh: solver Pythons for the KiCad RFsim plugin
RFSIM_PYTHON=$RF_VENV/bin/python
RFSIM_EMERGE_PYTHON=$EMERGE_VENV/bin/python
OPENEMS_PATH=$OPENEMS_PREFIX
EOF
    add_to_shells "export RFSIM_PYTHON=$RF_VENV/bin/python RFSIM_EMERGE_PYTHON=$EMERGE_VENV/bin/python OPENEMS_PATH=$OPENEMS_PREFIX"
fi

# ==== 10. Azure file share ======================================================
if [ "$DO_SHARE" -eq 1 ]; then
    step "Mounting Azure file share $SHARE_NAME at $SHARE_MNT"
    sudo apt-get -y install cifs-utils
    SHARE_HOST="$AZ_ACCOUNT.file.core.windows.net"
    if ! timeout 5 bash -c "exec 3<>/dev/tcp/$SHARE_HOST/445" 2>/dev/null; then
        warn "Cannot reach $SHARE_HOST on port 445 (often blocked by ISPs); the mount will fail until it is open (e.g. via VPN)."
    fi
    sudo mkdir -p "$SHARE_MNT"
    fstab_line="//$SHARE_HOST/$SHARE_NAME $SHARE_MNT cifs nofail,_netdev,x-systemd.automount,credentials=$SHARE_CRED,uid=$(id -u),gid=$(id -g),dir_mode=0775,file_mode=0664,serverino,nosharesock,actimeo=30,mfsymlinks,vers=3.1.1 0 0"
    if ! grep -qxF "$fstab_line" /etc/fstab; then
        sudo cp /etc/fstab /etc/fstab.bak-setup-noble
        # Replace any earlier entry for this mount point.
        sudo awk -v m="$SHARE_MNT" '$2 != m' /etc/fstab.bak-setup-noble | sudo tee /etc/fstab > /dev/null
        echo "$fstab_line" | sudo tee -a /etc/fstab > /dev/null
        echo "Added $SHARE_MNT to /etc/fstab (backup: /etc/fstab.bak-setup-noble)"
    fi
    sudo systemctl daemon-reload
    mountpoint -q "$SHARE_MNT" || sudo mount "$SHARE_MNT" \
        || warn "Mounting $SHARE_MNT failed; check the account key and port 445, then: sudo mount $SHARE_MNT"
fi

# ==== 11. Remote access =========================================================
if [ "$DO_REMOTE" -eq 1 ]; then
    step "Enabling SSH, reachable only through Tailscale"
    command -v tailscale > /dev/null 2>&1 || curl -fsSL https://tailscale.com/install.sh | sh
    sudo systemctl enable --now ssh
    sudo ufw allow in on tailscale0 to any port 22 proto tcp comment 'SSH over Tailscale'
    sudo ufw --force enable
    tailscale status > /dev/null 2>&1 \
        || warn "Tailscale is not logged in; run 'sudo tailscale up' or SSH will not be reachable."
fi

# ==== 12. Checks ================================================================
step "Checking the result"
fail=0
check() {
    local name="$1"; shift
    if "$@" > /dev/null 2>&1; then echo "OK    $name"; else echo "FAIL  $name"; fail=1; fi
}
check "zsh default shell"    test "$(getent passwd "$USER" | cut -d: -f7)" = "$(command -v zsh)"
check "Oh My Zsh"            test -f "$HOME/.oh-my-zsh/oh-my-zsh.sh"
check "Custom zsh prompt"    grep -q '🐧' "$HOME/.oh-my-zsh/custom/themes/apple.zsh-theme"
check "zsh starts cleanly"   bash -c "out=\$(zsh -i -c 'echo \$ZSH_THEME' 2>&1 < /dev/null) && [ \"\$out\" = apple ]"
check "CMake in /opt"        test -x "$CMAKE_DIR/bin/cmake"
check "uv"                   test -x "$UV"
check "Node.js"              bash -c ". '$NVM_DIR/nvm.sh' && node --version"
check "CUDA compiler"        test -x "/usr/local/cuda-${CUDA_VERSION}/bin/nvcc"
check "Docker GPU access"    sudo docker run --rm --gpus all ubuntu:24.04 nvidia-smi
check "OpenCV"               python3 -c "import cv2"
check "KiCad CLI"            kicad-cli version
check "ROS not sourced globally" bash -c "! grep -qE '^source /opt/ros/jazzy' '$HOME/.bashrc' '$HOME/.zshrc'"
if [ "$DO_ROS" -eq 1 ]; then
    check "ROS 2 Jazzy"          test -f /opt/ros/jazzy/setup.bash
    check "ros function in bash/zsh" bash -c "grep -qF '# >>> ros function' '$HOME/.bashrc' && grep -qF '# >>> ros function' '$HOME/.zshrc'"
fi
if [ "$DO_ML" -eq 1 ]; then
    check "PyTorch sees GPU"     "$ML_VENV/bin/python" -c "import torch; assert torch.cuda.is_available(); torch.ones(1, device='cuda')"
    check "TensorRT"             "$ML_VENV/bin/python" -c "import tensorrt"
fi
if [ "$DO_RF" -eq 1 ]; then
    py="$RF_VENV/bin/python"
    check "openEMS binary"             test -x "$OPENEMS_PREFIX/bin/openEMS"
    check "openEMS + CSXCAD in Python" bash -c "cd / && '$py' -c 'import openEMS, CSXCAD; openEMS.openEMS(); CSXCAD.ContinuousStructure()'"
    check "EMerge"                     bash -c "cd / && '$py' -c 'import emerge'"
    check "scikit-rf"                  "$py" -c "import skrf"
    check "gmsh"                       "$py" -c "import gmsh"
    check "PyVista"                    "$py" -c "import pyvista"
    check "PyVISA"                     "$py" -c "import pyvisa"
    check "Black / ruff / pytest"      bash -c "'$RF_VENV/bin/black' --version && '$RF_VENV/bin/ruff' --version && '$RF_VENV/bin/pytest' --version"
    grep -qw avx2 /proc/cpuinfo && \
        check "Palace container"       apptainer -q exec "$SIF_DIR/palace.sif" palace --help
    check "gerber2ems image"           "${DOCKER[@]}" image inspect gerber2ems
    check "gerbv"                      command -v gerbv
    check "git-lfs"                    git lfs version
    check "FreeCAD AppImage"           test -x "$APPS/FreeCAD.AppImage"
    check "Qucs-S AppImage"            test -x "$APPS/Qucs-S.AppImage"
    check "ParaView"                   test -x "$PARAVIEW_DIR/bin/paraview"
    check "KiKit"                      "$HOME/.local/bin/kikit" --version
    if [ -n "${KICAD_3RD:-}" ]; then
        check "KiKit KiCad plugin"         test -f "$KICAD_3RD/plugins/com_github_yaqwsx_kikit/__init__.py"
        check "KiKit KiCad library"        bash -c "grep -qF PCM_kikit '$KICAD_CFG/sym-lib-table' && test -d '$KICAD_3RD/footprints/com_github_yaqwsx_kikit-library/kikit.pretty'"
        check "RFsim KiCad plugin"         test -f "$KICAD_3RD/plugins/com_github_nbalciunas_kicad-rfsim/rfsim.py"
    fi
    check "RFsim deps in KiCad Python" /usr/bin/python3 -c "import skrf, matplotlib, h5py"
    check "RFsim openEMS solver"       bash -c "cd / && '$py' -c 'import numpy, h5py, CSXCAD, openEMS'"
    check "RFsim EMerge solver"        bash -c "cd / && '$EMERGE_VENV/bin/python' -c 'import numpy, h5py, emerge'"
fi
[ "$DO_REMOTE" -eq 1 ] && check "SSH running" systemctl is-active --quiet ssh
if [ "$DO_DESKTOP" -eq 1 ]; then
    check "Profile picture"      test -s "/var/lib/AccountsService/icons/$USER"
    check "Wallpaper set"        bash -c "gsettings get org.gnome.desktop.background picture-uri | grep -qF '$WALLPAPER_NAME'"
    check "Dark theme"           bash -c "gsettings get org.gnome.desktop.interface color-scheme | grep -q prefer-dark"
fi
[ "$DO_SHARE" -eq 1 ] && check "team-share mounted" bash -c "ls '$SHARE_MNT' && mountpoint -q '$SHARE_MNT'"

echo
echo "Installed on $(hostname): $GPU_NAME, driver $DRIVER_VERSION, CUDA toolkit $CUDA_VERSION"
if [ "$DO_RF" -eq 1 ]; then
    (cd / && "$RF_VENV/bin/python" -c "import openEMS, CSXCAD; print('  openEMS', openEMS.__version__, '/ CSXCAD', CSXCAD.__version__)") || true
    kicad-cli version 2>/dev/null | sed 's/^/  KiCad /' || true
    echo
    echo "KiCad: log out and in (RFsim finds its solvers through the new environment),"
    echo "       then open the PCB editor: KiKit and RFsim are in Tools > External Plugins."
    echo "Before a Gerber release: sudo apt-mark hold kicad"
fi
echo
if [ "$fail" -eq 0 ]; then
    echo "All done. Log out and back in so zsh, the docker group, PATH and aliases apply."
    echo "Shortcuts: ml / rf (Python envs), ros (ROS 2 Jazzy)."
else
    echo "Finished with failures, listed above."
    exit 1
fi
