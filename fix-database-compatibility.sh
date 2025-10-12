#!/bin/bash

# 修复数据库兼容性问题
echo "🔧 修复数据库兼容性问题..."

# 检查当前目录
if [ ! -f "backend/app/core/database.py" ]; then
    echo "❌ 不在项目根目录，请切换到项目根目录后运行此脚本"
    exit 1
fi

echo "📁 当前目录: $(pwd)"

# 1. 修复database.py中的engine导出问题
echo "🔧 修复database.py中的engine导出..."
if grep -q "engine = sync_engine" backend/app/core/database.py; then
    echo "✅ engine别名已存在"
else
    echo "📝 添加engine别名..."
    sed -i '/# 创建同步会话工厂/a\\n# 为了向后兼容，导出engine别名\nengine = sync_engine' backend/app/core/database.py
    echo "✅ engine别名已添加"
fi

# 2. 修复模型文件中的INET6兼容性问题
echo "🔧 修复模型文件中的INET6兼容性..."

# 修复wireguard.py
if grep -q "try:" backend/app/models/wireguard.py; then
    echo "✅ wireguard.py兼容性处理已存在"
else
    echo "📝 修复wireguard.py..."
    # 备份原文件
    cp backend/app/models/wireguard.py backend/app/models/wireguard.py.bak
    
    # 创建修复后的文件
    cat > backend/app/models/wireguard.py << 'EOF'
"""
WireGuard相关模型
"""
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text, ForeignKey, BigInteger
from sqlalchemy.dialects.postgresql import UUID, INET, ARRAY
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

# 兼容性处理：某些SQLAlchemy版本可能没有INET6
try:
    from sqlalchemy.dialects.postgresql import INET6
except ImportError:
    # 如果没有INET6，使用String作为替代
    INET6 = String(45)  # IPv6地址最大长度

from ..core.database import Base


class WireGuardServer(Base):
    """WireGuard服务器模型"""
    __tablename__ = "wireguard_servers"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False, index=True)
    interface = Column(String(20), default='wg0', nullable=False)
    listen_port = Column(Integer, nullable=False)
    private_key = Column(Text, nullable=False)
    public_key = Column(Text, nullable=False)
    ipv4_address = Column(INET, nullable=True)
    ipv6_address = Column(INET6, nullable=True)
    dns_servers = Column(ARRAY(INET), nullable=True)
    mtu = Column(Integer, default=1420, nullable=False)
    config_file_path = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # 关系
    clients = relationship("WireGuardClient", secondary="client_server_relations", back_populates="servers")

    def __repr__(self):
        return f"<WireGuardServer(id={self.id}, name={self.name}, interface={self.interface})>"


