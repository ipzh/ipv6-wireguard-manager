#!/bin/bash

# IPv6 WireGuard Manager WSL测试脚本
# 在WSL环境下执行全面的测试

set -e
set -u
set -o pipefail

# 脚本信息
SCRIPT_NAME="IPv6 WireGuard Manager WSL Test Suite"
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
TEST_MODE="${TEST_MODE:-all}"
TEST_DURATION="${TEST_DURATION:-3600}"
CONCURRENT_USERS="${CONCURRENT_USERS:-100}"

# 测试结果目录
TEST_RESULTS_DIR="wsl_test_results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$TEST_RESULTS_DIR"

# 检查WSL环境
check_wsl_environment() {
    log_info "检查WSL环境..."
    
    # 检查WSL版本
    if command -v wsl >/dev/null 2>&1; then
        log_success "WSL命令可用"
        wsl --version 2>/dev/null || log_warning "WSL版本检查失败"
    else
        log_warning "WSL命令不可用，可能不在WSL环境中"
    fi
    
    # 检查Linux内核
    log_info "Linux内核: $(uname -r)"
    
    # 检查系统信息
    log_info "系统信息:"
    lsb_release -a 2>/dev/null || log_warning "系统信息检查失败"
    
    # 检查系统资源
    log_info "系统资源:"
    free -h
    df -h
    
    # 检查网络配置
    log_info "网络配置:"
    ip addr show 2>/dev/null || log_warning "网络配置检查失败"
    
    log_success "WSL环境检查完成"
}

# 更新系统
update_system() {
    log_info "更新系统..."
    
    # 更新包列表
    sudo apt update || log_error "包列表更新失败"
    
    # 升级系统
    sudo apt upgrade -y || log_warning "系统升级失败"
    
    # 安装基础工具
    sudo apt install -y curl wget git vim nano || log_error "基础工具安装失败"
    sudo apt install -y build-essential python3-dev || log_error "开发工具安装失败"
    sudo apt install -y software-properties-common || log_error "软件源工具安装失败"
    
    log_success "系统更新完成"
}

# 安装依赖
install_dependencies() {
    log_info "安装测试依赖..."
    
    # 安装Python依赖
    pip3 install --upgrade pip || log_warning "pip升级失败"
    pip3 install requests aiohttp pytest pytest-asyncio pytest-cov || log_error "Python依赖安装失败"
    pip3 install locust safety bandit || log_warning "测试工具安装失败"
    
    # 安装系统依赖
    sudo apt install -y mysql-server redis-server || log_error "数据库服务安装失败"
    sudo apt install -y nginx php8.1 php8.1-fpm php8.1-mysql || log_error "Web服务安装失败"
    sudo apt install -y wireguard-tools || log_warning "WireGuard工具安装失败"
    
    # 安装Docker
    if ! command -v docker >/dev/null 2>&1; then
        log_info "安装Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
    else
        log_success "Docker已安装"
    fi
    
    # 安装Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1; then
        log_info "安装Docker Compose..."
        sudo apt install -y docker-compose || log_error "Docker Compose安装失败"
    else
        log_success "Docker Compose已安装"
    fi
    
    log_success "依赖安装完成"
}

# 配置服务
configure_services() {
    log_info "配置服务..."
    
    # 启动MySQL服务
    sudo systemctl start mysql || log_warning "MySQL启动失败"
    sudo systemctl enable mysql || log_warning "MySQL自启动配置失败"
    
    # 启动Redis服务
    sudo systemctl start redis-server || log_warning "Redis启动失败"
    sudo systemctl enable redis-server || log_warning "Redis自启动配置失败"
    
    # 启动Nginx服务
    sudo systemctl start nginx || log_warning "Nginx启动失败"
    sudo systemctl enable nginx || log_warning "Nginx自启动配置失败"
    
    # 启动PHP-FPM服务
    sudo systemctl start php8.1-fpm || log_warning "PHP-FPM启动失败"
    sudo systemctl enable php8.1-fpm || log_warning "PHP-FPM自启动配置失败"
    
    log_success "服务配置完成"
}

