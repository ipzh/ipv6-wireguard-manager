#!/bin/bash

# VPS数据库修复脚本
# 解决PostgreSQL权限问题和数据库配置冲突

set -e

LOG_FILE="vps-database-fix.log"
REPORT_FILE="vps-database-fix-report.txt"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 错误处理函数
error_exit() {
    log "[ERROR] $1"
    echo "修复失败: $1" >> "$REPORT_FILE"
    exit 1
}

# 成功函数
success() {
    log "[SUCCESS] $1"
    echo "修复成功: $1" >> "$REPORT_FILE"
}

# 信息函数
info() {
    log "[INFO] $1"
    echo "信息: $1" >> "$REPORT_FILE"
}

# 开始修复
log "开始VPS数据库修复..."

# 1. 检查当前数据库配置
info "检查当前数据库配置..."

# 检查PostgreSQL服务状态
if systemctl is-active --quiet postgresql; then
    info "PostgreSQL服务正在运行"
    
    # 检查数据库用户权限
    info "检查PostgreSQL用户权限..."
    
    # 尝试连接到PostgreSQL
    if sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1; then
        info "PostgreSQL连接正常"
        
        # 检查ipv6wgm数据库是否存在
        if sudo -u postgres psql -l | grep -q ipv6wgm; then
            info "ipv6wgm数据库已存在"
            
            # 检查用户权限
            info "检查数据库用户权限..."
            
            # 授予public schema权限
            sudo -u postgres psql -d ipv6wgm -c "GRANT ALL ON SCHEMA public TO ipv6wgm;" 2>/dev/null || info "权限设置可能已存在"
            sudo -u postgres psql -d ipv6wgm -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ipv6wgm;" 2>/dev/null || info "表权限可能已存在"
            sudo -u postgres psql -d ipv6wgm -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ipv6wgm;" 2>/dev/null || info "序列权限可能已存在"
            
            success "PostgreSQL权限修复完成"
        else
            info "ipv6wgm数据库不存在，将创建"
            
            # 创建数据库和用户
            sudo -u postgres psql -c "CREATE DATABASE ipv6wgm;"
            sudo -u postgres psql -c "CREATE USER ipv6wgm WITH PASSWORD 'ipv6wgm123';"
            sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ipv6wgm TO ipv6wgm;"
            sudo -u postgres psql -d ipv6wgm -c "GRANT ALL ON SCHEMA public TO ipv6wgm;"
            
            success "PostgreSQL数据库和用户创建完成"
        fi
    else
        error_exit "无法连接到PostgreSQL，请检查服务状态"
    fi
else
    info "PostgreSQL服务未运行，将使用SQLite模式"
fi

# 2. 修复应用配置
info "修复应用数据库配置..."

# 检查当前工作目录
if [ ! -d "backend" ]; then
    error_exit "请在项目根目录运行此脚本"
fi

# 备份原始配置
if [ -f "backend/app/core/config.py" ]; then
    cp "backend/app/core/config.py" "backend/app/core/config.py.backup"
    info "配置文件已备份"
fi

# 检查是否应该使用PostgreSQL
if systemctl is-active --quiet postgresql && sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1; then
    # 使用PostgreSQL
    info "配置应用使用PostgreSQL..."
    
    # 创建环境变量文件
    cat > backend/.env << EOF
# 数据库配置
DATABASE_URL=postgresql://ipv6wgm:ipv6wgm123@localhost:5432/ipv6wgm
REDIS_URL=redis://localhost:6379/0

# 应用配置
DEBUG=false
LOG_LEVEL=INFO
SECRET_KEY=$(openssl rand -hex 32)

# WireGuard配置
WIREGUARD_CONFIG_DIR=/etc/wireguard
WIREGUARD_CLIENTS_DIR=/etc/wireguard/clients
EOF
    
    success "PostgreSQL环境配置完成"
else
    # 使用SQLite
    info "配置应用使用SQLite..."
    
    # 创建环境变量文件
    cat > backend/.env << EOF
# 数据库配置
DATABASE_URL=sqlite:///./ipv6_wireguard.db
REDIS_URL=redis://localhost:6379/0

