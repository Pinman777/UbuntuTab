#!/bin/bash
# QwenPaw installer for DroidDesk's proot container (Debian 12: python3.11 fits;
# Ubuntu 22.04 fallback: deadsnakes). Run from DroidDesk's Termux terminal:
#   cat qp.sh | proot-distro login debian -- bash
# GPL-3.0-or-later
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

. /etc/os-release || true
echo "[qwenpaw] контейнер: ${PRETTY_NAME:-unknown}"

PY=python3.12
if command -v python3.12 >/dev/null 2>&1; then
    PY=python3.12
elif python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3,11) else 1)' 2>/dev/null; then
    PY=python3
else
    echo "[qwenpaw] системный python < 3.11 — deadsnakes PPA (только для Ubuntu)..."
    apt-get update -y
    apt-get install -y software-properties-common gnupg ca-certificates
    add-apt-repository -y ppa:deadsnakes/ppa
    apt-get update -y
    apt-get install -y python3.12 python3.12-venv
fi
echo "[qwenpaw] использую $PY ($($PY --version 2>&1))"

echo "[qwenpaw] создаю venv /opt/qwenpaw..."
$PY -m venv /opt/qwenpaw
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
