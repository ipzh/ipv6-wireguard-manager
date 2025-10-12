#!/bin/bash

# IPv6 WireGuard Manager 管理脚本
# 用于日常管理和维护

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 应用配置
APP_HOME="/opt/ipv6-wireguard-manager"
BACKEND_DIR="$APP_HOME/backend"
SERVICE_NAME="ipv6-wireguard-manager"

# 显示帮助信息
show_help() {
    echo -e "${BLUE}IPv6 WireGuard Manager 管理工具${NC}"
    echo "=================================="
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  status       - 查看服务状态"
    echo "  start        - 启动服务"
    echo "  stop         - 停止服务"
    echo "  restart      - 重启服务"
    echo "  logs         - 查看日志"
    echo "  update       - 更新应用"
    echo "  backup       - 备份数据"
    echo "  restore      - 恢复数据"
    echo "  config       - 配置管理"
    echo "  monitor      - 实时监控"
    echo "  health       - 健康检查"
    echo "  access       - 显示访问地址"
    echo "  help         - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 status    # 查看服务状态"
    echo "  $0 logs      # 查看服务日志"
    echo "  $0 restart   # 重启服务"
}

# 查看服务状态
check_status() {
    echo -e "${BLUE}🔍 检查服务状态...${NC}"
    echo "=================================="
    
    echo "后端服务状态:"
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "  ${GREEN}✅ 后端服务运行正常${NC}"
    else
        echo -e "  ${RED}❌ 后端服务未运行${NC}"
    fi
    
    echo "Nginx服务状态:"
    if systemctl is-active --quiet nginx; then
        echo -e "  ${GREEN}✅ Nginx服务运行正常${NC}"
    else
        echo -e "  ${RED}❌ Nginx服务未运行${NC}"
    fi
    
    echo ""
    echo "端口监听状态:"
    echo "  端口8000 (后端API):"
    ss -tlnp | grep :8000 | sed 's/^/    /'
    
    echo "  端口80 (Nginx):"
    ss -tlnp | grep :80 | sed 's/^/    /'
    
    echo ""
    echo "服务详细信息:"
    systemctl status $SERVICE_NAME --no-pager -l
}

# 启动服务
start_services() {
    echo -e "${BLUE}🚀 启动服务...${NC}"
    echo "=================================="
    
    echo "启动后端服务..."
    sudo systemctl start $SERVICE_NAME
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "  ${GREEN}✅ 后端服务启动成功${NC}"
    else
        echo -e "  ${RED}❌ 后端服务启动失败${NC}"
    fi
    
    echo "启动Nginx服务..."
    sudo systemctl start nginx
    if systemctl is-active --quiet nginx; then
        echo -e "  ${GREEN}✅ Nginx服务启动成功${NC}"
    else
        echo -e "  ${RED}❌ Nginx服务启动失败${NC}"
    fi
}

# 停止服务
stop_services() {
    echo -e "${BLUE}🛑 停止服务...${NC}"
    echo "=================================="
    
    echo "停止后端服务..."
    sudo systemctl stop $SERVICE_NAME
    echo -e "  ${GREEN}✅ 后端服务已停止${NC}"
    
    echo "停止Nginx服务..."
    sudo systemctl stop nginx
    echo -e "  ${GREEN}✅ Nginx服务已停止${NC}"
}

# 重启服务
restart_services() {
    echo -e "${BLUE}🔄 重启服务...${NC}"
    echo "=================================="
    
    echo "重启后端服务..."
    sudo systemctl restart $SERVICE_NAME
    sleep 3
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "  ${GREEN}✅ 后端服务重启成功${NC}"
    else
        echo -e "  ${RED}❌ 后端服务重启失败${NC}"
    fi
    
    echo "重启Nginx服务..."
    sudo systemctl restart nginx
    sleep 2
    
    if systemctl is-active --quiet nginx; then
        echo -e "  ${GREEN}✅ Nginx服务重启成功${NC}"
    else
        echo -e "  ${RED}❌ Nginx服务重启失败${NC}"
    fi
}

# 查看日志
view_logs() {
    echo -e "${BLUE}📋 查看服务日志...${NC}"
    echo "=================================="
    
    echo "选择要查看的日志:"
    echo "1) 后端服务日志"
    echo "2) Nginx错误日志"
    echo "3) Nginx访问日志"
    echo "4) 系统日志"
    echo "5) 实时监控所有日志"
    
    read -p "请选择 (1-5): " choice
    
    case $choice in
        1)
            echo "后端服务日志 (最近50条):"
            sudo journalctl -u $SERVICE_NAME --no-pager -n 50
            ;;
        2)
            echo "Nginx错误日志 (最近20条):"
            sudo tail -20 /var/log/nginx/error.log
            ;;
        3)
            echo "Nginx访问日志 (最近20条):"
            sudo tail -20 /var/log/nginx/access.log
            ;;
        4)
            echo "系统日志 (最近30条):"
            sudo journalctl --no-pager -n 30
            ;;
        5)
            echo "实时监控日志 (按Ctrl+C退出):"
            sudo journalctl -u $SERVICE_NAME -f
            ;;
        *)
            echo "无效选择"
            ;;
    esac
}