# 应用配置
DEBUG=false
LOG_LEVEL=INFO
SECRET_KEY=$(openssl rand -hex 32)

# WireGuard配置
WIREGUARD_CONFIG_DIR=/etc/wireguard
WIREGUARD_CLIENTS_DIR=/etc/wireguard/clients
EOF
    
    success "SQLite环境配置完成"
fi

# 3. 修复系统服务配置
info "修复系统服务配置..."

# 检查服务文件是否存在
if [ -f "/etc/systemd/system/ipv6-wireguard-manager.service" ]; then
    # 备份服务文件
    sudo cp "/etc/systemd/system/ipv6-wireguard-manager.service" "/etc/systemd/system/ipv6-wireguard-manager.service.backup"
    
    # 更新服务配置
    sudo sed -i 's/Environment=DATABASE_URL=.*/Environment=DATABASE_URL=sqlite:\/\/\/.\/ipv6_wireguard.db/' "/etc/systemd/system/ipv6-wireguard-manager.service"
    
    # 重新加载服务配置
    sudo systemctl daemon-reload
    
    success "系统服务配置已更新为SQLite模式"
else
    info "系统服务文件不存在，跳过服务配置修复"
fi

# 4. 测试修复结果
info "测试修复结果..."

# 测试数据库连接
cd backend

# 检查Python环境
if [ -d "venv" ]; then
    source venv/bin/activate
    
    # 测试数据库连接
    if python -c "
from app.core.database import sync_engine
from sqlalchemy import text
try:
    with sync_engine.connect() as conn:
        result = conn.execute(text('SELECT 1'))
        print('数据库连接测试成功')
except Exception as e:
    print(f'数据库连接失败: {e}')
    exit(1)
" >/dev/null 2>&1; then
        success "数据库连接测试成功"
    else
        error_exit "数据库连接测试失败"
    fi
    
    # 测试应用启动
    if python -c "
from app.main import app
print('应用导入成功')
" >/dev/null 2>&1; then
        success "应用导入测试成功"
    else
        error_exit "应用导入测试失败"
    fi
    
    deactivate
else
    info "Python虚拟环境不存在，跳过测试"
fi

cd ..

# 5. 生成修复报告
log "生成修复报告..."

echo "=== VPS数据库修复报告 ===" >> "$REPORT_FILE"
echo "修复时间: $(date)" >> "$REPORT_FILE"
echo "修复状态: 完成" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 检查关键文件
if [ -f "backend/.env" ]; then
    echo "环境配置文件: 已创建" >> "$REPORT_FILE"
    echo "数据库配置: $(grep DATABASE_URL backend/.env)" >> "$REPORT_FILE"
else
    echo "环境配置文件: 缺失" >> "$REPORT_FILE"
fi

if systemctl is-active --quiet postgresql; then
    echo "PostgreSQL状态: 运行中" >> "$REPORT_FILE"
else
    echo "PostgreSQL状态: 未运行（使用SQLite）" >> "$REPORT_FILE"
fi

if [ -f "/etc/systemd/system/ipv6-wireguard-manager.service" ]; then
    echo "系统服务: 已配置" >> "$REPORT_FILE"
    echo "服务数据库URL: $(grep DATABASE_URL /etc/systemd/system/ipv6-wireguard-manager.service)" >> "$REPORT_FILE"
else
    echo "系统服务: 未配置" >> "$REPORT_FILE"
fi

log "VPS数据库修复完成！"
echo ""
echo "=== 修复完成 ==="
echo "日志文件: $LOG_FILE"
echo "报告文件: $REPORT_FILE"
echo ""
echo "下一步操作:"
if systemctl is-active --quiet postgresql; then
    echo "1. PostgreSQL已配置完成，可以启动服务"
else
    echo "1. 使用SQLite模式，数据库文件将保存在backend/ipv6_wireguard.db"
fi
echo "2. 重启服务: sudo systemctl restart ipv6-wireguard-manager"
echo "3. 检查服务状态: sudo systemctl status ipv6-wireguard-manager"
echo "4. 查看服务日志: sudo journalctl -u ipv6-wireguard-manager -f"