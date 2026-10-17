<p align="center">
  <img src="docs/icon.png" width="112" alt="DayProgress icon">
</p>

<h1 align="center">DayProgress</h1>

<p align="center">
  <b>A tiny macOS menu bar app that shows how much of today is already gone.</b><br>
  <a href="README.md">中文</a> · English
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13%2B-blue" alt="macOS 13+">
  <img src="https://img.shields.io/badge/SwiftUI-%F0%9F%A7%A9-orange" alt="SwiftUI">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT">
</p>

## Why

Someone on X said it best: **24 minutes is 1/60 of your day.**

1440 minutes a day — 24 of them is 1.67%, and it takes one short scroll to burn one. I built this little app with **DeepSeek-V4-Flash-1017** to make that number visible. It won't manage your time; it just shows it.

## Download

- Grab the latest `DayProgress-x.y.z.zip` from [Releases](../../releases/latest), unzip it and drop `DayProgress.app` into Applications.
- Universal binary (Apple Silicon + Intel), macOS 13+.
- The app is ad-hoc signed and not notarized. If macOS blocks it on first launch, use System Settings → Privacy & Security → Open Anyway (on macOS 15+ right-click → Open may not be enough).

## Screenshots

Menu bar panel and floating card:

![Menu bar panel](docs/popover.png)

![Floating card](docs/floating-card.png)

Settings page (gear icon on the panel):

![Settings](docs/popover-settings.png)

Chinese / English UI, switchable on the fly:

![English panel](docs/popover-en.png)

Progress mode can show the day *remaining* instead of elapsed:

![Remaining mode](docs/floating-card-remaining.png)

Three sizes and three styles (dark / glass / clear):

![Medium card](docs/floating-card-medium.png)

![Small card](docs/floating-card-mini.png)

![Glass card](docs/floating-card-glass.png)

## Features

- **Live percentage** in the menu bar (`⏳ 79.0%`), full panel on click.
- **Floating card**: ring + big percentage + time left; always on top, draggable, remembers its position.
- **Elapsed / remaining mode** — the ring follows the selected value.
- **Chinese / English UI**, switchable in settings.
- **19 time zones** plus "follow system"; the date and “today” follow the chosen zone.
- **Day window**: natural day (00:00–24:00) or a custom range (e.g. 07:00–23:00, overnight supported).
- **Percent precision**: whole numbers or one decimal.
- **Card size / style**: large / medium / small × dark / glass / clear.
- **Launch at login**, all settings persisted locally.
- Refreshes every 10 seconds.

## Build from source

Requires macOS 13+ with Xcode or Command Line Tools (`swiftc`).

```bash
git clone https://github.com/ACGpp/DayProgress.git
cd DayProgress

./build.sh              # current architecture
UNIVERSAL=1 ./build.sh  # universal (arm64 + x86_64)
./install.sh            # copy to /Applications and launch
./release.sh            # universal binary + zip in dist/
```

Or run it directly: `open build/DayProgress.app`.

GitHub Actions builds on every push, and publishes a Release when a `v*` tag is pushed.

## Development

```
DayProgress/
├── Sources/
│   ├── DayProgressApp.swift   # menu bar entry
│   ├── AppDelegate.swift      # floating NSPanel: size, style, position
│   ├── DayClock.swift         # time window, time zone, percentages, strings
│   ├── Localization.swift     # language / progress mode / precision / zones
│   ├── DayRing.swift          # smooth ring + 24-slot ring + palette
│   ├── FloatingCardView.swift # card UI (3 sizes × 3 styles)
│   ├── PopoverView.swift      # panel: main page + settings page
│   └── LoginItem.swift        # launch at login (SMAppService)
├── Tools/MakePreview/         # offscreen previews + app icon
├── docs/                      # README screenshots and icon
├── build.sh / preview.sh / release.sh / install.sh
```

Quick UI preview without clicking the menu bar:

```bash
./preview.sh
```

Debug window (useful for screenshots):

```bash
DAYPROGRESS_DEBUG_POPOVER=1 ./build/DayProgress.app/Contents/MacOS/DayProgress          # main page
DAYPROGRESS_DEBUG_POPOVER=settings ./build/DayProgress.app/Contents/MacOS/DayProgress   # settings page
```

### Notes

- Not notarized — meant for personal use; you may need to allow it manually on first launch.
- “Launch at login” expects the app to live in Applications.
- All settings are stored locally in `com.tree.dayprogress` UserDefaults. Nothing is uploaded.

## Credits

- Inspired by a post on X about “24 minutes = 1/60 of your day”.
- Built end-to-end with **DeepSeek-V4-Flash-1017** — from idea to an installable Mac app in one afternoon.
- UI and icon drawn with SwiftUI.

If this makes you glance at the clock a little more often, a Star ⭐️ is appreciated.

## License

[MIT](LICENSE) © 2026 shouzhong
