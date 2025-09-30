#!/bin/bash
# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"

# 确保日志相关变量已定义
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
fi

# 增强的Web界面模块
# 实现实时状态显示、用户权限管理、API接口等功能

# Web界面配置
WEB_INTERFACE_DIR="${INSTALL_DIR}/web"
WEB_STATIC_DIR="${WEB_INTERFACE_DIR}/static"
WEB_TEMPLATES_DIR="${WEB_INTERFACE_DIR}/templates"
WEB_API_DIR="${WEB_INTERFACE_DIR}/api"
WEB_LOGS_DIR="${WEB_INTERFACE_DIR}/logs"

# 用户管理配置
USERS_DB="${CONFIG_DIR}/users.db"
SESSIONS_DB="${CONFIG_DIR}/sessions.db"

# 初始化增强Web界面
init_enhanced_web_interface() {
    log_info "初始化增强Web界面..."
    
    # 创建Web界面目录
    mkdir -p "$WEB_INTERFACE_DIR" "$WEB_STATIC_DIR" "$WEB_TEMPLATES_DIR" "$WEB_API_DIR" "$WEB_LOGS_DIR"
    
    # 创建用户数据库
    init_user_database
    
    # 创建Web界面文件
    create_web_interface_files
    
    # 创建API接口
    create_api_interfaces
    
    # 配置Web服务器
    configure_web_server
    
    log_info "增强Web界面初始化完成"
}

# 初始化用户数据库
init_user_database() {
    log_info "初始化用户数据库..."
    
    # 创建用户表
    sqlite3 "$USERS_DB" << EOF
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    email TEXT,
    role TEXT DEFAULT 'user',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME,
    status TEXT DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    user_id INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME,
    ip_address TEXT,
    user_agent TEXT,
    FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE IF NOT EXISTS permissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    resource TEXT NOT NULL,
    action TEXT NOT NULL,
    granted BOOLEAN DEFAULT 1,
    FOREIGN KEY (user_id) REFERENCES users (id)
);
EOF
    
    # 创建默认管理员用户
    create_default_admin_user
    
    log_info "用户数据库初始化完成"
}

# 创建默认管理员用户
create_default_admin_user() {
    local admin_password="${WEB_ADMIN_PASSWORD:-admin123}"
    local password_hash=$(echo -n "$admin_password" | sha256sum | awk '{print $1}')
    
    sqlite3 "$USERS_DB" << EOF
INSERT OR IGNORE INTO users (username, password_hash, email, role) 
VALUES ('admin', '$password_hash', 'admin@localhost', 'admin');
EOF
    
    log_info "默认管理员用户已创建: admin / $admin_password"
}

# 创建Web界面文件
create_web_interface_files() {
    log_info "创建Web界面文件..."
    
    # 创建主页面
    create_main_page
    
    # 创建登录页面
    create_login_page
    
    # 创建仪表板
    create_dashboard
    
    # 创建客户端管理页面
    create_client_management_page
    
    # 创建系统监控页面
    create_system_monitoring_page
    
    # 创建配置管理页面
    create_config_management_page
}

# 创建客户端管理页面
create_client_management_page() {
    cat > "${WEB_TEMPLATES_DIR}/clients.html" << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>客户端管理 - IPv6 WireGuard Manager</title>
    <link rel="stylesheet" href="/static/css/style.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>客户端管理</h1>
            <nav>
                <a href="/">首页</a>
                <a href="/dashboard">仪表板</a>
                <a href="/clients" class="active">客户端</a>
                <a href="/config">配置</a>
                <a href="/logout">退出</a>
            </nav>
        </header>
        
        <main>
            <div class="card">
                <h2>客户端列表</h2>
                <div class="actions">
                    <button onclick="addClient()" class="btn btn-primary">添加客户端</button>
                    <button onclick="refreshClients()" class="btn btn-secondary">刷新</button>
                </div>
                
                <div id="clients-list">
                    <div class="loading">加载中...</div>
                </div>
            </div>
        </main>
    </div>
    
    <script src="/static/js/clients.js"></script>
</body>
</html>
EOF
    log_info "客户端管理页面已创建"
}

