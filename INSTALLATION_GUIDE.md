# IPv6 WireGuard Manager - 安装指南

## 📋 概述

IPv6 WireGuard Manager 提供了智能化的安装脚本，支持多种Linux系统，自动检测系统环境并选择最佳安装方式。

## 🚀 快速安装

### 一键安装（推荐）

```bash
# 智能安装 - 自动检测系统并选择最佳安装方式
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash

# 静默安装 - 推荐生产环境
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --silent

# 指定安装类型
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --type minimal --silent
```

### 避免Apache依赖安装（Debian/Ubuntu推荐）

```bash
# 方法1: 使用专门的PHP-FPM安装脚本（推荐）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install_php_fpm_only.sh | bash

# 方法2: 使用智能安装脚本（已优化避免Apache依赖）
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --silent
```

### 本地安装

```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh
chmod +x install.sh

# 运行安装
./install.sh

## 📁 安装目录结构

安装完成后，系统将使用以下目录结构：

```
/opt/ipv6-wireguard-manager/          # 后端安装目录
├── backend/                          # 后端Python代码
├── php-frontend/                     # 前端源码（备份）
├── venv/                             # Python虚拟环境
├── logs/                              # 后端日志
├── config/                            # 配置文件
├── data/                              # 数据文件
└── ...

/var/www/html/                        # 前端Web目录
├── classes/                          # PHP类文件
├── controllers/                       # 控制器
├── views/                            # 视图模板
├── config/                           # 配置文件
├── logs/                              # 前端日志（777权限）
├── assets/                           # 静态资源
├── index.php                         # 主入口文件
└── index_jwt.php                     # JWT版本入口
```

## 🔧 权限配置

| 目录/文件 | 所有者 | 权限 | 说明 |
|-----------|--------|------|------|
| `/opt/ipv6-wireguard-manager/` | `ipv6wgm:ipv6wgm` | `755` | 后端安装目录 |
| `/var/www/html/` | `www-data:www-data` | `755` | 前端Web目录 |
| `/var/www/html/logs/` | `www-data:www-data` | `777` | 前端日志目录 |
```

## 🧠 智能选择安装

### 自动安装类型选择

安装脚本会根据系统资源综合评分自动选择最佳安装类型：

#### 评分系统

| 资源类型 | 评分标准 | 最高分 |
|----------|----------|--------|
| 内存 | ≥4GB(3分) / 2-4GB(2分) / 1-2GB(1分) | 3分 |
| CPU核心 | ≥4核(2分) / 2-4核(1分) | 2分 |
| 磁盘空间 | ≥10GB(1分) | 1分 |
| **总分** | **0-6分** | **6分** |

#### 安装类型选择

| 评分范围 | 推荐安装类型 | 选择理由 | 优化配置 |
|----------|-------------|----------|----------|
| 0-2分 | `minimal` | 系统资源有限，推荐最小化安装 | 禁用Redis、优化MySQL配置、减少并发连接 |
| 3-4分 | `native` | 系统资源适中，推荐原生安装 | 启用基础功能、平衡性能和资源使用 |
| 5-6分 | `native` | 系统资源充足，推荐原生安装 | 启用所有功能、最大化性能（Docker安装待实现） |

### 智能参数设置

在 `--auto` 模式下，脚本会自动设置以下参数：

- **安装目录**: 根据磁盘空间自动选择
- **端口配置**: 自动检测可用端口
- **服务配置**: 根据系统资源优化配置
- **依赖安装**: 避免Apache依赖，只安装PHP-FPM

### 安装示例

#### 示例1: 低配置服务器（1GB内存，1核CPU）
```bash
# 系统评分: 1分（内存1分 + CPU0分 + 磁盘0分）
# 自动选择: minimal
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --silent
# 输出: 自动选择的安装类型: minimal
# 输出: 选择理由: 系统资源有限（评分: 1/6），推荐最小化安装
```

#### 示例2: 中等配置服务器（2GB内存，2核CPU，20GB磁盘）
```bash
# 系统评分: 4分（内存2分 + CPU1分 + 磁盘1分）
# 自动选择: native
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --silent
# 输出: 自动选择的安装类型: native
# 输出: 选择理由: 系统资源适中（评分: 4/6），推荐原生安装
```

#### 示例3: 高配置服务器（8GB内存，4核CPU，50GB磁盘）
```bash
# 系统评分: 6分（内存3分 + CPU2分 + 磁盘1分）
# 自动选择: native
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash -s -- --silent
# 输出: 自动选择的安装类型: native
# 输出: 选择理由: 系统资源充足（评分: 6/6），推荐原生安装
```

### 智能安装演示

在正式安装前，可以使用演示脚本查看系统评分和推荐安装类型：

```bash
# 下载并运行智能安装演示脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/smart_install_demo.sh | bash

# 或者本地运行
chmod +x smart_install_demo.sh
./smart_install_demo.sh
```

