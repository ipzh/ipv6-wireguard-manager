#!/bin/bash
# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"

# 确保日志相关变量已定义
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
fi

# 资源配额管理模块
# 实现资源配额管理和监控

# 资源配额配置
QUOTA_DB="${CONFIG_DIR}/resource_quotas.db"
QUOTA_ALERTS_DB="${CONFIG_DIR}/quota_alerts.db"
QUOTA_MONITORING_DIR="${CONFIG_DIR}/quota_monitoring"

# 初始化资源配额模块
init_resource_quota() {
    log_info "初始化资源配额管理模块..."
    
    # 创建目录
    mkdir -p "$QUOTA_MONITORING_DIR"
    
    # 初始化配额数据库
    init_quota_databases
    
    # 创建配额监控脚本
    create_quota_monitoring_script
    
    # 创建配额告警配置
    create_quota_alert_config
    
    log_info "资源配额管理模块初始化完成"
}

# 初始化配额数据库
init_quota_databases() {
    log_info "初始化配额数据库..."
    
    # 资源配额数据库
    sqlite3 "$QUOTA_DB" << EOF
CREATE TABLE IF NOT EXISTS resource_quotas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_type TEXT NOT NULL,
    tenant_id INTEGER NOT NULL,
    resource_type TEXT NOT NULL,
    quota_limit INTEGER NOT NULL,
    current_usage INTEGER DEFAULT 0,
    warning_threshold INTEGER DEFAULT 80,
    critical_threshold INTEGER DEFAULT 95,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active',
    UNIQUE(tenant_type, tenant_id, resource_type)
);

CREATE TABLE IF NOT EXISTS quota_usage_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_type TEXT NOT NULL,
    tenant_id INTEGER NOT NULL,
    resource_type TEXT NOT NULL,
    usage_count INTEGER NOT NULL,
    usage_percentage REAL NOT NULL,
    recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_type, tenant_id, resource_type) REFERENCES resource_quotas (tenant_type, tenant_id, resource_type)
);

CREATE TABLE IF NOT EXISTS quota_violations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_type TEXT NOT NULL,
    tenant_id INTEGER NOT NULL,
    resource_type TEXT NOT NULL,
    violation_type TEXT NOT NULL,
    current_usage INTEGER NOT NULL,
    quota_limit INTEGER NOT NULL,
    violation_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved_time DATETIME,
    status TEXT DEFAULT 'active',
    FOREIGN KEY (tenant_type, tenant_id, resource_type) REFERENCES resource_quotas (tenant_type, tenant_id, resource_type)
);
EOF

    # 配额告警数据库
    sqlite3 "$QUOTA_ALERTS_DB" << EOF
CREATE TABLE IF NOT EXISTS quota_alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_type TEXT NOT NULL,
    tenant_id INTEGER NOT NULL,
    resource_type TEXT NOT NULL,
    alert_type TEXT NOT NULL,
    threshold_percentage INTEGER NOT NULL,
    current_percentage REAL NOT NULL,
    alert_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by INTEGER,
    acknowledged_at DATETIME,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at DATETIME,
    FOREIGN KEY (tenant_type, tenant_id, resource_type) REFERENCES resource_quotas (tenant_type, tenant_id, resource_type)
);

CREATE TABLE IF NOT EXISTS quota_alert_rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_type TEXT,
    tenant_id INTEGER,
    resource_type TEXT NOT NULL,
    alert_type TEXT NOT NULL,
    threshold_percentage INTEGER NOT NULL,
    notification_methods TEXT DEFAULT 'email',
    enabled BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_type, tenant_id) REFERENCES resource_quotas (tenant_type, tenant_id)
);
EOF
}

