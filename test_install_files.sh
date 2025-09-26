#!/bin/bash

# 测试install_files函数修复
echo "测试install_files函数修复..."

# 模拟install_files函数
test_install_files() {
    echo "测试文件路径检测..."
    
    # 获取脚本所在目录
    local script_dir="$(dirname "${BASH_SOURCE[0]}")"
    local main_script="$script_dir/ipv6-wireguard-manager.sh"
    
    echo "脚本目录: $script_dir"
    echo "主脚本路径: $main_script"
    echo "当前目录: $(pwd)"
    
    # 检查主脚本是否存在
    if [[ -f "$main_script" ]]; then
        echo "✓ 主脚本文件存在: $main_script"
    else
        echo "✗ 主脚本文件不存在: $main_script"
        return 1
    fi
    
    # 检查其他目录
    local dirs=("modules" "config" "scripts" "examples" "docs")
    for dir in "${dirs[@]}"; do
        local dir_path="$script_dir/$dir"
        if [[ -d "$dir_path" ]]; then
            echo "✓ $dir 目录存在: $dir_path"
        else
            echo "✗ $dir 目录不存在: $dir_path"
        fi
    done
    
    echo "文件路径检测完成"
}

# 运行测试
test_install_files

echo "测试完成！"
