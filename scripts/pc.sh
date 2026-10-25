#!/bin/bash
# UbuntuTab PC-apps pack: делает контейнер похожим на рабочий ПК.
# Запуск из Termux: cat pc.sh | proot-distro login ubuntu -- bash
# (или внутри контейнера: bash pc.sh).  GPL-3.0-or-later. Идемпотентен.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "[pc] обновление индексов..."
apt-get update -y

echo "[pc] базовый ПК-набор (LibreOffice, GIMP, VLC, архивы, PDF)..."
apt-get install -y --no-install-recommends \
    libreoffice libreoffice-l10n-ru libreoffice-help-ru \
    gimp \
    vlc \
    file-roller evince \
    htop tree unzip p7zip-full \
    fonts-liberation2

echo "[pc] VSCodium (VS Code, arm64)..."
apt-get install -y --no-install-recommends wget gpg
install -d -m 0755 /etc/apt/keyrings
wget -qO- https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor -o /etc/apt/keyrings/vscodium-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/vscodium-archive-keyring.gpg] https://download.vscodium.com/debs vscodium main" \
    > /etc/apt/sources.list.d/vscodium.list
apt-get update -y
apt-get install -y --no-install-recommends codium

echo "[pc] ярлыки обновятся автоматически (menu scan по .desktop)."
echo "[pc] ГОТОВО: LibreOffice, GIMP, VLC, Evince, VSCodium, архиваторы."
