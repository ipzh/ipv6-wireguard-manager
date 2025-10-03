# IPv6 WireGuard Manager 测试指南

## 📋 概述

本项目提供了完整的自动化测试套件，包括单元测试、集成测试、安全测试和兼容性测试。

## 🧪 测试类型

### 1. 单元测试
测试各个模块的独立功能。

**测试内容:**
- 变量管理功能
- 函数管理功能
- 配置管理功能
- 错误处理功能

**运行方式:**
```bash
# 使用测试脚本
./tests/run_tests.sh unit

# 详细模式
./tests/run_tests.sh -v unit
```

### 2. 集成测试
测试模块间的交互和系统整体功能。

**测试内容:**
- 模块加载和依赖管理
- 系统兼容性检查
- 配置文件处理
- 网络功能测试

**运行方式:**
```bash
./tests/run_tests.sh integration
```

### 3. 安全测试
检查安全相关功能和潜在漏洞。

**测试内容:**
- 硬编码凭据检查
- 文件权限验证
- 输入验证测试
- 敏感数据处理

**运行方式:**
```bash
./scripts/automated-testing.sh --test-type security
```

### 4. 兼容性测试
验证跨平台和多环境兼容性。

**测试内容:**
- 操作系统兼容性
- Shell兼容性
- 依赖工具检查
- Windows环境支持

**运行方式:**
```bash
./tests/run_tests.sh compatibility
```

## 🚀 快速开始

### 运行所有测试
```bash
# 完整测试套件
./tests/run_tests.sh all

# 使用Makefile
make test
```

### 测试环境配置
```bash
# 设置测试环境变量
export IPV6WGM_TEST_MODE=true
export IPV6WGM_DEBUG_MODE=false
export IPV6WGM_LOG_LEVEL=INFO
```

## 📊 测试报告

测试完成后会生成以下报告：
- 测试结果摘要
- 覆盖率报告
- 性能指标
- 错误日志

报告位置：`reports/` 目录

## 🔧 CI/CD 集成

项目使用GitHub Actions进行持续集成：

```yaml
# .github/workflows/main-ci.yml
- name: 运行测试
  run: ./tests/run_tests.sh all
```

## 📝 编写测试

### 测试文件结构
```
tests/
├── run_tests.sh          # 主测试运行器
├── test_config.sh        # 测试配置
├── test_cases.sh         # 测试用例
└── automated_test_suite.sh # 自动化测试套件
```

### 测试用例示例
```bash
test_config_validation() {
    local test_config="/tmp/test_config.conf"
    echo "TEST_VALUE=123" > "$test_config"
    
    if validate_config_file "$test_config"; then
        echo "✓ 配置验证测试通过"
        return 0
    else
        echo "✗ 配置验证测试失败"
        return 1
    fi
}
```

## 🐛 故障排除

### 常见问题

1. **权限错误**
   ```bash
   chmod +x tests/*.sh scripts/*.sh
   ```

2. **依赖缺失**
   ```bash
   sudo apt-get install bash curl wget git jq
   ```

3. **测试超时**
   - 增加超时时间：`--timeout 600`
   - 检查网络连接

### 调试模式
```bash
# 启用调试输出
export IPV6WGM_DEBUG_MODE=true
./tests/run_tests.sh -v unit
```

## 📈 性能测试

### 基准测试
```bash
# 启动时间测试
time ./ipv6-wireguard-manager.sh --version

# 内存使用测试
./tests/run_tests.sh performance
```

### 性能指标
- 启动时间 < 2秒
- 内存使用 < 50MB
- 配置加载 < 1秒

## 🔒 安全测试

### 安全检查清单
- [ ] 无硬编码密码
- [ ] 正确的文件权限
- [ ] 输入验证
- [ ] 错误信息不泄露敏感数据

### 安全扫描
```bash
# 运行安全扫描
./scripts/automated-testing.sh --test-type security

# 检查敏感信息
grep -r "password\|secret\|key" --include="*.sh" .
```

## 📚 参考资料

- [项目README](../README.md)
- [安装指南](INSTALLATION.md)
- [API文档](API.md)
- [使用指南](USAGE.md)