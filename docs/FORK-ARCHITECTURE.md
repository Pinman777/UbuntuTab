# FORK ARCHITECTURE: **UbuntuTab** — «Ubuntu-first Android desktop»

- дата: 2026-10-24, автор: Tech Lead (default)
- статус: **утверждено zeon 2026-10-24**: имя UbuntuTab; публикация на GitHub (открыто, GPL-3.0) после QA; QwenPaw — в образе ПО УМОЛЧАНИЮ (PyPI `qwenpaw==2.2.2.post1`)
- база: orailnoor/DroidDesk @ a410944 (2026-10-14), GPL-3.0 → форк обязан оставаться GPL-3.0 с сохранением NOTICE.md / THIRD_PARTY_NOTICES.md
- досье проекта: Obsidian `40_Agents/QwenPaw/Tasks/2026-10-24-droiddesk-fork-project.md`

## 1. Цель / не-цели

**Цель:** Android-приложение = «сел → сразу полноценная Ubuntu». Единственная первичная среда — proot-Ubuntu 24.04 arm64 с XFCE через embedded Termux:X11. Работает на no-root устройствах zeon и запускает QwenPaw.

**Не-цели (MVP):** chroot/root-режим, KDE, Wayland-десктоп (только X11-приложения через Termux:X11), snap-пакеты (нет snapd в proot), мультидистро (только Ubuntu), VNC-сервер по умолчанию.

## 2. Целевые устройства (no-root)

| | Huawei MatePad 11.5"S | Infinix Note 30 |
|---|---|---|
| SoC/GPU | Kirin 9000W / Maleoon 910 | Helio G99 / Mali-G57 MC2 |
| RAM | 8 ГБ | 8 ГБ |
| ОС | HarmonyOS 4.2 (APK ок) | XOS 13 / Android 13 |
| Рендер | **llvmpipe** (Mesa sw; драйверов Maleoon/Mali нет; Turnip/Zink — только для Adreno-девайсов, оставляем как автоопределение) | llvmpipe |

## 3. Архитектурные изменения vs DroidDesk

### Берём как есть (S)
- Flutter-оболочка (welcome/setup/desktop/apps screens), тема, иконки.
- `minSdk=targetSdk=28` (обход W^X exec-блока Android 10+).
- `bootstrap-aarch64.zip` (Termux bootstrap в ассетах) — при условии resolved provenance (пункт COMPLIANCE; иначе пересобрать из termux/termux-packages).
- Embedded Termux:X11 + `socket_hook.c`.
- Идея App Bridge / menu-sync: `.desktop` из контейнера → лаунчер приложения.

### Меняем (M/L)
1. **`termux-linux-setup.sh` → `ubuntu-setup.sh`** (M):
   - Termux bootstrap ставит ТОЛЬКО фундамент: `proot-distro`, репо `termux-x11` (для Termux:X11 APK-части/зависимостей), `pulseaudio` (аудио), `tigervnc` НЕ нужен.
   - `proot-distro install ubuntu-24.04` + `postinstall.sh` внутри контейнера:
     - `apt`: xfce4, xfce4-goodies, terminal, firefox-esr (PPA mozillateam — ubuntu-пакет firefox это snap-заглушка, в proot не работает), mousepad, file-manager, `mesa-utils` (glxinfo), шрифты (noto + cyrillic), `localegen ru_RU.UTF-8`.
     - Python 3.12 (нативный в 24.04) + venv `/opt/qwenpaw`; **QwenPaw по умолчанию**: `pip install qwenpaw` (PyPI 2.2.2.post1, wheels aarch64/glibc проверены), ярлык «QwenPaw Console».
     - Пользователь: **root** (решение интегратора 2026-10-24: паттерн оригинала + дефолт proot-distro; без systemd/sudo-слоя в MVP).
   - Убираем из дефолтного флоу: установку нативных TUR-десктопов (XFCE/LXQt/MATE/KDE в Termux), Turnip-этап на не-Adreno, Andronix-стиль VNC.
