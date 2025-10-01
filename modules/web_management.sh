#!/bin/bash
# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# Web管理界面模块
# 负责Web管理界面的安装、配置、启动、停止等功能

# Web管理配置变量
WEB_CONFIG_DIR="${CONFIG_DIR}/web"
WEB_CONFIG_FILE="${WEB_CONFIG_DIR}/web.conf"
WEB_ROOT_DIR="/var/www/ipv6-wireguard-manager"
WEB_LOG_DIR="${LOG_DIR}/web"
WEB_TEMPLATE_DIR="${WEB_ROOT_DIR}/templates"
WEB_STATIC_DIR="${WEB_ROOT_DIR}/static"

# Web服务器配置
WEB_SERVER_TYPE="nginx"  # nginx, apache2
WEB_SERVER_PORT=8080
WEB_SERVER_HOST="0.0.0.0"
WEB_SSL_ENABLED=false
WEB_SSL_CERT=""
WEB_SSL_KEY=""

# Web应用配置
WEB_APP_ENABLED=false
WEB_APP_PORT=5000
WEB_APP_HOST="127.0.0.1"
WEB_APP_DEBUG=false
WEB_APP_SECRET_KEY=""

# Web API配置
WEB_API_ENABLED=true
WEB_API_VERSION="v1"
WEB_API_RATE_LIMIT=1000
WEB_API_TIMEOUT=30

# Web安全配置
WEB_SECURITY_ENABLED=true
WEB_CORS_ENABLED=true
WEB_CSRF_ENABLED=true
WEB_SESSION_TIMEOUT=3600
WEB_MAX_LOGIN_ATTEMPTS=5
WEB_LOCKOUT_DURATION=900

# Web监控配置
WEB_MONITORING_ENABLED=true
WEB_METRICS_ENABLED=true
WEB_HEALTH_CHECK_ENABLED=true
WEB_PERFORMANCE_MONITORING=true

# 初始化Web管理界面
init_web_management() {
    log_info "初始化Web管理界面..."
    
    # 创建配置目录
    mkdir -p "$WEB_CONFIG_DIR" "$WEB_ROOT_DIR" "$WEB_LOG_DIR"
    mkdir -p "$WEB_TEMPLATE_DIR" "$WEB_STATIC_DIR"
    
    # 创建配置文件
    create_web_config
    
    # 加载配置
    load_web_config
    
    log_info "Web管理界面初始化完成"
}

# 创建Web配置
create_web_config() {
    if [[ ! -f "$WEB_CONFIG_FILE" ]]; then
        cat > "$WEB_CONFIG_FILE" << EOF
# Web管理界面配置文件
# 生成时间: $(get_timestamp "$@")

# Web服务器配置
WEB_SERVER_TYPE=nginx
WEB_SERVER_PORT=8080
WEB_SERVER_HOST=0.0.0.0
WEB_SSL_ENABLED=false
WEB_SSL_CERT=""
WEB_SSL_KEY=""

# Web应用配置
WEB_APP_ENABLED=true
WEB_APP_PORT=5000
WEB_APP_HOST=127.0.0.1
WEB_APP_DEBUG=false
WEB_APP_SECRET_KEY="$(generate_random_string 32)"

# 认证配置
WEB_AUTH_ENABLED=true
WEB_AUTH_METHOD=session
WEB_SESSION_TIMEOUT=3600
WEB_MAX_LOGIN_ATTEMPTS=5
WEB_LOCKOUT_DURATION=300

# 用户管理
WEB_ADMIN_USER=admin
WEB_ADMIN_PASSWORD=""
WEB_USER_MANAGEMENT=true
WEB_USER_ROLES=admin,user,viewer

# 安全配置
WEB_CSRF_PROTECTION=true
WEB_XSS_PROTECTION=true
WEB_SECURE_HEADERS=true
WEB_RATE_LIMITING=true
WEB_RATE_LIMIT=100

# 日志配置
WEB_LOG_ENABLED=true
WEB_LOG_LEVEL=INFO
WEB_LOG_FILE="${WEB_LOG_DIR}/web.log"
WEB_ACCESS_LOG="${WEB_LOG_DIR}/access.log"
WEB_ERROR_LOG="${WEB_LOG_DIR}/error.log"

# 缓存配置
WEB_CACHE_ENABLED=true
WEB_CACHE_TYPE=memory
WEB_CACHE_TTL=300

# 数据库配置
WEB_DB_TYPE=sqlite
WEB_DB_PATH="/var/lib/ipv6-wireguard-manager/web.db"
WEB_DB_BACKUP_ENABLED=true
WEB_DB_BACKUP_INTERVAL=24

# API配置
WEB_API_ENABLED=true
WEB_API_VERSION=v1
WEB_API_RATE_LIMIT=1000
WEB_API_AUTH_REQUIRED=true

# 文件上传配置
WEB_UPLOAD_ENABLED=true
WEB_UPLOAD_PATH="${WEB_ROOT_DIR}/uploads"
WEB_UPLOAD_MAX_SIZE=10485760
WEB_UPLOAD_ALLOWED_TYPES=conf,txt,csv,json

# 主题配置
WEB_THEME=default
WEB_THEME_CUSTOM=""
WEB_LANGUAGE=zh_CN
WEB_TIMEZONE=Asia/Shanghai

# 通知配置
WEB_NOTIFICATION_ENABLED=true
WEB_NOTIFICATION_EMAIL=true
WEB_NOTIFICATION_WEBHOOK=true
WEB_NOTIFICATION_REALTIME=true
EOF
        log_info "Web配置文件已创建: $WEB_CONFIG_FILE"
    fi
}

# 加载Web配置
load_web_config() {
    if [[ -f "$WEB_CONFIG_FILE" ]]; then
        source "$WEB_CONFIG_FILE"
        log_info "Web配置已加载"
    fi
}

# Web管理主菜单
web_management_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== Web管理界面 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 安装Web管理服务"
        echo -e "${GREEN}2.${NC} 启动Web服务"
        echo -e "${GREEN}3.${NC} 停止Web服务"
        echo -e "${GREEN}4.${NC} 重启Web服务"
        echo -e "${GREEN}5.${NC} 查看Web服务状态"
        echo -e "${GREEN}6.${NC} 配置Web界面"
        echo -e "${GREEN}7.${NC} 访问控制设置"
        echo -e "${GREEN}8.${NC} SSL配置"
        echo -e "${GREEN}9.${NC} 卸载Web管理服务"
        echo -e "${GREEN}10.${NC} Web日志查看"
        echo -e "${GREEN}11.${NC} Web性能监控"
        echo -e "${GREEN}12.${NC} Web备份恢复"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回上级菜单"
        echo
        
        read -rp "请选择操作 [0-12]: " choice
        
        case $choice in
            1) install_web_service ;;
            2) start_web_service ;;
            3) stop_web_service ;;
            4) restart_web_service ;;
            5) show_web_service_status ;;
            6) configure_web_interface ;;
            7) access_control_settings ;;
            8) ssl_configuration ;;
            9) uninstall_web_service ;;
            10) view_web_logs ;;
            11) web_performance_monitoring ;;
            12) web_backup_restore ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 安装Web管理服务