# 创建系统监控页面
create_system_monitoring_page() {
    cat > "${WEB_TEMPLATES_DIR}/monitor.html" << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>系统监控 - IPv6 WireGuard Manager</title>
    <link rel="stylesheet" href="/static/css/style.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>系统监控</h1>
            <nav>
                <a href="/">首页</a>
                <a href="/dashboard">仪表板</a>
                <a href="/clients">客户端</a>
                <a href="/monitor" class="active">监控</a>
                <a href="/logout">退出</a>
            </nav>
        </header>
        
        <main>
            <div class="card">
                <h2>系统状态</h2>
                <div id="system-status">
                    <div class="loading">加载中...</div>
                </div>
            </div>
            
            <div class="card">
                <h2>网络流量</h2>
                <canvas id="traffic-chart" width="800" height="400"></canvas>
            </div>
        </main>
    </div>
    
    <script src="/static/js/monitor.js"></script>
</body>
</html>
EOF
    log_info "系统监控页面已创建"
}

# 创建配置管理页面
create_config_management_page() {
    cat > "${WEB_TEMPLATES_DIR}/config.html" << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>配置管理 - IPv6 WireGuard Manager</title>
    <link rel="stylesheet" href="/static/css/style.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>配置管理</h1>
            <nav>
                <a href="/">首页</a>
                <a href="/dashboard">仪表板</a>
                <a href="/clients">客户端</a>
                <a href="/monitor">监控</a>
                <a href="/config" class="active">配置</a>
                <a href="/logout">退出</a>
            </nav>
        </header>
        
        <main>
            <div class="card">
                <h2>系统配置</h2>
                <form id="config-form">
                    <div class="form-group">
                        <label for="wireguard-port">WireGuard端口:</label>
                        <input type="number" id="wireguard-port" name="wireguard_port" value="51820">
                    </div>
                    <div class="form-group">
                        <label for="ipv6-prefix">IPv6前缀:</label>
                        <input type="text" id="ipv6-prefix" name="ipv6_prefix" value="2001:db8::/56">
                    </div>
                    <div class="form-group">
                        <label for="web-port">Web端口:</label>
                        <input type="number" id="web-port" name="web_port" value="8080">
                    </div>
                    <button type="submit" class="btn btn-primary">保存配置</button>
                </form>
            </div>
        </main>
    </div>
    
    <script src="/static/js/config.js"></script>
</body>
</html>
EOF
    log_info "配置管理页面已创建"
}

