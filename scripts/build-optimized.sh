#!/bin/bash

# =============================================================================
# go-stock 优化构建脚本
# 支持平台：Windows, macOS (Intel/ARM), Linux
# 特性：分步构建、内存优化、错误处理、重试机制
# =============================================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "go-stock 优化构建脚本"
    echo ""
    echo "用法: $0 [平台] [选项]"
    echo ""
    echo "支持的平台:"
    echo "  windows        - Windows AMD64"
    echo "  macos          - macOS Universal (Intel + ARM)"
    echo "  macos-intel    - macOS Intel x64"
    echo "  macos-arm      - macOS ARM64"
    echo "  linux          - Linux AMD64"
    echo "  all            - 所有平台"
    echo ""
    echo "选项:"
    echo "  --dev          - 开发模式构建"
    echo "  --clean        - 清理构建"
    echo "  --skip-frontend - 跳过前端构建"
    echo "  --help         - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 macos                # 构建 macOS Universal 版本"
    echo "  $0 windows --clean      # 清理构建 Windows 版本"
    echo "  $0 all                  # 构建所有平台版本"
}

# 检查必要工具
check_requirements() {
    log_step "检查构建环境..."
    
    # 检查 Go
    if ! command -v go &> /dev/null; then
        log_error "Go 未安装或不在 PATH 中"
        exit 1
    fi
    log_info "Go 版本: $(go version)"
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js 未安装或不在 PATH 中"
        exit 1
    fi
    log_info "Node.js 版本: $(node --version)"
    
    # 检查 npm
    if ! command -v npm &> /dev/null; then
        log_error "npm 未安装或不在 PATH 中"
        exit 1
    fi
    log_info "npm 版本: $(npm --version)"
    
    # 检查 Wails
    if ! command -v wails &> /dev/null; then
        log_error "Wails CLI 未安装或不在 PATH 中"
        log_info "请运行: go install github.com/wailsapp/wails/v2/cmd/wails@latest"
        exit 1
    fi
    log_info "Wails 版本: $(wails version)"
}

# 清理函数
clean_build() {
    log_step "清理构建产物..."
    
    # 清理 build 目录
    if [ -d "build/bin" ]; then
        rm -rf build/bin
        log_info "已清理 build/bin 目录"
    fi
    
    # 清理前端 dist 目录
    if [ -d "frontend/dist" ]; then
        rm -rf frontend/dist
        log_info "已清理 frontend/dist 目录"
    fi
    
    # 清理 Go 模块缓存
    go clean -modcache 2>/dev/null || true
    log_info "已清理 Go 模块缓存"
}

# 检查系统资源
check_system_resources() {
    log_step "检查系统资源..."
    
    # 检查可用内存 (macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        available_memory=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        available_mb=$((available_memory * 4096 / 1024 / 1024))
        log_info "可用内存: ${available_mb}MB"
        
        if [ $available_mb -lt 1000 ]; then
            log_warn "可用内存不足，建议关闭其他应用程序"
        fi
    fi
    
    # 检查磁盘空间
    available_space=$(df -h . | awk 'NR==2 {print $4}')
    log_info "可用磁盘空间: $available_space"
}

# 构建前端
build_frontend() {
    if [ "$SKIP_FRONTEND" = true ]; then
        log_info "跳过前端构建"
        return 0
    fi
    
    log_step "构建前端..."
    
    cd frontend
    
    # 安装依赖
    if [ ! -d "node_modules" ] || [ ! -f "package-lock.json" ]; then
        log_info "安装前端依赖..."
        npm install
    fi
    
    # 构建前端
    log_info "编译前端代码..."
    npm run build
    
    # 检查构建结果
    if [ ! -d "dist" ]; then
        log_error "前端构建失败：dist 目录不存在"
        exit 1
    fi
    
    log_info "前端构建成功"
    cd ..
}

