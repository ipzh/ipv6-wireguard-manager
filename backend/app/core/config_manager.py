"""
统一配置管理器
整合所有配置管理功能，提供单一入口点
"""

import os
import json
import yaml
from typing import Dict, Any, Optional, Union, List, Type
from pathlib import Path
from enum import Enum
import logging
from dataclasses import dataclass, field
from datetime import datetime

try:
    from pydantic_settings import BaseSettings
    from pydantic import field_validator, Field
except ImportError:
    try:
        from pydantic import BaseSettings, validator as field_validator, Field
    except ImportError:
        from pydantic import BaseSettings, Field
        def field_validator(*args, **kwargs):
            def decorator(func):
                return func
            return decorator

logger = logging.getLogger(__name__)

class EnvironmentType(str, Enum):
    """环境类型枚举"""
    DEVELOPMENT = "development"
    TESTING = "testing"
    STAGING = "staging"
    PRODUCTION = "production"

class ConfigFormat(str, Enum):
    """配置文件格式枚举"""
    JSON = "json"
    YAML = "yaml"
    ENV = "env"

@dataclass
class ConfigSource:
    """配置源定义"""
    name: str
    path: Optional[str] = None
    format: ConfigFormat = ConfigFormat.JSON
    priority: int = 0  # 优先级，数字越大优先级越高
    required: bool = True  # 是否必需
    encrypted: bool = False  # 是否加密
    watch_changes: bool = False  # 是否监控变更

@dataclass
class ConfigMetadata:
    """配置元数据"""
    name: str
    description: str
    type: Type
    default: Any = None
    required: bool = False
    sensitive: bool = False  # 是否为敏感信息
    env_var: Optional[str] = None  # 对应的环境变量名
    validator: Optional[callable] = None  # 自定义验证器

