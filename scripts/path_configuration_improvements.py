#!/bin/bash
"""
路径配置化改进实现
解决硬编码路径问题，实现动态路径配置
"""

# 路径配置管理
class PathConfig:
    """路径配置管理类"""
    
    def __init__(self):
        self.config = {
            # 系统目录路径 - 支持环境变量覆盖
            'INSTALL_DIR': os.getenv('INSTALL_DIR', '/opt/ipv6-wireguard-manager'),
            'FRONTEND_DIR': os.getenv('FRONTEND_DIR', '/var/www/html'),
            'WIREGUARD_CONFIG_DIR': os.getenv('WIREGUARD_CONFIG_DIR', '/etc/wireguard'),
            'NGINX_LOG_DIR': os.getenv('NGINX_LOG_DIR', '/var/log/nginx'),
            'NGINX_CONFIG_DIR': os.getenv('NGINX_CONFIG_DIR', '/etc/nginx/sites-available'),
            'BIN_DIR': os.getenv('BIN_DIR', '/usr/local/bin'),
            
            # API端点配置
            'API_BASE_URL': os.getenv('API_BASE_URL', 'http://localhost:8000/api/v1'),
            'WEBSOCKET_URL': os.getenv('WEBSOCKET_URL', 'ws://localhost:8000/ws/'),
            
            # 数据库配置
            'DATABASE_URL': os.getenv('DATABASE_URL', 'mysql://ipv6wgm:password@localhost:3306/ipv6wgm'),
            
            # 服务端口配置
            'BACKEND_PORT': int(os.getenv('BACKEND_PORT', '8000')),
            'FRONTEND_PORT': int(os.getenv('FRONTEND_PORT', '80')),
            'NGINX_PORT': int(os.getenv('NGINX_PORT', '80')),
            
            # 安全配置
            'DEFAULT_USERNAME': os.getenv('DEFAULT_USERNAME', 'admin'),
            'DEFAULT_PASSWORD': os.getenv('DEFAULT_PASSWORD', 'admin123'),
            'SESSION_TIMEOUT': int(os.getenv('SESSION_TIMEOUT', '1440')),
        }
    
    def get_path(self, key: str) -> str:
        """获取配置路径"""
        return self.config.get(key, '')
    
    def validate_paths(self) -> bool:
        """验证路径配置的有效性"""
        required_paths = ['INSTALL_DIR', 'FRONTEND_DIR', 'WIREGUARD_CONFIG_DIR']
        
        for path_key in required_paths:
            path = self.get_path(path_key)
            if not path or not os.path.exists(os.path.dirname(path)):
                print(f"错误: 路径配置无效 - {path_key}: {path}")
                return False
        
        return True
    
    def auto_detect_paths(self) -> dict:
        """自动检测系统路径"""
        detected_paths = {}
        
        # 检测安装目录
        if os.path.exists('/opt'):
            detected_paths['INSTALL_DIR'] = '/opt/ipv6-wireguard-manager'
        elif os.path.exists('/usr/local'):
            detected_paths['INSTALL_DIR'] = '/usr/local/ipv6-wireguard-manager'
        else:
            detected_paths['INSTALL_DIR'] = os.path.expanduser('~/ipv6-wireguard-manager')
        
        # 检测Web目录
        if os.path.exists('/var/www/html'):
            detected_paths['FRONTEND_DIR'] = '/var/www/html'
        elif os.path.exists('/usr/share/nginx/html'):
            detected_paths['FRONTEND_DIR'] = '/usr/share/nginx/html'
        else:
            detected_paths['FRONTEND_DIR'] = os.path.join(detected_paths['INSTALL_DIR'], 'web')
        
        return detected_paths

