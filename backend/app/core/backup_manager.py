"""
备份管理器
实现自动化备份系统，包括数据库备份、文件备份、配置备份
"""
import asyncio
import os
import shutil
import tarfile
import gzip
import json
import logging
from typing import Dict, List, Optional, Any, Union
from datetime import datetime, timedelta
from pathlib import Path
from dataclasses import dataclass, asdict
from enum import Enum
import subprocess
import hashlib

from .config_enhanced import settings
from .performance_enhanced import performance_manager

logger = logging.getLogger(__name__)

class BackupType(Enum):
    """备份类型枚举"""
    FULL = "full"
    INCREMENTAL = "incremental"
    DATABASE = "database"
    FILES = "files"
    CONFIG = "config"

class BackupStatus(Enum):
    """备份状态枚举"""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

@dataclass
class BackupInfo:
    """备份信息"""
    id: str
    name: str
    type: BackupType
    status: BackupStatus
    created_at: datetime
    completed_at: Optional[datetime]
    size_bytes: int
    file_path: str
    checksum: str
    metadata: Dict[str, Any]
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        return {
            "id": self.id,
            "name": self.name,
            "type": self.type.value,
            "status": self.status.value,
            "created_at": self.created_at.isoformat(),
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "size_bytes": self.size_bytes,
            "file_path": self.file_path,
            "checksum": self.checksum,
            "metadata": self.metadata
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'BackupInfo':
        """从字典创建"""
        return cls(
            id=data["id"],
            name=data["name"],
            type=BackupType(data["type"]),
            status=BackupStatus(data["status"]),
            created_at=datetime.fromisoformat(data["created_at"]),
            completed_at=datetime.fromisoformat(data["completed_at"]) if data["completed_at"] else None,
            size_bytes=data["size_bytes"],
            file_path=data["file_path"],
            checksum=data["checksum"],
            metadata=data["metadata"]
        )

class DatabaseBackup:
    """数据库备份"""
    
    def __init__(self):
        self.db_config = {
            "host": "localhost",
            "port": 3306,
            "user": "ipv6wgm",
            "password": "password",
            "database": "ipv6wgm"
        }
    
    async def create_backup(self, backup_path: str) -> bool:
        """创建数据库备份"""
        try:
            # 构建mysqldump命令
            cmd = [
                "mysqldump",
                f"--host={self.db_config['host']}",
                f"--port={self.db_config['port']}",
                f"--user={self.db_config['user']}",
                f"--password={self.db_config['password']}",
                "--single-transaction",
                "--routines",
                "--triggers",
                "--events",
                "--hex-blob",
                self.db_config['database']
            ]
            
            # 执行备份
            with open(backup_path, 'w') as f:
                process = await asyncio.create_subprocess_exec(
                    *cmd,
                    stdout=f,
                    stderr=asyncio.subprocess.PIPE
                )
                
                stdout, stderr = await process.communicate()
                
                if process.returncode != 0:
                    logger.error(f"Database backup failed: {stderr.decode()}")
                    return False
            
            logger.info(f"Database backup created: {backup_path}")
            return True
            
        except Exception as e:
            logger.error(f"Database backup error: {e}")
            return False
    
    async def restore_backup(self, backup_path: str) -> bool:
        """恢复数据库备份"""
        try:
            # 构建mysql命令
            cmd = [
                "mysql",
                f"--host={self.db_config['host']}",
                f"--port={self.db_config['port']}",
                f"--user={self.db_config['user']}",
                f"--password={self.db_config['password']}",
                self.db_config['database']
            ]
            
            # 执行恢复
            with open(backup_path, 'r') as f:
                process = await asyncio.create_subprocess_exec(
                    *cmd,
                    stdin=f,
                    stderr=asyncio.subprocess.PIPE
                )
                
                stdout, stderr = await process.communicate()
                
                if process.returncode != 0:
                    logger.error(f"Database restore failed: {stderr.decode()}")
                    return False
            
            logger.info(f"Database restored from: {backup_path}")
            return True
            
        except Exception as e:
            logger.error(f"Database restore error: {e}")
            return False

class FileBackup:
    """文件备份"""
    
    def __init__(self):
        self.backup_paths = [
            settings.WIREGUARD_CONFIG_DIR,
            settings.UPLOAD_DIR,
            "backend/app/core",
            "php-frontend/config"
        ]
        self.exclude_patterns = [
            "*.log",
            "*.tmp",
            "*.cache",
            "__pycache__",
            ".git",
            "node_modules"
        ]
    
    async def create_backup(self, backup_path: str) -> bool:
        """创建文件备份"""
        try:
            with tarfile.open(backup_path, 'w:gz') as tar:
                for path in self.backup_paths:
                    if os.path.exists(path):
                        tar.add(path, arcname=os.path.basename(path))
            
            logger.info(f"File backup created: {backup_path}")
            return True
            
        except Exception as e:
            logger.error(f"File backup error: {e}")
            return False
    
    async def restore_backup(self, backup_path: str, target_dir: str = None) -> bool:
        """恢复文件备份"""
        try:
            target_dir = target_dir or os.path.dirname(backup_path)
            
            with tarfile.open(backup_path, 'r:gz') as tar:
                tar.extractall(target_dir)
            
            logger.info(f"Files restored from: {backup_path}")
            return True
            
        except Exception as e:
            logger.error(f"File restore error: {e}")
            return False

class ConfigBackup:
    """配置备份"""
    
    def __init__(self):
        self.config_files = [
            "backend/app/core/config_enhanced.py",
            "php-frontend/config/config.php",
            "php-frontend/config/database.php",
            "docker-compose.yml",
            "docker-compose.production.yml",
            ".env"
        ]
    
    async def create_backup(self, backup_path: str) -> bool:
        """创建配置备份"""
        try:
            config_data = {}
            
            for config_file in self.config_files:
                if os.path.exists(config_file):
                    with open(config_file, 'r', encoding='utf-8') as f:
                        config_data[config_file] = f.read()
            
            with open(backup_path, 'w', encoding='utf-8') as f:
                json.dump(config_data, f, indent=2, ensure_ascii=False)
            
            logger.info(f"Config backup created: {backup_path}")
            return True
            
        except Exception as e:
            logger.error(f"Config backup error: {e}")
            return False
    
    async def restore_backup(self, backup_path: str) -> bool:
        """恢复配置备份"""
        try:
            with open(backup_path, 'r', encoding='utf-8') as f:
                config_data = json.load(f)
            
            for config_file, content in config_data.items():
                os.makedirs(os.path.dirname(config_file), exist_ok=True)
                with open(config_file, 'w', encoding='utf-8') as f:
                    f.write(content)
            
            logger.info(f"Config restored from: {backup_path}")
            return True
            
        except Exception as e:
            logger.error(f"Config restore error: {e}")
            return False

class BackupScheduler:
    """备份调度器"""
    
    def __init__(self):
        self.schedules: Dict[str, Dict[str, Any]] = {}
        self.running_backups: Dict[str, asyncio.Task] = {}
    
    def add_schedule(self, name: str, schedule_config: Dict[str, Any]):
        """添加备份计划"""
        self.schedules[name] = schedule_config
        logger.info(f"Backup schedule added: {name}")
    
    def remove_schedule(self, name: str):
        """移除备份计划"""
        if name in self.schedules:
            del self.schedules[name]
            logger.info(f"Backup schedule removed: {name}")
    
    def get_schedules(self) -> Dict[str, Dict[str, Any]]:
        """获取所有备份计划"""
        return self.schedules.copy()
    
    async def run_scheduled_backups(self):
        """运行计划备份"""
        current_time = datetime.utcnow()
        
        for name, config in self.schedules.items():
            if self._should_run_backup(name, config, current_time):
                if name not in self.running_backups:
                    task = asyncio.create_task(self._run_backup_task(name, config))
                    self.running_backups[name] = task
                    logger.info(f"Scheduled backup started: {name}")
    
    def _should_run_backup(self, name: str, config: Dict[str, Any], current_time: datetime) -> bool:
        """检查是否应该运行备份"""
        schedule_type = config.get("type", "daily")
        last_run = config.get("last_run")
        
        if last_run:
            last_run_time = datetime.fromisoformat(last_run)
        else:
            last_run_time = datetime.min
        
        if schedule_type == "daily":
            return (current_time - last_run_time).days >= 1
        elif schedule_type == "weekly":
            return (current_time - last_run_time).days >= 7
        elif schedule_type == "monthly":
            return (current_time - last_run_time).days >= 30
        elif schedule_type == "hourly":
            return (current_time - last_run_time).total_seconds() >= 3600
        
        return False
    
    async def _run_backup_task(self, name: str, config: Dict[str, Any]):
        """运行备份任务"""
        try:
            backup_manager = BackupManager()
            backup_type = BackupType(config.get("backup_type", "full"))
            
            result = await backup_manager.create_backup(
                name=f"Scheduled backup: {name}",
                backup_type=backup_type,
                metadata={"schedule": name, "config": config}
            )
            
            if result:
                # 更新最后运行时间
                self.schedules[name]["last_run"] = datetime.utcnow().isoformat()
                logger.info(f"Scheduled backup completed: {name}")
            else:
                logger.error(f"Scheduled backup failed: {name}")
                
        except Exception as e:
            logger.error(f"Scheduled backup error for {name}: {e}")
        finally:
            # 清理运行中的备份任务
            if name in self.running_backups:
                del self.running_backups[name]

class BackupManager:
    """备份管理器"""
    
    def __init__(self):
        self.backup_dir = Path("backups")
        self.backup_dir.mkdir(exist_ok=True)
        
        self.db_backup = DatabaseBackup()
        self.file_backup = FileBackup()
        self.config_backup = ConfigBackup()
        self.scheduler = BackupScheduler()
        
        self.backup_history: List[BackupInfo] = []
        self.max_backups = 30  # 最大备份数量
        self.retention_days = 30  # 保留天数
    
    def _generate_backup_id(self) -> str:
        """生成备份ID"""
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        return f"backup_{timestamp}"
    
    def _calculate_checksum(self, file_path: str) -> str:
        """计算文件校验和"""
        hash_md5 = hashlib.md5()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()
    
    async def create_backup(self, name: str, backup_type: BackupType = BackupType.FULL, 
                          metadata: Dict[str, Any] = None) -> Optional[BackupInfo]:
        """创建备份"""
        backup_id = self._generate_backup_id()
        backup_info = BackupInfo(
            id=backup_id,
            name=name,
            type=backup_type,
            status=BackupStatus.PENDING,
            created_at=datetime.utcnow(),
            completed_at=None,
            size_bytes=0,
            file_path="",
            checksum="",
            metadata=metadata or {}
        )
        
        try:
            backup_info.status = BackupStatus.RUNNING
            
            # 根据备份类型创建备份
            if backup_type == BackupType.DATABASE:
                success = await self._create_database_backup(backup_info)
            elif backup_type == BackupType.FILES:
                success = await self._create_file_backup(backup_info)
            elif backup_type == BackupType.CONFIG:
                success = await self._create_config_backup(backup_info)
            else:  # FULL
                success = await self._create_full_backup(backup_info)
            
            if success:
                backup_info.status = BackupStatus.COMPLETED
                backup_info.completed_at = datetime.utcnow()
                
                # 计算文件大小和校验和
                if os.path.exists(backup_info.file_path):
                    backup_info.size_bytes = os.path.getsize(backup_info.file_path)
                    backup_info.checksum = self._calculate_checksum(backup_info.file_path)
                
                # 添加到历史记录
                self.backup_history.append(backup_info)
                
                # 清理旧备份
                await self._cleanup_old_backups()
                
                logger.info(f"Backup created successfully: {backup_id}")
                return backup_info
            else:
                backup_info.status = BackupStatus.FAILED
                logger.error(f"Backup failed: {backup_id}")
                return backup_info
                
        except Exception as e:
            backup_info.status = BackupStatus.FAILED
            logger.error(f"Backup error: {e}")
            return backup_info
    
    async def _create_database_backup(self, backup_info: BackupInfo) -> bool:
        """创建数据库备份"""
        backup_path = self.backup_dir / f"{backup_info.id}_database.sql"
        backup_info.file_path = str(backup_path)
        return await self.db_backup.create_backup(str(backup_path))
    
    async def _create_file_backup(self, backup_info: BackupInfo) -> bool:
        """创建文件备份"""
        backup_path = self.backup_dir / f"{backup_info.id}_files.tar.gz"
        backup_info.file_path = str(backup_path)
        return await self.file_backup.create_backup(str(backup_path))
    
    async def _create_config_backup(self, backup_info: BackupInfo) -> bool:
        """创建配置备份"""
        backup_path = self.backup_dir / f"{backup_info.id}_config.json"
        backup_info.file_path = str(backup_path)
        return await self.config_backup.create_backup(str(backup_path))
    
    async def _create_full_backup(self, backup_info: BackupInfo) -> bool:
        """创建完整备份"""
        backup_path = self.backup_dir / f"{backup_info.id}_full.tar.gz"
        backup_info.file_path = str(backup_path)
        
        try:
            with tarfile.open(str(backup_path), 'w:gz') as tar:
                # 添加数据库备份
                db_backup_path = self.backup_dir / f"{backup_info.id}_database.sql"
                if await self.db_backup.create_backup(str(db_backup_path)):
                    tar.add(str(db_backup_path), arcname="database.sql")
                    os.remove(db_backup_path)
                
                # 添加文件备份
                for path in self.file_backup.backup_paths:
                    if os.path.exists(path):
                        tar.add(path, arcname=f"files/{os.path.basename(path)}")
                
                # 添加配置备份
                config_backup_path = self.backup_dir / f"{backup_info.id}_config.json"
                if await self.config_backup.create_backup(str(config_backup_path)):
                    tar.add(str(config_backup_path), arcname="config.json")
                    os.remove(config_backup_path)
            
            return True
            
        except Exception as e:
            logger.error(f"Full backup error: {e}")
            return False
    
    async def restore_backup(self, backup_id: str, target_dir: str = None) -> bool:
        """恢复备份"""
        backup_info = self.get_backup(backup_id)
        if not backup_info:
            logger.error(f"Backup not found: {backup_id}")
            return False
        
        if not os.path.exists(backup_info.file_path):
            logger.error(f"Backup file not found: {backup_info.file_path}")
            return False
        
        try:
            if backup_info.type == BackupType.DATABASE:
                return await self.db_backup.restore_backup(backup_info.file_path)
            elif backup_info.type == BackupType.FILES:
                return await self.file_backup.restore_backup(backup_info.file_path, target_dir)
            elif backup_info.type == BackupType.CONFIG:
                return await self.config_backup.restore_backup(backup_info.file_path)
            else:  # FULL
                return await self._restore_full_backup(backup_info.file_path, target_dir)
                
        except Exception as e:
            logger.error(f"Restore error: {e}")
            return False
    
    async def _restore_full_backup(self, backup_path: str, target_dir: str = None) -> bool:
        """恢复完整备份"""
        try:
            target_dir = target_dir or os.path.dirname(backup_path)
            
            with tarfile.open(backup_path, 'r:gz') as tar:
                tar.extractall(target_dir)
            
            # 恢复数据库
            db_backup_path = os.path.join(target_dir, "database.sql")
            if os.path.exists(db_backup_path):
                await self.db_backup.restore_backup(db_backup_path)
                os.remove(db_backup_path)
            
            # 恢复配置
            config_backup_path = os.path.join(target_dir, "config.json")
            if os.path.exists(config_backup_path):
                await self.config_backup.restore_backup(config_backup_path)
                os.remove(config_backup_path)
            
            return True
            
        except Exception as e:
            logger.error(f"Full restore error: {e}")
            return False
    
    def get_backup(self, backup_id: str) -> Optional[BackupInfo]:
        """获取备份信息"""
        for backup in self.backup_history:
            if backup.id == backup_id:
                return backup
        return None
    
    def get_all_backups(self) -> List[BackupInfo]:
        """获取所有备份"""
        return self.backup_history.copy()
    
    def delete_backup(self, backup_id: str) -> bool:
        """删除备份"""
        backup_info = self.get_backup(backup_id)
        if not backup_info:
            return False
        
        try:
            # 删除文件
            if os.path.exists(backup_info.file_path):
                os.remove(backup_info.file_path)
            
            # 从历史记录中移除
            self.backup_history = [b for b in self.backup_history if b.id != backup_id]
            
            logger.info(f"Backup deleted: {backup_id}")
            return True
            
        except Exception as e:
            logger.error(f"Delete backup error: {e}")
            return False
    
    async def _cleanup_old_backups(self):
        """清理旧备份"""
        # 按创建时间排序
        self.backup_history.sort(key=lambda x: x.created_at, reverse=True)
        
        # 删除超过最大数量的备份
        if len(self.backup_history) > self.max_backups:
            for backup in self.backup_history[self.max_backups:]:
                self.delete_backup(backup.id)
        
        # 删除超过保留天数的备份
        cutoff_date = datetime.utcnow() - timedelta(days=self.retention_days)
        for backup in self.backup_history.copy():
            if backup.created_at < cutoff_date:
                self.delete_backup(backup.id)
    
    async def start_scheduler(self):
        """启动备份调度器"""
        # 添加默认备份计划
        self.scheduler.add_schedule("daily_full", {
            "type": "daily",
            "backup_type": "full",
            "enabled": True
        })
        
        self.scheduler.add_schedule("weekly_database", {
            "type": "weekly",
            "backup_type": "database",
            "enabled": True
        })
        
        # 启动调度循环
        asyncio.create_task(self._scheduler_loop())
        logger.info("Backup scheduler started")
    
    async def _scheduler_loop(self):
        """调度器循环"""
        while True:
            try:
                await self.scheduler.run_scheduled_backups()
                await asyncio.sleep(3600)  # 每小时检查一次
            except Exception as e:
                logger.error(f"Scheduler loop error: {e}")
                await asyncio.sleep(60)
    
    def get_backup_stats(self) -> Dict[str, Any]:
        """获取备份统计"""
        total_backups = len(self.backup_history)
        successful_backups = len([b for b in self.backup_history if b.status == BackupStatus.COMPLETED])
        failed_backups = len([b for b in self.backup_history if b.status == BackupStatus.FAILED])
        
        total_size = sum(b.size_bytes for b in self.backup_history)
        
        return {
            "total_backups": total_backups,
            "successful_backups": successful_backups,
            "failed_backups": failed_backups,
            "total_size_bytes": total_size,
            "total_size_mb": round(total_size / (1024 * 1024), 2),
            "schedules": self.scheduler.get_schedules(),
            "running_backups": list(self.scheduler.running_backups.keys())
        }

# 创建全局备份管理器实例
backup_manager = BackupManager()

# 导出
__all__ = [
    "BackupManager",
    "BackupInfo",
    "BackupType",
    "BackupStatus",
    "DatabaseBackup",
    "FileBackup",
    "ConfigBackup",
    "BackupScheduler",
    "backup_manager"
]