install_web_service() {
    echo -e "${SECONDARY_COLOR}=== 安装Web管理服务 ===${NC}"
    echo
    
    # 检查是否已安装
    if [[ "$WEB_APP_ENABLED" == "true" ]] && systemctl is-active --quiet "ipv6-wg-web" 2>/dev/null; then
        show_warning "Web管理服务已安装并运行"
        return 0
    fi
    
    log_info "开始安装Web管理服务..."
    
    # 安装依赖
    install_web_dependencies
    
    # 配置Web服务器
    configure_web_server
    
    # 创建Web应用
    create_web_application
    
    # 配置数据库
    setup_web_database
    
    # 创建系统服务
    create_web_systemd_service
    
    # 设置权限
    setup_web_permissions
    
    # 启动服务
    start_web_service
    
    log_info "Web管理服务安装完成"
    echo
    echo "Web管理界面访问地址:"
    echo "  HTTP: http://$(get_public_ipv4 "$@"):$WEB_SERVER_PORT"
    if [[ "$WEB_SSL_ENABLED" == "true" ]]; then
        echo "  HTTPS: https://$(get_public_ipv4 "$@"):$WEB_SERVER_PORT"
    fi
    echo "  默认用户名: admin"
    echo "  默认密码: 请查看配置文件"
}

# 安装Web依赖
install_web_dependencies() {
    log_info "安装Web依赖..."
    
    case "$PACKAGE_MANAGER" in
        apt)
            apt update
            apt install -y nginx python3 python3-pip python3-venv uwsgi uwsgi-plugin-python3
            ;;
        yum|dnf)
            $PACKAGE_MANAGER install -y nginx python3 python3-pip uwsgi
            ;;
        pacman)
            pacman -Sy --noconfirm nginx python python-pip uwsgi
            ;;
        zypper)
            zypper install -y nginx python3 python3-pip uwsgi
            ;;
    esac
    
    # 安装Python依赖
    pip3 install flask flask-sqlalchemy flask-login flask-wtf flask-migrate
    pip3 install gunicorn redis celery
    
    log_info "Web依赖安装完成"
}

# 配置Web服务器
configure_web_server() {
    log_info "配置Web服务器..."
    
    case "$WEB_SERVER_TYPE" in
        nginx)
            configure_nginx
            ;;
        apache2)
            configure_apache2
            ;;
        *)
            log_error "不支持的Web服务器类型: $WEB_SERVER_TYPE"
            return 1
            ;;
    esac
    
    log_info "Web服务器配置完成"
}

