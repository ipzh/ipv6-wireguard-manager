"""
配置热更新服务
监控配置文件变更并自动重新加载配置
"""

import os
import json
import time
import threading
from typing import Dict, Any, List, Callable, Optional
from pathlib import Path
import logging
from .config_manager import config_manager

logger = logging.getLogger(__name__)

try:
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler
    WATCHDOG_AVAILABLE = True
except ImportError:
    WATCHDOG_AVAILABLE = False
    logger.warning("watchdog未安装，配置热更新功能不可用")

class ConfigFileChangeHandler:
    """配置文件变更处理器"""
    
    def __init__(self, config_hot_reload):
        self.config_hot_reload = config_hot_reload
        self.last_modified = {}
    
    def on_modified(self, event):
        """文件修改事件处理"""
        if event.is_directory:
            return
        
        file_path = event.src_path
        
        # 防止重复触发
        current_time = time.time()
        if file_path in self.last_modified:
            if current_time - self.last_modified[file_path] < 1:
                return
        
        self.last_modified[file_path] = current_time
        
        # 检查是否是配置文件
        if self.config_hot_reload.is_config_file(file_path):
            logger.info(f"配置文件变更检测: {file_path}")
            self.config_hot_reload.reload_config(file_path)

class ConfigHotReload:
    """配置热更新服务"""
    
    def __init__(self):
        self.observers: List[Observer] = []
        self.config_files: Dict[str, str] = {}  # 配置名称 -> 文件路径
        self.change_callbacks: List[Callable[[str, Dict[str, Any]], None]] = []
        self.enabled = False
        self._lock = threading.Lock()
    
    def add_config_file(self, name: str, file_path: str):
        """添加要监控的配置文件"""
        with self._lock:
            self.config_files[name] = file_path
            logger.info(f"添加配置文件监控: {name} -> {file_path}")
    
    def remove_config_file(self, name: str):
        """移除配置文件监控"""
        with self._lock:
            if name in self.config_files:
                del self.config_files[name]
                logger.info(f"移除配置文件监控: {name}")
    
    def is_config_file(self, file_path: str) -> bool:
        """检查是否是配置文件"""
        return file_path in self.config_files.values()
    
    def start(self):
        """启动热更新服务"""
        if not WATCHDOG_AVAILABLE:
            logger.warning("watchdog未安装，无法启动配置热更新服务")
            return
        
        with self._lock:
            if self.enabled:
                logger.warning("配置热更新服务已启动")
                return
            
            # 为每个配置文件目录创建观察者
            watched_dirs = set()
            for file_path in self.config_files.values():
                dir_path = os.path.dirname(file_path)
                if dir_path not in watched_dirs:
                    watched_dirs.add(dir_path)
                    
                    # 创建观察者
                    observer = Observer()
                    event_handler = ConfigFileChangeHandler(self)
                    observer.schedule(event_handler, dir_path, recursive=False)
                    observer.start()
                    
                    self.observers.append(observer)
                    logger.info(f"启动目录监控: {dir_path}")
            
            self.enabled = True
            logger.info("配置热更新服务已启动")
    
    def stop(self):
        """停止热更新服务"""
        with self._lock:
            if not self.enabled:
                logger.warning("配置热更新服务未启动")
                return
            
            # 停止所有观察者
            for observer in self.observers:
                observer.stop()
                observer.join()
            
            self.observers.clear()
            self.enabled = False
            logger.info("配置热更新服务已停止")
    
    def reload_config(self, file_path: str):
        """重新加载配置"""
        try:
            # 找到对应的配置名称
            config_name = None
            for name, path in self.config_files.items():
                if path == file_path:
                    config_name = name
                    break
            
            if not config_name:
                logger.warning(f"未找到配置名称: {file_path}")
                return
            
            # 重新加载配置
            old_config = config_manager.get(config_name, {})
            
            # 根据文件扩展名确定格式
            if file_path.endswith('.json'):
                with open(file_path, 'r', encoding='utf-8') as f:
                    new_config = json.load(f)
            elif file_path.endswith('.yaml') or file_path.endswith('.yml'):
                try:
                    import yaml
                    with open(file_path, 'r', encoding='utf-8') as f:
                        new_config = yaml.safe_load(f)
                except ImportError:
                    logger.error("PyYAML未安装，无法加载YAML配置文件")
                    return
            else:
                logger.warning(f"不支持的配置文件格式: {file_path}")
                return
            
            # 更新配置
            config_manager.set(config_name, new_config)
            
            # 触发变更回调
            for callback in self.change_callbacks:
                try:
                    callback(config_name, new_config)
                except Exception as e:
                    logger.error(f"配置变更回调执行失败: {e}")
            
            logger.info(f"配置重新加载成功: {config_name}")
            
        except Exception as e:
            logger.error(f"配置重新加载失败: {file_path} - {e}")
    
    def add_change_callback(self, callback: Callable[[str, Dict[str, Any]], None]):
        """添加配置变更回调"""
        self.change_callbacks.append(callback)
    
    def remove_change_callback(self, callback: Callable[[str, Dict[str, Any]], None]):
        """移除配置变更回调"""
        if callback in self.change_callbacks:
            self.change_callbacks.remove(callback)

# 创建全局配置热更新服务实例
config_hot_reload = ConfigHotReload()

# 导出便捷函数
def start_config_hot_reload():
    """启动配置热更新服务"""
    config_hot_reload.start()

def stop_config_hot_reload():
    """停止配置热更新服务"""
    config_hot_reload.stop()

def add_config_file(name: str, file_path: str):
    """添加要监控的配置文件"""
    config_hot_reload.add_config_file(name, file_path)

def add_config_change_callback(callback: Callable[[str, Dict[str, Any]], None]):
    """添加配置变更回调"""
    config_hot_reload.add_change_callback(callback)

# 导出主要组件
__all__ = [
    "ConfigHotReload", "config_hot_reload",
    "start_config_hot_reload", "stop_config_hot_reload",
    "add_config_file", "add_config_change_callback"
]
