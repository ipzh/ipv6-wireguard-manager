# 远程仓库测试配置指南

## 概述

本文档详细介绍了IPv6 WireGuard Manager项目的远程测试配置，包括GitHub Actions工作流、Docker测试、安全扫描和发布流程。

## 测试架构

### 1. GitHub Actions工作流

#### 主要工作流文件

- **`.github/workflows/ci.yml`** - 主要CI/CD流程
- **`.github/workflows/docker-test.yml`** - Docker镜像测试
- **`.github/workflows/release.yml`** - 发布流程

#### 测试阶段

1. **代码质量检查** (`code-quality`)
   - ShellCheck静态分析
   - 文件权限检查
   - 代码风格验证

2. **单元测试** (`unit-tests`)
   - 多操作系统矩阵测试
   - 模块功能验证
   - 基础功能测试

3. **集成测试** (`integration-tests`)
   - 模块间交互测试
   - 端到端流程测试
   - 错误处理测试

4. **性能测试** (`performance-tests`)
   - 配置加载性能
   - 模块导入性能
   - 内存使用监控

5. **兼容性测试** (`compatibility-tests`)
   - 多操作系统支持
   - 多架构支持
   - Shell兼容性

6. **安全扫描** (`security-scan`)
   - Trivy安全扫描
   - 漏洞检测
   - 依赖项安全检查

### 2. Docker测试

#### 支持的平台
- `linux/amd64`
- `linux/arm64`

#### 测试内容
- 镜像构建测试
- 容器启动测试
- 功能验证测试
- 安全扫描

### 3. 发布流程

#### 触发条件
- 推送标签 (`v*`)
- 手动触发 (`workflow_dispatch`)

#### 发布产物
- 源代码压缩包 (`.tar.gz`)
- ZIP压缩包 (`.zip`)
- Docker镜像
- 变更日志

## 测试环境配置

### 1. 本地测试环境

```bash
# 设置测试环境
./scripts/setup-test-environment.sh --verbose

# 运行测试
./tests/run_tests.sh --verbose all
```

### 2. 测试目录结构

```
/tmp/ipv6wgm-test/
├── config/           # 测试配置文件
├── logs/             # 测试日志
├── results/          # 测试结果
└── temp/             # 临时文件
```

### 3. 测试配置文件

- `manager.conf` - 主配置
- `client_template.conf` - 客户端模板
- `bird_template.conf` - BIRD配置模板
- `test_clients.csv` - 测试客户端数据
- `test_ipv6_prefixes.conf` - IPv6前缀配置
- `test_bgp_neighbors.conf` - BGP邻居配置

## 测试执行

### 1. 本地测试

```bash
# 运行所有测试
./tests/run_tests.sh --verbose all

# 运行特定测试
./tests/run_tests.sh --verbose unit
./tests/run_tests.sh --verbose integration
./tests/run_tests.sh --verbose performance
./tests/run_tests.sh --verbose compatibility

# 模拟运行
./tests/run_tests.sh --dry-run all
```

### 2. 远程测试

#### 自动触发
- 推送到 `main` 或 `develop` 分支
- 创建Pull Request
- 定时执行（每天凌晨2点）

#### 手动触发
- 通过GitHub Actions界面
- 使用GitHub CLI

### 3. 测试报告

#### 本地报告
- 控制台输出
- 日志文件 (`/tmp/ipv6wgm_test_logs/`)
- 结果文件 (`/tmp/ipv6wgm_test_results/`)

#### 远程报告
- GitHub Actions日志
- 测试产物上传
- 安全扫描结果

## 配置参数

### 1. 测试超时配置

```yaml
test_timeouts:
  unit_test: 30        # 单元测试超时（秒）
  integration_test: 60 # 集成测试超时（秒）
  performance_test: 120 # 性能测试超时（秒）
  compatibility_test: 90 # 兼容性测试超时（秒）
```

### 2. 性能测试配置

```yaml
performance_tests:
  cache_tests:
    enabled: true
    ttl: 300
    max_size: 1000
  parallel_tests:
    enabled: true
    max_jobs: 4
    job_timeout: 30
```

### 3. 兼容性测试配置

```yaml
compatibility_tests:
  operating_systems:
    - name: "ubuntu"
      versions: ["20.04", "22.04", "24.04"]
    - name: "debian"
      versions: ["11", "12"]
  architectures:
    - "x86_64"
    - "aarch64"
    - "armv7l"
```

## 故障排除

### 1. 常见问题

#### 测试失败
- 检查日志文件
- 验证测试环境
- 检查依赖项

#### 权限问题
- 确保脚本有执行权限
- 检查目录权限
- 验证用户权限

#### 路径问题
- 检查路径中的空格
- 验证相对路径
- 确认文件存在

### 2. 调试技巧

#### 启用详细输出
```bash
./tests/run_tests.sh --verbose all
```

#### 模拟运行
```bash
./tests/run_tests.sh --dry-run all
```

#### 检查测试环境
```bash
./scripts/setup-test-environment.sh --verbose
```

### 3. 日志分析

#### 测试日志位置
- 本地: `/tmp/ipv6wgm_test_logs/`
- 远程: GitHub Actions日志

#### 日志级别
- `DEBUG` - 详细调试信息
- `INFO` - 一般信息
- `WARN` - 警告信息
- `ERROR` - 错误信息

## 最佳实践

### 1. 测试开发

- 保持测试独立性
- 使用描述性测试名称
- 添加适当的断言
- 清理测试数据

### 2. 持续集成

- 快速反馈
- 并行执行
- 缓存优化
- 失败通知

### 3. 质量保证

- 代码覆盖率
- 性能基准
- 安全扫描
- 兼容性测试

## 扩展配置

### 1. 添加新的测试

1. 在 `tests/` 目录创建测试文件
2. 在 `run_tests.sh` 中添加测试函数
3. 更新测试配置

### 2. 添加新的工作流

1. 在 `.github/workflows/` 创建YAML文件
2. 定义触发条件
3. 配置测试步骤

### 3. 自定义测试环境

1. 修改 `scripts/setup-test-environment.sh`
2. 更新测试配置
3. 调整环境变量

## 监控和维护

### 1. 测试监控

- 测试成功率
- 执行时间
- 资源使用
- 失败原因

### 2. 定期维护

- 更新依赖项
- 优化测试性能
- 清理旧数据
- 更新文档

### 3. 通知配置

- 测试失败通知
- 发布成功通知
- 安全警报
- 性能报告

## 总结

远程仓库测试配置提供了完整的CI/CD流程，包括代码质量检查、自动化测试、安全扫描和发布管理。通过合理的配置和维护，可以确保代码质量和项目稳定性。

更多详细信息请参考：
- [GitHub Actions文档](https://docs.github.com/en/actions)
- [Docker测试指南](https://docs.docker.com/develop/dev-best-practices/)
- [安全扫描最佳实践](https://docs.github.com/en/code-security)
