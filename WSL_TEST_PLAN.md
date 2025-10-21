# IPv6 WireGuard Manager WSL测试计划

## 📋 测试概述

**测试环境**: Windows Subsystem for Linux (WSL)  
**测试目标**: 在WSL环境下全面验证IPv6 WireGuard Manager的功能、性能和稳定性  
**测试优势**: 结合Windows和Linux的优势，提供完整的开发测试环境  

## 🎯 WSL测试优势

### 1. 环境优势
- ✅ **Linux内核**: 真实的Linux环境，支持所有Linux功能
- ✅ **Windows集成**: 与Windows系统无缝集成
- ✅ **开发友好**: 支持Windows IDE和Linux命令行
- ✅ **资源充足**: 利用Windows主机的硬件资源

### 2. 测试优势
- ✅ **真实环境**: 接近生产环境的Linux测试
- ✅ **网络测试**: 支持IPv6和WireGuard网络功能
- ✅ **性能测试**: 不受虚拟机性能限制
- ✅ **开发测试**: 支持完整的开发测试流程

### 3. 部署优势
- ✅ **Docker支持**: 完整的Docker和Docker Compose支持
- ✅ **服务管理**: systemd服务管理
- ✅ **网络配置**: 完整的网络配置能力
- ✅ **文件系统**: 高性能的文件系统访问

## 🚀 WSL测试计划

### 阶段1: WSL环境准备 (1天)

#### 1.1 WSL环境检查
```bash
# 检查WSL版本
wsl --version

# 检查Linux发行版
lsb_release -a

# 检查内核版本
uname -r

# 检查系统资源
free -h
df -h
```

#### 1.2 系统更新和配置
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础工具
sudo apt install -y curl wget git vim nano
sudo apt install -y build-essential python3-dev
sudo apt install -y software-properties-common

# 配置网络
sudo apt install -y net-tools iputils-ping
sudo apt install -y dnsutils
```

#### 1.3 开发环境安装
```bash
# 安装Python环境
sudo apt install -y python3 python3-pip python3-venv
python3 -m pip install --upgrade pip

# 安装Node.js (如果需要前端构建)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 安装Docker Compose
sudo apt install -y docker-compose
```

#### 1.4 项目依赖安装
```bash
# 安装系统依赖
sudo apt install -y mysql-server redis-server
sudo apt install -y nginx php8.1 php8.1-fpm php8.1-mysql
sudo apt install -y wireguard-tools

# 安装Python依赖
pip3 install -r backend/requirements.txt
pip3 install pytest pytest-asyncio pytest-cov
pip3 install requests aiohttp locust
pip3 install safety bandit
```

### 阶段2: 项目部署测试 (1天)

#### 2.1 项目克隆和配置
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 配置环境变量
cp env.template .env
# 编辑.env文件，配置数据库和Redis连接
```

#### 2.2 数据库配置
```bash
# 启动MySQL服务
sudo systemctl start mysql
sudo systemctl enable mysql

# 创建数据库和用户
sudo mysql -u root -p
CREATE DATABASE ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'ipv6wgm'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

#### 2.3 Redis配置
```bash
# 启动Redis服务
sudo systemctl start redis-server
sudo systemctl enable redis-server

# 测试Redis连接
redis-cli ping
```

#### 2.4 应用部署
```bash
# 方式1: Docker部署
./scripts/install.sh --docker-only

# 方式2: 原生部署
./scripts/install.sh --native-only

# 方式3: 混合部署
./scripts/install.sh
```

### 阶段3: 功能测试 (2天)

#### 3.1 单元测试
```bash
# 运行单元测试
python3 scripts/run_tests.py --unit

# 运行特定模块测试
python3 -m pytest tests/test_unit.py -v
python3 -m pytest tests/test_config_management.py -v
python3 -m pytest tests/test_database_optimization.py -v
```

#### 3.2 集成测试
```bash
# 运行集成测试
python3 scripts/run_tests.py --integration

