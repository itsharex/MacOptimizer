#!/bin/bash

# 应用卸载器 - 构建脚本
# 构建 Universal Binary (Intel + Apple Silicon) 并打包 DMG

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}    Mac优化大师 (MacOptimizer) 构建脚本${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 1. 定义变量
APP_NAME="Mac优化大师"
EXECUTABLE_NAME="AppUninstaller"
BUNDLE_NAME="${APP_NAME}.app"
BUILD_DIR="build"
SOURCE_DIR="AppUninstaller"
DMG_NAME="${APP_NAME}.dmg"

# 2. 检查源文件
echo -e "${YELLOW}[1/7] 检查源文件...${NC}"
SWIFT_FILES=("${SOURCE_DIR}"/*.swift)
for file in "${SWIFT_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}错误: 找不到源文件 $file${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✓ 源文件检查通过${NC}"

# 3. 准备构建目录
echo -e "${YELLOW}[2/7] 准备构建目录...${NC}"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/${BUNDLE_NAME}/Contents/MacOS"
mkdir -p "${BUILD_DIR}/${BUNDLE_NAME}/Contents/Resources"
echo -e "${GREEN}✓ 目录准备完成${NC}"

# 4. 复制资源
echo -e "${YELLOW}[3/7] 复制资源文件...${NC}"
cp "${SOURCE_DIR}/Info.plist" "${BUILD_DIR}/${BUNDLE_NAME}/Contents/"
if [ -f "${SOURCE_DIR}/AppIcon.icns" ]; then
    cp "${SOURCE_DIR}/AppIcon.icns" "${BUILD_DIR}/${BUNDLE_NAME}/Contents/Resources/"
    echo -e "${GREEN}✓ Info.plist 和图标已复制${NC}"
else
    echo -e "${YELLOW}⚠ 警告: 未找到图标文件${NC}"
fi

# 5. 编译 (Apple Silicon)
echo -e "${YELLOW}[4/7] 正在编译 (Apple Silicon)...${NC}"

echo -n "  - 编译 arm64... "
swiftc -O \
    -target arm64-apple-macos13.0 \
    -sdk $(xcrun --sdk macosx --show-sdk-path) \
    -parse-as-library \
    -o "${BUILD_DIR}/${BUNDLE_NAME}/Contents/MacOS/${EXECUTABLE_NAME}" \
    "${SWIFT_FILES[@]}"
echo -e "${GREEN}OK${NC}"

# 6. 签名
echo -e "${YELLOW}[5/7] 签名应用...${NC}"
codesign --force --deep --sign - "${BUILD_DIR}/${BUNDLE_NAME}"
echo -e "${GREEN}✓ 签名完成${NC}"

# 7. 打包 DMG
echo -e "${YELLOW}[6/7] 打包 DMG 显示镜像...${NC}"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}"
if [ -f "${DMG_PATH}" ]; then
    rm "${DMG_PATH}"
fi

hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${BUILD_DIR}/${BUNDLE_NAME}" \
    -ov -format UDZO \
    "${DMG_PATH}" > /dev/null

echo -e "${GREEN}✓ DMG 打包完成${NC}"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}构建 & 打包全部完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "应用包: ${YELLOW}${BUILD_DIR}/${BUNDLE_NAME}${NC}"
echo -e "DMG文件: ${YELLOW}${DMG_PATH}${NC}"
echo ""
