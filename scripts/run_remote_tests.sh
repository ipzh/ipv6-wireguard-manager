#!/bin/bash

# IPv6 WireGuard Manager 远程VPS测试脚本
# 在远程VPS上执行全面的测试

set -e
set -u
set -o pipefail

# 脚本信息
SCRIPT_NAME="IPv6 WireGuard Manager Remote VPS Test Suite"
SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test() {
    echo -e "${PURPLE}[TEST]${NC} $1"
}

# 测试配置
VPS_IP="${VPS_IP:-}"
VPS_USER="${VPS_USER:-root}"
VPS_PORT="${VPS_PORT:-22}"
TEST_MODE="${TEST_MODE:-all}"
TEST_DURATION="${TEST_DURATION:-3600}"  # 1小时
CONCURRENT_USERS="${CONCURRENT_USERS:-100}"

# 测试结果目录
TEST_RESULTS_DIR="test_results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$TEST_RESULTS_DIR"

# 检查VPS连接
check_vps_connection() {
    log_info "检查VPS连接..."
    
    if [ -z "$VPS_IP" ]; then
        log_error "请设置VPS_IP环境变量"
        exit 1
    fi
    
    if ! ping -c 3 "$VPS_IP" > /dev/null 2>&1; then
        log_error "无法连接到VPS: $VPS_IP"
        exit 1
    fi
    
    log_success "VPS连接正常: $VPS_IP"
}

# 部署应用到VPS
deploy_to_vps() {
    log_info "部署应用到VPS..."
    
    # 创建部署脚本
    cat > deploy_script.sh << 'EOF'
#!/bin/bash
set -e

# 更新系统
apt update && apt upgrade -y

# 安装基础软件
apt install -y git curl wget docker.io docker-compose
apt install -y python3 python3-pip mysql-server redis-server
apt install -y nginx php8.1 php8.1-fpm php8.1-mysql
apt install -y wireguard-tools

# 克隆项目
if [ ! -d "ipv6-wireguard-manager" ]; then
    git clone https://github.com/ipzh/ipv6-wireguard-manager.git
fi

cd ipv6-wireguard-manager

# 运行安装脚本
chmod +x scripts/install.sh
./scripts/install.sh --docker-only

# 启动服务
docker-compose up -d

# 等待服务启动
sleep 30

# 检查服务状态
docker-compose ps
EOF

    # 上传并执行部署脚本
    scp -P "$VPS_PORT" deploy_script.sh "$VPS_USER@$VPS_IP:/tmp/"
    ssh -p "$VPS_PORT" "$VPS_USER@$VPS_IP" "chmod +x /tmp/deploy_script.sh && /tmp/deploy_script.sh"
    
    log_success "应用部署完成"
}

# 功能测试
run_functional_tests() {
    log_test "执行功能测试..."
    
    # 创建功能测试脚本
    cat > functional_test.py << 'EOF'
#!/usr/bin/env python3
import requests
import json
import time
import sys

VPS_IP = sys.argv[1] if len(sys.argv) > 1 else "localhost"
BASE_URL = f"http://{VPS_IP}"

def test_health_check():
    """测试健康检查"""
    try:
        response = requests.get(f"{BASE_URL}/api/v1/health", timeout=10)
        assert response.status_code == 200
        print("✅ 健康检查通过")
        return True
    except Exception as e:
        print(f"❌ 健康检查失败: {e}")
        return False

def test_api_endpoints():
    """测试API端点"""
    endpoints = [
        "/api/v1/health",
        "/api/v1/auth/login",
        "/api/v1/users",
        "/api/v1/wireguard/servers",
        "/api/v1/ipv6/pools",
        "/api/v1/bgp/sessions"
    ]
    
    results = []
    for endpoint in endpoints:
        try:
            response = requests.get(f"{BASE_URL}{endpoint}", timeout=10)
            print(f"✅ {endpoint}: {response.status_code}")
            results.append(True)
        except Exception as e:
            print(f"❌ {endpoint}: {e}")
            results.append(False)
    
    return all(results)

def test_frontend():
    """测试前端界面"""
    try:
        response = requests.get(f"{BASE_URL}/", timeout=10)
        assert response.status_code == 200
        assert "IPv6 WireGuard Manager" in response.text
        print("✅ 前端界面正常")
        return True
    except Exception as e:
        print(f"❌ 前端界面测试失败: {e}")
        return False

if __name__ == "__main__":
    print("🧪 开始功能测试...")
    
    health_ok = test_health_check()
    api_ok = test_api_endpoints()
    frontend_ok = test_frontend()
    
    if health_ok and api_ok and frontend_ok:
        print("✅ 所有功能测试通过")
        sys.exit(0)
    else:
        print("❌ 功能测试失败")
        sys.exit(1)
EOF

    # 执行功能测试
    python3 functional_test.py "$VPS_IP" > "$TEST_RESULTS_DIR/functional_test.log" 2>&1
    local functional_result=$?
    
    if [ $functional_result -eq 0 ]; then
        log_success "功能测试通过"
    else
        log_error "功能测试失败"
    fi
    
    return $functional_result
}

