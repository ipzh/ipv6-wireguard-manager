#!/bin/bash
# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# WebSocket实时通信模块
# 实现WebSocket实时通信功能

# WebSocket配置
WEBSOCKET_SERVER_PORT=3001
WEBSOCKET_LOG_FILE="${LOG_DIR}/websocket.log"
WEBSOCKET_PID_FILE="/var/run/ipv6-wireguard-websocket.pid"

# 初始化WebSocket模块
init_websocket_realtime() {
    log_info "初始化WebSocket实时通信模块..."
    
    # 创建WebSocket服务器
    create_websocket_server
    
    # 创建WebSocket客户端
    create_websocket_client
    
    # 创建WebSocket服务
    create_websocket_service
    
    log_info "WebSocket实时通信模块初始化完成"
}

# 创建WebSocket服务器
create_websocket_server() {
    cat > "${WEB_API_DIR}/websocket_server.py" << 'EOF'
#!/usr/bin/env python3
# WebSocket实时通信服务器

import asyncio
import websockets
import json
import sqlite3
import subprocess
import time
import signal
import sys
from datetime import datetime

class WebSocketServer:
    def __init__(self, host='localhost', port=3001):
        self.host = host
        self.port = port
        self.clients = set()
        self.running = True
        
        # 设置信号处理
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
    
    def signal_handler(self, signum, frame):
        print(f"收到信号 {signum}，正在关闭服务器...")
        self.running = False
        sys.exit(0)
    
    async def register_client(self, websocket, path):
        """注册客户端"""
        self.clients.add(websocket)
        print(f"客户端已连接: {websocket.remote_address}")
        
        try:
            # 发送欢迎消息
            await websocket.send(json.dumps({
                'type': 'welcome',
                'message': 'WebSocket连接已建立',
                'timestamp': datetime.now().isoformat()
            }))
            
            # 发送初始数据
            await self.send_initial_data(websocket)
            
            # 保持连接
            async for message in websocket:
                await self.handle_message(websocket, message)
                
        except websockets.exceptions.ConnectionClosed:
            pass
        finally:
            self.clients.remove(websocket)
            print(f"客户端已断开: {websocket.remote_address}")
    
    async def send_initial_data(self, websocket):
        """发送初始数据"""
        try:
            # 系统状态
            system_status = await self.get_system_status()
            await websocket.send(json.dumps({
                'type': 'system_status',
                'data': system_status,
                'timestamp': datetime.now().isoformat()
            }))
            
            # WireGuard状态
            wireguard_status = await self.get_wireguard_status()
            await websocket.send(json.dumps({
                'type': 'wireguard_status',
                'data': wireguard_status,
                'timestamp': datetime.now().isoformat()
            }))
            
            # 客户端状态
            clients_status = await self.get_clients_status()
            await websocket.send(json.dumps({
                'type': 'clients_status',
                'data': clients_status,
                'timestamp': datetime.now().isoformat()
            }))
            
        except Exception as e:
            print(f"发送初始数据失败: {e}")
    
    async def handle_message(self, websocket, message):
        """处理客户端消息"""
        try:
            data = json.loads(message)
            message_type = data.get('type')
            
            if message_type == 'ping':
                await websocket.send(json.dumps({
                    'type': 'pong',
                    'timestamp': datetime.now().isoformat()
                }))
            elif message_type == 'request_update':
                await self.send_system_update(websocket)
            elif message_type == 'subscribe':
                # 订阅特定类型的数据
                subscription = data.get('subscription', 'all')
                await websocket.send(json.dumps({
                    'type': 'subscription_confirmed',
                    'subscription': subscription,
                    'timestamp': datetime.now().isoformat()
                }))
                
        except json.JSONDecodeError:
            await websocket.send(json.dumps({
                'type': 'error',
                'message': '无效的JSON格式',
                'timestamp': datetime.now().isoformat()
            }))
        except Exception as e:
            await websocket.send(json.dumps({
                'type': 'error',
                'message': str(e),
                'timestamp': datetime.now().isoformat()
            }))
    
    async def get_system_status(self):
        """获取系统状态"""
        try:
            # CPU使用率
            cpu_result = subprocess.run(['top', '-bn1'], capture_output=True, text=True)
            cpu_usage = 0
            if cpu_result.returncode == 0:
                for line in cpu_result.stdout.split('\n'):
                    if 'Cpu(s)' in line:
                        cpu_usage = float(line.split(',')[0].split('%')[0].split()[-1])
                        break
            
            # 内存使用率
            memory_result = subprocess.run(['free'], capture_output=True, text=True)
            memory_usage = 0
            if memory_result.returncode == 0:
                lines = memory_result.stdout.split('\n')
                if len(lines) > 1:
                    mem_line = lines[1].split()
                    total = int(mem_line[1])
                    used = int(mem_line[2])
                    memory_usage = (used / total) * 100
            
            # 磁盘使用率
            disk_result = subprocess.run(['df', '-h', '/'], capture_output=True, text=True)
            disk_usage = 0
            if disk_result.returncode == 0:
                lines = disk_result.stdout.split('\n')
                if len(lines) > 1:
                    disk_line = lines[1].split()
                    disk_usage = int(disk_line[4].replace('%', ''))
            
            # 系统负载
            load_result = subprocess.run(['uptime'], capture_output=True, text=True)
            load_average = [0, 0, 0]
            if load_result.returncode == 0:
                load_str = load_result.stdout.split('load average:')[1].strip()
                load_average = [float(x.replace(',', '')) for x in load_str.split()[:3]]
            
            return {
                'cpu_usage': cpu_usage,
                'memory_usage': memory_usage,
                'disk_usage': disk_usage,
                'load_average': load_average,
                'uptime': subprocess.run(['uptime', '-p'], capture_output=True, text=True).stdout.strip()
            }
        except Exception as e:
            return {'error': str(e)}
    
    async def get_wireguard_status(self):
        """获取WireGuard状态"""
        try:
            result = subprocess.run(['wg', 'show'], capture_output=True, text=True)
            if result.returncode == 0:
                return {
                    'status': 'running',
                    'output': result.stdout
                }
            else:
                return {
                    'status': 'stopped',
                    'output': result.stderr
                }
        except Exception as e:
            return {
                'status': 'error',
                'error': str(e)
            }
    
    async def get_clients_status(self):
        """获取客户端状态"""
        try:
            # 这里应该从数据库读取客户端信息
            # 暂时返回模拟数据
            return {
                'total': 0,
                'online': 0,
                'offline': 0,
                'clients': []
            }
        except Exception as e:
            return {'error': str(e)}
    
    async def send_system_update(self, websocket):
        """发送系统更新"""
        try:
            system_status = await self.get_system_status()
            await websocket.send(json.dumps({
                'type': 'system_update',
                'data': system_status,
                'timestamp': datetime.now().isoformat()
            }))
        except Exception as e:
            print(f"发送系统更新失败: {e}")
    
    async def broadcast_update(self, update_type, data):
        """广播更新到所有客户端"""
        if self.clients:
            message = json.dumps({
                'type': update_type,
                'data': data,
                'timestamp': datetime.now().isoformat()
            })
            
            # 发送到所有连接的客户端
            disconnected = set()
            for client in self.clients:
                try:
                    await client.send(message)
                except websockets.exceptions.ConnectionClosed:
                    disconnected.add(client)
            
            # 移除断开的客户端
            self.clients -= disconnected
    
    async def start_server(self):
        """启动WebSocket服务器"""
        print(f"WebSocket服务器启动在 ws://{self.host}:{self.port}")
        
        async with websockets.serve(self.register_client, self.host, self.port):
            # 定期广播系统状态
            while self.running:
                try:
                    await self.broadcast_update('system_status', await self.get_system_status())
                    await asyncio.sleep(30)  # 每30秒广播一次
                except Exception as e:
                    print(f"广播更新失败: {e}")
                    await asyncio.sleep(5)

if __name__ == "__main__":
    server = WebSocketServer()
    asyncio.run(server.start_server())
EOF
    
    chmod +x "${WEB_API_DIR}/websocket_server.py"
}

