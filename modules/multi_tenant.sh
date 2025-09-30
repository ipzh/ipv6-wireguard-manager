#!/bin/bash
# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"

# 确保日志相关变量已定义
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
fi

# 多租户模块
# 实现多组织/多项目隔离支持

# 多租户配置
MULTI_TENANT_DB="${CONFIG_DIR}/multi_tenant.db"
ORGANIZATIONS_DB="${CONFIG_DIR}/organizations.db"
PROJECTS_DB="${CONFIG_DIR}/projects.db"
TENANT_ISOLATION_DIR="${CONFIG_DIR}/tenant_isolation"

# 初始化多租户模块
init_multi_tenant() {
    log_info "初始化多租户模块..."
    
    # 创建目录
    mkdir -p "$TENANT_ISOLATION_DIR"
    
    # 初始化多租户数据库
    init_multi_tenant_databases
    
    # 创建默认组织
    create_default_organization
    
    # 创建租户隔离配置
    create_tenant_isolation_config
    
    log_info "多租户模块初始化完成"
}

# 初始化多租户数据库
init_multi_tenant_databases() {
    log_info "初始化多租户数据库..."
    
    # 组织数据库
    sqlite3 "$ORGANIZATIONS_DB" << EOF
CREATE TABLE IF NOT EXISTS organizations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    description TEXT,
    domain TEXT,
    admin_user_id INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active',
    settings TEXT DEFAULT '{}',
    FOREIGN KEY (admin_user_id) REFERENCES users (id)
);

CREATE TABLE IF NOT EXISTS organization_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    organization_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    role TEXT DEFAULT 'member',
    joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations (id),
    FOREIGN KEY (user_id) REFERENCES users (id),
    UNIQUE(organization_id, user_id)
);

CREATE TABLE IF NOT EXISTS organization_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    organization_id INTEGER NOT NULL,
    setting_key TEXT NOT NULL,
    setting_value TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations (id),
    UNIQUE(organization_id, setting_key)
);
EOF

    # 项目数据库
    sqlite3 "$PROJECTS_DB" << EOF
CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    organization_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    display_name TEXT NOT NULL,
    description TEXT,
    owner_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active',
    settings TEXT DEFAULT '{}',
    FOREIGN KEY (organization_id) REFERENCES organizations (id),
    FOREIGN KEY (owner_id) REFERENCES users (id),
    UNIQUE(organization_id, name)
);

CREATE TABLE IF NOT EXISTS project_members (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    role TEXT DEFAULT 'member',
    permissions TEXT DEFAULT '[]',
    joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects (id),
    FOREIGN KEY (user_id) REFERENCES users (id),
    UNIQUE(project_id, user_id)
);

CREATE TABLE IF NOT EXISTS project_resources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id TEXT NOT NULL,
    resource_name TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects (id),
    UNIQUE(project_id, resource_type, resource_id)
);
EOF

    # 多租户数据库
    sqlite3 "$MULTI_TENANT_DB" << EOF
CREATE TABLE IF NOT EXISTS tenant_isolation (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_type TEXT NOT NULL,
    tenant_id INTEGER NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id TEXT NOT NULL,
    isolation_level TEXT DEFAULT 'strict',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES organizations (id),
    UNIQUE(tenant_type, tenant_id, resource_type, resource_id)
);

CREATE TABLE IF NOT EXISTS tenant_quotas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_type TEXT NOT NULL,
    tenant_id INTEGER NOT NULL,
    resource_type TEXT NOT NULL,
    quota_limit INTEGER NOT NULL,
    current_usage INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES organizations (id),
    UNIQUE(tenant_type, tenant_id, resource_type)
);

CREATE TABLE IF NOT EXISTS tenant_permissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_type TEXT NOT NULL,
    tenant_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    permission TEXT NOT NULL,
    granted BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES organizations (id),
    FOREIGN KEY (user_id) REFERENCES users (id),
    UNIQUE(tenant_type, tenant_id, user_id, permission)
);
EOF
}

