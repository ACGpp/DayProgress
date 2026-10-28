#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build-cache/tests
swiftc -Onone -swift-version 5 -parse-as-library \
  -module-cache-path "$(pwd)/.build-cache/modules" \
  Sources/DayClock.swift Sources/Localization.swift Tests/ClockTests.swift \
  -o .build-cache/tests/clock-tests
.build-cache/tests/clock-tests
