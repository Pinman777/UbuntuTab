#!/data/data/com.termux/files/usr/bin/bash
# UbuntuTab go: (re)install start-desktop.sh into container + launch session. GPL-3.0-or-later
set -euo pipefail
REPO="https://raw.githubusercontent.com/Pinman777/UbuntuTab/main/scripts"
ROOTFS="${PREFIX:-/data/data/com.termux/files/usr}/var/lib/proot-distro/containers/ubuntu/rootfs"
curl -fsSL "$REPO/start-desktop.sh" -o "$ROOTFS/usr/local/bin/start-desktop.sh"
chmod 0755 "$ROOTFS/usr/local/bin/start-desktop.sh"
echo "start-desktop.sh installed -> container"
exec bash "$HOME/start-ubuntutab.sh"