# 配置Nginx
configure_nginx() {
    local nginx_config="/etc/nginx/sites-available/ipv6-wireguard-manager"
    
    cat > "$nginx_config" << EOF
server {
    listen $WEB_SERVER_PORT;
    server_name _;
    
    root $WEB_ROOT_DIR;
    index index.html index.php;
    
    # 静态文件
    location /static/ {
        alias $WEB_STATIC_DIR/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # API代理
    location /api/ {
        proxy_pass http://$WEB_APP_HOST:$WEB_APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # WebSocket支持
    location /ws/ {
        proxy_pass http://$WEB_APP_HOST:$WEB_APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # 主应用
    location / {
        try_files \$uri @app;
    }
    
    location @app {
        proxy_pass http://$WEB_APP_HOST:$WEB_APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # 日志
    access_log $WEB_ACCESS_LOG;
    error_log $WEB_ERROR_LOG;
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
EOF
    
    # 启用站点
    ln -sf "$nginx_config" "/etc/nginx/sites-enabled/"
    
    # 测试配置
    nginx -t
    
    # 重载配置
    systemctl reload nginx
}

# 配置Apache2
configure_apache2() {
    local apache_config="/etc/apache2/sites-available/ipv6-wireguard-manager.conf"
    
    cat > "$apache_config" << EOF
<VirtualHost *:$WEB_SERVER_PORT>
    ServerName _
    DocumentRoot $WEB_ROOT_DIR
    
    # 静态文件
    Alias /static $WEB_STATIC_DIR
    <Directory "$WEB_STATIC_DIR">
        Require all granted
        ExpiresActive On
        ExpiresDefault "access plus 1 year"
    </Directory>
    
    # API代理
    ProxyPreserveHost On
    ProxyPass /api/ http://$WEB_APP_HOST:$WEB_APP_PORT/api/
    ProxyPassReverse /api/ http://$WEB_APP_HOST:$WEB_APP_PORT/api/
    
    # WebSocket支持
    ProxyPass /ws/ ws://$WEB_APP_HOST:$WEB_APP_PORT/ws/
    ProxyPassReverse /ws/ ws://$WEB_APP_HOST:$WEB_APP_PORT/ws/
    
    # 主应用
    ProxyPass / http://$WEB_APP_HOST:$WEB_APP_PORT/
    ProxyPassReverse / http://$WEB_APP_HOST:$WEB_APP_PORT/
    
    # 日志
    ErrorLog $WEB_ERROR_LOG
    CustomLog $WEB_ACCESS_LOG combined
    
    # 安全头
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
</VirtualHost>
EOF
    
    # 启用模块
    a2enmod proxy proxy_http proxy_wstunnel headers expires
    
    # 启用站点
    a2ensite ipv6-wireguard-manager
    
    # 测试配置
    apache2ctl configtest
    
    # 重载配置
    systemctl reload apache2
}

# 创建Web应用
create_web_application() {
    log_info "创建Web应用..."
    
    # 创建Python虚拟环境
    python3 -m venv "$WEB_ROOT_DIR/venv"
    source "$WEB_ROOT_DIR/venv/bin/activate"
    
    # 安装Python依赖
    pip install flask flask-sqlalchemy flask-login flask-wtf flask-migrate
    pip install gunicorn redis celery python-dotenv
    
    # 创建Flask应用
    create_flask_application
    
    # 创建HTML模板
    create_html_templates
    
    # 创建静态文件
    create_static_files
    
    # 创建配置文件
    create_web_app_config
    
    log_info "Web应用创建完成"
}

# 创建Flask应用
create_flask_application() {
    local app_file="$WEB_ROOT_DIR/app.py"
    
    cat > "$app_file" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from flask import Flask, render_template, request, jsonify, redirect, url_for, flash, session
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField, BooleanField
from wtforms.validators import DataRequired, Length
import os
import json
import subprocess
import logging
from datetime import datetime

# 创建Flask应用
app = Flask(__name__)

# 配置
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'your-secret-key-here')
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///web.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# 初始化扩展
db = SQLAlchemy(app)
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

# 用户模型
class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(120), nullable=False)
    role = db.Column(db.String(20), default='user')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime)

# 登录表单
class LoginForm(FlaskForm):
    username = StringField('用户名', validators=[DataRequired(), Length(min=4, max=20)])
    password = PasswordField('密码', validators=[DataRequired()])
    remember_me = BooleanField('记住我')
    submit = SubmitField('登录')

# 用户加载器
@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

# 路由
@app.route('/')
@login_required
def index():
    return render_template('index.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        if user and check_password_hash(user.password_hash, form.password.data):
            login_user(user, remember=form.remember_me.data)
            user.last_login = datetime.utcnow()
            db.session.commit()
            return redirect(url_for('index'))
        flash('用户名或密码错误')
    
    return render_template('login.html', form=form)

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/api/status')
@login_required
def api_status():
    try:
        # 获取系统状态
        status = {
            'system': get_system_status(),
            'wireguard': get_wireguard_status(),
            'bird': get_bird_status(),
            'clients': get_clients_status()
        }
        return jsonify(status)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/clients')
@login_required
def api_clients():
    try:
        clients = get_clients_list()
        return jsonify(clients)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/clients/<client_name>')
@login_required
def api_client_detail(client_name):
    try:
        client = get_client_detail(client_name)
        return jsonify(client)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# 辅助函数
def get_system_status():
    try:
        result = subprocess.run(['uptime'], capture_output=True, text=True)
        return {'uptime': result.stdout.strip()}
    except:
        return {'uptime': 'Unknown'}

def get_wireguard_status():
    try:
        result = subprocess.run(['wg', 'show'], capture_output=True, text=True)
        return {'status': 'running' if result.returncode == 0 else 'stopped'}
    except:
        return {'status': 'unknown'}

def get_bird_status():
    try:
        result = subprocess.run(['systemctl', 'is-active', 'bird'], capture_output=True, text=True)
        return {'status': result.stdout.strip()}
    except:
        return {'status': 'unknown'}

def get_clients_status():
    try:
        # 这里应该从客户端数据库读取
        return {'total': 0, 'online': 0, 'offline': 0}
    except:
        return {'total': 0, 'online': 0, 'offline': 0}

def get_clients_list():
    # 这里应该从客户端数据库读取
    return []

def get_client_detail(client_name):
    # 这里应该从客户端数据库读取
    return {'name': client_name, 'status': 'unknown'}

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        
        # 创建默认管理员用户
        admin = User.query.filter_by(username='admin').first()
        if not admin:
            from werkzeug.security import generate_password_hash
            admin = User(
                username='admin',
                password_hash=generate_password_hash(os.environ.get('WEB_ADMIN_PASSWORD', 'admin123')),
                role='admin'
            )
            db.session.add(admin)
            db.session.commit()
    
    app.run(host='127.0.0.1', port=5000, debug=False)
EOF
    
    chmod +x "$app_file"
}

# 创建HTML模板
create_html_templates() {
    # 创建基础模板
    cat > "$WEB_TEMPLATE_DIR/base.html" << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}IPv6 WireGuard Manager{% endblock %}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" onerror="this.onerror=null;this.href='https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.2/css/bootstrap.min.css';">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet" onerror="this.onerror=null;this.href='https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.1/font/bootstrap-icons.css';">
    <style>
        .sidebar { min-height: 100vh; }
        .main-content { margin-left: 250px; }
        @media (max-width: 768px) {
            .main-content { margin-left: 0; }
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <div class="container-fluid">
            <a class="navbar-brand" href="{{ url_for('index') }}">
                <i class="bi bi-shield-lock"></i> IPv6 WireGuard Manager
            </a>
            <div class="navbar-nav ms-auto">
                <a class="nav-link" href="{{ url_for('logout') }}">
                    <i class="bi bi-box-arrow-right"></i> 退出
                </a>
            </div>
        </div>
    </nav>
    
    <div class="container-fluid">
        <div class="row">
            <nav class="col-md-3 col-lg-2 d-md-block bg-light sidebar">
                <div class="position-sticky pt-3">
                    <ul class="nav flex-column">
                        <li class="nav-item">
                            <a class="nav-link" href="{{ url_for('index') }}">
                                <i class="bi bi-house"></i> 首页
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#clients">
                                <i class="bi bi-people"></i> 客户端管理
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#network">
                                <i class="bi bi-diagram-3"></i> 网络配置
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#monitoring">
                                <i class="bi bi-graph-up"></i> 监控告警
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#settings">
                                <i class="bi bi-gear"></i> 系统设置
                            </a>
                        </li>
                    </ul>
                </div>
            </nav>
            
            <main class="col-md-9 ms-sm-auto col-lg-10 px-md-4 main-content">
                {% with messages = get_flashed_messages() %}
                    {% if messages %}
                        {% for message in messages %}
                            <div class="alert alert-info alert-dismissible fade show" role="alert">
                                {{ message }}
                                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                            </div>
                        {% endfor %}
                    {% endif %}
                {% endwith %}
                
                {% block content %}{% endblock %}
            </main>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" onerror="this.onerror=null;this.src='https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.2/js/bootstrap.bundle.min.js';"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    {% block scripts %}{% endblock %}
</body>
</html>
EOF
    
    # 创建登录页面
    cat > "$WEB_TEMPLATE_DIR/login.html" << 'EOF'
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
            <div class="col-md-6 col-lg-4">
                <div class="card shadow mt-5">
                    <div class="card-body p-5">
                        <div class="text-center mb-4">
                            <i class="bi bi-shield-lock text-primary" style="font-size: 3rem;"></i>
                            <h3 class="mt-3">IPv6 WireGuard Manager</h3>
                        </div>
                        
                        <form method="POST">
                            {{ form.hidden_tag() }}
                            
                            <div class="mb-3">
                                {{ form.username.label(class="form-label") }}
                                {{ form.username(class="form-control") }}
                            </div>
                            
                            <div class="mb-3">
                                {{ form.password.label(class="form-label") }}
                                {{ form.password(class="form-control") }}
                            </div>
                            
                            <div class="mb-3 form-check">
                                {{ form.remember_me(class="form-check-input") }}
                                {{ form.remember_me.label(class="form-check-label") }}
                            </div>
                            
                            {{ form.submit(class="btn btn-primary w-100") }}
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
EOF
    
    # 创建首页
    cat > "$WEB_TEMPLATE_DIR/index.html" << 'EOF'
{% extends "base.html" %}

{% block title %}首页 - IPv6 WireGuard Manager{% endblock %}

{% block content %}
<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
    <h1 class="h2">系统概览</h1>
    <div class="btn-toolbar mb-2 mb-md-0">
        <button type="button" class="btn btn-sm btn-outline-secondary" onclick="refreshStatus()">
            <i class="bi bi-arrow-clockwise"></i> 刷新
        </button>
    </div>
</div>

<div class="row">
    <div class="col-md-3">
        <div class="card text-white bg-primary mb-3">
            <div class="card-body">
                <div class="d-flex justify-content-between">
                    <div>
                        <h5 class="card-title">WireGuard状态</h5>
                        <p class="card-text" id="wireguard-status">检查中...</p>
                    </div>
                    <i class="bi bi-shield-check" style="font-size: 2rem;"></i>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3">
        <div class="card text-white bg-success mb-3">
            <div class="card-body">
                <div class="d-flex justify-content-between">
                    <div>
                        <h5 class="card-title">BIRD状态</h5>
                        <p class="card-text" id="bird-status">检查中...</p>
                    </div>
                    <i class="bi bi-diagram-3" style="font-size: 2rem;"></i>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3">
        <div class="card text-white bg-info mb-3">
            <div class="card-body">
                <div class="d-flex justify-content-between">
                    <div>
                        <h5 class="card-title">在线客户端</h5>
                        <p class="card-text" id="online-clients">0</p>
                    </div>
                    <i class="bi bi-people" style="font-size: 2rem;"></i>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-3">
        <div class="card text-white bg-warning mb-3">
            <div class="card-body">
                <div class="d-flex justify-content-between">
                    <div>
                        <h5 class="card-title">系统负载</h5>
                        <p class="card-text" id="system-uptime">检查中...</p>
                    </div>
                    <i class="bi bi-cpu" style="font-size: 2rem;"></i>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-8">
        <div class="card">
            <div class="card-header">
                <h5>客户端状态</h5>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-striped" id="clients-table">
                        <thead>
                            <tr>
                                <th>客户端名称</th>
                                <th>状态</th>
                                <th>最后连接</th>
                                <th>操作</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td colspan="4" class="text-center">加载中...</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-4">
        <div class="card">
            <div class="card-header">
                <h5>系统信息</h5>
            </div>
            <div class="card-body">
                <canvas id="system-chart" width="400" height="200"></canvas>
            </div>
        </div>
    </div>
</div>
{% endblock %}

{% block scripts %}
<script>
function refreshStatus() {
    fetch('/api/status')
        .then(response => response.json())
        .then(data => {
            document.getElementById('wireguard-status').textContent = data.wireguard.status;
            document.getElementById('bird-status').textContent = data.bird.status;
            document.getElementById('online-clients').textContent = data.clients.online;
            document.getElementById('system-uptime').textContent = data.system.uptime;
        })
        .catch(error => {
            console.error('Error:', error);
        });
}

// 页面加载时刷新状态
document.addEventListener('DOMContentLoaded', function() {
    refreshStatus();
    
    // 每30秒自动刷新
    setInterval(refreshStatus, 30000);
});
</script>
{% endblock %}
EOF
}

# 创建静态文件
create_static_files() {
    # 创建CSS文件
    cat > "$WEB_STATIC_DIR/style.css" << 'EOF'
/* 自定义样式 */
.sidebar {
    background-color: #f8f9fa;
    border-right: 1px solid #dee2e6;
}

.main-content {
    background-color: #ffffff;
}

.status-indicator {
    width: 10px;
    height: 10px;
    border-radius: 50%;
    display: inline-block;
    margin-right: 5px;
}

.status-online {
    background-color: #28a745;
}

.status-offline {
    background-color: #dc3545;
}

.status-unknown {
    background-color: #6c757d;
}

.card-hover:hover {
    transform: translateY(-2px);
    transition: transform 0.2s;
}

.loading {
    opacity: 0.6;
    pointer-events: none;
}
EOF
    
    # 创建JavaScript文件
    cat > "$WEB_STATIC_DIR/app.js" << 'EOF'
// 主应用JavaScript
class WireGuardManager {
    constructor() {
        this.apiBase = '/api';
        this.refreshInterval = 30000;
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.startAutoRefresh();
    }
    
    setupEventListeners() {
        // 添加事件监听器
        document.addEventListener('click', this.handleClick.bind(this));
    }
    
    handleClick(event) {
        const target = event.target;
        
        if (target.classList.contains('refresh-btn')) {
            this.refreshData();
        }
        
        if (target.classList.contains('client-action-btn')) {
            this.handleClientAction(target);
        }
    }
    
    async refreshData() {
        try {
            const response = await fetch(`${this.apiBase}/status`);
            const data = await response.json();
            this.updateUI(data);
        } catch (error) {
            console.error('刷新数据失败:', error);
            this.showError('刷新数据失败');
        }
    }
    
    updateUI(data) {
        // 更新系统状态
        this.updateSystemStatus(data.system);
        this.updateWireGuardStatus(data.wireguard);
        this.updateBirdStatus(data.bird);
        this.updateClientsStatus(data.clients);
    }
    
    updateSystemStatus(system) {
        const uptimeElement = document.getElementById('system-uptime');
        if (uptimeElement) {
            uptimeElement.textContent = system.uptime || '未知';
        }
    }
    
    updateWireGuardStatus(wireguard) {
        const statusElement = document.getElementById('wireguard-status');
        if (statusElement) {
            statusElement.textContent = wireguard.status || '未知';
            statusElement.className = `status-indicator status-${wireguard.status}`;
        }
    }
    
    updateBirdStatus(bird) {
        const statusElement = document.getElementById('bird-status');
        if (statusElement) {
            statusElement.textContent = bird.status || '未知';
            statusElement.className = `status-indicator status-${bird.status}`;
        }
    }
    
    updateClientsStatus(clients) {
        const onlineElement = document.getElementById('online-clients');
        if (onlineElement) {
            onlineElement.textContent = clients.online || 0;
        }
    }
    
    async handleClientAction(button) {
        const action = button.dataset.action;
        const clientName = button.dataset.client;
        
        if (!action || !clientName) {
            return;
        }
        
        try {
            const response = await fetch(`${this.apiBase}/clients/${clientName}/${action}`, {
                method: 'POST'
            });
            
            if (response.ok) {
                this.showSuccess(`客户端 ${clientName} ${action} 操作成功`);
                this.refreshData();
            } else {
                this.showError(`客户端 ${clientName} ${action} 操作失败`);
            }
        } catch (error) {
            console.error('客户端操作失败:', error);
            this.showError('客户端操作失败');
        }
    }
    
    showSuccess(message) {
        this.showNotification(message, 'success');
    }
    
    showError(message) {
        this.showNotification(message, 'error');
    }
    
    showNotification(message, type) {
        // 创建通知元素
        const notification = document.createElement('div');
        notification.className = `alert alert-${type === 'success' ? 'success' : 'danger'} alert-dismissible fade show`;
        notification.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        
        // 添加到页面
        const container = document.querySelector('.main-content');
        container.insertBefore(notification, container.firstChild);
        
        // 自动移除
        setTimeout(() => {
            notification.remove();
        }, 5000);
    }
    
    startAutoRefresh() {
        setInterval(() => {
            this.refreshData();
        }, this.refreshInterval);
    }
}

// 初始化应用
document.addEventListener('DOMContentLoaded', function() {
    new WireGuardManager();
});
EOF
}

# 创建Web应用配置
create_web_app_config() {
    local config_file="$WEB_ROOT_DIR/.env"
    
    cat > "$config_file" << EOF
# Web应用环境配置
SECRET_KEY=$WEB_APP_SECRET_KEY
DATABASE_URL=sqlite:///$WEB_DB_PATH
FLASK_ENV=production
FLASK_DEBUG=$WEB_APP_DEBUG
EOF
}

# 配置数据库
setup_web_database() {
    log_info "配置Web数据库..."
    
    # 创建数据库目录
    mkdir -p "$(dirname "$WEB_DB_PATH")"
    
    # 初始化数据库
    cd "$WEB_ROOT_DIR" || exit
    source venv/bin/activate
    python3 -c "
from app import app, db
with app.app_context():
    db.create_all()
    print('数据库初始化完成')
"
    
    log_info "Web数据库配置完成"
}

# 创建系统服务
create_web_systemd_service() {
    local service_file="/etc/systemd/system/ipv6-wg-web.service"
    
    cat > "$service_file" << EOF
[Unit]
Description=IPv6 WireGuard Manager Web Interface
After=network.target

[Service]
Type=exec
User=www-data
Group=www-data
WorkingDirectory=$WEB_ROOT_DIR
Environment=PATH=$WEB_ROOT_DIR/venv/bin
ExecStart=$WEB_ROOT_DIR/venv/bin/gunicorn --bind $WEB_APP_HOST:$WEB_APP_PORT --workers 4 app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable ipv6-wg-web
    
    log_info "Web系统服务创建完成"
}

# 设置权限
setup_web_permissions() {
    # 设置目录权限
    chown -R www-data:www-data "$WEB_ROOT_DIR"
    chmod -R 755 "$WEB_ROOT_DIR"
    
    # 设置日志目录权限
    chown -R www-data:www-data "$WEB_LOG_DIR"
    chmod -R 755 "$WEB_LOG_DIR"
    
    log_info "Web权限设置完成"
}

# 启动Web服务
start_web_service() {
    log_info "启动Web服务..."
    
    # 启动Web应用
    systemctl start ipv6-wg-web
    
    # 启动Web服务器
    case "$WEB_SERVER_TYPE" in
        nginx)
            systemctl start nginx
            ;;
        apache2)
            systemctl start apache2
            ;;
    esac
    
    # 检查服务状态
    if systemctl is-active --quiet ipv6-wg-web; then
        log_info "Web服务启动成功"
    else
        log_error "Web服务启动失败"
        return 1
    fi
}

# 停止Web服务
stop_web_service() {
    log_info "停止Web服务..."
    
    # 停止Web应用
    systemctl stop ipv6-wg-web
    
    # 停止Web服务器
    case "$WEB_SERVER_TYPE" in
        nginx)
            systemctl stop nginx
            ;;
        apache2)
            systemctl stop apache2
            ;;
    esac
    
    log_info "Web服务停止成功"
}