# 创建配额监控脚本
create_quota_monitoring_script() {
    cat > "${QUOTA_MONITORING_DIR}/quota_monitor.py" << 'EOF'
#!/usr/bin/env python3
# 资源配额监控脚本

import sqlite3
import time
import json
import subprocess
import os
from datetime import datetime, timedelta

class QuotaMonitor:
    def __init__(self, quota_db_path, alert_db_path):
        self.quota_db_path = quota_db_path
        self.alert_db_path = alert_db_path
        self.monitoring_interval = 300  # 5分钟
        
    def start_monitoring(self):
        """开始监控资源配额"""
        print("资源配额监控已启动...")
        
        while True:
            try:
                self.check_all_quotas()
                self.cleanup_old_data()
                time.sleep(self.monitoring_interval)
            except KeyboardInterrupt:
                print("监控已停止")
                break
            except Exception as e:
                print(f"监控错误: {e}")
                time.sleep(60)
    
    def check_all_quotas(self):
        """检查所有配额"""
        conn = sqlite3.connect(self.quota_db_path)
        cursor = conn.cursor()
        
        # 获取所有活跃配额
        cursor.execute("""
            SELECT tenant_type, tenant_id, resource_type, quota_limit, 
                   warning_threshold, critical_threshold
            FROM resource_quotas 
            WHERE status = 'active'
        """)
        
        quotas = cursor.fetchall()
        
        for quota in quotas:
            tenant_type, tenant_id, resource_type, quota_limit, warning_threshold, critical_threshold = quota
            
            # 获取当前使用量
            current_usage = self.get_current_usage(tenant_type, tenant_id, resource_type)
            usage_percentage = (current_usage / quota_limit) * 100 if quota_limit > 0 else 0
            
            # 更新当前使用量
            cursor.execute("""
                UPDATE resource_quotas 
                SET current_usage = ?, updated_at = CURRENT_TIMESTAMP
                WHERE tenant_type = ? AND tenant_id = ? AND resource_type = ?
            """, (current_usage, tenant_type, tenant_id, resource_type))
            
            # 记录使用历史
            cursor.execute("""
                INSERT INTO quota_usage_history 
                (tenant_type, tenant_id, resource_type, usage_count, usage_percentage)
                VALUES (?, ?, ?, ?, ?)
            """, (tenant_type, tenant_id, resource_type, current_usage, usage_percentage))
            
            # 检查告警条件
            self.check_quota_alerts(tenant_type, tenant_id, resource_type, 
                                  usage_percentage, warning_threshold, critical_threshold)
            
            # 检查配额违规
            if usage_percentage >= 100:
                self.record_quota_violation(tenant_type, tenant_id, resource_type, 
                                          current_usage, quota_limit)
        
        conn.commit()
        conn.close()
    
    def get_current_usage(self, tenant_type, tenant_id, resource_type):
        """获取当前资源使用量"""
        if resource_type == 'users':
            return self.get_user_count(tenant_type, tenant_id)
        elif resource_type == 'clients':
            return self.get_client_count(tenant_type, tenant_id)
        elif resource_type == 'projects':
            return self.get_project_count(tenant_type, tenant_id)
        elif resource_type == 'storage':
            return self.get_storage_usage(tenant_type, tenant_id)
        else:
            return 0
    
    def get_user_count(self, tenant_type, tenant_id):
        """获取用户数量"""
        try:
            if tenant_type == 'organization':
                conn = sqlite3.connect('/etc/ipv6-wireguard-manager/organizations.db')
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT COUNT(*) FROM organization_users 
                    WHERE organization_id = ?
                """, (tenant_id,))
                count = cursor.fetchone()[0]
                conn.close()
                return count
            return 0
        except:
            return 0
    
    def get_client_count(self, tenant_type, tenant_id):
        """获取客户端数量"""
        try:
            # 这里应该根据租户隔离获取客户端数量
            # 暂时返回模拟数据
            return 0
        except:
            return 0
    
    def get_project_count(self, tenant_type, tenant_id):
        """获取项目数量"""
        try:
            if tenant_type == 'organization':
                conn = sqlite3.connect('/etc/ipv6-wireguard-manager/projects.db')
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT COUNT(*) FROM projects 
                    WHERE organization_id = ? AND status = 'active'
                """, (tenant_id,))
                count = cursor.fetchone()[0]
                conn.close()
                return count
            return 0
        except:
            return 0
    
    def get_storage_usage(self, tenant_type, tenant_id):
        """获取存储使用量（字节）"""
        try:
            # 计算租户相关的存储使用量
            tenant_dir = f"/var/lib/ipv6-wireguard-manager/tenants/{tenant_type}_{tenant_id}"
            if os.path.exists(tenant_dir):
                result = subprocess.run(['du', '-sb', tenant_dir], 
                                      capture_output=True, text=True)
                if result.returncode == 0:
                    return int(result.stdout.split()[0])
            return 0
        except:
            return 0
    
    def check_quota_alerts(self, tenant_type, tenant_id, resource_type, 
                          usage_percentage, warning_threshold, critical_threshold):
        """检查配额告警"""
        alert_conn = sqlite3.connect(self.alert_db_path)
        alert_cursor = alert_conn.cursor()
        
        # 检查是否已有未解决的告警
        alert_cursor.execute("""
            SELECT COUNT(*) FROM quota_alerts 
            WHERE tenant_type = ? AND tenant_id = ? AND resource_type = ?
            AND resolved = FALSE
        """, (tenant_type, tenant_id, resource_type))
        
        has_active_alert = alert_cursor.fetchone()[0] > 0
        
        # 检查告警条件
        if usage_percentage >= critical_threshold and not has_active_alert:
            self.create_quota_alert(tenant_type, tenant_id, resource_type, 
                                  'critical', critical_threshold, usage_percentage)
        elif usage_percentage >= warning_threshold and not has_active_alert:
            self.create_quota_alert(tenant_type, tenant_id, resource_type, 
                                  'warning', warning_threshold, usage_percentage)
        elif usage_percentage < warning_threshold and has_active_alert:
            # 解决现有告警
            alert_cursor.execute("""
                UPDATE quota_alerts 
                SET resolved = TRUE, resolved_at = CURRENT_TIMESTAMP
                WHERE tenant_type = ? AND tenant_id = ? AND resource_type = ?
                AND resolved = FALSE
            """, (tenant_type, tenant_id, resource_type))
        
        alert_conn.commit()
        alert_conn.close()
    
    def create_quota_alert(self, tenant_type, tenant_id, resource_type, 
                          alert_type, threshold_percentage, current_percentage):
        """创建配额告警"""
        alert_conn = sqlite3.connect(self.alert_db_path)
        alert_cursor = alert_conn.cursor()
        
        alert_cursor.execute("""
            INSERT INTO quota_alerts 
            (tenant_type, tenant_id, resource_type, alert_type, 
             threshold_percentage, current_percentage)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (tenant_type, tenant_id, resource_type, alert_type, 
              threshold_percentage, current_percentage))
        
        alert_conn.commit()
        alert_conn.close()
        
        # 发送告警通知
        self.send_quota_alert(tenant_type, tenant_id, resource_type, 
                            alert_type, current_percentage)
    
    def send_quota_alert(self, tenant_type, tenant_id, resource_type, 
                        alert_type, current_percentage):
        """发送配额告警通知"""
        message = f"配额告警: {tenant_type}_{tenant_id} 的 {resource_type} 使用率达到 {current_percentage:.1f}%"
        print(f"[{alert_type.upper()}] {message}")
        
        # 这里可以添加邮件、Webhook等通知方式
    
    def record_quota_violation(self, tenant_type, tenant_id, resource_type, 
                              current_usage, quota_limit):
        """记录配额违规"""
        conn = sqlite3.connect(self.quota_db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO quota_violations 
            (tenant_type, tenant_id, resource_type, violation_type, 
             current_usage, quota_limit)
            VALUES (?, ?, ?, 'quota_exceeded', ?, ?)
        """, (tenant_type, tenant_id, resource_type, current_usage, quota_limit))
        
        conn.commit()
        conn.close()
    
    def cleanup_old_data(self):
        """清理旧数据"""
        conn = sqlite3.connect(self.quota_db_path)
        cursor = conn.cursor()
        
        # 删除30天前的使用历史
        cursor.execute("""
            DELETE FROM quota_usage_history 
            WHERE recorded_at < datetime('now', '-30 days')
        """)
        
        conn.commit()
        conn.close()

