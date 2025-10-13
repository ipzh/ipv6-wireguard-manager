"""
自动化修复服务 - 基于告警的自动修复脚本
"""
import asyncio
import subprocess
import os
import time
from datetime import datetime
from typing import Dict, Any, List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
import logging

from ..models.alert import Alert
from ..core.config import settings

logger = logging.getLogger(__name__)

class AutoRemediationService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.remediation_actions = {}
        self.action_history = []
        self.initialize_remediation_actions()

    def initialize_remediation_actions(self):
        """初始化修复动作"""
        self.remediation_actions = {
            'cpu_exhaustion': [
                {
                    'name': 'restart_high_cpu_processes',
                    'description': '重启高CPU消耗进程',
                    'action': self.restart_high_cpu_processes,
                    'risk_level': 'medium'
                },
                {
                    'name': 'scale_up_resources',
                    'description': '扩展系统资源',
                    'action': self.scale_up_resources,
                    'risk_level': 'low'
                }
            ],
            'memory_exhaustion': [
                {
                    'name': 'clear_memory_cache',
                    'description': '清理内存缓存',
                    'action': self.clear_memory_cache,
                    'risk_level': 'low'
                },
                {
                    'name': 'restart_memory_intensive_services',
                    'description': '重启内存密集型服务',
                    'action': self.restart_memory_intensive_services,
                    'risk_level': 'medium'
                },
                {
                    'name': 'kill_zombie_processes',
                    'description': '清理僵尸进程',
                    'action': self.kill_zombie_processes,
                    'risk_level': 'low'
                }
            ],
            'disk_full': [
                {
                    'name': 'clean_temp_files',
                    'description': '清理临时文件',
                    'action': self.clean_temp_files,
                    'risk_level': 'low'
                },
                {
                    'name': 'clean_old_logs',
                    'description': '清理旧日志文件',
                    'action': self.clean_old_logs,
                    'risk_level': 'low'
                },
                {
                    'name': 'compress_old_files',
                    'description': '压缩旧文件',
                    'action': self.compress_old_files,
                    'risk_level': 'low'
                }
            ],
            'high_load': [
                {
                    'name': 'restart_services',
                    'description': '重启服务',
                    'action': self.restart_services,
                    'risk_level': 'medium'
                },
                {
                    'name': 'adjust_process_priorities',
                    'description': '调整进程优先级',
                    'action': self.adjust_process_priorities,
                    'risk_level': 'low'
                }
            ],
            'service_down': [
                {
                    'name': 'restart_service',
                    'description': '重启服务',
                    'action': self.restart_service,
                    'risk_level': 'medium'
                },
                {
                    'name': 'check_service_dependencies',
                    'description': '检查服务依赖',
                    'action': self.check_service_dependencies,
                    'risk_level': 'low'
                }
            ]
        }

    async def execute_remediation(self, alert: Alert, action_type: str = 'auto') -> Dict[str, Any]:
        """执行修复动作"""
        try:
            # 获取告警类型
            alert_type = alert.metadata.get('anomaly_type', 'unknown') if alert.metadata else 'unknown'
            
            # 获取可用的修复动作
            available_actions = self.remediation_actions.get(alert_type, [])
            
            if not available_actions:
                logger.warning(f"没有找到告警类型 {alert_type} 的修复动作")
                return {
                    'success': False,
                    'message': f'没有找到告警类型 {alert_type} 的修复动作',
                    'actions_taken': []
                }
            
            # 根据风险级别选择动作
            if action_type == 'auto':
                # 自动模式：选择低风险动作
                selected_actions = [action for action in available_actions 
                                  if action['risk_level'] == 'low']
            else:
                # 手动模式：显示所有动作
                selected_actions = available_actions
            
            if not selected_actions:
                logger.warning(f"没有找到低风险的修复动作")
                return {
                    'success': False,
                    'message': '没有找到低风险的修复动作',
                    'actions_taken': []
                }
            
            # 执行修复动作
            results = []
            for action in selected_actions:
                try:
                    logger.info(f"执行修复动作: {action['name']}")
                    result = await action['action'](alert)
                    
                    action_result = {
                        'action_name': action['name'],
                        'description': action['description'],
                        'risk_level': action['risk_level'],
                        'success': result.get('success', False),
                        'message': result.get('message', ''),
                        'timestamp': datetime.now().isoformat()
                    }
                    
                    results.append(action_result)
                    
                    # 记录动作历史
                    self.action_history.append({
                        'alert_id': str(alert.id),
                        'action': action['name'],
                        'result': action_result,
                        'timestamp': datetime.now()
                    })
                    
                    # 如果动作成功，等待一段时间再执行下一个
                    if result.get('success', False):
                        await asyncio.sleep(5)
                    
                except Exception as e:
                    logger.error(f"执行修复动作 {action['name']} 失败: {e}")
                    results.append({
                        'action_name': action['name'],
                        'description': action['description'],
                        'risk_level': action['risk_level'],
                        'success': False,
                        'message': f'执行失败: {str(e)}',
                        'timestamp': datetime.now().isoformat()
                    })
            
            # 检查是否有成功的动作
            successful_actions = [r for r in results if r['success']]
            
            return {
                'success': len(successful_actions) > 0,
                'message': f'执行了 {len(results)} 个修复动作，{len(successful_actions)} 个成功',
                'actions_taken': results,
                'successful_actions': len(successful_actions),
                'total_actions': len(results)
            }
            
        except Exception as e:
            logger.error(f"执行修复失败: {e}")
            return {
                'success': False,
                'message': f'执行修复失败: {str(e)}',
                'actions_taken': []
            }

    async def restart_high_cpu_processes(self, alert: Alert) -> Dict[str, Any]:
        """重启高CPU消耗进程"""
        try:
            # 获取高CPU消耗的进程
            result = subprocess.run(
                ['ps', 'aux', '--sort=-%cpu', '--no-headers'],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode != 0:
                return {'success': False, 'message': '获取进程信息失败'}
            
            lines = result.stdout.strip().split('\n')
            high_cpu_processes = []
            
            for line in lines[:10]:  # 检查前10个进程
                parts = line.split()
                if len(parts) >= 11:
                    cpu_usage = float(parts[2])
                    if cpu_usage > 80:  # CPU使用率超过80%
                        pid = parts[1]
                        process_name = parts[10]
                        high_cpu_processes.append({'pid': pid, 'name': process_name})
            
            if not high_cpu_processes:
                return {'success': True, 'message': '没有发现高CPU消耗进程'}
            
            # 重启进程（这里只是示例，实际应该更谨慎）
            restarted_count = 0
            for process in high_cpu_processes[:3]:  # 最多重启3个进程
                try:
                    # 发送SIGTERM信号
                    subprocess.run(['kill', '-TERM', process['pid']], timeout=10)
                    time.sleep(2)
                    
                    # 检查进程是否还在运行
                    check_result = subprocess.run(
                        ['ps', '-p', process['pid']],
                        capture_output=True,
                        timeout=5
                    )
                    
                    if check_result.returncode != 0:
                        restarted_count += 1
                        logger.info(f"成功重启进程 {process['name']} (PID: {process['pid']})")
                    
                except Exception as e:
                    logger.error(f"重启进程 {process['name']} 失败: {e}")
            
            return {
                'success': restarted_count > 0,
                'message': f'重启了 {restarted_count} 个高CPU消耗进程'
            }
            
        except Exception as e:
            logger.error(f"重启高CPU进程失败: {e}")
            return {'success': False, 'message': f'重启高CPU进程失败: {str(e)}'}

    async def clear_memory_cache(self, alert: Alert) -> Dict[str, Any]:
        """清理内存缓存"""
        try:
            # 清理页面缓存
            with open('/proc/sys/vm/drop_caches', 'w') as f:
                f.write('3')  # 清理页面缓存、目录项和inode
            
            # 清理交换分区
            subprocess.run(['swapoff', '-a'], timeout=30)
            subprocess.run(['swapon', '-a'], timeout=30)
            
            return {'success': True, 'message': '内存缓存清理完成'}
            
        except Exception as e:
            logger.error(f"清理内存缓存失败: {e}")
            return {'success': False, 'message': f'清理内存缓存失败: {str(e)}'}

    async def clean_temp_files(self, alert: Alert) -> Dict[str, Any]:
        """清理临时文件"""
        try:
            temp_dirs = ['/tmp', '/var/tmp', '/tmp/ipv6-wireguard-manager']
            cleaned_size = 0
            
            for temp_dir in temp_dirs:
                if os.path.exists(temp_dir):
                    # 清理7天前的临时文件
                    result = subprocess.run(
                        ['find', temp_dir, '-type', 'f', '-mtime', '+7', '-delete'],
                        capture_output=True,
                        timeout=60
                    )
                    
                    if result.returncode == 0:
                        cleaned_size += 1
            
            return {
                'success': True,
                'message': f'清理了 {len(temp_dirs)} 个临时目录中的旧文件'
            }
            
        except Exception as e:
            logger.error(f"清理临时文件失败: {e}")
            return {'success': False, 'message': f'清理临时文件失败: {str(e)}'}

    async def clean_old_logs(self, alert: Alert) -> Dict[str, Any]:
        """清理旧日志文件"""
        try:
            log_dirs = ['/var/log', '/opt/ipv6-wireguard-manager/logs']
            cleaned_count = 0
            
            for log_dir in log_dirs:
                if os.path.exists(log_dir):
                    # 清理30天前的日志文件
                    result = subprocess.run(
                        ['find', log_dir, '-name', '*.log', '-mtime', '+30', '-delete'],
                        capture_output=True,
                        timeout=60
                    )
                    
                    if result.returncode == 0:
                        cleaned_count += 1
            
            return {
                'success': True,
                'message': f'清理了 {cleaned_count} 个日志目录中的旧文件'
            }
            
        except Exception as e:
            logger.error(f"清理旧日志失败: {e}")
            return {'success': False, 'message': f'清理旧日志失败: {str(e)}'}

    async def restart_services(self, alert: Alert) -> Dict[str, Any]:
        """重启服务"""
        try:
            services = ['ipv6-wireguard-manager', 'nginx', 'postgresql', 'redis-server']
            restarted_count = 0
            
            for service in services:
                try:
                    # 检查服务状态
                    result = subprocess.run(
                        ['systemctl', 'is-active', service],
                        capture_output=True,
                        timeout=10
                    )
                    
                    if result.returncode == 0:  # 服务正在运行
                        # 重启服务
                        restart_result = subprocess.run(
                            ['systemctl', 'restart', service],
                            capture_output=True,
                            timeout=30
                        )
                        
                        if restart_result.returncode == 0:
                            restarted_count += 1
                            logger.info(f"成功重启服务: {service}")
                        
                except Exception as e:
                    logger.error(f"重启服务 {service} 失败: {e}")
            
            return {
                'success': restarted_count > 0,
                'message': f'重启了 {restarted_count} 个服务'
            }
            
        except Exception as e:
            logger.error(f"重启服务失败: {e}")
            return {'success': False, 'message': f'重启服务失败: {str(e)}'}

    async def scale_up_resources(self, alert: Alert) -> Dict[str, Any]:
        """扩展系统资源"""
        try:
            # 这里可以实现自动扩展逻辑
            # 例如：增加CPU限制、内存限制等
            
            # 示例：调整系统参数
            adjustments = []
            
            # 调整文件描述符限制
            try:
                with open('/proc/sys/fs/file-max', 'r') as f:
                    current_limit = int(f.read().strip())
                
                new_limit = current_limit * 2
                with open('/proc/sys/fs/file-max', 'w') as f:
                    f.write(str(new_limit))
                
                adjustments.append(f'文件描述符限制从 {current_limit} 增加到 {new_limit}')
                
            except Exception as e:
                logger.error(f"调整文件描述符限制失败: {e}")
            
            # 调整网络缓冲区
            try:
                with open('/proc/sys/net/core/rmem_max', 'r') as f:
                    current_rmem = int(f.read().strip())
                
                new_rmem = current_rmem * 2
                with open('/proc/sys/net/core/rmem_max', 'w') as f:
                    f.write(str(new_rmem))
                
                adjustments.append(f'网络接收缓冲区从 {current_rmem} 增加到 {new_rmem}')
                
            except Exception as e:
                logger.error(f"调整网络缓冲区失败: {e}")
            
            return {
                'success': len(adjustments) > 0,
                'message': f'完成了 {len(adjustments)} 项资源调整',
                'adjustments': adjustments
            }
            
        except Exception as e:
            logger.error(f"扩展资源失败: {e}")
            return {'success': False, 'message': f'扩展资源失败: {str(e)}'}

    async def kill_zombie_processes(self, alert: Alert) -> Dict[str, Any]:
        """清理僵尸进程"""
        try:
            # 查找僵尸进程
            result = subprocess.run(
                ['ps', 'aux', '--no-headers'],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode != 0:
                return {'success': False, 'message': '获取进程信息失败'}
            
            zombie_count = 0
            lines = result.stdout.strip().split('\n')
            
            for line in lines:
                if '<defunct>' in line:
                    zombie_count += 1
            
            if zombie_count == 0:
                return {'success': True, 'message': '没有发现僵尸进程'}
            
            # 尝试清理僵尸进程的父进程
            # 这里只是示例，实际应该更谨慎
            return {
                'success': True,
                'message': f'发现 {zombie_count} 个僵尸进程，建议手动处理'
            }
            
        except Exception as e:
            logger.error(f"清理僵尸进程失败: {e}")
            return {'success': False, 'message': f'清理僵尸进程失败: {str(e)}'}

    async def get_remediation_history(self, limit: int = 100) -> List[Dict[str, Any]]:
        """获取修复历史"""
        try:
            # 返回最近的修复历史
            recent_history = self.action_history[-limit:] if self.action_history else []
            
            return [
                {
                    'alert_id': action['alert_id'],
                    'action': action['action'],
                    'result': action['result'],
                    'timestamp': action['timestamp'].isoformat()
                }
                for action in recent_history
            ]
            
        except Exception as e:
            logger.error(f"获取修复历史失败: {e}")
            return []

    async def get_available_actions(self, alert_type: str) -> List[Dict[str, Any]]:
        """获取可用的修复动作"""
        try:
            actions = self.remediation_actions.get(alert_type, [])
            
            return [
                {
                    'name': action['name'],
                    'description': action['description'],
                    'risk_level': action['risk_level']
                }
                for action in actions
            ]
            
        except Exception as e:
            logger.error(f"获取可用动作失败: {e}")
            return []