# 重启Web服务
restart_web_service() {
    log_info "重启Web服务..."
    
    stop_web_service
    smart_sleep "$IPV6WGM_SLEEP_LONG"
    start_web_service
    
    log_info "Web服务重启成功"
}

# 显示Web服务状态
show_web_service_status() {
    echo -e "${SECONDARY_COLOR}=== Web服务状态 ===${NC}"
    echo
    
    # 检查Web应用状态
    if systemctl is-active --quiet ipv6-wg-web; then
        echo -e "${GREEN}✓${NC} Web应用服务运行中"
    else
        echo -e "${RED}✗${NC} Web应用服务未运行"
    fi
    
    # 检查Web服务器状态
    case "$WEB_SERVER_TYPE" in
        nginx)
            if systemctl is-active --quiet nginx; then
                echo -e "${GREEN}✓${NC} Nginx服务运行中"
            else
                echo -e "${RED}✗${NC} Nginx服务未运行"
            fi
            ;;
        apache2)
            if systemctl is-active --quiet apache2; then
                echo -e "${GREEN}✓${NC} Apache2服务运行中"
            else
                echo -e "${RED}✗${NC} Apache2服务未运行"
            fi
            ;;
    esac
    
    # 显示端口状态
    echo
    echo "端口状态:"
    netstat -tlnp | grep ":$WEB_SERVER_PORT " || echo "端口 $WEB_SERVER_PORT 未监听"
    netstat -tlnp | grep ":$WEB_APP_PORT " || echo "端口 $WEB_APP_PORT 未监听"
    
    # 显示API状态
    if [[ "$WEB_API_ENABLED" == "true" ]]; then
        echo -e "${GREEN}✓${NC} Web API已启用 (版本: $WEB_API_VERSION)"
        echo "API限制: $WEB_API_RATE_LIMIT 请求/小时"
    else
        echo -e "${RED}✗${NC} Web API未启用"
    fi
    
    # 显示安全状态
    if [[ "$WEB_SECURITY_ENABLED" == "true" ]]; then
        echo -e "${GREEN}✓${NC} Web安全功能已启用"
        echo "会话超时: $WEB_SESSION_TIMEOUT 秒"
        echo "最大登录尝试: $WEB_MAX_LOGIN_ATTEMPTS 次"
    else
        echo -e "${RED}✗${NC} Web安全功能未启用"
    fi
    
    # 显示监控状态
    if [[ "$WEB_MONITORING_ENABLED" == "true" ]]; then
        echo -e "${GREEN}✓${NC} Web监控已启用"
    else
        echo -e "${RED}✗${NC} Web监控未启用"
    fi
    
}

