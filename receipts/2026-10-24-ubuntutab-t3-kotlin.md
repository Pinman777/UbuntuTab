# Receipt — UbuntuTab Phase 2, T3a/T3b: Kotlin-интеграция скриптов и сканера приложений

- **date:** 2026-10-24
- **requester:** zeon → **delegator:** default (Tech Lead)
- **executor:** qwen_code
- **автономия:** L1 (только repo `~/projects/ubuntu-tab`; правки исключительно `app/android/**` (Kotlin), `app/pubspec.yaml`, `app/assets/**`, этот receipt; никаких внешних отправок)
- **authority:** docs/FORK-ARCHITECTURE.md (п.7: T3a бандлинг скриптов, T3b сетка приложений из контейнера) + задача T3 в диалоге делегации

## Artifacts

| Файл | Изменение |
|---|---|
| `app/assets/scripts/*.sh` (5 новых) | Копии `scripts/` из T1 (ubuntu-setup, postinstall, start-desktop, start-ubuntu, ubuntu-menu-sync), забандлены как Flutter-ассеты APK |
| `app/pubspec.yaml` | `+ assets/scripts/` в секции assets |
| `app/android/.../runtime/LinuxRuntime.kt` | T3a: `SESSION_SCRIPT_ASSETS` (5 имён) + `deploySessionScripts()` — копирует скрипты из ассетов в `filesDir/home/scripts/`, `setExecutable(true,false)`, перезапись всегда при setup (идемпотентно, апгрейд приложения обновляет копии). Вызовы: из `setupBootstrap()` (канал `setupBootstrap` — до `bash ~/scripts/ubuntu-setup.sh` в Dart-флоу) и из ветки «bootstrap уже извлечён» в `extractBootstrapIfNeeded()` (upgrade-путь) |
| `app/android/.../runtime/DesktopIntegration.kt` | T3b: `search()` no-root добавлены пути proot-контейнера — `usr/var/lib/proot-distro/installed-rootfs/ubuntu-24.04/{usr/share/applications, root/.local/share/applications}`; контейнер идёт ПЕРВЫМ в списке, чтобы `distinctBy name` оставлял контейнерную запись при конфликте с Termux-нативной |
| `app/android/.../runtime/LinuxAppIcons.kt` | T3b: `find()` до Papirus-fallback добавлены (1) `exportedContainerIcon` — иконки, экспортированные T1 `ubuntu-menu-sync.sh` в `home/.local/share/ubuntutab/apps/icons/<id>.{png,svg}`; (2) `containerIcon` — резолв `Icon=` из .desktop контейнера через rootfs-темы (`usr/share/icons/*/` PNG 512→32, затем SVG scalable→48, затем `usr/share/pixmaps`), абсолютные `Icon=`-пути через rootfs; только png/svg (XPM пропускается — Flutter не рендерит, остаётся плейсхолдер) |

Пути согласованы с T1-скриптами и окружением сессии: `getTermuxEnv()` задаёт `PREFIX=filesDir/usr`, `HOME=filesDir/home` → ROOTFS в menu-sync (`$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu-24.04`) и OUT_DIR (`$HOME/.local/share/ubuntutab/apps`) материализуются ровно по тем путям, которые читает Kotlin.

## Verify (команды + результаты)

```
$ cd app && ~/development/flutter/bin/flutter build apk --debug
✓ Built build/app/outputs/flutter-apk/app-debug.apk        # EXIT=0 (Gradle assembleDebug ~15s)

$ unzip -l app/build/app/outputs/flutter-apk/app-debug.apk | grep 'flutter_assets/assets/scripts/'
assets/flutter_assets/assets/scripts/postinstall.sh         7819
assets/flutter_assets/assets/scripts/start-desktop.sh       1269
assets/flutter_assets/assets/scripts/start-ubuntu.sh        3766
assets/flutter_assets/assets/scripts/ubuntu-menu-sync.sh    6612
assets/flutter_assets/assets/scripts/ubuntu-setup.sh        4370   # все 5 скриптов в APK

$ git status --short && git diff --stat
 M app/analysis_options.yaml          # pre-existing до T3 (см. Exceptions)
 M app/pubspec.lock                   # pre-existing до T3
 M app/android/.../runtime/DesktopIntegration.kt    | 11 +++-
 M app/android/.../runtime/LinuxAppIcons.kt         | 63 ++++++++++++++
 M app/android/.../runtime/LinuxRuntime.kt          | 38 ++++++++
 M app/pubspec.yaml                                |  1 +
?? app/assets/scripts/                             # новые, T3a
# изменённые пути — строго из разрешённого списка ✅
```

