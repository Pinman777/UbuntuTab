# Receipt — UbuntuTab Phase 2, T1: установочные и сессионные скрипты

- **date:** 2026-10-24
- **requester:** zeon → **delegator:** default (Tech Lead)
- **executor:** qwen_code
- **автономия:** L1 (только repo `~/projects/ubuntu-tab`, paths `scripts/` + этот receipt; никаких внешних отправок)
- **authority:** docs/FORK-ARCHITECTURE.md (утверждено zeon 2026-10-24) + задача T1 в диалоге делегации

## Artifacts (все новые, в `scripts/`)

| Файл | Назначение |
|---|---|
| `ubuntu-setup.sh` | Termux: pkg update → proot-distro + pulseaudio → install ubuntu-24.04 → копирует postinstall.sh/start-desktop.sh в контейнер → запускает postinstall в контейнере → ставит хуки start-ubuntu.sh/ubuntu-menu-sync.sh в $HOME → первичный menu-sync |
| `postinstall.sh` | В контейнере (root, идемпотентен): apt update/upgrade; XFCE (xfce4, terminal, goodies, dbus-x11, x11-xserver-utils, mesa-utils); firefox-esr из PPA mozillateam + apt-пин 1001; fonts-noto-core/ui-core; локали ru_RU+en_US.UTF-8; python3.12+venv → /opt/qwenpaw → pip install qwenpaw==2.2.2.post1 (playwright install сознательно НЕ запускается); .desktop «QwenPaw Console»; тёмная тема XFCE (Greybird-dark, xfconf-XML + terminalrc, композитинг off); install start-desktop.sh → /usr/local/bin |
| `start-desktop.sh` | В контейнере: `dbus-launch --exit-with-session startxfce4` (DISPLAY=:0, XDG_RUNTIME_DIR=/tmp) |
| `start-ubuntu.sh` | Termux: pulseaudio старт (если не запущен) + module-native-protocol-tcp 127.0.0.1; bind'ы сокета Termux:X11 ($TMPDIR/.X11-unix→/tmp/.X11-unix) и GPU (/dev/dri, /dev/kgsl-3d0 — паттерн DroidDesk start-proot.sh); `proot-distro login ubuntu-24.04 … env DISPLAY=:0 PULSE_SERVER=127.0.0.1 LANG=ru_RU.UTF-8 /usr/local/bin/start-desktop.sh` |
| `ubuntu-menu-sync.sh` | Termux: прямой скан `$ROOTFS/usr/share/applications/*.desktop` (без login) → манифест `~/.local/share/ubuntutab/apps/apps.json` + иконки в `…/apps/icons/`; резолв иконок (абсолютный путь в rootfs / темы hicolor+Adwaita PNG 512→32 / scalable SVG / pixmaps); NoDisplay/Hidden skip; Name[ru] приоритет; Terminal=true → флаг; полная пересборка за запуск (идемпотентно) |

Каждый скрипт: SPDX GPL-3.0-or-later + attribution DroidDesk (orailnoor) в шапке; `set -euo pipefail`; сообщения об ошибках RU.

## Verify (команды + результаты)

```
$ cd scripts && for s in ubuntu-setup.sh postinstall.sh start-desktop.sh start-ubuntu.sh ubuntu-menu-sync.sh; do bash -n "$s" && echo "OK $s"; done
OK ubuntu-setup.sh / OK postinstall.sh / OK start-desktop.sh / OK start-ubuntu.sh / OK ubuntu-menu-sync.sh   # exit=0

$ command -v shellcheck
(пусто — не установлен)

$ git status --short   # в репо ubuntu-tab
?? .worktrees/   # сессионная инфраструктура qwen, не T1
?? docs/         # pre-existing (спецификация Tech Lead), не T1
?? scripts/      # ← изменение T1
?? receipts/     # ← этот receipt (перезаписан из вилта по указанию zeon)
$ git diff --stat
(пусто — все файлы T1 новые/untracked; трекаемые файлы не менялись)
```