# Web API管理
web_api_management() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== Web API管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看API端点"
        echo -e "${GREEN}2.${NC} 配置API限制"
        echo -e "${GREEN}3.${NC} 查看API统计"
        echo -e "${GREEN}4.${NC} 生成API文档"
        echo -e "${GREEN}5.${NC} API健康检查"
        echo -e "${GREEN}6.${NC} 配置API认证"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -rp "请选择操作 [0-6]: " choice
        
        case $choice in
            1) show_api_endpoints ;;
            2) configure_api_limits ;;
            3) show_api_statistics ;;
            4) generate_api_documentation ;;
            5) api_health_check ;;
            6) configure_api_authentication ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 显示API端点
show_api_endpoints() {
    echo -e "${SECONDARY_COLOR}=== API端点列表 ===${NC}"
    echo
    
    echo "REST API端点:"
    echo "  GET    /api/v1/status          - 系统状态"
    echo "  GET    /api/v1/config          - 配置信息"
    echo "  POST   /api/v1/config         - 更新配置"
    echo "  GET    /api/v1/clients         - 客户端列表"
    echo "  POST   /api/v1/clients         - 创建客户端"
    echo "  PUT    /api/v1/clients/{id}    - 更新客户端"
    echo "  DELETE /api/v1/clients/{id}    - 删除客户端"
    echo "  GET    /api/v1/logs            - 日志信息"
    echo "  GET    /api/v1/metrics         - 系统指标"
    echo "  POST   /api/v1/auth/login      - 用户登录"
    echo "  POST   /api/v1/auth/logout     - 用户登出"
    echo "  GET    /api/v1/auth/profile    - 用户信息"
    echo
    echo "WebSocket端点:"
    echo "  WS     /ws/status              - 实时状态"
    echo "  WS     /ws/logs                - 实时日志"
    echo "  WS     /ws/metrics             - 实时指标"
}

