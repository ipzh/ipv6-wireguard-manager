#!/bin/bash

# 验证所有脚本的真正改进效果
# 检查execute_command函数的实际使用情况

echo "=== 验证脚本改进效果 ==="
echo "测试时间: $(date)"
echo

# 检查execute_command函数的实际使用
echo "1. 检查execute_command函数的实际使用情况..."

scripts=("ipv6-wireguard-manager.sh" "uninstall.sh" "install_with_download.sh" "scripts/automated-testing.sh")

for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        echo "  检查 $script:"
        
        # 检查函数定义
        if grep -q "execute_command()" "$script"; then
            echo "    ✓ execute_command函数已定义"
        else
            echo "    ✗ execute_command函数未定义"
        fi
        
        # 检查实际使用
        usage_count=$(grep -c "execute_command(" "$script" 2>/dev/null || echo "0")
        if [[ "$usage_count" -gt 0 ]]; then
            echo "    ✓ execute_command函数已使用 $usage_count 次"
        else
            echo "    ✗ execute_command函数未实际使用"
        fi
        
        # 检查传统命令执行
        traditional_commands=$(grep -c -E "(systemctl|service|chmod|chown|mkdir|cp|rm|mv|ln|apt-get|yum|dnf|pacman|zypper|wget|curl|tar)" "$script" 2>/dev/null || echo "0")
        echo "    ℹ 传统命令执行: $traditional_commands 个"
        
        echo
    else
        echo "  ✗ $script 文件不存在"
        echo
    fi
done

# 检查secure_permissions函数的实际使用
echo "2. 检查secure_permissions函数的实际使用情况..."

for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        echo "  检查 $script:"
        
        # 检查函数定义
        if grep -q "secure_permissions()" "$script"; then
            echo "    ✓ secure_permissions函数已定义"
        else
            echo "    ✗ secure_permissions函数未定义"
        fi
        
        # 检查实际使用
        usage_count=$(grep -c "secure_permissions(" "$script" 2>/dev/null || echo "0")
        if [[ "$usage_count" -gt 0 ]]; then
            echo "    ✓ secure_permissions函数已使用 $usage_count 次"
        else
            echo "    ✗ secure_permissions函数未实际使用"
        fi
        
        echo
    fi
done

# 检查模块加载器的实际使用
echo "3. 检查模块加载器的实际使用情况..."

for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        echo "  检查 $script:"
        
        # 检查模块加载器导入
        if grep -q "module_loader.sh" "$script"; then
            echo "    ✓ 模块加载器已导入"
        else
            echo "    ✗ 模块加载器未导入"
        fi
        
        # 检查lazy_load函数使用
        lazy_load_count=$(grep -c "lazy_load(" "$script" 2>/dev/null || echo "0")
        if [[ "$lazy_load_count" -gt 0 ]]; then
            echo "    ✓ lazy_load函数已使用 $lazy_load_count 次"
        else
            echo "    ✗ lazy_load函数未实际使用"
        fi
        
        echo
    fi
done

# 检查统一导入机制
echo "4. 检查统一导入机制..."

for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        echo "  检查 $script:"
        
        # 检查统一导入机制
        if grep -q "统一的导入机制" "$script"; then
            echo "    ✓ 统一导入机制已应用"
        else
            echo "    ✗ 统一导入机制未应用"
        fi
        
        # 检查SCRIPT_DIR使用
        if grep -q "SCRIPT_DIR=" "$script"; then
            echo "    ✓ SCRIPT_DIR变量已定义"
        else
            echo "    ✗ SCRIPT_DIR变量未定义"
        fi
        
        echo
    fi
done

echo "=== 验证完成 ==="
echo "所有脚本的改进效果已检查"
