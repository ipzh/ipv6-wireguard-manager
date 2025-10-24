#!/usr/bin/env python3
"""
安全监控脚本
实时监控系统安全状态和异常活动
"""

import asyncio
import json
import time
from datetime import datetime, timedelta
from typing import Dict, List, Any
import argparse
import sys
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(project_root))

from backend.app.core.security_validator import security_validator
from backend.app.core.database_manager import db_manager
from backend.app.core.logging_manager import get_logger

logger = get_logger("security_monitor")

class SecurityMonitor:
    """安全监控器"""
    
    def __init__(self):
        self.logger = logger
        self.monitoring = False
        self.alerts = []
    
    async def start_monitoring(self, interval: int = 60):
        """开始安全监控"""
        self.monitoring = True
        self.logger.info("安全监控已启动", interval=interval)
        
        while self.monitoring:
            try:
                await self._check_security_status()
                await self._check_database_security()
                await self._check_system_security()
                await self._process_alerts()
                
                await asyncio.sleep(interval)
                
            except Exception as e:
                self.logger.error("安全监控错误", error=str(e))
                await asyncio.sleep(interval)
    
    def stop_monitoring(self):
        """停止安全监控"""
        self.monitoring = False
        self.logger.info("安全监控已停止")
    
    async def _check_security_status(self):
        """检查安全状态"""
        try:
            status = await security_validator.get_security_status()
            
            # 检查被阻止的IP数量
            if status["blocked_ips"] > 10:
                self._add_alert("HIGH", "大量IP被阻止", {
                    "blocked_ips": status["blocked_ips"]
                })
            
            # 检查速率限制
            if status["rate_limited_ips"] > 5:
                self._add_alert("MEDIUM", "多个IP触发速率限制", {
                    "rate_limited_ips": status["rate_limited_ips"]
                })
            
            # 检查失败登录尝试
            if status["failed_login_attempts"] > 20:
                self._add_alert("HIGH", "大量失败登录尝试", {
                    "failed_attempts": status["failed_login_attempts"]
                })
            
            self.logger.debug("安全状态检查完成", status=status)
            
        except Exception as e:
            self.logger.error("安全状态检查失败", error=str(e))
    
    async def _check_database_security(self):
        """检查数据库安全"""
        try:
            async with db_manager.get_session() as session:
                # 检查异常登录
                await self._check_anomalous_logins(session)
                
                # 检查权限变更
                await self._check_permission_changes(session)
                
                # 检查数据访问模式
                await self._check_data_access_patterns(session)
                
        except Exception as e:
            self.logger.error("数据库安全检查失败", error=str(e))
    
    async def _check_anomalous_logins(self, session):
        """检查异常登录"""
        # 检查短时间内多次登录
        query = """
            SELECT user_id, COUNT(*) as login_count, 
                   MIN(created_at) as first_login,
                   MAX(created_at) as last_login
            FROM audit_logs 
            WHERE action = 'login' AND created_at > NOW() - INTERVAL 1 HOUR
            GROUP BY user_id
            HAVING login_count > 10
        """
        
        # 这里需要根据实际的数据库表结构调整
        # result = await session.execute(text(query))
        # anomalous_logins = result.fetchall()
        
        # if anomalous_logins:
        #     self._add_alert("HIGH", "检测到异常登录模式", {
        #         "anomalous_logins": len(anomalous_logins)
        #     })
        pass
    
    async def _check_permission_changes(self, session):
        """检查权限变更"""
        # 检查权限变更
        query = """
            SELECT user_id, COUNT(*) as permission_changes
            FROM audit_logs 
            WHERE action = 'permission_change' AND created_at > NOW() - INTERVAL 24 HOUR
            GROUP BY user_id
            HAVING permission_changes > 5
        """
        
        # 这里需要根据实际的数据库表结构调整
        pass
    
    async def _check_data_access_patterns(self, session):
        """检查数据访问模式"""
        # 检查大量数据访问
        query = """
            SELECT user_id, COUNT(*) as data_access_count
            FROM audit_logs 
            WHERE action IN ('data_read', 'data_write') AND created_at > NOW() - INTERVAL 1 HOUR
            GROUP BY user_id
            HAVING data_access_count > 1000
        """
        
        # 这里需要根据实际的数据库表结构调整
        pass
    
    async def _check_system_security(self):
        """检查系统安全"""
        try:
            # 检查配置文件权限
            await self._check_config_file_permissions()
            
            # 检查日志文件
            await self._check_log_files()
            
            # 检查系统资源
            await self._check_system_resources()
            
        except Exception as e:
            self.logger.error("系统安全检查失败", error=str(e))
    
    async def _check_config_file_permissions(self):
        """检查配置文件权限"""
        import os
        
        config_files = [
            "env.local",
            ".env",
            "docker-compose.yml",
            "docker-compose.production.yml"
        ]
        
        for config_file in config_files:
            file_path = project_root / config_file
            if file_path.exists():
                # 检查文件权限
                stat = file_path.stat()
                if stat.st_mode & 0o077:  # 检查是否有其他用户权限
                    self._add_alert("MEDIUM", f"配置文件权限过松: {config_file}", {
                        "file": config_file,
                        "permissions": oct(stat.st_mode)
                    })
    
    async def _check_log_files(self):
        """检查日志文件"""
        log_dir = project_root / "logs"
        if log_dir.exists():
            # 检查日志文件大小
            for log_file in log_dir.glob("*.log"):
                if log_file.stat().st_size > 100 * 1024 * 1024:  # 100MB
                    self._add_alert("LOW", f"日志文件过大: {log_file.name}", {
                        "file": log_file.name,
                        "size_mb": log_file.stat().st_size / (1024 * 1024)
                    })
    
    async def _check_system_resources(self):
        """检查系统资源"""
        import psutil
        
        # 检查CPU使用率
        cpu_percent = psutil.cpu_percent(interval=1)
        if cpu_percent > 90:
            self._add_alert("HIGH", "CPU使用率过高", {
                "cpu_percent": cpu_percent
            })
        
        # 检查内存使用率
        memory = psutil.virtual_memory()
        if memory.percent > 90:
            self._add_alert("HIGH", "内存使用率过高", {
                "memory_percent": memory.percent
            })
        
        # 检查磁盘使用率
        disk = psutil.disk_usage('/')
        if disk.percent > 90:
            self._add_alert("MEDIUM", "磁盘使用率过高", {
                "disk_percent": disk.percent
            })
    
    def _add_alert(self, severity: str, message: str, details: Dict[str, Any]):
        """添加安全警报"""
        alert = {
            "timestamp": datetime.utcnow().isoformat(),
            "severity": severity,
            "message": message,
            "details": details
        }
        
        self.alerts.append(alert)
        
        # 记录警报
        if severity == "HIGH":
            self.logger.error("安全警报", alert=alert)
        elif severity == "MEDIUM":
            self.logger.warning("安全警告", alert=alert)
        else:
            self.logger.info("安全通知", alert=alert)
    
    async def _process_alerts(self):
        """处理警报"""
        if not self.alerts:
            return
        
        # 清理过期警报（24小时）
        cutoff_time = datetime.utcnow() - timedelta(hours=24)
        self.alerts = [
            alert for alert in self.alerts
            if datetime.fromisoformat(alert["timestamp"]) > cutoff_time
        ]
        
        # 统计警报
        high_alerts = [a for a in self.alerts if a["severity"] == "HIGH"]
        medium_alerts = [a for a in self.alerts if a["severity"] == "MEDIUM"]
        
        if high_alerts:
            self.logger.warning("当前高优先级警报", count=len(high_alerts))
        
        if medium_alerts:
            self.logger.info("当前中优先级警报", count=len(medium_alerts))
    
    def get_security_report(self) -> Dict[str, Any]:
        """获取安全报告"""
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "monitoring_status": "running" if self.monitoring else "stopped",
            "total_alerts": len(self.alerts),
            "high_priority_alerts": len([a for a in self.alerts if a["severity"] == "HIGH"]),
            "medium_priority_alerts": len([a for a in self.alerts if a["severity"] == "MEDIUM"]),
            "low_priority_alerts": len([a for a in self.alerts if a["severity"] == "LOW"]),
            "recent_alerts": self.alerts[-10:] if self.alerts else []
        }