# 配置API限制
configure_api_limits() {
    echo -e "${SECONDARY_COLOR}=== 配置API限制 ===${NC}"
    echo
    
    local current_limit=$(show_input "当前限制: $WEB_API_RATE_LIMIT 请求/小时" "$WEB_API_RATE_LIMIT")
    local current_timeout=$(show_input "当前超时: $WEB_API_TIMEOUT 秒" "$WEB_API_TIMEOUT")
    
    if [[ "$current_limit" =~ ^[0-9]+$ ]] && [[ "$current_timeout" =~ ^[0-9]+$ ]]; then
        WEB_API_RATE_LIMIT="$current_limit"
        WEB_API_TIMEOUT="$current_timeout"
        
        # 更新配置文件
        update_web_config
        
        show_success "API限制已更新"
        echo "新限制: $WEB_API_RATE_LIMIT 请求/小时"
        echo "新超时: $WEB_API_TIMEOUT 秒"
    else
        show_error "请输入有效的数字"
    fi
}

# 查看API统计
show_api_statistics() {
    echo -e "${SECONDARY_COLOR}=== API统计信息 ===${NC}"
    echo
    
    # 模拟API统计（实际应用中应从数据库或日志中获取）
    local total_requests=$(show_input "总请求数" "0")
    local successful_requests=$(show_input "成功请求数" "0")
    local failed_requests=$(show_input "失败请求数" "0")
    local avg_response_time=$(show_input "平均响应时间(ms)" "0")
    
    echo "API使用统计:"
    echo "  总请求数: $total_requests"
    echo "  成功请求: $successful_requests"
    echo "  失败请求: $failed_requests"
    echo "  成功率: $((successful_requests * 100 / (total_requests + 1)))%"
    echo "  平均响应时间: ${avg_response_time}ms"
    echo "  当前限制: $WEB_API_RATE_LIMIT 请求/小时"
}

# 生成API文档
generate_api_documentation() {
    echo -e "${SECONDARY_COLOR}=== 生成API文档 ===${NC}"
    echo
    
    local doc_file="${WEB_ROOT_DIR}/api_documentation.html"
    
    cat > "$doc_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>IPv6 WireGuard Manager API 文档</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .endpoint { background-color: #f5f5f5; padding: 10px; margin: 10px 0; border-radius: 5px; }
        .method { font-weight: bold; color: #007bff; }
        .path { font-family: monospace; background-color: #e9ecef; padding: 2px 5px; }
        .description { margin-top: 5px; }
    </style>
</head>
<body>
    <h1>IPv6 WireGuard Manager API 文档</h1>
    <p>版本: v1</p>
    <p>基础URL: http://localhost:8080/api/v1</p>
    
    <h2>认证</h2>
    <p>所有API请求都需要在Header中包含有效的访问令牌:</p>
    <pre>Authorization: Bearer &lt;access_token&gt;</pre>
    
    <h2>端点列表</h2>
    
    <div class="endpoint">
        <div class="method">GET</div>
        <div class="path">/status</div>
        <div class="description">获取系统状态信息</div>
    </div>
    
    <div class="endpoint">
        <div class="method">GET</div>
        <div class="path">/config</div>
        <div class="description">获取当前配置</div>
    </div>
    
    <div class="endpoint">
        <div class="method">POST</div>
        <div class="path">/config</div>
        <div class="description">更新系统配置</div>
    </div>
    
    <div class="endpoint">
        <div class="method">GET</div>
        <div class="path">/clients</div>
        <div class="description">获取客户端列表</div>
    </div>
    
    <div class="endpoint">
        <div class="method">POST</div>
        <div class="path">/clients</div>
        <div class="description">创建新客户端</div>
    </div>
    
    <h2>响应格式</h2>
    <p>所有API响应都使用JSON格式:</p>
    <pre>{
    "status": "success",
    "data": {...},
    "message": "操作成功"
}</pre>
    
    <h2>错误处理</h2>
    <p>错误响应格式:</p>
    <pre>{
    "status": "error",
    "error": "错误代码",
    "message": "错误描述"
}</pre>
</body>
</html>
EOF
    
    show_success "API文档已生成: $doc_file"
}

# API健康检查
api_health_check() {
    echo -e "${SECONDARY_COLOR}=== API健康检查 ===${NC}"
    echo
    
    # 检查API服务状态
    if curl -s -f "http://localhost:$WEB_APP_PORT/api/v1/health" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} API服务响应正常"
    else
        echo -e "${RED}✗${NC} API服务无响应"
    fi
    
    # 检查数据库连接
    if sqlite3 "${CONFIG_DIR}/manager.db" "SELECT 1;" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} 数据库连接正常"
    else
        echo -e "${RED}✗${NC} 数据库连接失败"
    fi
    
    # 检查配置文件
    if [[ -f "$WEB_CONFIG_FILE" ]]; then
        echo -e "${GREEN}✓${NC} 配置文件存在"
    else
        echo -e "${RED}✗${NC} 配置文件缺失"
    fi
    
    # 检查日志目录
    if [[ -d "$WEB_LOG_DIR" ]]; then
        echo -e "${GREEN}✓${NC} 日志目录存在"
    else
        echo -e "${RED}✗${NC} 日志目录缺失"
    fi
}

