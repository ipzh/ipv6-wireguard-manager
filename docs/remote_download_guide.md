# 🌐 IPv6 WireGuard Manager 一键检查工具 - 远程下载指南

## 📋 概述

本文档提供了多种远程下载一键检查工具的方法，让您能够快速获取并使用检查工具来诊断IPv6 WireGuard Manager系统问题。

## 🚀 快速开始

### 方法1：一键下载并运行（推荐）

#### Windows系统
```cmd
# 下载并运行
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/download_check_tool.bat' -OutFile 'download_check_tool.bat'; .\download_check_tool.bat"
```

#### Linux/macOS系统
```bash
# 下载并运行
curl -o download_check_tool.sh https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/download_check_tool.sh
chmod +x download_check_tool.sh
./download_check_tool.sh
```

### 方法2：直接下载检查工具

#### Windows系统
```cmd
# 使用PowerShell
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/one_click_check_simple.bat' -OutFile 'one_click_check_simple.bat'"

# 使用curl
curl -o one_click_check_simple.bat https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/one_click_check_simple.bat

# 运行检查
one_click_check_simple.bat
```

#### Linux/macOS系统
```bash
# 使用wget
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/one_click_check.sh
chmod +x one_click_check.sh
./one_click_check.sh

# 使用curl
curl -o one_click_check.sh https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/one_click_check.sh
chmod +x one_click_check.sh
./one_click_check.sh
```

### 方法3：Python版本（功能最全面）

```bash
# 下载Python版本
curl -o one_click_check.py https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/scripts/one_click_check.py

# 安装依赖
pip install psutil requests

# 运行检查
python one_click_check.py
```

### 方法4：完整安装包

#### Windows系统
```cmd
# 下载完整安装包
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install_check_tool.bat' -OutFile 'install_check_tool.bat'; .\install_check_tool.bat"
```

## 📁 可下载的文件

| 文件名 | 描述 | 适用系统 | 功能 |
|--------|------|----------|------|
| `one_click_check_simple.bat` | 基础检查工具 | Windows | 无Python依赖，基础检查 |
| `one_click_check.sh` | 基础检查工具 | Linux/macOS | 无Python依赖，基础检查 |
| `one_click_check.py` | 高级检查工具 | 跨平台 | 需要Python，功能最全面 |
| `download_check_tool.bat` | 下载脚本 | Windows | 自动下载并运行检查工具 |
| `download_check_tool.sh` | 下载脚本 | Linux/macOS | 自动下载并运行检查工具 |
| `download_check_tool.py` | 下载脚本 | 跨平台 | Python版本下载脚本 |
| `install_check_tool.bat` | 安装脚本 | Windows | 完整安装和配置 |

## 🔧 使用场景

### 场景1：快速检查系统状态
```bash
# 下载并立即运行
curl -s https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/one_click_check.sh | bash
```

### 场景2：定期检查
```bash
# 创建定期检查任务
echo "0 */6 * * * curl -s https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/one_click_check.sh | bash" | crontab -
```

### 场景3：故障排查
```bash
# 下载详细检查工具
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/scripts/one_click_check.py
pip install psutil requests
python one_click_check.py --all
```

## 🌐 网络要求

- **GitHub访问**：需要能够访问 `raw.githubusercontent.com`
- **HTTPS支持**：需要支持HTTPS下载
- **防火墙**：确保防火墙允许HTTPS连接

## 🔒 安全说明

- 所有脚本都从GitHub官方仓库下载
- 建议在下载后检查文件完整性
- 可以在隔离环境中先测试脚本

## 📊 检查功能

下载的检查工具将检查以下项目：

1. **服务状态检查**
   - Python进程运行状态
   - MySQL进程运行状态
   - Nginx进程运行状态

2. **端口监听检查**
   - 80端口（HTTP）
   - 8000端口（API）
   - 3306端口（MySQL）

3. **配置文件检查**
   - .env环境配置文件
   - env.local本地配置
   - 数据库初始化脚本

4. **环境变量检查**
   - DATABASE_URL
   - SERVER_HOST
   - SERVER_PORT

5. **系统资源检查**
   - 内存使用情况
   - 磁盘使用情况
   - CPU使用情况

6. **网络连接测试**
   - Web服务可访问性
   - API服务可访问性

## 🚨 故障排除

### 下载失败
```bash
# 检查网络连接
ping raw.githubusercontent.com

# 使用代理下载
curl --proxy http://proxy:port -o one_click_check.sh https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/one_click_check.sh
```

### 权限问题
```bash
# Linux/macOS添加执行权限
chmod +x one_click_check.sh

# Windows以管理员身份运行
# 右键点击 -> 以管理员身份运行
```

### Python依赖问题
```bash
# 安装Python依赖
pip install psutil requests

# 或使用conda
conda install psutil requests
```

## 📞 技术支持

如果遇到下载或使用问题：

1. 检查网络连接
2. 确认GitHub访问正常
3. 查看错误日志
4. 联系技术支持团队

## 🔄 更新说明

- 检查工具会定期更新
- 建议定期重新下载最新版本
- 关注GitHub仓库的更新通知

---

**注意**：请确保从官方GitHub仓库下载，避免使用第三方来源的文件。
