# IPv6 WireGuard Manager 测试指南

## 📋 概述

本指南提供了IPv6 WireGuard Manager的完整测试方案，包括单元测试、集成测试、性能测试、安全测试等。

## 🎯 测试策略

### 测试层次
1. **单元测试** - 测试单个组件功能
2. **集成测试** - 测试组件间交互
3. **系统测试** - 测试完整系统功能
4. **性能测试** - 测试系统性能指标
5. **安全测试** - 测试安全漏洞和防护
6. **用户验收测试** - 测试用户体验

### 测试环境
- **开发环境** - 本地开发测试
- **测试环境** - 独立测试服务器
- **预生产环境** - 生产环境镜像
- **生产环境** - 生产环境验证

## 🚀 快速开始

### 运行所有测试
```bash
# 运行完整测试套件
python scripts/run_tests.py

# 运行特定类型测试
python scripts/run_tests.py --type unit
python scripts/run_tests.py --type integration
python scripts/run_tests.py --type performance
```

### 测试覆盖率
```bash
# 生成测试覆盖率报告
python scripts/run_tests.py --coverage

# 查看覆盖率报告
open htmlcov/index.html
```

## 🔧 单元测试

### 后端API测试
```bash
# 运行API单元测试
cd backend
python -m pytest tests/unit/test_api.py -v

# 运行特定API测试
python -m pytest tests/unit/test_api.py::test_user_creation -v
```

### 数据库测试
```bash
# 运行数据库单元测试
python -m pytest tests/unit/test_database.py -v

# 运行模型测试
python -m pytest tests/unit/test_models.py -v
```

### 核心功能测试
```bash
# 运行核心功能测试
python -m pytest tests/unit/test_core.py -v

# 运行配置测试
python -m pytest tests/unit/test_config.py -v
```

## 🔗 集成测试

### API集成测试
```bash
# 运行API集成测试
python -m pytest tests/integration/test_api_integration.py -v

# 运行数据库集成测试
python -m pytest tests/integration/test_database_integration.py -v
```

### 服务集成测试
```bash
# 运行服务集成测试
python -m pytest tests/integration/test_services.py -v

# 运行外部服务集成测试
python -m pytest tests/integration/test_external_services.py -v
```

## ⚡ 性能测试

### 负载测试
```bash
# 运行负载测试
python scripts/performance/load_test.py

# 运行压力测试
python scripts/performance/stress_test.py

# 运行并发测试
python scripts/performance/concurrent_test.py
```

### 性能基准测试
```bash
# 运行性能基准测试
python scripts/performance/benchmark_test.py

# 生成性能报告
python scripts/performance/performance_report.py
```

## 🔒 安全测试

### 漏洞扫描
```bash
# 运行安全扫描
python scripts/security/security_scan.py

# 运行依赖漏洞检查
python scripts/security/dependency_scan.py

# 运行代码安全分析
python scripts/security/code_analysis.py
```

### 渗透测试
```bash
# 运行渗透测试
python scripts/security/penetration_test.py

# 运行认证测试
python scripts/security/auth_test.py

# 运行授权测试
python scripts/security/authorization_test.py
```

## 🌐 环境测试

### WSL测试
```bash
# 运行WSL测试
python scripts/run_wsl_tests.py

# 运行WSL功能测试
python scripts/run_wsl_tests.py --mode functional

# 运行WSL性能测试
python scripts/run_wsl_tests.py --mode performance
```

### 远程VPS测试
```bash
# 运行远程VPS测试
python scripts/run_remote_tests.py

# 运行远程功能测试
python scripts/run_remote_tests.py --mode functional

# 运行远程性能测试
python scripts/run_remote_tests.py --mode performance
```

### Docker测试
```bash
# 运行Docker测试
docker-compose -f docker-compose.test.yml up --abort-on-container-exit

# 运行Docker集成测试
docker-compose -f docker-compose.test.yml run --rm test
```

