@echo off
REM =============================================================================
REM go-stock Windows 优化构建脚本
REM 支持平台：Windows, macOS, Linux
REM 特性：分步构建、内存优化、错误处理
REM =============================================================================

setlocal enabledelayedexpansion

REM 设置变量
set "PLATFORM="
set "CLEAN_BUILD=false"
set "SKIP_FRONTEND=false"
set "PROJECT_ROOT=%~dp0.."

REM 解析命令行参数
:parse_args
if "%~1"=="" goto :after_parse
if "%~1"=="--help" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="--clean" set "CLEAN_BUILD=true" & shift & goto :parse_args
if "%~1"=="--skip-frontend" set "SKIP_FRONTEND=true" & shift & goto :parse_args
if "%~1"=="windows" set "PLATFORM=windows" & shift & goto :parse_args
if "%~1"=="macos" set "PLATFORM=macos" & shift & goto :parse_args
if "%~1"=="linux" set "PLATFORM=linux" & shift & goto :parse_args
if "%~1"=="all" set "PLATFORM=all" & shift & goto :parse_args
echo [ERROR] 未知参数: %~1
goto :show_help

:after_parse

REM 如果没有指定平台，默认为Windows
if "%PLATFORM%"=="" set "PLATFORM=windows"

echo 🚀 go-stock Windows 优化构建脚本
echo ==================================

REM 切换到项目根目录
cd /d "%PROJECT_ROOT%"
if not exist "wails.json" (
    echo [ERROR] 请在项目根目录运行此脚本
    exit /b 1
)

REM 检查必要工具
echo [STEP] 检查构建环境...

where go >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Go 未安装或不在 PATH 中
    exit /b 1
)
for /f "tokens=*" %%i in ('go version') do echo [INFO] Go 版本: %%i

where node >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js 未安装或不在 PATH 中
    exit /b 1
)
for /f "tokens=*" %%i in ('node --version') do echo [INFO] Node.js 版本: %%i

where npm >nul 2>&1
if errorlevel 1 (
    echo [ERROR] npm 未安装或不在 PATH 中
    exit /b 1
)
for /f "tokens=*" %%i in ('npm --version') do echo [INFO] npm 版本: %%i

where wails >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Wails CLI 未安装或不在 PATH 中
    echo [INFO] 请运行: go install github.com/wailsapp/wails/v2/cmd/wails@latest
    exit /b 1
)
for /f "tokens=*" %%i in ('wails version') do echo [INFO] Wails 版本: %%i

REM 清理构建（如果需要）
if "%CLEAN_BUILD%"=="true" (
    echo [STEP] 清理构建产物...
    if exist "build\bin" (
        rmdir /s /q "build\bin"
        echo [INFO] 已清理 build\bin 目录
    )
    if exist "frontend\dist" (
        rmdir /s /q "frontend\dist"
        echo [INFO] 已清理 frontend\dist 目录
    )
    go clean -modcache >nul 2>&1
    echo [INFO] 已清理 Go 模块缓存
)

REM 准备 Go 模块
echo [STEP] 准备 Go 模块...
go mod tidy
if errorlevel 1 (
    echo [ERROR] go mod tidy 失败
    exit /b 1
)

go mod verify
if errorlevel 1 (
    echo [ERROR] go mod verify 失败
    exit /b 1
)

REM 构建前端
if "%SKIP_FRONTEND%"=="false" (
    echo [STEP] 构建前端...
    cd frontend
    
    if not exist "node_modules" (
        echo [INFO] 安装前端依赖...
        npm install
        if errorlevel 1 (
            echo [ERROR] npm install 失败
            exit /b 1
        )
    )
    
    echo [INFO] 编译前端代码...
    npm run build
    if errorlevel 1 (
        echo [ERROR] 前端构建失败
        exit /b 1
    )
    
    if not exist "dist" (
        echo [ERROR] 前端构建失败：dist 目录不存在
        exit /b 1
    )
    
    echo [INFO] 前端构建成功
    cd ..
) else (
    echo [INFO] 跳过前端构建
)

REM 构建指定平台
echo [STEP] 构建应用程序...

if "%PLATFORM%"=="windows" (
    echo [INFO] 构建 Windows AMD64...
    wails build --clean -s -skipbindings --platform windows/amd64
) else if "%PLATFORM%"=="macos" (
    echo [INFO] 构建 macOS Universal...
    wails build --clean -s -skipbindings --platform darwin/universal
) else if "%PLATFORM%"=="linux" (
    echo [INFO] 构建 Linux AMD64...
    wails build --clean -s -skipbindings --platform linux/amd64
) else if "%PLATFORM%"=="all" (
    echo [INFO] 构建所有平台...
    echo [INFO] 构建 Windows AMD64...
    wails build --clean -s -skipbindings --platform windows/amd64
    echo [INFO] 构建 macOS Universal...
    wails build --clean -s -skipbindings --platform darwin/universal
    echo [INFO] 构建 Linux AMD64...
    wails build --clean -s -skipbindings --platform linux/amd64
) else (
    echo [ERROR] 不支持的平台: %PLATFORM%
    exit /b 1
)

if errorlevel 1 (
    echo [ERROR] 构建失败
    exit /b 1
)

REM 显示构建结果
echo [STEP] 构建结果：
if exist "build\bin" (
    echo.
    for /r "build\bin" %%f in (*.exe *.app go-stock) do (
        if exist "%%f" echo [INFO] ✓ %%f
    )
    echo.
) else (
    echo [WARN] 未找到构建产物
)

echo.
echo 🎉 构建完成！
echo 构建产物位于: build\bin\
goto :eof

:show_help
echo go-stock Windows 优化构建脚本
echo.
echo 用法: %~nx0 [平台] [选项]
echo.
echo 支持的平台:
echo   windows        - Windows AMD64
echo   macos          - macOS Universal (Intel + ARM)
echo   linux          - Linux AMD64
echo   all            - 所有平台
echo.
echo 选项:
echo   --clean        - 清理构建
echo   --skip-frontend - 跳过前端构建
echo   --help         - 显示此帮助信息
echo.
echo 示例:
echo   %~nx0 windows           # 构建 Windows 版本
echo   %~nx0 windows --clean   # 清理构建 Windows 版本
echo   %~nx0 all               # 构建所有平台版本
exit /b 0 