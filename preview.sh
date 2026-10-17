#!/bin/bash
# 渲染界面预览图 & App 图标（开发用）
set -euo pipefail
cd "$(dirname "$0")"

CACHE="$(pwd)/.build-cache/modules"
mkdir -p "$CACHE" build/preview

swiftc -swift-version 5 -parse-as-library \
    -module-cache-path "$CACHE" \
    Sources/DayClock.swift \
    Sources/Localization.swift \
    Sources/DayRing.swift \
    Sources/FloatingCardView.swift \
    Sources/PopoverView.swift \
    Sources/LoginItem.swift \
    Tools/MakePreview/main.swift \
    -o build/make-preview

./build/make-preview