# 路径配置化改进实现
def implement_path_configuration():
    """实现路径配置化改进"""
    
    # 1. 创建路径配置文件
    path_config_content = '''# IPv6 WireGuard Manager 路径配置
# 支持环境变量覆盖

# 系统目录路径
INSTALL_DIR=${INSTALL_DIR:-/opt/ipv6-wireguard-manager}
FRONTEND_DIR=${FRONTEND_DIR:-/var/www/html}
WIREGUARD_CONFIG_DIR=${WIREGUARD_CONFIG_DIR:-/etc/wireguard}
NGINX_LOG_DIR=${NGINX_LOG_DIR:-/var/log/nginx}
NGINX_CONFIG_DIR=${NGINX_CONFIG_DIR:-/etc/nginx/sites-available}
BIN_DIR=${BIN_DIR:-/usr/local/bin}

# API端点配置
API_BASE_URL=${API_BASE_URL:-http://localhost:8000/api/v1}
WEBSOCKET_URL=${WEBSOCKET_URL:-ws://localhost:8000/ws/}

# 数据库配置
DATABASE_URL=${DATABASE_URL:-mysql://ipv6wgm:password@localhost:3306/ipv6wgm}

# 服务端口配置
BACKEND_PORT=${BACKEND_PORT:-8000}
FRONTEND_PORT=${FRONTEND_PORT:-80}
NGINX_PORT=${NGINX_PORT:-80}

# 安全配置
DEFAULT_USERNAME=${DEFAULT_USERNAME:-admin}
DEFAULT_PASSWORD=${DEFAULT_PASSWORD:-admin123}
SESSION_TIMEOUT=${SESSION_TIMEOUT:-1440}
'''
    
    # 2. 创建路径检测脚本
    path_detection_script = '''#!/bin/bash
# 路径自动检测脚本

detect_system_paths() {
    echo "检测系统路径..."
    
    # 检测安装目录
    if [[ -d "/opt" ]]; then
        INSTALL_DIR="/opt/ipv6-wireguard-manager"
    elif [[ -d "/usr/local" ]]; then
        INSTALL_DIR="/usr/local/ipv6-wireguard-manager"
    else
        INSTALL_DIR="$HOME/ipv6-wireguard-manager"
    fi
    
    # 检测Web目录
    if [[ -d "/var/www/html" ]]; then
        FRONTEND_DIR="/var/www/html"
    elif [[ -d "/usr/share/nginx/html" ]]; then
        FRONTEND_DIR="/usr/share/nginx/html"
    else
        FRONTEND_DIR="$INSTALL_DIR/web"
    fi
    
    # 检测WireGuard配置目录
    if [[ -d "/etc/wireguard" ]]; then
        WIREGUARD_CONFIG_DIR="/etc/wireguard"
    else
        WIREGUARD_CONFIG_DIR="$INSTALL_DIR/config/wireguard"
    fi
    
    echo "检测到的路径:"
    echo "  安装目录: $INSTALL_DIR"
    echo "  前端目录: $FRONTEND_DIR"
    echo "  WireGuard配置目录: $WIREGUARD_CONFIG_DIR"
}

# 导出检测到的路径
export INSTALL_DIR FRONTEND_DIR WIREGUARD_CONFIG_DIR
'''
    
    return {
        'path_config': path_config_content,
        'detection_script': path_detection_script
    }

# API端点动态化改进
def implement_dynamic_api_endpoints():
    """实现API端点动态化"""
    
    # 1. API端点自动发现
    api_discovery_script = '''#!/bin/bash
# API端点自动发现脚本

discover_api_endpoints() {
    local backend_host=${BACKEND_HOST:-localhost}
    local backend_port=${BACKEND_PORT:-8000}
    
    echo "发现API端点..."
    
    # 检查后端服务是否运行
    if curl -f "http://$backend_host:$backend_port/api/v1/health" >/dev/null 2>&1; then
        echo "✓ 后端API服务正常运行"
        export API_BASE_URL="http://$backend_host:$backend_port/api/v1"
        export WEBSOCKET_URL="ws://$backend_host:$backend_port/ws/"
    else
        echo "✗ 后端API服务不可用"
        return 1
    fi
    
    # 检查API端点
    local endpoints=(
        "/api/v1/auth/login"
        "/api/v1/users"
        "/api/v1/wireguard/servers"
        "/api/v1/bgp/sessions"
        "/api/v1/ipv6/pools"
    )
    
    for endpoint in "${endpoints[@]}"; do
        if curl -f "http://$backend_host:$backend_port$endpoint" >/dev/null 2>&1; then
            echo "✓ $endpoint 可用"
        else
            echo "✗ $endpoint 不可用"
        fi
    done
}
'''
    
    # 2. 多环境配置支持
    multi_env_config = '''# 多环境配置支持
# 开发环境
if [[ "$ENVIRONMENT" == "development" ]]; then
    export API_BASE_URL="http://localhost:8000/api/v1"
    export DATABASE_URL="mysql://dev:dev@localhost:3306/ipv6wgm_dev"
    export DEBUG=true
fi

# 测试环境
if [[ "$ENVIRONMENT" == "testing" ]]; then
    export API_BASE_URL="http://test-api.example.com/api/v1"
    export DATABASE_URL="mysql://test:test@test-db:3306/ipv6wgm_test"
    export DEBUG=false
fi

# 生产环境
if [[ "$ENVIRONMENT" == "production" ]]; then
    export API_BASE_URL="https://api.example.com/api/v1"
    export DATABASE_URL="mysql://prod:secure_password@prod-db:3306/ipv6wgm"
    export DEBUG=false
fi
'''
    
    return {
        'discovery_script': api_discovery_script,
        'multi_env_config': multi_env_config
    }

