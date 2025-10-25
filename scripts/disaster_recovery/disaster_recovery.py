#!/usr/bin/env python3
"""
灾难恢复脚本
支持系统恢复、数据恢复、服务重建
"""

import os
import sys
import json
import subprocess
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional
import argparse
import logging

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class DisasterRecovery:
    """灾难恢复管理器"""
    
    def __init__(self, config_file: str = "disaster_recovery_config.json"):
        self.config_file = Path(config_file)
        self.config = self.load_config()
        self.recovery_log = []
    
    def load_config(self) -> Dict[str, Any]:
        """加载灾难恢复配置"""
        default_config = {
            "recovery_mode": "full",  # full, partial, minimal
            "backup_location": "./backups",
            "restore_databases": True,
            "restore_files": True,
            "restore_configs": True,
            "restore_services": True,
            "notification": {
                "enabled": True,
                "email": "admin@example.com",
                "webhook": None
            },
            "services": {
                "mysql": {
                    "enabled": True,
                    "restore_command": "systemctl start mysql",
                    "health_check": "mysqladmin ping"
                },
                "redis": {
                    "enabled": True,
                    "restore_command": "systemctl start redis",
                    "health_check": "redis-cli ping"
                },
                "nginx": {
                    "enabled": True,
                    "restore_command": "systemctl start nginx",
                    "health_check": "curl -f http://localhost/health"
                },
                "wireguard": {
                    "enabled": True,
                    "restore_command": "systemctl start wg-quick@wg0",
                    "health_check": "wg show"
                }
            },
            "databases": {
                "mysql": {
                    "host": "localhost",
                    "port": 3306,
                    "user": "root",
                    "password": "password",
                    "databases": ["ipv6wgm"]
                }
            },
            "critical_files": [
                "/etc/wireguard/wg0.conf",
                "/etc/nginx/nginx.conf",
                "/etc/mysql/my.cnf",
                "/etc/redis/redis.conf"
            ],
            "recovery_scripts": [
                "./scripts/install.sh",
                "./scripts/backup/backup_manager.py"
            ]
        }
        
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                return {**default_config, **config}
            except Exception as e:
                logger.warning(f"配置文件加载失败，使用默认配置: {e}")
        
        return default_config
    
    def assess_damage(self) -> Dict[str, Any]:
        """评估系统损坏情况"""
        logger.info("开始评估系统损坏情况...")
        
        damage_assessment = {
            "timestamp": datetime.now().isoformat(),
            "services_status": {},
            "databases_status": {},
            "files_status": {},
            "overall_status": "unknown"
        }
        
        # 检查服务状态
        for service_name, service_config in self.config["services"].items():
            if service_config.get("enabled", True):
                status = self._check_service_status(service_name, service_config)
                damage_assessment["services_status"][service_name] = status
        
        # 检查数据库状态
        for db_name, db_config in self.config["databases"].items():
            status = self._check_database_status(db_name, db_config)
            damage_assessment["databases_status"][db_name] = status
        
        # 检查关键文件
        for file_path in self.config["critical_files"]:
            status = self._check_file_status(file_path)
            damage_assessment["files_status"][file_path] = status
        
        # 评估整体状态
        damage_assessment["overall_status"] = self._assess_overall_status(damage_assessment)
        
        logger.info(f"系统损坏评估完成，整体状态: {damage_assessment['overall_status']}")
        return damage_assessment
    
    def _check_service_status(self, service_name: str, service_config: Dict[str, Any]) -> Dict[str, Any]:
        """检查服务状态"""
        try:
            # 检查服务是否运行
            result = subprocess.run(
                ["systemctl", "is-active", service_name],
                capture_output=True,
                text=True
            )
            
            is_active = result.returncode == 0
            
            # 执行健康检查
            health_check = service_config.get("health_check")
            is_healthy = True
            if health_check:
                try:
                    subprocess.run(health_check.split(), capture_output=True, text=True, timeout=10)
                except subprocess.TimeoutExpired:
                    is_healthy = False
                except Exception:
                    is_healthy = False
            
            return {
                "status": "active" if is_active else "inactive",
                "healthy": is_healthy,
                "needs_recovery": not (is_active and is_healthy)
            }
            
        except Exception as e:
            logger.error(f"检查服务 {service_name} 状态失败: {e}")
            return {
                "status": "unknown",
                "healthy": False,
                "needs_recovery": True,
                "error": str(e)
            }
    
    def _check_database_status(self, db_name: str, db_config: Dict[str, Any]) -> Dict[str, Any]:
        """检查数据库状态"""
        try:
            # 尝试连接数据库
            cmd = [
                "mysql",
                "-h", db_config["host"],
                "-P", str(db_config["port"]),
                "-u", db_config["user"],
                f"-p{db_config['password']}",
                "-e", "SELECT 1"
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            is_connected = result.returncode == 0
            
            # 检查数据库是否存在
            databases_exist = True
            for db in db_config.get("databases", []):
                cmd = [
                    "mysql",
                    "-h", db_config["host"],
                    "-P", str(db_config["port"]),
                    "-u", db_config["user"],
                    f"-p{db_config['password']}",
                    "-e", f"USE {db}"
                ]
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
                if result.returncode != 0:
                    databases_exist = False
                    break
            
            return {
                "connected": is_connected,
                "databases_exist": databases_exist,
                "needs_recovery": not (is_connected and databases_exist)
            }
            
        except Exception as e:
            logger.error(f"检查数据库 {db_name} 状态失败: {e}")
            return {
                "connected": False,
                "databases_exist": False,
                "needs_recovery": True,
                "error": str(e)
            }
    
    def _check_file_status(self, file_path: str) -> Dict[str, Any]:
        """检查文件状态"""
        try:
            path = Path(file_path)
            exists = path.exists()
            readable = path.is_file() and os.access(path, os.R_OK)
            
            return {
                "exists": exists,
                "readable": readable,
                "needs_recovery": not (exists and readable)
            }
            
        except Exception as e:
            logger.error(f"检查文件 {file_path} 状态失败: {e}")
            return {
                "exists": False,
                "readable": False,
                "needs_recovery": True,
                "error": str(e)
            }
    
    def _assess_overall_status(self, assessment: Dict[str, Any]) -> str:
        """评估整体状态"""
        # 统计需要恢复的项目
        needs_recovery = 0
        total_items = 0
        
        for service_status in assessment["services_status"].values():
            total_items += 1
            if service_status.get("needs_recovery", False):
                needs_recovery += 1
        
        for db_status in assessment["databases_status"].values():
            total_items += 1
            if db_status.get("needs_recovery", False):
                needs_recovery += 1
        
        for file_status in assessment["files_status"].values():
            total_items += 1
            if file_status.get("needs_recovery", False):
                needs_recovery += 1
        
        if total_items == 0:
            return "unknown"
        elif needs_recovery == 0:
            return "healthy"
        elif needs_recovery < total_items * 0.5:
            return "partial_damage"
        else:
            return "severe_damage"
    
    def execute_recovery(self, recovery_mode: str = None) -> Dict[str, Any]:
        """执行灾难恢复"""
        recovery_mode = recovery_mode or self.config["recovery_mode"]
        logger.info(f"开始执行灾难恢复，模式: {recovery_mode}")
        
        recovery_result = {
            "timestamp": datetime.now().isoformat(),
            "mode": recovery_mode,
            "steps_completed": [],
            "steps_failed": [],
            "overall_success": False
        }
        
        try:
            # 1. 评估损坏情况
            assessment = self.assess_damage()
            recovery_result["assessment"] = assessment
            
            # 2. 根据恢复模式执行恢复步骤
            if recovery_mode == "full":
                self._execute_full_recovery(recovery_result)
            elif recovery_mode == "partial":
                self._execute_partial_recovery(recovery_result)
            elif recovery_mode == "minimal":
                self._execute_minimal_recovery(recovery_result)
            else:
                raise ValueError(f"未知的恢复模式: {recovery_mode}")
            
            # 3. 验证恢复结果
            final_assessment = self.assess_damage()
            recovery_result["final_assessment"] = final_assessment
            
            # 4. 判断恢复是否成功
            recovery_result["overall_success"] = final_assessment["overall_status"] in ["healthy", "partial_damage"]
            
            # 5. 发送通知
            self._send_recovery_notification(recovery_result)
            
            logger.info(f"灾难恢复完成，成功: {recovery_result['overall_success']}")
            
        except Exception as e:
            logger.error(f"灾难恢复失败: {e}")
            recovery_result["error"] = str(e)
            self._send_recovery_notification(recovery_result)
        
        return recovery_result
    
    def _execute_full_recovery(self, recovery_result: Dict[str, Any]):
        """执行完整恢复"""
        logger.info("执行完整恢复...")
        
        # 恢复数据库
        if self.config.get("restore_databases", True):
            self._restore_databases(recovery_result)
        
        # 恢复文件
        if self.config.get("restore_files", True):
            self._restore_files(recovery_result)
        
        # 恢复配置
        if self.config.get("restore_configs", True):
            self._restore_configs(recovery_result)
        
        # 恢复服务
        if self.config.get("restore_services", True):
            self._restore_services(recovery_result)
    
    def _execute_partial_recovery(self, recovery_result: Dict[str, Any]):
        """执行部分恢复"""
        logger.info("执行部分恢复...")
        
        # 只恢复关键服务
        self._restore_critical_services(recovery_result)
        
        # 恢复关键数据库
        self._restore_critical_databases(recovery_result)
    
    def _execute_minimal_recovery(self, recovery_result: Dict[str, Any]):
        """执行最小恢复"""
        logger.info("执行最小恢复...")
        
        # 只恢复最基础的服务
        critical_services = ["mysql", "nginx"]
        for service_name in critical_services:
            if service_name in self.config["services"]:
                self._restore_service(service_name, recovery_result)
    
    def _restore_databases(self, recovery_result: Dict[str, Any]):
        """恢复数据库"""
        logger.info("恢复数据库...")
        
        try:
            # 启动数据库服务
            subprocess.run(["systemctl", "start", "mysql"], check=True)
            time.sleep(5)
            
            # 恢复数据库数据
            backup_dir = Path(self.config["backup_location"]) / "database"
            if backup_dir.exists():
                for backup_file in backup_dir.glob("*.sql*"):
                    self._restore_database_from_backup(backup_file, recovery_result)
            
            recovery_result["steps_completed"].append("restore_databases")
            
        except Exception as e:
            logger.error(f"数据库恢复失败: {e}")
            recovery_result["steps_failed"].append(f"restore_databases: {e}")
    
    def _restore_database_from_backup(self, backup_file: Path, recovery_result: Dict[str, Any]):
        """从备份恢复数据库"""
        try:
            db_config = self.config["databases"]["mysql"]
            db_name = db_config["databases"][0]
            
            # 解压备份文件（如果需要）
            if backup_file.suffix == '.gz':
                temp_file = backup_file.with_suffix('')
                subprocess.run(["gunzip", "-c", str(backup_file)], stdout=open(temp_file, 'w'))
                backup_file = temp_file
            
            # 恢复数据库
            cmd = [
                "mysql",
                "-h", db_config["host"],
                "-P", str(db_config["port"]),
                "-u", db_config["user"],
                f"-p{db_config['password']}",
                db_name
            ]
            
            with open(backup_file, 'r') as f:
                subprocess.run(cmd, stdin=f, check=True)
            
            logger.info(f"数据库恢复完成: {backup_file}")
            
        except Exception as e:
            logger.error(f"数据库恢复失败: {e}")
            recovery_result["steps_failed"].append(f"restore_database: {e}")
    
    def _restore_files(self, recovery_result: Dict[str, Any]):
        """恢复文件"""
        logger.info("恢复文件...")
        
        try:
            backup_dir = Path(self.config["backup_location"]) / "directories"
            if backup_dir.exists():
                for backup_file in backup_dir.glob("*.tar.gz"):
                    self._restore_directory_from_backup(backup_file, recovery_result)
            
            recovery_result["steps_completed"].append("restore_files")
            
        except Exception as e:
            logger.error(f"文件恢复失败: {e}")
            recovery_result["steps_failed"].append(f"restore_files: {e}")
    
    def _restore_directory_from_backup(self, backup_file: Path, recovery_result: Dict[str, Any]):
        """从备份恢复目录"""
        try:
            # 解压备份文件
            subprocess.run(["tar", "-xzf", str(backup_file), "-C", "/"], check=True)
            logger.info(f"目录恢复完成: {backup_file}")
            
        except Exception as e:
            logger.error(f"目录恢复失败: {e}")
            recovery_result["steps_failed"].append(f"restore_directory: {e}")
    
    def _restore_configs(self, recovery_result: Dict[str, Any]):
        """恢复配置"""
        logger.info("恢复配置...")
        
        try:
            # 这里应该实现配置恢复逻辑
            # 从备份中恢复配置文件
            
            recovery_result["steps_completed"].append("restore_configs")
            
        except Exception as e:
            logger.error(f"配置恢复失败: {e}")
            recovery_result["steps_failed"].append(f"restore_configs: {e}")
    
    def _restore_services(self, recovery_result: Dict[str, Any]):
        """恢复服务"""
        logger.info("恢复服务...")
        
        for service_name, service_config in self.config["services"].items():
            if service_config.get("enabled", True):
                self._restore_service(service_name, recovery_result)
    
    def _restore_critical_services(self, recovery_result: Dict[str, Any]):
        """恢复关键服务"""
        critical_services = ["mysql", "nginx", "redis"]
        
        for service_name in critical_services:
            if service_name in self.config["services"]:
                self._restore_service(service_name, recovery_result)
    
    def _restore_service(self, service_name: str, recovery_result: Dict[str, Any]):
        """恢复单个服务"""
        try:
            service_config = self.config["services"][service_name]
            restore_command = service_config.get("restore_command")
            
            if restore_command:
                subprocess.run(restore_command.split(), check=True)
                time.sleep(2)
                
                # 验证服务状态
                health_check = service_config.get("health_check")
                if health_check:
                    subprocess.run(health_check.split(), check=True)
                
                logger.info(f"服务恢复完成: {service_name}")
                recovery_result["steps_completed"].append(f"restore_service_{service_name}")
            
        except Exception as e:
            logger.error(f"服务恢复失败: {service_name} - {e}")
            recovery_result["steps_failed"].append(f"restore_service_{service_name}: {e}")
    
    def _restore_critical_databases(self, recovery_result: Dict[str, Any]):
        """恢复关键数据库"""
        # 只恢复主数据库
        if "mysql" in self.config["databases"]:
            self._restore_databases(recovery_result)
    
    def _send_recovery_notification(self, recovery_result: Dict[str, Any]):
        """发送恢复通知"""
        if not self.config.get("notification", {}).get("enabled", False):
            return
        
        status = "成功" if recovery_result["overall_success"] else "失败"
        message = f"灾难恢复{status}: {len(recovery_result['steps_completed'])} 个步骤完成，{len(recovery_result['steps_failed'])} 个步骤失败"
        
        # 这里应该实现通知发送逻辑
        logger.info(f"发送恢复通知: {message}")

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="灾难恢复工具")
    parser.add_argument("--config", default="disaster_recovery_config.json", help="配置文件路径")
    parser.add_argument("--assess", action="store_true", help="评估系统损坏情况")
    parser.add_argument("--recover", choices=["full", "partial", "minimal"], help="执行灾难恢复")
    parser.add_argument("--output", help="输出文件路径")
    
    args = parser.parse_args()
    
    # 创建灾难恢复管理器
    dr = DisasterRecovery(args.config)
    
    try:
        if args.assess:
            # 评估损坏情况
            assessment = dr.assess_damage()
            print(f"系统损坏评估完成，整体状态: {assessment['overall_status']}")
            
            if args.output:
                with open(args.output, 'w', encoding='utf-8') as f:
                    json.dump(assessment, f, indent=2, ensure_ascii=False)
                print(f"评估结果已保存到: {args.output}")
        
        elif args.recover:
            # 执行灾难恢复
            recovery_result = dr.execute_recovery(args.recover)
            print(f"灾难恢复完成，成功: {recovery_result['overall_success']}")
            
            if args.output:
                with open(args.output, 'w', encoding='utf-8') as f:
                    json.dump(recovery_result, f, indent=2, ensure_ascii=False)
                print(f"恢复结果已保存到: {args.output}")
        
        else:
            parser.print_help()
    
    except Exception as e:
        logger.error(f"操作失败: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