if __name__ == "__main__":
    quota_db = "/etc/ipv6-wireguard-manager/resource_quotas.db"
    alert_db = "/etc/ipv6-wireguard-manager/quota_alerts.db"
    
    monitor = QuotaMonitor(quota_db, alert_db)
    monitor.start_monitoring()
EOF
    
    chmod +x "${QUOTA_MONITORING_DIR}/quota_monitor.py"
}

# 创建配额告警配置
create_quota_alert_config() {
    cat > "${QUOTA_MONITORING_DIR}/quota_alerts.conf" << 'EOF'
# 资源配额告警配置

[default]
warning_threshold = 80
critical_threshold = 95
notification_methods = email,webhook
alert_cooldown = 3600  # 1小时

[email]
smtp_server = smtp.gmail.com
smtp_port = 587
smtp_username = 
smtp_password = 
alert_email = 

[webhook]
webhook_url = 
webhook_timeout = 30
webhook_retry_count = 3

[slack]
slack_webhook_url = 
slack_channel = #alerts
slack_username = QuotaMonitor

[quotas]
# 默认配额设置
default_user_quota = 100
default_client_quota = 1000
default_project_quota = 50
default_storage_quota = 10737418240  # 10GB

# 配额类型配置
[resource_types]
users = 用户数量
clients = 客户端数量
projects = 项目数量
storage = 存储空间(字节)
EOF
}

