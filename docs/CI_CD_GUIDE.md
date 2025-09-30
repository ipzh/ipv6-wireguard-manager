# IPv6 WireGuard Manager CI/CD指南

## 📋 概述

本项目实现了完整的持续集成和持续部署(CI/CD)流水线，包括自动化测试、代码质量检查、安全扫描、构建打包和部署发布。

## 🚀 CI/CD流水线

### 流水线阶段

#### 1. 代码质量检查
- **ShellCheck静态分析**: 检查Shell脚本语法和最佳实践
- **语法检查**: 验证所有脚本文件的语法正确性
- **代码风格检查**: 确保代码风格一致性
- **依赖检查**: 验证项目依赖的完整性

#### 2. 自动化测试
- **单元测试**: 测试各个模块的独立功能
- **集成测试**: 测试模块间的交互和集成
- **性能测试**: 测试系统性能和资源使用
- **兼容性测试**: 测试多平台兼容性

#### 3. 安全扫描
- **Trivy安全扫描**: 扫描安全漏洞
- **敏感信息检查**: 检查硬编码密码和API密钥
- **依赖安全审计**: 检查依赖包的安全问题

#### 4. 构建打包
- **多格式打包**: 生成tar.gz和zip格式的发布包
- **Docker镜像构建**: 构建生产环境Docker镜像
- **版本管理**: 自动版本标记和发布

#### 5. 部署发布
- **测试环境部署**: 自动部署到测试环境
- **生产环境部署**: 自动部署到生产环境
- **回滚机制**: 支持一键回滚到之前版本

## 🔧 GitHub Actions配置

### 工作流文件
CI/CD配置位于 `.github/workflows/ci-cd.yml`，包含以下作业：

#### 代码质量检查作业
```yaml
code-quality:
  name: 代码质量检查
  runs-on: ubuntu-latest
  steps:
    - name: 检出代码
      uses: actions/checkout@v4
    - name: 安装ShellCheck
      run: sudo apt-get install -y shellcheck
    - name: 代码语法检查
      run: bash -n *.sh
    - name: ShellCheck静态分析
      run: shellcheck *.sh
```

#### 测试作业
```yaml
unit-tests:
  name: 单元测试
  runs-on: ubuntu-latest
  strategy:
    matrix:
      os: [ubuntu-20.04, ubuntu-22.04, ubuntu-24.04]
  steps:
    - name: 检出代码
      uses: actions/checkout@v4
    - name: 运行单元测试
      run: ./tests/run_tests.sh unit
```

#### 构建作业
```yaml
build:
  name: 构建和打包
  runs-on: ubuntu-latest
  steps:
    - name: 创建发布包
      run: |
        mkdir -p release
        cp -r . release/
        tar -czf ipv6-wireguard-manager.tar.gz release/
```