## 📊 测试报告

### 生成测试报告
```bash
# 生成HTML测试报告
python scripts/run_tests.py --html-report

# 生成JSON测试报告
python scripts/run_tests.py --json-report

# 生成XML测试报告
python scripts/run_tests.py --xml-report
```

### 测试指标
```bash
# 查看测试统计
python scripts/test_stats.py

# 查看测试趋势
python scripts/test_trends.py

# 查看测试质量
python scripts/test_quality.py
```

## 🔧 测试配置

### 测试环境配置
```bash
# 复制测试配置
cp env.template .env.test

# 编辑测试配置
vim .env.test
```

### 测试数据库配置
```bash
# 创建测试数据库
mysql -u root -p
CREATE DATABASE ipv6wgm_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'ipv6wgm_test'@'localhost' IDENTIFIED BY 'test_password';
GRANT ALL PRIVILEGES ON ipv6wgm_test.* TO 'ipv6wgm_test'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 测试数据准备
```bash
# 运行测试数据初始化
python scripts/test_data/init_test_data.py

# 运行测试数据清理
python scripts/test_data/cleanup_test_data.py
```

## 🚀 持续集成测试

### GitHub Actions
```yaml
# .github/workflows/test.yml
name: Test Suite
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: 3.11
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run tests
        run: python scripts/run_tests.py
```

### 自动化测试
```bash
# 运行自动化测试
./scripts/automated_testing.sh

# 运行夜间测试
./scripts/nightly_testing.sh

# 运行回归测试
./scripts/regression_testing.sh
```

## 📈 测试监控

### 测试指标监控
```bash
# 查看测试指标
python scripts/monitoring/test_metrics.py

# 查看测试趋势
python scripts/monitoring/test_trends.py

# 查看测试质量
python scripts/monitoring/test_quality.py
```

### 测试告警
```bash
# 配置测试告警
python scripts/monitoring/test_alerts.py

# 查看测试告警
python scripts/monitoring/test_alerts.py --status

# 测试告警配置
python scripts/monitoring/test_alerts.py --configure
```

## 🔧 故障排除

### 测试失败排查
```bash
# 查看测试日志
tail -f logs/test.log

# 查看测试错误
grep -i error logs/test.log

# 查看测试警告
grep -i warning logs/test.log
```

### 测试环境问题
```bash
# 检查测试环境
python scripts/test_environment.py

# 检查测试依赖
python scripts/test_dependencies.py

# 检查测试配置
python scripts/test_config.py
```

### 性能问题排查
```bash
# 查看性能指标
python scripts/performance/performance_monitor.py

# 查看性能瓶颈
python scripts/performance/performance_analysis.py

# 查看性能优化建议
python scripts/performance/performance_optimization.py
```

## 📚 测试最佳实践

### 测试编写规范
1. **测试命名** - 使用描述性名称
2. **测试结构** - 遵循AAA模式（Arrange, Act, Assert）
3. **测试隔离** - 每个测试独立运行
4. **测试数据** - 使用测试专用数据
5. **测试清理** - 测试后清理数据

### 测试维护
1. **定期更新** - 保持测试用例最新
2. **测试重构** - 优化测试代码
3. **测试文档** - 维护测试文档
4. **测试培训** - 团队测试技能培训

## 📞 技术支持

### 测试问题反馈
- **测试问题**: [GitHub Issues](https://github.com/ipzh/ipv6-wireguard-manager/issues)
- **测试讨论**: [GitHub Discussions](https://github.com/ipzh/ipv6-wireguard-manager/discussions)
- **测试文档**: [docs/](docs/)

### 测试工具
- **pytest**: Python测试框架
- **coverage**: 测试覆盖率工具
- **locust**: 性能测试工具
- **bandit**: 安全测试工具

---

**测试指南版本**: 3.1.0  
**最后更新**: 2024-01-01  
**维护团队**: IPv6 WireGuard Manager团队