2. **Сессия `start-ubuntu.sh`** (M): `proot-distro login ubuntu --bind /dev:... -- /root/start-desktop.sh` → внутри: `dbus-launch --exit-with-session startxfce4`, `DISPLAY=:0` на сокет Termux:X11, `PULSE_SERVER`. Полноэкранный Termux:X11 активити из Flutter-оболочки по кнопке/автозапуску.
3. **Menu-sync `ubuntu-menu-sync.sh`** (S-M): форк `proot-menu-sync.sh`: скан `/usr/share/applications/*.desktop` контейнера → иконки+ярлыки в лаунчер Flutter. Единственный источник приложений (нативного Termux-меню больше нет).
4. **Flutter-флоу** (M): welcome → «Установить Ubuntu» (прогресс: bootstrap→образ→apt→DE→готово) → desktop-скрин = «Открыть Ubuntu» (запуск сессии) + сетка приложений из menu-sync. Экран выбора DE удаляем (XFCE only в MVP).
5. **Брендинг** (S): имя, applicationId, иконка, splash. — **нужно имя от zeon**.

### Выпиливаем (S)
- `pi-launch_phone.sh` (RPi-мост) — в docs/ как опция, не в core.
- Выбор дистро (Debian/Kali) — MVP только Ubuntu.

## 4. Deliverables (Phase 2, MVP)

- **D1** Форк-репо (rename, лицензионные файлы сохранены), `gradle assembleDebug` зелёный.
- **D2** `ubuntu-setup.sh` + `postinstall.sh` (+ `--with-qwenpaw`).
- **D3** `start-ubuntu.sh` + hookup Termux:X11 + `ubuntu-menu-sync.sh`.
- **D4** README (RU): установка на MatePad 11.5"S и Note 30; XOS-грабли (разработчик → лимит фоновых процессов, battery optimization off); клавиатура/мышь.
- **D5** QA-чеклист на устройствах.

## 5. Verify-критерии (QA-gate)

1. `./gradlew assembleDebug` — exit 0, APK собирается.
2. На устройстве (живой тест): установка → автозапуск → XFCE-сессия **≤ 60 с** от тапа «Открыть Ubuntu» (холодный старт).
3. В контейнере: `apt install` работает; firefox-esr открывается; кириллица рендерится.
4. `pip install qwenpaw` в venv — exit 0; `qwenpaw --version` отвечает.
5. Menu-sync: ≥5 ярлыков из Ubuntu видны в лаунчере.
6. Стабильность: сессия живёт 10 мин при выключенном экране (wake lock), сворачивание/разворачивание не убивает X.
7. Память: XFCE+firefox < 5.5 ГБ RSS на 8 ГБ устройстве (иначе — план Б: LXQt/утилизация zram).

## 6. Риски и митигации

| Риск | Митигация |
|---|---|
| llvmpipe медленный на 2800×1840 | compositor XFCE off, разрешение Termux:X11 вниз (1440p→1080p опция), MVP-метрика — п.5.2 |
| Phantom/child process killer (XOS 13, HarmonyOS) | README-рецепт + runtime-подсказка в Flutter при детекте убийства |
| 8 ГБ RAM: DE+браузер+QwenPaw | firefox — вкладки ≤5 в QA; zram-рекомендация; метрика п.5.7 |
| snap-пакеты недоступны | firefox-esr из mozillateam PPA; в README список deb-приложений |
| GPL/compliance DroidDesk | сохранить LICENSES/, NOTICE.md, THIRD_PARTY_NOTICES.md; свои изменения — GPL-3.0; до публичного релиза закрыть пункты COMPLIANCE.md (provenance bootstrap) |

## 7. Разбиение для ACP-рук (Phase 2)

- **T1** (qwen_code): D2+D3 — скрипты установки/сессии/sync + постинстолл Ubuntu (verify 3,4,5 на эмуляторе arm64 или устройстве). ✅ done 2026-10-24 (commits 68f4989, e28e0a4)
- **T3a** (integration): бандлинг scripts/ в ассеты Flutter + распаковка в ~/scripts при первой установке.
- **T3b** (integration): сетка приложений Flutter читает манифест ~/.local/share/ubuntutab/apps.json (контракт T1: id/name/exec/terminal/icon).
- **T2** (claude_code): D1+D5 — Flutter-флоу, брендинг-хуки, сборка APK (verify 1).
- **T3** (Tech Lead + zeon): живой QA на обоих устройствах (verify 2,6,7), итерации.
- Параллельные правки изолированы: T1 в `scripts/`, T2 в `app/` — конфликтов минимум; общий rebase-порядок согласовывает Tech Lead.

## 8. Решения zeon (2026-10-24)

1. Имя проекта: **UbuntuTab** ✅
2. Публикация на GitHub — открыто, GPL-3.0 + attribution DroidDesk ✅ (после прохождения QA, до пуша — финальный 'go')
3. QwenPaw — в образе по умолчанию ✅ (PyPI)
