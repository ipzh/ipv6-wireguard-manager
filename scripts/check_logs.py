#!/usr/bin/env python3
"""
IPv6 WireGuard Manager 日志检查工具
用于快速诊断安装和运行问题
"""

import os
import sys
import json
import subprocess
import platform
import psutil
import requests
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
import argparse

class LogChecker:
    """日志检查器"""
    
    def __init__(self):
        self.system = platform.system().lower()
        self.project_root = Path(__file__).parent.parent
        self.log_dir = self.project_root / "logs"
        
    def log_info(self, message: str):
        """信息日志"""
        print(f"\033[94m[INFO]\033[0m {message}")
        
    def log_success(self, message: str):
        """成功日志"""
        print(f"\033[92m[SUCCESS]\033[0m {message}")
        
    def log_warning(self, message: str):
        """警告日志"""
        print(f"\033[93m[WARNING]\033[0m {message}")
        
    def log_error(self, message: str):
        """错误日志"""
        print(f"\033[91m[ERROR]\033[0m {message}")
        
    def run_command(self, command: str, shell: bool = True) -> tuple:
        """运行命令并返回结果"""
        try:
            result = subprocess.run(
                command, 
                shell=shell, 
                capture_output=True, 
                text=True, 
                timeout=30
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return -1, "", "命令执行超时"
        except Exception as e:
            return -1, "", str(e)
    
    def check_services(self) -> Dict[str, Any]:
        """检查服务状态"""
        self.log_info("检查服务状态...")
        
        services = {}
        
        # 检查Python进程
        python_processes = [p for p in psutil.process_iter(['pid', 'name', 'cmdline']) 
                           if 'python' in p.info['name'].lower()]
        
        if python_processes:
            services['python'] = {
                'status': 'running',
                'count': len(python_processes),
                'processes': [{'pid': p.info['pid'], 'cmdline': ' '.join(p.info['cmdline'])} 
                             for p in python_processes]
            }
            self.log_success(f"✓ Python进程运行正常 ({len(python_processes)}个)")
        else:
            services['python'] = {'status': 'stopped'}
            self.log_error("✗ Python进程未运行")
        
        # 检查MySQL进程
        mysql_processes = [p for p in psutil.process_iter(['pid', 'name']) 
                          if 'mysql' in p.info['name'].lower()]
        
        if mysql_processes:
            services['mysql'] = {
                'status': 'running',
                'count': len(mysql_processes),
                'processes': [{'pid': p.info['pid'], 'name': p.info['name']} 
                             for p in mysql_processes]
            }
            self.log_success(f"✓ MySQL进程运行正常 ({len(mysql_processes)}个)")
        else:
            services['mysql'] = {'status': 'stopped'}
            self.log_error("✗ MySQL进程未运行")
        
        # 检查Nginx进程
        nginx_processes = [p for p in psutil.process_iter(['pid', 'name']) 
                          if 'nginx' in p.info['name'].lower()]
        
        if nginx_processes:
            services['nginx'] = {
                'status': 'running',
                'count': len(nginx_processes),
                'processes': [{'pid': p.info['pid'], 'name': p.info['name']} 
                             for p in nginx_processes]
            }
            self.log_success(f"✓ Nginx进程运行正常 ({len(nginx_processes)}个)")
        else:
            services['nginx'] = {'status': 'stopped'}
            self.log_error("✗ Nginx进程未运行")
        
        return services
    
    def check_app_logs(self) -> Dict[str, Any]:
        """检查应用日志"""
        self.log_info("检查应用日志文件...")
        
        logs_info = {
            'log_dir_exists': False,
            'log_files': [],
            'latest_log': None,
            'latest_content': []
        }
        
        if self.log_dir.exists():
            logs_info['log_dir_exists'] = True
            self.log_success(f"✓ 日志目录存在: {self.log_dir}")
            
            # 查找日志文件
            log_files = list(self.log_dir.rglob("*.log"))
            logs_info['log_files'] = [str(f) for f in log_files]
            
            if log_files:
                print(f"日志文件列表:")
                for log_file in log_files:
                    size = log_file.stat().st_size
                    mtime = datetime.fromtimestamp(log_file.stat().st_mtime)
                    print(f"  {log_file.name} ({size} bytes, {mtime.strftime('%Y-%m-%d %H:%M:%S')})")
                
                # 获取最新日志文件的内容
                latest_log = max(log_files, key=lambda f: f.stat().st_mtime)
                logs_info['latest_log'] = str(latest_log)
                
                try:
                    with open(latest_log, 'r', encoding='utf-8') as f:
                        lines = f.readlines()
                        logs_info['latest_content'] = lines[-20:] if len(lines) > 20 else lines
                    
                    print(f"\n=== 最新日志文件内容 (最后20行) ===")
                    for line in logs_info['latest_content']:
                        print(line.rstrip())
                        
                except Exception as e:
                    self.log_error(f"读取日志文件失败: {e}")
            else:
                self.log_warning("⚠️ 未找到日志文件")
        else:
            logs_info['log_dir_exists'] = False
            self.log_warning(f"⚠️ 日志目录不存在: {self.log_dir}")
        
        return logs_info
    
    def check_ports(self) -> Dict[str, Any]:
        """检查端口监听"""
        self.log_info("检查端口监听情况...")
        
        ports_info = {
            'listening_ports': [],
            'web_accessible': False,
            'api_accessible': False
        }
        
        # 检查端口监听
        listening_ports = []
        for conn in psutil.net_connections(kind='inet'):
            if conn.status == 'LISTEN':
                port = conn.laddr.port
                if port in [80, 443, 8000, 3306, 9000]:
                    listening_ports.append({
                        'port': port,
                        'address': conn.laddr.ip,
                        'pid': conn.pid
                    })
        
        ports_info['listening_ports'] = listening_ports
        
        print("=== 端口监听情况 ===")
        for port_info in listening_ports:
            print(f"  端口 {port_info['port']}: {port_info['address']} (PID: {port_info['pid']})")
        
        # 检查Web服务连接
        print(f"\n=== 本地连接测试 ===")
        try:
            response = requests.get('http://localhost/', timeout=5)
            if response.status_code == 200:
                ports_info['web_accessible'] = True
                self.log_success("✓ Web服务可访问")
            else:
                self.log_warning(f"⚠️ Web服务返回状态码: {response.status_code}")
        except Exception as e:
            self.log_error(f"✗ Web服务不可访问: {e}")
        
        # 检查API服务连接
        try:
            response = requests.get('http://localhost:8000/', timeout=5)
            if response.status_code == 200:
                ports_info['api_accessible'] = True
                self.log_success("✓ API服务可访问")
            else:
                self.log_warning(f"⚠️ API服务返回状态码: {response.status_code}")
        except Exception as e:
            self.log_error(f"✗ API服务不可访问: {e}")
        
        return ports_info
    
    def check_system_resources(self) -> Dict[str, Any]:
        """检查系统资源"""
        self.log_info("检查系统资源...")
        
        resources = {
            'memory': {},
            'disk': {},
            'cpu': {}
        }
        
        # 内存信息
        memory = psutil.virtual_memory()
        resources['memory'] = {
            'total': memory.total,
            'available': memory.available,
            'used': memory.used,
            'percent': memory.percent
        }
        
        print("=== 内存使用情况 ===")
        print(f"  总内存: {memory.total // (1024**3)} GB")
        print(f"  可用内存: {memory.available // (1024**3)} GB")
        print(f"  已用内存: {memory.used // (1024**3)} GB")
        print(f"  使用率: {memory.percent}%")
        
        # 磁盘信息
        disk = psutil.disk_usage('/')
        resources['disk'] = {
            'total': disk.total,
            'used': disk.used,
            'free': disk.free,
            'percent': (disk.used / disk.total) * 100
        }
        
        print(f"\n=== 磁盘使用情况 ===")
        print(f"  总容量: {disk.total // (1024**3)} GB")
        print(f"  已使用: {disk.used // (1024**3)} GB")
        print(f"  可用空间: {disk.free // (1024**3)} GB")
        print(f"  使用率: {(disk.used / disk.total) * 100:.1f}%")
        
        # CPU信息
        cpu_percent = psutil.cpu_percent(interval=1)
        cpu_count = psutil.cpu_count()
        resources['cpu'] = {
            'percent': cpu_percent,
            'count': cpu_count
        }
        
        print(f"\n=== CPU使用情况 ===")
        print(f"  CPU核心数: {cpu_count}")
        print(f"  CPU使用率: {cpu_percent}%")
        
        return resources
    
    def check_environment(self) -> Dict[str, Any]:
        """检查环境变量"""
        self.log_info("检查环境变量...")
        
        env_vars = {
            'DATABASE_URL': os.getenv('DATABASE_URL'),
            'SERVER_HOST': os.getenv('SERVER_HOST'),
            'SERVER_PORT': os.getenv('SERVER_PORT'),
            'API_PORT': os.getenv('API_PORT'),
            'WIREGUARD_CONFIG_DIR': os.getenv('WIREGUARD_CONFIG_DIR'),
            'LOG_LEVEL': os.getenv('LOG_LEVEL'),
            'LOG_FORMAT': os.getenv('LOG_FORMAT')
        }
        
        print("=== 相关环境变量 ===")
        for key, value in env_vars.items():
            if value:
                print(f"  {key}={value}")
            else:
                print(f"  {key}=未设置")
        
        return env_vars
    
    def check_config_files(self) -> Dict[str, Any]:
        """检查配置文件"""
        self.log_info("检查配置文件...")
        
        config_files = {
            '.env': self.project_root / '.env',
            'env.local': self.project_root / 'env.local',
            'config.json': self.project_root / 'config.json',
            'backend_config': self.project_root / 'backend' / 'app' / 'core' / 'unified_config.py'
        }
        
        config_status = {}
        
        for name, path in config_files.items():
            if path.exists():
                config_status[name] = {
                    'exists': True,
                    'path': str(path),
                    'size': path.stat().st_size,
                    'modified': datetime.fromtimestamp(path.stat().st_mtime)
                }
                self.log_success(f"✓ {name} 存在")
            else:
                config_status[name] = {'exists': False, 'path': str(path)}
                self.log_warning(f"⚠️ {name} 不存在")
        
        return config_status
    
    def generate_report(self, output_file: Optional[str] = None) -> str:
        """生成诊断报告"""
        self.log_info("生成诊断报告...")
        
        if not output_file:
            timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
            output_file = f"ipv6-wireguard-manager-diagnosis-{timestamp}.json"
        
        report = {
            'timestamp': datetime.now().isoformat(),
            'system': {
                'platform': platform.platform(),
                'python_version': sys.version,
                'architecture': platform.architecture()
            },
            'services': self.check_services(),
            'logs': self.check_app_logs(),
            'ports': self.check_ports(),
            'resources': self.check_system_resources(),
            'environment': self.check_environment(),
            'config_files': self.check_config_files()
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False, default=str)
        
        self.log_success(f"✓ 诊断报告已生成: {output_file}")
        return output_file
    
    def run_full_check(self):
        """运行完整检查"""
        print("🔍 IPv6 WireGuard Manager 日志检查工具")
        print("=" * 50)
        
        self.check_services()
        print()
        
        self.check_app_logs()
        print()
        
        self.check_ports()
        print()
        
        self.check_system_resources()
        print()
        
        self.check_environment()
        print()
        
        self.check_config_files()
        print()
        
        # 生成报告
        report_file = self.generate_report()
        print(f"\n📊 完整诊断报告已保存到: {report_file}")

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='IPv6 WireGuard Manager 日志检查工具')
    parser.add_argument('--services', action='store_true', help='检查服务状态')
    parser.add_argument('--logs', action='store_true', help='检查应用日志')
    parser.add_argument('--ports', action='store_true', help='检查端口监听')
    parser.add_argument('--resources', action='store_true', help='检查系统资源')
    parser.add_argument('--env', action='store_true', help='检查环境变量')
    parser.add_argument('--config', action='store_true', help='检查配置文件')
    parser.add_argument('--report', action='store_true', help='生成诊断报告')
    parser.add_argument('--all', action='store_true', help='运行完整检查')
    parser.add_argument('--output', type=str, help='报告输出文件')
    
    args = parser.parse_args()
    
    checker = LogChecker()
    
    if args.all or not any(vars(args).values()):
        checker.run_full_check()
    else:
        if args.services:
            checker.check_services()
        if args.logs:
            checker.check_app_logs()
        if args.ports:
            checker.check_ports()
        if args.resources:
            checker.check_system_resources()
        if args.env:
            checker.check_environment()
        if args.config:
            checker.check_config_files()
        if args.report:
            checker.generate_report(args.output)

if __name__ == '__main__':
    main()