# 创建主页面
create_main_page() {
    cat > "${WEB_TEMPLATES_DIR}/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" onerror="this.onerror=null;this.href='https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.2/css/bootstrap.min.css';">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet" onerror="this.onerror=null;this.href='https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.1/font/bootstrap-icons.css';">
    <style>
        .status-card { transition: transform 0.2s; }
        .status-card:hover { transform: translateY(-2px); }
        .metric-value { font-size: 2rem; font-weight: bold; }
        .metric-label { color: #6c757d; }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
        <div class="container-fluid">
            <a class="navbar-brand" href="#">
                <i class="bi bi-shield-lock"></i> IPv6 WireGuard Manager
            </a>
            <div class="navbar-nav ms-auto">
                <span class="navbar-text" id="user-info">欢迎, <span id="username">admin</span></span>
                <button class="btn btn-outline-light btn-sm ms-2" onclick="logout()">退出</button>
            </div>
        </div>
    </nav>

    <div class="container-fluid mt-4">
        <div class="row">
            <div class="col-md-3">
                <div class="card status-card">
                    <div class="card-body text-center">
                        <i class="bi bi-wifi text-success" style="font-size: 2rem;"></i>
                        <h5 class="card-title mt-2">WireGuard状态</h5>
                        <p class="metric-value text-success" id="wireguard-status">运行中</p>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card status-card">
                    <div class="card-body text-center">
                        <i class="bi bi-diagram-3 text-info" style="font-size: 2rem;"></i>
                        <h5 class="card-title mt-2">BGP状态</h5>
                        <p class="metric-value text-info" id="bgp-status">已连接</p>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card status-card">
                    <div class="card-body text-center">
                        <i class="bi bi-people text-primary" style="font-size: 2rem;"></i>
                        <h5 class="card-title mt-2">客户端数量</h5>
                        <p class="metric-value text-primary" id="client-count">0</p>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card status-card">
                    <div class="card-body text-center">
                        <i class="bi bi-shield-check text-warning" style="font-size: 2rem;"></i>
                        <h5 class="card-title mt-2">防火墙状态</h5>
                        <p class="metric-value text-warning" id="firewall-status">已启用</p>
                    </div>
                </div>
            </div>
        </div>

        <div class="row mt-4">
            <div class="col-md-8">
                <div class="card">
                    <div class="card-header">
                        <h5><i class="bi bi-graph-up"></i> 系统监控</h5>
                    </div>
                    <div class="card-body">
                        <canvas id="systemChart" width="400" height="200"></canvas>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card">
                    <div class="card-header">
                        <h5><i class="bi bi-list-ul"></i> 快速操作</h5>
                    </div>
                    <div class="card-body">
                        <div class="d-grid gap-2">
                            <button class="btn btn-primary" onclick="showClientManagement()">
                                <i class="bi bi-people"></i> 客户端管理
                            </button>
                            <button class="btn btn-info" onclick="showSystemMonitoring()">
                                <i class="bi bi-graph-up"></i> 系统监控
                            </button>
                            <button class="btn btn-warning" onclick="showConfigManagement()">
                                <i class="bi bi-gear"></i> 配置管理
                            </button>
                            <button class="btn btn-success" onclick="showLogs()">
                                <i class="bi bi-file-text"></i> 查看日志
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" onerror="this.onerror=null;this.src='https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.2/js/bootstrap.bundle.min.js';"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="/static/js/main.js"></script>
</body>
</html>
EOF
}

# 创建登录页面
create_login_page() {
    cat > "${WEB_TEMPLATES_DIR}/login.html" << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>登录 - IPv6 WireGuard Manager</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" onerror="this.onerror=null;this.href='https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.2/css/bootstrap.min.css';">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet" onerror="this.onerror=null;this.href='https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.1/font/bootstrap-icons.css';">
</head>
<body class="bg-light">
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-md-4">
                <div class="card mt-5">
                    <div class="card-body">
                        <h3 class="card-title text-center mb-4">
                            <i class="bi bi-shield-lock"></i> 登录
                        </h3>
                        <form id="loginForm">
                            <div class="mb-3">
                                <label for="username" class="form-label">用户名</label>
                                <input type="text" class="form-control" id="username" required>
                            </div>
                            <div class="mb-3">
                                <label for="password" class="form-label">密码</label>
                                <input type="password" class="form-control" id="password" required>
                            </div>
                            <div class="d-grid">
                                <button type="submit" class="btn btn-primary">登录</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script src="/static/js/login.js"></script>
</body>
</html>
EOF
}

# 创建仪表板
create_dashboard() {
    cat > "${WEB_TEMPLATES_DIR}/dashboard.html" << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>仪表板 - IPv6 WireGuard Manager</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" onerror="this.onerror=null;this.href='https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.2/css/bootstrap.min.css';">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet" onerror="this.onerror=null;this.href='https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.1/font/bootstrap-icons.css';">
</head>
<body>
    <div class="container-fluid">
        <div class="row">
            <div class="col-md-12">
                <h2><i class="bi bi-speedometer2"></i> 系统仪表板</h2>
                <hr>
            </div>
        </div>
        
        <div class="row">
            <div class="col-md-6">
                <div class="card">
                    <div class="card-header">
                        <h5>实时状态</h5>
                    </div>
                    <div class="card-body">
                        <div id="real-time-status"></div>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="card">
                    <div class="card-header">
                        <h5>网络拓扑</h5>
                    </div>
                    <div class="card-body">
                        <div id="network-topology">
                            <canvas id="topology-canvas" width="400" height="300"></canvas>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script src="/static/js/dashboard.js"></script>
</body>
</html>
EOF
}

# 创建API接口
create_api_interfaces() {
    log_info "创建API接口..."
    
    # 创建认证API
    create_auth_api
    
    # 创建状态API
    create_status_api
    
    # 创建客户端API
    create_client_api
    
    # 创建配置API
    create_config_api
}

# 创建认证API
create_auth_api() {
    cat > "${WEB_API_DIR}/auth.py" << 'EOF'
#!/usr/bin/env python3
# 认证API接口

import sqlite3
import hashlib
import secrets
import time
from datetime import datetime, timedelta

class AuthAPI:
    def __init__(self, db_path):
        self.db_path = db_path
    
    def login(self, username, password):
        """用户登录"""
        password_hash = hashlib.sha256(password.encode()).hexdigest()
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT id, username, role, status FROM users 
            WHERE username = ? AND password_hash = ? AND status = 'active'
        """, (username, password_hash))
        
        user = cursor.fetchone()
        
        if user:
            # 创建会话
            session_id = secrets.token_urlsafe(32)
            expires_at = datetime.now() + timedelta(hours=24)
            
            cursor.execute("""
                INSERT INTO sessions (id, user_id, expires_at) 
                VALUES (?, ?, ?)
            """, (session_id, user[0], expires_at))
            
            # 更新最后登录时间
            cursor.execute("""
                UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = ?
            """, (user[0],))
            
            conn.commit()
            conn.close()
            
            return {
                'success': True,
                'session_id': session_id,
                'user': {
                    'id': user[0],
                    'username': user[1],
                    'role': user[2]
                }
            }
        else:
            conn.close()
            return {'success': False, 'message': '用户名或密码错误'}
    
    def logout(self, session_id):
        """用户登出"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("DELETE FROM sessions WHERE id = ?", (session_id,))
        conn.commit()
        conn.close()
        
        return {'success': True}
    
    def validate_session(self, session_id):
        """验证会话"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT u.id, u.username, u.role, s.expires_at 
            FROM users u 
            JOIN sessions s ON u.id = s.user_id 
            WHERE s.id = ? AND s.expires_at > datetime('now')
        """, (session_id,))
        
        user = cursor.fetchone()
        conn.close()
        
        if user:
            return {
                'valid': True,
                'user': {
                    'id': user[0],
                    'username': user[1],
                    'role': user[2]
                }
            }
        else:
            return {'valid': False}
EOF
}

