#!/bin/bash
# 渲染界面预览图 & App 图标（开发用）
set -euo pipefail
if [[ "${1:-}" != "" && "${1:-}" != "--update-docs" ]]; then
    echo "Usage: ./preview.sh [--update-docs]" >&2
    exit 1
fi
cd "$(dirname "$0")"

CACHE="$(pwd)/.build-cache/modules"
mkdir -p "$CACHE" build/preview

swiftc -swift-version 5 -parse-as-library \
    -target "$(uname -m)-apple-macos13.0" \
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

if [[ "${1:-}" == "--update-docs" ]]; then
    cp build/preview/card-large-chinese.png docs/floating-card.png
    for variant in medium mini plain glass remaining; do
        cp "build/preview/card-${variant}.png" "docs/floating-card-${variant}.png"
    done
    cp build/preview/popover-light.png docs/popover.png
    for variant in en settings menu-only; do
        cp "build/preview/popover-${variant}.png" "docs/popover-${variant}.png"
    done
    echo "Updated README previews in docs/ (application icon unchanged)."
fi
