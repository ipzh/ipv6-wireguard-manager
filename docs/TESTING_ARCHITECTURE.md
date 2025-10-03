# 测试架构文档

## 概述

本文档详细描述了 IPv6-WireGuard Manager 项目的测试架构，包括测试策略、测试类型、测试工具、测试环境和测试流程等方面的设计。

## 测试架构概览

### 测试金字塔

```
                    ┌─────────────────┐
                    │   端到端测试     │
                    │   (E2E Tests)   │
                    └─────────────────┘
                           │
                    ┌─────────────────┐
                    │   集成测试       │
                    │ (Integration)   │
                    └─────────────────┘
                           │
                    ┌─────────────────┐
                    │   单元测试       │
                    │   (Unit Tests)  │
                    └─────────────────┘
```

### 测试层次说明

1. **单元测试 (Unit Tests)**
   - 测试单个函数或模块
   - 快速执行，高覆盖率
   - 隔离外部依赖

2. **集成测试 (Integration Tests)**
   - 测试模块间的交互
   - 验证接口兼容性
   - 测试数据流

3. **端到端测试 (E2E Tests)**
   - 测试完整用户流程
   - 验证系统整体功能
   - 模拟真实使用场景

## 测试类型详细说明

### 1. 单元测试

#### 测试范围
- 函数逻辑测试
- 模块功能测试
- 错误处理测试
- 边界条件测试

#### 测试工具
```bash
# Shell 脚本测试
bash -n script.sh  # 语法检查
shellcheck script.sh  # 静态分析

# 自定义测试框架
./tests/run_tests.sh unit
```

#### 测试示例
```bash
#!/bin/bash
# tests/unit/test_common_functions.sh

test_log_info() {
    local result=$(log_info "Test message" 2>&1)
    assert_contains "$result" "INFO"
}

test_validate_ipv6() {
    assert_true "validate_ipv6 '2001:db8::1'"
    assert_false "validate_ipv6 'invalid-ip'"
}
```

### 2. 集成测试

#### 测试范围
- 模块间通信测试
- 配置文件处理测试
- 数据库操作测试
- API 接口测试

#### 测试环境
```yaml
# docker-compose.test.yml
version: '3.8'
services:
  test-environment:
    build: .
    environment:
      - IPV6WGM_TEST_MODE=true
      - IPV6WGM_DEBUG_MODE=true
    volumes:
      - ./tests:/opt/ipv6-wireguard-manager/tests
```

#### 测试示例
```bash
#!/bin/bash
# tests/integration/test_module_loading.sh

test_module_loading() {
    # 测试模块加载
    source modules/common_functions.sh
    assert_true "function_exists log_info"
    
    # 测试模块依赖
    source modules/config_manager.sh
    assert_true "function_exists load_config"
}

test_config_management() {
    # 测试配置加载
    create_test_config
    load_config
    assert_equals "$WIREGUARD_INTERFACE" "wg0"
}
```

### 3. 端到端测试

#### 测试范围
- 完整安装流程测试
- 客户端管理测试
- 网络配置测试
- 服务运行测试

#### 测试场景
```bash
#!/bin/bash
# tests/e2e/test_full_installation.sh

test_full_installation() {
    # 测试完整安装流程
    ./install.sh
    assert_true "systemctl is-active ipv6-wireguard-manager"
    
    # 测试客户端添加
    ./ipv6-wireguard-manager.sh add-client test-client
    assert_true "wg show | grep test-client"
    
    # 测试客户端删除
    ./ipv6-wireguard-manager.sh remove-client test-client
    assert_false "wg show | grep test-client"
}
```

## 测试工具和框架

### 1. 测试框架

#### 自定义测试框架
```bash
# tests/test_framework.sh
assert_true() {
    if ! eval "$1"; then
        echo "FAIL: $1"
        exit 1
    fi
}

assert_false() {
    if eval "$1"; then
        echo "FAIL: $1 (expected false)"
        exit 1
    fi
}

assert_equals() {
    if [ "$1" != "$2" ]; then
        echo "FAIL: Expected '$2', got '$1'"
        exit 1
    fi
}

assert_contains() {
    if [[ "$1" != *"$2"* ]]; then
        echo "FAIL: '$1' does not contain '$2'"
        exit 1
    fi
}
```

