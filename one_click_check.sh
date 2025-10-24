#!/bin/bash

# IPv6 WireGuard Manager 一键检查工具 (Linux/macOS版本)
# 一键检查所有问题并生成综合诊断报告

echo "🔍 IPv6 WireGuard Manager 一键检查工具"
echo "========================================"
echo

# 检查Python是否可用
if ! command -v python3 &> /dev/null; then
    echo "[ERROR] Python3未安装或不在PATH中"
    echo "请先安装Python3"
    exit 1
fi

# 检查必要的Python包
echo "[INFO] 检查Python依赖包..."
python3 -c "import psutil, requests" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "[WARNING] 缺少必要的Python包，正在安装..."
    
    # 尝试多种安装方式
    echo "[INFO] 尝试使用系统包管理器安装..."
    if command -v apt &> /dev/null; then
        # Ubuntu/Debian系统
        apt update >/dev/null 2>&1
        apt install -y python3-psutil python3-requests 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "[SUCCESS] ✓ 使用apt安装成功"
        else
            echo "[INFO] apt安装失败，尝试pip安装..."
            pip3 install --user psutil requests 2>/dev/null
            if [ $? -eq 0 ]; then
                echo "[SUCCESS] ✓ 使用pip --user安装成功"
            else
                echo "[INFO] pip --user安装失败，尝试虚拟环境..."
                python3 -m venv /tmp/check_env 2>/dev/null
                if [ $? -eq 0 ]; then
                    source /tmp/check_env/bin/activate
                    pip install psutil requests 2>/dev/null
                    if [ $? -eq 0 ]; then
                        echo "[SUCCESS] ✓ 使用虚拟环境安装成功"
                        export PYTHON_PATH="/tmp/check_env/bin/python"
                    else
                        echo "[ERROR] 所有安装方式都失败了"
                        echo "[INFO] 将使用基础检查模式（无需Python包）"
                        export USE_BASIC_MODE=1
                    fi
                else
                    echo "[ERROR] 无法创建虚拟环境"
                    echo "[INFO] 将使用基础检查模式（无需Python包）"
                    export USE_BASIC_MODE=1
                fi
            fi
        fi
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL系统
        yum install -y python3-psutil python3-requests 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "[SUCCESS] ✓ 使用yum安装成功"
        else
            echo "[INFO] yum安装失败，尝试pip安装..."
            pip3 install --user psutil requests 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "[ERROR] pip安装失败"
                echo "[INFO] 将使用基础检查模式（无需Python包）"
                export USE_BASIC_MODE=1
            fi
        fi
    else
        echo "[INFO] 未知的包管理器，尝试pip安装..."
        pip3 install --user psutil requests 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "[ERROR] pip安装失败"
            echo "[INFO] 将使用基础检查模式（无需Python包）"
            export USE_BASIC_MODE=1
        fi
    fi
fi

# 运行一键检查
echo "[INFO] 开始运行一键检查..."

if [ "$USE_BASIC_MODE" = "1" ]; then
    echo "[INFO] 使用基础检查模式..."
    # 运行基础检查（无需Python包）
    ./scripts/check_logs.sh all
else
    # 使用Python版本检查
    if [ -n "$PYTHON_PATH" ]; then
        echo "[INFO] 使用虚拟环境Python..."
        $PYTHON_PATH scripts/one_click_check.py
    else
        echo "[INFO] 使用系统Python..."
        python3 scripts/one_click_check.py
    fi
fi

# 检查退出码
case $? in
    0)
        echo
        echo "[SUCCESS] ✅ 所有检查通过，系统运行正常！"
        ;;
    1)
        echo
        echo "[ERROR] ❌ 发现严重问题，需要修复！"
        ;;
    2)
        echo
        echo "[WARNING] ⚠️ 发现警告，建议检查！"
        ;;
esac

echo
echo "检查完成！详细报告已保存到当前目录"
