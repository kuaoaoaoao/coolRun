#!/bin/bash
#
# create-dmg.sh
# 从 Xcode 导出的 coolRun.app 制作 DMG 安装包
#
# 用法:
#   ./scripts/create-dmg.sh /path/to/coolRun.app
#
# 如果不传参数，默认在当前目录下查找 coolRun.app
#

set -euo pipefail

APP_PATH="${1:-coolRun.app}"
VOLUME_NAME="coolRun"
DMG_NAME="coolRun.dmg"
DMG_DIR="coolRun-dmg-tmp"

# 检查 app 是否存在
if [ ! -d "$APP_PATH" ]; then
  echo "❌ 找不到 $APP_PATH"
  echo "用法: $0 /path/to/coolRun.app"
  exit 1
fi

echo "📦 正在制作 DMG..."

# 清理旧的临时目录和 dmg
rm -rf "$DMG_DIR"
rm -f "$DMG_NAME"

# 创建临时目录并复制 app
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

# 创建 DMG
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_DIR" \
  -ov \
  -format UDZO \
  "$DMG_NAME"

# 清理临时目录
rm -rf "$DMG_DIR"

echo "✅ 已生成: $(pwd)/$DMG_NAME"
