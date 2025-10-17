# IPv6 WireGuard Manager 前端自动部署系统

## 🎯 系统概述

为了解决每次修改前端都需要手动重装的问题，我们创建了一套完整的自动部署系统，支持多种部署方式和环境。

## 🚀 核心功能

### 1. 一键部署
- **本地脚本部署** - 支持Linux、macOS、Windows
- **CI/CD自动部署** - 基于GitHub Actions
- **多环境支持** - 生产、测试、开发环境

### 2. 安全可靠
- **自动备份** - 部署前自动创建备份
- **权限管理** - 自动设置正确的文件权限
- **SSH密钥认证** - 安全的远程连接
- **回滚支持** - 快速回滚到之前版本

### 3. 智能同步
- **增量同步** - 只同步修改的文件
- **排除规则** - 自动排除不需要的文件
- **权限保持** - 保持正确的文件权限

## 📁 文件结构

```
deploy/
├── deploy.sh              # Linux/macOS部署脚本
├── deploy.bat             # Windows批处理部署脚本
├── deploy.ps1             # PowerShell部署脚本
├── deploy.conf.example    # 配置文件模板
├── setup.sh               # Linux/macOS快速设置脚本
├── setup.bat              # Windows快速设置脚本
└── README.md              # 详细使用说明

.github/workflows/
└── deploy.yml             # GitHub Actions工作流
```

## 🛠️ 快速开始

### 1. 快速设置

#### Linux/macOS
```bash
cd deploy
chmod +x setup.sh
./setup.sh
```

#### Windows
```cmd
cd deploy
setup.bat
```

### 2. 配置服务器信息

编辑 `deploy/deploy.conf` 文件：
```ini
REMOTE_HOST=your-server.com
REMOTE_USER=root
REMOTE_PORT=22
REMOTE_PATH=/var/www/ipv6-wireguard-manager
```

### 3. 设置SSH密钥认证

```bash
# 生成SSH密钥
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# 复制公钥到服务器
ssh-copy-id -p 22 user@your-server.com
```

### 4. 执行部署

#### Linux/macOS
```bash
./deploy.sh production --backup
```

#### Windows
```cmd
deploy.bat production --backup
```

#### PowerShell
```powershell
.\deploy.ps1 production -Backup
```

## 🔧 部署选项

### 环境选择
- `production` - 生产环境
- `staging` - 测试环境  
- `development` - 开发环境

### 部署参数
- `--backup` - 创建备份（默认）
- `--no-backup` - 不创建备份
- `--restart` - 重启服务（默认）
- `--no-restart` - 不重启服务
- `--cache` - 清除缓存（默认）
- `--no-cache` - 不清除缓存
- `--test` - 运行测试
- `--dry-run` - 模拟运行
- `--help` - 显示帮助

## 🔄 部署流程

每次部署都会执行以下步骤：

1. **依赖检查** - 验证rsync、ssh等工具
2. **配置验证** - 检查配置文件正确性
3. **连接测试** - 测试SSH连接
4. **创建备份** - 备份当前版本（可选）
5. **文件同步** - 同步本地文件到远程服务器
6. **权限设置** - 设置正确的文件权限
7. **缓存清理** - 清除PHP缓存和临时文件
8. **服务重启** - 重启PHP和Web服务器
9. **部署验证** - 验证部署是否成功
10. **状态报告** - 输出部署结果

## 🚨 安全特性

### 1. SSH密钥认证
- 使用RSA 4096位密钥
- 禁用密码认证
- 支持密钥轮换

### 2. 文件权限管理
- 目录权限：755
- 文件权限：644
- 可执行文件：755
- 日志目录：777

### 3. 备份策略
- 自动创建时间戳备份
- 支持手动回滚
- 定期清理旧备份

## 📊 监控和日志

### 1. 部署日志
- 详细的步骤日志
- 错误和警告信息
- 执行时间统计

### 2. 服务监控
- PHP服务状态检查
- Web服务器状态检查
- 文件权限验证

### 3. 健康检查
- 语法检查
- 配置文件验证
- 服务可用性测试

## 🔄 CI/CD集成

### GitHub Actions工作流

#### 触发条件
- 推送到 `main` 分支 → 生产环境部署
- 推送到 `develop` 分支 → 测试环境部署
- 手动触发 → 可选择环境

