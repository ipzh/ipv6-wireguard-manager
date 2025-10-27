#!/usr/bin/env python3
"""
IPv6 WireGuard Manager 一键检查工具
一键检查所有问题并生成综合诊断报告
"""

import os
import sys
import json
import subprocess
import platform
import shutil
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
import argparse
from urllib import error as urllib_error, request as urllib_request

try:  # 可选依赖
    import psutil  # type: ignore[import-not-found]
except ImportError:  # pragma: no cover - 在未安装psutil时使用降级模式
    psutil = None  # type: ignore[assignment]

try:  # 可选依赖
    import requests  # type: ignore[import-not-found]
except ImportError:  # pragma: no cover - 在未安装requests时使用降级模式
    requests = None  # type: ignore[assignment]


class OneClickChecker:
    """一键检查器"""
    
    def __init__(self):
        self.system = platform.system().lower()
        self.project_root = Path(__file__).parent.parent
        self.log_dir = self.project_root / "logs"
        self.issues: List[str] = []
        self.warnings: List[str] = []
        self.successes: List[str] = []
        self.psutil_available = psutil is not None
        self.requests_available = requests is not None
        self._psutil_warning_emitted = False
        self._requests_warning_emitted = False
        
    def log_info(self, message: str):
        """信息日志"""
        print(f"\033[94m[INFO]\033[0m {message}")
        
    def log_success(self, message: str):
        """成功日志"""
        print(f"\033[92m[SUCCESS]\033[0m {message}")
        self.successes.append(message)
        
    def log_warning(self, message: str):
        """警告日志"""
        print(f"\033[93m[WARNING]\033[0m {message}")
        self.warnings.append(message)
        
    def log_error(self, message: str):
        """错误日志"""
        print(f"\033[91m[ERROR]\033[0m {message}")
        self.issues.append(message)
        
    def run_command(self, command: str, shell: bool = True) -> Tuple[int, str, str]:
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
    
    def _warn_psutil_missing(self) -> None:
        """在缺少psutil时输出提示信息（仅提示一次）"""
        if not self._psutil_warning_emitted:
            self.log_warning("psutil 未安装，相关检查将使用降级模式。建议执行: pip install psutil")
            self._psutil_warning_emitted = True
    
    def _warn_requests_missing(self) -> None:
        """在缺少requests时输出提示信息（仅提示一次）"""
        if not self._requests_warning_emitted:
            self.log_warning("requests 未安装，HTTP 检查将使用 urllib 降级模式。建议执行: pip install requests")
            self._requests_warning_emitted = True
    
    def http_get(self, url: str, timeout: int = 5) -> Tuple[Optional[int], str, Optional[str]]:
        """执行 HTTP GET 请求，兼容 requests 缺失时的降级模式"""
        if self.requests_available and requests is not None:
            try:
                response = requests.get(url, timeout=timeout)
                return response.status_code, response.text, None
            except Exception as exc:  # pragma: no cover - 捕获网络异常
                return None, "", str(exc)
        else:
            self._warn_requests_missing()
            try:
                with urllib_request.urlopen(url, timeout=timeout) as response:
                    body = response.read().decode('utf-8', errors='ignore')
                    return response.getcode(), body, None
            except urllib_error.URLError as exc:  # pragma: no cover - 网络异常
                return None, "", str(exc)
            except Exception as exc:  # pragma: no cover - 其他异常
                return None, "", str(exc)
    
    def _check_process_with_pgrep(self, pattern: str, display_name: str) -> Dict[str, Any]:
        """使用 pgrep 命令检查进程状态"""
        command = f"pgrep -fl {pattern}"
        code, stdout, stderr = self.run_command(command)
        if code == 0 and stdout.strip():
            lines = [line.strip() for line in stdout.strip().splitlines() if line.strip()]
            processes = []
            for line in lines:
                parts = line.split(None, 1)
                pid = int(parts[0]) if parts and parts[0].isdigit() else None
                cmdline = parts[1] if len(parts) > 1 else ''
                processes.append({'pid': pid, 'cmdline': cmdline})
            self.log_success(f"✓ {display_name}进程运行正常 ({len(processes)}个)")
            return {
                'status': 'running',
                'count': len(processes),
                'processes': processes
            }
        if stderr:
            self.log_warning(f"⚠️ 无法通过 pgrep 检查 {display_name} 进程: {stderr.strip()}")
        else:
            self.log_error(f"✗ {display_name}进程未运行")
        return {
            'status': 'unknown' if code == 127 else 'stopped',
            'reason': stderr.strip() if stderr else 'process not found'
        }
    
    def _collect_listening_ports(self, expected_ports: List[int]) -> List[Dict[str, Any]]:
        """收集监听端口信息，优先使用 psutil，必要时回退到系统命令"""
        if self.psutil_available and psutil is not None:
            listening_ports = []
            for conn in psutil.net_connections(kind='inet'):
                if conn.status == 'LISTEN' and conn.laddr:
                    port = conn.laddr.port
                    if port in expected_ports:
                        listening_ports.append({
                            'port': port,
                            'address': conn.laddr.ip,
                            'pid': conn.pid
                        })
            return listening_ports
        self._warn_psutil_missing()
        return self._collect_listening_ports_from_command(expected_ports)
    
    def _collect_listening_ports_from_command(self, expected_ports: List[int]) -> List[Dict[str, Any]]:
        """使用 netstat 或 ss 命令搜集监听端口"""
        commands = [
            ("netstat -tuln", "netstat"),
            ("ss -tuln", "ss"),
        ]
        for command, label in commands:
            code, stdout, stderr = self.run_command(command)
            if code != 0 or not stdout.strip():
                continue
            listening_ports: List[Dict[str, Any]] = []
            for line in stdout.splitlines():
                line = line.strip()
                if not line or line.startswith('Proto'):
                    continue
                parts = line.split()
                if len(parts) < 4:
                    continue
                local_address = parts[3]
                address = local_address
                port = None
                if '[' in local_address and ']' in local_address:
                    # 处理 [::]:80 类格式
                    addr_part, _, rest = local_address.partition(']')
                    address = addr_part.strip('[]')
                    port_str = rest.lstrip(':')
                elif ':' in local_address:
                    address, port_str = local_address.rsplit(':', 1)
                else:
                    continue
                try:
                    port = int(port_str)
                except (TypeError, ValueError):
                    continue
                if port not in expected_ports:
                    continue
                pid = None
                if parts[-1] and '/' in parts[-1]:
                    pid_token = parts[-1].split('/', 1)[0]
                    if pid_token.isdigit():
                        pid = int(pid_token)
                listening_ports.append({
                    'port': port,
                    'address': address or '*',
                    'pid': pid
                })
            if listening_ports:
                self.log_info(f"使用 {label} 收集到 {len(listening_ports)} 个监听端口")
                return listening_ports
        self.log_warning("⚠️ 未能通过系统命令获取监听端口信息")
        return []
    
    def _read_memory_info_without_psutil(self) -> Optional[Dict[str, float]]:
        """在缺少 psutil 时读取内存信息"""
        meminfo_path = Path('/proc/meminfo')
        if not meminfo_path.exists():
            return None
        data: Dict[str, int] = {}
        try:
            with meminfo_path.open() as fh:
                for line in fh:
                    if ':' not in line:
                        continue
                    key, value = line.split(':', 1)
                    parts = value.strip().split()
                    if not parts:
                        continue
                    # /proc/meminfo 以 kB 为单位
                    data[key.strip()] = int(parts[0]) * 1024
        except Exception as exc:  # pragma: no cover - 文件读取异常
            self.log_warning(f"无法读取 /proc/meminfo: {exc}")
            return None
        total = data.get('MemTotal')
        available = data.get('MemAvailable', data.get('MemFree'))
        if total is None or available is None:
            return None
        used = total - available
        percent = round((used / total) * 100, 1) if total else 0.0
        return {
            'total': float(total),
            'available': float(available),
            'used': float(used),
            'percent': percent
        }
    
    def _read_cpu_usage_without_psutil(self, interval: float = 1.0) -> Optional[float]:
        """使用 /proc/stat 估算 CPU 使用率"""
        stat_path = Path('/proc/stat')
        if not stat_path.exists():
            return None
        def read_cpu_times() -> Optional[Tuple[int, int]]:
            try:
                with stat_path.open() as fh:
                    first_line = fh.readline()
                parts = first_line.split()
                if len(parts) < 5:
                    return None
                values = [int(value) for value in parts[1:]]
                idle = values[3]
                total = sum(values)
                return total, idle
            except Exception:  # pragma: no cover - 文件读取异常
                return None
        first = read_cpu_times()
        if not first:
            return None
        time.sleep(interval)
        second = read_cpu_times()
        if not second:
            return None
        total_diff = second[0] - first[0]
        idle_diff = second[1] - first[1]
        if total_diff <= 0:
            return None
        usage = (1 - idle_diff / total_diff) * 100
        return round(usage, 1)
    
    def check_python_environment(self) -> Dict[str, Any]:
        """检查Python环境"""
        self.log_info("检查Python环境...")
        
        python_info = {
            'version': sys.version,
            'executable': sys.executable,
            'path': sys.path[:5],  # 只显示前5个路径
            'packages': {}
        }
        
        # 检查关键包
        required_packages = [
            'fastapi', 'uvicorn', 'sqlalchemy', 'pymysql', 'aiomysql',
            'pydantic', 'python-multipart', 'python-jose', 'passlib',
            'bcrypt', 'psutil', 'requests'
        ]
        
        for package in required_packages:
            try:
                __import__(package.replace('-', '_'))
                python_info['packages'][package] = 'installed'
                self.log_success(f"✓ {package} 已安装")
            except ImportError:
                python_info['packages'][package] = 'missing'
                self.log_error(f"✗ {package} 未安装")
        
        return python_info
    
    def check_services(self) -> Dict[str, Any]:
        """检查服务状态"""
        self.log_info("检查服务状态...")
        
        services: Dict[str, Any] = {}
        
        if self.psutil_available and psutil is not None:
            python_processes = [
                p for p in psutil.process_iter(['pid', 'name', 'cmdline'])
                if p.info.get('name') and 'python' in p.info['name'].lower()
            ]
            if python_processes:
                services['python'] = {
                    'status': 'running',
                    'count': len(python_processes),
                    'processes': [
                        {
                            'pid': p.info['pid'],
                            'cmdline': ' '.join(p.info.get('cmdline') or []) if p.info.get('cmdline') else p.info.get('name', '')
                        }
                        for p in python_processes
                    ]
                }
                self.log_success(f"✓ Python进程运行正常 ({len(python_processes)}个)")
            else:
                services['python'] = {'status': 'stopped'}
                self.log_error("✗ Python进程未运行")
            
            mysql_processes = [
                p for p in psutil.process_iter(['pid', 'name'])
                if p.info.get('name') and 'mysql' in p.info['name'].lower()
            ]
            if mysql_processes:
                services['mysql'] = {
                    'status': 'running',
                    'count': len(mysql_processes),
                    'processes': [
                        {'pid': p.info['pid'], 'name': p.info.get('name')}
                        for p in mysql_processes
                    ]
                }
                self.log_success(f"✓ MySQL进程运行正常 ({len(mysql_processes)}个)")
            else:
                services['mysql'] = {'status': 'stopped'}
                self.log_error("✗ MySQL进程未运行")
            
            nginx_processes = [
                p for p in psutil.process_iter(['pid', 'name'])
                if p.info.get('name') and 'nginx' in p.info['name'].lower()
            ]
            if nginx_processes:
                services['nginx'] = {
                    'status': 'running',
                    'count': len(nginx_processes),
                    'processes': [
                        {'pid': p.info['pid'], 'name': p.info.get('name')}
                        for p in nginx_processes
                    ]
                }
                self.log_success(f"✓ Nginx进程运行正常 ({len(nginx_processes)}个)")
            else:
                services['nginx'] = {'status': 'stopped'}
                self.log_error("✗ Nginx进程未运行")
            
            return services
        
        self._warn_psutil_missing()
        services['python'] = self._check_process_with_pgrep('python', 'Python')
        services['mysql'] = self._check_process_with_pgrep('mysql', 'MySQL')
        services['nginx'] = self._check_process_with_pgrep('nginx', 'Nginx')
        return services
    
    def check_database_connection(self) -> Dict[str, Any]:
        """检查数据库连接"""
        self.log_info("检查数据库连接...")
        
        db_info = {
            'connection': False,
            'url': os.getenv('DATABASE_URL'),
            'error': None
        }
        
        if not db_info['url']:
            self.log_error("✗ DATABASE_URL 环境变量未设置")
            return db_info
        
        # 尝试连接数据库
        try:
            import pymysql  # type: ignore[import-not-found]
        except ImportError:
            db_info['error'] = "PyMySQL 未安装"
            self.log_error("✗ 未安装PyMySQL，无法执行数据库连接检查。请运行: pip install PyMySQL")
            return db_info
        
        import re
        
        try:
            pattern = r'mysql://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)'
            match = re.match(pattern, db_info['url'])
            
            if match:
                user, password, host, port, database = match.groups()
                connection = pymysql.connect(
                    host=host,
                    port=int(port),
                    user=user,
                    password=password,
                    database=database,
                    connect_timeout=10
                )
                try:
                    with connection.cursor() as cursor:
                        cursor.execute("SELECT 1")
                        result = cursor.fetchone()
                finally:
                    connection.close()
                
                if result:
                    db_info['connection'] = True
                    self.log_success("✓ 数据库连接正常")
                else:
                    db_info['error'] = "数据库查询失败"
                    self.log_error("✗ 数据库查询失败")
            else:
                db_info['error'] = "数据库URL格式错误"
                self.log_error("✗ 数据库URL格式错误")
        except Exception as e:
            db_info['error'] = str(e)
            self.log_error(f"✗ 数据库连接失败: {e}")
        
        return db_info
    
    def check_ports(self) -> Dict[str, Any]:
        """检查端口监听"""
        self.log_info("检查端口监听情况...")
        
        ports_info = {
            'listening_ports': [],
            'web_accessible': False,
            'api_accessible': False,
            'expected_ports': [80, 443, 8000, 3306, 9000]
        }
        
        listening_ports = self._collect_listening_ports(ports_info['expected_ports'])
        ports_info['listening_ports'] = listening_ports
        
        print("=== 端口监听情况 ===")
        if listening_ports:
            for port_info in listening_ports:
                pid_display = port_info['pid'] if port_info.get('pid') is not None else '未知'
                print(f"  端口 {port_info['port']}: {port_info['address']} (PID: {pid_display})")
        else:
            print("  未检测到预期端口的监听")
        
        print("\n=== 本地连接测试 ===")
        status_code, _, error = self.http_get('http://localhost/', timeout=5)
        if status_code is not None:
            if status_code == 200:
                ports_info['web_accessible'] = True
                self.log_success("✓ Web服务可访问")
            else:
                self.log_warning(f"⚠️ Web服务返回状态码: {status_code}")
        else:
            self.log_error(f"✗ Web服务不可访问: {error or '未知错误'}")
        
        status_code, _, error = self.http_get('http://localhost:8000/', timeout=5)
        if status_code is not None:
            if status_code == 200:
                ports_info['api_accessible'] = True
                self.log_success("✓ API服务可访问")
            else:
                self.log_warning(f"⚠️ API服务返回状态码: {status_code}")
        else:
            self.log_error(f"✗ API服务不可访问: {error or '未知错误'}")
        
        return ports_info
    
    def check_config_files(self) -> Dict[str, Any]:
        """检查配置文件"""
        self.log_info("检查配置文件...")
        
        config_files = {
            '.env': self.project_root / '.env',
            'env.local': self.project_root / 'env.local',
            'config.json': self.project_root / 'config.json',
            'backend_config': self.project_root / 'backend' / 'app' / 'core' / 'unified_config.py',
            'database_init': self.project_root / 'backend' / 'init_database.py',
            'install_script': self.project_root / 'install.sh'
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
                self.log_error(f"✗ {name} 不存在")
        
        return config_status
    
    def check_environment_variables(self) -> Dict[str, Any]:
        """检查环境变量"""
        self.log_info("检查环境变量...")
        
        env_vars = {
            'DATABASE_URL': os.getenv('DATABASE_URL'),
            'SERVER_HOST': os.getenv('SERVER_HOST'),
            'SERVER_PORT': os.getenv('SERVER_PORT'),
            'API_PORT': os.getenv('API_PORT'),
            'WIREGUARD_CONFIG_DIR': os.getenv('WIREGUARD_CONFIG_DIR'),
            'LOG_LEVEL': os.getenv('LOG_LEVEL'),
            'LOG_FORMAT': os.getenv('LOG_FORMAT'),
            'FIRST_SUPERUSER': os.getenv('FIRST_SUPERUSER'),
            'FIRST_SUPERUSER_PASSWORD': os.getenv('FIRST_SUPERUSER_PASSWORD')
        }
        
        print("=== 相关环境变量 ===")
        for key, value in env_vars.items():
            if value:
                # 隐藏敏感信息
                if 'PASSWORD' in key or 'SECRET' in key:
                    display_value = '*' * len(value) if value else '未设置'
                else:
                    display_value = value
                print(f"  {key}={display_value}")
                self.log_success(f"✓ {key} 已设置")
            else:
                print(f"  {key}=未设置")
                self.log_error(f"✗ {key} 未设置")
        
        return env_vars
    
    def check_logs(self) -> Dict[str, Any]:
        """检查日志文件"""
        self.log_info("检查日志文件...")
        
        logs_info = {
            'log_dir_exists': False,
            'log_files': [],
            'latest_log': None,
            'latest_content': [],
            'error_count': 0,
            'warning_count': 0
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
                        logs_info['latest_content'] = lines[-50:] if len(lines) > 50 else lines
                    
                    # 统计错误和警告
                    for line in lines:
                        if 'ERROR' in line.upper():
                            logs_info['error_count'] += 1
                        elif 'WARNING' in line.upper():
                            logs_info['warning_count'] += 1
                    
                    print(f"\n=== 最新日志文件内容 (最后50行) ===")
                    for line in logs_info['latest_content']:
                        print(line.rstrip())
                        
                except Exception as e:
                    self.log_error(f"读取日志文件失败: {e}")
            else:
                self.log_warning("⚠️ 未找到日志文件")
        else:
            logs_info['log_dir_exists'] = False
            self.log_error(f"✗ 日志目录不存在: {self.log_dir}")
        
        return logs_info
    
    def check_system_resources(self) -> Dict[str, Any]:
        """检查系统资源"""
        self.log_info("检查系统资源...")
        
        resources: Dict[str, Any] = {
            'memory': {},
            'disk': {},
            'cpu': {},
            'load_average': None
        }
        
        memory_info: Optional[Dict[str, float]] = None
        if self.psutil_available and psutil is not None:
            vm = psutil.virtual_memory()
            memory_info = {
                'total': float(vm.total),
                'available': float(vm.available),
                'used': float(vm.used),
                'percent': float(vm.percent)
            }
        else:
            self._warn_psutil_missing()
            memory_info = self._read_memory_info_without_psutil()
        
        print("=== 内存使用情况 ===")
        if memory_info:
            resources['memory'] = memory_info
            total_gb = memory_info['total'] / (1024 ** 3)
            available_gb = memory_info['available'] / (1024 ** 3)
            used_gb = memory_info['used'] / (1024 ** 3)
            percent = memory_info['percent']
            print(f"  总内存: {total_gb:.2f} GB")
            print(f"  可用内存: {available_gb:.2f} GB")
            print(f"  已用内存: {used_gb:.2f} GB")
            print(f"  使用率: {percent}%")
            if percent > 90:
                self.log_error(f"✗ 内存使用率过高: {percent}%")
            elif percent > 80:
                self.log_warning(f"⚠️ 内存使用率较高: {percent}%")
            else:
                self.log_success(f"✓ 内存使用率正常: {percent}%")
        else:
            print("  无法获取内存信息")
            self.log_warning("⚠️ 无法获取内存使用情况")
        
        try:
            disk = shutil.disk_usage('/')
            disk_percent = round((disk.used / disk.total) * 100, 1) if disk.total else 0.0
            resources['disk'] = {
                'total': float(disk.total),
                'used': float(disk.used),
                'free': float(disk.free),
                'percent': disk_percent
            }
            print(f"\n=== 磁盘使用情况 ===")
            print(f"  总容量: {disk.total // (1024**3)} GB")
            print(f"  已使用: {disk.used // (1024**3)} GB")
            print(f"  可用空间: {disk.free // (1024**3)} GB")
            print(f"  使用率: {disk_percent:.1f}%")
            if disk_percent > 90:
                self.log_error(f"✗ 磁盘使用率过高: {disk_percent:.1f}%")
            elif disk_percent > 80:
                self.log_warning(f"⚠️ 磁盘使用率较高: {disk_percent:.1f}%")
            else:
                self.log_success(f"✓ 磁盘使用率正常: {disk_percent:.1f}%")
        except Exception as exc:  # pragma: no cover - 磁盘统计异常
            self.log_warning(f"⚠️ 无法获取磁盘使用情况: {exc}")
        
        cpu_percent: Optional[float] = None
        cpu_count: Optional[int] = None
        if self.psutil_available and psutil is not None:
            cpu_percent = float(psutil.cpu_percent(interval=1))
            cpu_count = psutil.cpu_count()
        else:
            cpu_percent = self._read_cpu_usage_without_psutil()
            cpu_count = os.cpu_count()
        
        resources['cpu'] = {
            'percent': cpu_percent,
            'count': cpu_count
        }
        
        print("\n=== CPU使用情况 ===")
        print(f"  CPU核心数: {cpu_count if cpu_count is not None else '未知'}")
        if cpu_percent is not None:
            print(f"  CPU使用率: {cpu_percent}%")
            if cpu_percent > 90:
                self.log_error(f"✗ CPU使用率过高: {cpu_percent}%")
            elif cpu_percent > 80:
                self.log_warning(f"⚠️ CPU使用率较高: {cpu_percent}%")
            else:
                self.log_success(f"✓ CPU使用率正常: {cpu_percent}%")
        else:
            print("  CPU使用率: 未知")
            self.log_warning("⚠️ 无法计算CPU使用率")
        
        try:
            load_avg = os.getloadavg()
            resources['load_average'] = load_avg
            print("\n=== 系统平均负载 ===")
            print(f"  1分钟: {load_avg[0]:.2f}")
            print(f"  5分钟: {load_avg[1]:.2f}")
            print(f"  15分钟: {load_avg[2]:.2f}")
        except (AttributeError, OSError):
            resources['load_average'] = None
        
        return resources
    
    def check_permissions(self) -> Dict[str, Any]:
        """检查文件权限"""
        self.log_info("检查文件权限...")
        
        permission_info = {
            'directories': {},
            'files': {},
            'issues': []
        }
        
        # 检查关键目录权限
        key_directories = [
            self.project_root,
            self.project_root / 'logs',
            self.project_root / 'uploads',
            self.project_root / 'backups',
            self.project_root / 'config'
        ]
        
        for directory in key_directories:
            if directory.exists():
                stat = directory.stat()
                permission_info['directories'][str(directory)] = {
                    'exists': True,
                    'mode': oct(stat.st_mode)[-3:],
                    'owner': stat.st_uid,
                    'group': stat.st_gid
                }
                
                # 检查写权限
                if os.access(directory, os.W_OK):
                    self.log_success(f"✓ {directory.name} 目录可写")
                else:
                    permission_info['issues'].append(f"{directory.name} 目录不可写")
                    self.log_error(f"✗ {directory.name} 目录不可写")
            else:
                permission_info['directories'][str(directory)] = {'exists': False}
                self.log_warning(f"⚠️ {directory.name} 目录不存在")
        
        return permission_info
    
    def generate_fix_suggestions(self) -> List[str]:
        """生成修复建议"""
        suggestions = []
        
        if self.issues:
            suggestions.append("🚨 发现以下问题需要修复:")
            for issue in self.issues:
                suggestions.append(f"  - {issue}")
        
        if self.warnings:
            suggestions.append("\n⚠️ 发现以下警告:")
            for warning in self.warnings:
                suggestions.append(f"  - {warning}")
        
        # 基于问题类型提供具体建议
        if any("未安装" in issue for issue in self.issues):
            suggestions.append("\n📦 Python包安装建议:")
            suggestions.append("  pip install -r requirements.txt")
        
        if any("未运行" in issue for issue in self.issues):
            suggestions.append("\n🔧 服务启动建议:")
            suggestions.append("  sudo systemctl start ipv6-wireguard-manager")
            suggestions.append("  sudo systemctl start mysql")
            suggestions.append("  sudo systemctl start nginx")
        
        if any("连接失败" in issue for issue in self.issues):
            suggestions.append("\n🗄️ 数据库连接修复建议:")
            suggestions.append("  1. 检查MySQL服务状态")
            suggestions.append("  2. 验证DATABASE_URL配置")
            suggestions.append("  3. 检查防火墙设置")
        
        if any("不可访问" in issue for issue in self.issues):
            suggestions.append("\n🌐 网络服务修复建议:")
            suggestions.append("  1. 检查端口监听状态")
            suggestions.append("  2. 验证Nginx配置")
            suggestions.append("  3. 检查防火墙规则")
        
        return suggestions
    
    def run_comprehensive_check(self) -> Dict[str, Any]:
        """运行综合检查"""
        print("🔍 IPv6 WireGuard Manager 一键检查工具")
        print("=" * 60)
        print(f"检查时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"系统平台: {platform.platform()}")
        print("=" * 60)
        
        start_time = time.time()
        
        # 执行所有检查
        results = {
            'timestamp': datetime.now().isoformat(),
            'system': {
                'platform': platform.platform(),
                'python_version': sys.version,
                'architecture': platform.architecture()
            },
            'python_environment': self.check_python_environment(),
            'services': self.check_services(),
            'database': self.check_database_connection(),
            'ports': self.check_ports(),
            'config_files': self.check_config_files(),
            'environment': self.check_environment_variables(),
            'logs': self.check_logs(),
            'resources': self.check_system_resources(),
            'permissions': self.check_permissions(),
            'summary': {
                'total_issues': len(self.issues),
                'total_warnings': len(self.warnings),
                'total_successes': len(self.successes),
                'check_duration': 0
            }
        }
        
        end_time = time.time()
        results['summary']['check_duration'] = round(end_time - start_time, 2)
        
        # 显示总结
        print("\n" + "=" * 60)
        print("📊 检查总结")
        print("=" * 60)
        print(f"✅ 成功项目: {len(self.successes)}")
        print(f"⚠️ 警告项目: {len(self.warnings)}")
        print(f"❌ 问题项目: {len(self.issues)}")
        print(f"⏱️ 检查耗时: {results['summary']['check_duration']} 秒")
        
        # 生成修复建议
        suggestions = self.generate_fix_suggestions()
        if suggestions:
            print("\n" + "=" * 60)
            print("🔧 修复建议")
            print("=" * 60)
            for suggestion in suggestions:
                print(suggestion)
        
        return results
    
    def save_report(self, results: Dict[str, Any], filename: Optional[str] = None) -> str:
        """保存检查报告"""
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
            filename = f"ipv6-wireguard-manager-comprehensive-check-{timestamp}.json"
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False, default=str)
        
        self.log_success(f"✓ 综合检查报告已保存: {filename}")
        return filename

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='IPv6 WireGuard Manager 一键检查工具')
    parser.add_argument('--output', type=str, help='报告输出文件')
    parser.add_argument('--quiet', action='store_true', help='静默模式，只显示结果')
    
    args = parser.parse_args()
    
    checker = OneClickChecker()
    
    # 运行综合检查
    results = checker.run_comprehensive_check()
    
    # 保存报告
    report_file = checker.save_report(results, args.output)
    
    # 返回退出码
    if checker.issues:
        sys.exit(1)  # 有问题
    elif checker.warnings:
        sys.exit(2)  # 有警告
    else:
        sys.exit(0)  # 一切正常

if __name__ == '__main__':
    main()