# 构建指定平台
build_platform() {
    local platform=$1
    local platform_name=$2
    
    log_step "构建 $platform_name..."
    
    # 构建参数
    local build_args="--clean -s -skipbindings"
    
    if [ "$platform" != "default" ]; then
        build_args="$build_args --platform $platform"
    fi
    
    # 尝试构建，如果失败则重试
    local max_retries=2
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        log_info "尝试构建 $platform_name (第 $((retry_count + 1)) 次)..."
        
        if wails build $build_args; then
            log_info "$platform_name 构建成功！"
            return 0
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                log_warn "构建失败，30秒后重试..."
                sleep 30
                
                # 清理可能的残留文件
                go clean -cache 2>/dev/null || true
            else
                log_error "$platform_name 构建失败"
                return 1
            fi
        fi
    done
}

# 显示构建结果
show_build_results() {
    log_step "构建结果："
    
    if [ -d "build/bin" ]; then
        echo ""
        find build/bin -type f -name "*.exe" -o -name "*.app" -o -name "go-stock" | while read file; do
            size=$(du -h "$file" | cut -f1)
            log_info "✓ $file ($size)"
        done
        echo ""
    else
        log_warn "未找到构建产物"
    fi
}

# 主函数
main() {
    # 解析参数
    PLATFORM=""
    CLEAN_BUILD=false
    DEV_MODE=false
    SKIP_FRONTEND=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            --dev)
                DEV_MODE=true
                shift
                ;;
            --skip-frontend)
                SKIP_FRONTEND=true
                shift
                ;;
            windows|macos|macos-intel|macos-arm|linux|all)
                PLATFORM=$1
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 如果没有指定平台，根据当前系统选择默认平台
    if [ -z "$PLATFORM" ]; then
        case "$OSTYPE" in
            darwin*) PLATFORM="macos" ;;
            linux*) PLATFORM="linux" ;;
            msys*|win32*) PLATFORM="windows" ;;
            *) 
                log_error "无法检测当前平台，请手动指定"
                show_help
                exit 1
                ;;
        esac
        log_info "自动检测平台: $PLATFORM"
    fi
    
    # 确保在项目根目录
    if [ ! -f "wails.json" ]; then
        log_error "请在项目根目录运行此脚本"
        exit 1
    fi
    
    echo "🚀 go-stock 优化构建脚本"
    echo "=========================="
    
    # 检查环境
    check_requirements
    check_system_resources
    
    # 清理构建（如果需要）
    if [ "$CLEAN_BUILD" = true ]; then
        clean_build
    fi
    
    # 准备 Go 模块
    log_step "准备 Go 模块..."
    go mod tidy
    go mod verify
    
    # 构建前端
    build_frontend
    
    # 构建指定平台
    case $PLATFORM in
        windows)
            build_platform "windows/amd64" "Windows AMD64"
            ;;
        macos)
            build_platform "darwin/universal" "macOS Universal"
            ;;
        macos-intel)
            build_platform "darwin/amd64" "macOS Intel"
            ;;
        macos-arm)
            build_platform "darwin/arm64" "macOS ARM"
            ;;
        linux)
            build_platform "linux/amd64" "Linux AMD64"
            ;;
        all)
            log_info "构建所有平台..."
            build_platform "windows/amd64" "Windows AMD64"
            build_platform "darwin/universal" "macOS Universal"
            build_platform "linux/amd64" "Linux AMD64"
            ;;
        *)
            log_error "不支持的平台: $PLATFORM"
            exit 1
            ;;
    esac
    
    # 显示结果
    show_build_results
    
    echo ""
    echo "🎉 构建完成！"
    echo "构建产物位于: build/bin/"
    
    # 询问是否启动应用程序（仅限单平台构建且为 macOS）
    if [[ "$PLATFORM" == "macos"* ]] && [ -d "build/bin/go-stock.app" ]; then
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
}

# 运行主函数
main "$@" 