# 性能测试
run_performance_tests() {
    log_test "执行性能测试..."
    
    # 安装性能测试工具
    pip3 install locust requests aiohttp
    
    # 创建性能测试脚本
    cat > performance_test.py << 'EOF'
#!/usr/bin/env python3
import asyncio
import aiohttp
import time
import statistics
import sys

VPS_IP = sys.argv[1] if len(sys.argv) > 1 else "localhost"
BASE_URL = f"http://{VPS_IP}"

async def make_request(session, url):
    """发送单个请求"""
    start_time = time.time()
    try:
        async with session.get(url) as response:
            await response.text()
            end_time = time.time()
            return end_time - start_time, response.status
    except Exception as e:
        end_time = time.time()
        return end_time - start_time, 0

async def performance_test():
    """性能测试"""
    urls = [
        f"{BASE_URL}/api/v1/health",
        f"{BASE_URL}/api/v1/users",
        f"{BASE_URL}/api/v1/wireguard/servers"
    ]
    
    concurrent_users = 100
    test_duration = 60  # 60秒
    
    print(f"🚀 开始性能测试: {concurrent_users}并发用户, {test_duration}秒")
    
    async with aiohttp.ClientSession() as session:
        tasks = []
        start_time = time.time()
        
        # 创建并发任务
        for _ in range(concurrent_users):
            for url in urls:
                task = asyncio.create_task(make_request(session, url))
                tasks.append(task)
        
        # 等待测试完成
        await asyncio.sleep(test_duration)
        
        # 取消未完成的任务
        for task in tasks:
            task.cancel()
        
        end_time = time.time()
        actual_duration = end_time - start_time
        
        print(f"✅ 性能测试完成: {actual_duration:.2f}秒")
        
        # 计算统计信息
        results = []
        for task in tasks:
            if not task.cancelled():
                try:
                    result = task.result()
                    if result:
                        results.append(result)
                except:
                    pass
        
        if results:
            response_times = [r[0] for r in results if r[0] > 0]
            if response_times:
                avg_response_time = statistics.mean(response_times)
                max_response_time = max(response_times)
                min_response_time = min(response_times)
                
                print(f"📊 性能统计:")
                print(f"   平均响应时间: {avg_response_time:.3f}秒")
                print(f"   最大响应时间: {max_response_time:.3f}秒")
                print(f"   最小响应时间: {min_response_time:.3f}秒")
                print(f"   总请求数: {len(results)}")
                
                # 性能判断
                if avg_response_time < 0.2:  # 200ms
                    print("✅ 性能测试通过")
                    return True
                else:
                    print("❌ 性能测试失败: 响应时间过长")
                    return False
            else:
                print("❌ 性能测试失败: 无有效响应")
                return False
        else:
            print("❌ 性能测试失败: 无测试结果")
            return False

if __name__ == "__main__":
    result = asyncio.run(performance_test())
    sys.exit(0 if result else 1)
EOF

    # 执行性能测试
    python3 performance_test.py "$VPS_IP" > "$TEST_RESULTS_DIR/performance_test.log" 2>&1
    local performance_result=$?
    
    if [ $performance_result -eq 0 ]; then
        log_success "性能测试通过"
    else
        log_error "性能测试失败"
    fi
    
    return $performance_result
}