# 创建状态API
create_status_api() {
    cat > "${WEB_API_DIR}/status.py" << 'EOF'
#!/usr/bin/env python3
# 状态API接口

import subprocess
import json
import psutil
import time

class StatusAPI:
    def __init__(self):
        pass
    
    def get_system_status(self):
        """获取系统状态"""
        return {
            'cpu_usage': psutil.cpu_percent(interval=1),
            'memory_usage': psutil.virtual_memory().percent,
            'disk_usage': psutil.disk_usage('/').percent,
            'uptime': time.time() - psutil.boot_time(),
            'timestamp': time.time()
        }
    
    def get_wireguard_status(self):
        """获取WireGuard状态"""
        try:
            result = subprocess.run(['wg', 'show'], capture_output=True, text=True)
            if result.returncode == 0:
                return {
                    'status': 'running',
                    'interfaces': self._parse_wg_output(result.stdout)
                }
            else:
                return {'status': 'stopped', 'error': result.stderr}
        except Exception as e:
            return {'status': 'error', 'error': str(e)}
    
    def get_bgp_status(self):
        """获取BGP状态"""
        try:
            result = subprocess.run(['birdc', 'show', 'protocols'], capture_output=True, text=True)
            if result.returncode == 0:
                return {
                    'status': 'running',
                    'protocols': self._parse_bgp_output(result.stdout)
                }
            else:
                return {'status': 'stopped', 'error': result.stderr}
        except Exception as e:
            return {'status': 'error', 'error': str(e)}
    
    def get_client_count(self):
        """获取客户端数量"""
        try:
            result = subprocess.run(['wg', 'show', 'all', 'peers'], capture_output=True, text=True)
            if result.returncode == 0:
                peer_count = len([line for line in result.stdout.split('\n') if line.strip()])
                return {'count': peer_count}
            else:
                return {'count': 0, 'error': result.stderr}
        except Exception as e:
            return {'count': 0, 'error': str(e)}
    
    def _parse_wg_output(self, output):
        """解析WireGuard输出"""
        interfaces = {}
        current_interface = None
        
        for line in output.split('\n'):
            if line.startswith('interface:'):
                current_interface = line.split(':')[1].strip()
                interfaces[current_interface] = {'peers': []}
            elif line.startswith('peer:') and current_interface:
                peer = line.split(':')[1].strip()
                interfaces[current_interface]['peers'].append(peer)
        
        return interfaces
    
    def _parse_bgp_output(self, output):
        """解析BGP输出"""
        protocols = []
        for line in output.split('\n'):
            if line.strip() and not line.startswith('BIRD'):
                parts = line.split()
                if len(parts) >= 4:
                    protocols.append({
                        'name': parts[0],
                        'proto': parts[1],
                        'table': parts[2],
                        'state': parts[3],
                        'since': ' '.join(parts[4:]) if len(parts) > 4 else ''
                    })
        return protocols
EOF
}