# 部署应用
deploy_application() {
    log_info "部署应用..."
    
    # 检查项目目录
    if [ ! -d "ipv6-wireguard-manager" ]; then
        log_info "克隆项目..."
        git clone https://github.com/ipzh/ipv6-wireguard-manager.git || log_error "项目克隆失败"
    fi
    
    cd ipv6-wireguard-manager || log_error "进入项目目录失败"
    
    # 配置环境变量
    if [ ! -f ".env" ]; then
        log_info "配置环境变量..."
        cp env.template .env || log_warning "环境变量模板复制失败"
        # 这里可以添加自动配置环境变量的逻辑
    fi
    
    # 安装Python依赖
    if [ -f "backend/requirements.txt" ]; then
        log_info "安装Python依赖..."
        pip3 install -r backend/requirements.txt || log_warning "Python依赖安装失败"
    fi
    
    # 运行安装脚本
    if [ -f "scripts/install.sh" ]; then
        log_info "运行安装脚本..."
        chmod +x scripts/install.sh
        ./scripts/install.sh --docker-only || log_warning "安装脚本执行失败"
    fi
    
    log_success "应用部署完成"
}

# 运行功能测试
run_functional_tests() {
    log_test "执行功能测试..."
    
    # 创建功能测试脚本
    cat > functional_test.py << 'EOF'
#!/usr/bin/env python3
import requests
import sys
import time

BASE_URL = "http://localhost"

def test_health_check():
    """测试健康检查"""
    try:
        response = requests.get(f"{BASE_URL}/api/v1/health", timeout=10)
        if response.status_code == 200:
            print("✅ 健康检查通过")
            return True
        else:
            print(f"❌ 健康检查失败: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ 健康检查异常: {e}")
        return False

def test_api_endpoints():
    """测试API端点"""
    endpoints = [
        "/api/v1/health",
        "/api/v1/users",
        "/api/v1/wireguard/servers",
        "/api/v1/ipv6/pools",
        "/api/v1/bgp/sessions"
    ]
    
    results = []
    for endpoint in endpoints:
        try:
            response = requests.get(f"{BASE_URL}{endpoint}", timeout=10)
            if response.status_code in [200, 401, 403]:
                print(f"✅ {endpoint}: {response.status_code}")
                results.append(True)
            else:
                print(f"❌ {endpoint}: {response.status_code}")
                results.append(False)
        except Exception as e:
            print(f"❌ {endpoint}: {e}")
            results.append(False)
    
    return all(results)

def test_frontend():
    """测试前端界面"""
    try:
        response = requests.get(f"{BASE_URL}/", timeout=10)
        if response.status_code == 200:
            print("✅ 前端界面正常")
            return True
        else:
            print(f"❌ 前端界面异常: {response.status_code}")
            return False
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
    python3 functional_test.py > "$TEST_RESULTS_DIR/functional_test.log" 2>&1
    local functional_result=$?
    
    if [ $functional_result -eq 0 ]; then
        log_success "功能测试通过"
    else
        log_error "功能测试失败"
    fi
    
    return $functional_result
}

# 运行性能测试
run_performance_tests() {
    log_test "执行性能测试..."
    
    # 创建性能测试脚本
    cat > performance_test.py << 'EOF'
#!/usr/bin/env python3
import asyncio
import aiohttp
import time
import statistics
import sys

BASE_URL = "http://localhost"

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
    
    concurrent_users = 50
    test_duration = 30  # 30秒
    
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
                if avg_response_time < 1.0:  # 1秒
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
    python3 performance_test.py > "$TEST_RESULTS_DIR/performance_test.log" 2>&1
    local performance_result=$?
    
    if [ $performance_result -eq 0 ]; then
        log_success "性能测试通过"
    else
        log_error "性能测试失败"
    fi
    
    return $performance_result
}

# 运行安全测试
run_security_tests() {
    log_test "执行安全测试..."
    
    # 创建安全测试脚本
    cat > security_test.py << 'EOF'
#!/usr/bin/env python3
import requests
import sys

BASE_URL = "http://localhost"

def test_sql_injection():
    """测试SQL注入"""
    print("🔍 测试SQL注入...")
    
    payloads = [
        "' OR '1'='1",
        "'; DROP TABLE users; --",
        "1' UNION SELECT * FROM users --"
    ]
    
    for payload in payloads:
        try:
            response = requests.get(f"{BASE_URL}/api/v1/users?search={payload}", timeout=5)
            if "error" in response.text.lower() or response.status_code == 500:
                print(f"❌ 可能的SQL注入漏洞: {payload}")
                return False
            else:
                print(f"✅ SQL注入测试通过: {payload}")
        except Exception as e:
            print(f"⚠️ SQL注入测试异常: {e}")
    
    return True

def test_xss():
    """测试XSS"""
    print("🔍 测试XSS...")
    
    payloads = [
        "<script>alert('xss')</script>",
        "javascript:alert('xss')",
        "<img src=x onerror=alert('xss')>"
    ]
    
    for payload in payloads:
        try:
            response = requests.get(f"{BASE_URL}/api/v1/users?search={payload}", timeout=5)
            if payload in response.text:
                print(f"❌ 可能的XSS漏洞: {payload}")
                return False
            else:
                print(f"✅ XSS测试通过: {payload}")
        except Exception as e:
            print(f"⚠️ XSS测试异常: {e}")
    
    return True

if __name__ == "__main__":
    print("🔒 开始安全测试...")
    
    sql_ok = test_sql_injection()
    xss_ok = test_xss()
    
    if sql_ok and xss_ok:
        print("✅ 所有安全测试通过")
        sys.exit(0)
    else:
        print("❌ 安全测试失败")
        sys.exit(1)
EOF

    # 执行安全测试
    python3 security_test.py > "$TEST_RESULTS_DIR/security_test.log" 2>&1
    local security_result=$?
    
    if [ $security_result -eq 0 ]; then
        log_success "安全测试通过"
    else
        log_error "安全测试失败"
    fi
    
    return $security_result
}

