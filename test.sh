#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build-cache/tests
swiftc -Onone -swift-version 5 -parse-as-library \
  -module-cache-path "$(pwd)/.build-cache/modules" \
  Sources/DayClock.swift Sources/Localization.swift Sources/MenuBarLabel.swift Tests/ClockTests.swift \
  -o .build-cache/tests/clock-tests
.build-cache/tests/clock-tests
swiftc -Onone -swift-version 5 -parse-as-library \
  -module-cache-path "$(pwd)/.build-cache/modules" \
  Sources/AppDelegate.swift Sources/DayClock.swift Sources/Localization.swift \
  Sources/FloatingCardView.swift Sources/DayRing.swift Sources/PopoverView.swift \
  Sources/WelcomeView.swift Sources/LoginItem.swift Tests/PanelTests.swift \
  -o .build-cache/tests/panel-tests
.build-cache/tests/panel-tests
