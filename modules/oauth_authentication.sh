#!/bin/bash
# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"

# 确保日志相关变量已定义
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
fi

# OAuth 2.0认证模块
# 实现OAuth 2.0/OpenID Connect集成、多因素认证、细粒度权限控制

# OAuth配置
OAUTH_CONFIG_DIR="${CONFIG_DIR}/oauth"
OAUTH_CLIENTS_DB="${OAUTH_CONFIG_DIR}/clients.db"
OAUTH_TOKENS_DB="${OAUTH_CONFIG_DIR}/tokens.db"
OAUTH_SCOPES_DB="${OAUTH_CONFIG_DIR}/scopes.db"

# MFA配置
MFA_CONFIG_DIR="${CONFIG_DIR}/mfa"
MFA_SECRETS_DB="${MFA_CONFIG_DIR}/secrets.db"
MFA_BACKUP_CODES_DB="${MFA_CONFIG_DIR}/backup_codes.db"

# 权限配置
RBAC_CONFIG_DIR="${CONFIG_DIR}/rbac"
RBAC_ROLES_DB="${RBAC_CONFIG_DIR}/roles.db"
RBAC_PERMISSIONS_DB="${RBAC_CONFIG_DIR}/permissions.db"
RBAC_USER_ROLES_DB="${RBAC_CONFIG_DIR}/user_roles.db"

# 审计配置
AUDIT_CONFIG_DIR="${CONFIG_DIR}/audit"
AUDIT_LOGS_DB="${AUDIT_CONFIG_DIR}/audit_logs.db"
AUDIT_EVENTS_DB="${AUDIT_CONFIG_DIR}/audit_events.db"

# 初始化OAuth认证系统
init_oauth_authentication() {
    log_info "初始化OAuth认证系统..."
    
    # 创建配置目录
    mkdir -p "$OAUTH_CONFIG_DIR" "$MFA_CONFIG_DIR" "$RBAC_CONFIG_DIR" "$AUDIT_CONFIG_DIR"
    
    # 初始化OAuth数据库
    init_oauth_databases
    
    # 初始化MFA系统
    init_mfa_system
    
    # 初始化RBAC系统
    init_rbac_system
    
    # 初始化审计系统
    init_audit_system
    
    # 创建OAuth客户端
    create_default_oauth_clients
    
    # 创建默认角色和权限
    create_default_roles_permissions
    
    log_info "OAuth认证系统初始化完成"
}

# 初始化OAuth数据库
init_oauth_databases() {
    log_info "初始化OAuth数据库..."
    
    # OAuth客户端数据库
    sqlite3 "$OAUTH_CLIENTS_DB" << EOF
CREATE TABLE IF NOT EXISTS oauth_clients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_id TEXT UNIQUE NOT NULL,
    client_secret TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    redirect_uris TEXT NOT NULL,
    scopes TEXT NOT NULL,
    grant_types TEXT NOT NULL,
    response_types TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS oauth_tokens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    access_token TEXT UNIQUE NOT NULL,
    refresh_token TEXT UNIQUE,
    client_id TEXT NOT NULL,
    user_id INTEGER NOT NULL,
    scopes TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active',
    FOREIGN KEY (client_id) REFERENCES oauth_clients (client_id),
    FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE IF NOT EXISTS oauth_authorization_codes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT UNIQUE NOT NULL,
    client_id TEXT NOT NULL,
    user_id INTEGER NOT NULL,
    redirect_uri TEXT NOT NULL,
    scopes TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    used BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (client_id) REFERENCES oauth_clients (client_id),
    FOREIGN KEY (user_id) REFERENCES users (id)
);
EOF

    # OAuth作用域数据库
    sqlite3 "$OAUTH_SCOPES_DB" << EOF
CREATE TABLE IF NOT EXISTS oauth_scopes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scope TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT OR IGNORE INTO oauth_scopes (scope, name, description) VALUES
('read', '读取权限', '读取系统信息的权限'),
('write', '写入权限', '修改系统配置的权限'),
('admin', '管理权限', '系统管理权限'),
('user:read', '用户读取', '读取用户信息的权限'),
('user:write', '用户写入', '修改用户信息的权限'),
('client:read', '客户端读取', '读取客户端信息的权限'),
('client:write', '客户端写入', '修改客户端信息的权限'),
('config:read', '配置读取', '读取配置信息的权限'),
('config:write', '配置写入', '修改配置信息的权限'),
('monitor:read', '监控读取', '读取监控信息的权限');
EOF
}

