#!/bin/bash
# 编译 DayProgress.app 到 DayProgress/build/DayProgress.app
#   ./build.sh                 # 只编译当前架构（快）
#   UNIVERSAL=1 ./build.sh     # 编译 arm64 + x86_64 通用二进制（发布用）
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="DayProgress"
BUNDLE="build/${APP_NAME}.app"
BINARY="$BUNDLE/Contents/MacOS/${APP_NAME}"
CACHE="$(pwd)/.build-cache/modules"
DEPLOYMENT_TARGET="13.0"

SOURCES=(
    Sources/DayProgressApp.swift
    Sources/AppDelegate.swift
    Sources/DayClock.swift
    Sources/Localization.swift
    Sources/DayRing.swift
    Sources/FloatingCardView.swift
    Sources/PopoverView.swift
    Sources/LoginItem.swift
    Sources/WelcomeView.swift
)

rm -rf "$BUNDLE"
mkdir -p "$CACHE" "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

build_arch() {
    local arch="$1"
    local output="$2"
    echo "    编译 ${arch} ..."
    swiftc -O -swift-version 5 -parse-as-library \
        -module-cache-path "$CACHE" \
        -target "${arch}-apple-macos${DEPLOYMENT_TARGET}" \
        "${SOURCES[@]}" \
        -o "$output"
}

echo "==> 编译 ${APP_NAME}"
if [ "${UNIVERSAL:-0}" = "1" ]; then
    build_arch arm64 "build/${APP_NAME}-arm64"
    build_arch x86_64 "build/${APP_NAME}-x86_64"
    lipo -create "build/${APP_NAME}-arm64" "build/${APP_NAME}-x86_64" -output "$BINARY"
    rm -f "build/${APP_NAME}-arm64" "build/${APP_NAME}-x86_64"
    echo "    架构：$(lipo -archs "$BINARY")"
else
    build_arch "$(uname -m)" "$BINARY"
fi

cp Resources/Info.plist "$BUNDLE/Contents/Info.plist"
install -m 644 LICENSE "$BUNDLE/Contents/Resources/LICENSE"

ICON_SOURCE=""
if [ -f "build/AppIcon.png" ]; then
    ICON_SOURCE="build/AppIcon.png"
elif [ -f "docs/icon.png" ]; then
    ICON_SOURCE="docs/icon.png"
fi

if [ -n "$ICON_SOURCE" ] && command -v iconutil >/dev/null 2>&1; then
    echo "==> 生成图标"
    ICONSET="build/AppIcon.iconset"
    rm -rf "$ICONSET"
    mkdir -p "$ICONSET"
    icon_size() {
        sips -z "$1" "$1" "$ICON_SOURCE" --out "$ICONSET/$2" >/dev/null
    }
    icon_size 16   "icon_16x16.png"
    icon_size 32   "icon_16x16@2x.png"
    icon_size 32   "icon_32x32.png"
    icon_size 64   "icon_32x32@2x.png"
    icon_size 128  "icon_128x128.png"
    icon_size 256  "icon_128x128@2x.png"
    icon_size 256  "icon_256x256.png"
    icon_size 512  "icon_256x256@2x.png"
    icon_size 512  "icon_512x512.png"
    icon_size 1024 "icon_512x512@2x.png"
    if iconutil -c icns "$ICONSET" -o "$BUNDLE/Contents/Resources/AppIcon.icns"; then
        rm -rf "$ICONSET"
    else
        echo "!! 图标生成失败，跳过"
    fi
fi

echo "==> 签名（ad-hoc）"
codesign --force --sign - "$BUNDLE" >/dev/null

echo "==> 构建完成：$(pwd)/$BUNDLE"
echo "    直接运行：open \"$(pwd)/$BUNDLE\""
echo "    安装到「应用程序」：./install.sh"
echo "    打发布包：./release.sh"
