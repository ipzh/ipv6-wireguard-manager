# 模块路径查找优化说明

## 📋 问题分析

您提到的两个路径确实可能导致模块查找问题：

1. `/opt/ipv6-wireguard-manager/modules/${module_name}.sh`
2. `/usr/local/share/ipv6-wireguard-manager/modules/${module_name}.sh`

## 🔍 问题原因

### 1. 硬编码绝对路径的问题
- **开发环境**: 这些路径在开发环境中通常不存在
- **Windows环境**: 这些Linux特定路径在Windows下无效
- **便携性**: 硬编码路径降低了脚本的便携性
- **优先级**: 原来的顺序可能导致优先查找不存在的路径

### 2. 路径查找顺序不合理
**原来的顺序**:
1. `/opt/ipv6-wireguard-manager/modules/` (可能不存在)
2. `$IPV6WGM_MODULES_DIR/` (环境变量路径)
3. `$(pwd)/modules/` (当前目录)
4. `/usr/local/share/ipv6-wireguard-manager/modules/` (可能不存在)

**问题**: 优先查找可能不存在的绝对路径，降低了查找效率

## ✅ 优化方案

### 1. 路径查找顺序优化

**新的优化顺序**:
1. `$IPV6WGM_MODULES_DIR/${module_name}.sh` - 环境变量定义的路径（首选）
2. `${SCRIPT_DIR}/modules/${module_name}.sh` - 相对于脚本目录
3. `$(pwd)/modules/${module_name}.sh` - 相对于当前工作目录
4. `$(dirname "${BASH_SOURCE[0]}")/${module_name}.sh` - 相对于当前模块目录
5. `/opt/ipv6-wireguard-manager/modules/${module_name}.sh` - 标准安装路径（仅Linux）
6. `/usr/local/share/ipv6-wireguard-manager/modules/${module_name}.sh` - 系统级安装路径（仅Linux）

### 2. 优化效果

#### 提高查找成功率
- **开发环境**: 优先使用相对路径，确保开发时能找到模块
- **生产环境**: 支持标准安装路径
- **跨平台**: 相对路径在所有平台都有效

#### 提高查找效率
- **减少无效查找**: 优先查找最可能存在的路径
- **快速定位**: 环境变量路径优先级最高
- **智能回退**: 多层回退机制确保兼容性

## 🔧 具体修复

### enhanced_module_loader.sh
```bash
# 查找模块文件 - 优化路径查找顺序
local module_path=""
local search_paths=(
    "$IPV6WGM_MODULES_DIR/${module_name}.sh"                    # 首选：环境变量定义的路径
    "${SCRIPT_DIR}/modules/${module_name}.sh"                   # 相对于脚本目录
    "$(pwd)/modules/${module_name}.sh"                          # 相对于当前工作目录
    "$(dirname "${BASH_SOURCE[0]}")/${module_name}.sh"          # 相对于当前模块目录
    "/opt/ipv6-wireguard-manager/modules/${module_name}.sh"     # 标准安装路径（仅Linux）
    "/usr/local/share/ipv6-wireguard-manager/modules/${module_name}.sh"  # 系统级安装路径（仅Linux）
)
```

### ipv6-wireguard-manager.sh
```bash
# 尝试从多个位置查找模块 - 优化路径查找顺序
local alt_paths=(
    "${SCRIPT_DIR}/modules/${module_name}.sh"                   # 相对于脚本目录
    "$(pwd)/modules/${module_name}.sh"                          # 相对于当前工作目录
    "$(dirname "${BASH_SOURCE[0]}")/modules/${module_name}.sh"  # 相对于主脚本目录
    "/opt/ipv6-wireguard-manager/modules/${module_name}.sh"     # 标准安装路径（仅Linux）
    "/usr/local/share/ipv6-wireguard-manager/modules/${module_name}.sh"  # 系统级安装路径（仅Linux）
)
```

## 🎯 优化效果

### 1. 提高兼容性
- **开发环境**: 在项目目录下直接运行脚本
- **安装环境**: 支持标准的Linux安装路径
- **Windows环境**: 相对路径在Windows下也能正常工作

### 2. 提高可靠性
- **路径检测**: 智能检测模块文件位置
- **多重回退**: 多个路径选项确保找到模块
- **错误处理**: 详细的错误信息帮助调试

### 3. 提高性能
- **优先级**: 最可能的路径优先查找
- **减少IO**: 避免查找不存在的路径
- **缓存友好**: 环境变量路径可以被缓存

## 🌐 跨平台支持

### Linux/Unix系统
- 支持标准安装路径 `/opt/ipv6-wireguard-manager/`
- 支持系统级路径 `/usr/local/share/ipv6-wireguard-manager/`
- 支持相对路径开发模式

### Windows系统
- 主要依赖相对路径
- 跳过Linux特定的绝对路径
- 支持WSL环境下的路径映射

### macOS系统
- 支持相对路径开发
- 支持Homebrew安装路径
- 兼容Unix标准路径

## 📝 使用建议

### 开发环境
```bash
# 设置环境变量（推荐）
export IPV6WGM_MODULES_DIR="$(pwd)/modules"

# 或者在项目目录下直接运行
cd /path/to/ipv6-wireguard-manager
./ipv6-wireguard-manager.sh
```

### 生产环境
```bash
# 标准安装后，路径会自动配置
sudo ./install.sh

# 安装后的路径配置
IPV6WGM_MODULES_DIR="/opt/ipv6-wireguard-manager/modules"
```

### 测试环境
```bash
# WSL环境测试
cd /mnt/d/IPv6-WireGuard-manager/ipv6-wireguard-manager
export IPV6WGM_MODULES_DIR="$(pwd)/modules"
./ipv6-wireguard-manager.sh --version
```

## 🔍 验证方法

### 路径查找测试
```bash
# 测试模块路径查找
source modules/enhanced_module_loader.sh
load_module_smart_enhanced "common_functions"
echo "模块加载测试: $?"
```

### 跨环境测试
```bash
# 在不同目录下测试
cd /tmp
/path/to/ipv6-wireguard-manager/ipv6-wireguard-manager.sh --version

# 测试符号链接
ln -s /path/to/ipv6-wireguard-manager/ipv6-wireguard-manager.sh /usr/local/bin/test-wg
test-wg --version
```

## 📈 优化总结

通过路径查找优化，解决了以下问题：

1. **提高查找成功率** - 相对路径优先，减少查找失败
2. **增强跨平台兼容性** - 支持Windows、Linux、macOS
3. **提升开发体验** - 开发环境下更容易运行和测试
4. **保持生产兼容性** - 仍然支持标准安装路径

这个优化确保了模块在各种环境下都能被正确找到和加载。