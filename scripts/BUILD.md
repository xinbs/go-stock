# go-stock 构建脚本使用说明

本项目提供了多个构建脚本，适用于不同的构建需求和平台。

## 📁 脚本概览

| 脚本文件 | 平台 | 用途 | 推荐场景 |
|---------|------|------|----------|
| `build-optimized.sh` | macOS/Linux | 完整构建脚本，支持多平台 | 正式发布、多平台构建 |
| `build-optimized.bat` | Windows | Windows 版本的完整构建脚本 | Windows 环境构建 |
| `quick-build.sh` | macOS/Linux | 快速构建当前平台 | 日常开发、快速测试 |
| `build-macos.sh` | macOS | macOS Universal 构建 | macOS 专用构建 |
| `build-windows.sh` | Windows | Windows 构建 | Windows 专用构建 |

## 🚀 快速开始

### 1. 日常开发 - 快速构建
```bash
# macOS/Linux
./scripts/quick-build.sh

# Windows (PowerShell)
./scripts/quick-build.sh
```

### 2. 完整构建 - 当前平台
```bash
# macOS/Linux - 自动检测平台
./scripts/build-optimized.sh

# Windows
scripts\build-optimized.bat
```

### 3. 指定平台构建
```bash
# 构建 Windows 版本
./scripts/build-optimized.sh windows

# 构建 macOS 版本
./scripts/build-optimized.sh macos

# 构建 Linux 版本
./scripts/build-optimized.sh linux

# 构建所有平台
./scripts/build-optimized.sh all
```

## 🛠 构建选项

### build-optimized.sh / build-optimized.bat

#### 支持的平台
- `windows` - Windows AMD64
- `macos` - macOS Universal (Intel + ARM)
- `macos-intel` - macOS Intel x64
- `macos-arm` - macOS ARM64
- `linux` - Linux AMD64
- `all` - 所有平台

#### 构建选项
- `--clean` - 清理之前的构建产物
- `--skip-frontend` - 跳过前端构建（使用已有的 dist）
- `--help` - 显示帮助信息

#### 使用示例
```bash
# 清理构建 macOS 版本
./scripts/build-optimized.sh macos --clean

# 跳过前端构建，直接构建 Windows 版本
./scripts/build-optimized.sh windows --skip-frontend

# 构建所有平台，清理之前的构建
./scripts/build-optimized.sh all --clean
```

## 🔧 环境要求

### 必备工具
- **Go** 1.23.0+
- **Node.js** 16+
- **npm** 8+
- **Wails CLI** v2.10.0+

### 安装 Wails CLI
```bash
go install github.com/wailsapp/wails/v2/cmd/wails@latest
```

### 检查环境
```bash
go version
node --version
npm --version
wails version
```

## 📦 构建产物

构建完成后，产物将位于：
- **位置**: `build/bin/`
- **Windows**: `go-stock.exe`
- **macOS**: `go-stock.app`
- **Linux**: `go-stock`

### 文件结构示例
```
build/bin/
├── go-stock.app/          # macOS 应用程序包
│   └── Contents/
│       └── MacOS/
│           └── go-stock   # macOS 可执行文件
├── go-stock.exe           # Windows 可执行文件
└── go-stock               # Linux 可执行文件
```

## 🚨 常见问题

### 1. "signal: killed" 错误
**问题**: 构建时出现内存不足导致的 killed 信号

**解决方案**:
- 关闭其他占用内存的应用程序
- 使用分步构建（脚本已自动处理）
- 使用 `--skip-frontend` 选项

### 2. 前端构建失败
**问题**: npm run build 失败

**解决方案**:
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
npm run build
```

### 3. Wails CLI 未找到
**问题**: wails: command not found

**解决方案**:
```bash
go install github.com/wailsapp/wails/v2/cmd/wails@latest
export PATH=$PATH:$(go env GOPATH)/bin
```

### 4. Go 模块问题
**问题**: Go 模块相关错误

**解决方案**:
```bash
go mod tidy
go mod verify
go clean -modcache
```

## 🔄 构建流程

### 优化构建脚本流程
1. **环境检查** - 验证必要工具
2. **资源检查** - 检查系统内存和磁盘空间
3. **清理构建** - 清理之前的构建产物（可选）
4. **准备模块** - 整理和验证 Go 模块
5. **构建前端** - 编译 Vue.js 前端代码
6. **构建应用** - 使用 Wails 构建跨平台应用
7. **结果展示** - 显示构建产物和大小

### 内存优化特性
- **分步构建**: 前端和后端分别构建，减少内存峰值
- **跳过绑定**: 使用 `-skipbindings` 减少内存占用
- **重试机制**: 构建失败自动重试
- **资源监控**: 检查系统资源状况

## 🎯 使用建议

### 开发阶段
- 使用 `quick-build.sh` 进行快速构建和测试
- 使用 `wails dev` 进行开发时热重载

### 测试阶段
- 使用 `build-optimized.sh macos` 构建单平台测试
- 使用 `--clean` 选项确保干净构建

### 发布阶段
- 使用 `build-optimized.sh all --clean` 构建所有平台
- 检查所有构建产物的功能完整性

## 📞 技术支持

如果遇到构建问题：

1. **检查环境** - 确保所有必备工具已正确安装
2. **查看日志** - 脚本会显示详细的构建信息
3. **清理重试** - 使用 `--clean` 选项重新构建
4. **查看文档** - 参考 Wails 官方文档

---

**注意**: 这些构建脚本基于我们解决 "signal: killed" 错误的经验优化，采用分步构建和内存优化策略，确保在各种环境下都能稳定构建。 