# 资源配额管理菜单
resource_quota_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 资源配额管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看配额列表"
        echo -e "${GREEN}2.${NC} 设置配额"
        echo -e "${GREEN}3.${NC} 配额使用统计"
        echo -e "${GREEN}4.${NC} 配额告警管理"
        echo -e "${GREEN}5.${NC} 配额违规记录"
        echo -e "${GREEN}6.${NC} 配额监控设置"
        echo -e "${GREEN}7.${NC} 启动配额监控"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -p "请选择操作 [0-7]: " choice
        
        case $choice in
            1) list_resource_quotas ;;
            2) set_resource_quota ;;
            3) quota_usage_statistics ;;
            4) quota_alert_management ;;
            5) quota_violation_records ;;
            6) quota_monitoring_settings ;;
            7) start_quota_monitoring ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 查看配额列表
list_resource_quotas() {
    echo -e "${SECONDARY_COLOR}=== 资源配额列表 ===${NC}"
    echo
    
    sqlite3 "$QUOTA_DB" << EOF
.mode column
.headers on
SELECT tenant_type, tenant_id, resource_type, quota_limit, current_usage,
       (current_usage * 100.0 / quota_limit) as usage_percentage,
       warning_threshold, critical_threshold, status
FROM resource_quotas
ORDER BY tenant_type, tenant_id, resource_type;
EOF
}

# 设置配额
set_resource_quota() {
    echo -e "${SECONDARY_COLOR}=== 设置资源配额 ===${NC}"
    echo
    
    local tenant_type=$(show_selection "租户类型" "organization" "project")
    local tenant_id=$(show_input "租户ID" "")
    local resource_type=$(show_selection "资源类型" "users" "clients" "projects" "storage")
    local quota_limit=$(show_input "配额限制" "")
    local warning_threshold=$(show_input "警告阈值(%)" "80")
    local critical_threshold=$(show_input "严重阈值(%)" "95")
    
    if [[ -n "$tenant_type" && -n "$tenant_id" && -n "$resource_type" && -n "$quota_limit" ]]; then
        sqlite3 "$QUOTA_DB" << EOF
INSERT OR REPLACE INTO resource_quotas 
(tenant_type, tenant_id, resource_type, quota_limit, warning_threshold, critical_threshold)
VALUES ('$tenant_type', $tenant_id, '$resource_type', $quota_limit, $warning_threshold, $critical_threshold);
EOF
        
        show_success "资源配额已设置"
    else
        show_error "所有字段都不能为空"
    fi
}