演示脚本会显示：
- 系统资源检测结果
- 系统评分计算过程
- 推荐的安装类型
- 优化配置建议
- 具体的安装命令

## ⚙️ 安装选项

### 基本选项

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `--type TYPE` | 安装类型 (docker\|native\|minimal) | 自动选择 |
| `--dir DIR` | 安装目录 | `/opt/ipv6-wireguard-manager` |
| `--port PORT` | Web端口 | `80` |
| `--api-port PORT` | API端口 | `8000` |

### 功能选项

| 选项 | 说明 |
|------|------|
| `--silent` | 静默安装，不显示交互界面 |
| `--auto` | 智能安装，自动选择参数并退出 |
| `--production` | 生产环境安装 |
| `--performance` | 性能优化安装 |

## ⚠️ 重要说明

### Apache依赖问题

在Debian/Ubuntu系统上，安装PHP时可能会自动安装Apache作为依赖。为了避免这个问题：

1. **推荐方式**: 使用专门的PHP-FPM安装脚本
   ```bash
   ./install_php_fpm_only.sh
   ```

2. **主安装脚本已优化**: 使用精确的包安装方式，避免触发Apache依赖

3. **如果已安装Apache**: 使用修复脚本清理
   ```bash
   ./fix_apache_dependency_issue.sh
   ```

### 跳过选项

| 选项 | 说明 |
|------|------|
| `--skip-deps` | 跳过依赖安装 |
| `--skip-db` | 跳过数据库配置 |
| `--skip-service` | 跳过服务创建 |
| `--skip-frontend` | 跳过前端部署 |
| `--debug` | 调试模式 |

## 🖥️ 安装类型

### 1. 原生安装 (native)
- **适用场景**: 开发环境、性能要求高的环境
- **优点**: 性能最佳、资源占用低、启动快速
- **缺点**: 依赖系统环境、配置复杂
- **要求**: 内存 ≥ 2GB，磁盘 ≥ 5GB

```bash
./install.sh --type native
```

### 2. 最小化安装 (minimal)
- **适用场景**: 资源受限环境、测试环境
- **优点**: 资源占用最低、启动最快
- **缺点**: 功能受限、性能一般
- **要求**: 内存 ≥ 1GB，磁盘 ≥ 3GB

```bash
./install.sh --type minimal
```

### 3. Docker安装 (docker)
- **适用场景**: 生产环境、需要隔离的环境
- **优点**: 完全隔离、易于管理、可移植性强
- **缺点**: 资源占用较高、启动较慢
- **要求**: 内存 ≥ 4GB，磁盘 ≥ 10GB

```bash
./install.sh --type docker
```

## 🖥️ 支持的系统

### 完全支持
- **Ubuntu**: 18.04, 20.04, 22.04, 24.04
- **Debian**: 9, 10, 11, 12
- **CentOS**: 7, 8, 9
- **RHEL**: 7, 8, 9
- **Fedora**: 30+
- **Arch Linux**: 最新版本
- **openSUSE**: 15+

### 部分支持
- **Gentoo**: 需要手动配置
- **Alpine Linux**: 基础支持

## 📦 支持的包管理器

- **APT**: Ubuntu/Debian
- **YUM/DNF**: CentOS/RHEL/Fedora
- **Pacman**: Arch Linux
- **Zypper**: openSUSE
- **Emerge**: Gentoo
- **APK**: Alpine Linux

## 🔧 安装示例

### 生产环境安装

```bash
# 生产环境 + 静默安装
./install.sh --production --silent

# 自定义目录和端口
./install.sh --production --dir /opt/ipv6wgm --port 8080 --api-port 9000
```

### 开发环境安装

```bash
# 开发环境 + 调试模式
./install.sh --type native --debug

# 跳过某些步骤
./install.sh --type native --skip-deps --skip-db
```

### 资源受限环境

```bash
# 最小化安装
./install.sh --type minimal --silent

# 自定义配置
./install.sh --type minimal --dir /opt/ipv6wgm --skip-monitoring
```

## 🔍 安装前检查

### 系统兼容性测试

```bash
# 运行系统兼容性测试
./test_system_compatibility.sh
```

测试内容包括：
- 操作系统检测
- 包管理器检测
- Python环境检查
- 数据库支持检查
- Web服务器检查
- PHP环境检查
- 网络连接测试
- 系统服务检查
- 权限检查

### 手动检查

```bash
# 检查系统信息
cat /etc/os-release
uname -a
free -h
df -h

# 检查包管理器
which apt-get yum dnf pacman zypper emerge apk

# 检查Python
python3 --version
pip3 --version

# 检查网络
ping -c 1 8.8.8.8
ping6 -c 1 2001:4860:4860::8888
```

## 📋 安装步骤

### 自动安装流程

1. **系统检测** - 检测操作系统、架构、包管理器
2. **依赖安装** - 安装Python、MySQL、Nginx、PHP等依赖
3. **用户创建** - 创建服务用户和组
4. **代码下载** - 从GitHub下载项目代码
5. **依赖配置** - 安装Python依赖包
6. **数据库配置** - 创建数据库和用户
7. **前端部署** - 部署PHP前端
8. **服务配置** - 配置Nginx和systemd服务
9. **服务启动** - 启动所有服务
10. **环境检查** - 验证安装是否成功

