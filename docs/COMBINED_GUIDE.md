# IPv6 WireGuard Manager - 综合使用与功能指南

本指南整合了快速开始与功能特性说明，便于你“一文掌握”安装、使用与核心能力。

## 🚀 快速开始

### 安装
- 一键安装（推荐）：
```bash
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
```
- 下载安装：
```bash
wget -O install.sh https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh
chmod +x install.sh
sudo ./install.sh
```
- 克隆安装：
```bash
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager
sudo ./install.sh
```
- Docker：
```bash
docker-compose up -d
```

### 启动与常用命令
```bash
sudo ./ipv6-wireguard-manager.sh            # 启动管理界面
sudo ./ipv6-wireguard-manager.sh --status   # 查看状态
sudo ./ipv6-wireguard-manager.sh --restart  # 重启服务
sudo ./ipv6-wireguard-manager.sh --logs     # 查看日志
```

### Web 界面
- 访问地址：`http://your-server:8080`
- 核心特性：仪表板、客户端管理、网络配置、监控面板、安全中心、日志查看、系统设置
- 认证：OAuth 2.0、MFA、RBAC、会话管理

### 客户端管理
```bash
sudo ./ipv6-wireguard-manager.sh --add-client client1
sudo ./ipv6-wireguard-manager.sh --gen-config client1
sudo ./ipv6-wireguard-manager.sh --list-clients
sudo ./ipv6-wireguard-manager.sh --del-client client1
```

## 🧭 功能地图

- WireGuard 管理：`modules/wireguard_config.sh`
- 客户端管理：`modules/client_management.sh`
- BGP 路由：`modules/bird_config.sh`
- 防火墙管理：`modules/firewall_management.sh`
- Web 管理界面：`modules/web_management.sh`、`modules/web_interface_enhanced.sh`
- 认证与权限：`modules/oauth_authentication.sh`、`modules/security_functions.sh`
- 系统监控与告警：`modules/system_monitoring.sh`、`modules/monitoring_alerting.sh`
- 错误处理与恢复：`modules/unified_error_handling.sh`、`modules/advanced_error_handling.sh`
- 性能与缓存优化：`modules/performance_optimizer.sh`、`modules/smart_caching.sh`、`modules/lazy_loading.sh`
- 备份与更新：`modules/backup_restore.sh`、`modules/update_management.sh`

## 🔐 安全与认证
- OAuth 2.0 授权码流程，支持第三方提供商
- 多因素认证（TOTP/备份码）与 RBAC 权限控制
- 审计日志与安全事件监控、漏洞扫描

## 📊 监控与告警
- CPU/内存/磁盘/网络使用率监控，温度监控
- 阈值告警与冷却机制，历史统计与报告

## ⚙️ 配置管理
- 主要配置：`/etc/ipv6-wireguard-manager/manager.conf`
- BIRD 路由：`/etc/bird/bird.conf`
- WireGuard：`/etc/wireguard/wg0.conf`
- Web/Nginx：`/etc/nginx/sites-available/ipv6-wireguard-manager`
- OAuth/MFA/RBAC/审计/告警/缓存配置文件

## 🧪 测试与质量
- 统一测试框架与自动化测试：单元、集成、性能、兼容性
- CI/CD（GitHub Actions），覆盖率报告，ShellCheck
```bash
bash test_optimizations.sh
bash test_root_permission.sh
bash tests/comprehensive_test_suite.sh
```

## 🪟 Windows 注意事项
- 建议使用 WSL 运行；原生 PowerShell 需确保 `git.exe` 在 `PATH`
- 使用 Git Bash/WSL 执行 Shell 脚本，避免路径与权限差异

## 🔍 故障排除
- 权限：以 root 运行
- 端口：检查占用
- 网络：验证 IPv6 配置
- 依赖：安装 WireGuard、BIRD、Nginx、Python3 等
- 日志：`/var/log/ipv6-wireguard-manager/manager.log`

---
*综合指南 - 由快速开始与功能特性整合，便于统一阅读*