- **Сборка:** exit 0, APK собран ✅
- **Границы:** только `app/android/**` (3 Kotlin-файла), `app/pubspec.yaml`, `app/assets/scripts/**` (+ этот receipt). scripts/, README, docs/, LICENSES/, NOTICE.md, chroot-ветки не тронуты ✅
- **Метод проверки иконок/путей:** статический анализ (устройств нет) — пути ROOTFS/иконок сверены с `scripts/ubuntu-menu-sync.sh` (переменные ROOTFS/OUT_DIR/ICONS_OUT) и `LinuxRuntime.getTermuxEnv()` (PREFIX/HOME); порядок деплоя сверен с Dart-флоу `runSetup()` (канал `setupBootstrap` → `executeCommand('bash ~/scripts/ubuntu-setup.sh')` — деплой происходит внутри `setupBootstrap` до запуска скрипта) ✅

## Exceptions

1. **`app/analysis_options.yaml` и `app/pubspec.lock` были изменены ДО начала T3** (видны в git-снапшоте старта сессии) — не трогались; lock дополнительно мог обновить `flutter pub get` при сборке (bump транзитивных версий, напр. matcher 0.12.19→0.12.20). Для коммита T3 их stage'ить не следует без решения Tech Lead.
2. **Живой прогон на устройстве не выполнялся** (нет устройства/эмулятора) — иконки и сетка проверены статически; device-QA у zeon.
3. **XPM-иконки не поддерживаются** (Flutter рендерит png/svg) — для таких приложений плейсхолдер; T1 open question №4 уже это-flagged.
4. **Перезапись скриптов при каждом setup** (простейшая идемпотентность по задаче): локальные правки пользователя в `~/scripts/*` затираются при re-setup/апгрейде — осознанный trade-off.
5. `containerIcon` читает `Icon=` из .desktop при каждом вызове без кэша — приемлемо для масштаба грида; сетевой Papirus-fallback кэшируется как раньше.

## Friction

1. **ИНТЕГРАЦИОННАЯ ДЫРА: UI-грид приложений не подключён к данным.** Метод-канал `searchDesktopItems` (канал `com.droiddesk/core`) имеет Dart-обёртку `UbuntuTabPlatform.searchDesktopItems` (`platform_bridge.dart:272`), но **ни один экран её не вызывает** (grep по `app/lib`: единственные матчинги — определение обёртки). Манифест T1 `apps.json` тоже никем в Dart не читается. Итого: сетка приложений Ubuntu-контейнера сейчас не отображается вообще — T3b расширил Kotlin-поставщика данных, но потребитель должен появиться в следующей UI-итерации. Рекомендуемый контракт для подключения: `searchDesktopItems` (записи `kind=linux`, `id`=desktop-file id) + `launchDesktopItem(kind=linux)` + иконки `getLinuxAppIcon(package=<desktop-id>)` — иконки контейнера уже резолвятся (вкл. экспорт T1).
2. **Два параллельных контракта одних и тех же данных:** T1 `apps.json` (id/name/exec/terminal/icon) vs `DesktopIntegration.search()` (label/subtitle/source/kind/id). Задача T3b явно про `search()`, архитектура (п.7) — про apps.json. Реализовано через `search()` (канал существовал, свежее данных); `apps.json` остаётся без потребителя — Tech Lead'у решить, что канонично (тогда второй убрать или оставить menu-sync только как экспортёр иконок).
3. **ROOTFS-путь и distro-id захардкожены в 3 местах** (ubuntu-menu-sync.sh, DesktopIntegration.kt, LinuxAppIcons.kt) — смена дистро/версии требует синхронной правки; кандидат на общую константу при ближайшей правке.
4. **Дублирование источника скриптов:** `app/assets/scripts/` — ручная копия `scripts/`; при каждом изменении T1-скриптов копировать заново (процедура не автоматизирована — кандидат на pre-build шаг или CI-проверку консистентности).

## Open questions (на ревью Tech Lead)

1. Кто и как подключает UI-грид (friction №1) — T2-итерация или отдельная задача? Потреблять `searchDesktopItems` или `apps.json`?
2. Нужен ли автозапуск `ubuntu-menu-sync.sh` перед показом грида (свежие иконки после `apt install` новых пакетов), или скана ФС в `search()` достаточно, а menu-sync оставить ручным/хуком postinstall?
3. Дедупликация Android vs Linux записей с одинаковым именем (firefox Android + firefox-esr контейнера) — политика отображения в гриде.

## Status

**done** (код готов, сборка зелёная; подключение UI-потребителя грида — следующая итерация, device-QA — у zeon). Все границы L1 соблюдены.
