#!/bin/bash

# =============================================================================
# go-stock 快速构建脚本
# 适用于日常开发，快速构建当前平台版本
# =============================================================================

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 go-stock 快速构建${NC}"
echo "===================="

# 确保在项目根目录
if [ ! -f "wails.json" ]; then
    echo "❌ 请在项目根目录运行此脚本"
    exit 1
fi

# 检测当前平台
case "$OSTYPE" in
    darwin*) PLATFORM="macOS" ;;
    linux*) PLATFORM="Linux" ;;
    msys*|win32*) PLATFORM="Windows" ;;
    *) PLATFORM="当前平台" ;;
esac

echo -e "${GREEN}📦 构建 $PLATFORM 版本...${NC}"

# 步骤1：构建前端（如果需要）
if [ ! -d "frontend/dist" ] || [ "frontend/src" -nt "frontend/dist" ]; then
    echo -e "${YELLOW}🔧 构建前端...${NC}"
    cd frontend
    npm run build > /dev/null 2>&1
    cd ..
    echo "✅ 前端构建完成"
else
    echo "⏭️  跳过前端构建（已是最新）"
fi

# 步骤2：构建应用程序
echo -e "${YELLOW}🔨 构建应用程序...${NC}"
wails build --clean -s -skipbindings > /dev/null 2>&1

# 检查构建结果
if [ -d "build/bin" ]; then
    echo "✅ 构建成功！"
    
    # 显示构建产物
    echo ""
    echo "📁 构建产物："
    find build/bin -name "*.app" -o -name "*.exe" -o -name "go-stock" | while read file; do
        size=$(du -h "$file" | cut -f1)
        echo "   📄 $(basename "$file") ($size)"
    done
    
    # 自动启动（仅 macOS）
    if [[ "$OSTYPE" == "darwin"* ]] && [ -d "build/bin/go-stock.app" ]; then
        echo ""
        read -p "🚀 是否启动应用程序? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "启动应用程序中..."
            # 直接运行二进制文件，避免脚本环境影响
            nohup ./build/bin/go-stock.app/Contents/MacOS/go-stock > /dev/null 2>&1 &
            # 脱离脚本控制
            disown
            sleep 2
            echo "✅ 应用程序已启动"
            echo "💡 如果应用程序没有正常显示，请手动运行: open build/bin/go-stock.app"
        fi
    fi
else
    echo "❌ 构建失败"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 完成！${NC}" 