# 更新应用
update_app() {
    echo -e "${BLUE}🔄 更新应用...${NC}"
    echo "=================================="
    
    echo "⚠️  更新前建议先备份数据"
    read -p "是否继续? (y/N): " confirm
    
    if [[ $confirm != [yY] ]]; then
        echo "更新已取消"
        return
    fi
    
    echo "停止服务..."
    sudo systemctl stop $SERVICE_NAME
    sudo systemctl stop nginx
    
    echo "备份当前配置..."
    sudo cp -r $APP_HOME $APP_HOME.backup.$(date +%Y%m%d_%H%M%S)
    
    echo "更新应用代码..."
    cd $APP_HOME
    if [ -d ".git" ]; then
        git pull origin main
    else
        echo "非Git仓库，请手动更新"
        return
    fi
    
    echo "更新依赖..."
    cd $BACKEND_DIR
    source venv/bin/activate
    pip install -r requirements.txt
    
    echo "重启服务..."
    sudo systemctl start $SERVICE_NAME
    sudo systemctl start nginx
    
    echo -e "${GREEN}✅ 更新完成${NC}"
}

# 备份数据
backup_data() {
    echo -e "${BLUE}💾 备份数据...${NC}"
    echo "=================================="
    
    BACKUP_DIR="/opt/backups/ipv6-wireguard-manager"
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    echo "创建备份目录..."
    sudo mkdir -p $BACKUP_DIR
    
    echo "备份应用数据..."
    sudo tar -czf $BACKUP_DIR/$BACKUP_FILE -C /opt ipv6-wireguard-manager
    
    echo "备份数据库..."
    sudo -u postgres pg_dump ipv6wgm > $BACKUP_DIR/database_$(date +%Y%m%d_%H%M%S).sql
    
    echo -e "${GREEN}✅ 备份完成: $BACKUP_DIR/$BACKUP_FILE${NC}"
}