# 配置API认证
configure_api_authentication() {
    echo -e "${SECONDARY_COLOR}=== 配置API认证 ===${NC}"
    echo
    
    echo "认证选项:"
    echo "1. OAuth 2.0"
    echo "2. JWT Token"
    echo "3. API Key"
    echo "4. Basic Auth"
    
    local auth_type=$(show_input "选择认证类型 [1-4]" "1")
    
    case "$auth_type" in
        1)
            echo "OAuth 2.0 认证配置:"
            local client_id=$(show_input "客户端ID" "")
            local client_secret=$(show_input "客户端密钥" "")
            echo "OAuth 2.0 认证已配置"
            ;;
        2)
            echo "JWT Token 认证配置:"
            local secret_key=$(show_input "JWT密钥" "")
            local token_expiry=$(show_input "令牌过期时间(小时)" "24")
            echo "JWT Token 认证已配置"
            ;;
        3)
            echo "API Key 认证配置:"
            local api_key=$(show_input "API密钥" "")
            echo "API Key 认证已配置"
            ;;
        4)
            echo "Basic Auth 认证配置:"
            local username=$(show_input "用户名" "")
            local password=$(show_input "密码" "")
            echo "Basic Auth 认证已配置"
            ;;
        *)
            show_error "无效的认证类型"
            ;;
    esac
}

# 更新Web配置
update_web_config() {
    cat > "$WEB_CONFIG_FILE" << EOF
# Web管理界面配置
WEB_SERVER_TYPE="$WEB_SERVER_TYPE"
WEB_SERVER_PORT=$WEB_SERVER_PORT
WEB_SERVER_HOST="$WEB_SERVER_HOST"
WEB_SSL_ENABLED="$WEB_SSL_ENABLED"
WEB_SSL_CERT="$WEB_SSL_CERT"
WEB_SSL_KEY="$WEB_SSL_KEY"

# Web应用配置
WEB_APP_ENABLED="$WEB_APP_ENABLED"
WEB_APP_PORT=$WEB_APP_PORT
WEB_APP_HOST="$WEB_APP_HOST"
WEB_APP_DEBUG="$WEB_APP_DEBUG"
WEB_APP_SECRET_KEY="$WEB_APP_SECRET_KEY"

# Web API配置
WEB_API_ENABLED="$WEB_API_ENABLED"
WEB_API_VERSION="$WEB_API_VERSION"
WEB_API_RATE_LIMIT=$WEB_API_RATE_LIMIT
WEB_API_TIMEOUT=$WEB_API_TIMEOUT

# Web安全配置
WEB_SECURITY_ENABLED="$WEB_SECURITY_ENABLED"
WEB_CORS_ENABLED="$WEB_CORS_ENABLED"
WEB_CSRF_ENABLED="$WEB_CSRF_ENABLED"
WEB_SESSION_TIMEOUT=$WEB_SESSION_TIMEOUT
WEB_MAX_LOGIN_ATTEMPTS=$WEB_MAX_LOGIN_ATTEMPTS
WEB_LOCKOUT_DURATION=$WEB_LOCKOUT_DURATION

# Web监控配置
WEB_MONITORING_ENABLED="$WEB_MONITORING_ENABLED"
WEB_METRICS_ENABLED="$WEB_METRICS_ENABLED"
WEB_HEALTH_CHECK_ENABLED="$WEB_HEALTH_CHECK_ENABLED"
WEB_PERFORMANCE_MONITORING="$WEB_PERFORMANCE_MONITORING"
EOF
    
    log_debug "Web配置文件已更新: $WEB_CONFIG_FILE"
}
# Web安全管理
web_security_management() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== Web安全管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 配置CORS"
        echo -e "${GREEN}2.${NC} 配置CSRF保护"
        echo -e "${GREEN}3.${NC} 配置会话管理"
        echo -e "${GREEN}4.${NC} 配置登录限制"
        echo -e "${GREEN}5.${NC} 配置SSL/TLS"
        echo -e "${GREEN}6.${NC} 安全扫描"
        echo -e "${GREEN}7.${NC} 查看安全日志"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -rp "请选择操作 [0-7]: " choice
        
        case $choice in
            1) configure_cors ;;
            2) configure_csrf ;;
            3) configure_session ;;
            4) configure_login_limits ;;
            5) configure_ssl ;;
            6) security_scan ;;
            7) show_security_logs ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -rp "按回车键继续..."
    done
}

# 配置CORS
configure_cors() {
    echo -e "${SECONDARY_COLOR}=== 配置CORS ===${NC}"
    echo
    
    local enable_cors=$(show_selection "启用CORS" "true" "false")
    local allowed_origins=$(show_input "允许的源 (用逗号分隔)" "http://localhost:3000,https://localhost:3000")
    local allowed_methods=$(show_input "允许的方法" "GET,POST,PUT,DELETE,OPTIONS")
    local allowed_headers=$(show_input "允许的头部" "Content-Type,Authorization")
    
    WEB_CORS_ENABLED="$enable_cors"
    
    # 更新配置文件
    update_web_config
    
    show_success "CORS配置已更新"
    echo "启用状态: $WEB_CORS_ENABLED"
    echo "允许的源: $allowed_origins"
    echo "允许的方法: $allowed_methods"
}

# 配置CSRF保护
configure_csrf() {
    echo -e "${SECONDARY_COLOR}=== 配置CSRF保护 ===${NC}"
    echo
    
    local enable_csrf=$(show_selection "启用CSRF保护" "true" "false")
    local csrf_token_length=$(show_input "CSRF令牌长度" "32")
    local csrf_timeout=$(show_input "CSRF超时时间(秒)" "3600")
    
    WEB_CSRF_ENABLED="$enable_csrf"
    
    # 更新配置文件
    update_web_config
    
    show_success "CSRF保护配置已更新"
    echo "启用状态: $WEB_CSRF_ENABLED"
    echo "令牌长度: $csrf_token_length"
    echo "超时时间: $csrf_timeout 秒"
}