# 初始化MFA系统
init_mfa_system() {
    log_info "初始化MFA系统..."
    
    # MFA密钥数据库
    sqlite3 "$MFA_SECRETS_DB" << EOF
CREATE TABLE IF NOT EXISTS mfa_secrets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    secret TEXT NOT NULL,
    algorithm TEXT DEFAULT 'SHA1',
    digits INTEGER DEFAULT 6,
    period INTEGER DEFAULT 30,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active',
    FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE IF NOT EXISTS mfa_backup_codes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    code TEXT NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    used_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users (id)
);
EOF
}

# 初始化RBAC系统
init_rbac_system() {
    log_info "初始化RBAC系统..."
    
    # 角色数据库
    sqlite3 "$RBAC_ROLES_DB" << EOF
CREATE TABLE IF NOT EXISTS roles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS permissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    resource TEXT NOT NULL,
    action TEXT NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS role_permissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    role_id INTEGER NOT NULL,
    permission_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles (id),
    FOREIGN KEY (permission_id) REFERENCES permissions (id),
    UNIQUE(role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS user_roles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    role_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id),
    FOREIGN KEY (role_id) REFERENCES roles (id),
    UNIQUE(user_id, role_id)
);
EOF

    # 权限数据库
    sqlite3 "$RBAC_PERMISSIONS_DB" << EOF
CREATE TABLE IF NOT EXISTS resource_permissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    resource TEXT NOT NULL,
    action TEXT NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT OR IGNORE INTO resource_permissions (resource, action, description) VALUES
('user', 'create', '创建用户'),
('user', 'read', '读取用户信息'),
('user', 'update', '更新用户信息'),
('user', 'delete', '删除用户'),
('client', 'create', '创建客户端'),
('client', 'read', '读取客户端信息'),
('client', 'update', '更新客户端信息'),
('client', 'delete', '删除客户端'),
('config', 'read', '读取配置'),
('config', 'update', '更新配置'),
('monitor', 'read', '读取监控信息'),
('system', 'admin', '系统管理');
EOF
}

# 初始化审计系统
init_audit_system() {
    log_info "初始化审计系统..."
    
    # 审计日志数据库
    sqlite3 "$AUDIT_LOGS_DB" << EOF
CREATE TABLE IF NOT EXISTS audit_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    username TEXT,
    action TEXT NOT NULL,
    resource TEXT NOT NULL,
    resource_id TEXT,
    details TEXT,
    ip_address TEXT,
    user_agent TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'success',
    FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE IF NOT EXISTS audit_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT NOT NULL,
    severity TEXT NOT NULL,
    message TEXT NOT NULL,
    details TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at DATETIME,
    resolved_by INTEGER,
    FOREIGN KEY (resolved_by) REFERENCES users (id)
);
EOF
}

# 创建默认OAuth客户端
create_default_oauth_clients() {
    log_info "创建默认OAuth客户端..."
    
    # 创建Web管理界面客户端
    local web_client_id="web-manager"
    local web_client_secret=$(generate_client_secret)
    
    sqlite3 "$OAUTH_CLIENTS_DB" << EOF
INSERT OR IGNORE INTO oauth_clients (
    client_id, client_secret, name, description, 
    redirect_uris, scopes, grant_types, response_types
) VALUES (
    '$web_client_id', '$web_client_secret', 'Web管理界面', 'Web管理界面OAuth客户端',
    'http://localhost:8080/callback,https://localhost:8443/callback', 
    'read write user:read user:write client:read client:write config:read config:write monitor:read',
    'authorization_code,refresh_token', 'code'
);
EOF

    # 创建API客户端
    local api_client_id="api-client"
    local api_client_secret=$(generate_client_secret)
    
    sqlite3 "$OAUTH_CLIENTS_DB" << EOF
INSERT OR IGNORE INTO oauth_clients (
    client_id, client_secret, name, description,
    redirect_uris, scopes, grant_types, response_types
) VALUES (
    '$api_client_id', '$api_client_secret', 'API客户端', 'API访问OAuth客户端',
    'urn:ietf:wg:oauth:2.0:oob', 
    'read write user:read client:read client:write config:read monitor:read',
    'client_credentials,authorization_code', 'code'
);
EOF

    log_info "默认OAuth客户端已创建"
}

