#!/bin/bash
# 发布包：带安装引导的 DMG 与 ZIP（通用二进制）。
set -euo pipefail
cd "$(dirname "$0")"

UNIVERSAL=1 ./build.sh

APP="build/DayProgress.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")
ARCHIVE="dist/DayProgress-${VERSION}.zip"

rm -rf dist
mkdir -p dist

echo "==> 校验签名与架构"
codesign --verify --deep --strict "$APP"
lipo -archs "$APP/Contents/MacOS/DayProgress"

STAGE="build/installer/DayProgress-${VERSION}"
rm -rf build/installer
mkdir -p "$STAGE"
ditto "$APP" "$STAGE/DayProgress.app"
cp packaging/* "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "==> 打包 ZIP（包含安装指南）"
ditto -c -k --norsrc --keepParent "$STAGE" "$ARCHIVE"
echo "==> 创建 DMG"
hdiutil create -volname "DayProgress ${VERSION}" -srcfolder "$STAGE" \
  -format UDZO -ov "dist/DayProgress-${VERSION}.dmg"
hdiutil verify "dist/DayProgress-${VERSION}.dmg"
(cd dist && shasum -a 256 "DayProgress-${VERSION}.dmg" "DayProgress-${VERSION}.zip" > SHA256SUMS.txt)
ls -lh dist/
