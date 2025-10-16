import uuid
import subprocess
import psutil
import json
from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from ..models.network import NetworkInterface, FirewallRule
from ..schemas.network import (
    NetworkInterfaceCreate, NetworkInterfaceUpdate,
    FirewallRuleCreate, FirewallRuleUpdate,
    NetworkStatus, InterfaceStats
)
import logging

logger = logging.getLogger(__name__)

class NetworkService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_interfaces(self) -> List[NetworkInterface]:
        """获取所有网络接口"""
        result = await self.db.execute(select(NetworkInterface))
        return result.scalars().all()

    async def get_interface_by_id(self, interface_id: uuid.UUID) -> Optional[NetworkInterface]:
        """根据ID获取网络接口"""
        result = await self.db.execute(
            select(NetworkInterface).where(NetworkInterface.id == interface_id)
        )
        return result.scalars().first()

    async def create_interface(self, interface_in: NetworkInterfaceCreate) -> NetworkInterface:
        """创建网络接口记录"""
        try:
            interface = NetworkInterface(**interface_in.model_dump())
            self.db.add(interface)
            await self.db.commit()
            await self.db.refresh(interface)
            return interface
        except Exception as e:
            await self.db.rollback()
            logger.error(f"创建网络接口失败: {e}")
            raise

    async def update_interface(self, interface: NetworkInterface, interface_in: NetworkInterfaceUpdate) -> NetworkInterface:
        """更新网络接口"""
        try:
            update_data = interface_in.model_dump(exclude_unset=True)
            for field, value in update_data.items():
                setattr(interface, field, value)
            
            await self.db.commit()
            await self.db.refresh(interface)
            return interface
        except Exception as e:
            await self.db.rollback()
            logger.error(f"更新网络接口失败: {e}")
            raise

    async def delete_interface(self, interface: NetworkInterface):
        """删除网络接口记录"""
        try:
            await self.db.delete(interface)
            await self.db.commit()
        except Exception as e:
            await self.db.rollback()
            logger.error(f"删除网络接口失败: {e}")
            raise

    async def get_interface_stats(self, interface_name: str) -> Optional[InterfaceStats]:
        """获取网络接口统计信息"""
        try:
            net_io = psutil.net_io_counters(pernic=True)
            if interface_name in net_io:
                stats = net_io[interface_name]
                return InterfaceStats(
                    interface=interface_name,
                    rx_bytes=stats.bytes_recv,
                    tx_bytes=stats.bytes_sent,
                    rx_packets=stats.packets_recv,
                    tx_packets=stats.packets_sent,
                    rx_errors=stats.errin,
                    tx_errors=stats.errout
                )
            return None
        except Exception as e:
            logger.error(f"获取接口统计信息失败: {e}")
            return None

    async def get_system_interfaces(self) -> List[Dict[str, Any]]:
        """获取系统网络接口信息"""
        try:
            interfaces = []
            net_if_addrs = psutil.net_if_addrs()
            net_if_stats = psutil.net_if_stats()
            
            for interface_name, addresses in net_if_addrs.items():
                interface_info = {
                    "name": interface_name,
                    "addresses": [],
                    "is_up": net_if_stats[interface_name].isup if interface_name in net_if_stats else False,
                    "mtu": net_if_stats[interface_name].mtu if interface_name in net_if_stats else None
                }
                
                for addr in addresses:
                    interface_info["addresses"].append({
                        "family": str(addr.family),
                        "address": addr.address,
                        "netmask": addr.netmask,
                        "broadcast": addr.broadcast
                    })
                
                interfaces.append(interface_info)
            
            return interfaces
        except Exception as e:
            logger.error(f"获取系统接口信息失败: {e}")
            return []

    # 防火墙规则管理
    async def get_firewall_rules(self) -> List[FirewallRule]:
        """获取所有防火墙规则"""
        result = await self.db.execute(select(FirewallRule))
        return result.scalars().all()

    async def get_firewall_rule_by_id(self, rule_id: uuid.UUID) -> Optional[FirewallRule]:
        """根据ID获取防火墙规则"""
        result = await self.db.execute(
            select(FirewallRule).where(FirewallRule.id == rule_id)
        )
        return result.scalars().first()

    async def create_firewall_rule(self, rule_in: FirewallRuleCreate) -> FirewallRule:
        """创建防火墙规则"""
        try:
            rule = FirewallRule(**rule_in.model_dump())
            self.db.add(rule)
            await self.db.commit()
            await self.db.refresh(rule)
            
            # 应用防火墙规则
            await self.apply_firewall_rule(rule)
            
            return rule
        except Exception as e:
            await self.db.rollback()
            logger.error(f"创建防火墙规则失败: {e}")
            raise

    async def update_firewall_rule(self, rule: FirewallRule, rule_in: FirewallRuleUpdate) -> FirewallRule:
        """更新防火墙规则"""
        try:
            # 先删除旧规则
            await self.remove_firewall_rule(rule)
            
            update_data = rule_in.model_dump(exclude_unset=True)
            for field, value in update_data.items():
                setattr(rule, field, value)
            
            await self.db.commit()
            await self.db.refresh(rule)
            
            # 应用新规则
            await self.apply_firewall_rule(rule)
            
            return rule
        except Exception as e:
            await self.db.rollback()
            logger.error(f"更新防火墙规则失败: {e}")
            raise

    async def delete_firewall_rule(self, rule: FirewallRule):
        """删除防火墙规则"""
        try:
            # 删除系统规则
            await self.remove_firewall_rule(rule)
            
            # 删除数据库记录
            await self.db.delete(rule)
            await self.db.commit()
        except Exception as e:
            await self.db.rollback()
            logger.error(f"删除防火墙规则失败: {e}")
            raise

    async def apply_firewall_rule(self, rule: FirewallRule) -> bool:
        """应用防火墙规则到系统"""
        try:
            if not rule.is_active:
                return True
            
            # 构建iptables命令
            cmd = self.build_iptables_command(rule)
            if not cmd:
                return False
            
            # 执行命令
            result = subprocess.run(cmd, capture_output=True, text=True, shell=True)
            
            if result.returncode == 0:
                logger.info(f"防火墙规则应用成功: {rule.name}")
                return True
            else:
                logger.error(f"防火墙规则应用失败: {result.stderr}")
                return False
        except Exception as e:
            logger.error(f"应用防火墙规则异常: {e}")
            return False

    async def remove_firewall_rule(self, rule: FirewallRule) -> bool:
        """从系统删除防火墙规则"""
        try:
            # 构建删除命令
            cmd = self.build_iptables_delete_command(rule)
            if not cmd:
                return True
            
            # 执行命令
            result = subprocess.run(cmd, capture_output=True, text=True, shell=True)
            
            if result.returncode == 0:
                logger.info(f"防火墙规则删除成功: {rule.name}")
                return True
            else:
                logger.warning(f"防火墙规则删除失败: {result.stderr}")
                return False
        except Exception as e:
            logger.error(f"删除防火墙规则异常: {e}")
            return False

    def build_iptables_command(self, rule: FirewallRule) -> Optional[str]:
        """构建iptables命令"""
        try:
            # 基础命令
            cmd_parts = ["iptables", "-t", rule.table_name]
            
            # 根据动作确定命令类型
            if rule.action in ["ACCEPT", "DROP", "REJECT"]:
                cmd_parts.extend(["-A", rule.chain_name])
            elif rule.action in ["MASQUERADE", "SNAT", "DNAT"]:
                cmd_parts.extend(["-A", rule.chain_name])
            else:
                logger.error(f"不支持的防火墙动作: {rule.action}")
                return None
            
            # 添加规则规格
            if rule.rule_spec:
                cmd_parts.extend(rule.rule_spec.split())
            
            # 添加动作
            cmd_parts.extend(["-j", rule.action])
            
            return " ".join(cmd_parts)
        except Exception as e:
            logger.error(f"构建iptables命令失败: {e}")
            return None

    def build_iptables_delete_command(self, rule: FirewallRule) -> Optional[str]:
        """构建iptables删除命令"""
        try:
            # 基础命令
            cmd_parts = ["iptables", "-t", rule.table_name, "-D", rule.chain_name]
            
            # 添加规则规格
            if rule.rule_spec:
                cmd_parts.extend(rule.rule_spec.split())
            
            # 添加动作
            cmd_parts.extend(["-j", rule.action])
            
            return " ".join(cmd_parts)
        except Exception as e:
            logger.error(f"构建iptables删除命令失败: {e}")
            return None

    async def get_network_status(self) -> NetworkStatus:
        """获取网络状态"""
        try:
            # 获取接口信息
            interfaces = await self.get_interfaces()
            
            # 获取防火墙规则
            firewall_rules = await self.get_firewall_rules()
            
            # 获取路由表
            routing_table = await self.get_routing_table()
            
            return NetworkStatus(
                interfaces=interfaces,
                firewall_rules=firewall_rules,
                routing_table=routing_table
            )
        except Exception as e:
            logger.error(f"获取网络状态失败: {e}")
            raise

    async def get_routing_table(self) -> List[Dict[str, Any]]:
        """获取路由表"""
        try:
            routes = []
            result = subprocess.run(["ip", "route", "show"], capture_output=True, text=True)
            
            if result.returncode == 0:
                for line in result.stdout.strip().split('\n'):
                    if line:
                        route_info = self.parse_route_line(line)
                        if route_info:
                            routes.append(route_info)
            
            return routes
        except Exception as e:
            logger.error(f"获取路由表失败: {e}")
            return []

    def parse_route_line(self, line: str) -> Optional[Dict[str, Any]]:
        """解析路由行"""
        try:
            parts = line.split()
            route_info = {
                "destination": "",
                "gateway": "",
                "interface": "",
                "metric": None
            }
            
            i = 0
            while i < len(parts):
                if parts[i] == "via":
                    if i + 1 < len(parts):
                        route_info["gateway"] = parts[i + 1]
                        i += 2
                elif parts[i] == "dev":
                    if i + 1 < len(parts):
                        route_info["interface"] = parts[i + 1]
                        i += 2
                elif parts[i] == "metric":
                    if i + 1 < len(parts):
                        route_info["metric"] = int(parts[i + 1])
                        i += 2
                else:
                    if not route_info["destination"]:
                        route_info["destination"] = parts[i]
                    i += 1
            
            return route_info
        except Exception as e:
            logger.error(f"解析路由行失败: {e}")
            return None

    async def reload_firewall_rules(self) -> bool:
        """重新加载所有防火墙规则"""
        try:
            # 清空现有规则
            subprocess.run(["iptables", "-F"], capture_output=True)
            subprocess.run(["iptables", "-t", "nat", "-F"], capture_output=True)
            subprocess.run(["iptables", "-t", "mangle", "-F"], capture_output=True)
            
            # 重新应用所有规则
            rules = await self.get_firewall_rules()
            for rule in rules:
                if rule.is_active:
                    await self.apply_firewall_rule(rule)
            
            logger.info("防火墙规则重新加载完成")
            return True
        except Exception as e:
            logger.error(f"重新加载防火墙规则失败: {e}")
            return False
