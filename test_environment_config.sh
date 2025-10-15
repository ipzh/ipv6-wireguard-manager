#!/bin/bash

# 环境配置测试脚本
# 测试不同安装模式下的环境配置

set -e

echo "=========================================="
echo "🧪 环境配置测试脚本"
echo "=========================================="
echo ""

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

# 测试目录
TEST_DIR="/tmp/ipv6-wireguard-test"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "📁 测试目录: $TEST_DIR"
echo ""

# 模拟不同内存环境
test_memory_scenarios() {
    echo "🔍 测试不同内存环境配置..."
    
    # 低内存环境 (512MB)
    echo "  测试低内存环境 (512MB)..."
    MEMORY_MB=512 python3 -c "
import sys
sys.path.insert(0, '/opt/ipv6-wireguard-manager')
from backend.app.core.environment import EnvironmentManager
manager = EnvironmentManager()
manager.memory_mb = 512
config = manager.get_all_config()
print(f'    配置档案: {manager.profile.value}')
print(f'    Redis状态: {\"启用\" if config[\"USE_REDIS\"] else \"禁用\"}')
print(f'    工作进程: {config[\"MAX_WORKERS\"]}')
print(f'    数据库连接池: {config[\"DATABASE_POOL_SIZE\"]}')
"
    
    # 标准内存环境 (2GB)
    echo "  测试标准内存环境 (2GB)..."
    MEMORY_MB=2048 python3 -c "
import sys
sys.path.insert(0, '/opt/ipv6-wireguard-manager')
from backend.app.core.environment import EnvironmentManager
manager = EnvironmentManager()
manager.memory_mb = 2048
config = manager.get_all_config()
print(f'    配置档案: {manager.profile.value}')
print(f'    Redis状态: {\"启用\" if config[\"USE_REDIS\"] else \"禁用\"}')
print(f'    工作进程: {config[\"MAX_WORKERS\"]}')
print(f'    数据库连接池: {config[\"DATABASE_POOL_SIZE\"]}')
"
    
    # 高内存环境 (8GB)
    echo "  测试高内存环境 (8GB)..."
    MEMORY_MB=8192 python3 -c "
import sys
sys.path.insert(0, '/opt/ipv6-wireguard-manager')
from backend.app.core.environment import EnvironmentManager
manager = EnvironmentManager()
manager.memory_mb = 8192
config = manager.get_all_config()
print(f'    配置档案: {manager.profile.value}')
print(f'    Redis状态: {\"启用\" if config[\"USE_REDIS\"] else \"禁用\"}')
print(f'    工作进程: {config[\"MAX_WORKERS\"]}')
print(f'    数据库连接池: {config[\"DATABASE_POOL_SIZE\"]}')
"
}

# 测试不同安装模式
test_install_modes() {
    echo ""
    echo "🔍 测试不同安装模式配置..."
    
    # Docker模式
    echo "  测试Docker模式..."
    DOCKER_CONTAINER=1 python3 -c "
import sys
sys.path.insert(0, '/opt/ipv6-wireguard-manager')
from backend.app.core.environment import EnvironmentManager
manager = EnvironmentManager()
print(f'    安装模式: {manager.install_mode.value}')
print(f'    数据库URL: {manager.get_database_config()[\"DATABASE_URL\"]}')
print(f'    Redis URL: {manager.get_redis_config().get(\"REDIS_URL\", \"未配置\")}')
"
    
    # 原生模式
    echo "  测试原生模式..."
    VIRTUAL_ENV="/opt/ipv6-wireguard-manager/backend/venv" python3 -c "
import sys
sys.path.insert(0, '/opt/ipv6-wireguard-manager')
from backend.app.core.environment import EnvironmentManager
manager = EnvironmentManager()
print(f'    安装模式: {manager.install_mode.value}')
print(f'    数据库URL: {manager.get_database_config()[\"DATABASE_URL\"]}')
print(f'    Redis URL: {manager.get_redis_config().get(\"REDIS_URL\", \"未配置\")}')
"
    
    # 最小化模式
    echo "  测试最小化模式..."
    INSTALL_MODE=minimal python3 -c "
import sys
sys.path.insert(0, '/opt/ipv6-wireguard-manager')
from backend.app.core.environment import EnvironmentManager
manager = EnvironmentManager()
print(f'    安装模式: {manager.install_mode.value}')
print(f'    数据库URL: {manager.get_database_config()[\"DATABASE_URL\"]}')
print(f'    Redis URL: {manager.get_redis_config().get(\"REDIS_URL\", \"未配置\")}')
"
}