#### 测试运行器
```bash
#!/bin/bash
# tests/run_tests.sh

run_unit_tests() {
    echo "运行单元测试..."
    find tests/unit -name "*.sh" -exec bash {} \;
}

run_integration_tests() {
    echo "运行集成测试..."
    find tests/integration -name "*.sh" -exec bash {} \;
}

run_e2e_tests() {
    echo "运行端到端测试..."
    find tests/e2e -name "*.sh" -exec bash {} \;
}
```

### 2. 静态分析工具

#### ShellCheck
```bash
# 语法检查
shellcheck --shell=bash script.sh

# 安全检查
shellcheck --severity=warning script.sh

# 格式化输出
shellcheck --format=json script.sh
```

#### 其他工具
```bash
# 代码复杂度分析
complexity script.sh

# 代码覆盖率
kcov --include-pattern=*.sh coverage/ script.sh

# 性能分析
time script.sh
```

### 3. 动态测试工具

#### 内存检测
```bash
# Valgrind 内存检测
valgrind --tool=memcheck --leak-check=full script.sh

# 内存使用监控
/usr/bin/time -v script.sh
```

#### 性能测试
```bash
# 基准测试
hyperfine 'script.sh'

# 系统监控
htop
iotop
```

## 测试环境配置

### 1. 本地测试环境

#### 环境要求
```bash
# 操作系统
Ubuntu 20.04+ / Debian 11+ / CentOS 8+ / Fedora 38+

# 依赖工具
bash 4.4+
curl 7.68+
wget 1.20+
git 2.25+
jq 1.6+
```

#### 环境设置
```bash
#!/bin/bash
# scripts/setup-test-environment.sh

setup_test_environment() {
    # 创建测试目录
    mkdir -p /tmp/ipv6wgm_test
    
    # 设置环境变量
    export IPV6WGM_TEST_MODE=true
    export IPV6WGM_DEBUG_MODE=true
    export IPV6WGM_CONFIG_DIR=/tmp/ipv6wgm_test/config
    export IPV6WGM_LOG_DIR=/tmp/ipv6wgm_test/logs
    export IPV6WGM_TEMP_DIR=/tmp/ipv6wgm_test/temp
    
    # 安装测试依赖
    install_test_dependencies
}
```

### 2. CI/CD 测试环境

#### GitHub Actions 环境
```yaml
# .github/workflows/enhanced-ci.yml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest, macos-latest]
    shell: [bash, dash]
    version: [20.04, 22.04]
```

#### Docker 测试环境
```dockerfile
# Dockerfile.test
FROM ubuntu:22.04

# 安装测试依赖
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    wget \
    git \
    jq \
    shellcheck \
    valgrind

# 设置测试环境
ENV IPV6WGM_TEST_MODE=true
ENV IPV6WGM_DEBUG_MODE=true

# 复制测试文件
COPY tests/ /opt/ipv6-wireguard-manager/tests/
COPY modules/ /opt/ipv6-wireguard-manager/modules/

# 运行测试
CMD ["/opt/ipv6-wireguard-manager/tests/run_tests.sh"]
```

### 3. 生产环境测试

#### 测试环境
```yaml
# docker-compose.prod-test.yml
version: '3.8'
services:
  ipv6-wireguard-manager:
    image: ipv6-wireguard-manager:latest
    environment:
      - IPV6WGM_ENV=production
      - IPV6WGM_TEST_MODE=true
    volumes:
      - ./config:/etc/ipv6-wireguard-manager
      - ./logs:/var/log/ipv6-wireguard-manager
```

## 测试数据管理

### 1. 测试数据分类

#### 静态测试数据
```bash
# tests/data/test_configs/
├── basic_config.conf
├── advanced_config.conf
├── invalid_config.conf
└── edge_case_config.conf
```

#### 动态测试数据
```bash
# tests/data/test_clients/
├── client1.conf
├── client2.conf
├── client3.conf
└── client4.conf
```

