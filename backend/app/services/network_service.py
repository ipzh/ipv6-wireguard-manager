import uuid
import subprocess
import psutil
import json
import re
from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from ..models.network import NetworkInterface, FirewallRule
from ..schemas.network import (
    NetworkInterfaceCreate, NetworkInterfaceUpdate,
    FirewallRuleCreate, FirewallRuleUpdate,
    NetworkStatus, InterfaceStats
)
from ..core.logging import get_logger

logger = get_logger(__name__)

class NetworkService:
    def __init__(self, db: AsyncSession):
        self.db = db
        
        # 安全的防火墙参数白名单
        self.allowed_tables = {"filter", "nat", "mangle", "raw"}
        self.allowed_chains = {"INPUT", "OUTPUT", "FORWARD", "PREROUTING", "POSTROUTING"}
        self.allowed_actions = {"ACCEPT", "DROP", "REJECT", "MASQUERADE", "SNAT", "DNAT"}
        self.allowed_protocols = {"tcp", "udp", "icmp", "all"}
        
        # 安全的规则参数模式
        self.safe_patterns = {
            "protocol": r"^-p\s+(tcp|udp|icmp|all)$",
            "source": r"^-s\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?:/\d{1,2})?)$",
            "destination": r"^-d\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?:/\d{1,2})?)$",
            "source_port": r"^--sport\s+(\d{1,5}(?:-\d{1,5})?)$",
            "destination_port": r"^--dport\s+(\d{1,5}(?:-\d{1,5})?)$",
            "interface_in": r"^-i\s+([a-zA-Z0-9_-]+)$",
            "interface_out": r"^-o\s+([a-zA-Z0-9_-]+)$",
            "state": r"^--state\s+(NEW|ESTABLISHED|RELATED|INVALID)$"
        }

    def validate_firewall_parameters(self, table_name: str, chain_name: str, action: str, rule_spec: str) -> bool:
        """验证防火墙参数的安全性"""
        try:
            # 验证表名
            if table_name not in self.allowed_tables:
                logger.error(f"不允许的防火墙表: {table_name}")
                return False
            
            # 验证链名
            if chain_name not in self.allowed_chains:
                logger.error(f"不允许的防火墙链: {chain_name}")
                return False
            
            # 验证动作
            if action not in self.allowed_actions:
                logger.error(f"不允许的防火墙动作: {action}")
                return False
            
            # 验证规则规格
            if rule_spec:
                # 分割规则规格并验证每个部分
                parts = rule_spec.strip().split()
                for part in parts:
                    if not self._is_safe_rule_part(part):
                        logger.error(f"不安全的规则参数: {part}")
                        return False
            
            return True
        except Exception as e:
            logger.error(f"验证防火墙参数失败: {e}")
            return False

    def _is_safe_rule_part(self, part: str) -> bool:
        """检查规则参数是否安全"""
        try:
            # 检查是否匹配任何安全模式
            for pattern_name, pattern in self.safe_patterns.items():
                if re.match(pattern, part.strip()):
                    return True
            
            # 允许的独立参数
            safe_standalone = {"!", "-m", "state", "multiport", "conntrack"}
            if part.strip() in safe_standalone:
                return True
            
            # 检查是否为数字（端口号等）
            if part.strip().isdigit() and 1 <= int(part.strip()) <= 65535:
                return True
            
            # 检查是否为端口范围
            if "-" in part and part.count("-") == 1:
                start, end = part.split("-")
                if start.isdigit() and end.isdigit():
                    if 1 <= int(start) <= 65535 and 1 <= int(end) <= 65535:
                        return True
            
            logger.warning(f"未知的规则参数: {part}")
            return False
        except Exception as e:
            logger.error(f"检查规则参数安全性失败: {e}")
            return False

    def build_safe_iptables_command(self, table_name: str, chain_name: str, action: str, rule_spec: str) -> Optional[List[str]]:
        """构建安全的iptables命令（返回参数列表而不是字符串）"""
        try:
            # 验证参数
            if not self.validate_firewall_parameters(table_name, chain_name, action, rule_spec):
                return None
            
            # 构建命令参数列表
            cmd_parts = ["iptables", "-t", table_name, "-A", chain_name]
            
            # 添加规则规格
            if rule_spec:
                cmd_parts.extend(rule_spec.strip().split())
            
            # 添加动作
            cmd_parts.extend(["-j", action])
            
            return cmd_parts
        except Exception as e:
            logger.error(f"构建安全iptables命令失败: {e}")
            return None

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
            
            # 构建安全的iptables命令
            cmd_parts = self.build_safe_iptables_command(
                rule.table_name, rule.chain_name, rule.action, rule.rule_spec or ""
            )
            if not cmd_parts:
                logger.error(f"无法构建安全的防火墙命令: {rule.name}")
                return False
            
            # 执行命令（使用shell=False避免注入）
            result = subprocess.run(cmd_parts, capture_output=True, text=True, shell=False)
            
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
            # 构建安全的删除命令
            cmd_parts = self.build_safe_iptables_delete_command(
                rule.table_name, rule.chain_name, rule.action, rule.rule_spec or ""
            )
            if not cmd_parts:
                logger.warning(f"无法构建安全的删除命令: {rule.name}")
                return True  # 删除失败不算严重错误
            
            # 执行命令（使用shell=False避免注入）
            result = subprocess.run(cmd_parts, capture_output=True, text=True, shell=False)
            
            if result.returncode == 0:
                logger.info(f"防火墙规则删除成功: {rule.name}")
                return True
            else:
                logger.warning(f"防火墙规则删除失败: {result.stderr}")
                return False
        except Exception as e:
            logger.error(f"删除防火墙规则异常: {e}")
            return False

    def build_safe_iptables_delete_command(self, table_name: str, chain_name: str, action: str, rule_spec: str) -> Optional[List[str]]:
        """构建安全的iptables删除命令"""
        try:
            # 验证参数
            if not self.validate_firewall_parameters(table_name, chain_name, action, rule_spec):
                return None
            
            # 构建删除命令参数列表
            cmd_parts = ["iptables", "-t", table_name, "-D", chain_name]
            
            # 添加规则规格
            if rule_spec:
                cmd_parts.extend(rule_spec.strip().split())
            
            # 添加动作
            cmd_parts.extend(["-j", action])
            
            return cmd_parts
        except Exception as e:
            logger.error(f"构建安全删除命令失败: {e}")
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
            # 使用shell=False避免命令注入
            result = subprocess.run(["ip", "route", "show"], capture_output=True, text=True, shell=False)
            
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
            # 清空现有规则（使用shell=False避免注入）
            subprocess.run(["iptables", "-F"], capture_output=True, shell=False)
            subprocess.run(["iptables", "-t", "nat", "-F"], capture_output=True, shell=False)
            subprocess.run(["iptables", "-t", "mangle", "-F"], capture_output=True, shell=False)
            
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
