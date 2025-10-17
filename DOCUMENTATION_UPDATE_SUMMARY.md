# 📚 文档更新总结

## 🎯 更新概述

本次更新将所有文档中的目录路径统一更新为最新的标准配置：

- **后端安装目录**: `/opt/ipv6-wireguard-manager/`
- **前端Web目录**: `/var/www/html/`

## 📋 已更新的文档

### 1. 主要文档

| 文档 | 更新内容 | 状态 |
|------|----------|------|
| `README.md` | 添加目录结构说明、权限配置表 | ✅ 已更新 |
| `INSTALLATION_GUIDE.md` | 添加目录结构和权限配置 | ✅ 已更新 |
| `PRODUCTION_DEPLOYMENT_GUIDE.md` | 添加架构目录结构说明 | ✅ 已更新 |
| `TROUBLESHOOTING_MANUAL.md` | 添加目录结构、服务路径错误修复 | ✅ 已更新 |
| `CLI_MANAGEMENT_GUIDE.md` | 添加目录结构说明 | ✅ 已更新 |
| `API_REFERENCE.md` | 添加部署目录结构和API访问地址 | ✅ 已更新 |
| `QUICK_INSTALL_GUIDE.md` | 更新安装目录选项、添加目录结构 | ✅ 已更新 |

### 2. 脚本和配置文件

| 文件 | 更新内容 | 状态 |
|------|----------|------|
| `install.sh` | 默认安装目录配置 | ✅ 已更新 |
| `remote_fix.sh` | 项目目录路径 | ✅ 已更新 |
| `remote_fix_simple.sh` | 项目目录路径 | ✅ 已更新 |
| `ONE_CLICK_REMOTE_FIX.md` | 路径引用更新 | ✅ 已更新 |
| `comprehensive_error_fix.sh` | 综合错误修复脚本 | ✅ 已创建 |
| `verify_permissions.sh` | 权限验证脚本 | ✅ 已创建 |
| `verify_installation_flow.sh` | 安装流程验证脚本 | ✅ 已创建 |

## 📁 标准目录结构

### 后端目录结构
```
/opt/ipv6-wireguard-manager/          # 后端安装目录
├── backend/                          # 后端Python代码
├── php-frontend/                     # 前端源码（备份）
├── venv/                             # Python虚拟环境
├── logs/                              # 后端日志
├── config/                            # 配置文件
├── data/                              # 数据文件
├── uploads/                           # 上传文件
├── temp/                              # 临时文件
├── backups/                           # 备份文件
└── wireguard/                         # WireGuard配置
    └── clients/                       # 客户端配置
```

### 前端目录结构
```
/var/www/html/                        # 前端Web目录
├── classes/                          # PHP类文件
├── controllers/                       # 控制器
├── views/                            # 视图模板
├── config/                           # 配置文件
├── logs/                              # 前端日志（777权限）
├── assets/                           # 静态资源
├── includes/                          # 包含文件
├── api/                              # API相关文件
├── index.php                         # 主入口文件
└── index_jwt.php                     # JWT版本入口
```

## 🔧 权限配置

| 目录/文件 | 所有者 | 权限 | 说明 |
|-----------|--------|------|------|
| `/opt/ipv6-wireguard-manager/` | `ipv6wgm:ipv6wgm` | `755` | 后端安装目录 |
| `/var/www/html/` | `www-data:www-data` | `755` | 前端Web目录 |
| `/var/www/html/logs/` | `www-data:www-data` | `777` | 前端日志目录 |
| `/opt/ipv6-wireguard-manager/logs/` | `ipv6wgm:ipv6wgm` | `755` | 后端日志目录 |
| `/opt/ipv6-wireguard-manager/uploads/` | `ipv6wgm:ipv6wgm` | `755` | 上传目录 |
| `/opt/ipv6-wireguard-manager/temp/` | `ipv6wgm:ipv6wgm` | `755` | 临时目录 |

## 🌐 服务配置

### systemd服务配置
```ini
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target mysql.service

[Service]
Type=exec
User=ipv6wgm
Group=ipv6wgm
WorkingDirectory=/opt/ipv6-wireguard-manager
Environment=PATH=/opt/ipv6-wireguard-manager/venv/bin
ExecStart=/opt/ipv6-wireguard-manager/venv/bin/uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Nginx配置
```nginx
server {
    listen 80;
    listen [::]:80;
    server_name _;
    root /var/www/html;
    index index.php index.html;
    
    # 其他配置...
}
```

## 🚀 安装命令

### 标准安装
```bash
# 一键安装
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | sudo bash

# 本地安装
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

### 验证安装
```bash
# 验证权限配置
sudo ./verify_permissions.sh

# 验证安装流程
./verify_installation_flow.sh

# 综合错误检查和修复
sudo ./comprehensive_error_fix.sh
```

## 📝 重要变更

### 1. 安装目录变更
- **旧路径**: `/tmp/ipv6-wireguard-manager/` (临时目录)
- **新路径**: `/opt/ipv6-wireguard-manager/` (标准安装目录)

### 2. 前端目录变更
- **旧路径**: `/opt/ipv6-wireguard-manager/php-frontend/`
- **新路径**: `/var/www/html/` (标准Web目录)

### 3. 权限配置统一
- **后端**: `ipv6wgm:ipv6wgm` 用户和组
- **前端**: `www-data:www-data` 用户和组
- **日志目录**: 特殊权限 `777` 确保可写

## ✅ 验证清单

- [x] 所有文档中的路径引用已更新
- [x] 安装脚本配置正确
- [x] 部署脚本配置正确
- [x] 远程修复脚本配置正确
- [x] 权限验证脚本已创建
- [x] 安装流程验证脚本已创建
- [x] 综合错误修复脚本已创建
- [x] 文档结构说明完整
- [x] 权限配置说明详细
- [x] 服务配置示例正确

## 🎉 更新完成

所有文档已成功更新，确保：

1. **目录路径统一**: 所有文档使用相同的标准目录结构
2. **权限配置明确**: 详细的权限配置说明和表格
3. **安装流程清晰**: 完整的安装和验证流程
4. **故障排除完善**: 针对新目录结构的故障排除指南
5. **脚本工具齐全**: 提供完整的验证和修复工具

**🚀 系统已准备就绪，可以开始标准化的安装和部署！**
