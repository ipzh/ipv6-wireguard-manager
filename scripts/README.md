# IPv6 WireGuard Manager 脚本说明

本目录包含了 IPv6 WireGuard Manager 项目的各种管理脚本，支持 Linux/macOS 和 Windows 系统。

## 脚本列表

### 基础管理脚本

| 脚本 | 功能 | Linux/macOS | Windows |
|------|------|-------------|---------|
| 启动服务 | 启动所有服务 | `./scripts/start.sh` | `scripts\start.bat` |
| 停止服务 | 停止所有服务 | `./scripts/stop.sh` | `scripts\stop.bat` |
| 清理数据 | 删除所有数据和容器 | `./scripts/clean.sh` | `scripts\clean.bat` |
| 查看日志 | 查看服务日志 | `./scripts/logs.sh` | `scripts\logs.bat` |
| 检查状态 | 检查服务状态 | `./scripts/status.sh` | `scripts\status.bat` |

### 开发相关脚本

| 脚本 | 功能 | Linux/macOS | Windows |
|------|------|-------------|---------|
| 开发环境 | 启动开发环境 | `./scripts/dev.sh` | `scripts\dev.bat` |
| 运行测试 | 运行所有测试 | `./scripts/test.sh` | `scripts\test.bat` |
| 构建镜像 | 构建Docker镜像 | `./scripts/build.sh` | `scripts\build.bat` |

### 数据管理脚本

| 脚本 | 功能 | Linux/macOS | Windows |
|------|------|-------------|---------|
| 备份数据 | 备份所有数据 | `./scripts/backup.sh` | `scripts\backup.bat` |
| 恢复数据 | 恢复备份数据 | `./scripts/restore.sh <backup>` | `scripts\restore.bat <backup>` |
| 更新系统 | 更新到最新版本 | `./scripts/update.sh` | `scripts\update.bat` |

## 使用方法

### 快速开始

1. **启动服务**
   ```bash
   # Linux/macOS
   ./scripts/start.sh
   
   # Windows
   scripts\start.bat
   ```

2. **访问系统**
   - 前端: http://localhost:3000
   - 后端API: http://localhost:8000
   - API文档: http://localhost:8000/docs

3. **默认登录信息**
   - 用户名: `admin`
   - 密码: `admin123`

### 开发环境

1. **启动开发环境**
   ```bash
   # Linux/macOS
   ./scripts/dev.sh
   
   # Windows
   scripts\dev.bat
   ```

2. **运行测试**
   ```bash
   # Linux/macOS
   ./scripts/test.sh
   
   # Windows
   scripts\test.bat
   ```

### 数据管理

1. **备份数据**
   ```bash
   # Linux/macOS
   ./scripts/backup.sh
   
   # Windows
   scripts\backup.bat
   ```

2. **恢复数据**
   ```bash
   # Linux/macOS
   ./scripts/restore.sh ipv6wgm_backup_20231201_120000.tar.gz
   
   # Windows
   scripts\restore.bat ipv6wgm_backup_20231201_120000
   ```

### 日志查看

1. **查看所有日志**
   ```bash
   # Linux/macOS
   ./scripts/logs.sh
   
   # Windows
   scripts\logs.bat
   ```

2. **查看特定服务日志**
   ```bash
   # Linux/macOS
   ./scripts/logs.sh backend
   ./scripts/logs.sh frontend
   ./scripts/logs.sh db
   ./scripts/logs.sh redis
   
   # Windows
   scripts\logs.bat backend
   scripts\logs.bat frontend
   scripts\logs.bat db
   scripts\logs.bat redis
   ```

## 注意事项

1. **权限设置**
   - Linux/macOS 脚本需要执行权限: `chmod +x scripts/*.sh`

2. **环境要求**
   - Docker 和 Docker Compose
   - 开发环境需要 Python 3.11+ 和 Node.js 18+

3. **数据安全**
   - 定期备份数据
   - 备份文件存储在 `backups/` 目录

4. **故障排除**
   - 查看日志: `./scripts/logs.sh`
   - 检查状态: `./scripts/status.sh`
   - 重启服务: `./scripts/stop.sh && ./scripts/start.sh`

## 脚本参数

### logs.sh/logs.bat
- 无参数: 显示所有服务日志
- `backend`: 显示后端日志
- `frontend`: 显示前端日志
- `db`: 显示数据库日志
- `redis`: 显示Redis日志

### restore.sh/restore.bat
- 必需参数: 备份文件名或目录名

## 故障排除

### 常见问题

1. **端口冲突**
   - 检查端口 3000, 8000, 5432, 6379 是否被占用
   - 修改 `docker-compose.yml` 中的端口映射

2. **权限问题**
   - Linux/macOS: 确保脚本有执行权限
   - Windows: 以管理员身份运行

3. **Docker问题**
   - 确保 Docker 服务正在运行
   - 检查 Docker 版本兼容性

4. **数据库连接问题**
   - 检查数据库服务是否启动
   - 验证连接配置

### 获取帮助

- 查看项目文档: `docs/`
- 查看API文档: http://localhost:8000/docs
- 提交问题: GitHub Issues
