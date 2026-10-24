#!/bin/bash
###############################################################################
# UbuntuTab — start-desktop.sh
#
# Запускается ВНУТРИ контейнера Ubuntu 24.04 (устанавливается в
# /usr/local/bin/start-desktop.sh скриптом postinstall.sh). Запускает
# XFCE-сессию на дисплее Termux:X11 (DISPLAY=:0 пробрасывается из Termux
# скриптом start-ubuntu.sh).
#
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 UbuntuTab contributors
# На основе DroidDesk, Copyright (C) 2026 orailnoor and DroidDesk
# contributors — https://github.com/orailnoor/DroidDesk (GPL-3.0)
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version. Полный текст: LICENSES/GPL-3.0.txt.
###############################################################################
set -euo pipefail

export DISPLAY="${DISPLAY:-:0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null || true

exec dbus-launch --exit-with-session startxfce4
