# IPv6 WireGuard Manager 测试指南

## 📋 概述

本项目提供了完整的自动化测试套件，包括单元测试、集成测试、性能测试和兼容性测试。所有测试都支持多种运行方式和报告格式。

## 🧪 测试类型

### 1. 单元测试
测试各个模块的独立功能，确保每个组件按预期工作。

**测试内容:**
- 变量管理功能
- 函数管理功能
- 配置管理功能
- 错误处理功能
- 资源监控功能

**运行方式:**
```bash
# 使用Makefile
make test-unit

# 直接运行
./tests/run_tests.sh unit

# 详细模式
./tests/run_tests.sh -v unit
```

### 2. 集成测试
测试模块间的交互和整体功能集成。

**测试内容:**
- 模块加载机制
- 依赖关系管理
- 系统兼容性检测
- 端到端功能测试

**运行方式:**
```bash
# 使用Makefile
make test-integration

# 直接运行
./tests/run_tests.sh integration
```

### 3. 性能测试
测试系统的性能表现和资源使用情况。

**测试内容:**
- 缓存性能测试
- 并行处理性能测试
- 内存使用测试
- 响应时间测试

**运行方式:**
```bash
# 使用Makefile
make test-performance

# 直接运行
./tests/run_tests.sh performance
```

### 4. 兼容性测试
测试在不同环境下的兼容性。

**测试内容:**
- 多操作系统兼容性
- 多Shell兼容性
- 多架构兼容性
- 依赖软件兼容性

**运行方式:**
```bash
# 使用Makefile
make test-compatibility

# 直接运行
./tests/run_tests.sh compatibility
```

## 🚀 快速开始

### 运行所有测试
```bash
# 使用Makefile (推荐)
make test

# 直接运行
./tests/run_tests.sh all
```

### 生成测试报告
```bash
# 生成文本报告
./tests/run_tests.sh -f text all

# 生成JSON报告
./tests/run_tests.sh -f json all

# 生成HTML报告
./tests/run_tests.sh -f html all
```

### 生成覆盖率报告
```bash
# 生成覆盖率报告
make test-coverage

# 或使用测试运行器
./tests/run_tests.sh -c all
```

## 🔧 测试配置

### 配置文件
测试配置位于 `tests/test_config.yml`，包含以下配置项：

```yaml
# 测试环境配置
test_environment:
  name: "automated_testing"
  log_level: "DEBUG"
  debug_mode: true

# 测试超时配置
test_timeouts:
  unit_test: 30
  integration_test: 60
  performance_test: 120
  compatibility_test: 90

# 性能测试配置
performance_tests:
  cache_tests:
    enabled: true
    ttl: 300
    max_size: 1000
```

### 环境变量
可以通过环境变量自定义测试行为：

```bash
# 设置日志级别
export IPV6WGM_LOG_LEVEL=DEBUG

# 启用调试模式
export IPV6WGM_DEBUG_MODE=true

# 设置测试目录
export IPV6WGM_CONFIG_DIR=/tmp/test_config
export IPV6WGM_LOG_DIR=/tmp/test_logs
```

## 🐳 Docker测试

### 在Docker中运行测试
```bash
# 构建测试镜像
make docker-build

# 运行Docker测试
make docker-test

# 或使用docker-compose
docker-compose --profile testing up --build
```

### Docker测试环境
Docker测试环境包含：
- Ubuntu 22.04 基础镜像
- 所有必要的依赖软件
- 预配置的测试环境
- 隔离的测试空间

## 📊 测试报告

### 报告格式

#### 1. 文本报告
```bash
./tests/run_tests.sh -f text all
```
- 人类可读的格式
- 包含详细的测试结果
- 适合终端查看

#### 2. JSON报告
```bash
./tests/run_tests.sh -f json all
```
- 机器可读的格式
- 适合自动化处理
- 包含结构化数据

#### 3. HTML报告
```bash
./tests/run_tests.sh -f html all
```
- 网页格式
- 包含图表和统计
- 适合分享和存档

### 报告内容
测试报告包含以下信息：
- 测试统计 (总数、通过、失败、跳过)
- 执行时间
- 系统信息
- 测试结果详情
- 覆盖率信息
- 性能指标

## 🔍 调试测试

### 详细输出
```bash
# 启用详细模式
./tests/run_tests.sh -v all

# 查看调试信息
./tests/run_tests.sh -v -d all
```

### 单个测试调试
```bash
# 运行特定测试
./tests/run_tests.sh unit

# 检查测试日志
tail -f /tmp/ipv6wgm_test_logs/test.log
```

### 测试环境检查
```bash
# 检查测试环境
./tests/run_tests.sh --check-env

# 验证依赖
make check-deps
```

## 🚨 故障排除

### 常见问题

#### 1. 权限问题
```bash
# 确保脚本有执行权限
chmod +x tests/run_tests.sh

# 检查目录权限
ls -la tests/
```

#### 2. 依赖缺失
```bash
# 安装必要依赖
sudo apt-get update
sudo apt-get install -y bash curl wget jq

# 检查依赖
make check-deps
```

#### 3. 测试超时
```bash
# 增加超时时间
./tests/run_tests.sh -t 600 all

# 或修改配置文件
vim tests/test_config.yml
```

#### 4. 内存不足
```bash
# 清理系统内存
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches

# 减少并行测试数量
export IPV6WGM_MAX_PARALLEL_JOBS=2
```

### 日志分析
```bash
# 查看测试日志
tail -f /tmp/ipv6wgm_test_logs/test_runner.log

# 查看错误日志
grep -i error /tmp/ipv6wgm_test_logs/*.log

# 查看性能日志
grep -i performance /tmp/ipv6wgm_test_logs/*.log
```

## 📈 持续集成

### GitHub Actions
项目配置了完整的CI/CD流水线，包括：
- 自动代码质量检查
- 多环境测试
- 安全扫描
- 自动构建和部署

### 本地CI检查
```bash
# 运行完整的CI检查
make ci

# 包括以下步骤：
# 1. 依赖检查
# 2. 代码质量检查
# 3. 运行测试
# 4. 构建Docker镜像
```

## 🎯 最佳实践

### 编写测试
1. 测试应该独立且可重复
2. 使用描述性的测试名称
3. 包含正面和负面测试用例
4. 测试边界条件和异常情况

### 运行测试
1. 在提交代码前运行测试
2. 定期运行完整测试套件
3. 监控测试覆盖率和性能
4. 及时修复失败的测试

### 维护测试
1. 保持测试代码的整洁
2. 及时更新过时的测试
3. 添加新功能的测试
4. 定期审查测试质量

## 📚 相关文档

- [安装指南](INSTALLATION.md) - 项目安装说明
- [使用指南](USAGE.md) - 功能使用说明
- [API文档](API.md) - API接口文档
- [开发指南](DEVELOPMENT.md) - 开发环境设置

## 🤝 贡献测试

欢迎为项目贡献测试用例！请遵循以下步骤：

1. Fork 项目
2. 创建测试分支
3. 添加新的测试用例
4. 运行测试确保通过
5. 提交 Pull Request

## 📞 支持

如果您在测试过程中遇到问题，请：

1. 查看本文档的故障排除部分
2. 检查项目的 Issues 页面
3. 创建新的 Issue 描述问题
4. 提供详细的错误信息和日志
