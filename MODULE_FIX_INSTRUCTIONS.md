# 模块文件修复说明

## 问题描述

安装后出现错误：
```
[ERROR] 通用工具函数文件不存在: /usr/local/bin/modules/common_utils.sh
[2025-09-30 00:11:00] [ERROR] 脚本异常退出，退出码: 1
```

## 问题原因

1. **路径问题**: 主脚本通过符号链接运行时，路径设置不正确
2. **模块缺失**: 已安装的版本缺少新的关键模块文件（如 `common_functions.sh`）

## 解决方案

### 方案1: 重新安装（推荐）

```bash
# 卸载现有安装
sudo /opt/ipv6-wireguard-manager/uninstall.sh

# 重新安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```

### 方案2: 手动修复模块文件

```bash
# 1. 下载最新项目文件
cd /tmp
wget https://github.com/ipzh/ipv6-wireguard-manager/archive/main.tar.gz
tar -xzf main.tar.gz
cd ipv6-wireguard-manager-main

# 2. 复制新的模块文件
sudo cp -r modules/* /opt/ipv6-wireguard-manager/modules/
sudo chmod +x /opt/ipv6-wireguard-manager/modules/*.sh

# 3. 更新主脚本
sudo cp ipv6-wireguard-manager.sh /opt/ipv6-wireguard-manager/
sudo chmod +x /opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh

# 4. 更新符号链接
sudo ln -sf /opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh /usr/local/bin/ipv6-wireguard-manager

# 5. 清理临时文件
cd /
rm -rf /tmp/ipv6-wireguard-manager-main
```

### 方案3: 使用修复脚本

```bash
# 下载修复脚本
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix_installed_modules.sh
chmod +x fix_installed_modules.sh

# 运行修复脚本
sudo ./fix_installed_modules.sh
```

## 验证修复

修复后，运行以下命令验证：

```bash
# 检查关键模块是否存在
ls -la /opt/ipv6-wireguard-manager/modules/common_functions.sh
ls -la /opt/ipv6-wireguard-manager/modules/variable_management.sh

# 测试主脚本
sudo ipv6-wireguard-manager --help
```

## 预防措施

为了避免将来出现类似问题，建议：

1. **使用最新版本**: 定期更新到最新版本
2. **检查安装**: 安装后运行测试脚本验证
3. **备份配置**: 定期备份配置文件

## 技术细节

### 路径设置修复

主脚本已修复路径检测逻辑：

```bash
# 检查是否通过符号链接运行
if [[ -L "/usr/local/bin/ipv6-wireguard-manager" ]]; then
    # 通过符号链接运行，使用实际安装目录
    SCRIPT_DIR="/opt/ipv6-wireguard-manager"
    MODULES_DIR="/opt/ipv6-wireguard-manager/modules"
else
    # 直接运行，使用相对路径
    MODULES_DIR="${MODULES_DIR:-${SCRIPT_DIR}/modules}"
fi
```

### 模块导入改进

改进了模块导入机制，支持多个路径查找：

```bash
local alt_paths=(
    "/opt/ipv6-wireguard-manager/modules/${module_name}.sh"
    "/usr/local/share/ipv6-wireguard-manager/modules/${module_name}.sh"
    "$(pwd)/modules/${module_name}.sh"
    "${SCRIPT_DIR}/modules/${module_name}.sh"
)
```

---

*修复说明 - 2025-09-30*