# 创建WebSocket客户端
create_websocket_client() {
    cat > "${WEB_STATIC_DIR}/js/websocket-client.js" << 'EOF'
// WebSocket客户端实现
class WebSocketClient {
    constructor(url = 'ws://localhost:3001') {
        this.url = url;
        this.ws = null;
        this.reconnectInterval = 5000;
        this.maxReconnectAttempts = 10;
        this.reconnectAttempts = 0;
        this.subscriptions = new Set();
        this.messageHandlers = new Map();
        
        this.connect();
    }
    
    connect() {
        try {
            this.ws = new WebSocket(this.url);
            
            this.ws.onopen = (event) => {
                console.log('WebSocket连接已建立');
                this.reconnectAttempts = 0;
                this.setupHeartbeat();
            };
            
            this.ws.onmessage = (event) => {
                this.handleMessage(event.data);
            };
            
            this.ws.onclose = (event) => {
                console.log('WebSocket连接已关闭');
                this.handleReconnect();
            };
            
            this.ws.onerror = (error) => {
                console.error('WebSocket错误:', error);
            };
            
        } catch (error) {
            console.error('WebSocket连接失败:', error);
            this.handleReconnect();
        }
    }
    
    handleMessage(data) {
        try {
            const message = JSON.parse(data);
            const type = message.type;
            
            // 调用注册的消息处理器
            if (this.messageHandlers.has(type)) {
                this.messageHandlers.get(type)(message);
            }
            
            // 触发自定义事件
            this.dispatchEvent(new CustomEvent(type, { detail: message }));
            
        } catch (error) {
            console.error('处理WebSocket消息失败:', error);
        }
    }
    
    handleReconnect() {
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
            this.reconnectAttempts++;
            console.log(`尝试重连... (${this.reconnectAttempts}/${this.maxReconnectAttempts})`);
            
            setTimeout(() => {
                this.connect();
            }, this.reconnectInterval);
        } else {
            console.error('WebSocket重连失败，已达到最大重连次数');
        }
    }
    
    setupHeartbeat() {
        // 定期发送ping消息
        setInterval(() => {
            if (this.ws && this.ws.readyState === WebSocket.OPEN) {
                this.send({
                    type: 'ping',
                    timestamp: new Date().toISOString()
                });
            }
        }, 30000); // 每30秒发送一次ping
    }
    
    send(data) {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify(data));
        } else {
            console.warn('WebSocket未连接，无法发送消息');
        }
    }
    
    subscribe(type) {
        this.subscriptions.add(type);
        this.send({
            type: 'subscribe',
            subscription: type
        });
    }
    
    unsubscribe(type) {
        this.subscriptions.delete(type);
    }
    
    onMessage(type, handler) {
        this.messageHandlers.set(type, handler);
    }
    
    requestUpdate() {
        this.send({
            type: 'request_update',
            timestamp: new Date().toISOString()
        });
    }
    
    disconnect() {
        if (this.ws) {
            this.ws.close();
        }
    }
}

