# 🔧 解决externally-managed-environment问题

## 📋 问题描述

在现代Linux系统（如Ubuntu 22.04+）中，Python环境被标记为"externally-managed"，这防止了使用pip直接安装包到系统级Python环境。

## 🚀 解决方案

### 方案1：使用系统包管理器（推荐）

#### Ubuntu/Debian系统
```bash
# 更新包列表
sudo apt update

# 安装Python包
sudo apt install -y python3-psutil python3-requests

# 验证安装
python3 -c "import psutil, requests; print('包安装成功')"
```

#### CentOS/RHEL系统
```bash
# 安装Python包
sudo yum install -y python3-psutil python3-requests

# 或者使用dnf
sudo dnf install -y python3-psutil python3-requests
```

### 方案2：使用pip --user安装

```bash
# 安装到用户目录
pip3 install --user psutil requests

# 验证安装
python3 -c "import psutil, requests; print('包安装成功')"
```

### 方案3：使用虚拟环境

```bash
# 创建虚拟环境
python3 -m venv check_env

# 激活虚拟环境
source check_env/bin/activate

# 安装包
pip install psutil requests

# 运行检查工具
python scripts/one_click_check.py

# 退出虚拟环境
deactivate
```

### 方案4：使用基础检查模式（无需Python包）

如果以上方案都不可行，可以使用基础检查模式：

```bash
# 下载基础检查脚本
curl -o basic_check.sh https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/scripts/basic_check.sh
chmod +x basic_check.sh
./basic_check.sh
```

## 🔄 自动处理

更新后的一键检查工具会自动处理这些问题：

1. **优先尝试系统包管理器安装**
2. **如果失败，尝试pip --user安装**
3. **如果仍然失败，创建虚拟环境**
4. **如果所有方法都失败，自动切换到基础检查模式**

## 📊 检查模式对比

| 模式 | 功能 | 依赖 | 适用场景 |
|------|------|------|----------|
| Python高级模式 | 全面检查，详细报告 | psutil, requests | 正常环境 |
| 基础检查模式 | 基础检查，简单报告 | 无 | externally-managed-environment |

## 🚨 故障排除

### 如果系统包管理器安装失败
```bash
# 检查包是否存在
apt search python3-psutil
apt search python3-requests

# 如果包不存在，使用pip --user
pip3 install --user psutil requests
```

### 如果pip --user安装失败
```bash
# 检查pip版本
pip3 --version

# 升级pip
python3 -m pip install --upgrade pip --user

# 重新安装
pip3 install --user psutil requests
```

### 如果虚拟环境创建失败
```bash
# 检查python3-venv包
sudo apt install python3-venv

# 重新创建虚拟环境
python3 -m venv check_env
```

## 💡 使用建议

1. **优先使用系统包管理器**：最稳定，不会污染系统环境
2. **次选pip --user**：安装到用户目录，不影响系统
3. **最后选择虚拟环境**：隔离性好，但需要手动管理
4. **基础检查模式**：作为备选方案，确保检查工具始终可用

## 🔄 更新说明

- 检查工具已更新，自动处理externally-managed-environment问题
- 支持多种安装方式，确保在不同环境下都能正常工作
- 提供基础检查模式作为备选方案
