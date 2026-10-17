#!/bin/bash
# 打发布包：通用二进制 + 压缩成 dist/DayProgress-<版本>.zip
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

echo "==> 打包 ${ARCHIVE}"
ditto -c -k --norsrc --keepParent "$APP" "$ARCHIVE"
ls -lh "$ARCHIVE"
echo "完成：$(pwd)/${ARCHIVE}"