#### 部署步骤
1. 代码检出
2. 运行测试
3. 设置SSH密钥
4. 创建备份
5. 同步文件
6. 设置权限
7. 清除缓存
8. 重启服务
9. 验证部署

#### 环境变量配置
需要在GitHub仓库中设置以下Secrets：

**测试环境:**
- `STAGING_HOST` - 测试服务器地址
- `STAGING_USER` - 测试服务器用户名
- `STAGING_SSH_PORT` - SSH端口
- `STAGING_SSH_KEY` - SSH私钥
- `STAGING_PATH` - 部署路径
- `STAGING_PHP_SERVICE` - PHP服务名
- `STAGING_WEB_SERVER` - Web服务器名

**生产环境:**
- `PRODUCTION_HOST` - 生产服务器地址
- `PRODUCTION_USER` - 生产服务器用户名
- `PRODUCTION_SSH_PORT` - SSH端口
- `PRODUCTION_SSH_KEY` - SSH私钥
- `PRODUCTION_PATH` - 部署路径
- `PRODUCTION_PHP_SERVICE` - PHP服务名
- `PRODUCTION_WEB_SERVER` - Web服务器名

## 🛠️ 故障排除

### 常见问题

#### 1. SSH连接失败
```bash
# 检查SSH连接
ssh -p 22 user@your-server.com

# 检查SSH密钥
ssh-add -l

# 重新生成known_hosts
ssh-keygen -R your-server.com
```

#### 2. rsync同步失败
```bash
# 检查rsync安装
which rsync

# 手动测试同步
rsync -avz --dry-run local/path/ user@server:remote/path/
```

#### 3. 权限问题
```bash
# 检查远程权限
ssh user@server "ls -la /var/www/"

# 手动设置权限
ssh user@server "chmod -R 755 /var/www/php-frontend"
```

#### 4. 服务重启失败
```bash
# 检查服务状态
ssh user@server "systemctl status nginx php8.1-fpm"

# 查看服务日志
ssh user@server "journalctl -u nginx -f"
```

## 🔄 回滚操作

### 自动回滚
如果部署失败，系统会自动回滚到之前版本。

### 手动回滚
```bash
# 查看可用备份
ssh user@server "ls -la /var/www/backups/"

# 恢复备份
ssh user@server "cd /var/www && tar -xzf backups/frontend_backup_20240101_120000.tar.gz"

# 重启服务
ssh user@server "systemctl restart php8.1-fpm && systemctl reload nginx"
```

## 📈 性能优化

### 1. 增量同步
- 只同步修改的文件
- 使用rsync的增量算法
- 减少网络传输时间

### 2. 并行处理
- 文件同步和权限设置并行
- 缓存清理和服务重启并行
- 提高部署效率

### 3. 智能缓存
- 跳过未修改的文件
- 使用文件时间戳判断
- 减少不必要的操作

## 🎯 最佳实践

### 1. 部署前准备
- 在测试环境验证更改
- 运行完整的测试套件
- 检查配置文件正确性
- 准备回滚计划

### 2. 部署策略
- 使用蓝绿部署
- 在低峰期进行部署
- 监控部署过程
- 验证功能正常

### 3. 安全考虑
- 定期轮换SSH密钥
- 限制SSH访问IP
- 监控部署日志
- 定期备份验证

## 📝 更新日志

### v1.0.0 (2024-01-01)
- 初始版本发布
- 支持基本的文件同步和部署
- 支持Linux、macOS、Windows

### v1.1.0 (2024-01-15)
- 添加了备份功能
- 改进了权限设置
- 添加了错误处理

### v1.2.0 (2024-02-01)
- 添加了GitHub Actions支持
- 支持多环境部署
- 改进了日志记录

### v1.3.0 (2024-02-15)
- 添加了PowerShell支持
- 改进了错误处理
- 添加了健康检查

## 🆘 技术支持

如果遇到问题，可以：

1. 查看部署日志
2. 检查配置文件
3. 验证SSH连接
4. 查看服务状态
5. 参考故障排除指南
6. 联系技术支持

## 📚 相关文档

- [详细使用说明](deploy/README.md)
- [配置文件模板](deploy/deploy.conf.example)
- [GitHub Actions工作流](.github/workflows/deploy.yml)
- [快速设置脚本](deploy/setup.sh)

---

**注意**: 请在生产环境使用前，先在测试环境验证部署脚本的正确性。
