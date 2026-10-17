#!/bin/bash
# 把构建好的 App 安装到「应用程序」并启动。
# 源：build/DayProgress.app；只做本地复制，不会联网，也不会使用 sudo。
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="DayProgress"
SOURCE="build/${APP_NAME}.app"
MIN_MACOS_MAJOR=13

note() { printf '    %s\n' "$*"; }
step() { printf '==> %s\n' "$*"; }
warn() { printf '!!  %s\n' "$*" >&2; }

# 1. 检查 macOS 版本
if command -v sw_vers >/dev/null 2>&1; then
    MACOS_VERSION="$(sw_vers -productVersion)"
    MACOS_MAJOR="${MACOS_VERSION%%.*}"
    if [[ "$MACOS_MAJOR" =~ ^[0-9]+$ ]] && (( 10#$MACOS_MAJOR < MIN_MACOS_MAJOR )); then
        warn "DayProgress 需要 macOS ${MIN_MACOS_MAJOR} 或更高版本，当前系统是 macOS ${MACOS_VERSION}。"
        exit 1
    fi
    step "检查系统"
    note "macOS ${MACOS_VERSION}"
else
    warn "没能检测 macOS 版本，跳过版本检查。"
fi

# 2. 检查构建产物
if [ ! -d "$SOURCE" ]; then
    warn "还没构建过，先运行：./build.sh"
    exit 1
fi
if [ ! -x "$SOURCE/Contents/MacOS/${APP_NAME}" ]; then
    warn "构建产物不完整，找不到可执行文件：$SOURCE/Contents/MacOS/${APP_NAME}"
    exit 1
fi

# 3. 选择安装位置：优先 /Applications，不可写就退到 ~/Applications
if [ -w "/Applications" ]; then
    TARGET_DIR="/Applications"
else
    TARGET_DIR="$HOME/Applications"
    mkdir -p "$TARGET_DIR"
fi
TARGET="${TARGET_DIR}/${APP_NAME}.app"

# 双重保险：只允许操作自己安装的 App bundle。
case "$TARGET" in
    "/Applications/${APP_NAME}.app"|"$HOME/Applications/${APP_NAME}.app") ;;
    *) warn "目标路径异常：$TARGET"; exit 1 ;;
esac

step "安装 ${APP_NAME}"
note "从 ${SOURCE}"
note "到 ${TARGET}"

if pkill -f "${TARGET}/Contents/MacOS/${APP_NAME}" >/dev/null 2>&1; then
    note "已停止正在运行的旧版本"
    sleep 1
fi

rm -rf "$TARGET"
cp -R "$SOURCE" "$TARGET"
xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null || true

# 4. 从刚装好的 App 里读版本号
VERSION=""
if [ -x /usr/libexec/PlistBuddy ]; then
    VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$TARGET/Contents/Info.plist" 2>/dev/null || true)"
fi
if [ -z "$VERSION" ]; then
    VERSION="$(defaults read "$TARGET/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || true)"
fi
VERSION="${VERSION:-未知版本}"

ARCHS=""
if command -v lipo >/dev/null 2>&1; then
    ARCHS="$(lipo -archs "$TARGET/Contents/MacOS/${APP_NAME}" 2>/dev/null || true)"
fi

step "完成"
note "${APP_NAME} ${VERSION} 已安装到 ${TARGET}"
if [ -n "$ARCHS" ]; then
    note "架构：${ARCHS}"
fi

if open "$TARGET"; then
    note "已启动。看屏幕右上角菜单栏的沙漏图标。"
else
    warn "安装完成，但自动启动失败；请到「应用程序」里手动打开。"
fi

cat <<EOF

第一次打开如果被系统拦截（App 未公证，属于正常现象）：
  系统设置 → 隐私与安全性 →「仍要打开」（英文界面 Open Anyway）
  macOS 15+ 上右键 →「打开」不一定管用，请用上面的按钮。
  仅在确认 App 来自官方 Release 时，才考虑：
  xattr -dr com.apple.quarantine "${TARGET}"
  （本脚本复制时已清除隔离标记，所以通常不会弹。）

退出：点菜单栏图标 → 面板底部「退出」。
EOF
