# IPv6 WireGuard Manager 测试架构文档

## 概述

本文档描述了IPv6 WireGuard Manager项目的测试架构，包括测试框架、配置管理、执行流程和最佳实践。

## 测试架构

### 核心组件

1. **测试框架** (`modules/test_framework.sh`)
   - 提供统一的测试函数、日志和工具
   - 包含颜色定义、日志函数、测试执行函数
   - 提供环境准备、报告生成、验证等功能

2. **测试配置** (`tests/test_config.sh`)
   - 集中管理所有测试相关配置
   - 定义测试套件、目录配置、参数设置
   - 提供配置验证和加载功能

3. **测试运行器** (`tests/run_tests.sh`)
   - 主测试入口，负责参数解析和测试执行协调
   - 支持多种测试类型：unit、integration、performance、compatibility
   - 提供统一的测试执行流程

4. **自动化测试套件** (`scripts/automated-testing.sh`)
   - 实现具体的测试逻辑
   - 支持语法检查、功能测试、集成测试等
   - 提供详细的测试报告

5. **兼容性测试** (`scripts/compatibility_test.sh`)
   - 专门处理系统兼容性测试
   - 支持不同操作系统、Shell环境、架构的测试

### 测试文件结构

```
tests/
├── run_tests.sh              # 主测试入口
├── test_config.sh            # 测试配置
├── comprehensive_test_suite.sh # 综合测试套件
└── data/                     # 测试数据
    ├── sample_configs/       # 示例配置
    └── certificates/         # 测试证书

modules/
└── test_framework.sh         # 测试框架

scripts/
├── automated-testing.sh      # 自动化测试
└── compatibility_test.sh     # 兼容性测试
```

## 测试执行流程

### 1. 初始化阶段
- 解析命令行参数
- 加载测试框架和配置
- 设置环境变量
- 验证测试环境

### 2. 环境准备阶段
- 创建必要目录
- 清理旧数据
- 设置测试环境变量
- 验证系统要求

### 3. 测试执行阶段
- 根据测试类型执行相应测试
- 收集测试结果
- 记录测试日志
- 处理测试错误

### 4. 报告生成阶段
- 生成文本报告
- 生成JSON报告（可选）
- 生成HTML报告（可选）
- 清理临时文件

## 测试类型

### 单元测试 (Unit Tests)
- 测试单个函数和模块
- 验证变量管理、函数管理、配置管理
- 检查错误处理、资源监控功能

### 集成测试 (Integration Tests)
- 测试模块间的交互
- 验证模块加载、依赖管理
- 检查系统兼容性、缓存性能

### 性能测试 (Performance Tests)
- 测试系统性能指标
- 验证内存使用、CPU使用、启动时间
- 检查缓存性能、并行性能

### 兼容性测试 (Compatibility Tests)
- 测试不同环境下的兼容性
- 验证Shell兼容性、OS兼容性
- 检查架构兼容性、版本兼容性

## 配置管理

### 测试配置变量
- `TEST_DIR`: 测试目录
- `PROJECT_ROOT`: 项目根目录
- `REPORT_DIR`: 报告目录
- `LOG_DIR`: 日志目录
- `TEMP_DIR`: 临时目录

### 测试参数
- `TEST_TIMEOUT`: 测试超时时间
- `PARALLEL_JOBS`: 并行任务数
- `VERBOSE`: 详细输出模式
- `DRY_RUN`: 模拟运行模式

### 测试套件定义
- `BASIC_TEST_SUITES`: 基础测试套件
- `FULL_TEST_SUITES`: 完整测试套件
- `UNIT_TEST_SUITES`: 单元测试套件
- `INTEGRATION_TEST_SUITES`: 集成测试套件
- `PERFORMANCE_TEST_SUITES`: 性能测试套件
- `COMPATIBILITY_TEST_SUITES`: 兼容性测试套件

## 使用方法