# 创建默认角色和权限
create_default_roles_permissions() {
    log_info "创建默认角色和权限..."
    
    # 创建角色
    sqlite3 "$RBAC_ROLES_DB" << EOF
INSERT OR IGNORE INTO roles (name, display_name, description) VALUES
('super_admin', '超级管理员', '系统超级管理员，拥有所有权限'),
('admin', '管理员', '系统管理员，拥有大部分管理权限'),
('operator', '操作员', '系统操作员，拥有操作权限'),
('user', '普通用户', '普通用户，拥有基本权限'),
('readonly', '只读用户', '只读用户，只能查看信息');
EOF

    # 创建权限
    sqlite3 "$RBAC_ROLES_DB" << EOF
INSERT OR IGNORE INTO permissions (name, resource, action) VALUES
('user.create', 'user', 'create'),
('user.read', 'user', 'read'),
('user.update', 'user', 'update'),
('user.delete', 'user', 'delete'),
('client.create', 'client', 'create'),
('client.read', 'client', 'read'),
('client.update', 'client', 'update'),
('client.delete', 'client', 'delete'),
('config.read', 'config', 'read'),
('config.update', 'config', 'update'),
('monitor.read', 'monitor', 'read'),
('system.admin', 'system', 'admin');
EOF

    # 分配角色权限
    assign_role_permissions
    
    log_info "默认角色和权限已创建"
}

# 分配角色权限
assign_role_permissions() {
    # 超级管理员 - 所有权限
    sqlite3 "$RBAC_ROLES_DB" << EOF
INSERT OR IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p 
WHERE r.name = 'super_admin';
EOF

    # 管理员 - 大部分权限
    sqlite3 "$RBAC_ROLES_DB" << EOF
INSERT OR IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p 
WHERE r.name = 'admin' AND p.name != 'system.admin';
EOF

    # 操作员 - 操作权限
    sqlite3 "$RBAC_ROLES_DB" << EOF
INSERT OR IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p 
WHERE r.name = 'operator' AND p.name IN (
    'client.create', 'client.read', 'client.update', 'client.delete',
    'config.read', 'monitor.read'
);
EOF

    # 普通用户 - 基本权限
    sqlite3 "$RBAC_ROLES_DB" << EOF
INSERT OR IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p 
WHERE r.name = 'user' AND p.name IN (
    'client.read', 'config.read', 'monitor.read'
);
EOF

    # 只读用户 - 只读权限
    sqlite3 "$RBAC_ROLES_DB" << EOF
INSERT OR IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p 
WHERE r.name = 'readonly' AND p.name IN (
    'client.read', 'config.read', 'monitor.read'
);
EOF
}

# OAuth认证菜单
oauth_authentication_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== OAuth认证管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} OAuth客户端管理"
        echo -e "${GREEN}2.${NC} OAuth令牌管理"
        echo -e "${GREEN}3.${NC} 多因素认证(MFA)管理"
        echo -e "${GREEN}4.${NC} 角色权限管理(RBAC)"
        echo -e "${GREEN}5.${NC} 安全审计日志"
        echo -e "${GREEN}6.${NC} 安全事件管理"
        echo -e "${GREEN}7.${NC} 安全配置检查"
        echo -e "${GREEN}8.${NC} 用户权限测试"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 [0-8]: " choice
        
        case $choice in
            1) oauth_client_management ;;
            2) oauth_token_management ;;
            3) mfa_management ;;
            4) rbac_management ;;
            5) audit_log_management ;;
            6) security_event_management ;;
            7) security_config_check ;;
            8) user_permission_test ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# OAuth客户端管理
oauth_client_management() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== OAuth客户端管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看客户端列表"
        echo -e "${GREEN}2.${NC} 添加OAuth客户端"
        echo -e "${GREEN}3.${NC} 编辑OAuth客户端"
        echo -e "${GREEN}4.${NC} 删除OAuth客户端"
        echo -e "${GREEN}5.${NC} 重置客户端密钥"
        echo -e "${GREEN}6.${NC} 查看客户端详情"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -p "请选择操作 [0-6]: " choice
        
        case $choice in
            1) show_oauth_clients ;;
            2) add_oauth_client ;;
            3) edit_oauth_client ;;
            4) delete_oauth_client ;;
            5) reset_client_secret ;;
            6) show_client_details ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 显示OAuth客户端列表
