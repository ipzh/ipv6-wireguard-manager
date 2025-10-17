# IPv6 WireGuard Manager 前端自动部署系统

这个部署系统提供了多种方式来一键更新远程主机的前端代码，支持本地部署和CI/CD自动部署。

## 🚀 部署方式

### 1. 本地部署脚本

#### Linux/macOS (Bash)
```bash
# 给脚本执行权限
chmod +x deploy/deploy.sh

# 部署到生产环境
./deploy/deploy.sh production --backup

# 部署到测试环境，不创建备份
./deploy/deploy.sh staging --no-backup

# 模拟运行，查看将要执行的操作
./deploy/deploy.sh production --dry-run
```

#### Windows (批处理)
```cmd
# 部署到生产环境
deploy\deploy.bat production --backup

# 部署到测试环境，不创建备份
deploy\deploy.bat staging --no-backup

# 模拟运行
deploy\deploy.bat production --dry-run
```

#### Windows (PowerShell)
```powershell
# 部署到生产环境
.\deploy\deploy.ps1 production -Backup

# 部署到测试环境，不创建备份
.\deploy\deploy.ps1 staging -NoBackup

# 模拟运行
.\deploy\deploy.ps1 production -DryRun
```

### 2. GitHub Actions 自动部署

当代码推送到特定分支时，会自动触发部署：

- **develop 分支** → 自动部署到测试环境
- **main 分支** → 自动部署到生产环境
- **手动触发** → 可选择部署环境

## ⚙️ 配置说明

### 1. 创建配置文件

复制配置文件模板：
```bash
cp deploy/deploy.conf.example deploy/deploy.conf
```

### 2. 编辑配置文件

编辑 `deploy/deploy.conf` 文件，设置你的服务器信息：

```ini
# 远程服务器配置
REMOTE_HOST=your-server.com
REMOTE_USER=root
REMOTE_PORT=22
REMOTE_PATH=/var/www/ipv6-wireguard-manager

# 本地配置
LOCAL_FRONTEND_PATH=php-frontend
BACKUP_PATH=backups
LOG_PATH=logs

# 部署选项
CREATE_BACKUP=true
RESTART_SERVICES=true
CLEAR_CACHE=true
RUN_TESTS=false

# 服务配置
WEB_SERVER=nginx
PHP_SERVICE=php8.1-fpm
```

### 3. 设置SSH密钥认证

为了安全起见，建议使用SSH密钥认证：

```bash
# 生成SSH密钥对（如果还没有）
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# 将公钥复制到远程服务器
ssh-copy-id -p 22 user@your-server.com

# 测试连接
ssh -p 22 user@your-server.com
```

## 📋 部署选项

### 环境选择
- `production` - 生产环境
- `staging` - 测试环境
- `development` - 开发环境

### 部署选项
- `--backup` / `-Backup` - 创建备份（默认）
- `--no-backup` / `-NoBackup` - 不创建备份
- `--restart` / `-Restart` - 重启服务（默认）
- `--no-restart` / `-NoRestart` - 不重启服务
- `--cache` / `-Cache` - 清除缓存（默认）
- `--no-cache` / `-NoCache` - 不清除缓存
- `--test` / `-Test` - 运行测试
- `--dry-run` / `-DryRun` - 模拟运行
- `--help` / `-Help` - 显示帮助信息

## 🔧 部署流程

每次部署都会执行以下步骤：

1. **检查依赖** - 验证rsync、ssh等工具是否可用
2. **创建备份** - 备份当前的前端文件（可选）
3. **同步文件** - 使用rsync同步本地文件到远程服务器
4. **设置权限** - 设置正确的文件权限
5. **清除缓存** - 清除PHP缓存和临时文件
6. **重启服务** - 重启PHP和Web服务器
7. **运行测试** - 验证部署是否成功（可选）

## 🛡️ 安全考虑

### 1. SSH密钥认证
- 使用SSH密钥而不是密码认证
- 定期轮换SSH密钥
- 限制SSH访问IP范围

### 2. 文件权限
- 设置适当的文件权限（755 for directories, 644 for files）
- 保护敏感配置文件
- 限制日志目录访问

### 3. 备份策略
- 自动创建部署前备份
- 定期清理旧备份文件
- 测试备份恢复流程

## 🚨 故障排除

### 常见问题

#### 1. SSH连接失败
```bash
# 检查SSH连接
ssh -p 22 user@your-server.com

# 检查SSH密钥
ssh-add -l

# 检查known_hosts
ssh-keygen -R your-server.com
```

#### 2. rsync同步失败
```bash
# 检查rsync是否安装
which rsync

# 手动测试rsync
rsync -avz --dry-run local/path/ user@server:remote/path/
```

#### 3. 权限问题
```bash
# 检查远程目录权限
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

## 📊 监控和日志

### 1. 部署日志
部署脚本会输出详细的日志信息，包括：
- 每个步骤的执行状态
- 错误信息和警告
- 执行时间统计

### 2. 服务监控
部署后会自动检查服务状态：
- PHP服务是否正常运行
- Web服务器是否正常运行
- 文件权限是否正确

### 3. 备份管理
- 备份文件按时间戳命名
- 建议定期清理旧备份
- 可以手动恢复备份

## 🔄 回滚操作

如果需要回滚到之前的版本：

```bash
# 查看可用备份
ssh user@server "ls -la /var/www/backups/"

# 恢复备份
ssh user@server "cd /var/www && tar -xzf backups/frontend_backup_20240101_120000.tar.gz"

# 重启服务
ssh user@server "systemctl restart php8.1-fpm && systemctl reload nginx"
```

## 📈 最佳实践

### 1. 部署前检查
- 在测试环境验证更改
- 运行完整的测试套件
- 检查配置文件正确性

### 2. 部署策略
- 使用蓝绿部署或滚动更新
- 在低峰期进行部署
- 准备回滚计划

### 3. 监控部署
- 监控服务状态
- 检查错误日志
- 验证功能正常

## 🆘 获取帮助

如果遇到问题，可以：

1. 查看部署日志
2. 检查配置文件
3. 验证SSH连接
4. 查看服务状态
5. 联系系统管理员

## 📝 更新日志

- **v1.0.0** - 初始版本，支持基本的文件同步和部署
- **v1.1.0** - 添加了备份功能和权限设置
- **v1.2.0** - 添加了GitHub Actions支持
- **v1.3.0** - 改进了错误处理和日志记录
