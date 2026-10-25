#!/data/data/com.termux/files/usr/bin/bash
# UbuntuTab: (re)create session starter only. GPL-3.0-or-later
set -euo pipefail
cat > "$HOME/start-ubuntutab.sh" <<'EOS'
#!/data/data/com.termux/files/usr/bin/bash
# UbuntuTab session starter (real Termux + Termux:X11, канонический рецепт termux-x11)
set -euo pipefail
pulseaudio --start --exit-idle-time=-1 2>/dev/null || true
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 >/dev/null 2>&1 || true
termux-x11 :1 >/dev/null 2>&1 &
sleep 2
exec proot-distro login ubuntu --shared-tmp -- \
    env DISPLAY=:1 PULSE_SERVER=127.0.0.1 /usr/local/bin/start-desktop.sh
EOS
chmod 0755 "$HOME/start-ubuntutab.sh"
ls -l "$HOME/start-ubuntutab.sh"
echo "starter OK — запускай: bash ~/start-ubuntutab.sh"
