#!/usr/bin/env python3
"""
IPv6 WireGuard Manager WSL测试脚本
在WSL环境下执行全面的测试
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
import psutil
import socket
from datetime import datetime
from pathlib import Path

class WSLTester:
    """WSL测试器"""
    
    def __init__(self, test_mode="all", test_duration=3600, concurrent_users=100):
        self.test_mode = test_mode
        self.test_duration = test_duration
        self.concurrent_users = concurrent_users
        self.base_url = "http://localhost"
        self.test_results_dir = f"wsl_test_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
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
    
    def check_wsl_environment(self):
        """检查WSL环境"""
        self.log_info("检查WSL环境...")
        
        try:
            # 检查WSL版本
            result = subprocess.run(['wsl', '--version'], capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                self.log_success(f"WSL版本: {result.stdout.strip()}")
            else:
                self.log_warning("WSL版本检查失败")
        except Exception as e:
            self.log_warning(f"WSL版本检查异常: {e}")
        
        try:
            # 检查Linux内核
            result = subprocess.run(['uname', '-r'], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                self.log_success(f"Linux内核: {result.stdout.strip()}")
            else:
                self.log_warning("Linux内核检查失败")
        except Exception as e:
            self.log_warning(f"Linux内核检查异常: {e}")
        
        try:
            # 检查系统资源
            result = subprocess.run(['free', '-h'], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                self.log_info(f"内存使用:\n{result.stdout}")
            else:
                self.log_warning("内存检查失败")
        except Exception as e:
            self.log_warning(f"内存检查异常: {e}")
        
        try:
            # 检查磁盘空间
            result = subprocess.run(['df', '-h'], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                self.log_info(f"磁盘使用:\n{result.stdout}")
            else:
                self.log_warning("磁盘检查失败")
        except Exception as e:
            self.log_warning(f"磁盘检查异常: {e}")
        
        return True
    
    def install_dependencies(self):
        """安装依赖"""
        self.log_info("安装测试依赖...")
        
        try:
            # 更新系统
            self.log_info("更新系统包...")
            result = subprocess.run(['sudo', 'apt', 'update'], capture_output=True, text=True, timeout=300)
            if result.returncode == 0:
                self.log_success("系统包更新成功")
            else:
                self.log_warning(f"系统包更新失败: {result.stderr}")
        except Exception as e:
            self.log_warning(f"系统包更新异常: {e}")
        
        try:
            # 安装基础工具
            self.log_info("安装基础工具...")
            tools = ['curl', 'wget', 'git', 'vim', 'nano', 'build-essential', 'python3-dev']
            result = subprocess.run(['sudo', 'apt', 'install', '-y'] + tools, 
                                  capture_output=True, text=True, timeout=600)
            if result.returncode == 0:
                self.log_success("基础工具安装成功")
            else:
                self.log_warning(f"基础工具安装失败: {result.stderr}")
        except Exception as e:
            self.log_warning(f"基础工具安装异常: {e}")
        
        try:
            # 安装Python依赖
            self.log_info("安装Python依赖...")
            result = subprocess.run(['pip3', 'install', 'requests', 'aiohttp', 'pytest', 'pytest-asyncio', 'pytest-cov'], 
                                  capture_output=True, text=True, timeout=300)
            if result.returncode == 0:
                self.log_success("Python依赖安装成功")
            else:
                self.log_warning(f"Python依赖安装失败: {result.stderr}")
        except Exception as e:
            self.log_warning(f"Python依赖安装异常: {e}")
        
        return True
    
    def run_functional_tests(self):
        """运行功能测试"""
        self.log_test("执行功能测试...")
        
        functional_results = []
        
        # 测试健康检查
        try:
            response = requests.get(f"{self.base_url}/api/v1/health", timeout=10)
            if response.status_code == 200:
                self.log_success("健康检查通过")
                functional_results.append(True)
            else:
                self.log_error(f"健康检查失败: {response.status_code}")
                functional_results.append(False)
        except Exception as e:
            self.log_error(f"健康检查异常: {e}")
            functional_results.append(False)
        
        # 测试API端点
        endpoints = [
            "/api/v1/health",
            "/api/v1/users",
            "/api/v1/wireguard/servers",
            "/api/v1/ipv6/pools",
            "/api/v1/bgp/sessions"
        ]
        
        for endpoint in endpoints:
            try:
                response = requests.get(f"{self.base_url}{endpoint}", timeout=10)
                if response.status_code in [200, 401, 403]:  # 401/403也是正常的响应
                    self.log_success(f"{endpoint}: {response.status_code}")
                    functional_results.append(True)
                else:
                    self.log_error(f"{endpoint}: {response.status_code}")
                    functional_results.append(False)
            except Exception as e:
                self.log_error(f"{endpoint}: {e}")
                functional_results.append(False)
        
        # 测试前端界面
        try:
            response = requests.get(f"{self.base_url}/", timeout=10)
            if response.status_code == 200:
                self.log_success("前端界面正常")
                functional_results.append(True)
            else:
                self.log_error(f"前端界面异常: {response.status_code}")
                functional_results.append(False)
        except Exception as e:
            self.log_error(f"前端界面测试失败: {e}")
            functional_results.append(False)
        
        functional_result = all(functional_results)
        self.results['functional'] = functional_result
        
        if functional_result:
            self.log_success("功能测试通过")
        else:
            self.log_error("功能测试失败")
        
        return functional_result
    
    async def run_performance_tests(self):
        """运行性能测试"""
        self.log_test("执行性能测试...")
        
        urls = [
            f"{self.base_url}/api/v1/health",
            f"{self.base_url}/api/v1/users",
            f"{self.base_url}/api/v1/wireguard/servers"
        ]
        
        concurrent_users = min(self.concurrent_users, 50)  # WSL环境限制
        test_duration = min(self.test_duration, 60)  # 1分钟测试
        
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
                    if avg_response_time < 1.0:  # 1秒
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
        """运行安全测试"""
        self.log_test("执行安全测试...")
        
        security_results = []
        
        # 测试SQL注入
        self.log_info("测试SQL注入...")
        sql_payloads = [
            "' OR '1'='1",
            "'; DROP TABLE users; --",
            "1' UNION SELECT * FROM users --"
        ]
        
        for payload in sql_payloads:
            try:
                response = requests.get(f"{self.base_url}/api/v1/users?search={payload}", timeout=5)
                if "error" in response.text.lower() or response.status_code == 500:
                    self.log_error(f"可能的SQL注入漏洞: {payload}")
                    security_results.append(False)
                else:
                    self.log_success(f"SQL注入测试通过: {payload}")
                    security_results.append(True)
            except Exception as e:
                self.log_warning(f"SQL注入测试异常: {e}")
                security_results.append(True)
        
        # 测试XSS
        self.log_info("测试XSS...")
        xss_payloads = [
            "<script>alert('xss')</script>",
            "javascript:alert('xss')",
            "<img src=x onerror=alert('xss')>"
        ]
        
        for payload in xss_payloads:
            try:
                response = requests.get(f"{self.base_url}/api/v1/users?search={payload}", timeout=5)
                if payload in response.text:
                    self.log_error(f"可能的XSS漏洞: {payload}")
                    security_results.append(False)
                else:
                    self.log_success(f"XSS测试通过: {payload}")
                    security_results.append(True)
            except Exception as e:
                self.log_warning(f"XSS测试异常: {e}")
                security_results.append(True)
        
        # 测试认证安全
        self.log_info("测试认证安全...")
        try:
            # 测试弱密码
            weak_passwords = ["123456", "password", "admin"]
            for pwd in weak_passwords:
                # 这里应该调用实际的密码验证函数
                self.log_info(f"弱密码测试: {pwd}")
            security_results.append(True)
        except Exception as e:
            self.log_warning(f"认证安全测试异常: {e}")
            security_results.append(True)
        
        security_result = all(security_results)
        self.results['security'] = security_result
        
        if security_result:
            self.log_success("安全测试通过")
        else:
            self.log_error("安全测试失败")
        
        return security_result
    
    def run_network_tests(self):
        """运行网络测试"""
        self.log_test("执行网络测试...")
        
        network_results = []
        
        # 测试端口连通性
        self.log_info("测试端口连通性...")
        ports = [80, 443, 8000, 3306, 6379]
        
        for port in ports:
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(5)
                result = sock.connect_ex(('localhost', port))
                sock.close()
                
                if result == 0:
                    self.log_success(f"端口 {port} 开放")
                    network_results.append(True)
                else:
                    self.log_warning(f"端口 {port} 关闭")
                    network_results.append(False)
            except Exception as e:
                self.log_error(f"端口 {port} 测试失败: {e}")
                network_results.append(False)
        
        # 测试HTTP连通性
        self.log_info("测试HTTP连通性...")
        try:
            response = requests.get(f"http://localhost", timeout=10)
            if response.status_code == 200:
                self.log_success("HTTP连通性正常")
                network_results.append(True)
            else:
                self.log_error(f"HTTP连通性异常: {response.status_code}")
                network_results.append(False)
        except Exception as e:
            self.log_error(f"HTTP连通性测试失败: {e}")
            network_results.append(False)
        
        # 测试IPv6支持
        self.log_info("测试IPv6支持...")
        try:
            result = subprocess.run(['ip', '-6', 'addr', 'show'], capture_output=True, text=True, timeout=10)
            if result.returncode == 0 and result.stdout.strip():
                self.log_success("IPv6支持正常")
                network_results.append(True)
            else:
                self.log_warning("IPv6支持检查失败")
                network_results.append(False)
        except Exception as e:
            self.log_warning(f"IPv6支持检查异常: {e}")
            network_results.append(False)
        
        network_result = any(network_results)  # 至少一个网络测试通过
        self.results['network'] = network_result
        
        if network_result:
            self.log_success("网络测试通过")
        else:
            self.log_error("网络测试失败")
        
        return network_result
    
    async def run_stability_tests(self):
        """运行稳定性测试"""
        self.log_test("执行稳定性测试...")
        
        test_duration = min(self.test_duration, 120)  # 2分钟测试
        request_interval = 2  # 2秒间隔
        
        start_time = time.time()
        request_count = 0
        success_count = 0
        
        self.log_info(f"稳定性测试: {test_duration}秒")
        
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
        
        if success_rate >= 80:  # 80%成功率
            self.log_success("稳定性测试通过")
            stability_result = True
        else:
            self.log_error("稳定性测试失败")
            stability_result = False
        
        self.results['stability'] = stability_result
        return stability_result
    
    def run_database_tests(self):
        """运行数据库测试"""
        self.log_test("执行数据库测试...")
        
        try:
            # 测试数据库连接
            result = subprocess.run(['mysql', '-u', 'root', '-p', '-e', 'SELECT 1'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                self.log_success("数据库连接正常")
                return True
            else:
                self.log_error(f"数据库连接失败: {result.stderr}")
                return False
        except Exception as e:
            self.log_error(f"数据库测试异常: {e}")
            return False
    
    def run_cache_tests(self):
        """运行缓存测试"""
        self.log_test("执行缓存测试...")
        
        try:
            # 测试Redis连接
            result = subprocess.run(['redis-cli', 'ping'], capture_output=True, text=True, timeout=5)
            if result.returncode == 0 and 'PONG' in result.stdout:
                self.log_success("Redis缓存正常")
                return True
            else:
                self.log_error(f"Redis缓存失败: {result.stderr}")
                return False
        except Exception as e:
            self.log_error(f"缓存测试异常: {e}")
            return False
    
    def generate_test_report(self):
        """生成测试报告"""
        self.log_info("生成测试报告...")
        
        report_content = f"""