// 全局WebSocket客户端实例
let wsClient = null;

// 初始化WebSocket连接
function initWebSocket() {
    if (!wsClient) {
        wsClient = new WebSocketClient();
        
        // 注册消息处理器
        wsClient.onMessage('system_status', (message) => {
            updateSystemStatus(message.data);
        });
        
        wsClient.onMessage('wireguard_status', (message) => {
            updateWireGuardStatus(message.data);
        });
        
        wsClient.onMessage('clients_status', (message) => {
            updateClientsStatus(message.data);
        });
        
        wsClient.onMessage('system_update', (message) => {
            updateSystemStatus(message.data);
        });
        
        // 订阅所有更新
        wsClient.subscribe('all');
    }
}

// 更新系统状态显示
function updateSystemStatus(data) {
    if (data.error) {
        console.error('系统状态更新失败:', data.error);
        return;
    }
    
    // 更新CPU使用率
    const cpuElement = document.getElementById('cpu-usage');
    if (cpuElement) {
        cpuElement.textContent = `${data.cpu_usage.toFixed(1)}%`;
        cpuElement.style.color = data.cpu_usage > 80 ? '#dc3545' : '#28a745';
    }
    
    // 更新内存使用率
    const memoryElement = document.getElementById('memory-usage');
    if (memoryElement) {
        memoryElement.textContent = `${data.memory_usage.toFixed(1)}%`;
        memoryElement.style.color = data.memory_usage > 80 ? '#dc3545' : '#28a745';
    }
    
    // 更新磁盘使用率
    const diskElement = document.getElementById('disk-usage');
    if (diskElement) {
        diskElement.textContent = `${data.disk_usage}%`;
        diskElement.style.color = data.disk_usage > 85 ? '#dc3545' : '#28a745';
    }
    
    // 更新系统运行时间
    const uptimeElement = document.getElementById('system-uptime');
    if (uptimeElement) {
        uptimeElement.textContent = data.uptime || '未知';
    }
}

// 更新WireGuard状态显示
function updateWireGuardStatus(data) {
    const statusElement = document.getElementById('wireguard-status');
    if (statusElement) {
        statusElement.textContent = data.status === 'running' ? '运行中' : '已停止';
        statusElement.className = `status-indicator status-${data.status}`;
    }
}

// 更新客户端状态显示
function updateClientsStatus(data) {
    const onlineElement = document.getElementById('online-clients');
    if (onlineElement) {
        onlineElement.textContent = data.online || 0;
    }
    
    const totalElement = document.getElementById('total-clients');
    if (totalElement) {
        totalElement.textContent = data.total || 0;
    }
}

// 页面加载完成后初始化WebSocket
document.addEventListener('DOMContentLoaded', function() {
    initWebSocket();
});

