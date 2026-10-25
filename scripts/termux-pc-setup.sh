#!/data/data/com.termux/files/usr/bin/bash
# UbuntuTab PC-setup wrapper (Termux side): ставит ПК-набор в контейнер ubuntu.
# Использование: curl -fsSL <url> -o pcs.sh && bash pcs.sh
# GPL-3.0-or-later
set -euo pipefail
REPO="https://raw.githubusercontent.com/Pinman777/UbuntuTab/main/scripts"

echo "[pcs] качаю pc.sh (основной источник, затем зеркало)..."
curl -fsSL --retry 3 --retry-delay 2 "$REPO/pc.sh" -o "$HOME/pc.sh" \
  || curl -fsSL --retry 3 --retry-delay 2 "https://cdn.jsdelivr.net/gh/Pinman777/UbuntuTab@main/scripts/pc.sh" -o "$HOME/pc.sh"

echo "[pcs] запускаю в контейнере ubuntu (идемпотентно, 10-20 мин)..."
proot-distro login ubuntu -- bash -c '
    if dpkg --audit 2>/dev/null | grep -q .; then
        echo "[pcs] восстановление прерванного dpkg..."; dpkg --configure -a
    fi
    bash /data/data/com.termux/files/home/pc.sh
'

echo
echo "[pcs] ГОТОВО. Запуск десктопа: bash ~/utab.sh"