#### 模拟数据
```bash
# tests/data/mock/
├── network_interfaces.json
├── routing_tables.json
└── system_info.json
```

### 2. 测试数据生成

#### 自动生成
```bash
#!/bin/bash
# tests/generate_test_data.sh

generate_test_configs() {
    # 生成基本配置
    cat > tests/data/test_configs/basic_config.conf << EOF
    [Interface]
    PrivateKey = $(wg genkey)
    Address = 10.0.0.1/24
    ListenPort = 51820
    EOF
    
    # 生成高级配置
    cat > tests/data/test_configs/advanced_config.conf << EOF
    [Interface]
    PrivateKey = $(wg genkey)
    Address = 10.0.0.1/24,fd00:dead:beef::1/64
    ListenPort = 51820
    PostUp = iptables -A FORWARD -i %i -j ACCEPT
    PostDown = iptables -D FORWARD -i %i -j ACCEPT
    EOF
}
```

#### 数据验证
```bash
#!/bin/bash
# tests/validate_test_data.sh

validate_test_data() {
    # 验证配置文件
    for config in tests/data/test_configs/*.conf; do
        assert_true "wg-quick strip $config"
    done
    
    # 验证客户端配置
    for client in tests/data/test_clients/*.conf; do
        assert_true "wg-quick strip $client"
    done
}
```

## 测试覆盖率

### 1. 覆盖率指标

#### 代码覆盖率
```bash
#!/bin/bash
# tests/coverage/collect_coverage.sh

collect_coverage() {
    # 使用 kcov 收集覆盖率
    kcov --include-pattern=*.sh \
         --exclude-pattern=test_* \
         coverage/ \
         ipv6-wireguard-manager.sh
    
    # 生成覆盖率报告
    generate_coverage_report
}
```

#### 功能覆盖率
```bash
#!/bin/bash
# tests/coverage/functional_coverage.sh

check_functional_coverage() {
    # 检查主要功能
    local functions=(
        "install_wireguard"
        "configure_wireguard"
        "add_client"
        "remove_client"
        "list_clients"
        "show_status"
    )
    
    for func in "${functions[@]}"; do
        assert_true "function_exists $func"
    done
}
```

### 2. 覆盖率报告

#### 生成报告
```bash
#!/bin/bash
# tests/coverage/generate_report.sh

generate_coverage_report() {
    # 生成 HTML 报告
    kcov --report-only \
         --include-pattern=*.sh \
         coverage/ \
         coverage-report/
    
    # 生成 JSON 报告
    kcov --report-only \
         --include-pattern=*.sh \
         coverage/ \
         coverage.json
}
```

#### 覆盖率阈值
```yaml
# .github/workflows/enhanced-ci.yml
- name: 检查覆盖率阈值
  run: |
    coverage=$(cat coverage.json | jq '.percent_covered')
    if (( $(echo "$coverage < 80" | bc -l) )); then
      echo "覆盖率低于阈值: $coverage% < 80%"
      exit 1
    fi
```

## 性能测试

### 1. 性能指标

#### 响应时间
```bash
#!/bin/bash
# tests/performance/response_time.sh

test_response_time() {
    # 测试命令响应时间
    local start_time=$(date +%s%N)
    ./ipv6-wireguard-manager.sh --help > /dev/null
    local end_time=$(date +%s%N)
    
    local duration=$(( (end_time - start_time) / 1000000 ))
    assert_true "[ $duration -lt 1000 ]"  # 小于1秒
}
```

#### 内存使用
```bash
#!/bin/bash
# tests/performance/memory_usage.sh

test_memory_usage() {
    # 测试内存使用
    local memory_usage=$(/usr/bin/time -v ./ipv6-wireguard-manager.sh --help 2>&1 | grep "Maximum resident set size" | awk '{print $6}')
    assert_true "[ $memory_usage -lt 50000 ]"  # 小于50MB
}
```

#### CPU 使用
```bash
#!/bin/bash
# tests/performance/cpu_usage.sh

test_cpu_usage() {
    # 测试 CPU 使用
    local cpu_usage=$(/usr/bin/time -v ./ipv6-wireguard-manager.sh --help 2>&1 | grep "User time" | awk '{print $4}')
    assert_true "[ $(echo "$cpu_usage < 1.0" | bc -l) -eq 1 ]"  # 小于1秒
}
```