# 创建默认组织
create_default_organization() {
    log_info "创建默认组织..."
    
    # 检查是否已有默认组织
    local default_org=$(sqlite3 "$ORGANIZATIONS_DB" "SELECT id FROM organizations WHERE name = 'default'")
    
    if [[ -z "$default_org" ]]; then
        sqlite3 "$ORGANIZATIONS_DB" << EOF
INSERT INTO organizations (name, display_name, description, admin_user_id) 
VALUES ('default', '默认组织', '系统默认组织', 1);
EOF
        
        # 设置默认配额
        sqlite3 "$MULTI_TENANT_DB" << EOF
INSERT INTO tenant_quotas (tenant_type, tenant_id, resource_type, quota_limit) VALUES
('organization', 1, 'users', 100),
('organization', 1, 'clients', 1000),
('organization', 1, 'projects', 50),
('organization', 1, 'storage', 10737418240);  -- 10GB
EOF
        
        log_info "默认组织已创建"
    fi
}

# 创建租户隔离配置
create_tenant_isolation_config() {
    cat > "${TENANT_ISOLATION_DIR}/isolation.conf" << 'EOF'
# 租户隔离配置
# 隔离级别: strict, moderate, permissive

[default]
isolation_level = strict
data_isolation = true
network_isolation = true
resource_isolation = true

[organizations]
isolation_level = strict
data_isolation = true
network_isolation = true
resource_isolation = true

[projects]
isolation_level = moderate
data_isolation = true
network_isolation = false
resource_isolation = true

[quotas]
# 默认配额设置
default_user_quota = 100
default_client_quota = 1000
default_project_quota = 50
default_storage_quota = 10737418240  # 10GB

[permissions]
# 权限继承设置
inherit_organization_permissions = true
inherit_project_permissions = true
allow_cross_tenant_access = false
EOF
}

# 多租户管理菜单
multi_tenant_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 多租户管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 组织管理"
        echo -e "${GREEN}2.${NC} 项目管理"
        echo -e "${GREEN}3.${NC} 租户隔离设置"
        echo -e "${GREEN}4.${NC} 资源配额管理"
        echo -e "${GREEN}5.${NC} 权限管理"
        echo -e "${GREEN}6.${NC} 租户统计"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -rp "请选择操作 [0-6]: " choice
        
        case $choice in
            1) organization_management ;;
            2) project_management ;;
            3) tenant_isolation_settings ;;
            4) resource_quota_management ;;
            5) tenant_permission_management ;;
            6) tenant_statistics ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 组织管理
organization_management() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 组织管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看组织列表"
        echo -e "${GREEN}2.${NC} 创建组织"
        echo -e "${GREEN}3.${NC} 编辑组织"
        echo -e "${GREEN}4.${NC} 删除组织"
        echo -e "${GREEN}5.${NC} 组织成员管理"
        echo -e "${GREEN}6.${NC} 组织设置"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -rp "请选择操作 [0-6]: " choice
        
        case $choice in
            1) list_organizations ;;
            2) create_organization ;;
            3) edit_organization ;;
            4) delete_organization ;;
            5) manage_organization_members ;;
            6) organization_settings ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 查看组织列表
list_organizations() {
    echo -e "${SECONDARY_COLOR}=== 组织列表 ===${NC}"
    echo
    
    sqlite3 "$ORGANIZATIONS_DB" << EOF
.mode column
.headers on
SELECT id, name, display_name, status, created_at
FROM organizations
ORDER BY created_at DESC;
EOF
}

