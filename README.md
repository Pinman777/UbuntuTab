# UbuntuTab

Полноценная Ubuntu 24.04 на Android-планшете или телефоне — без root. Открываешь приложение → нажимаешь «Open Ubuntu» → работаешь в XFCE-десктопе: терминал, Firefox, LibreOffice, VS Code, Python и [QwenPaw](https://github.com/agentscope-ai/QwenPaw).

Форк проекта [DroidDesk](https://github.com/orailnoor/DroidDesk) от orailnoor (GPL-3.0). Ключевое отличие: первичная и единственная среда — **proot-контейнер Ubuntu**, а не нативный Termux-десктоп.

> ⚠️ UbuntuTab — независимый open-source проект (GPL-3.0), использующий модифицированные компоненты Termux:X11. Не аффилирован с Termux, Canonical или Ubuntu; торговые марки принадлежат их владельцам.

## Что работает

- **proot-Ubuntu 24.04 (arm64)**: `apt`, компиляция (gcc, python), привычные deb-пакеты
- **XFCE-десктоп** через встроенный Termux:X11 — без VNC
- **Firefox ESR**, терминал, файловый менеджер, кириллица из коробки
- **QwenPaw** — агент-фреймворк ставится в контейнер, ярлык «QwenPaw Console»
- Автозапуск сессии, ярлыки приложений из Ubuntu в лаунчере (App Bridge / menu-sync)

## Требования

- Android-устройство **ARM64**, 8+ ГБ RAM, ~10 ГБ свободного места
- Без root — работает везде; root не требуется и не используется
- Клавиатура/мышь: Bluetooth или USB-C hub — резко улучшают опыт

## Установка

1. Скачай свежий APK из [Releases](../../releases) и установи (sideload: «Настройки → Безопасность → Установка приложений из неизвестных источников»).
2. Открой UbuntuTab → **Install Ubuntu** → жди (5–15 минут: загрузка образа + apt + XFCE + QwenPaw; прогресс виден в логе).
3. Нажми **Open Ubuntu** — откроется XFCE-сессия.

## Грабли по устройствам (важно!)

### Huawei MatePad 11.5"S (HarmonyOS 4.2)
- APK ставятся штатно (AppGallery-магазин не нужен).
- Если сессия умирает при сворачивании: **Настройки → Приложения → UbuntuTab → Запуск → снять ограничения фоновой активности**; батарею — «Не ограничивать».
- Вывод на монитор: USB-C (DP alt mode) — переходник USB-C→HDMI/DP; если образа нет — экран планшета и есть монитор.
- У MatePad нет Google-сервисов — не мешает: всё локально.

### Infinix Note 30 (XOS 13 / Android 13)
- **Обязательно**: Настройки → О телефоне → 7 раз по «Номер сборки» (включить «Для разработчиков») → **включить «Не сохранять процессы»/«Лимит фоновых процессов» → «Стандартно», отключить «Убивать процессы»**, если пункт есть; XOS агрессивно убивает фоновые.
- **Аккумулятор → UbuntuTab → Без ограничений** (иначе долгая установка прервётся).
- Не сворачивай приложение во время установки.

### Общее
- Установка идёт в фоне приложения; прерывание = начать заново.
- GPU: на Adreno работает аппаратное ускорение (Turnip/Zink); на Mali/Maleoon (Huawei/Infinix) — программный рендер (llvmpipe): XFCE быстрый, тяжёлые 3D-приложения — нет.
- snap-пакеты не работают (нет snapd в proot) — используй deb-версии (Firefox ESR уже в образе).

## Команды (в терминале UbuntuTab)

| Команда | Что делает |
|---|---|
| `bash ~/scripts/start-ubuntu.sh` | Запустить Ubuntu-сессию вручную |
| `proot-distro login ubuntu` | Войти в контейнер без десктопа |
| `bash ~/scripts/ubuntu-setup.sh` | Переустановка/починка окружения |

## Разработка

- Flutter-приложение: `app/` (сборка: `cd app && flutter build apk --release`)
- Скрипты окружения: `scripts/` (ubuntu-setup.sh, start-ubuntu.sh)
- Архитектура форка: [docs/FORK-ARCHITECTURE.md](docs/FORK-ARCHITECTURE.md)

## Лицензия и credits

GPL-3.0 (только). Форк [DroidDesk](https://github.com/orailnoor/DroidDesk) © orailnoor (YouTube: [@orailnoor](https://youtube.com/@orailnoor)), который, в свою очередь, использует компоненты [Termux](https://termux.dev), [Termux:X11](https://github.com/termux/termux-x11), TUR и proot. См. [NOTICE.md](NOTICE.md) и [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