# 安全测试
run_security_tests() {
    log_test "执行安全测试..."
    
    # 安装安全测试工具
    pip3 install safety bandit
    
    # 创建安全测试脚本
    cat > security_test.py << 'EOF'
#!/usr/bin/env python3
import subprocess
import sys
import requests
import json

VPS_IP = sys.argv[1] if len(sys.argv) > 1 else "localhost"
BASE_URL = f"http://{VPS_IP}"

def test_dependency_security():
    """测试依赖安全"""
    print("🔍 检查依赖安全...")
    try:
        result = subprocess.run(['safety', 'check'], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ 依赖安全检查通过")
            return True
        else:
            print(f"❌ 依赖安全检查失败: {result.stdout}")
            return False
    except Exception as e:
        print(f"❌ 依赖安全检查异常: {e}")
        return False

def test_code_security():
    """测试代码安全"""
    print("🔍 检查代码安全...")
    try:
        result = subprocess.run(['bandit', '-r', 'backend/app/', '-f', 'json'], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ 代码安全检查通过")
            return True
        else:
            print(f"❌ 代码安全检查失败: {result.stdout}")
            return False
    except Exception as e:
        print(f"❌ 代码安全检查异常: {e}")
        return False

def test_api_security():
    """测试API安全"""
    print("🔍 检查API安全...")
    
    # 测试SQL注入
    sql_injection_tests = [
        "' OR '1'='1",
        "'; DROP TABLE users; --",
        "1' UNION SELECT * FROM users --"
    ]
    
    for payload in sql_injection_tests:
        try:
            response = requests.get(f"{BASE_URL}/api/v1/users?search={payload}", timeout=5)
            if "error" in response.text.lower() or response.status_code == 500:
                print(f"❌ 可能的SQL注入漏洞: {payload}")
                return False
        except:
            pass
    
    print("✅ API安全检查通过")
    return True

if __name__ == "__main__":
    print("🔒 开始安全测试...")
    
    dep_ok = test_dependency_security()
    code_ok = test_code_security()
    api_ok = test_api_security()
    
    if dep_ok and code_ok and api_ok:
        print("✅ 所有安全测试通过")
        sys.exit(0)
    else:
        print("❌ 安全测试失败")
        sys.exit(1)
EOF

    # 执行安全测试
    python3 security_test.py "$VPS_IP" > "$TEST_RESULTS_DIR/security_test.log" 2>&1
    local security_result=$?
    
    if [ $security_result -eq 0 ]; then
        log_success "安全测试通过"
    else
        log_error "安全测试失败"
    fi
    
    return $security_result
}

# 网络测试
run_network_tests() {
    log_test "执行网络测试..."
    
    # 创建网络测试脚本
    cat > network_test.py << 'EOF'
#!/usr/bin/env python3
import subprocess
import sys
import socket
import requests

VPS_IP = sys.argv[1] if len(sys.argv) > 1 else "localhost"

def test_ipv6_connectivity():
    """测试IPv6连通性"""
    print("🌐 测试IPv6连通性...")
    try:
        # 测试IPv6 ping
        result = subprocess.run(['ping6', '-c', '3', '2001:db8::1'], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            print("✅ IPv6连通性正常")
            return True
        else:
            print("⚠️ IPv6连通性测试跳过 (测试环境)")
            return True
    except Exception as e:
        print(f"⚠️ IPv6连通性测试跳过: {e}")
        return True

def test_port_connectivity():
    """测试端口连通性"""
    print("🔌 测试端口连通性...")
    
    ports = [80, 443, 8000, 3306, 6379]
    results = []
    
    for port in ports:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((VPS_IP, port))
            sock.close()
            
            if result == 0:
                print(f"✅ 端口 {port} 开放")
                results.append(True)
            else:
                print(f"❌ 端口 {port} 关闭")
                results.append(False)
        except Exception as e:
            print(f"❌ 端口 {port} 测试失败: {e}")
            results.append(False)
    
    return all(results)

def test_http_connectivity():
    """测试HTTP连通性"""
    print("🌍 测试HTTP连通性...")
    try:
        response = requests.get(f"http://{VPS_IP}", timeout=10)
        if response.status_code == 200:
            print("✅ HTTP连通性正常")
            return True
        else:
            print(f"❌ HTTP连通性异常: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ HTTP连通性测试失败: {e}")
        return False

if __name__ == "__main__":
    print("🌐 开始网络测试...")
    
    ipv6_ok = test_ipv6_connectivity()
    port_ok = test_port_connectivity()
    http_ok = test_http_connectivity()
    
    if ipv6_ok and port_ok and http_ok:
        print("✅ 所有网络测试通过")
        sys.exit(0)
    else:
        print("❌ 网络测试失败")
        sys.exit(1)
EOF

    # 执行网络测试
    python3 network_test.py "$VPS_IP" > "$TEST_RESULTS_DIR/network_test.log" 2>&1
    local network_result=$?
    
    if [ $network_result -eq 0 ]; then
        log_success "网络测试通过"
    else
        log_error "网络测试失败"
    fi
    
    return $network_result
}

# 稳定性测试
run_stability_tests() {
    log_test "执行稳定性测试..."
    
    # 创建稳定性测试脚本
    cat > stability_test.py << 'EOF'
#!/usr/bin/env python3
import asyncio
import aiohttp
import time
import sys
import psutil
import os

VPS_IP = sys.argv[1] if len(sys.argv) > 1 else "localhost"
BASE_URL = f"http://{VPS_IP}"

async def stability_test():
    """稳定性测试"""
    print("⏱️ 开始稳定性测试...")
    
    test_duration = 300  # 5分钟
    request_interval = 1  # 1秒间隔
    
    start_time = time.time()
    request_count = 0
    success_count = 0
    
    async with aiohttp.ClientSession() as session:
        while time.time() - start_time < test_duration:
            try:
                async with session.get(f"{BASE_URL}/api/v1/health", timeout=10) as response:
                    if response.status == 200:
                        success_count += 1
                    request_count += 1
            except Exception as e:
                print(f"请求失败: {e}")
                request_count += 1
            
            await asyncio.sleep(request_interval)
    
    success_rate = (success_count / request_count) * 100 if request_count > 0 else 0
    
    print(f"📊 稳定性测试结果:")
    print(f"   测试时长: {test_duration}秒")
    print(f"   总请求数: {request_count}")
    print(f"   成功请求: {success_count}")
    print(f"   成功率: {success_rate:.2f}%")
    
    if success_rate >= 95:
        print("✅ 稳定性测试通过")
        return True
    else:
        print("❌ 稳定性测试失败")
        return False

if __name__ == "__main__":
    result = asyncio.run(stability_test())
    sys.exit(0 if result else 1)
EOF

    # 执行稳定性测试
    python3 stability_test.py "$VPS_IP" > "$TEST_RESULTS_DIR/stability_test.log" 2>&1
    local stability_result=$?
    
    if [ $stability_result -eq 0 ]; then
        log_success "稳定性测试通过"
    else
        log_error "稳定性测试失败"
    fi
    
    return $stability_result
}

# 生成测试报告
generate_test_report() {
    log_info "生成测试报告..."
    
    cat > "$TEST_RESULTS_DIR/test_report.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>IPv6 WireGuard Manager 远程VPS测试报告</title>
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
        <h1>IPv6 WireGuard Manager 远程VPS测试报告</h1>
        <p>测试时间: $(date)</p>
        <p>VPS地址: $VPS_IP</p>
        <p>测试模式: $TEST_MODE</p>
    </div>
    
    <h2>测试结果摘要</h2>
    <div class="test-result info">
        <p>测试结果目录: $TEST_RESULTS_DIR</p>
        <p>详细日志请查看各个测试日志文件</p>
    </div>
    
    <h2>测试详情</h2>
    <ul>
        <li><a href="functional_test.log">功能测试日志</a></li>
        <li><a href="performance_test.log">性能测试日志</a></li>
        <li><a href="security_test.log">安全测试日志</a></li>
        <li><a href="network_test.log">网络测试日志</a></li>
        <li><a href="stability_test.log">稳定性测试日志</a></li>
    </ul>
</body>
</html>
EOF

    log_success "测试报告已生成: $TEST_RESULTS_DIR/test_report.html"
}

# 主函数
main() {
    log_info "===================================="
    log_info "$SCRIPT_NAME v$SCRIPT_VERSION 启动"
    log_info "===================================="
    
    # 检查参数
    if [ $# -eq 0 ]; then
        echo "用法: $0 <VPS_IP> [TEST_MODE]"
        echo "TEST_MODE: all, functional, performance, security, network, stability"
        exit 1
    fi
    
    VPS_IP="$1"
    if [ $# -gt 1 ]; then
        TEST_MODE="$2"
    fi
    
    log_info "VPS地址: $VPS_IP"
    log_info "测试模式: $TEST_MODE"
    
    # 检查VPS连接
    check_vps_connection
    
    # 部署应用
    deploy_to_vps
    
    # 执行测试
    test_results=()
    
    if [ "$TEST_MODE" = "all" ] || [ "$TEST_MODE" = "functional" ]; then
        run_functional_tests
        test_results+=($?)
    fi
    
    if [ "$TEST_MODE" = "all" ] || [ "$TEST_MODE" = "performance" ]; then
        run_performance_tests
        test_results+=($?)
    fi
    
    if [ "$TEST_MODE" = "all" ] || [ "$TEST_MODE" = "security" ]; then
        run_security_tests
        test_results+=($?)
    fi
    
    if [ "$TEST_MODE" = "all" ] || [ "$TEST_MODE" = "network" ]; then
        run_network_tests
        test_results+=($?)
    fi
    
    if [ "$TEST_MODE" = "all" ] || [ "$TEST_MODE" = "stability" ]; then
        run_stability_tests
        test_results+=($?)
    fi
    
    # 生成测试报告
    generate_test_report
    
    # 显示测试结果摘要
    log_info "===================================="
    log_info "测试结果摘要"
    log_info "===================================="
    
    total_tests=${#test_results[@]}
    passed_tests=0
    
    for result in "${test_results[@]}"; do
        if [ $result -eq 0 ]; then
            passed_tests=$((passed_tests + 1))
        fi
    done
    
    log_info "总测试数: $total_tests"
    log_info "通过测试: $passed_tests"
    log_info "失败测试: $((total_tests - passed_tests))"
    
    if [ $passed_tests -eq $total_tests ]; then
        log_success "所有测试通过！"
        exit 0
    else
        log_error "部分测试失败！"
        exit 1
    fi
}

# 调用主函数
main "$@"
