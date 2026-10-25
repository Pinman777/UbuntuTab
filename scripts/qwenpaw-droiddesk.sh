#!/bin/bash
# QwenPaw installer for DroidDesk's proot container (Ubuntu 22.04, python3.10 base).
# Run from DroidDesk's Termux terminal:
#   proot-distro login ubuntu -- bash -c "$(curl -fsSL https://raw.githubusercontent.com/Pinman777/UbuntuTab/main/scripts/qwenpaw-droiddesk.sh)"
# GPL-3.0-or-later
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

. /etc/os-release || true
echo "[qwenpaw] контейнер: ${PRETTY_NAME:-unknown}"

need_ppa=0
python3.12 --version 2>/dev/null || need_ppa=1

if [ "$need_ppa" = "1" ]; then
    echo "[qwenpaw] python3.12 нет — подключаю deadsnakes PPA..."
    apt-get update -y
    apt-get install -y software-properties-common gnupg ca-certificates
    add-apt-repository -y ppa:deadsnakes/ppa
    apt-get update -y
    apt-get install -y python3.12 python3.12-venv python3.12-distutils
fi

echo "[qwenpaw] создаю venv /opt/qwenpaw..."
python3.12 -m venv /opt/qwenpaw
/opt/qwenpaw/bin/pip install --upgrade pip wheel

echo "[qwenpaw] ставлю qwenpaw (пару минут, ~1 ГБ зависимостей)..."
/opt/qwenpaw/bin/pip install qwenpaw

echo "[qwenpaw] ярлык в меню..."
cat > /usr/share/applications/qwenpaw-console.desktop <<'EOS'
[Desktop Entry]
Type=Application
Name=QwenPaw Console
Comment=AI agent framework console
Exec=qwenpaw-console
Terminal=true
Icon=utilities-terminal
Categories=System;TerminalEmulator;
EOS
cat > /usr/local/bin/qwenpaw-console <<'EOS'
#!/bin/bash
exec /opt/qwenpaw/bin/qwenpaw "$@"
EOS
chmod 0755 /usr/local/bin/qwenpaw-console

echo
echo "[qwenpaw] ГОТОВО. Выйди (exit) и в Termux прогони: bash ~/proot-menu-sync.sh"
/opt/qwenpaw/bin/qwenpaw --version 2>/dev/null || echo "(version check недоступен — но установка завершена; проверь ярлыком)"