show_oauth_clients() {
    echo -e "${SECONDARY_COLOR}=== OAuth客户端列表 ===${NC}"
    echo
    
    sqlite3 "$OAUTH_CLIENTS_DB" << EOF
.mode column
.headers on
SELECT client_id, name, status, created_at FROM oauth_clients ORDER BY created_at DESC;
EOF
}

# 添加OAuth客户端
add_oauth_client() {
    echo -e "${SECONDARY_COLOR}=== 添加OAuth客户端 ===${NC}"
    echo
    
    local client_id=$(show_input "客户端ID" "")
    local name=$(show_input "客户端名称" "")
    local description=$(show_input "客户端描述" "")
    local redirect_uris=$(show_input "重定向URI (多个用逗号分隔)" "")
    local scopes=$(show_selection "作用域" "read" "write" "admin" "user:read" "user:write" "client:read" "client:write" "config:read" "config:write" "monitor:read")
    local grant_types=$(show_selection "授权类型" "authorization_code" "client_credentials" "refresh_token" "password")
    local response_types=$(show_selection "响应类型" "code" "token" "id_token")
    
    if [[ -n "$client_id" && -n "$name" && -n "$redirect_uris" ]]; then
        local client_secret=$(generate_client_secret)
        
        sqlite3 "$OAUTH_CLIENTS_DB" << EOF
INSERT INTO oauth_clients (
    client_id, client_secret, name, description, 
    redirect_uris, scopes, grant_types, response_types
) VALUES (
    '$client_id', '$client_secret', '$name', '$description',
    '$redirect_uris', '$scopes', '$grant_types', '$response_types'
);
EOF
        
        show_success "OAuth客户端已添加: $client_id"
        echo "客户端密钥: $client_secret"
    else
        show_error "客户端ID、名称和重定向URI不能为空"
    fi
}

# 多因素认证管理
mfa_management() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 多因素认证管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 启用用户MFA"
        echo -e "${GREEN}2.${NC} 禁用用户MFA"
        echo -e "${GREEN}3.${NC} 生成MFA密钥"
        echo -e "${GREEN}4.${NC} 生成备用代码"
        echo -e "${GREEN}5.${NC} 验证MFA令牌"
        echo -e "${GREEN}6.${NC} 查看MFA状态"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -p "请选择操作 [0-6]: " choice
        
        case $choice in
            1) enable_user_mfa ;;
            2) disable_user_mfa ;;
            3) generate_mfa_secret ;;
            4) generate_backup_codes ;;
            5) verify_mfa_token ;;
            6) show_mfa_status ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 启用用户MFA
enable_user_mfa() {
    echo -e "${SECONDARY_COLOR}=== 启用用户MFA ===${NC}"
    echo
    
    local username=$(show_input "用户名" "")
    
    if [[ -n "$username" ]]; then
        # 检查用户是否存在
        local user_id=$(sqlite3 "$USERS_DB" "SELECT id FROM users WHERE username = '$username'")
        
        if [[ -n "$user_id" ]]; then
            # 生成MFA密钥
            local mfa_secret=$(generate_mfa_secret)
            
            # 保存MFA密钥
            sqlite3 "$MFA_SECRETS_DB" << EOF
INSERT OR REPLACE INTO mfa_secrets (user_id, secret) VALUES ($user_id, '$mfa_secret');
EOF
            
            # 生成备用代码
            generate_user_backup_codes "$user_id"
            
            show_success "用户MFA已启用: $username"
            echo "MFA密钥: $mfa_secret"
            echo "请使用Google Authenticator等应用扫描二维码"
        else
            show_error "用户不存在: $username"
        fi
    else
        show_error "用户名不能为空"
    fi
}

# 生成MFA密钥
generate_mfa_secret() {
    # 生成32字节的随机密钥
    openssl rand -base32 32
}

# 生成用户备用代码
generate_user_backup_codes() {
    local user_id="$1"
    
    # 生成10个备用代码
    for i in {1..10}; do
        local code=$(openssl rand -hex 4)
        sqlite3 "$MFA_BACKUP_CODES_DB" << EOF
INSERT INTO mfa_backup_codes (user_id, code) VALUES ($user_id, '$code');
EOF
    done
    
    log_info "用户 $user_id 的备用代码已生成"
}