### 2. 负载测试

#### 并发测试
```bash
#!/bin/bash
# tests/performance/concurrent_test.sh

test_concurrent_operations() {
    # 并发添加客户端
    for i in {1..10}; do
        ./ipv6-wireguard-manager.sh add-client "client-$i" &
    done
    wait
    
    # 验证所有客户端都已添加
    local client_count=$(./ipv6-wireguard-manager.sh list-clients | wc -l)
    assert_equals "$client_count" "10"
}
```

#### 压力测试
```bash
#!/bin/bash
# tests/performance/stress_test.sh

test_stress_operations() {
    # 压力测试
    for i in {1..100}; do
        ./ipv6-wireguard-manager.sh add-client "stress-client-$i"
        ./ipv6-wireguard-manager.sh remove-client "stress-client-$i"
    done
    
    # 验证系统稳定性
    assert_true "systemctl is-active ipv6-wireguard-manager"
}
```

## 安全测试

### 1. 安全扫描

#### 静态安全分析
```bash
#!/bin/bash
# tests/security/static_analysis.sh

run_static_security_analysis() {
    # ShellCheck 安全扫描
    shellcheck --severity=warning --format=json *.sh > security-report.json
    
    # 检查敏感信息
    grep -r "password\|secret\|key" --include="*.sh" . | grep -v "example\|test" > sensitive-info.txt
    
    # 检查权限
    find . -name "*.sh" -exec ls -la {} \; | grep -v "rwxr-xr-x" > permission-issues.txt
}
```

#### 动态安全测试
```bash
#!/bin/bash
# tests/security/dynamic_test.sh

test_security_vulnerabilities() {
    # 测试输入验证
    assert_false "./ipv6-wireguard-manager.sh add-client '; rm -rf /'"
    
    # 测试权限提升
    assert_false "./ipv6-wireguard-manager.sh --root-command 'chmod 777 /'"
    
    # 测试路径遍历
    assert_false "./ipv6-wireguard-manager.sh add-client '../../../etc/passwd'"
}
```

### 2. 渗透测试

#### 网络渗透测试
```bash
#!/bin/bash
# tests/security/penetration_test.sh

test_network_security() {
    # 测试端口扫描
    nmap -sS -O localhost
    
    # 测试服务漏洞
    nikto -h localhost:8080
    
    # 测试 SSL/TLS 配置
    sslscan localhost:443
}
```

## 测试自动化

### 1. 自动化测试流程

#### 测试流水线
```yaml
# .github/workflows/enhanced-ci.yml
jobs:
  unit-tests:
    name: 单元测试
    runs-on: ubuntu-latest
    steps:
      - name: 运行单元测试
        run: ./tests/run_tests.sh unit
        
  integration-tests:
    name: 集成测试
    needs: unit-tests
    runs-on: ubuntu-latest
    steps:
      - name: 运行集成测试
        run: ./tests/run_tests.sh integration
        
  e2e-tests:
    name: 端到端测试
    needs: integration-tests
    runs-on: ubuntu-latest
    steps:
      - name: 运行端到端测试
        run: ./tests/run_tests.sh e2e
```

#### 测试调度
```bash
#!/bin/bash
# tests/scheduler.sh

schedule_tests() {
    # 每日测试
    echo "0 2 * * * /opt/ipv6-wireguard-manager/tests/run_tests.sh daily" | crontab -
    
    # 每周测试
    echo "0 3 * * 1 /opt/ipv6-wireguard-manager/tests/run_tests.sh weekly" | crontab -
    
    # 每月测试
    echo "0 4 1 * * /opt/ipv6-wireguard-manager/tests/run_tests.sh monthly" | crontab -
}
```

### 2. 测试报告