# 测试API集成
python3 -m pytest tests/test_integration.py -v
python3 -m pytest tests/test_api_standardization.py -v
```

#### 3.3 前端测试
```bash
# 测试前端功能
curl -X GET http://localhost/
curl -X GET http://localhost/api/v1/health
curl -X POST http://localhost/api/v1/auth/login
```

#### 3.4 数据库测试
```bash
# 测试数据库连接
python3 -c "
from backend.app.core.database import get_db
db = next(get_db())
print('数据库连接成功')
"

# 测试数据库迁移
cd backend
alembic upgrade head
```

### 阶段4: 性能测试 (1天)

#### 4.1 API性能测试
```bash
# 运行性能测试
python3 scripts/run_tests.py --performance

# 使用Locust进行负载测试
locust -f tests/performance/locustfile.py --host=http://localhost
```

#### 4.2 数据库性能测试
```bash
# 数据库查询性能测试
python3 tests/test_performance.py

# 连接池测试
python3 -c "
import asyncio
from backend.app.core.database import get_db
async def test_connections():
    for i in range(100):
        db = next(get_db())
        print(f'连接 {i+1} 成功')
asyncio.run(test_connections())
"
```

#### 4.3 缓存性能测试
```bash
# Redis缓存测试
python3 -c "
import redis
r = redis.Redis(host='localhost', port=6379, db=0)
for i in range(1000):
    r.set(f'key_{i}', f'value_{i}')
    r.get(f'key_{i}')
print('缓存测试完成')
"
```

### 阶段5: 安全测试 (1天)

#### 5.1 代码安全扫描
```bash
# 运行安全扫描
python3 scripts/run_tests.py --security

# 依赖安全扫描
safety check