- **bash -n:** 5/5 скриптов, exit 0 ✅
- **shellcheck:** не установлен в системе хоста. Обоснование: установка пакетов в систему = изменение вне L1; вместо этого — bash -n + построчное само-ревью логики (найдены и исправлены до verify: JSON-контракт иконки `null` vs строка, абсолютные пути Icon= внутри rootfs, TMPDIR-fallback для mktemp, экранирование табуляций в JSON). shellcheck рекомендуется прогнать в CI (GitHub Actions) — вне скоупа T1.
- **git:** изменения строго `scripts/` + `receipts/` (untracked, новые). app/, README.md, termux-linux-setup.sh, LICENSES/, NOTICE.md, THIRD_PARTY_NOTICES.md не тронуты ✅
- Живой прогон (Termux/контейнер) — не выполнялся: хост x86_64 без Termux; по плану это T3 (QA на устройствах), verify-критерии 3–5 из FORK-ARCHITECTURE.md.

## Exceptions

1. **shellcheck недоступен** на хосте — см. обоснование выше.
2. **git diff --stat пуст** (новые untracked-файлы); объём изменений доказан `git status --short`.
3. **Receipt в репо, а не в вилте:** запись в `~/Obsidian-Home/…` заблокирована политикой (вне cwd); по указанию zeon receipt положен в `receipts/`, Tech Lead перенесёт в вилт.
4. **postinstall.sh допускает запуск не на 24.04** с warning (grep VERSION_ID) — полезно для эмулятора/дебага, жёсткий fail был бы излишен.
5. **QwenPaw запинен** `==2.2.2.post1` (проверенная версия из FORK-ARCHITECTURE.md, п. «статус»).
6. **Тема применяется для /root** — контейнерная сессия работает от root (паттерн DroidDesk, SETUP_USERNAME=root).
7. **pactl load-module** повторяется безвредно (модуль уже загружен → ошибка подавлена `|| true`).

## Friction

1. **Противоречие «пользователь ubuntu» vs root:** FORK-ARCHITECTURE.md (M1) упоминает «Пользователь ubuntu, sudo», но Deliverables T1 пользователя не требуют, а паттерн оригинала (termux-linux-setup.sh) работает от root. Реализовал root; вопрос вынесен на ревью.
2. **Флаг `--with-qwenpaw`:** в D2 спецификации указан «(+ --with-qwenpaw)», но задача T1 требует QwenPaw **по умолчанию** и запрещает выдумывать фичи. Реализовал «по умолчанию», флаг не делал.
3. **Гигантский монолит-источник:** termux-linux-setup.sh (1104 строки) смешивает Termux-нативный DE и proot; паттерны (bind'ы, тема, menu-sync) извлекал фрагментами; оригинальный menu-sync пишет wrappers для XFCE-меню Termux — потребитель у нас другой (Flutter-лаунчер), поэтому контракт apps.json спроектирован заново, минимально.
4. **Adwaita-dark из xsettings.xml DroidDesk** отсутствует в чистом Ubuntu без gnome-themes-extra — поставил gnome-themes-extra, но тему взял Greybird-dark (идёт с xfce4 в Ubuntu, каноничнее для XFCE).
5. **Сессия исполнителя прерывалась** по таймауту рантайма — состояние сохранялось, verify повторён свежим прогоном.

## Open questions (на ревью Tech Lead)

1. **root vs пользователь `ubuntu`** в контейнере — влияет на T2/QA (home, права на /opt/qwenpaw).
2. **Нужен ли флаг `--with-qwenpaw`** (D2) при «по умолчанию» — или убрать из архитектуры.
3. **Контракт `apps.json`** (поля id/name/exec/terminal/icon, путь `~/.local/share/ubuntutab/apps/`) — согласовать с T2: Flutter читает сам или через MethodChannel?
4. **Иконки svg/xpm** копируются как есть — Flutter рендерит png нативно; svg/xpm потребуют обработки на стороне T2 (или фильтровать на этапе sync?).
5. **arm64-сборка firefox-esr в mozillateam PPA** — подтвердить на устройстве (T3): если PPA не публикует arm64, fallback — официальные tarballs Mozilla aarch64 (правка postinstall.sh).
6. **apt-пин 1001** перекрывает все источники для всех пакетов PPA — штатный рецепт mozilla, но подтвердить осознанно.

## Status

**done** (код готов; живой device-QA — T3). Все границы L1 соблюдены.