class UnifiedConfigManager:
    """统一配置管理器"""
    
    def __init__(self, app_name: str = "IPv6 WireGuard Manager"):
        self.app_name = app_name
        self.config_data: Dict[str, Any] = {}
        self.config_sources: List[ConfigSource] = []
        self.config_metadata: Dict[str, ConfigMetadata] = {}
        self.environment = os.getenv("ENVIRONMENT", EnvironmentType.DEVELOPMENT.value)
        self._watchers = []
        self._change_callbacks = []
        
        # 注册默认配置源
        self._register_default_sources()
        
        # 注册配置元数据
        self._register_config_metadata()
    
    def _register_default_sources(self):
        """注册默认配置源"""
        # 1. 基础配置文件（最低优先级）
        self.add_source(ConfigSource(
            name="base",
            path=f"config/base.{self.environment}.json",
            format=ConfigFormat.JSON,
            priority=10,
            required=False
        ))
        
        # 2. 环境变量文件
        self.add_source(ConfigSource(
            name="env_file",
            path=".env",
            format=ConfigFormat.ENV,
            priority=20,
            required=False
        ))
        
        # 3. 系统环境变量（最高优先级）
        self.add_source(ConfigSource(
            name="environment",
            format=ConfigFormat.ENV,
            priority=30,
            required=False
        ))
    
    def _register_config_metadata(self):
        """注册配置元数据"""
        # 应用基础配置
        self.register_metadata("APP_NAME", str, "应用名称", default=self.app_name)
        self.register_metadata("APP_VERSION", str, "应用版本", default="3.0.0")
        self.register_metadata("DEBUG", bool, "调试模式", default=False, env_var="DEBUG")
        self.register_metadata("ENVIRONMENT", str, "运行环境", default=EnvironmentType.DEVELOPMENT.value, 
                              validator=lambda x: x in [e.value for e in EnvironmentType])
        
        # API配置
        self.register_metadata("API_V1_STR", str, "API路径前缀", default="/api/v1")
        self.register_metadata("SECRET_KEY", str, "密钥", default="", sensitive=True, 
                              validator=lambda x: len(x) >= 32)
        self.register_metadata("ACCESS_TOKEN_EXPIRE_MINUTES", int, "访问令牌过期时间(分钟)", 
                              default=60 * 24 * 8)
        
        # 服务器配置
        self.register_metadata("SERVER_HOST", str, "服务器主机", default="${SERVER_HOST}")
        self.register_metadata("SERVER_PORT", int, "服务器端口", default=8000, 
                              validator=lambda x: 1 <= x <= 65535)
        
        # 数据库配置
        self.register_metadata("DATABASE_URL", str, "数据库连接URL", 
                              default="mysql://ipv6wgm:password@localhost:3306/ipv6wgm", 
                              sensitive=True)
        self.register_metadata("DATABASE_HOST", str, "数据库主机", default="localhost")
        self.register_metadata("DATABASE_PORT", int, "数据库端口", default=3306)
        self.register_metadata("DATABASE_USER", str, "数据库用户名", default="ipv6wgm")
        self.register_metadata("DATABASE_PASSWORD", str, "数据库密码", default="", sensitive=True)
        self.register_metadata("DATABASE_NAME", str, "数据库名称", default="ipv6wgm")
        self.register_metadata("DATABASE_POOL_SIZE", int, "数据库连接池大小", default=10)
        self.register_metadata("DATABASE_MAX_OVERFLOW", int, "数据库连接池最大溢出", default=20)
        self.register_metadata("DATABASE_CONNECT_TIMEOUT", int, "数据库连接超时(秒)", default=30)
        self.register_metadata("DATABASE_POOL_RECYCLE", int, "数据库连接回收时间(秒)", default=3600)
        self.register_metadata("DATABASE_POOL_PRE_PING", bool, "数据库连接预检查", default=True)
        self.register_metadata("AUTO_CREATE_DATABASE", bool, "自动创建数据库", default=True)
        
        # Redis配置
        self.register_metadata("REDIS_URL", str, "Redis连接URL", default=None)
        self.register_metadata("REDIS_POOL_SIZE", int, "Redis连接池大小", default=10)
        self.register_metadata("USE_REDIS", bool, "是否使用Redis", default=False)
        
        # 安全配置
        self.register_metadata("ALGORITHM", str, "加密算法", default="HS256")
        self.register_metadata("BACKEND_CORS_ORIGINS", List[str], "CORS允许的源", 
                              default=["http://localhost:${FRONTEND_PORT}", "http://localhost:${ADMIN_PORT}"])
        
        # 文件上传配置
        self.register_metadata("MAX_FILE_SIZE", int, "最大文件大小(字节)", 
                              default=10 * 1024 * 1024)  # 10MB
        self.register_metadata("UPLOAD_DIR", str, "上传目录", default="uploads")
        self.register_metadata("ALLOWED_EXTENSIONS", List[str], "允许的文件扩展名", 
                              default=[".conf", ".key", ".crt", ".pem", ".txt", ".log"])
        
        # WireGuard配置
        self.register_metadata("WIREGUARD_CONFIG_DIR", str, "WireGuard配置目录", 
                              default="/etc/wireguard")
        self.register_metadata("WIREGUARD_CLIENTS_DIR", str, "WireGuard客户端配置目录", 
                              default="/etc/wireguard/clients")
        
        # 监控配置
        self.register_metadata("ENABLE_METRICS", bool, "是否启用指标", default=True)
        self.register_metadata("METRICS_PORT", int, "指标端口", default=9090)
        self.register_metadata("ENABLE_HEALTH_CHECK", bool, "是否启用健康检查", default=True)
        self.register_metadata("HEALTH_CHECK_INTERVAL", int, "健康检查间隔(秒)", default=30)
        
        # 日志配置
        self.register_metadata("LOG_LEVEL", str, "日志级别", default="INFO", 
                              validator=lambda x: x.upper() in ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"])
        self.register_metadata("LOG_FORMAT", str, "日志格式", default="json")
        self.register_metadata("LOG_FILE", str, "日志文件路径", default=None)
        self.register_metadata("LOG_ROTATION", str, "日志轮转", default="1 day")
        self.register_metadata("LOG_RETENTION", str, "日志保留时间", default="30 days")
        
        # 性能配置
        self.register_metadata("MAX_WORKERS", int, "最大工作进程数", default=4)
        self.register_metadata("WORKER_CLASS", str, "工作进程类", default="uvicorn.workers.UvicornWorker")
        self.register_metadata("KEEP_ALIVE", int, "连接保持时间(秒)", default=2)
        self.register_metadata("MAX_REQUESTS", int, "最大请求数", default=1000)
        self.register_metadata("MAX_REQUESTS_JITTER", int, "最大请求数抖动", default=100)
        
        # 邮件配置
        self.register_metadata("SMTP_TLS", bool, "SMTP是否使用TLS", default=True)
        self.register_metadata("SMTP_PORT", int, "SMTP端口", default=None)
        self.register_metadata("SMTP_HOST", str, "SMTP主机", default=None)
        self.register_metadata("SMTP_USER", str, "SMTP用户名", default=None)
        self.register_metadata("SMTP_PASSWORD", str, "SMTP密码", default=None, sensitive=True)
        self.register_metadata("EMAILS_FROM_EMAIL", str, "发件人邮箱", default=None)
        self.register_metadata("EMAILS_FROM_NAME", str, "发件人名称", default=None)
        
        # 超级用户配置
        self.register_metadata("FIRST_SUPERUSER", str, "超级用户名", default="admin")
        self.register_metadata("FIRST_SUPERUSER_PASSWORD", str, "超级用户密码", 
                              default="admin123", sensitive=True)
        self.register_metadata("FIRST_SUPERUSER_EMAIL", str, "超级用户邮箱", 
                              default="admin@example.com")
    
    def add_source(self, source: ConfigSource):
        """添加配置源"""
        self.config_sources.append(source)
        # 按优先级排序
        self.config_sources.sort(key=lambda x: x.priority)
    
    def register_metadata(self, key: str, type: Type, description: str, 
                         default: Any = None, required: bool = False, 
                         sensitive: bool = False, env_var: Optional[str] = None,
                         validator: Optional[callable] = None):
        """注册配置元数据"""
        self.config_metadata[key] = ConfigMetadata(
            name=key,
            description=description,
            type=type,
            default=default,
            required=required,
            sensitive=sensitive,
            env_var=env_var or key,
            validator=validator
        )
    
    def load_config(self):
        """加载所有配置源"""
        self.config_data = {}
        
        # 按优先级从低到高加载配置
        for source in self.config_sources:
            try:
                if source.format == ConfigFormat.ENV and source.name == "environment":
                    # 从系统环境变量加载
                    self._load_from_environment()
                elif source.format == ConfigFormat.ENV and source.name == "env_file":
                    # 从.env文件加载
                    self._load_from_env_file(source.path)
                else:
                    # 从文件加载
                    self._load_from_file(source)
                
                logger.info(f"已加载配置源: {source.name}")
            except Exception as e:
                if source.required:
                    logger.error(f"必需配置源加载失败: {source.name} - {e}")
                    raise
                else:
                    logger.warning(f"可选配置源加载失败: {source.name} - {e}")
        
        # 应用默认值
        self._apply_defaults()
        
        # 验证配置
        self._validate_config()
        
        # 处理敏感信息
        self._handle_sensitive_data()
        
        logger.info("配置加载完成")
    
    def _load_from_file(self, source: ConfigSource):
        """从文件加载配置"""
        if not source.path or not Path(source.path).exists():
            return
        
        with open(source.path, 'r', encoding='utf-8') as f:
            if source.format == ConfigFormat.JSON:
                config = json.load(f)
            elif source.format == ConfigFormat.YAML:
                config = yaml.safe_load(f)
            else:
                raise ValueError(f"不支持的配置格式: {source.format}")
        
        # 如果是加密配置，先解密
        if source.encrypted:
            config = self._decrypt_config(config)
        
        # 合并配置
        self._merge_config(config)
    
    def _load_from_env_file(self, path: Optional[str]):
        """从.env文件加载配置"""
        if not path or not Path(path).exists():
            return
        
        try:
            from dotenv import load_dotenv
            load_dotenv(path)
            
            # 从环境变量中读取
            for key in os.environ:
                if key in self.config_metadata:
                    self.config_data[key] = os.environ[key]
        except ImportError:
            logger.warning("python-dotenv未安装，跳过.env文件加载")
        except Exception as e:
            logger.error(f"加载.env文件失败: {e}")
    
    def _load_from_environment(self):
        """从系统环境变量加载配置"""
        for key, metadata in self.config_metadata.items():
            if metadata.env_var in os.environ:
                value = os.environ[metadata.env_var]
                # 类型转换
                try:
                    if metadata.type == bool:
                        value = value.lower() in ('true', '1', 'yes', 'on')
                    elif metadata.type == int:
                        value = int(value)
                    elif metadata.type == float:
                        value = float(value)
                    elif metadata.type == list:
                        # 简单的逗号分隔列表处理
                        value = [v.strip() for v in value.split(',')]
                except ValueError as e:
                    logger.warning(f"环境变量类型转换失败: {metadata.env_var}={value} - {e}")
                    continue
                
                self.config_data[key] = value
    
    def _merge_config(self, config: Dict[str, Any]):
        """合并配置"""
        for key, value in config.items():
            if key in self.config_metadata:
                self.config_data[key] = value
    
    def _apply_defaults(self):
        """应用默认值"""
        for key, metadata in self.config_metadata.items():
            if key not in self.config_data and metadata.default is not None:
                self.config_data[key] = metadata.default
    
    def _validate_config(self):
        """验证配置"""
        errors = []
        
        for key, metadata in self.config_metadata.items():
            if key not in self.config_data:
                if metadata.required:
                    errors.append(f"缺少必需配置项: {key}")
                continue
            
            value = self.config_data[key]
            
            # 类型验证
            # 处理泛型类型，如List[str]
            type_check = metadata.type
            if hasattr(metadata.type, '__origin__'):
                # 处理Python 3.9+中的泛型类型
                type_check = metadata.type.__origin__
            
            if not isinstance(value, type_check):
                try:
                    # 尝试类型转换
                    if metadata.type == bool:
                        self.config_data[key] = bool(value)
                    elif metadata.type == int:
                        self.config_data[key] = int(value)
                    elif metadata.type == float:
                        self.config_data[key] = float(value)
                    elif metadata.type == list:
                        if isinstance(value, str):
                            self.config_data[key] = [v.strip() for v in value.split(',')]
                        else:
                            self.config_data[key] = list(value)
                except ValueError:
                    errors.append(f"配置项类型错误: {key} 期望 {metadata.type.__name__}")
            
            # 自定义验证
            if metadata.validator and key in self.config_data:
                try:
                    if not metadata.validator(self.config_data[key]):
                        errors.append(f"配置项验证失败: {key}")
                except Exception as e:
                    errors.append(f"配置项验证异常: {key} - {e}")
        
        if errors:
            raise ValueError(f"配置验证失败: {'; '.join(errors)}")
    
    def _handle_sensitive_data(self):
        """处理敏感数据"""
        for key, metadata in self.config_metadata.items():
            if metadata.sensitive and key in self.config_data:
                # 在日志中隐藏敏感数据
                value = self.config_data[key]
                if value:
                    masked_value = '*' * len(str(value))
                    logger.debug(f"配置项 {key} 已设置: {masked_value}")
    
    def _decrypt_config(self, config: Dict[str, Any]) -> Dict[str, Any]:
        """解密配置"""
        # 实现配置解密逻辑
        # 这里可以使用Fernet或其他加密方法
        return config
    
    def get(self, key: str, default: Any = None) -> Any:
        """获取配置值"""
        if key in self.config_data:
            return self.config_data[key]
        return default
    
    def set(self, key: str, value: Any, persist: bool = False):
        """设置配置值"""
        if key not in self.config_metadata:
            logger.warning(f"未知配置项: {key}")
        
        old_value = self.config_data.get(key)
        self.config_data[key] = value
        
        # 触发变更回调
        for callback in self._change_callbacks:
            try:
                callback(key, old_value, value)
            except Exception as e:
                logger.error(f"配置变更回调执行失败: {e}")
        
        # 持久化配置
        if persist:
            self._persist_config(key, value)
    
    def _persist_config(self, key: str, value: Any):
        """持久化配置"""
        # 实现配置持久化逻辑
        pass
    
    def add_change_callback(self, callback: callable):
        """添加配置变更回调"""
        self._change_callbacks.append(callback)
    
    def get_config_summary(self) -> Dict[str, Any]:
        """获取配置摘要"""
        return {
            "environment": self.environment,
            "config_count": len(self.config_data),
            "sources": [{"name": s.name, "priority": s.priority} for s in self.config_sources],
            "metadata_count": len(self.config_metadata)
        }
    
    def get_config_documentation(self) -> str:
        """获取配置文档"""
        doc = f"# {self.app_name} 配置文档\n\n"
        doc += f"当前环境: {self.environment}\n\n"
        doc += "## 配置项说明\n\n"
        
        for key, metadata in self.config_metadata.items():
            doc += f"### {key}\n"
            doc += f"- **描述**: {metadata.description}\n"
            doc += f"- **类型**: {metadata.type.__name__}\n"
            doc += f"- **默认值**: {metadata.default}\n"
            doc += f"- **必需**: {'是' if metadata.required else '否'}\n"
            doc += f"- **敏感**: {'是' if metadata.sensitive else '否'}\n"
            doc += f"- **环境变量**: {metadata.env_var}\n"
            
            if key in self.config_data:
                value = self.config_data[key]
                if metadata.sensitive and value:
                    value = '*' * len(str(value))
                doc += f"- **当前值**: {value}\n"
            
            doc += "\n"
        
        return doc

# 创建全局配置管理器实例
config_manager = UnifiedConfigManager()

# 加载配置
config_manager.load_config()

# 提供便捷的访问函数
def get_config(key: str, default: Any = None) -> Any:
    """获取配置值"""
    return config_manager.get(key, default)

def set_config(key: str, value: Any, persist: bool = False):
    """设置配置值"""
    config_manager.set(key, value, persist)

def is_development() -> bool:
    """判断是否为开发环境"""
    return config_manager.get("ENVIRONMENT") == EnvironmentType.DEVELOPMENT.value

def is_production() -> bool:
    """判断是否为生产环境"""
    return config_manager.get("ENVIRONMENT") == EnvironmentType.PRODUCTION.value

def is_testing() -> bool:
    """判断是否为测试环境"""
    return config_manager.get("ENVIRONMENT") == EnvironmentType.TESTING.value

# 导出主要组件
__all__ = [
    "UnifiedConfigManager", "config_manager", 
    "get_config", "set_config", 
    "is_development", "is_production", "is_testing",
    "EnvironmentType", "ConfigFormat", "ConfigSource"
]