# 安全参数配置化改进
def implement_security_configuration():
    """实现安全参数配置化"""
    
    # 1. 强制修改默认凭据
    security_setup_script = '''#!/bin/bash
# 安全配置设置脚本

setup_security_config() {
    echo "设置安全配置..."
    
    # 检查是否首次部署
    if [[ ! -f "$INSTALL_DIR/.security_configured" ]]; then
        echo "首次部署检测到，需要设置安全参数"
        
        # 强制修改默认密码
        read -s -p "请输入新的管理员密码: " new_password
        echo
        read -s -p "请确认密码: " confirm_password
        echo
        
        if [[ "$new_password" != "$confirm_password" ]]; then
            echo "密码不匹配，请重新设置"
            return 1
        fi
        
        # 生成随机密钥
        secret_key=$(openssl rand -hex 32)
        
        # 更新配置文件
        cat > "$INSTALL_DIR/.env" << EOF
# 安全配置
SECRET_KEY="$secret_key"
FIRST_SUPERUSER_PASSWORD="$new_password"
DEFAULT_PASSWORD="$new_password"

# 其他配置...
EOF
        
        # 标记已配置
        touch "$INSTALL_DIR/.security_configured"
        echo "✓ 安全配置完成"
    else
        echo "✓ 安全配置已存在"
    fi
}
'''
    
    # 2. 密钥管理系统
    key_management_script = '''#!/bin/bash
# 密钥管理系统

manage_secrets() {
    local action=$1
    local key_name=$2
    local key_value=$3
    
    case $action in
        "set")
            # 加密存储密钥
            encrypted_value=$(echo "$key_value" | openssl enc -aes-256-cbc -base64 -pass pass:"$SECRET_KEY")
            echo "$encrypted_value" > "$INSTALL_DIR/secrets/$key_name.enc"
            echo "✓ 密钥 $key_name 已加密存储"
            ;;
        "get")
            # 解密获取密钥
            if [[ -f "$INSTALL_DIR/secrets/$key_name.enc" ]]; then
                decrypted_value=$(cat "$INSTALL_DIR/secrets/$key_name.enc" | openssl enc -aes-256-cbc -base64 -d -pass pass:"$SECRET_KEY")
                echo "$decrypted_value"
            else
                echo "密钥 $key_name 不存在"
                return 1
            fi
            ;;
        "list")
            # 列出所有密钥
            ls -la "$INSTALL_DIR/secrets/"*.enc 2>/dev/null | while read line; do
                echo "$line" | awk '{print $9}' | sed 's/.*\///' | sed 's/\.enc$//'
            done
            ;;
    esac
}
'''
    
    return {
        'security_setup': security_setup_script,
        'key_management': key_management_script
    }

if __name__ == "__main__":
    # 实现路径配置化改进
    path_improvements = implement_path_configuration()
    api_improvements = implement_dynamic_api_endpoints()
    security_improvements = implement_security_configuration()
    
    print("路径配置化改进实现完成")
    print("包含:")
    print("- 路径配置文件")
    print("- 路径检测脚本")
    print("- API端点自动发现")
    print("- 多环境配置支持")
    print("- 安全参数配置化")
    print("- 密钥管理系统")