# 角色权限管理
rbac_management() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 角色权限管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看角色列表"
        echo -e "${GREEN}2.${NC} 添加角色"
        echo -e "${GREEN}3.${NC} 编辑角色"
        echo -e "${GREEN}4.${NC} 删除角色"
        echo -e "${GREEN}5.${NC} 分配用户角色"
        echo -e "${GREEN}6.${NC} 移除用户角色"
        echo -e "${GREEN}7.${NC} 查看权限列表"
        echo -e "${GREEN}8.${NC} 分配角色权限"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -p "请选择操作 [0-8]: " choice
        
        case $choice in
            1) show_roles ;;
            2) add_role ;;
            3) edit_role ;;
            4) delete_role ;;
            5) assign_user_role ;;
            6) remove_user_role ;;
            7) show_permissions ;;
            8) assign_role_permission ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 显示角色列表
show_roles() {
    echo -e "${SECONDARY_COLOR}=== 角色列表 ===${NC}"
    echo
    
    sqlite3 "$RBAC_ROLES_DB" << EOF
.mode column
.headers on
SELECT r.name, r.display_name, r.description, r.status, COUNT(ur.user_id) as user_count
FROM roles r
LEFT JOIN user_roles ur ON r.id = ur.role_id
GROUP BY r.id, r.name, r.display_name, r.description, r.status
ORDER BY r.name;
EOF
}

# 添加角色
add_role() {
    echo -e "${SECONDARY_COLOR}=== 添加角色 ===${NC}"
    echo
    
    local name=$(show_input "角色名称" "")
    local display_name=$(show_input "显示名称" "")
    local description=$(show_input "角色描述" "")
    
    if [[ -n "$name" && -n "$display_name" ]]; then
        sqlite3 "$RBAC_ROLES_DB" << EOF
INSERT INTO roles (name, display_name, description) 
VALUES ('$name', '$display_name', '$description');
EOF
        
        show_success "角色已添加: $name"
    else
        show_error "角色名称和显示名称不能为空"
    fi
}

# 分配用户角色
assign_user_role() {
    echo -e "${SECONDARY_COLOR}=== 分配用户角色 ===${NC}"
    echo
    
    local username=$(show_input "用户名" "")
    local role_name=$(show_input "角色名称" "")
    
    if [[ -n "$username" && -n "$role_name" ]]; then
        # 获取用户ID
        local user_id=$(sqlite3 "$USERS_DB" "SELECT id FROM users WHERE username = '$username'")
        # 获取角色ID
        local role_id=$(sqlite3 "$RBAC_ROLES_DB" "SELECT id FROM roles WHERE name = '$role_name'")
        
        if [[ -n "$user_id" && -n "$role_id" ]]; then
            sqlite3 "$RBAC_ROLES_DB" << EOF
INSERT OR IGNORE INTO user_roles (user_id, role_id) VALUES ($user_id, $role_id);
EOF
            
            show_success "用户角色已分配: $username -> $role_name"
        else
            show_error "用户或角色不存在"
        fi
    else
        show_error "用户名和角色名称不能为空"
    fi
}

# 安全审计日志管理
audit_log_management() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 安全审计日志管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看审计日志"
        echo -e "${GREEN}2.${NC} 搜索审计日志"
        echo -e "${GREEN}3.${NC} 导出审计日志"
        echo -e "${GREEN}4.${NC} 清理审计日志"
        echo -e "${GREEN}5.${NC} 审计日志统计"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -p "请选择操作 [0-5]: " choice
        
        case $choice in
            1) show_audit_logs ;;
            2) search_audit_logs ;;
            3) export_audit_logs ;;
            4) cleanup_audit_logs ;;
            5) audit_log_statistics ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 查看审计日志
show_audit_logs() {
    echo -e "${SECONDARY_COLOR}=== 审计日志 ===${NC}"
    echo
    
    local limit=$(show_input "显示条数 (默认50)" "50")
    
    sqlite3 "$AUDIT_LOGS_DB" << EOF
.mode column
.headers on
SELECT username, action, resource, ip_address, timestamp, status
FROM audit_logs 
ORDER BY timestamp DESC 
LIMIT $limit;
EOF
}