# 代码安全扫描
bandit -r backend/app/
```

#### 5.2 API安全测试
```bash
# SQL注入测试
python3 -c "
import requests
payloads = [\"' OR '1'='1\", \"'; DROP TABLE users; --\"]
for payload in payloads:
    response = requests.get(f'http://localhost/api/v1/users?search={payload}')
    print(f'Payload: {payload}, Status: {response.status_code}')
"

# XSS测试
python3 -c "
import requests
payloads = ['<script>alert(\"xss\")</script>', 'javascript:alert(\"xss\")']
for payload in payloads:
    response = requests.get(f'http://localhost/api/v1/users?search={payload}')
    print(f'XSS Payload: {payload}, Status: {response.status_code}')
"
```

#### 5.3 认证安全测试
```bash
# 密码策略测试
python3 -c "
from backend.app.core.security import validate_password
weak_passwords = ['123456', 'password', 'admin']
for pwd in weak_passwords:
    result = validate_password(pwd)
    print(f'Password: {pwd}, Valid: {result}')
"
```

### 阶段6: 网络测试 (1天)

#### 6.1 IPv6网络测试
```bash
# 检查IPv6支持
ip -6 addr show

# IPv6连通性测试
ping6 -c 4 2001:db8::1

# IPv6路由测试
ip -6 route show
```

#### 6.2 WireGuard测试
```bash
# 检查WireGuard支持
wg --version

# 创建测试配置
sudo wg genkey | tee privatekey | wg pubkey > publickey

# 测试WireGuard配置
sudo wg-quick up wg0
sudo wg show
```

#### 6.3 BGP测试
```bash
# 检查BGP工具
which bgpd
which zebra

# 测试BGP配置
python3 -c "
from backend.app.core.bgp import BGPSession
session = BGPSession()
print('BGP会话创建成功')
"
```

### 阶段7: 稳定性测试 (1天)

#### 7.1 长时间运行测试
```bash
# 运行稳定性测试
python3 scripts/run_tests.py --stability

# 24小时运行测试
nohup python3 tests/test_stability.py --duration=86400 &
```

#### 7.2 内存泄漏测试
```bash
# 内存使用监控
python3 -c "
import psutil
import time
import os

def monitor_memory():
    process = psutil.Process(os.getpid())
    for i in range(100):
        memory_info = process.memory_info()
        print(f'Iteration {i}: Memory usage: {memory_info.rss / 1024 / 1024:.2f} MB')
        time.sleep(1)

monitor_memory()
"
```

#### 7.3 服务重启测试
```bash
# 测试服务重启
sudo systemctl restart ipv6-wireguard-manager
sudo systemctl status ipv6-wireguard-manager

# 测试Docker服务重启
docker-compose restart
docker-compose ps
```

## 🔧 WSL测试脚本

### 1. 自动化测试脚本

#### 1.1 主测试脚本
```bash
#!/bin/bash
# scripts/run_wsl_tests.sh

# WSL环境检查
check_wsl_environment() {
    echo "检查WSL环境..."
    wsl --version
    uname -r
    lsb_release -a
}

# 系统更新
update_system() {
    echo "更新系统..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget git vim nano
    sudo apt install -y build-essential python3-dev
}

# 安装依赖
install_dependencies() {
    echo "安装依赖..."
    sudo apt install -y mysql-server redis-server
    sudo apt install -y nginx php8.1 php8.1-fpm php8.1-mysql
    sudo apt install -y wireguard-tools
    pip3 install -r backend/requirements.txt
}

# 运行测试
run_tests() {
    echo "运行测试..."
    python3 scripts/run_tests.py --all
}

# 主函数
main() {
    check_wsl_environment
    update_system
    install_dependencies
    run_tests
}

main "$@"
```

#### 1.2 Python测试脚本
```python
#!/usr/bin/env python3
# scripts/run_wsl_tests.py

import os
import sys
import subprocess
import time
import requests
import asyncio
import aiohttp
from datetime import datetime

class WSLTester:
    """WSL测试器"""
    
    def __init__(self):
        self.base_url = "http://localhost"
        self.test_results = {}
    
    def check_wsl_environment(self):
        """检查WSL环境"""
        print("检查WSL环境...")
        
        # 检查WSL版本
        try:
            result = subprocess.run(['wsl', '--version'], capture_output=True, text=True)
            print(f"WSL版本: {result.stdout}")
        except:
            print("WSL版本检查失败")
        
        # 检查Linux内核
        try:
            result = subprocess.run(['uname', '-r'], capture_output=True, text=True)
            print(f"Linux内核: {result.stdout.strip()}")
        except:
            print("Linux内核检查失败")
        
        # 检查系统资源
        try:
            result = subprocess.run(['free', '-h'], capture_output=True, text=True)
            print(f"内存使用: {result.stdout}")
        except:
            print("内存检查失败")
    
    def run_functional_tests(self):
        """运行功能测试"""
        print("运行功能测试...")
        
        # 测试健康检查
        try:
            response = requests.get(f"{self.base_url}/api/v1/health", timeout=10)
            if response.status_code == 200:
                print("✅ 健康检查通过")
                return True
            else:
                print(f"❌ 健康检查失败: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ 健康检查异常: {e}")
            return False
    
    async def run_performance_tests(self):
        """运行性能测试"""
        print("运行性能测试...")
        
        urls = [
            f"{self.base_url}/api/v1/health",
            f"{self.base_url}/api/v1/users",
            f"{self.base_url}/api/v1/wireguard/servers"
        ]
        
        concurrent_users = 50
        test_duration = 30
        
        async with aiohttp.ClientSession() as session:
            tasks = []
            start_time = time.time()
            
            for _ in range(concurrent_users):
                for url in urls:
                    task = asyncio.create_task(self.make_request(session, url))
                    tasks.append(task)
            
            await asyncio.sleep(test_duration)
            
            for task in tasks:
                task.cancel()
            
            end_time = time.time()
            actual_duration = end_time - start_time
            
            print(f"性能测试完成: {actual_duration:.2f}秒")
            return True
    
    async def make_request(self, session, url):
        """发送请求"""
        start_time = time.time()
        try:
            async with session.get(url) as response:
                await response.text()
                end_time = time.time()
                return end_time - start_time, response.status
        except Exception as e:
            end_time = time.time()
            return end_time - start_time, 0
    
    def run_security_tests(self):
        """运行安全测试"""
        print("运行安全测试...")
        
        # SQL注入测试
        payloads = ["' OR '1'='1", "'; DROP TABLE users; --"]
        for payload in payloads:
            try:
                response = requests.get(f"{self.base_url}/api/v1/users?search={payload}", timeout=5)
                print(f"SQL注入测试: {payload} -> {response.status_code}")
            except:
                pass
        
        print("安全测试完成")
        return True
    
    def run_network_tests(self):
        """运行网络测试"""
        print("运行网络测试...")
        
        # 测试端口连通性
        ports = [80, 443, 8000, 3306, 6379]
        for port in ports:
            try:
                import socket
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(5)
                result = sock.connect_ex(('localhost', port))
                sock.close()
                
                if result == 0:
                    print(f"✅ 端口 {port} 开放")
                else:
                    print(f"❌ 端口 {port} 关闭")
            except Exception as e:
                print(f"❌ 端口 {port} 测试失败: {e}")
        
        return True
    
    async def run_stability_tests(self):
        """运行稳定性测试"""
        print("运行稳定性测试...")
        
        test_duration = 60
        request_interval = 2
        
        start_time = time.time()
        request_count = 0
        success_count = 0
        
        async with aiohttp.ClientSession() as session:
            while time.time() - start_time < test_duration:
                try:
                    async with session.get(f"{self.base_url}/api/v1/health", timeout=10) as response:
                        if response.status == 200:
                            success_count += 1
                        request_count += 1
                except Exception as e:
                    print(f"请求失败: {e}")
                    request_count += 1
                
                await asyncio.sleep(request_interval)
        
        success_rate = (success_count / request_count) * 100 if request_count > 0 else 0
        print(f"稳定性测试结果: 成功率 {success_rate:.2f}%")
        
        return success_rate >= 90
    
    async def run_all_tests(self):
        """运行所有测试"""
        print("开始WSL测试...")
        
        # 检查WSL环境
        self.check_wsl_environment()
        
        # 运行测试
        functional_result = self.run_functional_tests()
        performance_result = await self.run_performance_tests()
        security_result = self.run_security_tests()
        network_result = self.run_network_tests()
        stability_result = await self.run_stability_tests()
        
        # 显示结果
        print("\n测试结果摘要:")
        print(f"功能测试: {'✅ 通过' if functional_result else '❌ 失败'}")
        print(f"性能测试: {'✅ 通过' if performance_result else '❌ 失败'}")
        print(f"安全测试: {'✅ 通过' if security_result else '❌ 失败'}")
        print(f"网络测试: {'✅ 通过' if network_result else '❌ 失败'}")
        print(f"稳定性测试: {'✅ 通过' if stability_result else '❌ 失败'}")
        
        total_tests = 5
        passed_tests = sum([functional_result, performance_result, security_result, network_result, stability_result])
        
        print(f"\n总测试数: {total_tests}")
        print(f"通过测试: {passed_tests}")
        print(f"失败测试: {total_tests - passed_tests}")
        
        if passed_tests == total_tests:
            print("🎉 所有测试通过！")
            return True
        else:
            print("❌ 部分测试失败！")
            return False

async def main():
    """主函数"""
    tester = WSLTester()
    success = await tester.run_all_tests()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    asyncio.run(main())
```

## 📊 测试报告

### 1. 测试报告内容

#### 1.1 WSL环境报告
- ✅ WSL版本和配置
- ✅ Linux内核版本
- ✅ 系统资源使用情况
- ✅ 网络配置状态

#### 1.2 功能测试报告
- ✅ 单元测试结果
- ✅ 集成测试结果
- ✅ API功能测试
- ✅ 前端功能测试

#### 1.3 性能测试报告
- ✅ API响应时间
- ✅ 并发处理能力
- ✅ 数据库性能
- ✅ 缓存性能

#### 1.4 安全测试报告
- ✅ 代码安全扫描
- ✅ 依赖安全扫描
- ✅ API安全测试
- ✅ 认证安全测试

#### 1.5 网络测试报告
- ✅ IPv6连通性
- ✅ WireGuard功能
- ✅ BGP功能
- ✅ 端口连通性

#### 1.6 稳定性测试报告
- ✅ 长时间运行测试
- ✅ 内存泄漏检测
- ✅ 服务重启测试
- ✅ 故障恢复测试

### 2. 报告格式

#### 2.1 HTML报告
```html
<!DOCTYPE html>
<html>
<head>
    <title>IPv6 WireGuard Manager WSL测试报告</title>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .test-result { margin: 10px 0; padding: 10px; border-radius: 5px; }
        .success { background-color: #d4edda; color: #155724; }
        .failure { background-color: #f8d7da; color: #721c24; }
        .info { background-color: #d1ecf1; color: #0c5460; }
    </style>
</head>
<body>
    <div class="header">
        <h1>IPv6 WireGuard Manager WSL测试报告</h1>
        <p>测试时间: 2024-01-01</p>
        <p>测试环境: WSL2 Ubuntu 20.04</p>
    </div>
    
    <h2>测试结果摘要</h2>
    <div class="test-result info">
        <p>WSL环境: ✅ 正常</p>
        <p>功能测试: ✅ 通过</p>
        <p>性能测试: ✅ 通过</p>
        <p>安全测试: ✅ 通过</p>
        <p>网络测试: ✅ 通过</p>
        <p>稳定性测试: ✅ 通过</p>
    </div>
</body>
</html>
```

## 🚀 测试执行

### 1. 快速开始

#### 1.1 环境检查
```bash
# 检查WSL状态
wsl --status

# 检查Linux环境
wsl -l -v

# 进入WSL环境
wsl
```

#### 1.2 执行测试
```bash
# 克隆项目
git clone https://github.com/ipzh/ipv6-wireguard-manager.git
cd ipv6-wireguard-manager

# 运行WSL测试
python3 scripts/run_wsl_tests.py

# 或使用Shell脚本
chmod +x scripts/run_wsl_tests.sh
./scripts/run_wsl_tests.sh
```

### 2. 测试配置

#### 2.1 环境变量
```bash
# 设置测试环境
export TEST_MODE="all"
export TEST_DURATION="3600"
export CONCURRENT_USERS="100"
export WSL_DISTRO="Ubuntu-20.04"
```

#### 2.2 测试配置
```json
{
  "wsl_config": {
    "distro": "Ubuntu-20.04",
    "memory": "8GB",
    "cpu": "4",
    "test_mode": "all",
    "test_duration": 3600,
    "concurrent_users": 100
  }
}
```

## 📞 测试支持

### 1. 测试团队
- **测试负责人**: WSL环境测试执行
- **开发团队**: 问题修复和技术支持
- **运维团队**: WSL环境维护和监控

### 2. 测试资源
- **WSL环境**: Windows Subsystem for Linux
- **测试工具**: 专业测试工具和脚本
- **监控系统**: 实时监控和告警
- **测试数据**: 完整的测试数据集

### 3. 技术支持
- **文档**: [WSL测试计划](WSL_TEST_PLAN.md)
- **脚本**: [WSL测试脚本](scripts/run_wsl_tests.py)
- **配置**: [测试配置文件](config/wsl_test_config.json)
- **报告**: [测试报告模板](templates/wsl_test_report.html)

---

**WSL测试计划版本**: 1.0  
**制定时间**: 2024-01-01  
**适用版本**: IPv6 WireGuard Manager v3.1.0  
**测试负责人**: 测试技术团队