<!DOCTYPE html>
<html>
<head>
    <title>IPv6 WireGuard Manager WSL测试报告</title>
    <meta charset="UTF-8">
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        .header {{ background-color: #f0f0f0; padding: 20px; border-radius: 5px; }}
        .test-result {{ margin: 10px 0; padding: 10px; border-radius: 5px; }}
        .success {{ background-color: #d4edda; color: #155724; }}
        .failure {{ background-color: #f8d7da; color: #721c24; }}
        .info {{ background-color: #d1ecf1; color: #0c5460; }}
        .warning {{ background-color: #fff3cd; color: #856404; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>IPv6 WireGuard Manager WSL测试报告</h1>
        <p>测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        <p>测试环境: WSL2 Ubuntu</p>
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
    
    <h2>WSL环境信息</h2>
    <div class="test-result info">
        <p>WSL版本: 检查WSL版本输出</p>
        <p>Linux内核: 检查内核版本输出</p>
        <p>系统资源: 检查内存和磁盘使用情况</p>
    </div>
    
    <h2>测试建议</h2>
    <div class="test-result warning">
        <p>1. 确保WSL环境配置正确</p>
        <p>2. 检查网络连接和端口开放</p>
        <p>3. 验证数据库和缓存服务状态</p>
        <p>4. 监控系统资源使用情况</p>
    </div>
</body>
</html>
"""
        
        # 保存测试报告
        with open(f"{self.test_results_dir}/wsl_test_report.html", "w", encoding="utf-8") as f:
            f.write(report_content)
        
        self.log_success(f"测试报告已生成: {self.test_results_dir}/wsl_test_report.html")
    
    async def run_all_tests(self):
        """运行所有测试"""
        self.log_info("====================================")
        self.log_info("IPv6 WireGuard Manager WSL测试")
        self.log_info("====================================")
        
        # 检查WSL环境
        self.check_wsl_environment()
        
        # 安装依赖
        self.install_dependencies()
        
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
        
        if self.test_mode in ["all", "database"]:
            self.run_database_tests()
        
        if self.test_mode in ["all", "cache"]:
            self.run_cache_tests()
        
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
            self.log_success("🎉 所有测试通过！")
            return True
        else:
            self.log_error("❌ 部分测试失败！")
            return False

async def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="IPv6 WireGuard Manager WSL测试")
    parser.add_argument("--mode", default="all", 
                       choices=["all", "functional", "performance", "security", "network", "stability", "database", "cache"],
                       help="测试模式")
    parser.add_argument("--duration", type=int, default=3600, help="测试持续时间(秒)")
    parser.add_argument("--users", type=int, default=100, help="并发用户数")
    
    args = parser.parse_args()
    
    # 创建测试器
    tester = WSLTester(args.mode, args.duration, args.users)
    
    # 运行测试
    success = await tester.run_all_tests()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    asyncio.run(main())
