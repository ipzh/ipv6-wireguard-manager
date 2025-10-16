"""
数据库初始化脚本
"""
import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from ..models.user import User, Role, UserRole
from ..models.wireguard import WireGuardServer, WireGuardClient
from ..models.network import NetworkInterface, FirewallRule
from ..models.monitoring import SystemMetric, AuditLog
from ..models.config import ConfigVersion, BackupRecord
from ..core.security import get_password_hash
import logging

logger = logging.getLogger(__name__)

async def init_db_data(session: AsyncSession):
    """初始化数据库默认数据"""
    try:
        # 检查是否已经初始化
        result = await session.execute(select(User))
        existing_users = result.scalars().all()
        
        if existing_users:
            logger.info("数据库已初始化，跳过默认数据创建")
            return
        
        # 创建默认角色
        await create_default_roles(session)
        
        # 创建默认用户
        await create_default_users(session)
        
        # 创建默认WireGuard服务器
        await create_default_wireguard_server(session)
        
        # 创建默认网络接口
        await create_default_network_interfaces(session)
        
        # 创建默认防火墙规则
        await create_default_firewall_rules(session)
        
        await session.commit()
        logger.info("数据库默认数据初始化完成")
        
    except Exception as e:
        await session.rollback()
        logger.error(f"数据库初始化失败: {e}")
        # 对于远程服务器，记录更详细的错误信息
        error_msg = str(e)
        if "Connection refused" in error_msg or "10061" in error_msg:
            logger.error("💡 建议: 检查远程数据库服务器是否运行")
        elif "timeout" in error_msg.lower():
            logger.error("💡 建议: 检查网络连接和防火墙设置")
        elif "authentication failed" in error_msg.lower():
            logger.error("💡 建议: 检查数据库用户名和密码")
        elif "database" in error_msg.lower() and "does not exist" in error_msg.lower():
            logger.error("💡 建议: 数据库不存在，请先创建数据库")
        elif "permission" in error_msg.lower():
            logger.error("💡 建议: 检查数据库用户权限")
        
        # 对于远程服务器错误，不抛出异常，而是记录警告
        if any(keyword in error_msg.lower() for keyword in [
            "connection refused", "10061", "timeout", "authentication"
        ]):
            logger.warning("⚠️ 远程数据库连接问题，跳过数据初始化")
            return
        else:
            raise

async def create_default_roles(session: AsyncSession):
    """创建默认角色"""
    roles_data = [
        {
            "name": "admin",
            "description": "系统管理员",
            "permissions": {
                "users": ["create", "read", "update", "delete"],
                "servers": ["create", "read", "update", "delete", "start", "stop", "restart"],
                "clients": ["create", "read", "update", "delete"],
                "network": ["create", "read", "update", "delete"],
                "monitoring": ["read"],
                "logs": ["read", "export"],
                "settings": ["read", "update"]
            }
        },
        {
            "name": "operator",
            "description": "操作员",
            "permissions": {
                "servers": ["read", "start", "stop", "restart"],
                "clients": ["create", "read", "update", "delete"],
                "network": ["read"],
                "monitoring": ["read"],
                "logs": ["read"]
            }
        },
        {
            "name": "viewer",
            "description": "查看者",
            "permissions": {
                "servers": ["read"],
                "clients": ["read"],
                "network": ["read"],
                "monitoring": ["read"],
                "logs": ["read"]
            }
        }
    ]
    
    for role_data in roles_data:
        role = Role(**role_data)
        session.add(role)
    
    await session.flush()  # 获取生成的ID

async def create_default_users(session: AsyncSession):
    """创建默认用户"""
    # 获取admin角色
    result = await session.execute(select(Role).where(Role.name == "admin"))
    admin_role = result.scalars().first()
    
    if not admin_role:
        logger.error("未找到admin角色")
        return
    
    # 创建默认管理员用户
    admin_user = User(
        username="admin",
        email="admin@ipv6wgm.local",
        password_hash=get_password_hash("admin123"),
        is_active=True,
        is_superuser=True
    )
    session.add(admin_user)
    await session.flush()
    
    # 分配admin角色
    user_role = UserRole(user_id=admin_user.id, role_id=admin_role.id)
    session.add(user_role)
    
    # 创建测试用户
    test_user = User(
        username="test",
        email="test@ipv6wgm.local",
        password_hash=get_password_hash("test123"),
        is_active=True,
        is_superuser=False
    )
    session.add(test_user)
    await session.flush()
    
    # 获取operator角色
    result = await session.execute(select(Role).where(Role.name == "operator"))
    operator_role = result.scalars().first()
    
    if operator_role:
        user_role = UserRole(user_id=test_user.id, role_id=operator_role.id)
        session.add(user_role)

async def create_default_wireguard_server(session: AsyncSession):
    """创建默认WireGuard服务器"""
    # 这里应该生成真实的密钥对，简化实现
    server = WireGuardServer(
        name="Default VPN Server",
        interface="wg0",
        listen_port=51820,
        private_key="mock_private_key",
        public_key="mock_public_key",
        ipv4_address="10.0.0.1/24",
        ipv6_address="fd00:1234::1/64",
        dns_servers=["8.8.8.8", "8.8.4.4"],
        mtu=1420,
        config_file_path="/etc/wireguard/wg0.conf",
        is_active=False
    )
    session.add(server)

async def create_default_network_interfaces(session: AsyncSession):
    """创建默认网络接口"""
    interfaces_data = [
        {
            "name": "eth0",
            "type": "physical",
            "ipv4_address": "192.168.1.100/24",
            "ipv6_address": "2001:db8::100/64",
            "is_up": True
        },
        {
            "name": "wg0",
            "type": "tunnel",
            "ipv4_address": "10.0.0.1/24",
            "ipv6_address": "fd00:1234::1/64",
            "is_up": False
        }
    ]
    
    for interface_data in interfaces_data:
        interface = NetworkInterface(**interface_data)
        session.add(interface)

async def create_default_firewall_rules(session: AsyncSession):
    """创建默认防火墙规则"""
    rules_data = [
        {
            "name": "Allow SSH",
            "table_name": "filter",
            "chain_name": "INPUT",
            "rule_spec": "-p tcp --dport 22",
            "action": "ACCEPT",
            "priority": 100
        },
        {
            "name": "Allow WireGuard",
            "table_name": "filter",
            "chain_name": "INPUT",
            "rule_spec": "-p udp --dport 51820",
            "action": "ACCEPT",
            "priority": 200
        },
        {
            "name": "Allow HTTP/HTTPS",
            "table_name": "filter",
            "chain_name": "INPUT",
            "rule_spec": "-p tcp --dport 80,443",
            "action": "ACCEPT",
            "priority": 300
        },
        {
            "name": "Default Drop",
            "table_name": "filter",
            "chain_name": "INPUT",
            "rule_spec": "",
            "action": "DROP",
            "priority": 1000
        }
    ]
    
    for rule_data in rules_data:
        rule = FirewallRule(**rule_data)
        session.add(rule)

async def init_db():
    """初始化数据库（独立函数）"""
    from .database import AsyncSessionLocal
    
    async with AsyncSessionLocal() as session:
        await init_db_data(session)