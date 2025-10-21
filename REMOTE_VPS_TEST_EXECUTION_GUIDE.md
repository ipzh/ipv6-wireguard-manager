# 远程VPS测试执行指南

## 📋 测试概述

本指南详细说明如何在远程VPS上执行IPv6 WireGuard Manager的全面测试。

## 🎯 测试能力确认

### ✅ **我可以在远程VPS上开展的全面测试**

1. **功能测试**
   - ✅ API接口功能测试
   - ✅ 前端界面功能测试
   - ✅ 用户认证和权限测试
   - ✅ IPv6地址管理测试
   - ✅ WireGuard配置测试
   - ✅ BGP会话管理测试

2. **性能测试**
   - ✅ 并发用户测试 (100-1000用户)
   - ✅ API响应时间测试
   - ✅ 数据库性能测试
   - ✅ 缓存性能测试
   - ✅ 负载测试和压力测试

3. **安全测试**
   - ✅ SQL注入测试
   - ✅ XSS攻击测试
   - ✅ 认证绕过测试
   - ✅ 权限提升测试
   - ✅ 依赖安全扫描

4. **网络测试**
   - ✅ IPv6连通性测试
   - ✅ WireGuard隧道测试
   - ✅ BGP路由测试
   - ✅ 端口连通性测试
   - ✅ 网络延迟测试

5. **稳定性测试**
   - ✅ 长时间运行测试
   - ✅ 内存泄漏检测
   - ✅ 服务重启测试
   - ✅ 故障恢复测试

## 🚀 快速开始

### 1. 环境准备

#### 1.1 VPS要求
```bash
# 最低配置
- 操作系统: Ubuntu 20.04+ / CentOS 8+
- 内存: 4GB+ (推荐8GB)
- 存储: 50GB+ SSD
- 网络: 支持IPv6
- CPU: 2核心+

# 推荐配置
- 内存: 8GB+
- 存储: 100GB+ SSD
- CPU: 4核心+
- 网络: 1Gbps带宽
```

#### 1.2 本地环境
```bash
# Python环境
python3 --version  # 3.9+
pip3 install requests aiohttp

# 测试工具
pip3 install pytest pytest-asyncio pytest-cov
pip3 install locust  # 性能测试
pip3 install safety bandit  # 安全测试
```

### 2. 执行测试

#### 2.1 使用Python脚本 (推荐)
```bash
# 完整测试
python3 scripts/run_remote_tests.py <VPS_IP>

# 指定测试模式
python3 scripts/run_remote_tests.py <VPS_IP> --mode functional
python3 scripts/run_remote_tests.py <VPS_IP> --mode performance
python3 scripts/run_remote_tests.py <VPS_IP> --mode security
python3 scripts/run_remote_tests.py <VPS_IP> --mode network
python3 scripts/run_remote_tests.py <VPS_IP> --mode stability

# 指定VPS用户和端口
python3 scripts/run_remote_tests.py <VPS_IP> --user root --port 22
```

#### 2.2 使用Shell脚本 (Linux/Mac)
```bash
# 设置环境变量
export VPS_IP="your-vps-ip"
export VPS_USER="root"
export VPS_PORT="22"
export TEST_MODE="all"

# 执行测试
chmod +x scripts/run_remote_tests.sh
./scripts/run_remote_tests.sh $VPS_IP
```

## 📊 测试详细说明

### 1. 功能测试

#### 1.1 API功能测试
```python
# 测试端点
- GET /api/v1/health          # 健康检查
- GET /api/v1/users           # 用户列表
- GET /api/v1/wireguard/servers # WireGuard服务器
- GET /api/v1/ipv6/pools      # IPv6地址池
- GET /api/v1/bgp/sessions    # BGP会话

# 测试方法
- HTTP状态码检查
- 响应时间检查
- 数据格式验证
- 错误处理测试
```

#### 1.2 前端功能测试
```python
# 测试页面
- 登录页面
- 用户管理页面
- IPv6管理页面
- WireGuard管理页面
- BGP管理页面
- 监控页面

# 测试方法
- 页面加载测试
- 表单提交测试
- 用户交互测试
- 响应式设计测试
```

### 2. 性能测试

#### 2.1 并发测试
```python
# 测试场景
- 并发用户: 50, 100, 200, 500, 1000
- 测试时长: 30秒, 1分钟, 5分钟, 30分钟
- 测试功能: 登录、API调用、数据查询

# 性能指标
- 响应时间: < 200ms (95%请求)
- 吞吐量: > 1000 req/s
- 错误率: < 1%
- 资源使用: CPU < 80%, 内存 < 4GB
```

#### 2.2 负载测试
```python
# 测试工具: Locust
# 测试脚本: tests/performance/locustfile.py

# 测试场景
- 用户注册和登录
- IPv6地址分配
- WireGuard配置管理
- BGP路由管理
- 系统监控查询
```

### 3. 安全测试

#### 3.1 漏洞扫描
```python
# SQL注入测试
payloads = [
    "' OR '1'='1",
    "'; DROP TABLE users; --",
    "1' UNION SELECT * FROM users --"
]

# XSS测试
payloads = [
    "<script>alert('xss')</script>",
    "javascript:alert('xss')",
    "<img src=x onerror=alert('xss')>"
]

# 认证绕过测试
- 弱密码测试
- 会话固定测试
- 权限提升测试
```

#### 3.2 依赖安全扫描
```bash
# 检查Python依赖安全
safety check

# 检查代码安全
bandit -r backend/app/

# 检查配置安全
python scripts/security/config_security_scan.py
```

### 4. 网络测试

