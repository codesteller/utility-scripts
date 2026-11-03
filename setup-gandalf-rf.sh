#!/usr/bin/env bash
# setup-rf.sh
# RF / mmWave EM toolchain for gandalf-3080 (Ubuntu 24.04), AWR2944 LRR board project.
# Runs after setup-gandalf.sh, which already provides KiCad 10, Docker with GPU access,
# CMake in /opt, git, gh and uv.
#
# Installs:
#   openEMS v0.37.0 + CSXCAD (built from source into ~/opt/openEMS)
#   Python env ~/venvs/rf: openEMS/CSXCAD modules, EMerge, scikit-rf, PyVISA, PyVista,
#     gmsh, h5py, NumPy/SciPy/Matplotlib, JupyterLab, Black, ruff, pre-commit, pytest
#   Palace (Apptainer image), gerber2ems (Docker image), gerbv, git-lfs
#   FreeCAD and Qucs-S (AppImages), ParaView (official tarball in /opt), KiKit (pipx)
# Also stops ROS 2 from loading in every shell (it leaks PYTHONPATH into venvs) and
# adds an "ros" alias instead.
#
# Run as your normal user, not with sudo:  bash setup-rf.sh
# Safe to re-run: finished steps are detected and skipped.
set -euo pipefail

# ---- Versions and paths ------------------------------------------------------
CMAKE_VERSION=3.30.0                      # same as setup-gandalf.sh
OPENEMS_TAG=v0.37.0
OPENEMS_PREFIX="$HOME/opt/openEMS"
RF_VENV="$HOME/venvs/rf"
SRC="$HOME/src"
SIF_DIR="$HOME/sif"
APPS="$HOME/Applications"
PALACE_IMAGE="oras://ghcr.io/volkermuehlhaus/palace_0181:latest"   # community image, learning only
FREECAD_TAG=1.1.1
QUCS_TAG=26.1.1
PARAVIEW_VERSION=6.0.1
PARAVIEW_DIR=/opt/paraview

if [ "$(id -u)" -eq 0 ]; then
    echo "Run this as your normal user; it calls sudo when needed." >&2
    exit 1
fi