### 基本用法
```bash
# 运行所有测试
./tests/run_tests.sh

# 运行特定测试类型
./tests/run_tests.sh unit
./tests/run_tests.sh integration
./tests/run_tests.sh performance
./tests/run_tests.sh compatibility

# 使用详细输出
./tests/run_tests.sh --verbose unit

# 设置超时时间
./tests/run_tests.sh --timeout 600 integration

# 模拟运行
./tests/run_tests.sh --dry-run all
```

### 高级用法
```bash
# 设置环境变量
export IPV6WGM_DEBUG_MODE=true
export IPV6WGM_VERBOSE_MODE=true
./tests/run_tests.sh unit

# 生成JSON报告
export GENERATE_JSON_REPORT=true
./tests/run_tests.sh all

# 并行执行
export PARALLEL_JOBS=8
./tests/run_tests.sh performance
```

## 测试报告

### 报告格式
- **文本报告**: 人类可读的测试结果
- **JSON报告**: 机器可读的测试数据
- **HTML报告**: 可视化测试结果（可选）

### 报告内容
- 测试统计信息
- 系统信息
- 环境变量
- 测试结果详情
- 错误信息

### 报告位置
- 文本报告: `$REPORT_DIR/test_report_YYYYMMDD_HHMMSS.txt`
- JSON报告: `$REPORT_DIR/test_report_YYYYMMDD_HHMMSS.json`
- HTML报告: `$REPORT_DIR/test_report_YYYYMMDD_HHMMSS.html`

## 最佳实践

### 1. 测试编写
- 使用统一的测试框架函数
- 遵循命名约定
- 添加适当的注释
- 处理异常情况

### 2. 测试执行
- 定期运行测试
- 使用适当的超时设置
- 监控测试性能
- 及时修复失败的测试

### 3. 测试维护
- 保持测试配置同步
- 定期清理测试数据
- 更新测试文档
- 监控测试覆盖率

### 4. 错误处理
- 提供详细的错误信息
- 记录错误日志
- 实现自动恢复机制
- 提供故障排除指南

## 故障排除

### 常见问题

1. **权限问题**
   ```bash
   chmod +x tests/run_tests.sh
   chmod +x modules/test_framework.sh
   ```

2. **环境问题**
   ```bash
   # 检查必要命令
   command -v bash curl wget
   
   # 检查目录权限
   ls -la tests/
   ```

3. **配置问题**
   ```bash
   # 验证测试配置
   source tests/test_config.sh
   validate_test_config
   ```

4. **测试失败**
   ```bash
   # 查看详细日志
   ./tests/run_tests.sh --verbose unit
   
   # 检查测试环境
   source modules/test_framework.sh
   validate_test_environment
   ```

### 调试技巧

1. **启用调试模式**
   ```bash
   export IPV6WGM_DEBUG_MODE=true
   ./tests/run_tests.sh unit
   ```

2. **查看测试日志**
   ```bash
   tail -f /tmp/ipv6wgm_test_logs/test_runner.log
   ```

3. **运行单个测试**
   ```bash
   bash -c 'source modules/test_framework.sh && run_test "test_name" "test_command"'
   ```

## 扩展指南

### 添加新测试
1. 在相应的测试套件中添加测试命令
2. 更新测试配置
3. 添加测试文档
4. 验证测试执行

### 自定义测试框架
1. 扩展 `modules/test_framework.sh`
2. 添加新的测试函数
3. 更新测试配置
4. 更新文档

### 集成CI/CD
1. 配置GitHub Actions
2. 设置测试环境
3. 配置测试报告
4. 设置通知机制

## 版本历史

- **v2.0.0**: 重构版本，消除重复代码，统一测试框架
- **v1.0.0**: 初始版本，基础测试功能

## 贡献指南

1. 遵循现有的代码风格
2. 添加适当的测试
3. 更新相关文档
4. 提交前运行所有测试
5. 提供详细的提交信息