# 记录审计日志
log_audit_event() {
    local user_id="$1"
    local username="$2"
    local action="$3"
    local resource="$4"
    local resource_id="$5"
    local details="$6"
    local ip_address="$7"
    local user_agent="$8"
    local status="${9:-success}"
    
    sqlite3 "$AUDIT_LOGS_DB" << EOF
INSERT INTO audit_logs (
    user_id, username, action, resource, resource_id, 
    details, ip_address, user_agent, status
) VALUES (
    $user_id, '$username', '$action', '$resource', '$resource_id',
    '$details', '$ip_address', '$user_agent', '$status'
);
EOF
}

# 安全事件管理
security_event_management() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 安全事件管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看安全事件"
        echo -e "${GREEN}2.${NC} 创建安全事件"
        echo -e "${GREEN}3.${NC} 解决安全事件"
        echo -e "${GREEN}4.${NC} 安全事件统计"
        echo -e "${GREEN}5.${NC} 安全事件告警"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -p "请选择操作 [0-5]: " choice
        
        case $choice in
            1) show_security_events ;;
            2) create_security_event ;;
            3) resolve_security_event ;;
            4) security_event_statistics ;;
            5) security_event_alerts ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 查看安全事件
show_security_events() {
    echo -e "${SECONDARY_COLOR}=== 安全事件 ===${NC}"
    echo
    
    sqlite3 "$AUDIT_EVENTS_DB" << EOF
.mode column
.headers on
SELECT event_type, severity, message, timestamp, resolved
FROM audit_events 
ORDER BY timestamp DESC 
LIMIT 50;
EOF
}

# 创建安全事件
create_security_event() {
    echo -e "${SECONDARY_COLOR}=== 创建安全事件 ===${NC}"
    echo
    
    local event_type=$(show_selection "事件类型" "login_failure" "permission_denied" "suspicious_activity" "system_error" "security_violation")
    local severity=$(show_selection "严重程度" "low" "medium" "high" "critical")
    local message=$(show_input "事件消息" "")
    local details=$(show_input "详细信息" "")
    
    if [[ -n "$event_type" && -n "$severity" && -n "$message" ]]; then
        sqlite3 "$AUDIT_EVENTS_DB" << EOF
INSERT INTO audit_events (event_type, severity, message, details) 
VALUES ('$event_type', '$severity', '$message', '$details');
EOF
        
        show_success "安全事件已创建"
    else
        show_error "事件类型、严重程度和消息不能为空"
    fi
}

# 安全配置检查
security_config_check() {
    echo -e "${SECONDARY_COLOR}=== 安全配置检查 ===${NC}"
    echo
    
    echo "检查项目:"
    echo "1. 检查用户密码强度..."
    check_password_strength
    
    echo "2. 检查MFA启用状态..."
    check_mfa_status
    
    echo "3. 检查权限配置..."
    check_permission_config
    
    echo "4. 检查审计日志配置..."
    check_audit_config
    
    echo "5. 检查OAuth客户端配置..."
    check_oauth_config
    
    echo "6. 检查系统安全设置..."
    check_system_security
    
    show_success "安全配置检查完成"
}

# 检查密码强度
check_password_strength() {
    local weak_passwords=$(sqlite3 "$USERS_DB" "SELECT COUNT(*) FROM users WHERE LENGTH(password_hash) < 32")
    if [[ "$weak_passwords" -gt 0 ]]; then
        show_warn "发现 $weak_passwords 个弱密码用户"
    else
        show_success "密码强度检查通过"
    fi
}

# 检查MFA状态
check_mfa_status() {
    local total_users=$(sqlite3 "$USERS_DB" "SELECT COUNT(*) FROM users WHERE status = 'active'")
    local mfa_users=$(sqlite3 "$MFA_SECRETS_DB" "SELECT COUNT(DISTINCT user_id) FROM mfa_secrets WHERE status = 'active'")
    
    if [[ "$total_users" -gt 0 ]]; then
        local mfa_percentage=$((mfa_users * 100 / total_users))
        echo "MFA启用率: $mfa_percentage% ($mfa_users/$total_users)"
        
        if [[ "$mfa_percentage" -lt 50 ]]; then
            show_warn "MFA启用率较低，建议启用更多用户的MFA"
        else
            show_success "MFA启用率良好"
        fi
    fi
}

# 检查权限配置
check_permission_config() {
    local orphaned_permissions=$(sqlite3 "$RBAC_ROLES_DB" "SELECT COUNT(*) FROM role_permissions rp LEFT JOIN roles r ON rp.role_id = r.id WHERE r.id IS NULL")
    if [[ "$orphaned_permissions" -gt 0 ]]; then
        show_warn "发现 $orphaned_permissions 个孤立权限"
    else
        show_success "权限配置检查通过"
    fi
}

