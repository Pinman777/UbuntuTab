# UbuntuTab

Полноценная Ubuntu 24.04 с XFCE-десктопом на Android-планшете/телефоне — **без root**. Плюс предустановленный **QwenPaw** (агент-фреймворк) прямо в контейнере.

GPL-3.0 форк [DroidDesk](https://github.com/orailnoor/DroidDesk) (orailnoor) с архитектурой «Ubuntu-first»: настоящая proot-Ubuntu как основная среда, проверенный связкой Termux + Termux:X11.

## Установка (проверенный путь, v0.2)

**1.** Поставь два приложения:
- [Termux с F-Droid](https://f-droid.org/packages/com.termux/) (НЕ из Google Play)
- [Termux:X11 — termux-x11-universal-debug.apk](https://github.com/termux/termux-x11/releases/tag/nightly)

**2.** Открой Termux и вставь одну команду:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Pinman777/UbuntuTab/main/scripts/termux-ubuntutab.sh)"
```

Установит: proot-distro + официальные зеркала Termux → Ubuntu 24.04 (контейнер `ubuntu`) → XFCE + firefox-esr + шрифты/локали ru_RU → QwenPaw (`/opt/qwenpaw`) → стартовый скрипт. ~15–30 минут, нужен Wi-Fi и питание.

**3.** Запуск десктопа:

```bash
bash ~/start-ubuntutab.sh
```

Поднимет X-сервер, приложение Termux:X11 и XFCE. Повторный запуск — та же команда.

### Если GitHub не открывается (DPI)
Если `curl` пишет `Could not resolve host: raw.githubusercontent.com` — ваш провайдер блокирует GitHub. Включи VPN **для приложения Termux** (например, AmneziaVPN → раздельное туннелирование → добавить Termux и Termux:X11).

## Грабли конкретных устройств

- **Aggressive battery/фоны**: Настройки → Для разработчиков → отключить лимит фоновых/дочерних процессов; в настройках батареи разрешить UbuntuTab/Termux фоновую работу. На Huawei: Приложения → Termux → Запуск → вручную + все тумблеры.
- **Чёрный экран с курсором** в Termux:X11 → перезапусти `bash ~/start-ubuntutab.sh` с флагом `-legacy-drawing` (см. [README Termux:X11](https://github.com/termux/termux-x11)).

## Что тестировалось

- Infinix Note 30 (Android 14, Helio G99) — установка и XFCE-десктоп ✅
- Huawei MatePad 11.5"S (HarmonyOS 4.2, Kirin 9000W) — установка ✅, десктоп — в проверке

## Legacy: standalone APK (экспериментально)

В [Releases](https://github.com/Pinman777/UbuntuTab/releases) лежит автономный APK (форк приложения DroidDesk со встроенным бутстрапом). **Известный фундаментальный порок** (унаследован от DroidDesk, см. их COMPLIANCE.md «custom-prefix bootstrap»): пакеты termux-репозиториев несут зашитый путь `/data/data/com.termux/...`, и андроидная песочница запрещает их исполнение из чужого приложения (`bad interpreter: Permission denied`). Рекомендуемый путь — Termux-скрипт выше; APK оставлен как эксперимент.

## Состав и лицензии

Форк DroidDesk (GPL-3.0-only), включает компоненты Termux, Termux:X11, proot-distro, TUR. См. [NOTICE.md](NOTICE.md), [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md), [LICENSES/](LICENSES/), [COMPLIANCE.md](COMPLIANCE.md).