# 创建客户端API
create_client_api() {
    cat > "${WEB_API_DIR}/client.py" << 'EOF'
#!/usr/bin/env python3
# 客户端API接口

import sqlite3
import json
import subprocess
import secrets
import string

class ClientAPI:
    def __init__(self, db_path):
        self.db_path = db_path
    
    def get_clients(self):
        """获取客户端列表"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT id, name, email, ipv4_address, ipv6_address, 
                   public_key, created_at, status 
            FROM clients 
            ORDER BY created_at DESC
        """)
        
        clients = []
        for row in cursor.fetchall():
            clients.append({
                'id': row[0],
                'name': row[1],
                'email': row[2],
                'ipv4_address': row[3],
                'ipv6_address': row[4],
                'public_key': row[5],
                'created_at': row[6],
                'status': row[7]
            })
        
        conn.close()
        return clients
    
    def add_client(self, name, email):
        """添加客户端"""
        # 生成密钥对
        private_key = self._generate_private_key()
        public_key = self._get_public_key(private_key)
        
        # 分配IP地址
        ipv4_address = self._allocate_ipv4()
        ipv6_address = self._allocate_ipv6()
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO clients (name, email, private_key, public_key, 
                               ipv4_address, ipv6_address, status)
            VALUES (?, ?, ?, ?, ?, ?, 'active')
        """, (name, email, private_key, public_key, ipv4_address, ipv6_address))
        
        client_id = cursor.lastrowid
        conn.commit()
        conn.close()
        
        return {
            'success': True,
            'client_id': client_id,
            'config': self._generate_client_config(client_id)
        }
    
    def delete_client(self, client_id):
        """删除客户端"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("DELETE FROM clients WHERE id = ?", (client_id,))
        affected_rows = cursor.rowcount
        
        conn.commit()
        conn.close()
        
        return {'success': affected_rows > 0}
    
    def _generate_private_key(self):
        """生成私钥"""
        result = subprocess.run(['wg', 'genkey'], capture_output=True, text=True)
        return result.stdout.strip()
    
    def _get_public_key(self, private_key):
        """从私钥生成公钥"""
        process = subprocess.Popen(['wg', 'pubkey'], stdin=subprocess.PIPE, 
                                 stdout=subprocess.PIPE, text=True)
        stdout, _ = process.communicate(input=private_key)
        return stdout.strip()
    
    def _allocate_ipv4(self):
        """分配IPv4地址"""
        # 这里实现IPv4地址分配逻辑
        return "10.0.0.2/24"
    
    def _allocate_ipv6(self):
        """分配IPv6地址"""
        # 这里实现IPv6地址分配逻辑
        return "2001:db8::2/64"
    
    def _generate_client_config(self, client_id):
        """生成客户端配置"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT private_key, ipv4_address, ipv6_address 
            FROM clients WHERE id = ?
        """, (client_id,))
        
        client = cursor.fetchone()
        conn.close()
        
        if client:
            config = f"""[Interface]
PrivateKey = {client[0]}
Address = {client[1]}, {client[2]}
DNS = 8.8.8.8, 2001:4860:4860::8888

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = SERVER_ENDPOINT:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
"""
            return config
        
        return None
EOF
}

