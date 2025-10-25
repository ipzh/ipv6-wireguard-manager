"""
环境变量管理器
提供环境变量的加载、验证、类型转换和持久化功能
"""

import os
import json
from typing import Dict, Any, Optional, Type, List, Union
from pathlib import Path
import logging
from enum import Enum

logger = logging.getLogger(__name__)

class EnvironmentType(str, Enum):
    """环境类型枚举"""
    DEVELOPMENT = "development"
    TESTING = "testing"
    STAGING = "staging"
    PRODUCTION = "production"

class EnvironmentManager:
    """环境变量管理器"""
    
    def __init__(self, env_file: Optional[str] = None):
        self.env_file = env_file or ".env"
        self._env_vars: Dict[str, Any] = {}
        self._original_env: Dict[str, str] = {}
        self._type_casters = {
            bool: self._cast_bool,
            int: self._cast_int,
            float: self._cast_float,
            list: self._cast_list,
            dict: self._cast_dict,
            str: self._cast_str
        }
        
        # 保存原始环境变量
        self._backup_original_env()
        
        # 加载环境变量
        self.load_env_file()
    
    def _backup_original_env(self):
        """备份原始环境变量"""
        self._original_env = {k: v for k, v in os.environ.items()}
    
    def load_env_file(self):
        """加载.env文件"""
        if Path(self.env_file).exists():
            try:
                from dotenv import load_dotenv
                load_dotenv(self.env_file)
                logger.info(f"已加载环境变量文件: {self.env_file}")
            except ImportError:
                logger.warning("python-dotenv未安装，跳过.env文件加载")
            except Exception as e:
                logger.error(f"加载环境变量文件失败: {e}")
    
    def get(self, key: str, default: Any = None, type: Optional[Type] = None) -> Any:
        """获取环境变量值"""
        value = os.environ.get(key, default)
        
        if value is None:
            return default
        
        # 类型转换
        if type and type in self._type_casters:
            try:
                return self._type_casters[type](value)
            except ValueError as e:
                logger.warning(f"环境变量类型转换失败: {key}={value} - {e}")
                return default
        
        return value
    
    def set(self, key: str, value: Any, persist: bool = False):
        """设置环境变量值"""
        os.environ[key] = str(value)
        self._env_vars[key] = value
        
        if persist:
            self._persist_env_var(key, value)
    
    def _persist_env_var(self, key: str, value: Any):
        """持久化环境变量到.env文件"""
        try:
            # 读取现有.env文件内容
            env_lines = []
            if Path(self.env_file).exists():
                with open(self.env_file, 'r') as f:
                    env_lines = f.readlines()
            
            # 查找并更新或添加环境变量
            key_found = False
            for i, line in enumerate(env_lines):
                if line.strip().startswith(f"{key}="):
                    env_lines[i] = f"{key}={value}\n"
                    key_found = True
                    break
            
            if not key_found:
                env_lines.append(f"{key}={value}\n")
            
            # 写回文件
            with open(self.env_file, 'w') as f:
                f.writelines(env_lines)
            
            logger.info(f"环境变量已持久化: {key}")
        except Exception as e:
            logger.error(f"环境变量持久化失败: {key} - {e}")
    
    def get_all_config(self) -> Dict[str, Any]:
        """获取所有配置"""
        config = {}
        
        # 从环境变量获取
        for key in os.environ:
            if key.startswith(("APP_", "API_", "SERVER_", "DATABASE_", "REDIS_", 
                              "LOG_", "SMTP_", "WIREGUARD_", "MONITORING_")):
                config[key] = os.environ[key]
        
        return config
    
    def _cast_bool(self, value: str) -> bool:
        """转换为布尔值"""
        return value.lower() in ('true', '1', 'yes', 'on')
    
    def _cast_int(self, value: str) -> int:
        """转换为整数"""
        return int(value)
    
    def _cast_float(self, value: str) -> float:
        """转换为浮点数"""
        return float(value)
    
    def _cast_list(self, value: str) -> List[str]:
        """转换为列表"""
        # 支持逗号分隔的字符串和JSON数组
        if value.startswith('[') and value.endswith(']'):
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                pass
        
        return [v.strip() for v in value.split(',')]
    
    def _cast_dict(self, value: str) -> Dict[str, Any]:
        """转换为字典"""
        if value.startswith('{') and value.endswith('}'):
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                pass
        
        # 简单的key=value格式
        result = {}
        for pair in value.split(','):
            if '=' in pair:
                k, v = pair.split('=', 1)
                result[k.strip()] = v.strip()
        
        return result
    
    def _cast_str(self, value: str) -> str:
        """转换为字符串"""
        return value
    
    def validate_required_vars(self, required_vars: List[str]) -> List[str]:
        """验证必需的环境变量"""
        missing = []
        for var in required_vars:
            if var not in os.environ or not os.environ[var]:
                missing.append(var)
        
        return missing
    
    def get_environment_type(self) -> EnvironmentType:
        """获取当前环境类型"""
        env_type = self.get("ENVIRONMENT", EnvironmentType.DEVELOPMENT.value)
        try:
            return EnvironmentType(env_type.lower())
        except ValueError:
            logger.warning(f"无效的环境类型: {env_type}，使用默认值: {EnvironmentType.DEVELOPMENT.value}")
            return EnvironmentType.DEVELOPMENT
    
    def is_development(self) -> bool:
        """判断是否为开发环境"""
        return self.get_environment_type() == EnvironmentType.DEVELOPMENT
    
    def is_testing(self) -> bool:
        """判断是否为测试环境"""
        return self.get_environment_type() == EnvironmentType.TESTING
    
    def is_staging(self) -> bool:
        """判断是否为预发布环境"""
        return self.get_environment_type() == EnvironmentType.STAGING
    
    def is_production(self) -> bool:
        """判断是否为生产环境"""
        return self.get_environment_type() == EnvironmentType.PRODUCTION
    
    def reset_to_original(self):
        """重置为原始环境变量"""
        # 清除当前环境变量
        for key in list(os.environ.keys()):
            if key not in self._original_env:
                os.environ.pop(key, None)
        
        # 恢复原始环境变量
        for key, value in self._original_env.items():
            os.environ[key] = value
        
        self._env_vars.clear()
        logger.info("环境变量已重置为原始值")

# 创建全局环境管理器实例
env_manager = EnvironmentManager()

# 导出便捷函数
def get_env(key: str, default: Any = None, type: Optional[Type] = None) -> Any:
    """获取环境变量值"""
    return env_manager.get(key, default, type)

def set_env(key: str, value: Any, persist: bool = False):
    """设置环境变量值"""
    env_manager.set(key, value, persist)

def is_development() -> bool:
    """判断是否为开发环境"""
    return env_manager.is_development()

def is_production() -> bool:
    """判断是否为生产环境"""
    return env_manager.is_production()

def is_testing() -> bool:
    """判断是否为测试环境"""
    return env_manager.is_testing()

# 导出主要组件
__all__ = [
    "EnvironmentManager", "env_manager",
    "get_env", "set_env",
    "is_development", "is_production", "is_testing",
    "EnvironmentType"
]
