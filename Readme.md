# Utility Scripts for System Setup - Noble Numbat
These scripts are intended to setup Ubuntu 24.04 system

## Main setup: `setup_noble_nv_rf.sh`
One script for any Ubuntu 24.04 x86_64 machine with an NVIDIA GPU (desktop or laptop).
It replaces `setup_noble.sh`, `setup-gandalf.sh` and `setup-gandalf-rf.sh`.

Prerequisite: NVIDIA driver installed and `nvidia-smi` working
(`sudo ubuntu-drivers install && sudo reboot`). The script never touches the driver;
it picks the newest CUDA toolkit the driver supports.

```bash
bash setup_noble_nv_rf.sh                 # everything
bash setup_noble_nv_rf.sh --no-rf --no-ros   # skip parts: --no-ros --no-ml --no-rf --no-remote --no-share --no-desktop
CUDA_VERSION=12.8 bash setup_noble_nv_rf.sh  # force a CUDA toolkit version
```

Run as your normal user (not sudo). Safe to re-run. Unless you pass `--no-remote`,
run `sudo tailscale up` once: SSH is only allowed over Tailscale.

The Azure file share `team-share` is mounted at `/mnt/team-share`. At the start the script
asks for the storage account name (or set `AZ_STORAGE_ACCOUNT=<name>`) and the account key;
the key is saved only in `/etc/smbcredentials/<account>.cred` (root, mode 600). Outbound
port 445 must be open. CMake 3.31.12 is installed into `/opt/cmake/3.31.12`.

Desktop: team images are downloaded from Google Drive into `~/Pictures/images_logo` (gdown),
`prof_pic.JPG` becomes the profile picture and `GahanAI_Wallpaper.png` the wallpaper and lock
screen. Theme: Yaru dark with the `prussiangreen` accent (`THEME_ACCENT=bark` etc. to change),
dock on the left, full height and always shown. Run from the desktop session so the theme can be applied.

KiCad plugins are installed without the GUI, the way "Install from File" does it: KiKit
(plugin + library, from the official KiCad repository, SHA-256 checked) and RFsim. RFsim's
package says Windows only, but its code supports Linux; the script points it at the solvers
through `~/.config/environment.d/60-rfsim.conf` (openEMS: `~/venvs/rf`, EMerge 2.8.9:
`~/venvs/rfsim-emerge`). Close KiCad before running the script; log out and in afterwards.