# 配额使用统计
quota_usage_statistics() {
    echo -e "${SECONDARY_COLOR}=== 配额使用统计 ===${NC}"
    echo
    
    echo "总体统计:"
    sqlite3 "$QUOTA_DB" << EOF
.mode column
.headers on
SELECT 
    resource_type,
    COUNT(*) as total_quotas,
    AVG(current_usage * 100.0 / quota_limit) as avg_usage_percentage,
    MAX(current_usage * 100.0 / quota_limit) as max_usage_percentage,
    SUM(CASE WHEN current_usage * 100.0 / quota_limit >= 80 THEN 1 ELSE 0 END) as warning_count,
    SUM(CASE WHEN current_usage * 100.0 / quota_limit >= 95 THEN 1 ELSE 0 END) as critical_count
FROM resource_quotas
WHERE status = 'active'
GROUP BY resource_type;
EOF
    
    echo
    echo "使用历史趋势:"
    sqlite3 "$QUOTA_DB" << EOF
.mode column
.headers on
SELECT 
    DATE(recorded_at) as date,
    resource_type,
    AVG(usage_percentage) as avg_usage_percentage,
    MAX(usage_percentage) as max_usage_percentage
FROM quota_usage_history
WHERE recorded_at >= datetime('now', '-7 days')
GROUP BY DATE(recorded_at), resource_type
ORDER BY date DESC;
EOF
}

# 配额告警管理
quota_alert_management() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 配额告警管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看告警列表"
        echo -e "${GREEN}2.${NC} 确认告警"
        echo -e "${GREEN}3.${NC} 解决告警"
        echo -e "${GREEN}4.${NC} 告警规则设置"
        echo -e "${GREEN}5.${NC} 告警统计"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -p "请选择操作 [0-5]: " choice
        
        case $choice in
            1) list_quota_alerts ;;
            2) acknowledge_quota_alert ;;
            3) resolve_quota_alert ;;
            4) quota_alert_rules_settings ;;
            5) quota_alert_statistics ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 查看告警列表
list_quota_alerts() {
    echo -e "${SECONDARY_COLOR}=== 配额告警列表 ===${NC}"
    echo
    
    sqlite3 "$QUOTA_ALERTS_DB" << EOF
.mode column
.headers on
SELECT id, tenant_type, tenant_id, resource_type, alert_type, 
       threshold_percentage, current_percentage, alert_time,
       acknowledged, resolved
FROM quota_alerts
ORDER BY alert_time DESC
LIMIT 50;
EOF
}

# 启动配额监控
start_quota_monitoring() {
    log_info "启动配额监控..."
    
    # 检查是否已在运行
    if pgrep -f "quota_monitor.py" > /dev/null; then
        show_warn "配额监控已在运行"
        return
    fi
    
    # 启动监控脚本
    nohup python3 "${QUOTA_MONITORING_DIR}/quota_monitor.py" > "${QUOTA_MONITORING_DIR}/monitor.log" 2>&1 &
    
    # 保存PID
    echo $! > "${QUOTA_MONITORING_DIR}/monitor.pid"
    
    show_success "配额监控已启动"
}

# 停止配额监控
stop_quota_monitoring() {
    log_info "停止配额监控..."
    
    if [[ -f "${QUOTA_MONITORING_DIR}/monitor.pid" ]]; then
        local pid=$(cat "${QUOTA_MONITORING_DIR}/monitor.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            show_success "配额监控已停止"
        else
            show_warn "配额监控未运行"
        fi
        rm -f "${QUOTA_MONITORING_DIR}/monitor.pid"
    else
        show_warn "配额监控未运行"
    fi
}

# 导出函数
export -f init_resource_quota init_quota_databases create_quota_monitoring_script
export -f create_quota_alert_config resource_quota_menu list_resource_quotas
export -f set_resource_quota quota_usage_statistics quota_alert_management
export -f list_quota_alerts start_quota_monitoring stop_quota_monitoring