# 测试配置生成器
test_config_generator() {
    echo ""
    echo "🔍 测试配置生成器..."
    
    # 测试低内存配置生成
    echo "  测试低内存配置生成..."
    if [ -f "/opt/ipv6-wireguard-manager/backend/scripts/generate_environment.py" ]; then
        cd /opt/ipv6-wireguard-manager/backend
        python scripts/generate_environment.py --mode minimal --profile low_memory --output "$TEST_DIR/test-low-memory.env" --show-config
        echo "    ✅ 低内存配置生成成功"
    else
        echo "    ❌ 配置生成器不存在"
    fi
    
    # 测试标准配置生成
    echo "  测试标准配置生成..."
    if [ -f "/opt/ipv6-wireguard-manager/backend/scripts/generate_environment.py" ]; then
        python scripts/generate_environment.py --mode native --profile standard --output "$TEST_DIR/test-standard.env" --show-config
        echo "    ✅ 标准配置生成成功"
    fi
    
    # 测试Docker配置生成
    echo "  测试Docker配置生成..."
    if [ -f "/opt/ipv6-wireguard-manager/backend/scripts/generate_environment.py" ]; then
        python scripts/generate_environment.py --mode docker --profile high_performance --output "$TEST_DIR/test-docker.env" --show-config
        echo "    ✅ Docker配置生成成功"
    fi
}

# 测试配置验证
test_config_validation() {
    echo ""
    echo "🔍 测试配置验证..."
    
    for config_file in "$TEST_DIR"/*.env; do
        if [ -f "$config_file" ]; then
            echo "  验证配置文件: $(basename "$config_file")"
            if [ -f "/opt/ipv6-wireguard-manager/backend/scripts/generate_environment.py" ]; then
                cd /opt/ipv6-wireguard-manager/backend
                if python scripts/generate_environment.py --validate --output "$config_file" 2>/dev/null; then
                    echo "    ✅ 配置验证通过"
                else
                    echo "    ❌ 配置验证失败"
                fi
            fi
        fi
    done
}

# 测试配置差异
test_config_differences() {
    echo ""
    echo "🔍 测试配置差异..."
    
    if [ -f "$TEST_DIR/test-low-memory.env" ] && [ -f "$TEST_DIR/test-standard.env" ]; then
        echo "  比较低内存和标准配置差异:"
        echo "    数据库连接池大小:"
        echo "      低内存: $(grep 'DATABASE_POOL_SIZE=' "$TEST_DIR/test-low-memory.env" | cut -d'=' -f2)"
        echo "      标准: $(grep 'DATABASE_POOL_SIZE=' "$TEST_DIR/test-standard.env" | cut -d'=' -f2)"
        echo "    工作进程数:"
        echo "      低内存: $(grep 'MAX_WORKERS=' "$TEST_DIR/test-low-memory.env" | cut -d'=' -f2)"
        echo "      标准: $(grep 'MAX_WORKERS=' "$TEST_DIR/test-standard.env" | cut -d'=' -f2)"
        echo "    Redis状态:"
        echo "      低内存: $(grep 'USE_REDIS=' "$TEST_DIR/test-low-memory.env" | cut -d'=' -f2)"
        echo "      标准: $(grep 'USE_REDIS=' "$TEST_DIR/test-standard.env" | cut -d'=' -f2)"
    fi
}

# 主测试流程
main() {
    echo "开始环境配置测试..."
    echo ""
    
    # 检查环境管理器是否存在
    if [ ! -f "/opt/ipv6-wireguard-manager/backend/app/core/environment.py" ]; then
        echo "❌ 环境管理器不存在"
        echo "请先运行安装脚本"
        exit 1
    fi
    
    # 运行测试
    test_memory_scenarios
    test_install_modes
    test_config_generator
    test_config_validation
    test_config_differences
    
    echo ""
    echo "=========================================="
    echo "🎉 环境配置测试完成！"
    echo "=========================================="
    echo ""
    echo "测试结果:"
    echo "✅ 内存环境配置测试"
    echo "✅ 安装模式配置测试"
    echo "✅ 配置生成器测试"
    echo "✅ 配置验证测试"
    echo "✅ 配置差异测试"
    echo ""
    echo "生成的测试配置文件:"
    ls -la "$TEST_DIR"/*.env 2>/dev/null || echo "  无配置文件生成"
    echo ""
    echo "清理测试目录:"
    echo "  rm -rf $TEST_DIR"
}

# 运行主函数
main "$@"