step() { printf '\n==== %s ====\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1" >&2; }
add_line() { touch "$1"; grep -qxF "$2" "$1" || echo "$2" >> "$1"; }
add_to_shells() { add_line "$HOME/.bashrc" "$1"; add_line "$HOME/.zshrc" "$1"; }

# Download URL of the first GitHub release asset whose name matches a regex.
# Prints nothing if the release or asset is not found (caller decides what to do).
gh_asset_url() {
    local repo="$1" tag="$2" pattern="$3"
    curl -fsSL "https://api.github.com/repos/${repo}/releases/tags/${tag}" 2>/dev/null \
        | jq -r --arg p "$pattern" '.assets[].browser_download_url | select(test($p))' \
        | head -n 1 || true
}

export DEBIAN_FRONTEND=noninteractive
export PATH="/opt/cmake/${CMAKE_VERSION}/bin:$HOME/.local/bin:$PATH"
sudo -v
mkdir -p "$SRC" "$SIF_DIR" "$APPS"

# Docker needs sudo until you log out and back in after setup-gandalf.sh added you
# to the docker group.
if docker info > /dev/null 2>&1; then DOCKER=(docker); else DOCKER=(sudo docker); fi

UV="$(command -v uv || echo "$HOME/.local/bin/uv")"
if [ ! -x "$UV" ]; then
    echo "uv not found; run setup-gandalf.sh first." >&2
    exit 1
fi

# ---- 1. Keep ROS 2 out of every shell ------------------------------------------
step "Making ROS 2 load only on demand (alias: ros)"
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$rc" ] || continue
    if grep -qE '^source /opt/ros/jazzy/setup\.(bash|zsh)$' "$rc"; then
        cp "$rc" "$rc.bak-setup-rf"
        sed -i -E '/^source \/opt\/ros\/jazzy\/setup\.(bash|zsh)$/d' "$rc"
        echo "Removed global ROS source line from $rc (backup: $rc.bak-setup-rf)"
    fi
done
add_line "$HOME/.bashrc" "alias ros='source /opt/ros/jazzy/setup.bash'"
add_line "$HOME/.zshrc" "alias ros='source /opt/ros/jazzy/setup.zsh'"
echo "NOTE: setup-gandalf.sh lines 115-116 add the global source lines back if re-run;"
echo "      replace them with the two alias lines above."

# ---- 2. System packages --------------------------------------------------------
step "Installing build dependencies, gerbv, git-lfs, pipx and Apptainer"
sudo apt-get update
sudo apt-get -y install libhdf5-dev libvtk9-dev libvtk9-qt-dev libboost-all-dev \
    libcgal-dev libtinyxml-dev qtbase5-dev cython3 gerbv git-lfs pipx jq
git lfs install
if ! command -v apptainer > /dev/null 2>&1; then
    sudo add-apt-repository -y ppa:apptainer/ppa
    sudo apt-get update
    sudo apt-get -y install apptainer
fi

# ---- 3. RF Python environment --------------------------------------------------
step "Creating Python RF environment at ${RF_VENV}"
# --seed puts pip in the venv; openEMS's build script calls pip.
"$UV" venv --allow-existing --seed --python 3.12 "$RF_VENV"

# ---- 4. openEMS + CSXCAD from source --------------------------------------------
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
    # With a venv active, update_openEMS.sh installs the Python modules into it
    # instead of creating its own (its default --python-venv-mode auto).
    # The activate script reads unset variables, so strict mode stays off around it.
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

# ---- 5. Python packages --------------------------------------------------------
step "Installing EMerge, scikit-rf and the rest of the Python stack"
"$UV" pip install --python "$RF_VENV/bin/python" \
    emerge scikit-rf pyvisa pyvisa-py pyvista gmsh h5py numpy scipy matplotlib \
    jupyterlab black ruff pre-commit pytest
add_to_shells "alias rf='source $RF_VENV/bin/activate'"

# ---- 6. Palace (Apptainer) -----------------------------------------------------
step "Pulling Palace container image"
# Community image (Volker Muehlhaus, IHP), built for x86_64_v3, runs on Zen 3.
# Use for learning only; build our own from the official Spack recipe before any
# Palace result feeds a design decision.
if [ ! -f "$SIF_DIR/palace.sif" ]; then
    apptainer pull "$SIF_DIR/palace.sif" "$PALACE_IMAGE"
else
    echo "Palace image already present."
fi
add_to_shells "alias palace='apptainer -q exec $SIF_DIR/palace.sif palace'"

# ---- 7. gerber2ems (Docker) ----------------------------------------------------
step "Building gerber2ems Docker image"
# The image builds its own openEMS at the commit gerber2ems was tested with,
# so it never touches the v0.37.0 install above.
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

# ---- 8. GUI applications -------------------------------------------------------
step "Installing FreeCAD ${FREECAD_TAG} and Qucs-S ${QUCS_TAG} AppImages"
# AppImages need FUSE 2 on Ubuntu 24.04.
sudo apt-get -y install libfuse2t64

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

# ---- 9. KiKit ------------------------------------------------------------------
step "Installing KiKit (needs KiCad's pcbnew module, so system site packages)"
pipx ensurepath > /dev/null
if ! pipx list --short 2>/dev/null | grep -q '^kikit '; then
    pipx install kikit --system-site-packages
else
    pipx upgrade kikit || true
fi

# ---- 10. Checks ----------------------------------------------------------------
step "Checking the result"
fail=0
check() {
    local name="$1"; shift
    if "$@" > /dev/null 2>&1; then echo "OK    $name"; else echo "FAIL  $name"; fail=1; fi
}
py="$RF_VENV/bin/python"
check "ROS not sourced globally"   bash -c "! grep -qE '^source /opt/ros/jazzy' '$HOME/.bashrc' '$HOME/.zshrc'"
check "openEMS binary"             test -x "$OPENEMS_PREFIX/bin/openEMS"
check "openEMS + CSXCAD in Python" bash -c "cd / && '$py' -c 'import openEMS, CSXCAD; openEMS.openEMS(); CSXCAD.ContinuousStructure()'"
check "EMerge"                     bash -c "cd / && '$py' -c 'import emerge'"
check "scikit-rf"                  "$py" -c "import skrf"
check "gmsh"                       "$py" -c "import gmsh"
check "PyVista"                    "$py" -c "import pyvista"
check "PyVISA"                     "$py" -c "import pyvisa"
check "Black / ruff / pytest"      bash -c "'$RF_VENV/bin/black' --version && '$RF_VENV/bin/ruff' --version && '$RF_VENV/bin/pytest' --version"
check "Palace container"           apptainer -q exec "$SIF_DIR/palace.sif" palace --help
check "gerber2ems image"           "${DOCKER[@]}" image inspect gerber2ems
check "gerbv"                      command -v gerbv
check "git-lfs"                    git lfs version
check "FreeCAD AppImage"           test -x "$APPS/FreeCAD.AppImage"
check "Qucs-S AppImage"            test -x "$APPS/Qucs-S.AppImage"
check "ParaView"                   test -x "$PARAVIEW_DIR/bin/paraview"
check "KiCad CLI"                  kicad-cli version
check "KiKit"                      "$HOME/.local/bin/kikit" --version

echo
echo "Versions installed:"
(cd / && "$py" -c "import openEMS, CSXCAD; print('  openEMS', openEMS.__version__, '/ CSXCAD', CSXCAD.__version__)") || true
"$py" -c "import emerge, skrf; print('  EMerge', getattr(emerge, '__version__', '?'), '/ scikit-rf', skrf.__version__)" || true
apptainer -q exec "$SIF_DIR/palace.sif" palace --version 2>/dev/null | head -n 2 | sed 's/^/  /' || true
kicad-cli version 2>/dev/null | sed 's/^/  KiCad /' || true

echo
echo "Manual steps left:"
echo "  1. KiCad > Plugin and Content Manager: install the KiKit plugin and library."
echo "  2. RFsim: download its release zip from github.com/NBalciunas/kicad-rfsim,"
echo "     install with 'Install from File', and point it at $RF_VENV."
echo "  3. Before Gerber release: sudo apt-mark hold kicad"
echo
if [ "$fail" -eq 0 ]; then
    echo "All done. Open a new terminal (or log out and in) so PATH and aliases apply."
    echo "Then: rf  (activates the RF Python environment)"
else
    echo "Finished with failures, listed above."
    exit 1
fi