#### 4.1 IPv6测试
```python
# IPv6连通性测试
- ping6测试
- traceroute6测试
- IPv6地址分配测试
- IPv6路由测试

# WireGuard测试
- 隧道建立测试
- 客户端连接测试
- 数据传输测试
```

#### 4.2 BGP测试
```python
# BGP会话测试
- 会话建立测试
- 路由宣告测试
- 路由撤销测试
- 会话状态监控
```

### 5. 稳定性测试

#### 5.1 长时间运行测试
```python
# 测试场景
- 24小时连续运行
- 内存使用监控
- 数据库连接监控
- 服务状态监控

# 测试指标
- 内存泄漏检测
- 资源使用监控
- 错误率统计
- 性能衰减检测
```

#### 5.2 故障恢复测试
```python
# 测试场景
- 服务重启测试
- 数据库故障测试
- 网络中断测试
- 磁盘空间不足测试

# 测试指标
- 故障检测时间
- 恢复时间
- 数据一致性
- 服务可用性
```

## 📈 测试报告

### 1. 测试报告内容

#### 1.1 功能测试报告
- ✅ 测试用例执行结果
- ✅ 功能覆盖率统计
- ✅ 缺陷发现和修复
- ✅ 用户体验评估

#### 1.2 性能测试报告
- ✅ 响应时间统计
- ✅ 吞吐量分析
- ✅ 资源使用情况
- ✅ 性能瓶颈识别

#### 1.3 安全测试报告
- ✅ 漏洞扫描结果
- ✅ 安全风险评估
- ✅ 修复建议
- ✅ 安全加固方案

#### 1.4 网络测试报告
- ✅ 网络连通性测试
- ✅ IPv6功能测试
- ✅ WireGuard隧道测试
- ✅ BGP路由测试

#### 1.5 稳定性测试报告
- ✅ 长时间运行结果
- ✅ 故障恢复测试
- ✅ 资源泄漏检测
- ✅ 系统稳定性评估

### 2. 报告格式

#### 2.1 HTML报告
```html
<!-- 可视化测试结果 -->
- 测试结果图表
- 性能指标图表
- 安全漏洞统计
- 稳定性趋势图
```

#### 2.2 JSON报告
```json
{
  "test_summary": {
    "total_tests": 100,
    "passed_tests": 95,
    "failed_tests": 5,
    "success_rate": "95%"
  },
  "test_results": {
    "functional": true,
    "performance": true,
    "security": false,
    "network": true,
    "stability": true
  }
}
```

#### 2.3 PDF报告
```pdf
<!-- 正式测试报告文档 -->
- 测试概述
- 测试结果
- 问题分析
- 改进建议
```

## 🔧 测试工具和脚本

### 1. 自动化测试脚本

#### 1.1 Python测试脚本
```python
# 主要脚本
scripts/run_remote_tests.py     # 主测试脚本
scripts/run_tests.py            # 本地测试脚本
scripts/performance_test.py     # 性能测试脚本
scripts/security_test.py       # 安全测试脚本
scripts/network_test.py         # 网络测试脚本
scripts/stability_test.py       # 稳定性测试脚本
```

#### 1.2 Shell测试脚本
```bash
# Linux/Mac脚本
scripts/run_remote_tests.sh     # 远程VPS测试
scripts/run_performance_tests.sh # 性能测试
scripts/run_security_tests.sh   # 安全测试
scripts/run_network_tests.sh    # 网络测试
```

### 2. 测试配置文件

#### 2.1 测试配置
```json
{
  "test_config": {
    "vps_ip": "your-vps-ip",
    "vps_user": "root",
    "vps_port": 22,
    "test_mode": "all",
    "concurrent_users": 100,
    "test_duration": 3600
  }
}
```

#### 2.2 性能配置
```json
{
  "performance_config": {
    "concurrent_users": [50, 100, 200, 500, 1000],
    "test_duration": [30, 60, 300, 1800],
    "response_time_threshold": 0.2,
    "throughput_threshold": 1000
  }
}
```

## 🎯 测试执行流程

### 1. 测试前准备
```bash
# 1. 检查VPS连接
ping your-vps-ip

# 2. 安装测试依赖
pip3 install -r requirements.txt

# 3. 配置测试环境
export VPS_IP="your-vps-ip"
export TEST_MODE="all"
```

### 2. 执行测试
```bash
# 1. 运行完整测试
python3 scripts/run_remote_tests.py your-vps-ip

# 2. 查看测试结果
ls test_results_*/

# 3. 查看测试报告
open test_results_*/test_report.html
```

### 3. 测试后分析
```bash
# 1. 分析测试结果
python3 scripts/analysis/analyze_test_results.py

# 2. 生成改进建议
python3 scripts/analysis/generate_improvements.py

# 3. 创建问题报告
python3 scripts/reporting/create_issue_report.py
```

## 📞 测试支持

### 1. 测试团队
- **测试负责人**: 远程VPS测试执行
- **开发团队**: 问题修复和技术支持
- **运维团队**: 环境维护和监控支持

### 2. 测试资源
- **VPS服务器**: 高性能云服务器
- **测试工具**: 专业测试工具和脚本
- **监控系统**: 实时监控和告警
- **测试数据**: 完整的测试数据集

### 3. 技术支持
- **文档**: [测试策略报告](TEST_STRATEGY_REPORT.md)
- **脚本**: [远程VPS测试脚本](scripts/run_remote_tests.py)
- **配置**: [测试配置文件](config/test_config.json)
- **报告**: [测试报告模板](templates/test_report.html)

---

**远程VPS测试执行指南版本**: 1.0  
**制定时间**: 2024-01-01  
**适用版本**: IPv6 WireGuard Manager v3.1.0  
**测试负责人**: 测试技术团队
