#!/usr/bin/env python3
"""
备份管理脚本
支持数据库备份、文件备份、增量备份、恢复功能
"""

import os
import sys
import json
import shutil
import subprocess
import gzip
import tarfile
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Any, Optional
import argparse
import logging

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class BackupManager:
    """备份管理器"""
    
    def __init__(self, config_file: str = "backup_config.json"):
        self.config_file = Path(config_file)
        self.config = self.load_config()
        self.backup_dir = Path(self.config.get("backup_dir", "./backups"))
        self.backup_dir.mkdir(parents=True, exist_ok=True)
    
    def load_config(self) -> Dict[str, Any]:
        """加载备份配置"""
        default_config = {
            "backup_dir": "./backups",
            "retention_days": 30,
            "compression": True,
            "encryption": False,
            "databases": {
                "mysql": {
                    "host": "localhost",
                    "port": 3306,
                    "user": "root",
                    "password": "password",
                    "databases": ["ipv6wgm"]
                }
            },
            "directories": [
                "./config",
                "./uploads",
                "./logs"
            ],
            "exclude_patterns": [
                "*.tmp",
                "*.log",
                "__pycache__",
                ".git"
            ],
            "notification": {
                "enabled": False,
                "email": "admin@example.com",
                "webhook": None
            }
        }
        
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                return {**default_config, **config}
            except Exception as e:
                logger.warning(f"配置文件加载失败，使用默认配置: {e}")
        
        return default_config
    
    def save_config(self):
        """保存配置"""
        with open(self.config_file, 'w', encoding='utf-8') as f:
            json.dump(self.config, f, indent=2, ensure_ascii=False)
    
    def create_database_backup(self, db_name: str) -> Optional[Path]:
        """创建数据库备份"""
        try:
            db_config = self.config["databases"]["mysql"]
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_filename = f"{db_name}_{timestamp}.sql"
            backup_path = self.backup_dir / "database" / backup_filename
            backup_path.parent.mkdir(parents=True, exist_ok=True)
            
            # 构建mysqldump命令
            cmd = [
                "mysqldump",
                "-h", db_config["host"],
                "-P", str(db_config["port"]),
                "-u", db_config["user"],
                f"-p{db_config['password']}",
                "--single-transaction",
                "--routines",
                "--triggers",
                db_name
            ]
            
            # 执行备份
            with open(backup_path, 'w') as f:
                result = subprocess.run(cmd, stdout=f, stderr=subprocess.PIPE, text=True)
            
            if result.returncode != 0:
                logger.error(f"数据库备份失败: {result.stderr}")
                return None
            
            # 压缩备份文件
            if self.config.get("compression", True):
                compressed_path = self.compress_file(backup_path)
                backup_path.unlink()  # 删除未压缩的文件
                backup_path = compressed_path
            
            logger.info(f"数据库备份完成: {backup_path}")
            return backup_path
            
        except Exception as e:
            logger.error(f"数据库备份失败: {e}")
            return None
    
    def create_directory_backup(self, directory: str) -> Optional[Path]:
        """创建目录备份"""
        try:
            source_path = Path(directory)
            if not source_path.exists():
                logger.warning(f"目录不存在: {directory}")
                return None
            
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_filename = f"{source_path.name}_{timestamp}.tar.gz"
            backup_path = self.backup_dir / "directories" / backup_filename
            backup_path.parent.mkdir(parents=True, exist_ok=True)
            
            # 创建tar.gz备份
            with tarfile.open(backup_path, "w:gz") as tar:
                tar.add(source_path, arcname=source_path.name, exclude=self._get_exclude_filter())
            
            logger.info(f"目录备份完成: {backup_path}")
            return backup_path
            
        except Exception as e:
            logger.error(f"目录备份失败: {e}")
            return None
    
    def create_full_backup(self) -> Dict[str, Any]:
        """创建完整备份"""
        logger.info("开始创建完整备份...")
        backup_info = {
            "timestamp": datetime.now().isoformat(),
            "type": "full",
            "databases": [],
            "directories": [],
            "total_size": 0
        }
        
        # 备份数据库
        for db_name in self.config["databases"]["mysql"]["databases"]:
            db_backup = self.create_database_backup(db_name)
            if db_backup:
                backup_info["databases"].append(str(db_backup))
                backup_info["total_size"] += db_backup.stat().st_size
        
        # 备份目录
        for directory in self.config["directories"]:
            dir_backup = self.create_directory_backup(directory)
            if dir_backup:
                backup_info["directories"].append(str(dir_backup))
                backup_info["total_size"] += dir_backup.stat().st_size
        
        # 保存备份信息
        backup_info_file = self.backup_dir / f"backup_info_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(backup_info_file, 'w', encoding='utf-8') as f:
            json.dump(backup_info, f, indent=2, ensure_ascii=False)
        
        logger.info(f"完整备份完成，总大小: {backup_info['total_size'] / 1024 / 1024:.2f} MB")
        return backup_info
    
    def create_incremental_backup(self, last_backup_time: datetime) -> Dict[str, Any]:
        """创建增量备份"""
        logger.info("开始创建增量备份...")
        backup_info = {
            "timestamp": datetime.now().isoformat(),
            "type": "incremental",
            "last_backup": last_backup_time.isoformat(),
            "databases": [],
            "directories": [],
            "total_size": 0
        }
        
        # 增量备份数据库（这里简化处理，实际应该使用binlog）
        for db_name in self.config["databases"]["mysql"]["databases"]:
            db_backup = self.create_database_backup(db_name)
            if db_backup:
                backup_info["databases"].append(str(db_backup))
                backup_info["total_size"] += db_backup.stat().st_size
        
        # 增量备份目录（只备份修改的文件）
        for directory in self.config["directories"]:
            dir_backup = self.create_incremental_directory_backup(directory, last_backup_time)
            if dir_backup:
                backup_info["directories"].append(str(dir_backup))
                backup_info["total_size"] += dir_backup.stat().st_size
        
        logger.info(f"增量备份完成，总大小: {backup_info['total_size'] / 1024 / 1024:.2f} MB")
        return backup_info
    
    def create_incremental_directory_backup(self, directory: str, last_backup_time: datetime) -> Optional[Path]:
        """创建增量目录备份"""
        try:
            source_path = Path(directory)
            if not source_path.exists():
                return None
            
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_filename = f"{source_path.name}_incremental_{timestamp}.tar.gz"
            backup_path = self.backup_dir / "directories" / backup_filename
            backup_path.parent.mkdir(parents=True, exist_ok=True)
            
            # 只备份修改时间晚于上次备份的文件
            modified_files = []
            for file_path in source_path.rglob("*"):
                if file_path.is_file() and file_path.stat().st_mtime > last_backup_time.timestamp():
                    modified_files.append(file_path)
            
            if not modified_files:
                logger.info(f"目录 {directory} 没有修改的文件")
                return None
            
            # 创建增量备份
            with tarfile.open(backup_path, "w:gz") as tar:
                for file_path in modified_files:
                    tar.add(file_path, arcname=file_path.relative_to(source_path.parent))
            
            logger.info(f"增量目录备份完成: {backup_path}")
            return backup_path
            
        except Exception as e:
            logger.error(f"增量目录备份失败: {e}")
            return None
    
    def restore_database(self, backup_path: Path, db_name: str) -> bool:
        """恢复数据库"""
        try:
            db_config = self.config["databases"]["mysql"]
            
            # 解压备份文件（如果需要）
            if backup_path.suffix == '.gz':
                temp_path = backup_path.with_suffix('')
                with gzip.open(backup_path, 'rb') as f_in:
                    with open(temp_path, 'wb') as f_out:
                        shutil.copyfileobj(f_in, f_out)
                backup_path = temp_path
            
            # 构建mysql恢复命令
            cmd = [
                "mysql",
                "-h", db_config["host"],
                "-P", str(db_config["port"]),
                "-u", db_config["user"],
                f"-p{db_config['password']}",
                db_name
            ]
            
            # 执行恢复
            with open(backup_path, 'r') as f:
                result = subprocess.run(cmd, stdin=f, stderr=subprocess.PIPE, text=True)
            
            if result.returncode != 0:
                logger.error(f"数据库恢复失败: {result.stderr}")
                return False
            
            logger.info(f"数据库恢复完成: {db_name}")
            return True
            
        except Exception as e:
            logger.error(f"数据库恢复失败: {e}")
            return False
    
    def restore_directory(self, backup_path: Path, target_directory: str) -> bool:
        """恢复目录"""
        try:
            target_path = Path(target_directory)
            target_path.mkdir(parents=True, exist_ok=True)
            
            # 解压备份文件
            with tarfile.open(backup_path, "r:gz") as tar:
                tar.extractall(target_path)
            
            logger.info(f"目录恢复完成: {target_directory}")
            return True
            
        except Exception as e:
            logger.error(f"目录恢复失败: {e}")
            return False
    
    def cleanup_old_backups(self):
        """清理旧备份"""
        try:
            retention_days = self.config.get("retention_days", 30)
            cutoff_date = datetime.now() - timedelta(days=retention_days)
            
            cleaned_count = 0
            cleaned_size = 0
            
            for backup_file in self.backup_dir.rglob("*"):
                if backup_file.is_file() and backup_file.stat().st_mtime < cutoff_date.timestamp():
                    file_size = backup_file.stat().st_size
                    backup_file.unlink()
                    cleaned_count += 1
                    cleaned_size += file_size
            
            logger.info(f"清理完成: 删除 {cleaned_count} 个文件，释放 {cleaned_size / 1024 / 1024:.2f} MB")
            
        except Exception as e:
            logger.error(f"清理旧备份失败: {e}")
    
    def list_backups(self) -> List[Dict[str, Any]]:
        """列出所有备份"""
        backups = []
        
        for backup_file in self.backup_dir.rglob("*"):
            if backup_file.is_file() and backup_file.suffix in ['.sql', '.tar.gz', '.gz']:
                stat = backup_file.stat()
                backups.append({
                    "path": str(backup_file),
                    "name": backup_file.name,
                    "size": stat.st_size,
                    "created": datetime.fromtimestamp(stat.st_ctime).isoformat(),
                    "modified": datetime.fromtimestamp(stat.st_mtime).isoformat()
                })
        
        return sorted(backups, key=lambda x: x["modified"], reverse=True)
    
    def compress_file(self, file_path: Path) -> Path:
        """压缩文件"""
        compressed_path = file_path.with_suffix(file_path.suffix + '.gz')
        
        with open(file_path, 'rb') as f_in:
            with gzip.open(compressed_path, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
        
        return compressed_path
    
    def _get_exclude_filter(self):
        """获取排除过滤器"""
        def exclude_filter(tarinfo):
            for pattern in self.config.get("exclude_patterns", []):
                if pattern in tarinfo.name:
                    return None
            return tarinfo
        
        return exclude_filter
    
    def send_notification(self, message: str, status: str = "info"):
        """发送通知"""
        if not self.config.get("notification", {}).get("enabled", False):
            return
        
        notification_config = self.config["notification"]
        
        # 发送邮件通知
        if notification_config.get("email"):
            self._send_email_notification(notification_config["email"], message, status)
        
        # 发送Webhook通知
        if notification_config.get("webhook"):
            self._send_webhook_notification(notification_config["webhook"], message, status)
    
    def _send_email_notification(self, email: str, message: str, status: str):
        """发送邮件通知"""
        # 这里应该实现邮件发送逻辑
        logger.info(f"发送邮件通知到 {email}: {message}")
    
    def _send_webhook_notification(self, webhook_url: str, message: str, status: str):
        """发送Webhook通知"""
        # 这里应该实现Webhook发送逻辑
        logger.info(f"发送Webhook通知到 {webhook_url}: {message}")

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="备份管理工具")
    parser.add_argument("--config", default="backup_config.json", help="配置文件路径")
    parser.add_argument("--backup", action="store_true", help="执行备份")
    parser.add_argument("--restore", help="恢复备份文件")
    parser.add_argument("--list", action="store_true", help="列出备份")
    parser.add_argument("--cleanup", action="store_true", help="清理旧备份")
    parser.add_argument("--incremental", action="store_true", help="增量备份")
    
    args = parser.parse_args()
    
    # 创建备份管理器
    backup_manager = BackupManager(args.config)
    
    try:
        if args.backup:
            if args.incremental:
                # 获取上次备份时间
                backups = backup_manager.list_backups()
                last_backup_time = datetime.now() - timedelta(days=1)  # 默认1天前
                if backups:
                    last_backup_time = datetime.fromisoformat(backups[0]["created"])
                
                backup_info = backup_manager.create_incremental_backup(last_backup_time)
            else:
                backup_info = backup_manager.create_full_backup()
            
            backup_manager.send_notification(f"备份完成: {backup_info['total_size'] / 1024 / 1024:.2f} MB", "success")
        
        elif args.restore:
            backup_path = Path(args.restore)
            if not backup_path.exists():
                logger.error(f"备份文件不存在: {backup_path}")
                sys.exit(1)
            
            # 根据文件类型选择恢复方法
            if backup_path.suffix == '.sql' or backup_path.suffix == '.gz':
                # 数据库恢复
                db_name = backup_manager.config["databases"]["mysql"]["databases"][0]
                success = backup_manager.restore_database(backup_path, db_name)
            else:
                # 目录恢复
                target_dir = "./restored"
                success = backup_manager.restore_directory(backup_path, target_dir)
            
            if success:
                backup_manager.send_notification(f"恢复完成: {backup_path}", "success")
            else:
                backup_manager.send_notification(f"恢复失败: {backup_path}", "error")
        
        elif args.list:
            backups = backup_manager.list_backups()
            print(f"找到 {len(backups)} 个备份文件:")
            for backup in backups:
                print(f"  {backup['name']} - {backup['size'] / 1024 / 1024:.2f} MB - {backup['created']}")
        
        elif args.cleanup:
            backup_manager.cleanup_old_backups()
            backup_manager.send_notification("旧备份清理完成", "info")
        
        else:
            parser.print_help()
    
    except Exception as e:
        logger.error(f"操作失败: {e}")
        backup_manager.send_notification(f"操作失败: {e}", "error")
        sys.exit(1)

if __name__ == "__main__":
    main()