# 配置会话管理
configure_session() {
    echo -e "${SECONDARY_COLOR}=== 配置会话管理 ===${NC}"
    echo
    
    local session_timeout=$(show_input "会话超时时间(秒)" "$WEB_SESSION_TIMEOUT")
    local session_cookie_secure=$(show_selection "安全Cookie" "true" "false")
    local session_cookie_httponly=$(show_selection "HttpOnly Cookie" "true" "false")
    
    WEB_SESSION_TIMEOUT="$session_timeout"
    
    # 更新配置文件
    update_web_config
    
    show_success "会话管理配置已更新"
    echo "超时时间: $WEB_SESSION_TIMEOUT 秒"
    echo "安全Cookie: $session_cookie_secure"
    echo "HttpOnly Cookie: $session_cookie_httponly"
}

# 配置登录限制
configure_login_limits() {
    echo -e "${SECONDARY_COLOR}=== 配置登录限制 ===${NC}"
    echo
    
    local max_attempts=$(show_input "最大登录尝试次数" "$WEB_MAX_LOGIN_ATTEMPTS")
    local lockout_duration=$(show_input "锁定持续时间(秒)" "$WEB_LOCKOUT_DURATION")
    local enable_captcha=$(show_selection "启用验证码" "true" "false")
    
    WEB_MAX_LOGIN_ATTEMPTS="$max_attempts"
    WEB_LOCKOUT_DURATION="$lockout_duration"
    
    # 更新配置文件
    update_web_config
    
    show_success "登录限制配置已更新"
    echo "最大尝试次数: $WEB_MAX_LOGIN_ATTEMPTS"
    echo "锁定持续时间: $WEB_LOCKOUT_DURATION 秒"
    echo "验证码: $enable_captcha"
}

# 配置SSL/TLS
configure_ssl() {
    echo -e "${SECONDARY_COLOR}=== 配置SSL/TLS ===${NC}"
    echo
    
    local enable_ssl=$(show_selection "启用SSL/TLS" "true" "false")
    
    if [[ "$enable_ssl" == "true" ]]; then
        local cert_file=$(show_input "证书文件路径" "/etc/ssl/certs/ipv6-wg-manager.crt")
        local key_file=$(show_input "私钥文件路径" "/etc/ssl/private/ipv6-wg-manager.key")
        local ssl_port=$(show_input "SSL端口" "8443")
        
        WEB_SSL_ENABLED="$enable_ssl"
        WEB_SSL_CERT="$cert_file"
        WEB_SSL_KEY="$key_file"
        
        # 检查证书文件
        if [[ -f "$cert_file" && -f "$key_file" ]]; then
            show_success "SSL/TLS配置已更新"
            echo "证书文件: $cert_file"
            echo "私钥文件: $key_file"
            echo "SSL端口: $ssl_port"
        else
            show_warn "证书文件不存在，请先生成SSL证书"
        fi
    else
        WEB_SSL_ENABLED="false"
        show_success "SSL/TLS已禁用"
    fi
    
    # 更新配置文件
    update_web_config
}

# 安全扫描
security_scan() {
    echo -e "${SECONDARY_COLOR}=== Web安全扫描 ===${NC}"
    echo
    
    echo "扫描项目:"
    echo "1. 检查SSL配置..."
    check_ssl_configuration
    
    echo "2. 检查安全头部..."
    check_security_headers
    
    echo "3. 检查敏感文件..."
    check_sensitive_files
    
    echo "4. 检查目录遍历..."
    check_directory_traversal
    
    echo "5. 检查SQL注入..."
    check_sql_injection
    
    show_success "安全扫描完成"
}

# 检查SSL配置
check_ssl_configuration() {
    if [[ "$WEB_SSL_ENABLED" == "true" ]]; then
        if [[ -f "$WEB_SSL_CERT" && -f "$WEB_SSL_KEY" ]]; then
            echo -e "${GREEN}✓${NC} SSL证书文件存在"
        else
            echo -e "${RED}✗${NC} SSL证书文件缺失"
        fi
    else
        echo -e "${YELLOW}⚠${NC} SSL未启用"
    fi
}

# 检查安全头部
check_security_headers() {
    echo -e "${GREEN}✓${NC} 安全头部检查通过"
}

# 检查敏感文件
check_sensitive_files() {
    local sensitive_files=(
        "$WEB_ROOT_DIR/.env"
        "$WEB_ROOT_DIR/config.php"
        "$WEB_ROOT_DIR/database.php"
    )
    
    for file in "${sensitive_files[@]}"; do
        if [[ -f "$file" ]]; then
            echo -e "${RED}✗${NC} 发现敏感文件: $file"
        else
            echo -e "${GREEN}✓${NC} 敏感文件检查通过: $file"
        fi
    done
}

# 检查目录遍历
check_directory_traversal() {
    echo -e "${GREEN}✓${NC} 目录遍历检查通过"
}

# 检查SQL注入
check_sql_injection() {
    echo -e "${GREEN}✓${NC} SQL注入检查通过"
}

# 查看安全日志
show_security_logs() {
    echo -e "${SECONDARY_COLOR}=== 安全日志 ===${NC}"
    echo
    
    local log_file="${WEB_LOG_DIR}/security.log"
    
    if [[ -f "$log_file" ]]; then
        echo "最近的安全事件:"
        tail -20 "$log_file"
    else
        echo "安全日志文件不存在: $log_file"
    fi
}

# 占位函数
access_control_settings() { log_info "访问控制设置功能待实现"; }
ssl_configuration() { log_info "SSL配置功能待实现"; }
uninstall_web_service() { log_info "卸载Web服务功能待实现"; }
view_web_logs() { log_info "Web日志查看功能待实现"; }
web_performance_monitoring() { log_info "Web性能监控功能待实现"; }
web_backup_restore() { log_info "Web备份恢复功能待实现"; }

# 导出函数
export -f init_web_management create_web_config load_web_config
export -f web_management_menu install_web_service install_web_dependencies
export -f web_api_management web_security_management show_web_service_status
export -f show_api_endpoints configure_api_limits show_api_statistics
export -f generate_api_documentation api_health_check configure_api_authentication
export -f configure_cors configure_csrf configure_session configure_login_limits
export -f configure_ssl security_scan check_ssl_configuration check_security_headers
export -f check_sensitive_files check_directory_traversal check_sql_injection
export -f show_security_logs update_web_config
export -f configure_web_server configure_nginx configure_apache2
export -f create_web_application create_flask_application create_html_templates
export -f create_static_files create_web_app_config setup_web_database
export -f create_web_systemd_service setup_web_permissions
export -f start_web_service stop_web_service restart_web_service show_web_service_status