# 恢复数据
restore_data() {
    echo -e "${BLUE}🔄 恢复数据...${NC}"
    echo "=================================="
    
    BACKUP_DIR="/opt/backups/ipv6-wireguard-manager"
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${RED}❌ 备份目录不存在${NC}"
        return
    fi
    
    echo "可用的备份文件:"
    ls -la $BACKUP_DIR/*.tar.gz 2>/dev/null || echo "没有找到备份文件"
    
    read -p "请输入备份文件名: " backup_file
    
    if [ ! -f "$BACKUP_DIR/$backup_file" ]; then
        echo -e "${RED}❌ 备份文件不存在${NC}"
        return
    fi
    
    echo "⚠️  恢复将覆盖当前数据"
    read -p "是否继续? (y/N): " confirm
    
    if [[ $confirm != [yY] ]]; then
        echo "恢复已取消"
        return
    fi
    
    echo "停止服务..."
    sudo systemctl stop $SERVICE_NAME
    sudo systemctl stop nginx
    
    echo "恢复数据..."
    sudo rm -rf $APP_HOME
    sudo tar -xzf $BACKUP_DIR/$backup_file -C /opt
    
    echo "重启服务..."
    sudo systemctl start $SERVICE_NAME
    sudo systemctl start nginx
    
    echo -e "${GREEN}✅ 恢复完成${NC}"
}

# 配置管理
config_management() {
    echo -e "${BLUE}⚙️  配置管理...${NC}"
    echo "=================================="
    
    echo "选择配置操作:"
    echo "1) 查看当前配置"
    echo "2) 编辑环境配置"
    echo "3) 编辑Nginx配置"
    echo "4) 编辑systemd服务"
    echo "5) 重新加载配置"
    
    read -p "请选择 (1-5): " choice
    
    case $choice in
        1)
            echo "当前环境配置:"
            cat $BACKEND_DIR/.env
            ;;
        2)
            sudo nano $BACKEND_DIR/.env
            ;;
        3)
            sudo nano /etc/nginx/sites-available/ipv6-wireguard-manager
            ;;
        4)
            sudo nano /etc/systemd/system/$SERVICE_NAME.service
            ;;
        5)
            echo "重新加载配置..."
            sudo systemctl daemon-reload
            sudo nginx -t && sudo systemctl reload nginx
            sudo systemctl restart $SERVICE_NAME
            echo -e "${GREEN}✅ 配置已重新加载${NC}"
            ;;
        *)
            echo "无效选择"
            ;;
    esac
}

# 实时监控
monitor_services() {
    echo -e "${BLUE}📊 实时监控...${NC}"
    echo "=================================="
    
    echo "选择监控类型:"
    echo "1) 服务状态监控"
    echo "2) 日志实时监控"
    echo "3) 系统资源监控"
    echo "4) 网络连接监控"
    
    read -p "请选择 (1-4): " choice
    
    case $choice in
        1)
            echo "服务状态监控 (按Ctrl+C退出):"
            while true; do
                clear
                echo "=== 服务状态监控 ==="
                echo "时间: $(date)"
                echo ""
                check_status
                sleep 5
            done
            ;;
        2)
            echo "日志实时监控 (按Ctrl+C退出):"
            sudo journalctl -u $SERVICE_NAME -f
            ;;
        3)
            echo "系统资源监控 (按Ctrl+C退出):"
            htop
            ;;
        4)
            echo "网络连接监控 (按Ctrl+C退出):"
            watch -n 1 'ss -tlnp | grep -E ":(80|8000)"'
            ;;
        *)
            echo "无效选择"
            ;;
    esac
}

# 健康检查
health_check() {
    echo -e "${BLUE}🏥 健康检查...${NC}"
    echo "=================================="
    
    # 检查服务状态
    echo "1. 检查服务状态..."
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "  ${GREEN}✅ 后端服务正常${NC}"
    else
        echo -e "  ${RED}❌ 后端服务异常${NC}"
    fi
    
    if systemctl is-active --quiet nginx; then
        echo -e "  ${GREEN}✅ Nginx服务正常${NC}"
    else
        echo -e "  ${RED}❌ Nginx服务异常${NC}"
    fi
    
    # 检查端口监听
    echo ""
    echo "2. 检查端口监听..."
    if ss -tlnp | grep -q :8000; then
        echo -e "  ${GREEN}✅ 端口8000正常监听${NC}"
    else
        echo -e "  ${RED}❌ 端口8000未监听${NC}"
    fi
    
    if ss -tlnp | grep -q :80; then
        echo -e "  ${GREEN}✅ 端口80正常监听${NC}"
    else
        echo -e "  ${RED}❌ 端口80未监听${NC}"
    fi
    
    # 检查API响应
    echo ""
    echo "3. 检查API响应..."
    if curl -s http://127.0.0.1:8000/health >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ API健康检查正常${NC}"
        curl -s http://127.0.0.1:8000/health
    else
        echo -e "  ${RED}❌ API健康检查失败${NC}"
    fi
    
    # 检查前端访问
    echo ""
    echo "4. 检查前端访问..."
    if curl -s http://localhost >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ 前端访问正常${NC}"
    else
        echo -e "  ${RED}❌ 前端访问失败${NC}"
    fi
    
    # 检查IPv6访问
    echo ""
    echo "5. 检查IPv6访问..."
    IPV6_ADDRESS=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)
    if [ -n "$IPV6_ADDRESS" ]; then
        echo "  检测到IPv6地址: $IPV6_ADDRESS"
        if curl -6 -s http://[$IPV6_ADDRESS]/api/v1/status >/dev/null 2>&1; then
            echo -e "  ${GREEN}✅ IPv6访问正常${NC}"
        else
            echo -e "  ${YELLOW}⚠️  IPv6访问可能有问题${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠️  未检测到IPv6地址${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}🏥 健康检查完成${NC}"
}

# 显示访问地址
show_access() {
    echo -e "${BLUE}🌐 访问地址...${NC}"
    echo "=================================="
    
    # 获取IP地址
    PUBLIC_IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || echo "")
    PUBLIC_IPV6=$(curl -s -6 ifconfig.me 2>/dev/null || echo "")
    LOCAL_IPV4=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
    LOCAL_IPV6=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)
    
    echo "📱 本地访问:"
    echo "   前端: http://localhost"
    echo "   API:  http://localhost/api/v1/status"
    echo "   健康: http://localhost/health"
    echo ""
    
    if [ -n "$LOCAL_IPV4" ] && [ "$LOCAL_IPV4" != "localhost" ]; then
        echo "🌐 IPv4访问:"
        echo "   前端: http://$LOCAL_IPV4"
        echo "   API:  http://$LOCAL_IPV4/api/v1/status"
        echo ""
    fi
    
    if [ -n "$LOCAL_IPV6" ]; then
        echo "🌐 IPv6访问:"
        echo "   前端: http://[$LOCAL_IPV6]"
        echo "   API:  http://[$LOCAL_IPV6]/api/v1/status"
        echo ""
    fi
    
    if [ -n "$PUBLIC_IPV4" ]; then
        echo "🌍 公网IPv4访问:"
        echo "   前端: http://$PUBLIC_IPV4"
        echo "   API:  http://$PUBLIC_IPV4/api/v1/status"
        echo ""
    fi
    
    if [ -n "$PUBLIC_IPV6" ]; then
        echo "🌍 公网IPv6访问:"
        echo "   前端: http://[$PUBLIC_IPV6]"
        echo "   API:  http://[$PUBLIC_IPV6]/api/v1/status"
        echo ""
    fi
    
    echo "🔑 默认登录信息:"
    echo "   用户名: admin"
    echo "   密码: admin123"
}

# 主函数
main() {
    case "${1:-help}" in
        status)
            check_status
            ;;
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        logs)
            view_logs
            ;;
        update)
            update_app
            ;;
        backup)
            backup_data
            ;;
        restore)
            restore_data
            ;;
        config)
            config_management
            ;;
        monitor)
            monitor_services
            ;;
        health)
            health_check
            ;;
        access)
            show_access
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知选项: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