#### 测试结果报告
```bash
#!/bin/bash
# tests/reporting/generate_report.sh

generate_test_report() {
    # 生成测试报告
    cat > test-report.html << EOF
    <!DOCTYPE html>
    <html>
    <head>
        <title>IPv6-WireGuard Manager 测试报告</title>
    </head>
    <body>
        <h1>测试报告</h1>
        <h2>测试统计</h2>
        <p>总测试数: $(cat test-results.txt | wc -l)</p>
        <p>通过测试: $(grep PASS test-results.txt | wc -l)</p>
        <p>失败测试: $(grep FAIL test-results.txt | wc -l)</p>
        <p>成功率: $(echo "scale=2; $(grep PASS test-results.txt | wc -l) * 100 / $(cat test-results.txt | wc -l)" | bc)%</p>
    </body>
    </html>
    EOF
}
```

#### 测试趋势分析
```bash
#!/bin/bash
# tests/reporting/trend_analysis.sh

analyze_test_trends() {
    # 分析测试趋势
    echo "测试趋势分析:" > trend-analysis.txt
    echo "日期,总测试数,通过数,失败数,成功率" >> trend-analysis.txt
    
    # 收集历史数据
    for date in $(ls test-results/ | sort); do
        local total=$(cat test-results/$date | wc -l)
        local passed=$(grep PASS test-results/$date | wc -l)
        local failed=$(grep FAIL test-results/$date | wc -l)
        local success_rate=$(echo "scale=2; $passed * 100 / $total" | bc)
        
        echo "$date,$total,$passed,$failed,$success_rate%" >> trend-analysis.txt
    done
}
```

## 测试维护

### 1. 测试用例维护

#### 测试用例更新
```bash
#!/bin/bash
# tests/maintenance/update_test_cases.sh

update_test_cases() {
    # 更新测试用例
    find tests/ -name "*.sh" -exec sed -i 's/old_function/new_function/g' {} \;
    
    # 验证测试用例
    ./tests/run_tests.sh validate
    
    # 更新测试文档
    ./tests/generate_documentation.sh
}
```

#### 测试数据维护
```bash
#!/bin/bash
# tests/maintenance/maintain_test_data.sh

maintain_test_data() {
    # 清理过期测试数据
    find tests/data/ -name "*.tmp" -mtime +7 -delete
    
    # 更新测试数据
    ./tests/generate_test_data.sh
    
    # 验证测试数据
    ./tests/validate_test_data.sh
}
```

### 2. 测试环境维护

#### 环境清理
```bash
#!/bin/bash
# tests/maintenance/cleanup_environment.sh

cleanup_test_environment() {
    # 清理测试环境
    rm -rf /tmp/ipv6wgm_test_*
    
    # 重置网络配置
    ip link delete wg0 2>/dev/null || true
    
    # 清理防火墙规则
    iptables -F
    ip6tables -F
    
    # 重启服务
    systemctl restart ipv6-wireguard-manager
}
```

#### 环境监控
```bash
#!/bin/bash
# tests/maintenance/monitor_environment.sh

monitor_test_environment() {
    # 监控磁盘空间
    local disk_usage=$(df /tmp | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ $disk_usage -gt 80 ]; then
        echo "警告: 磁盘使用率过高: $disk_usage%"
        cleanup_test_environment
    fi
    
    # 监控内存使用
    local memory_usage=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100)}')
    if [ $memory_usage -gt 80 ]; then
        echo "警告: 内存使用率过高: $memory_usage%"
    fi
}
```

## 总结

IPv6-WireGuard Manager 项目的测试架构采用了分层的测试策略，包括单元测试、集成测试和端到端测试。通过使用自定义测试框架和多种测试工具，确保了代码质量、功能正确性和系统稳定性。

关键特点：

1. **全面的测试覆盖**：从单元测试到端到端测试的完整覆盖
2. **自动化测试流程**：集成到 CI/CD 流水线中的自动化测试
3. **多种测试工具**：静态分析、动态测试、性能测试、安全测试
4. **测试环境管理**：本地、CI/CD 和生产环境的测试支持
5. **测试数据管理**：静态和动态测试数据的生成和管理
6. **测试报告和趋势分析**：详细的测试报告和趋势分析
7. **测试维护**：测试用例和测试环境的持续维护

这个测试架构为项目提供了可靠的质量保证，确保了软件的稳定性和可靠性。