# 检查审计配置
check_audit_config() {
    local recent_logs=$(sqlite3 "$AUDIT_LOGS_DB" "SELECT COUNT(*) FROM audit_logs WHERE timestamp > datetime('now', '-1 day')")
    if [[ "$recent_logs" -eq 0 ]]; then
        show_warn "最近24小时内没有审计日志记录"
    else
        show_success "审计日志记录正常: $recent_logs 条记录"
    fi
}

# 检查OAuth配置
check_oauth_config() {
    local active_clients=$(sqlite3 "$OAUTH_CLIENTS_DB" "SELECT COUNT(*) FROM oauth_clients WHERE status = 'active'")
    local expired_tokens=$(sqlite3 "$OAUTH_TOKENS_DB" "SELECT COUNT(*) FROM oauth_tokens WHERE expires_at < datetime('now')")
    
    echo "活跃OAuth客户端: $active_clients"
    if [[ "$expired_tokens" -gt 0 ]]; then
        show_warn "发现 $expired_tokens 个过期令牌"
    else
        show_success "OAuth令牌状态正常"
    fi
}

# 检查系统安全设置
check_system_security() {
    # 检查防火墙状态
    if command -v ufw &> /dev/null; then
        local ufw_status=$(ufw status | grep "Status" | awk '{print $2}')
        if [[ "$ufw_status" == "active" ]]; then
            show_success "UFW防火墙已启用"
        else
            show_warn "UFW防火墙未启用"
        fi
    fi
    
    # 检查SSH配置
    if [[ -f "/etc/ssh/sshd_config" ]]; then
        local ssh_password_auth=$(grep "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}')
        if [[ "$ssh_password_auth" == "no" ]]; then
            show_success "SSH密码认证已禁用"
        else
            show_warn "SSH密码认证已启用，建议禁用"
        fi
    fi
}

# 用户权限测试
user_permission_test() {
    echo -e "${SECONDARY_COLOR}=== 用户权限测试 ===${NC}"
    echo
    
    local username=$(show_input "测试用户名" "")
    local resource=$(show_input "资源" "user")
    local action=$(show_input "操作" "read")
    
    if [[ -n "$username" && -n "$resource" && -n "$action" ]]; then
        if check_user_permission "$username" "$resource" "$action"; then
            show_success "用户 $username 有权限执行 $action 操作 $resource"
        else
            show_error "用户 $username 没有权限执行 $action 操作 $resource"
        fi
    else
        show_error "用户名、资源和操作不能为空"
    fi
}

# 检查用户权限
check_user_permission() {
    local username="$1"
    local resource="$2"
    local action="$3"
    
    # 获取用户ID
    local user_id=$(sqlite3 "$USERS_DB" "SELECT id FROM users WHERE username = '$username'")
    
    if [[ -z "$user_id" ]]; then
        return 1
    fi
    
    # 检查用户是否有对应权限
    local has_permission=$(sqlite3 "$RBAC_ROLES_DB" << EOF
SELECT COUNT(*) FROM user_roles ur
JOIN role_permissions rp ON ur.role_id = rp.role_id
JOIN permissions p ON rp.permission_id = p.id
WHERE ur.user_id = $user_id AND p.resource = '$resource' AND p.action = '$action';
EOF
)
    
    if [[ "$has_permission" -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

# 生成客户端密钥
generate_client_secret() {
    openssl rand -base64 32
}

# 导出函数
export -f init_oauth_authentication init_oauth_databases init_mfa_system init_rbac_system
export -f init_audit_system create_default_oauth_clients create_default_roles_permissions
export -f assign_role_permissions oauth_authentication_menu oauth_client_management
export -f show_oauth_clients add_oauth_client mfa_management enable_user_mfa
export -f generate_mfa_secret generate_user_backup_codes rbac_management show_roles
export -f add_role assign_user_role audit_log_management show_audit_logs
export -f log_audit_event security_event_management show_security_events
export -f create_security_event security_config_check check_password_strength
export -f check_mfa_status check_permission_config check_audit_config
export -f check_oauth_config check_system_security user_permission_test
export -f check_user_permission generate_client_secret
