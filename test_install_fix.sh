#!/bin/bash

# 获取传递给脚本的参数
INSTALL_TYPE="${1:-docker}"

# 测试安装脚本的参数解析功能（远程服务器版本）
echo "=== 测试安装脚本参数解析（远程服务器版本） ==="
echo "安装类型参数: $INSTALL_TYPE"

# 下载安装脚本到临时目录
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "下载安装脚本..."
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh -o install.sh
chmod +x install.sh

# 创建一个测试版本的安装脚本，绕过root权限检查
cat > install_test.sh << 'EOF'
#!/bin/bash

# 测试版本的安装脚本，绕过root权限检查

# 重写main函数，跳过root权限检查
test_main() {
    echo "=========================================="
    echo "🚀 IPv6 WireGuard Manager 测试版本"
    echo "=========================================="
    echo ""
    echo "[INFO] 版本: 3.0.0"
    echo "[INFO] 测试模式：跳过root权限检查"
    echo ""
    
    # 解析参数
    local args=$(parse_arguments "$@")
    IFS='|' read -r install_type install_dir port silent performance production debug skip_deps skip_db skip_service <<< "$args"
    
    echo "[INFO] 安装配置:"
    echo "[INFO]   类型: $install_type"
    echo "[INFO]   目录: $install_dir"
    echo "[INFO]   端口: $port"
    echo "[INFO]   静默: $silent"
    echo "[INFO]   性能优化: $performance"
    echo "[INFO]   生产环境: $production"
    echo "[INFO]   调试模式: $debug"
    echo ""
    
    if [ -n "$install_type" ] && [[ "$install_type" =~ ^(docker|native|minimal)$ ]]; then
        echo "[SUCCESS] 参数解析成功！安装类型: $install_type"
    else
        echo "[ERROR] 无效的安装类型: $install_type"
    fi
}

# 包含原始脚本的函数定义
source <(sed -n '/^#.*/,/^main()/p' install.sh | grep -v '^main()')

# 运行测试主函数
test_main "$@"
EOF

chmod +x install_test.sh

# 测试1: 直接运行帮助
echo "测试1: 直接运行帮助"
./install.sh --help 2>&1 | head -20

echo -e "\n=== 测试2: 模拟管道执行 ==="

# 测试2: 模拟管道执行（无参数）
echo "测试2: 模拟管道执行（无参数）"
cat install.sh | head -20 | grep -A5 "版本:"

echo -e "\n=== 测试3: 检查参数解析逻辑 ==="

# 测试3: 检查参数解析函数
echo "测试3: 检查参数解析函数"
cat install.sh | grep -A30 "parse_arguments()" | head -40

echo -e "\n=== 测试4: 测试管道执行参数传递 ==="

# 测试4: 测试管道执行参数传递
echo "测试4: 测试管道执行参数传递"
echo "模拟: curl | bash -s -- $INSTALL_TYPE"
./install_test.sh "$INSTALL_TYPE" --help

echo -e "\n=== 测试5: 测试直接参数传递 ==="

# 测试5: 测试直接参数传递
echo "测试5: 测试直接参数传递"
echo "模拟: ./install.sh $INSTALL_TYPE --help"
./install_test.sh "$INSTALL_TYPE" --help

echo -e "\n=== 测试6: 测试参数解析函数 ==="

# 测试6: 直接测试参数解析函数
echo "测试6: 直接测试参数解析函数"
cat > test_parse.sh << 'EOF'
#!/bin/bash

# 包含参数解析函数
parse_arguments() {
    local install_type=""
    local install_dir="/opt/ipv6-wireguard-manager"
    local port="80"
    local silent=false
    local performance=false
    local production=false
    local debug=false
    local skip_deps=false
    local skip_db=false
    local skip_service=false
    
    # 检查是否通过管道执行（curl | bash）
    local is_piped=false
    if [ ! -t 0 ]; then
        is_piped=true
        # 如果是管道执行，检查是否有参数通过bash -s传递
        if [ $# -gt 0 ]; then
            # 重新解析参数（bash -s传递的参数）
            set -- $@
        fi
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            docker|native|minimal)
                install_type="$1"
                shift
                ;;
            --dir)
                install_dir="$2"
                shift 2
                ;;
            --port)
                port="$2"
                shift 2
                ;;
            --silent)
                silent=true
                shift
                ;;
            --performance)
                performance=true
                shift
                ;;
            --production)
                production=true
                shift
                ;;
            --debug)
                debug=true
                shift
                ;;
            --skip-deps)
                skip_deps=true
                shift
                ;;
            --skip-db)
                skip_db=true
                shift
                ;;
            --skip-service)
                skip_service=true
                shift
                ;;
            --auto)
                silent=true
                shift
                ;;
            --help|-h)
                echo "帮助信息"
                exit 0
                ;;
            --version|-v)
                echo "版本信息"
                exit 0
                ;;
            *)
                # 如果是管道执行且第一个参数不是选项，可能是安装类型
                if [ "$is_piped" = true ] && [ -z "$install_type" ] && [[ "$1" =~ ^(docker|native|minimal)$ ]]; then
                    install_type="$1"
                    shift
                else
                    echo "[ERROR] 未知选项: $1"
                    exit 1
                fi
                ;;
        esac
    done
    
    # 如果没有指定安装类型，自动选择
    if [ -z "$install_type" ]; then
        if [ "$silent" = true ] || [ "$is_piped" = true ] || [ ! -t 0 ]; then
            echo "[INFO] 自动选择安装类型..."
            install_type="docker"
            echo "[INFO] 选择的安装类型: $install_type"
        else
            install_type="docker"
        fi
    fi
    
    echo "$install_type|$install_dir|$port|$silent|$performance|$production|$debug|$skip_deps|$skip_db|$skip_service"
}

# 测试参数解析
result=$(parse_arguments "$@")
echo "参数解析结果: $result"
EOF

chmod +x test_parse.sh
./test_parse.sh "$INSTALL_TYPE" --help

echo -e "\n=== 测试完成 ==="

# 清理临时目录
cd /
rm -rf "$TEMP_DIR"