# 创建组织
create_organization() {
    echo -e "${SECONDARY_COLOR}=== 创建组织 ===${NC}"
    echo
    
    local name=$(show_input "组织名称" "")
    local display_name=$(show_input "显示名称" "")
    local description=$(show_input "组织描述" "")
    local domain=$(show_input "组织域名" "")
    local admin_user_id=$(show_input "管理员用户ID" "1")
    
    if [[ -n "$name" && -n "$display_name" ]]; then
        sqlite3 "$ORGANIZATIONS_DB" << EOF
INSERT INTO organizations (name, display_name, description, domain, admin_user_id) 
VALUES ('$name', '$display_name', '$description', '$domain', $admin_user_id);
EOF
        
        # 获取新创建的组织ID
        local org_id=$(sqlite3 "$ORGANIZATIONS_DB" "SELECT id FROM organizations WHERE name = '$name'")
        
        # 设置默认配额
        sqlite3 "$MULTI_TENANT_DB" << EOF
INSERT INTO tenant_quotas (tenant_type, tenant_id, resource_type, quota_limit) VALUES
('organization', $org_id, 'users', 100),
('organization', $org_id, 'clients', 1000),
('organization', $org_id, 'projects', 50),
('organization', $org_id, 'storage', 10737418240);
EOF
        
        show_success "组织 '$name' 已创建"
    else
        show_error "组织名称和显示名称不能为空"
    fi
}

# 项目管理
project_management() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 项目管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看项目列表"
        echo -e "${GREEN}2.${NC} 创建项目"
        echo -e "${GREEN}3.${NC} 编辑项目"
        echo -e "${GREEN}4.${NC} 删除项目"
        echo -e "${GREEN}5.${NC} 项目成员管理"
        echo -e "${GREEN}6.${NC} 项目资源管理"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -rp "请选择操作 [0-6]: " choice
        
        case $choice in
            1) list_projects ;;
            2) create_project ;;
            3) edit_project ;;
            4) delete_project ;;
            5) manage_project_members ;;
            6) manage_project_resources ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 查看项目列表
list_projects() {
    echo -e "${SECONDARY_COLOR}=== 项目列表 ===${NC}"
    echo
    
    sqlite3 "$PROJECTS_DB" << EOF
.mode column
.headers on
SELECT p.id, p.name, p.display_name, o.display_name as organization, p.status, p.created_at
FROM projects p
JOIN organizations o ON p.organization_id = o.id
ORDER BY p.created_at DESC;
EOF
}

# 创建项目
create_project() {
    echo -e "${SECONDARY_COLOR}=== 创建项目 ===${NC}"
    echo
    
    # 选择组织
    echo "选择组织:"
    sqlite3 "$ORGANIZATIONS_DB" << EOF
.mode column
.headers on
SELECT id, name, display_name
FROM organizations
WHERE status = 'active'
ORDER BY name;
EOF
    
    local org_id=$(show_input "组织ID" "")
    local name=$(show_input "项目名称" "")
    local display_name=$(show_input "显示名称" "")
    local description=$(show_input "项目描述" "")
    local owner_id=$(show_input "项目所有者ID" "1")
    
    if [[ -n "$org_id" && -n "$name" && -n "$display_name" ]]; then
        sqlite3 "$PROJECTS_DB" << EOF
INSERT INTO projects (organization_id, name, display_name, description, owner_id) 
VALUES ($org_id, '$name', '$display_name', '$description', $owner_id);
EOF
        
        show_success "项目 '$name' 已创建"
    else
        show_error "组织ID、项目名称和显示名称不能为空"
    fi
}

# 资源配额管理
resource_quota_management() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 资源配额管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看配额列表"
        echo -e "${GREEN}2.${NC} 设置组织配额"
        echo -e "${GREEN}3.${NC} 设置项目配额"
        echo -e "${GREEN}4.${NC} 配额使用统计"
        echo -e "${GREEN}5.${NC} 配额告警设置"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -rp "请选择操作 [0-5]: " choice
        
        case $choice in
            1) list_quotas ;;
            2) set_organization_quota ;;
            3) set_project_quota ;;
            4) quota_usage_statistics ;;
            5) quota_alert_settings ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 查看配额列表
list_quotas() {
    echo -e "${SECONDARY_COLOR}=== 配额列表 ===${NC}"
    echo
    
    sqlite3 "$MULTI_TENANT_DB" << EOF
.mode column
.headers on
SELECT tenant_type, tenant_id, resource_type, quota_limit, current_usage, 
       (current_usage * 100.0 / quota_limit) as usage_percentage
FROM tenant_quotas
ORDER BY tenant_type, tenant_id, resource_type;
EOF
}

