#!/bin/bash
# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"

# 确保日志相关变量已定义
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
fi

# 网络拓扑图模块
# 实现网络拓扑可视化功能

# 网络拓扑配置
NETWORK_TOPOLOGY_DIR="${WEB_INTERFACE_DIR}/topology"
TOPOLOGY_DATA_FILE="${NETWORK_TOPOLOGY_DIR}/topology.json"
TOPOLOGY_JS_FILE="${WEB_STATIC_DIR}/js/network-topology.js"

# 初始化网络拓扑模块
init_network_topology() {
    log_info "初始化网络拓扑模块..."
    
    # 创建目录
    mkdir -p "$NETWORK_TOPOLOGY_DIR"
    
    # 创建网络拓扑JavaScript文件
    create_network_topology_js
    
    # 创建网络拓扑API
    create_network_topology_api
    
    # 创建默认拓扑数据
    create_default_topology_data
    
    log_info "网络拓扑模块初始化完成"
}

# 创建网络拓扑JavaScript
create_network_topology_js() {
    cat > "$TOPOLOGY_JS_FILE" << 'EOF'
// 网络拓扑图实现
class NetworkTopology {
    constructor(canvasId) {
        this.canvas = document.getElementById(canvasId);
        this.ctx = this.canvas.getContext('2d');
        this.nodes = [];
        this.connections = [];
        this.selectedNode = null;
        this.dragging = false;
        this.dragOffset = { x: 0, y: 0 };
        
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.loadNetworkData();
        this.startAnimation();
    }
    
    setupEventListeners() {
        this.canvas.addEventListener('mousedown', this.onMouseDown.bind(this));
        this.canvas.addEventListener('mousemove', this.onMouseMove.bind(this));
        this.canvas.addEventListener('mouseup', this.onMouseUp.bind(this));
    }
    
    loadNetworkData() {
        fetch('/api/network/topology')
            .then(response => response.json())
            .then(data => {
                this.nodes = data.nodes || [];
                this.connections = data.connections || [];
                this.render();
            })
            .catch(error => {
                console.error('加载网络拓扑数据失败:', error);
                this.loadDefaultData();
            });
    }
    
    loadDefaultData() {
        this.nodes = [
            { id: 'server', name: 'VPN服务器', type: 'server', x: 200, y: 150, status: 'online' },
            { id: 'client1', name: '客户端1', type: 'client', x: 100, y: 100, status: 'online' },
            { id: 'client2', name: '客户端2', type: 'client', x: 300, y: 100, status: 'online' },
            { id: 'client3', name: '客户端3', type: 'client', x: 100, y: 200, status: 'offline' },
            { id: 'client4', name: '客户端4', type: 'client', x: 300, y: 200, status: 'online' }
        ];
        
        this.connections = [
            { from: 'server', to: 'client1', type: 'wireguard', status: 'active' },
            { from: 'server', to: 'client2', type: 'wireguard', status: 'active' },
            { from: 'server', to: 'client3', type: 'wireguard', status: 'inactive' },
            { from: 'server', to: 'client4', type: 'wireguard', status: 'active' }
        ];
        
        this.render();
    }
    
    render() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        this.drawConnections();
        this.drawNodes();
        this.drawLabels();
    }
    
    drawConnections() {
        this.connections.forEach(conn => {
            const fromNode = this.nodes.find(n => n.id === conn.from);
            const toNode = this.nodes.find(n => n.id === conn.to);
            
            if (fromNode && toNode) {
                this.ctx.strokeStyle = conn.status === 'active' ? '#28a745' : '#dc3545';
                this.ctx.lineWidth = 2;
                this.ctx.setLineDash(conn.status === 'active' ? [] : [5, 5]);
                
                this.ctx.beginPath();
                this.ctx.moveTo(fromNode.x, fromNode.y);
                this.ctx.lineTo(toNode.x, toNode.y);
                this.ctx.stroke();
            }
        });
    }
    
    drawNodes() {
        this.nodes.forEach(node => {
            this.ctx.fillStyle = this.getNodeColor(node);
            this.ctx.beginPath();
            this.ctx.arc(node.x, node.y, 20, 0, 2 * Math.PI);
            this.ctx.fill();
            
            this.ctx.strokeStyle = node === this.selectedNode ? '#007bff' : '#000000';
            this.ctx.lineWidth = node === this.selectedNode ? 3 : 1;
            this.ctx.stroke();
            
            // 状态指示器
            this.ctx.fillStyle = node.status === 'online' ? '#28a745' : '#dc3545';
            this.ctx.beginPath();
            this.ctx.arc(node.x + 15, node.y - 15, 5, 0, 2 * Math.PI);
            this.ctx.fill();
        });
    }
    
    drawLabels() {
        this.nodes.forEach(node => {
            this.ctx.fillStyle = '#000000';
            this.ctx.font = '12px Arial';
            this.ctx.textAlign = 'center';
            this.ctx.fillText(node.name, node.x, node.y + 35);
        });
    }
    
    getNodeColor(node) {
        switch (node.type) {
            case 'server': return '#007bff';
            case 'client': return node.status === 'online' ? '#28a745' : '#6c757d';
            default: return '#6c757d';
        }
    }
    
    onMouseDown(event) {
        const rect = this.canvas.getBoundingClientRect();
        const x = event.clientX - rect.left;
        const y = event.clientY - rect.top;
        
        this.selectedNode = this.nodes.find(node => {
            const distance = Math.sqrt((x - node.x) ** 2 + (y - node.y) ** 2);
            return distance <= 20;
        });
        
        if (this.selectedNode) {
            this.dragging = true;
            this.dragOffset.x = x - this.selectedNode.x;
            this.dragOffset.y = y - this.selectedNode.y;
        }
    }
    
    onMouseMove(event) {
        if (this.dragging && this.selectedNode) {
            const rect = this.canvas.getBoundingClientRect();
            const x = event.clientX - rect.left;
            const y = event.clientY - rect.top;
            
            this.selectedNode.x = x - this.dragOffset.x;
            this.selectedNode.y = y - this.dragOffset.y;
            this.render();
        }
    }
    
    onMouseUp(event) {
        this.dragging = false;
        this.selectedNode = null;
    }
    
    startAnimation() {
        setInterval(() => {
            this.loadNetworkData();
        }, 30000);
    }
}

