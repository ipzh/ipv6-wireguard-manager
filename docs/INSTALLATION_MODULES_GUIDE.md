# IPv6 WireGuard Manager 模块化安装指南

## 📋 概述

IPv6 WireGuard Manager现在采用模块化安装设计，将原来的3227行单文件安装脚本拆分为多个功能模块，提高可维护性和可读性。

## 🏗️ 模块架构

### 核心模块

1. **环境检查模块** (`module_environment.sh`)
   - 检查操作系统和架构
   - 验证系统资源（内存、磁盘空间）
   - 检查网络连接
   - 验证必需命令和工具
   - 检查Python、PHP、MySQL、Docker环境

2. **依赖安装模块** (`module_dependencies.sh`)
   - 检测包管理器（APT、YUM、DNF、Pacman、Homebrew）
   - 安装系统依赖
   - 安装Python依赖
   - 检查PHP扩展
   - 安装Docker（可选）

3. **配置模块** (`module_configuration.sh`)
   - 创建服务用户和组
   - 创建目录结构
   - 生成环境配置文件
   - 配置数据库
   - 配置Nginx
   - 配置systemd服务
   - 配置防火墙

4. **部署模块** (`module_deployment.sh`)
   - 复制应用文件
   - 设置文件权限
   - 初始化数据库
   - 配置应用服务

5. **服务管理模块** (`module_service.sh`)
   - 启动系统服务
   - 配置服务自启动
   - 验证服务状态
   - 配置日志轮转

6. **验证模块** (`module_verification.sh`)
   - 测试API端点
   - 验证数据库连接
   - 检查服务健康状态
   - 生成安装报告

## 🚀 使用方法

### 完整安装
```bash
# 运行完整安装流程
./scripts/install.sh

# 静默安装
./scripts/install.sh --quiet

# 强制安装（覆盖现有配置）
./scripts/install.sh --force
```

### 模块化安装
```bash
# 仅运行环境检查
./scripts/install.sh environment

# 运行多个模块
./scripts/install.sh environment dependencies configuration

# 跳过依赖检查
./scripts/install.sh --skip-deps configuration deployment
```

### 部署模式选择
```bash
# 仅Docker部署
./scripts/install.sh --docker-only

# 仅原生部署
./scripts/install.sh --native-only
```

## 📁 目录结构

```
scripts/
├── install.sh                    # 主安装脚本
└── install/                      # 安装模块目录
    ├── module_environment.sh     # 环境检查模块
    ├── module_dependencies.sh    # 依赖安装模块
    ├── module_configuration.sh   # 配置模块
    ├── module_deployment.sh      # 部署模块
    ├── module_service.sh         # 服务管理模块
    └── module_verification.sh   # 验证模块
```

## 🔧 模块功能详解

### 1. 环境检查模块
- **功能**: 全面检查系统环境
- **检查项**: OS、架构、内存、磁盘、网络、命令、Python、PHP、MySQL、Docker
- **输出**: 环境检查报告
- **失败处理**: 提供修复建议

### 2. 依赖安装模块
- **功能**: 安装系统依赖和开发工具
- **支持系统**: Ubuntu/Debian、CentOS/RHEL、Arch Linux、macOS
- **包管理器**: APT、YUM、DNF、Pacman、Homebrew
- **依赖类型**: 系统包、Python包、PHP扩展、Docker

### 3. 配置模块
- **功能**: 创建系统配置和服务配置
- **配置项**: 用户、目录、环境变量、数据库、Nginx、systemd、防火墙
- **安全**: 设置适当的文件权限
- **验证**: 测试配置文件有效性

### 4. 部署模块
- **功能**: 部署应用文件和初始化系统
- **部署内容**: 后端代码、前端文件、配置文件
- **初始化**: 数据库迁移、服务配置
- **权限**: 设置文件所有权和权限

### 5. 服务管理模块
- **功能**: 管理系统服务
- **服务类型**: systemd服务、Nginx、MySQL、Redis
- **操作**: 启动、停止、重启、状态检查
- **自启动**: 配置服务开机自启

### 6. 验证模块
- **功能**: 验证安装结果
- **测试项**: API端点、数据库连接、服务状态、健康检查
- **报告**: 生成安装验证报告
- **问题**: 识别和报告问题

## ⚙️ 配置选项

### 命令行选项
- `-h, --help`: 显示帮助信息
- `-v, --version`: 显示版本信息
- `-d, --debug`: 启用调试模式
- `-q, --quiet`: 静默模式
- `-f, --force`: 强制安装
- `--skip-deps`: 跳过依赖检查
- `--skip-config`: 跳过配置步骤
- `--docker-only`: 仅Docker部署
- `--native-only`: 仅原生部署

### 环境变量
- `INSTALL_DIR`: 安装目录（默认: /opt/ipv6-wireguard-manager）
- `SERVICE_USER`: 服务用户（默认: ipv6wgm）
- `API_PORT`: API端口（默认: 8000）
- `MYSQL_PORT`: MySQL端口（默认: 3306）

## 🐛 故障排除

### 常见问题

1. **权限问题**
   ```bash
   # 检查文件权限
   ls -la scripts/install/
   
   # 设置执行权限
   chmod +x scripts/install.sh scripts/install/module_*.sh
   ```

2. **模块执行失败**
   ```bash
   # 启用调试模式
   ./scripts/install.sh --debug module_name
   
   # 检查模块文件
   bash -x scripts/install/module_environment.sh
   ```

3. **依赖安装失败**
   ```bash
   # 手动安装依赖
   sudo apt-get update
   sudo apt-get install python3-pip python3-venv
   
   # 重新运行安装
   ./scripts/install.sh dependencies
   ```

### 日志查看
```bash
# 查看安装日志
sudo journalctl -u ipv6-wireguard-manager -f

# 查看Nginx日志
sudo tail -f /var/log/nginx/error.log

# 查看应用日志
tail -f /opt/ipv6-wireguard-manager/logs/app.log
```

## 📊 性能优化

### 安装优化
- 并行安装依赖包
- 缓存下载文件
- 跳过不必要的检查

### 运行时优化
- 服务进程优化
- 数据库连接池
- 缓存配置

## 🔄 升级和维护

### 模块更新
```bash
# 更新特定模块
./scripts/install.sh --force module_name

# 更新所有模块
./scripts/install.sh --force
```

### 配置更新
```bash
# 重新配置系统
./scripts/install.sh configuration

# 重新部署应用
./scripts/install.sh deployment
```

## 📞 支持

如果在使用模块化安装过程中遇到问题：

1. 查看模块日志
2. 检查系统环境
3. 验证配置文件
4. 联系技术支持

---

**模块化设计优势**:
- ✅ 代码可读性提升
- ✅ 功能模块化
- ✅ 易于维护
- ✅ 支持选择性安装
- ✅ 错误定位精确
- ✅ 支持调试模式