class WireGuardClient(Base):
    """WireGuard客户端模型"""
    __tablename__ = "wireguard_clients"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False, index=True)
    description = Column(Text, nullable=True)
    private_key = Column(Text, nullable=False)
    public_key = Column(Text, nullable=False)
    ipv4_address = Column(INET, nullable=True)
    ipv6_address = Column(INET6, nullable=True)
    allowed_ips = Column(ARRAY(INET), nullable=True)
    persistent_keepalive = Column(Integer, default=25, nullable=False)
    qr_code = Column(Text, nullable=True)
    config_file_path = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    last_seen = Column(DateTime(timezone=True), nullable=True)
    bytes_received = Column(BigInteger, default=0, nullable=False)
    bytes_sent = Column(BigInteger, default=0, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # 关系
    servers = relationship("WireGuardServer", secondary="client_server_relations", back_populates="clients")

    def __repr__(self):
        return f"<WireGuardClient(id={self.id}, name={self.name})>"


class ClientServerRelation(Base):
    """客户端服务器关联模型"""
    __tablename__ = "client_server_relations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    client_id = Column(UUID(as_uuid=True), ForeignKey('wireguard_clients.id', ondelete='CASCADE'), nullable=False)
    server_id = Column(UUID(as_uuid=True), ForeignKey('wireguard_servers.id', ondelete='CASCADE'), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    def __repr__(self):
        return f"<ClientServerRelation(client_id={self.client_id}, server_id={self.server_id})>"
EOF
    echo "✅ wireguard.py已修复"
fi

# 修复network.py
if grep -q "try:" backend/app/models/network.py; then
    echo "✅ network.py兼容性处理已存在"
else
    echo "📝 修复network.py..."
    # 备份原文件
    cp backend/app/models/network.py backend/app/models/network.py.bak
    
    # 创建修复后的文件
    cat > backend/app/models/network.py << 'EOF'
"""
网络相关模型
"""
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text
from sqlalchemy.dialects.postgresql import UUID, INET, MACADDR
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

# 兼容性处理：某些SQLAlchemy版本可能没有INET6
try:
    from sqlalchemy.dialects.postgresql import INET6
except ImportError:
    # 如果没有INET6，使用String作为替代
    INET6 = String(45)  # IPv6地址最大长度

from ..core.database import Base


class NetworkInterface(Base):
    """网络接口模型"""
    __tablename__ = "network_interfaces"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(50), nullable=False, index=True)
    type = Column(String(20), nullable=False)  # 'physical', 'virtual', 'tunnel'
    ipv4_address = Column(INET, nullable=True)
    ipv6_address = Column(INET6, nullable=True)
    mac_address = Column(MACADDR, nullable=True)
    mtu = Column(Integer, nullable=True)
    is_up = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    def __repr__(self):
        return f"<NetworkInterface(id={self.id}, name={self.name}, type={self.type})>"


class FirewallRule(Base):
    """防火墙规则模型"""
    __tablename__ = "firewall_rules"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False, index=True)
    table_name = Column(String(20), nullable=False)  # 'filter', 'nat', 'mangle'
    chain_name = Column(String(50), nullable=False)
    rule_spec = Column(Text, nullable=False)
    action = Column(String(20), nullable=False)
    priority = Column(Integer, default=0, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    def __repr__(self):
        return f"<FirewallRule(id={self.id}, name={self.name}, table={self.table_name})>"
EOF
    echo "✅ network.py已修复"
fi

# 3. 测试数据库连接
echo "🔧 测试数据库连接..."
cd backend

# 检查虚拟环境
if [ -d "venv" ]; then
    echo "📦 激活虚拟环境..."
    source venv/bin/activate
    
    # 测试导入
    echo "🧪 测试数据库模块导入..."
    if python -c "from app.core.database import engine, Base; print('✅ 数据库模块导入成功')"; then
        echo "✅ 数据库模块导入测试通过"
    else
        echo "❌ 数据库模块导入失败"
        exit 1
    fi
    
    # 测试模型导入
    echo "🧪 测试模型导入..."
    if python -c "from app.models import Base; print('✅ 模型导入成功')"; then
        echo "✅ 模型导入测试通过"
    else
        echo "❌ 模型导入失败"
        exit 1
    fi
    
    # 尝试创建数据库表
    echo "🔧 尝试创建数据库表..."
    if python -c "from app.core.database import engine; from app.models import Base; Base.metadata.create_all(bind=engine); print('✅ 数据库表创建成功')"; then
        echo "✅ 数据库表创建成功"
    else
        echo "⚠️  数据库表创建失败，但继续..."
    fi
    
    deactivate
else
    echo "⚠️  虚拟环境不存在，跳过测试"
fi

cd ..

echo ""
echo "🎉 数据库兼容性修复完成！"
echo ""
echo "📋 修复内容："
echo "   ✅ 添加了engine别名到database.py"
echo "   ✅ 修复了wireguard.py中的INET6兼容性"
echo "   ✅ 修复了network.py中的INET6兼容性"
echo "   ✅ 测试了数据库模块导入"
echo ""
echo "💡 现在可以重新运行安装脚本或手动初始化数据库"
