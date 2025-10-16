"""
环境配置管理模块
统一管理不同安装模式的环境配置
"""
import os
from typing import Dict, Any, Optional
from enum import Enum

class InstallMode(Enum):
    """安装模式枚举"""
    DOCKER = "docker"
    NATIVE = "native"
    MINIMAL = "minimal"

class EnvironmentProfile(Enum):
    """环境配置档案枚举"""
    LOW_MEMORY = "low_memory"      # 低内存优化
    STANDARD = "standard"          # 标准配置
    HIGH_PERFORMANCE = "high_performance"  # 高性能配置

class EnvironmentManager:
    """环境配置管理器"""
    
    def __init__(self):
        self.install_mode = self._detect_install_mode()
        self.memory_mb = self._get_memory_mb()
        self.profile = self._determine_profile()
    
    def _detect_install_mode(self) -> InstallMode:
        """检测安装模式"""
        # 检查是否在Docker容器中
        if os.path.exists("/.dockerenv") or os.environ.get("DOCKER_CONTAINER"):
            return InstallMode.DOCKER
        
        # 检查是否有虚拟环境（原生安装）
        if os.environ.get("VIRTUAL_ENV"):
            return InstallMode.NATIVE
        
        # 检查系统服务（最小化安装）
        if os.path.exists("/etc/systemd/system/ipv6-wireguard-manager.service"):
            return InstallMode.MINIMAL
        
        # 默认检测
        if os.environ.get("INSTALL_MODE"):
            try:
                return InstallMode(os.environ.get("INSTALL_MODE"))
            except ValueError:
                pass
        
        # 默认使用原生模式
        return InstallMode.NATIVE
    
    def _get_memory_mb(self) -> int:
        """获取系统内存（MB）"""
        try:
            with open("/proc/meminfo", "r") as f:
                for line in f:
                    if line.startswith("MemTotal:"):
                        return int(line.split()[1]) // 1024
        except:
            pass
        return 2048  # 默认2GB
    
    def _determine_profile(self) -> EnvironmentProfile:
        """根据内存确定配置档案"""
        if self.memory_mb < 1024:
            return EnvironmentProfile.LOW_MEMORY
        elif self.memory_mb < 4096:
            return EnvironmentProfile.STANDARD
        else:
            return EnvironmentProfile.HIGH_PERFORMANCE
    
    def get_database_config(self) -> Dict[str, Any]:
        """获取数据库配置"""
        base_config = {
            "AUTO_CREATE_DATABASE": True,
            "DATABASE_POOL_PRE_PING": True,
            "DATABASE_POOL_RECYCLE": 3600,
        }
        
        # 根据安装模式设置数据库URL
        if self.install_mode == InstallMode.DOCKER:
            base_config["DATABASE_URL"] = "mysql://ipv6wgm:password@mysql:3306/ipv6wgm"
        else:
            base_config["DATABASE_URL"] = "mysql://ipv6wgm:password@localhost:3306/ipv6wgm"
        
        # 根据配置档案设置性能参数
        if self.profile == EnvironmentProfile.LOW_MEMORY:
            base_config.update({
                "DATABASE_POOL_SIZE": 5,
                "DATABASE_MAX_OVERFLOW": 10,
            })
        elif self.profile == EnvironmentProfile.STANDARD:
            base_config.update({
                "DATABASE_POOL_SIZE": 10,
                "DATABASE_MAX_OVERFLOW": 15,
            })
        else:  # HIGH_PERFORMANCE
            base_config.update({
                "DATABASE_POOL_SIZE": 20,
                "DATABASE_MAX_OVERFLOW": 30,
            })
        
        return base_config
    
    def get_redis_config(self) -> Dict[str, Any]:
        """获取Redis配置"""
        # 低内存模式禁用Redis
        if self.profile == EnvironmentProfile.LOW_MEMORY:
            return {
                "USE_REDIS": False,
                "REDIS_URL": None,
            }
        
        # 其他模式启用Redis
        if self.install_mode == InstallMode.DOCKER:
            redis_url = "redis://redis:6379/0"
        else:
            redis_url = "redis://localhost:6379/0"
        
        return {
            "USE_REDIS": True,
            "REDIS_URL": redis_url,
            "REDIS_POOL_SIZE": 10,
        }
    
    def get_server_config(self) -> Dict[str, Any]:
        """获取服务器配置"""
        config = {
            "SERVER_HOST": "0.0.0.0",
            "DEBUG": False,
            "ACCESS_TOKEN_EXPIRE_MINUTES": 10080,
        }
        
        # 根据安装模式设置端口
        if self.install_mode == InstallMode.DOCKER:
            config["SERVER_PORT"] = 8000
        else:
            config["SERVER_PORT"] = int(os.environ.get("API_PORT", "8000"))
        
        return config
    
    def get_performance_config(self) -> Dict[str, Any]:
        """获取性能配置"""
        if self.profile == EnvironmentProfile.LOW_MEMORY:
            return {
                "MAX_WORKERS": 2,
                "KEEP_ALIVE": 2,
                "MAX_REQUESTS": 1000,
                "MAX_REQUESTS_JITTER": 100,
            }
        elif self.profile == EnvironmentProfile.STANDARD:
            return {
                "MAX_WORKERS": 4,
                "KEEP_ALIVE": 5,
                "MAX_REQUESTS": 2000,
                "MAX_REQUESTS_JITTER": 200,
            }
        else:  # HIGH_PERFORMANCE
            return {
                "MAX_WORKERS": 8,
                "KEEP_ALIVE": 10,
                "MAX_REQUESTS": 5000,
                "MAX_REQUESTS_JITTER": 500,
            }
    
    def get_logging_config(self) -> Dict[str, Any]:
        """获取日志配置"""
        if self.profile == EnvironmentProfile.LOW_MEMORY:
            return {
                "LOG_LEVEL": "warning",
                "LOG_FILE": None,
                "LOG_ROTATION": "1 day",
                "LOG_RETENTION": "7 days",
            }
        else:
            return {
                "LOG_LEVEL": "info",
                "LOG_FILE": "/var/log/ipv6-wireguard-manager.log",
                "LOG_ROTATION": "1 day",
                "LOG_RETENTION": "30 days",
            }
    
    def get_monitoring_config(self) -> Dict[str, Any]:
        """获取监控配置"""
        if self.profile == EnvironmentProfile.LOW_MEMORY:
            return {
                "ENABLE_HEALTH_CHECK": True,
                "HEALTH_CHECK_INTERVAL": 60,  # 降低检查频率
            }
        else:
            return {
                "ENABLE_HEALTH_CHECK": True,
                "HEALTH_CHECK_INTERVAL": 30,
            }
    
    def get_cors_config(self) -> Dict[str, Any]:
        """获取CORS配置"""
        base_origins = [
            "http://localhost:3000",
            "http://localhost:8080",
            "http://localhost:5173",
            "http://localhost",
            "http://127.0.0.1:3000",
            "http://127.0.0.1:8080",
            "http://127.0.0.1:5173",
            "http://127.0.0.1",
        ]
        
        # 添加IPv6本地地址
        ipv6_origins = [
            "http://[::1]:3000",
            "http://[::1]:8080",
            "http://[::1]:5173",
            "http://[::1]",
        ]
        
        # 添加内部网络地址
        internal_origins = [
            "http://10.0.0.0/8",
            "http://172.16.0.0/12",
            "http://192.168.0.0/16",
            "http://fc00::/7",
            "http://fe80::/10",
        ]
        
        return {
            "BACKEND_CORS_ORIGINS": base_origins + ipv6_origins + internal_origins + ["*"],
        }
    
    def get_all_config(self) -> Dict[str, Any]:
        """获取所有配置"""
        config = {}
        config.update(self.get_database_config())
        config.update(self.get_redis_config())
        config.update(self.get_server_config())
        config.update(self.get_performance_config())
        config.update(self.get_logging_config())
        config.update(self.get_monitoring_config())
        config.update(self.get_cors_config())
        
        # 添加环境信息
        config.update({
            "INSTALL_MODE": self.install_mode.value,
            "ENVIRONMENT_PROFILE": self.profile.value,
            "MEMORY_MB": self.memory_mb,
        })
        
        return config
    
    def generate_env_file(self, output_path: str = ".env"):
        """生成环境变量文件"""
        config = self.get_all_config()
        
        with open(output_path, "w") as f:
            f.write("# IPv6 WireGuard Manager 环境配置\n")
            f.write(f"# 安装模式: {self.install_mode.value}\n")
            f.write(f"# 配置档案: {self.profile.value}\n")
            f.write(f"# 系统内存: {self.memory_mb}MB\n")
            f.write(f"# 自动生成时间: {os.popen('date').read().strip()}\n\n")
            
            # 数据库配置
            f.write("# 数据库配置\n")
            for key, value in self.get_database_config().items():
                f.write(f"{key}={value}\n")
            f.write("\n")
            
            # Redis配置
            f.write("# Redis配置\n")
            for key, value in self.get_redis_config().items():
                f.write(f"{key}={value}\n")
            f.write("\n")
            
            # 服务器配置
            f.write("# 服务器配置\n")
            for key, value in self.get_server_config().items():
                f.write(f"{key}={value}\n")
            f.write("\n")
            
            # 性能配置
            f.write("# 性能配置\n")
            for key, value in self.get_performance_config().items():
                f.write(f"{key}={value}\n")
            f.write("\n")
            
            # 日志配置
            f.write("# 日志配置\n")
            for key, value in self.get_logging_config().items():
                f.write(f"{key}={value}\n")
            f.write("\n")
            
            # 监控配置
            f.write("# 监控配置\n")
            for key, value in self.get_monitoring_config().items():
                f.write(f"{key}={value}\n")
            f.write("\n")
            
            # 安全配置
            f.write("# 安全配置\n")
            f.write("ALGORITHM=HS256\n")
            f.write(f"SECRET_KEY={os.urandom(32).hex()}\n")
            f.write("\n")
            
            # CORS配置
            f.write("# CORS配置\n")
            cors_origins = self.get_cors_config()["BACKEND_CORS_ORIGINS"]
            f.write(f"BACKEND_CORS_ORIGINS={','.join(cors_origins)}\n")
        
        print(f"✅ 环境配置文件已生成: {output_path}")
        print(f"   安装模式: {self.install_mode.value}")
        print(f"   配置档案: {self.profile.value}")
        print(f"   系统内存: {self.memory_mb}MB")

def main():
    """主函数 - 用于测试和生成配置"""
    import sys
    
    if len(sys.argv) > 1:
        output_path = sys.argv[1]
    else:
        output_path = ".env"
    
    manager = EnvironmentManager()
    manager.generate_env_file(output_path)
    
    print("\n📊 配置摘要:")
    config = manager.get_all_config()
    for key, value in config.items():
        if isinstance(value, (str, int, bool)) and not key.startswith("BACKEND_CORS"):
            print(f"   {key}: {value}")

if __name__ == "__main__":
    main()