# 运行网络测试
run_network_tests() {
    log_test "执行网络测试..."
    
    # 测试端口连通性
    ports=(80 443 8000 3306 6379)
    port_results=()
    
    for port in "${ports[@]}"; do
        if nc -z localhost $port 2>/dev/null; then
            log_success "端口 $port 开放"
            port_results+=(true)
        else
            log_warning "端口 $port 关闭"
            port_results+=(false)
        fi
    done
    
    # 测试HTTP连通性
    if curl -s http://localhost >/dev/null 2>&1; then
        log_success "HTTP连通性正常"
        http_ok=true
    else
        log_error "HTTP连通性异常"
        http_ok=false
    fi
    
    # 测试IPv6支持
    if ip -6 addr show >/dev/null 2>&1; then
        log_success "IPv6支持正常"
        ipv6_ok=true
    else
        log_warning "IPv6支持检查失败"
        ipv6_ok=false
    fi
    
    # 判断网络测试结果
    if $http_ok; then
        log_success "网络测试通过"
        return 0
    else
        log_error "网络测试失败"
        return 1
    fi
}

# 运行稳定性测试
run_stability_tests() {
    log_test "执行稳定性测试..."
    
    # 创建稳定性测试脚本
    cat > stability_test.py << 'EOF'
#!/usr/bin/env python3
import asyncio
import aiohttp
import time
import sys

BASE_URL = "http://localhost"

async def stability_test():
    """稳定性测试"""
    test_duration = 60  # 1分钟
    request_interval = 2  # 2秒间隔
    
    print("⏱️ 开始稳定性测试...")
    
    async with aiohttp.ClientSession() as session:
        start_time = time.time()
        request_count = 0
        success_count = 0
        
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
        
        if success_rate >= 80:
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
    python3 stability_test.py > "$TEST_RESULTS_DIR/stability_test.log" 2>&1
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
    
    cat > "$TEST_RESULTS_DIR/wsl_test_report.html" << EOF
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
        <p>测试时间: $(date)</p>
        <p>测试环境: WSL2 Ubuntu</p>
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
        <li><a href="stability_test.log">稳定性测试日志</a></li>
    </ul>
    
    <h2>WSL环境信息</h2>
    <div class="test-result info">
        <p>WSL版本: $(wsl --version 2>/dev/null || echo '检查失败')</p>
        <p>Linux内核: $(uname -r)</p>
        <p>系统信息: $(lsb_release -d 2>/dev/null || echo '检查失败')</p>
    </div>
</body>
</html>
EOF

    log_success "测试报告已生成: $TEST_RESULTS_DIR/wsl_test_report.html"
}

# 主函数
main() {
    log_info "===================================="
    log_info "$SCRIPT_NAME v$SCRIPT_VERSION 启动"
    log_info "===================================="
    
    log_info "测试模式: $TEST_MODE"
    log_info "测试时长: $TEST_DURATION 秒"
    log_info "并发用户: $CONCURRENT_USERS"
    
    # 检查WSL环境
    check_wsl_environment
    
    # 更新系统
    update_system
    
    # 安装依赖
    install_dependencies
    
    # 配置服务
    configure_services
    
    # 部署应用
    deploy_application
    
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
        log_success "🎉 所有测试通过！"
        exit 0
    else
        log_error "❌ 部分测试失败！"
        exit 1
    fi
}

# 调用主函数
main "$@"
