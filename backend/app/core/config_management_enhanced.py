"""
配置管理机制增强实现
基于您的分析，实现配置加密、热更新、配置审计等功能
"""

import os
import json
import yaml
import hashlib
import logging
from typing import Dict, Any, Optional, List, Union
from datetime import datetime
from pathlib import Path
from cryptography.fernet import Fernet
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import threading
import time

logger = logging.getLogger(__name__)

class ConfigEncryption:
    """配置加密管理"""
    
    def __init__(self, key: Optional[str] = None):
        if key:
            self.cipher = Fernet(key.encode())
        else:
            # 生成新密钥
            self.key = Fernet.generate_key()
            self.cipher = Fernet(self.key)
    
    def encrypt_config(self, config: Dict[str, Any]) -> str:
        """加密配置"""
        config_json = json.dumps(config, ensure_ascii=False)
        encrypted_data = self.cipher.encrypt(config_json.encode())
        return encrypted_data.decode()
    
    def decrypt_config(self, encrypted_config: str) -> Dict[str, Any]:
        """解密配置"""
        try:
            decrypted_data = self.cipher.decrypt(encrypted_config.encode())
            return json.loads(decrypted_data.decode())
        except Exception as e:
            logger.error(f"配置解密失败: {e}")
            raise
    
    def get_key(self) -> str:
        """获取加密密钥"""
        return self.key.decode()

class ConfigAuditLogger:
    """配置审计日志"""
    
    def __init__(self, log_file: str = "config_audit.log"):
        self.log_file = log_file
        self.setup_logger()
    
    def setup_logger(self):
        """设置审计日志器"""
        self.audit_logger = logging.getLogger('config_audit')
        self.audit_logger.setLevel(logging.INFO)
        
        # 创建文件处理器
        handler = logging.FileHandler(self.log_file)
        formatter = logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s'
        )
        handler.setFormatter(formatter)
        self.audit_logger.addHandler(handler)
    
    def log_config_change(self, action: str, key: str, old_value: Any, new_value: Any, user: str = "system"):
        """记录配置变更"""
        audit_entry = {
            'timestamp': datetime.now().isoformat(),
            'action': action,
            'key': key,
            'old_value': str(old_value) if old_value is not None else None,
            'new_value': str(new_value) if new_value is not None else None,
            'user': user,
            'hash': hashlib.md5(f"{key}{new_value}".encode()).hexdigest()
        }
        
        self.audit_logger.info(json.dumps(audit_entry, ensure_ascii=False))
    
    def get_audit_history(self, key: Optional[str] = None, limit: int = 100) -> List[Dict[str, Any]]:
        """获取审计历史"""
        history = []
        
        try:
            with open(self.log_file, 'r', encoding='utf-8') as f:
                for line in f:
                    try:
                        entry = json.loads(line.strip())
                        if key is None or entry.get('key') == key:
                            history.append(entry)
                    except json.JSONDecodeError:
                        continue
            
            return history[-limit:] if limit > 0 else history
            
        except FileNotFoundError:
            return []

class ConfigHotReloadHandler(FileSystemEventHandler):
    """配置热更新处理器"""
    
    def __init__(self, config_manager):
        self.config_manager = config_manager
        self.last_modified = {}
    
    def on_modified(self, event):
        """文件修改事件处理"""
        if event.is_directory:
            return
        
        file_path = event.src_path
        
        # 检查是否是配置文件
        if not self.config_manager.is_config_file(file_path):
            return
        
        # 防止重复触发
        current_time = time.time()
        if file_path in self.last_modified:
            if current_time - self.last_modified[file_path] < 1:
                return
        
        self.last_modified[file_path] = current_time
        
        logger.info(f"配置文件变更检测: {file_path}")
        
        # 重新加载配置
        try:
            self.config_manager.reload_config(file_path)
            logger.info(f"配置热更新成功: {file_path}")
        except Exception as e:
            logger.error(f"配置热更新失败: {file_path} - {e}")