# 创建配置API
create_config_api() {
    cat > "${WEB_API_DIR}/config.py" << 'EOF'
#!/usr/bin/env python3
# 配置API接口

import yaml
import json
import os

class ConfigAPI:
    def __init__(self, config_dir):
        self.config_dir = config_dir
    
    def get_config(self, config_type):
        """获取配置"""
        config_file = os.path.join(self.config_dir, f"{config_type}.yaml")
        
        if os.path.exists(config_file):
            with open(config_file, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        else:
            return None
    
    def save_config(self, config_type, config_data):
        """保存配置"""
        config_file = os.path.join(self.config_dir, f"{config_type}.yaml")
        
        with open(config_file, 'w', encoding='utf-8') as f:
            yaml.dump(config_data, f, default_flow_style=False, allow_unicode=True)
        
        return True
    
    def validate_config(self, config_data):
        """验证配置"""
        # 这里实现配置验证逻辑
        return True
EOF
}

# 配置Web服务器
configure_web_server() {
    log_info "配置Web服务器..."
    
    # 检查并安装Nginx
    if ! command -v nginx &> /dev/null; then
        log_info "Nginx未安装，正在安装..."
        install_nginx
    fi
    
    # 创建nginx配置
    create_nginx_config
    
    # 创建systemd服务
    create_web_service
    
    # 启动Web服务
    start_web_service
}

# 安装Nginx
install_nginx() {
    log_info "安装Nginx..."
    
    # 检测包管理器
    local package_manager=""
    if command -v apt &> /dev/null; then
        package_manager="apt"
    elif command -v yum &> /dev/null; then
        package_manager="yum"
    elif command -v dnf &> /dev/null; then
        package_manager="dnf"
    elif command -v pacman &> /dev/null; then
        package_manager="pacman"
    elif command -v zypper &> /dev/null; then
        package_manager="zypper"
    fi
    
    case "$package_manager" in
        "apt")
            apt-get update
            apt-get install -y nginx
            ;;
        "yum"|"dnf")
            $package_manager install -y nginx
            ;;
        "pacman")
            pacman -S --noconfirm nginx
            ;;
        "zypper")
            zypper install -y nginx
            ;;
        *)
            log_error "不支持的包管理器，请手动安装Nginx"
            return 1
            ;;
    esac
    
    # 启动并启用Nginx服务
    systemctl start nginx
    systemctl enable nginx
    
    # 创建必要的目录
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    
    log_success "Nginx安装完成"
}

# 创建nginx配置
create_nginx_config() {
    log_info "创建Nginx配置..."
    
    # 确保Nginx目录存在
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    
    # 检查Nginx是否已安装
    if ! command -v nginx &> /dev/null; then
        log_error "Nginx未安装，请先安装Nginx"
        return 1
    fi
    
    cat > "/etc/nginx/sites-available/ipv6-wireguard-manager" << EOF
server {
    listen 8080;
    server_name _;
    
    root ${WEB_INTERFACE_DIR};
    index index.html;
    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    location /api/ {
        proxy_pass http://127.0.0.1:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    
    location /static/ {
        alias ${WEB_STATIC_DIR}/;
    }
}
EOF
    
    # 启用站点
    if ln -sf "/etc/nginx/sites-available/ipv6-wireguard-manager" "/etc/nginx/sites-enabled/"; then
        log_info "Nginx站点配置已启用"
    else
        log_error "无法创建Nginx站点链接"
        return 1
    fi
    
    # 测试配置
    if nginx -t; then
        log_success "Nginx配置测试通过"
        if systemctl reload nginx; then
            log_success "Nginx配置已重载"
        else
            log_warn "Nginx重载失败，请手动重启"
        fi
    else
        log_error "Nginx配置测试失败"
        return 1
    fi
}

# 创建Web服务
create_web_service() {
    cat > "/etc/systemd/system/ipv6-wireguard-manager-web.service" << EOF
[Unit]
Description=IPv6 WireGuard Manager Web Interface
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=${WEB_INTERFACE_DIR}
ExecStart=/usr/bin/python3 -m http.server 3000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable ipv6-wireguard-manager-web.service
}

# 启动Web服务
start_web_service() {
    systemctl start ipv6-wireguard-manager-web.service
    log_info "Web服务已启动"
}

# 增强Web界面菜单
enhanced_web_interface_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 增强Web界面管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 启动Web服务"
        echo -e "${GREEN}2.${NC} 停止Web服务"
        echo -e "${GREEN}3.${NC} 重启Web服务"
        echo -e "${GREEN}4.${NC} 查看Web服务状态"
        echo -e "${GREEN}5.${NC} 用户管理"
        echo -e "${GREEN}6.${NC} 权限管理"
        echo -e "${GREEN}7.${NC} API接口测试"
        echo -e "${GREEN}8.${NC} 查看Web日志"
        echo -e "${GREEN}9.${NC} 配置Web服务器"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回主菜单"
        echo
        
        read -rp "请选择操作 [0-9]: " choice
        
        case $choice in
            1) start_web_service ;;
            2) stop_web_service ;;
            3) restart_web_service ;;
            4) show_web_service_status ;;
            5) user_management_menu ;;
            6) permission_management_menu ;;
            7) test_api_interfaces ;;
            8) show_web_logs ;;
            9) configure_web_server ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 用户管理菜单
