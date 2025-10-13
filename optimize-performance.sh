#!/bin/bash

echo "🚀 性能优化脚本 - IPv6 WireGuard Manager"
echo ""

# 检查系统资源
echo "📊 检查系统资源..."
echo "CPU核心数: $(nproc)"
echo "内存大小: $(free -h | awk '/^Mem:/ {print $2}')"
echo "磁盘空间: $(df -h / | awk 'NR==2 {print $4}')"
echo ""

# 1. 数据库优化
echo "🗄️ 数据库性能优化..."

# PostgreSQL配置优化
if command -v psql &> /dev/null; then
    echo "优化PostgreSQL配置..."
    
    # 备份原配置
    sudo cp /etc/postgresql/*/main/postgresql.conf /etc/postgresql/*/main/postgresql.conf.backup
    
    # 优化配置
    cat >> /etc/postgresql/*/main/postgresql.conf << 'EOF'

# 性能优化配置
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200

# 连接优化
max_connections = 100
shared_preload_libraries = 'pg_stat_statements'

# 日志优化
log_min_duration_statement = 1000
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0
log_autovacuum_min_duration = 0
log_error_verbosity = default
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_statement = 'none'
log_replication_commands = off
log_timezone = 'UTC'
log_rotation_age = 1d
log_rotation_size = 10MB
log_truncate_on_rotation = on
EOF

    # 重启PostgreSQL
    sudo systemctl restart postgresql
    echo "✅ PostgreSQL配置已优化"
else
    echo "⚠️ PostgreSQL未安装，跳过数据库优化"
fi

# 2. Redis优化
echo "🔴 Redis性能优化..."

if command -v redis-cli &> /dev/null; then
    echo "优化Redis配置..."
    
    # 备份原配置
    sudo cp /etc/redis/redis.conf /etc/redis/redis.conf.backup
    
    # 优化配置
    cat >> /etc/redis/redis.conf << 'EOF'

# 性能优化配置
maxmemory 256mb
maxmemory-policy allkeys-lru
tcp-keepalive 60
timeout 300
tcp-backlog 511
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis
EOF

    # 重启Redis
    sudo systemctl restart redis-server
    echo "✅ Redis配置已优化"
else
    echo "⚠️ Redis未安装，跳过Redis优化"
fi

# 3. Nginx优化
echo "🌐 Nginx性能优化..."

if command -v nginx &> /dev/null; then
    echo "优化Nginx配置..."
    
    # 备份原配置
    sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
    
    # 优化配置
    cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    # 基本设置
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    
    # 缓冲区设置
    client_body_buffer_size 128k;
    client_max_body_size 10m;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 4k;
    output_buffers 1 32k;
    postpone_output 1460;
    
    # 超时设置
    client_header_timeout 3m;
    client_body_timeout 3m;
    send_timeout 3m;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # 缓存设置
    open_file_cache max=1000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
    
    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;
    
    # 包含站点配置
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

    # 测试配置
    sudo nginx -t
    if [ $? -eq 0 ]; then
        sudo systemctl reload nginx
        echo "✅ Nginx配置已优化"
    else
        echo "❌ Nginx配置有误，恢复原配置"
        sudo cp /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf
    fi
else
    echo "⚠️ Nginx未安装，跳过Nginx优化"
fi

# 4. 系统内核优化
echo "⚙️ 系统内核优化..."

# 网络优化
cat >> /etc/sysctl.conf << 'EOF'

# 网络性能优化
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 65535
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1

# 文件系统优化
fs.file-max = 2097152
fs.nr_open = 1048576
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
EOF

# 应用内核参数
sysctl -p

# 5. 应用服务优化
echo "🔧 应用服务优化..."

# 创建systemd服务优化配置
if [ -f "/etc/systemd/system/ipv6-wireguard-manager.service" ]; then
    echo "优化systemd服务配置..."
    
    # 备份原配置
    sudo cp /etc/systemd/system/ipv6-wireguard-manager.service /etc/systemd/system/ipv6-wireguard-manager.service.backup
    
    # 优化配置
    cat > /etc/systemd/system/ipv6-wireguard-manager.service << 'EOF'
[Unit]
Description=IPv6 WireGuard Manager
After=network.target postgresql.service redis.service
Wants=postgresql.service redis.service

[Service]
Type=exec
User=www-data
Group=www-data
WorkingDirectory=/opt/ipv6-wireguard-manager
Environment=PATH=/opt/ipv6-wireguard-manager/venv/bin
Environment=PYTHONPATH=/opt/ipv6-wireguard-manager
ExecStart=/opt/ipv6-wireguard-manager/venv/bin/uvicorn app.main:app --host :: --port 8000 --workers 4
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ipv6-wireguard-manager

# 资源限制
LimitNOFILE=65536
LimitNPROC=32768

# 安全设置
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/ipv6-wireguard-manager
ReadWritePaths=/var/log/ipv6-wireguard-manager
ReadWritePaths=/tmp

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd配置
    sudo systemctl daemon-reload
    sudo systemctl restart ipv6-wireguard-manager
    echo "✅ systemd服务配置已优化"
fi

# 6. 前端优化
echo "🎨 前端性能优化..."

if [ -d "/opt/ipv6-wireguard-manager/frontend" ]; then
    cd /opt/ipv6-wireguard-manager/frontend
    
    # 安装依赖
    if [ -f "package.json" ]; then
        echo "安装前端依赖..."
        npm install --production
        
        # 构建优化版本
        echo "构建优化版本..."
        npm run build
        
        # 启用Gzip压缩
        echo "配置Gzip压缩..."
        if [ -f "dist" ]; then
            find dist -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" \) -exec gzip -k {} \;
        fi
        
        echo "✅ 前端已优化"
    fi
fi

# 7. 监控和日志优化
echo "📊 监控和日志优化..."

# 创建日志轮转配置
cat > /etc/logrotate.d/ipv6-wireguard-manager << 'EOF'
/var/log/ipv6-wireguard-manager/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload ipv6-wireguard-manager
    endscript
}
EOF

# 创建性能监控脚本
cat > /opt/ipv6-wireguard-manager/scripts/performance-monitor.sh << 'EOF'
#!/bin/bash

# 性能监控脚本
LOG_FILE="/var/log/ipv6-wireguard-manager/performance.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# 获取系统指标
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.2f"), $3/$2 * 100.0}')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d',' -f1)

# 获取应用指标
if systemctl is-active --quiet ipv6-wireguard-manager; then
    APP_STATUS="running"
else
    APP_STATUS="stopped"
fi

# 记录日志
echo "$DATE - CPU: ${CPU_USAGE}%, Memory: ${MEMORY_USAGE}%, Disk: ${DISK_USAGE}%, Load: ${LOAD_AVG}, App: ${APP_STATUS}" >> $LOG_FILE

# 检查告警条件
if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    echo "$DATE - WARNING: High CPU usage: ${CPU_USAGE}%" >> $LOG_FILE
fi

if (( $(echo "$MEMORY_USAGE > 85" | bc -l) )); then
    echo "$DATE - WARNING: High memory usage: ${MEMORY_USAGE}%" >> $LOG_FILE
fi

if (( $(echo "$DISK_USAGE > 90" | bc -l) )); then
    echo "$DATE - WARNING: High disk usage: ${DISK_USAGE}%" >> $LOG_FILE
fi
EOF

chmod +x /opt/ipv6-wireguard-manager/scripts/performance-monitor.sh

# 添加到crontab
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/ipv6-wireguard-manager/scripts/performance-monitor.sh") | crontab -

echo "✅ 监控和日志已优化"

# 8. 清理和优化
echo "🧹 清理和优化..."

# 清理临时文件
sudo apt-get clean
sudo apt-get autoremove -y

# 清理日志文件
sudo find /var/log -name "*.log" -type f -mtime +30 -delete
sudo find /var/log -name "*.gz" -type f -mtime +30 -delete

# 优化文件系统
sudo fstrim -av

echo "✅ 清理完成"

# 9. 性能测试
echo "🧪 性能测试..."

# 测试数据库连接
if command -v psql &> /dev/null; then
    echo "测试数据库连接..."
    sudo -u postgres psql -c "SELECT 1;" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ 数据库连接正常"
    else
        echo "❌ 数据库连接失败"
    fi
fi

# 测试Redis连接
if command -v redis-cli &> /dev/null; then
    echo "测试Redis连接..."
    redis-cli ping > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Redis连接正常"
    else
        echo "❌ Redis连接失败"
    fi
fi

# 测试应用服务
echo "测试应用服务..."
if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "✅ 应用服务运行正常"
else
    echo "❌ 应用服务未运行"
fi

# 测试WebSocket连接
echo "测试WebSocket连接..."
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health
if [ $? -eq 0 ]; then
    echo "✅ API服务响应正常"
else
    echo "❌ API服务响应异常"
fi

echo ""
echo "🎉 性能优化完成！"
echo ""
echo "优化内容："
echo "✅ 数据库配置优化"
echo "✅ Redis配置优化"
echo "✅ Nginx配置优化"
echo "✅ 系统内核参数优化"
echo "✅ 应用服务配置优化"
echo "✅ 前端构建优化"
echo "✅ 监控和日志优化"
echo "✅ 系统清理完成"
echo ""
echo "建议重启系统以应用所有优化："
echo "sudo reboot"