class EnhancedConfigManager:
    """增强的配置管理器"""
    
    def __init__(self, config_dir: str = "config", encrypted: bool = False):
        self.config_dir = Path(config_dir)
        self.config_dir.mkdir(exist_ok=True)
        
        self.configs: Dict[str, Dict[str, Any]] = {}
        self.config_files: Dict[str, str] = {}
        self.encrypted = encrypted
        
        # 初始化加密
        if encrypted:
            self.encryption = ConfigEncryption()
        else:
            self.encryption = None
        
        # 初始化审计日志
        self.audit_logger = ConfigAuditLogger()
        
        # 初始化热更新
        self.observer = Observer()
        self.hot_reload_handler = ConfigHotReloadHandler(self)
        self.hot_reload_enabled = False
        
        # 配置变更回调
        self.change_callbacks: List[callable] = []
    
    def add_config_file(self, name: str, file_path: str, format: str = "json"):
        """添加配置文件"""
        self.config_files[name] = file_path
        
        # 加载配置
        self.load_config(name, file_path, format)
        
        # 监听文件变化
        if self.hot_reload_enabled:
            self.observer.schedule(
                self.hot_reload_handler,
                os.path.dirname(file_path),
                recursive=False
            )
    
    def load_config(self, name: str, file_path: str, format: str = "json"):
        """加载配置文件"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                if format == "json":
                    config = json.load(f)
                elif format == "yaml":
                    config = yaml.safe_load(f)
                else:
                    raise ValueError(f"不支持的配置格式: {format}")
            
            # 解密配置
            if self.encrypted and self.encryption:
                config = self.encryption.decrypt_config(config)
            
            old_config = self.configs.get(name, {})
            self.configs[name] = config
            
            # 记录审计日志
            self.audit_logger.log_config_change(
                "load", name, old_config, config
            )
            
            logger.info(f"配置文件加载成功: {name}")
            
        except Exception as e:
            logger.error(f"配置文件加载失败: {name} - {e}")
            raise
    
    def reload_config(self, file_path: str):
        """重新加载配置文件"""
        # 找到对应的配置名称
        config_name = None
        for name, path in self.config_files.items():
            if path == file_path:
                config_name = name
                break
        
        if config_name:
            # 重新加载
            format = "json" if file_path.endswith('.json') else "yaml"
            self.load_config(config_name, file_path, format)
            
            # 触发变更回调
            self._trigger_change_callbacks(config_name)
    
    def get_config(self, name: str, key: Optional[str] = None, default: Any = None) -> Any:
        """获取配置值"""
        if name not in self.configs:
            return default
        
        config = self.configs[name]
        
        if key is None:
            return config
        
        # 支持点号分隔的嵌套键
        keys = key.split('.')
        value = config
        
        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                return default
        
        return value
    
    def set_config(self, name: str, key: str, value: Any, user: str = "system"):
        """设置配置值"""
        if name not in self.configs:
            self.configs[name] = {}
        
        # 获取旧值
        old_value = self.get_config(name, key)
        
        # 设置新值
        keys = key.split('.')
        config = self.configs[name]
        
        for k in keys[:-1]:
            if k not in config:
                config[k] = {}
            config = config[k]
        
        config[keys[-1]] = value
        
        # 记录审计日志
        self.audit_logger.log_config_change(
            "set", f"{name}.{key}", old_value, value, user
        )
        
        # 触发变更回调
        self._trigger_change_callbacks(name)
        
        logger.info(f"配置值已更新: {name}.{key}")
    
    def save_config(self, name: str, file_path: Optional[str] = None):
        """保存配置文件"""
        if name not in self.configs:
            raise ValueError(f"配置不存在: {name}")
        
        config = self.configs[name]
        
        # 加密配置
        if self.encrypted and self.encryption:
            config = self.encryption.encrypt_config(config)
        
        # 确定文件路径
        if file_path is None:
            file_path = self.config_files.get(name)
            if file_path is None:
                raise ValueError(f"未指定配置文件路径: {name}")
        
        # 保存文件
        with open(file_path, 'w', encoding='utf-8') as f:
            if file_path.endswith('.json'):
                json.dump(config, f, indent=2, ensure_ascii=False)
            elif file_path.endswith('.yaml'):
                yaml.dump(config, f, default_flow_style=False, allow_unicode=True)
            else:
                raise ValueError(f"不支持的配置文件格式: {file_path}")
        
        logger.info(f"配置文件保存成功: {name}")
    
    def enable_hot_reload(self):
        """启用热更新"""
        if not self.hot_reload_enabled:
            self.observer.start()
            self.hot_reload_enabled = True
            logger.info("配置热更新已启用")
    
    def disable_hot_reload(self):
        """禁用热更新"""
        if self.hot_reload_enabled:
            self.observer.stop()
            self.hot_reload_enabled = False
            logger.info("配置热更新已禁用")
    
    def add_change_callback(self, callback: callable):
        """添加配置变更回调"""
        self.change_callbacks.append(callback)
    
    def _trigger_change_callbacks(self, config_name: str):
        """触发配置变更回调"""
        for callback in self.change_callbacks:
            try:
                callback(config_name, self.configs[config_name])
            except Exception as e:
                logger.error(f"配置变更回调执行失败: {e}")
    
    def is_config_file(self, file_path: str) -> bool:
        """检查是否是配置文件"""
        return file_path in self.config_files.values()
    
    def get_config_summary(self) -> Dict[str, Any]:
        """获取配置摘要"""
        return {
            "total_configs": len(self.configs),
            "config_names": list(self.configs.keys()),
            "hot_reload_enabled": self.hot_reload_enabled,
            "encrypted": self.encrypted,
            "audit_log_file": self.audit_logger.log_file
        }
    
    def validate_config(self, name: str, schema: Dict[str, Any]) -> List[str]:
        """验证配置"""
        if name not in self.configs:
            return [f"配置不存在: {name}"]
        
        config = self.configs[name]
        errors = []
        
        for key, expected_type in schema.items():
            if key not in config:
                errors.append(f"缺少必需配置项: {key}")
            elif not isinstance(config[key], expected_type):
                errors.append(f"配置项类型错误: {key} 期望 {expected_type.__name__}")
        
        return errors
    
    def export_config(self, name: str, format: str = "json") -> str:
        """导出配置"""
        if name not in self.configs:
            raise ValueError(f"配置不存在: {name}")
        
        config = self.configs[name]
        
        if format == "json":
            return json.dumps(config, indent=2, ensure_ascii=False)
        elif format == "yaml":
            return yaml.dump(config, default_flow_style=False, allow_unicode=True)
        else:
            raise ValueError(f"不支持的导出格式: {format}")
    
    def import_config(self, name: str, config_data: str, format: str = "json"):
        """导入配置"""
        try:
            if format == "json":
                config = json.loads(config_data)
            elif format == "yaml":
                config = yaml.safe_load(config_data)
            else:
                raise ValueError(f"不支持的导入格式: {format}")
            
            old_config = self.configs.get(name, {})
            self.configs[name] = config
            
            # 记录审计日志
            self.audit_logger.log_config_change(
                "import", name, old_config, config
            )
            
            logger.info(f"配置导入成功: {name}")
            
        except Exception as e:
            logger.error(f"配置导入失败: {name} - {e}")
            raise

# 使用示例
def config_change_callback(config_name: str, config: Dict[str, Any]):
    """配置变更回调示例"""
    print(f"配置已更新: {config_name}")
    print(f"新配置: {config}")

if __name__ == "__main__":
    # 创建配置管理器
    config_manager = EnhancedConfigManager(encrypted=True)
    
    # 添加配置变更回调
    config_manager.add_change_callback(config_change_callback)
    
    # 启用热更新
    config_manager.enable_hot_reload()
    
    # 添加配置文件
    config_manager.add_config_file("app", "config/app.json")
    config_manager.add_config_file("database", "config/database.yaml")
    
    # 设置配置值
    config_manager.set_config("app", "debug", True, "admin")
    config_manager.set_config("app", "server.port", 8000, "admin")
    
    # 获取配置值
    debug_mode = config_manager.get_config("app", "debug")
    server_port = config_manager.get_config("app", "server.port")
    
    print(f"调试模式: {debug_mode}")
    print(f"服务器端口: {server_port}")
    
    # 获取配置摘要
    summary = config_manager.get_config_summary()
    print(f"配置摘要: {summary}")
    
    # 获取审计历史
    audit_history = config_manager.audit_logger.get_audit_history(limit=5)
    print(f"审计历史: {audit_history}")
    
    # 验证配置
    schema = {"debug": bool, "server.port": int}
    errors = config_manager.validate_config("app", schema)
    print(f"配置验证: {errors}")
    
    # 导出配置
    exported_config = config_manager.export_config("app")
    print(f"导出配置: {exported_config}")
    
    # 禁用热更新
    config_manager.disable_hot_reload()
