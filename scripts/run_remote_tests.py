#!/usr/bin/env python3
"""
IPv6 WireGuard Manager 远程VPS测试脚本
在远程VPS上执行全面的测试
"""

import os
import sys
import subprocess
import argparse
import time
import json
import requests
import asyncio
import aiohttp
from datetime import datetime
from pathlib import Path

class RemoteVPSTester:
    """远程VPS测试器"""
    
    def __init__(self, vps_ip, vps_user="root", vps_port=22, test_mode="all"):
        self.vps_ip = vps_ip
        self.vps_user = vps_user
        self.vps_port = vps_port
        self.test_mode = test_mode
        self.base_url = f"http://{vps_ip}"
        self.test_results_dir = f"test_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.results = {}
        
        # 创建测试结果目录
        Path(self.test_results_dir).mkdir(exist_ok=True)
    
    def log_info(self, message):
        """信息日志"""
        print(f"[INFO] {message}")
    
    def log_success(self, message):
        """成功日志"""
        print(f"[SUCCESS] {message}")
    
    def log_warning(self, message):
        """警告日志"""
        print(f"[WARNING] {message}")
    
    def log_error(self, message):
        """错误日志"""
        print(f"[ERROR] {message}")
    
    def log_test(self, message):
        """测试日志"""
        print(f"[TEST] {message}")
    
    def check_vps_connection(self):
        """检查VPS连接"""
        self.log_info("检查VPS连接...")
        
        try:
            # 使用ping检查连通性
            if os.name == 'nt':  # Windows
                result = subprocess.run(['ping', '-n', '3', self.vps_ip], 
                                      capture_output=True, text=True, timeout=10)
            else:  # Linux/Mac
                result = subprocess.run(['ping', '-c', '3', self.vps_ip], 
                                      capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                self.log_success(f"VPS连接正常: {self.vps_ip}")
                return True
            else:
                self.log_error(f"无法连接到VPS: {self.vps_ip}")
                return False
        except Exception as e:
            self.log_error(f"VPS连接检查失败: {e}")
            return False
    
    def deploy_to_vps(self):
        """部署应用到VPS"""
        self.log_info("部署应用到VPS...")
        
        # 创建部署脚本
        deploy_script = """#!/bin/bash
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
"""
        
        # 保存部署脚本
        with open("deploy_script.sh", "w") as f:
            f.write(deploy_script)
        
        self.log_success("部署脚本已创建")
        self.log_warning("请手动在VPS上执行部署脚本")
        return True
    
    def run_functional_tests(self):
        """执行功能测试"""
        self.log_test("执行功能测试...")
        
        try:
            # 测试健康检查
            response = requests.get(f"{self.base_url}/api/v1/health", timeout=10)
            if response.status_code == 200:
                self.log_success("健康检查通过")
                health_ok = True
            else:
                self.log_error(f"健康检查失败: {response.status_code}")
                health_ok = False
        except Exception as e:
            self.log_error(f"健康检查异常: {e}")
            health_ok = False
        
        # 测试API端点
        endpoints = [
            "/api/v1/health",
            "/api/v1/users",
            "/api/v1/wireguard/servers",
            "/api/v1/ipv6/pools",
            "/api/v1/bgp/sessions"
        ]
        
        api_results = []
        for endpoint in endpoints:
            try:
                response = requests.get(f"{self.base_url}{endpoint}", timeout=10)
                if response.status_code in [200, 401, 403]:  # 401/403也是正常的响应
                    self.log_success(f"{endpoint}: {response.status_code}")
                    api_results.append(True)
                else:
                    self.log_error(f"{endpoint}: {response.status_code}")
                    api_results.append(False)
            except Exception as e:
                self.log_error(f"{endpoint}: {e}")
                api_results.append(False)
        
        # 测试前端界面
        try:
            response = requests.get(f"{self.base_url}/", timeout=10)
            if response.status_code == 200:
                self.log_success("前端界面正常")
                frontend_ok = True
            else:
                self.log_error(f"前端界面异常: {response.status_code}")
                frontend_ok = False
        except Exception as e:
            self.log_error(f"前端界面测试失败: {e}")
            frontend_ok = False
        
        # 保存测试结果
        functional_result = health_ok and all(api_results) and frontend_ok
        self.results['functional'] = functional_result
        
        if functional_result:
            self.log_success("功能测试通过")
        else:
            self.log_error("功能测试失败")
        
        return functional_result
    
    async def run_performance_tests(self):
        """执行性能测试"""
        self.log_test("执行性能测试...")
        
        urls = [
            f"{self.base_url}/api/v1/health",
            f"{self.base_url}/api/v1/users",
            f"{self.base_url}/api/v1/wireguard/servers"
        ]
        
        concurrent_users = 50
        test_duration = 30  # 30秒
        
        self.log_info(f"性能测试: {concurrent_users}并发用户, {test_duration}秒")
        
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
            
            self.log_info(f"性能测试完成: {actual_duration:.2f}秒")
            
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
                    avg_response_time = sum(response_times) / len(response_times)
                    max_response_time = max(response_times)
                    min_response_time = min(response_times)
                    
                    self.log_info(f"性能统计:")
                    self.log_info(f"   平均响应时间: {avg_response_time:.3f}秒")
                    self.log_info(f"   最大响应时间: {max_response_time:.3f}秒")
                    self.log_info(f"   最小响应时间: {min_response_time:.3f}秒")
                    self.log_info(f"   总请求数: {len(results)}")
                    
                    # 性能判断
                    if avg_response_time < 0.5:  # 500ms
                        self.log_success("性能测试通过")
                        performance_result = True
                    else:
                        self.log_error("性能测试失败: 响应时间过长")
                        performance_result = False
                else:
                    self.log_error("性能测试失败: 无有效响应")
                    performance_result = False
            else:
                self.log_error("性能测试失败: 无测试结果")
                performance_result = False
        
        self.results['performance'] = performance_result
        return performance_result
    
    def run_security_tests(self):
        """执行安全测试"""
        self.log_test("执行安全测试...")
        
        # 测试API安全
        self.log_info("检查API安全...")
        
        # 测试SQL注入
        sql_injection_tests = [
            "' OR '1'='1",
            "'; DROP TABLE users; --",
            "1' UNION SELECT * FROM users --"
        ]
        
        security_issues = []
        for payload in sql_injection_tests:
            try:
                response = requests.get(f"{self.base_url}/api/v1/users?search={payload}", timeout=5)
                if "error" in response.text.lower() or response.status_code == 500:
                    security_issues.append(f"可能的SQL注入漏洞: {payload}")
            except:
                pass
        
        # 测试XSS
        xss_tests = [
            "<script>alert('xss')</script>",
            "javascript:alert('xss')",
            "<img src=x onerror=alert('xss')>"
        ]
        
        for payload in xss_tests:
            try:
                response = requests.get(f"{self.base_url}/api/v1/users?search={payload}", timeout=5)
                if payload in response.text:
                    security_issues.append(f"可能的XSS漏洞: {payload}")
            except:
                pass
        
        if security_issues:
            for issue in security_issues:
                self.log_error(issue)
            security_result = False
        else:
            self.log_success("安全测试通过")
            security_result = True
        
        self.results['security'] = security_result
        return security_result
    
    def run_network_tests(self):
        """执行网络测试"""
        self.log_test("执行网络测试...")
        
        # 测试端口连通性
        ports = [80, 443, 8000, 3306, 6379]
        port_results = []
        
        for port in ports:
            try:
                import socket
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(5)
                result = sock.connect_ex((self.vps_ip, port))
                sock.close()
                
                if result == 0:
                    self.log_success(f"端口 {port} 开放")
                    port_results.append(True)
                else:
                    self.log_warning(f"端口 {port} 关闭")
                    port_results.append(False)
            except Exception as e:
                self.log_error(f"端口 {port} 测试失败: {e}")
                port_results.append(False)
        
        # 测试HTTP连通性
        try:
            response = requests.get(f"http://{self.vps_ip}", timeout=10)
            if response.status_code == 200:
                self.log_success("HTTP连通性正常")
                http_ok = True
            else:
                self.log_error(f"HTTP连通性异常: {response.status_code}")
                http_ok = False
        except Exception as e:
            self.log_error(f"HTTP连通性测试失败: {e}")
            http_ok = False
        
        network_result = http_ok  # 主要关注HTTP连通性
        self.results['network'] = network_result
        
        if network_result:
            self.log_success("网络测试通过")
        else:
            self.log_error("网络测试失败")
        
        return network_result
    
    async def run_stability_tests(self):
        """执行稳定性测试"""
        self.log_test("执行稳定性测试...")
        
        test_duration = 60  # 1分钟
        request_interval = 2  # 2秒间隔
        
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
                    self.log_warning(f"请求失败: {e}")
                    request_count += 1
                
                await asyncio.sleep(request_interval)
        
        success_rate = (success_count / request_count) * 100 if request_count > 0 else 0
        
        self.log_info(f"稳定性测试结果:")
        self.log_info(f"   测试时长: {test_duration}秒")
        self.log_info(f"   总请求数: {request_count}")
        self.log_info(f"   成功请求: {success_count}")
        self.log_info(f"   成功率: {success_rate:.2f}%")
        
        if success_rate >= 90:
            self.log_success("稳定性测试通过")
            stability_result = True
        else:
            self.log_error("稳定性测试失败")
            stability_result = False
        
        self.results['stability'] = stability_result
        return stability_result
    
    def generate_test_report(self):
        """生成测试报告"""
        self.log_info("生成测试报告...")
        
        report_content = f"""
<!DOCTYPE html>
<html>
<head>
    <title>IPv6 WireGuard Manager 远程VPS测试报告</title>
    <meta charset="UTF-8">
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        .header {{ background-color: #f0f0f0; padding: 20px; border-radius: 5px; }}
        .test-result {{ margin: 10px 0; padding: 10px; border-radius: 5px; }}
        .success {{ background-color: #d4edda; color: #155724; }}
        .failure {{ background-color: #f8d7da; color: #721c24; }}
        .info {{ background-color: #d1ecf1; color: #0c5460; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>IPv6 WireGuard Manager 远程VPS测试报告</h1>
        <p>测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        <p>VPS地址: {self.vps_ip}</p>
        <p>测试模式: {self.test_mode}</p>
    </div>
    
    <h2>测试结果摘要</h2>
    <div class="test-result info">
        <p>测试结果目录: {self.test_results_dir}</p>
    </div>
    
    <h2>测试详情</h2>
    <ul>
"""
        
        for test_name, result in self.results.items():
            status = "通过" if result else "失败"
            color = "success" if result else "failure"
            report_content += f"""
        <li class="test-result {color}">
            {test_name}: {status}
        </li>
"""
        
        report_content += """
    </ul>
</body>
</html>
"""
        
        # 保存测试报告
        with open(f"{self.test_results_dir}/test_report.html", "w", encoding="utf-8") as f:
            f.write(report_content)
        
        self.log_success(f"测试报告已生成: {self.test_results_dir}/test_report.html")
    
    async def run_all_tests(self):
        """运行所有测试"""
        self.log_info("====================================")
        self.log_info("IPv6 WireGuard Manager 远程VPS测试")
        self.log_info("====================================")
        
        # 检查VPS连接
        if not self.check_vps_connection():
            return False
        
        # 部署应用
        self.deploy_to_vps()
        
        # 执行测试
        if self.test_mode in ["all", "functional"]:
            self.run_functional_tests()
        
        if self.test_mode in ["all", "performance"]:
            await self.run_performance_tests()
        
        if self.test_mode in ["all", "security"]:
            self.run_security_tests()
        
        if self.test_mode in ["all", "network"]:
            self.run_network_tests()
        
        if self.test_mode in ["all", "stability"]:
            await self.run_stability_tests()
        
        # 生成测试报告
        self.generate_test_report()
        
        # 显示测试结果摘要
        self.log_info("====================================")
        self.log_info("测试结果摘要")
        self.log_info("====================================")
        
        total_tests = len(self.results)
        passed_tests = sum(1 for result in self.results.values() if result)
        
        self.log_info(f"总测试数: {total_tests}")
        self.log_info(f"通过测试: {passed_tests}")
        self.log_info(f"失败测试: {total_tests - passed_tests}")
        
        if passed_tests == total_tests:
            self.log_success("所有测试通过！")
            return True
        else:
            self.log_error("部分测试失败！")
            return False

async def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="IPv6 WireGuard Manager 远程VPS测试")
    parser.add_argument("vps_ip", help="VPS IP地址")
    parser.add_argument("--user", default="root", help="VPS用户名")
    parser.add_argument("--port", type=int, default=22, help="VPS端口")
    parser.add_argument("--mode", default="all", 
                       choices=["all", "functional", "performance", "security", "network", "stability"],
                       help="测试模式")
    
    args = parser.parse_args()
    
    # 创建测试器
    tester = RemoteVPSTester(args.vps_ip, args.user, args.port, args.mode)
    
    # 运行测试
    success = await tester.run_all_tests()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    asyncio.run(main())
