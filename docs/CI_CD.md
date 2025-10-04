# IPv6 WireGuard Manager CI/CD 指南

## 📋 概述

本项目使用GitHub Actions实现持续集成和持续部署，确保代码质量和自动化发布。

## 🔄 CI/CD 流程

### 主要工作流程

1. **代码质量检查**
   - ShellCheck静态分析
   - YAML文件语法检查
   - 代码风格检查

2. **自动化测试**
   - 单元测试
   - 集成测试
   - 兼容性测试

3. **安全扫描**
   - 硬编码凭据检查
   - 敏感信息扫描
   - 文件权限验证

4. **部署准备**
   - 创建发布包
   - 生成测试报告
   - 上传构建产物

## 🚀 工作流配置

### 主要工作流文件

```yaml
# .github/workflows/main-ci.yml
name: IPv6-WireGuard Manager CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
  schedule:
    - cron: '0 2 * * *'  # 每日构建
```

### 触发条件

- **推送触发**: main、develop分支
- **PR触发**: 针对main、develop分支的PR
- **定时触发**: 每天凌晨2点
- **手动触发**: 支持手动运行

## 🧪 测试阶段

### 1. 代码质量检查
```bash
# ShellCheck分析
find . -name "*.sh" | xargs shellcheck

# YAML语法检查
yamllint .github/workflows/
```

### 2. 单元测试
```bash
# 运行单元测试
bash tests/run_tests.sh unit

# 功能测试
bash scripts/automated-testing.sh --test-type functionality
```

### 3. 安全扫描
```bash
# 检查硬编码密码
grep -r "password.*=" --include="*.sh" .

# 检查敏感信息
grep -r "api.*key\|secret.*key" --include="*.sh" .
```

### 4. 兼容性测试
- Ubuntu 20.04 / 22.04
- Bash / Dash shell
- 多架构支持

## 📦 部署流程

### 发布包创建
```bash
# 创建发布包
tar -czf release/ipv6-wireguard-manager.tar.gz \
  --exclude='.git' \
  --exclude='reports' \
  --exclude='logs' \
  .
```

### 构建产物
- 发布包 (tar.gz)
- 测试报告
- 安全扫描结果

## 🔧 本地开发

### 预提交检查
```bash
# 运行本地测试
make test

# 代码质量检查
make lint

# 安全检查
make security-check
```

### 环境变量
```bash
export IPV6WGM_VERSION="1.0.0"
export IPV6WGM_TEST_MODE="true"
export IPV6WGM_DEBUG_MODE="false"
export IPV6WGM_CI_MODE="true"
```

## 📊 监控和报告

### 测试报告
- 单元测试结果
- 覆盖率报告
- 性能指标
- 安全扫描结果

### 构建状态
- 构建成功/失败状态
- 测试通过率
- 代码质量评分

## 🚨 故障排除

### 常见CI问题

1. **测试失败**
   - 检查测试日志
   - 验证环境配置
   - 确认依赖安装

2. **权限错误**
   ```bash
   chmod +x scripts/*.sh tests/*.sh
   ```

3. **依赖缺失**
   ```bash
   sudo apt-get update
   sudo apt-get install bash curl wget git jq
   ```

### 调试CI问题
```bash
# 本地复现CI环境
docker run -it ubuntu:22.04 bash
apt-get update && apt-get install -y bash curl wget git

# 运行相同的测试命令
bash tests/run_tests.sh all
```

## 🔒 安全最佳实践

### Secrets管理
- 使用GitHub Secrets存储敏感信息
- 不在代码中硬编码凭据
- 定期轮换访问令牌

### 权限控制
- 最小权限原则
- 分支保护规则
- 必需的状态检查

## 📈 性能优化

### 构建优化
- 并行执行测试
- 缓存依赖
- 条件执行任务

### 资源管理
- 合理设置超时时间
- 限制并发任务数量
- 及时清理临时文件

## 📚 相关文档

- [测试指南](TESTING.md)
- [安装指南](INSTALLATION.md)
- [API文档](API.md)
- [使用指南](USAGE.md)

## 🔄 工作流更新

### 修改工作流
1. 编辑 `.github/workflows/main-ci.yml`
2. 提交更改
3. 验证工作流运行

### 添加新检查
```yaml
- name: 新的检查步骤
  run: |
    echo "执行新的检查"
    # 添加检查命令
```

## 📋 检查清单

发布前确认：
- [ ] 所有测试通过
- [ ] 安全扫描无问题
- [ ] 文档已更新
- [ ] 版本号已更新
- [ ] 变更日志已记录
## 模块元数据校验与缓存API测试集成

CI 已在以下工作流中集成模块元数据校验：

- `.github/workflows/enhanced-ci-cd.yml`
- `.github/workflows/main-ci.yml`

构建阶段会调用 `modules/module_metadata_checker.sh` 对模块文件的前 30 行进行扫描，若缺失 `# Module:`、`# Version:` 或 `# Depends:` 头部，构建将失败。

此外，统一缓存 API 的基础单元测试已纳入 `tests/run_tests.sh`：

- `tests/cache_api_tests.sh`：验证缓存读写与 TTL 过期。
- `tests/cache_stats_tests.sh`：验证缓存统计输出。
- `tests/metadata_validation_tests.sh`：验证模块元数据校验在正常与异常场景下的行为。

本地验证可执行：

```bash
bash tests/run_tests.sh
```