// 初始化网络拓扑图
document.addEventListener('DOMContentLoaded', function() {
    if (document.getElementById('topology-canvas')) {
        new NetworkTopology('topology-canvas');
    }
});
EOF
}

# 创建网络拓扑API
create_network_topology_api() {
    cat > "${WEB_API_DIR}/network_topology.py" << 'EOF'
#!/usr/bin/env python3
# 网络拓扑API接口

import json
import sqlite3
import subprocess
import os

class NetworkTopologyAPI:
    def __init__(self, db_path, config_dir):
        self.db_path = db_path
        self.config_dir = config_dir
    
    def get_topology_data(self):
        """获取网络拓扑数据"""
        try:
            # 获取服务器信息
            server_info = self.get_server_info()
            
            # 获取客户端信息
            clients_info = self.get_clients_info()
            
            # 获取连接信息
            connections_info = self.get_connections_info()
            
            return {
                'nodes': [server_info] + clients_info,
                'connections': connections_info
            }
        except Exception as e:
            return {'error': str(e)}
    
    def get_server_info(self):
        """获取服务器信息"""
        return {
            'id': 'server',
            'name': 'VPN服务器',
            'type': 'server',
            'x': 200,
            'y': 150,
            'status': 'online',
            'ip': self.get_server_ip(),
            'uptime': self.get_server_uptime()
        }
    
    def get_clients_info(self):
        """获取客户端信息"""
        clients = []
        
        # 从WireGuard获取客户端信息
        try:
            result = subprocess.run(['wg', 'show'], capture_output=True, text=True)
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                client_id = 1
                for line in lines:
                    if 'peer:' in line:
                        peer_key = line.split(':')[1].strip()
                        status = 'online' if 'latest handshake:' in result.stdout else 'offline'
                        
                        clients.append({
                            'id': f'client{client_id}',
                            'name': f'客户端{client_id}',
                            'type': 'client',
                            'x': 100 + (client_id % 2) * 200,
                            'y': 100 + ((client_id - 1) // 2) * 100,
                            'status': status,
                            'peer_key': peer_key[:8] + '...'
                        })
                        client_id += 1
        except:
            pass
        
        return clients
    
    def get_connections_info(self):
        """获取连接信息"""
        connections = []
        
        # 从WireGuard获取连接信息
        try:
            result = subprocess.run(['wg', 'show'], capture_output=True, text=True)
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                client_id = 1
                for line in lines:
                    if 'peer:' in line:
                        status = 'active' if 'latest handshake:' in result.stdout else 'inactive'
                        connections.append({
                            'from': 'server',
                            'to': f'client{client_id}',
                            'type': 'wireguard',
                            'status': status
                        })
                        client_id += 1
        except:
            pass
        
        return connections
    
    def get_server_ip(self):
        """获取服务器IP地址"""
        try:
            result = subprocess.run(['hostname', '-I'], capture_output=True, text=True)
            return result.stdout.strip().split()[0]
        except:
            return '127.0.0.1'
    
    def get_server_uptime(self):
        """获取服务器运行时间"""
        try:
            result = subprocess.run(['uptime', '-p'], capture_output=True, text=True)
            return result.stdout.strip()
        except:
            return 'Unknown'
EOF
}

# 创建默认拓扑数据
create_default_topology_data() {
    cat > "$TOPOLOGY_DATA_FILE" << 'EOF'
{
    "nodes": [
        {
            "id": "server",
            "name": "VPN服务器",
            "type": "server",
            "x": 200,
            "y": 150,
            "status": "online",
            "ip": "192.168.1.1",
            "uptime": "2 days"
        }
    ],
    "connections": []
}
EOF
}

# 网络拓扑菜单
network_topology_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 网络拓扑管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看网络拓扑"
        echo -e "${GREEN}2.${NC} 刷新拓扑数据"
        echo -e "${GREEN}3.${NC} 导出拓扑数据"
        echo -e "${GREEN}4.${NC} 导入拓扑数据"
        echo -e "${GREEN}5.${NC} 拓扑设置"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -p "请选择操作 [0-5]: " choice
        
        case $choice in
            1) view_network_topology ;;
            2) refresh_topology_data ;;
            3) export_topology_data ;;
            4) import_topology_data ;;
            5) topology_settings ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 查看网络拓扑