user_management_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 用户管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看用户列表"
        echo -e "${GREEN}2.${NC} 添加用户"
        echo -e "${GREEN}3.${NC} 删除用户"
        echo -e "${GREEN}4.${NC} 修改用户密码"
        echo -e "${GREEN}5.${NC} 修改用户角色"
        echo -e "${GREEN}6.${NC} 查看用户会话"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -rp "请选择操作 [0-6]: " choice
        
        case $choice in
            1) show_user_list ;;
            2) add_user ;;
            3) delete_user ;;
            4) change_user_password ;;
            5) change_user_role ;;
            6) show_user_sessions ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 显示用户列表
show_user_list() {
    echo -e "${SECONDARY_COLOR}=== 用户列表 ===${NC}"
    echo
    
    sqlite3 "$USERS_DB" << EOF
.mode column
.headers on
SELECT id, username, email, role, status, created_at, last_login FROM users;
EOF
}

# 添加用户
add_user() {
    echo -e "${SECONDARY_COLOR}=== 添加用户 ===${NC}"
    echo
    
    local username=$(show_input "用户名" "")
    local email=$(show_input "邮箱" "")
    local password=$(show_input "密码" "")
    local role=$(show_selection "角色" "admin" "user" "readonly")
    
    if [[ -n "$username" && -n "$password" ]]; then
        local password_hash=$(echo -n "$password" | sha256sum | awk '{print $1}')
        
        sqlite3 "$USERS_DB" << EOF
INSERT INTO users (username, password_hash, email, role) 
VALUES ('$username', '$password_hash', '$email', '$role');
EOF
        
        show_success "用户已添加: $username"
    else
        show_error "用户名和密码不能为空"
    fi
}

# 停止Web服务
stop_web_service() {
    systemctl stop ipv6-wireguard-manager-web.service
    log_info "Web服务已停止"
}

# 重启Web服务
restart_web_service() {
    systemctl restart ipv6-wireguard-manager-web.service
    log_info "Web服务已重启"
}

# 显示Web服务状态
show_web_service_status() {
    echo -e "${SECONDARY_COLOR}=== Web服务状态 ===${NC}"
    echo
    
    systemctl status ipv6-wireguard-manager-web.service --no-pager
}

# 显示Web日志
show_web_logs() {
    echo -e "${SECONDARY_COLOR}=== Web服务日志 ===${NC}"
    echo
    
    journalctl -u ipv6-wireguard-manager-web.service -n 50 --no-pager
}

# 测试API接口
test_api_interfaces() {
    echo -e "${SECONDARY_COLOR}=== API接口测试 ===${NC}"
    echo
    
    # 测试状态API
    echo "测试状态API..."
    curl -s http://localhost:3000/api/status/system || echo "状态API测试失败"
    
    echo
    echo "测试WireGuard状态API..."
    curl -s http://localhost:3000/api/status/wireguard || echo "WireGuard状态API测试失败"
    
    echo
    echo "测试客户端API..."
    curl -s http://localhost:3000/api/client/list || echo "客户端API测试失败"
}

# 导出函数
export -f init_enhanced_web_interface init_user_database create_default_admin_user
export -f create_web_interface_files create_main_page create_login_page create_dashboard
export -f create_api_interfaces create_auth_api create_status_api create_client_api
export -f create_config_api configure_web_server create_nginx_config create_web_service
export -f start_web_service enhanced_web_interface_menu user_management_menu
export -f show_user_list add_user stop_web_service restart_web_service
export -f show_web_service_status show_web_logs test_api_interfaces
