#!/bin/bash
# 把构建好的 App 安装到「应用程序」并启动
set -euo pipefail
cd "$(dirname "$0")"

SOURCE="build/DayProgress.app"
if [ ! -d "$SOURCE" ]; then
    echo "还没构建过，先运行：./build.sh"
    exit 1
fi

if [ -w "/Applications" ]; then
    TARGET_DIR="/Applications"
else
    TARGET_DIR="$HOME/Applications"
    mkdir -p "$TARGET_DIR"
fi
TARGET="$TARGET_DIR/DayProgress.app"

case "$TARGET" in
    */DayProgress.app) ;;
    *) echo "目标路径异常：$TARGET"; exit 1 ;;
esac

pkill -f "$TARGET/Contents/MacOS/DayProgress" >/dev/null 2>&1 || true
sleep 1
rm -rf "$TARGET"
cp -R "$SOURCE" "$TARGET"
xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null || true
open "$TARGET"

echo "已安装到 $TARGET 并启动"
echo "退出：点菜单栏图标 → 退出"