view_network_topology() {
    echo -e "${SECONDARY_COLOR}=== 网络拓扑 ===${NC}"
    echo
    
    if [[ -f "$TOPOLOGY_DATA_FILE" ]]; then
        cat "$TOPOLOGY_DATA_FILE" | python3 -m json.tool
    else
        show_error "拓扑数据文件不存在"
    fi
}

# 刷新拓扑数据
refresh_topology_data() {
    log_info "刷新网络拓扑数据..."
    
    # 调用API刷新数据
    if command -v python3 &> /dev/null; then
        python3 "${WEB_API_DIR}/network_topology.py" > "$TOPOLOGY_DATA_FILE"
        show_success "拓扑数据已刷新"
    else
        show_error "Python3未安装，无法刷新拓扑数据"
    fi
}

# 导出拓扑数据
export_topology_data() {
    local export_file=$(show_input "导出文件名" "topology_export.json")
    
    if [[ -n "$export_file" ]]; then
        cp "$TOPOLOGY_DATA_FILE" "$export_file"
        show_success "拓扑数据已导出到: $export_file"
    fi
}

# 导入拓扑数据
import_topology_data() {
    local import_file=$(show_input "导入文件路径" "")
    
    if [[ -f "$import_file" ]]; then
        cp "$import_file" "$TOPOLOGY_DATA_FILE"
        show_success "拓扑数据已导入"
    else
        show_error "文件不存在: $import_file"
    fi
}

# 拓扑设置
topology_settings() {
    echo -e "${SECONDARY_COLOR}=== 拓扑设置 ===${NC}"
    echo
    
    local auto_refresh=$(show_selection "自动刷新" "启用" "禁用")
    local refresh_interval=$(show_input "刷新间隔(秒)" "30")
    local show_labels=$(show_selection "显示标签" "是" "否")
    
    # 保存设置
    cat > "${NETWORK_TOPOLOGY_DIR}/settings.json" << EOF
{
    "auto_refresh": "$auto_refresh",
    "refresh_interval": $refresh_interval,
    "show_labels": "$show_labels"
}
EOF
    
    show_success "拓扑设置已保存"
}

# 导出函数
export -f init_network_topology create_network_topology_js create_network_topology_api
export -f create_default_topology_data network_topology_menu view_network_topology
export -f refresh_topology_data export_topology_data import_topology_data topology_settings