### 触发条件
- **Push事件**: 推送到master、develop、feature/*分支
- **Pull Request**: 创建或更新PR时触发
- **定时触发**: 每天凌晨2点自动运行
- **手动触发**: 支持手动触发工作流

## 🐳 Docker集成

### Dockerfile
```dockerfile
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    bash curl wget git jq iproute2 iptables
COPY . /opt/ipv6-wireguard-manager/
WORKDIR /opt/ipv6-wireguard-manager
USER ipv6wgm
EXPOSE 51820 8080
CMD ["./ipv6-wireguard-manager.sh"]
```

### Docker Compose
```yaml
version: '3.8'
services:
  ipv6-wireguard-manager:
    build: .
    container_name: ipv6-wireguard-manager
    restart: unless-stopped
    privileged: true
    network_mode: host
    volumes:
      - /etc/ipv6-wireguard-manager:/etc/ipv6-wireguard-manager
      - /var/log/ipv6-wireguard-manager:/var/log/ipv6-wireguard-manager
```

## 🔨 构建系统

### Makefile目标

#### 测试目标
```bash
make test              # 运行所有测试
make test-unit         # 单元测试
make test-integration  # 集成测试
make test-performance  # 性能测试
make test-coverage     # 覆盖率报告
```

#### 构建目标
```bash
make build             # 构建项目
make docker-build      # 构建Docker镜像
make release           # 创建发布包
```

#### 部署目标
```bash
make deploy            # 部署到目标环境
make docker-run        # 运行Docker容器
make docker-stop       # 停止Docker容器
```

#### 开发目标
```bash
make dev-setup         # 设置开发环境
make lint              # 代码质量检查
make ci                # 运行CI检查
```

## 🚀 部署流程

### 本地部署
```bash
# 使用Makefile
make deploy

# 使用部署脚本
./scripts/deploy.sh deploy local
```

### 远程部署
```bash
# 部署到远程服务器
./scripts/deploy.sh deploy remote server.example.com root 22

# 参数说明:
# - server.example.com: 服务器地址
# - root: 用户名
# - 22: SSH端口
```

### Docker部署
```bash
# 使用Docker Compose
docker-compose up -d

# 使用Docker镜像
docker run -d --name ipv6-wireguard-manager \
  --privileged --network host \
  -v /etc/ipv6-wireguard-manager:/etc/ipv6-wireguard-manager \
  ipv6-wireguard-manager:latest
```

## 🔄 回滚机制

### 自动回滚
当部署验证失败时，系统会自动回滚到之前版本：

```bash
# 检查回滚状态
./scripts/deploy.sh rollback /path/to/backup

# 手动回滚
./scripts/deploy.sh rollback /opt/ipv6-wireguard-manager/backups/20231201_120000
```

### 备份管理
- **自动备份**: 每次部署前自动创建备份
- **备份保留**: 保留最近10个备份版本
- **备份验证**: 部署前验证备份完整性

## 📊 监控和告警

### 健康检查
```bash
# 系统健康检查
./ipv6-wireguard-manager.sh --health-check

# Docker健康检查
docker exec ipv6-wireguard-manager ./ipv6-wireguard-manager.sh --health-check
```

### 监控指标
- **系统资源**: CPU、内存、磁盘使用率
- **服务状态**: 各服务组件的运行状态
- **网络状态**: 网络连接和流量统计
- **错误日志**: 错误和异常情况统计

### 告警通知
- **邮件通知**: 部署成功/失败通知
- **Slack通知**: 实时状态更新
- **Webhook通知**: 自定义通知接口

## 🔐 安全考虑

### 代码安全
- **静态分析**: 使用ShellCheck检查安全问题
- **依赖扫描**: 检查依赖包的安全漏洞
- **敏感信息**: 检查硬编码的密码和密钥

### 部署安全
- **权限控制**: 最小权限原则
- **网络安全**: 安全的网络配置
- **数据保护**: 敏感数据加密存储

### 运行时安全
- **容器安全**: 非root用户运行
- **资源限制**: 限制容器资源使用
- **日志审计**: 完整的操作日志记录

## 🛠️ 本地开发

### 开发环境设置
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 设置开发环境
make dev-setup

# 安装依赖
make check-deps

# 运行测试
make test
```

### 代码提交流程
```bash
# 1. 创建功能分支
git checkout -b feature/new-feature

# 2. 开发功能
# ... 编写代码 ...

# 3. 运行测试
make test

# 4. 代码质量检查
make lint

# 5. 提交代码
git add .
git commit -m "Add new feature"

# 6. 推送分支
git push origin feature/new-feature

# 7. 创建Pull Request
```

### 本地CI检查
```bash
# 运行完整的CI检查
make ci

# 包括:
# - 依赖检查
# - 代码质量检查
# - 运行测试
# - 构建Docker镜像
```

## 📈 性能优化

### 测试性能
- **并行测试**: 支持并行运行多个测试
- **缓存机制**: 智能缓存减少重复计算
- **资源监控**: 实时监控测试资源使用

### 构建性能
- **增量构建**: 只构建变更的部分
- **缓存利用**: 利用Docker层缓存
- **并行构建**: 并行构建多个组件

### 部署性能
- **增量部署**: 只部署变更的文件
- **压缩传输**: 使用压缩减少传输时间
- **并行部署**: 支持多环境并行部署

## 🚨 故障排除

### 常见问题

#### 1. 测试失败
```bash
# 查看测试日志
tail -f /tmp/ipv6wgm_test_logs/test_runner.log

# 运行单个测试
./tests/run_tests.sh unit

# 检查测试环境
./tests/run_tests.sh --check-env
```

#### 2. 构建失败
```bash
# 检查Docker环境
docker --version
docker-compose --version

# 清理构建缓存
docker system prune -a

# 重新构建
make docker-build
```

#### 3. 部署失败
```bash
# 检查网络连接
ping server.example.com

# 检查SSH连接
ssh user@server.example.com

# 查看部署日志
tail -f /var/log/ipv6-wireguard-manager/deploy.log
```

### 日志分析
```bash
# 查看CI/CD日志
# GitHub Actions: 在Actions页面查看
# 本地日志: /tmp/ipv6wgm_*_logs/

# 查看部署日志
tail -f /var/log/ipv6-wireguard-manager/*.log

# 查看Docker日志
docker logs ipv6-wireguard-manager
```

## 📚 相关文档

- [测试指南](TESTING_GUIDE.md) - 详细的测试说明
- [安装指南](INSTALLATION.md) - 项目安装说明
- [使用指南](USAGE.md) - 功能使用说明
- [开发指南](DEVELOPMENT.md) - 开发环境设置

## 🤝 贡献CI/CD

欢迎为项目的CI/CD流水线贡献改进！

### 贡献方式
1. Fork 项目
2. 创建CI/CD改进分支
3. 修改 `.github/workflows/ci-cd.yml`
4. 测试修改效果
5. 提交 Pull Request

### 改进建议
- 添加新的测试类型
- 优化构建性能
- 改进部署流程
- 增强监控告警

## 📞 支持

如果您在CI/CD过程中遇到问题：

1. 查看本文档的故障排除部分
2. 检查GitHub Actions的日志
3. 创建Issue描述问题
4. 提供详细的错误信息