async def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="安全监控工具")
    parser.add_argument("--interval", type=int, default=60, help="监控间隔（秒）")
    parser.add_argument("--duration", type=int, help="监控持续时间（秒）")
    parser.add_argument("--report", action="store_true", help="生成安全报告")
    parser.add_argument("--output", help="报告输出文件")
    
    args = parser.parse_args()
    
    try:
        # 初始化数据库连接
        await db_manager.initialize()
        
        monitor = SecurityMonitor()
        
        if args.report:
            # 生成安全报告
            report = monitor.get_security_report()
            
            if args.output:
                with open(args.output, 'w', encoding='utf-8') as f:
                    json.dump(report, f, indent=2, ensure_ascii=False)
                print(f"安全报告已保存到: {args.output}")
            else:
                print(json.dumps(report, indent=2, ensure_ascii=False))
        else:
            # 开始监控
            if args.duration:
                # 运行指定时间
                await asyncio.wait_for(
                    monitor.start_monitoring(args.interval),
                    timeout=args.duration
                )
            else:
                # 持续运行
                await monitor.start_monitoring(args.interval)
    
    except KeyboardInterrupt:
        print("\n监控已停止")
    except Exception as e:
        print(f"监控失败: {e}")
        sys.exit(1)
    finally:
        await db_manager.close()

if __name__ == "__main__":
    asyncio.run(main())