# 设置组织配额
set_organization_quota() {
    echo -e "${SECONDARY_COLOR}=== 设置组织配额 ===${NC}"
    echo
    
    # 选择组织
    echo "选择组织:"
    sqlite3 "$ORGANIZATIONS_DB" << EOF
.mode column
.headers on
SELECT id, name, display_name
FROM organizations
WHERE status = 'active'
ORDER BY name;
EOF
    
    local org_id=$(show_input "组织ID" "")
    local resource_type=$(show_selection "资源类型" "users" "clients" "projects" "storage")
    local quota_limit=$(show_input "配额限制" "")
    
    if [[ -n "$org_id" && -n "$resource_type" && -n "$quota_limit" ]]; then
        sqlite3 "$MULTI_TENANT_DB" << EOF
INSERT OR REPLACE INTO tenant_quotas (tenant_type, tenant_id, resource_type, quota_limit) 
VALUES ('organization', $org_id, '$resource_type', $quota_limit);
EOF
        
        show_success "组织配额已设置"
    else
        show_error "所有字段都不能为空"
    fi
}

# 租户统计
tenant_statistics() {
    echo -e "${SECONDARY_COLOR}=== 租户统计 ===${NC}"
    echo
    
    echo "组织统计:"
    sqlite3 "$ORGANIZATIONS_DB" << EOF
.mode column
.headers on
SELECT 
    COUNT(*) as total_organizations,
    SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_organizations,
    SUM(CASE WHEN status = 'inactive' THEN 1 ELSE 0 END) as inactive_organizations
FROM organizations;
EOF
    
    echo
    echo "项目统计:"
    sqlite3 "$PROJECTS_DB" << EOF
.mode column
.headers on
SELECT 
    COUNT(*) as total_projects,
    SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_projects,
    SUM(CASE WHEN status = 'inactive' THEN 1 ELSE 0 END) as inactive_projects
FROM projects;
EOF
    
    echo
    echo "配额使用统计:"
    sqlite3 "$MULTI_TENANT_DB" << EOF
.mode column
.headers on
SELECT 
    resource_type,
    COUNT(*) as total_quotas,
    AVG(current_usage * 100.0 / quota_limit) as avg_usage_percentage,
    MAX(current_usage * 100.0 / quota_limit) as max_usage_percentage
FROM tenant_quotas
GROUP BY resource_type;
EOF
}

# 检查租户权限
check_tenant_permission() {
    local user_id="$1"
    local tenant_type="$2"
    local tenant_id="$3"
    local permission="$4"
    
    # 检查用户是否有租户权限
    local has_permission=$(sqlite3 "$MULTI_TENANT_DB" << EOF
SELECT COUNT(*) FROM tenant_permissions 
WHERE tenant_type = '$tenant_type' 
  AND tenant_id = $tenant_id 
  AND user_id = $user_id 
  AND permission = '$permission' 
  AND granted = 1;
EOF
)
    
    if [[ "$has_permission" -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

# 设置租户权限
set_tenant_permission() {
    local user_id="$1"
    local tenant_type="$2"
    local tenant_id="$3"
    local permission="$4"
    local granted="${5:-1}"
    
    sqlite3 "$MULTI_TENANT_DB" << EOF
INSERT OR REPLACE INTO tenant_permissions (tenant_type, tenant_id, user_id, permission, granted) 
VALUES ('$tenant_type', $tenant_id, $user_id, '$permission', $granted);
EOF
}

# 导出函数
export -f init_multi_tenant init_multi_tenant_databases create_default_organization
export -f create_tenant_isolation_config multi_tenant_menu organization_management
export -f list_organizations create_organization project_management list_projects
export -f create_project resource_quota_management list_quotas set_organization_quota
export -f tenant_statistics check_tenant_permission set_tenant_permission