// 页面卸载时断开WebSocket连接
window.addEventListener('beforeunload', function() {
    if (wsClient) {
        wsClient.disconnect();
    }
});
EOF
}

# 创建WebSocket服务
create_websocket_service() {
    cat > "/etc/systemd/system/ipv6-wireguard-websocket.service" << EOF
[Unit]
Description=IPv6 WireGuard Manager WebSocket Server
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=${WEB_API_DIR}
ExecStart=/usr/bin/python3 ${WEB_API_DIR}/websocket_server.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
}

# WebSocket管理菜单
websocket_realtime_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== WebSocket实时通信管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 启动WebSocket服务"
        echo -e "${GREEN}2.${NC} 停止WebSocket服务"
        echo -e "${GREEN}3.${NC} 重启WebSocket服务"
        echo -e "${GREEN}4.${NC} 查看WebSocket状态"
        echo -e "${GREEN}5.${NC} 查看WebSocket日志"
        echo -e "${GREEN}6.${NC} 测试WebSocket连接"
        echo -e "${GREEN}7.${NC} WebSocket设置"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -p "请选择操作 [0-7]: " choice
        
        case $choice in
            1) start_websocket_service ;;
            2) stop_websocket_service ;;
            3) restart_websocket_service ;;
            4) show_websocket_status ;;
            5) show_websocket_logs ;;
            6) test_websocket_connection ;;
            7) websocket_settings ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 启动WebSocket服务
start_websocket_service() {
    log_info "启动WebSocket服务..."
    
    systemctl daemon-reload
    systemctl enable ipv6-wireguard-websocket.service
    systemctl start ipv6-wireguard-websocket.service
    
    if systemctl is-active --quiet ipv6-wireguard-websocket.service; then
        show_success "WebSocket服务已启动"
    else
        show_error "WebSocket服务启动失败"
    fi
}

# 停止WebSocket服务
stop_websocket_service() {
    log_info "停止WebSocket服务..."
    
    systemctl stop ipv6-wireguard-websocket.service
    
    if ! systemctl is-active --quiet ipv6-wireguard-websocket.service; then
        show_success "WebSocket服务已停止"
    else
        show_error "WebSocket服务停止失败"
    fi
}

# 重启WebSocket服务
restart_websocket_service() {
    log_info "重启WebSocket服务..."
    
    systemctl restart ipv6-wireguard-websocket.service
    
    if systemctl is-active --quiet ipv6-wireguard-websocket.service; then
        show_success "WebSocket服务已重启"
    else
        show_error "WebSocket服务重启失败"
    fi
}

# 查看WebSocket状态
show_websocket_status() {
    echo -e "${SECONDARY_COLOR}=== WebSocket服务状态 ===${NC}"
    echo
    
    systemctl status ipv6-wireguard-websocket.service --no-pager
}

# 查看WebSocket日志
show_websocket_logs() {
    echo -e "${SECONDARY_COLOR}=== WebSocket服务日志 ===${NC}"
    echo
    
    journalctl -u ipv6-wireguard-websocket.service -n 50 --no-pager
}

# 测试WebSocket连接
test_websocket_connection() {
    echo -e "${SECONDARY_COLOR}=== WebSocket连接测试 ===${NC}"
    echo
    
    if command -v wscat &> /dev/null; then
        echo "使用wscat测试WebSocket连接..."
        wscat -c ws://localhost:3001
    else
        echo "wscat未安装，使用curl测试..."
        curl -i -N -H "Connection: Upgrade" \
             -H "Upgrade: websocket" \
             -H "Sec-WebSocket-Version: 13" \
             -H "Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==" \
             http://localhost:3001
    fi
}

# WebSocket设置
websocket_settings() {
    echo -e "${SECONDARY_COLOR}=== WebSocket设置 ===${NC}"
    echo
    
    local port=$(show_input "WebSocket端口" "3001")
    local host=$(show_input "绑定主机" "localhost")
    local max_clients=$(show_input "最大客户端数" "100")
    local heartbeat_interval=$(show_input "心跳间隔(秒)" "30")
    
    # 更新WebSocket服务器配置
    sed -i "s/port=3001/port=$port/g" "${WEB_API_DIR}/websocket_server.py"
    sed -i "s/host='localhost'/host='$host'/g" "${WEB_API_DIR}/websocket_server.py"
    
    show_success "WebSocket设置已保存"
}

# 导出函数
export -f init_websocket_realtime create_websocket_server create_websocket_client
export -f create_websocket_service websocket_realtime_menu start_websocket_service
export -f stop_websocket_service restart_websocket_service show_websocket_status
export -f show_websocket_logs test_websocket_connection websocket_settings