### 手动安装步骤

如果自动安装失败，可以手动执行以下步骤：

```bash
# 1. 安装系统依赖
sudo apt update
sudo apt install -y python3.11 python3.11-venv mysql-server nginx php8.1-fpm git curl wget

# 2. 创建服务用户
sudo useradd -r -s /bin/false -d /opt/ipv6-wireguard-manager ipv6wgm

# 3. 下载项目
sudo git clone https://github.com/ipzh/ipv6-wireguard-manager.git /opt/ipv6-wireguard-manager
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager

# 4. 安装Python依赖
cd /opt/ipv6-wireguard-manager
python3.11 -m venv venv
source venv/bin/activate
pip install -r backend/requirements.txt

# 5. 配置数据库
sudo mysql -e "CREATE DATABASE ipv6wgm; CREATE USER 'ipv6wgm'@'localhost' IDENTIFIED BY 'password'; GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';"

# 6. 部署前端
sudo cp -r php-frontend/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/

# 7. 配置Nginx
sudo cp php-frontend/nginx.conf /etc/nginx/sites-available/ipv6-wireguard-manager
sudo ln -s /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
sudo systemctl restart nginx

# 8. 创建系统服务
sudo cp install/ipv6-wireguard-manager.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable ipv6-wireguard-manager
sudo systemctl start ipv6-wireguard-manager
```

## ✅ 安装验证

### 自动验证

```bash
# 运行安装验证脚本
./verify_installation.sh
```

验证内容包括：
- 系统服务状态检查
- 端口监听检查
- 数据库连接测试
- Web服务测试
- API服务测试
- 文件权限检查
- 配置文件检查
- 日志文件检查
- 性能测试

### 手动验证

```bash
# 检查服务状态
sudo systemctl status ipv6-wireguard-manager
sudo systemctl status nginx
sudo systemctl status mysql
sudo systemctl status php8.1-fpm

# 检查端口监听
sudo netstat -tlnp | grep -E ":(80|8000) "

# 测试Web访问
curl -f http://localhost/

# 测试API访问
curl -f http://localhost:8000/api/v1/health

# 检查日志
sudo journalctl -u ipv6-wireguard-manager -f
```

## 🚨 故障排除

### 常见问题

#### 1. PHP-FPM服务启动失败
```bash
# 运行PHP-FPM修复脚本
./fix_php_fpm.sh

# 或手动修复
sudo systemctl start php8.1-fpm
sudo systemctl enable php8.1-fpm
```

#### 2. 数据库连接失败
```bash
# 检查MySQL服务
sudo systemctl status mysql
sudo systemctl restart mysql

# 测试连接
mysql -u ipv6wgm -p -e "SELECT 1;"
```

#### 3. 端口占用问题
```bash
# 检查端口占用
sudo netstat -tlnp | grep :80
sudo lsof -i :80

# 杀死占用进程
sudo kill -9 <PID>
```

#### 4. 权限问题
```bash
# 设置正确的文件权限
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager
```

### 日志查看

```bash
# 应用日志
sudo journalctl -u ipv6-wireguard-manager -f

# Nginx日志
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# 系统日志
sudo journalctl -f
```

### 重新安装

```bash
# 停止服务
sudo systemctl stop ipv6-wireguard-manager

# 备份数据
sudo mysqldump -u ipv6wgm -p ipv6wgm > backup.sql

# 清理安装
sudo rm -rf /opt/ipv6-wireguard-manager
sudo rm -f /etc/nginx/sites-enabled/ipv6-wireguard-manager
sudo rm -f /etc/systemd/system/ipv6-wireguard-manager.service

# 重新安装
./install.sh --type minimal --silent
```

## 📚 相关文档

- [生产部署指南](PRODUCTION_DEPLOYMENT_GUIDE.md)
- [故障排除手册](TROUBLESHOOTING_MANUAL.md)
- [API参考文档](docs/API_REFERENCE_DETAILED.md)
- [用户手册](docs/USER_MANUAL.md)
- [安装脚本总结](INSTALLATION_SCRIPT_SUMMARY.md)

## 🆘 获取帮助

### 在线资源
- GitHub仓库: https://github.com/ipzh/ipv6-wireguard-manager
- 问题反馈: https://github.com/ipzh/ipv6-wireguard-manager/issues
- 文档中心: https://github.com/ipzh/ipv6-wireguard-manager/wiki

### 社区支持
- 技术讨论: GitHub Discussions
- 问题报告: GitHub Issues
- 功能请求: GitHub Issues

---

**IPv6 WireGuard Manager 安装指南** - 让部署变得简单可靠！🚀

通过本指南，您可以在任何支持的Linux系统上成功安装和部署IPv6 WireGuard Manager。