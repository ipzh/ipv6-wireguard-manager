#!/usr/bin/env python3
"""
IPv6 WireGuard Manager 一键检查工具 - 远程下载版本
自动下载并运行一键检查工具
"""

import os
import sys
import requests
import subprocess
from pathlib import Path

def download_file(url: str, filename: str) -> bool:
    """下载文件"""
    try:
        print(f"[INFO] 正在下载: {url}")
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        
        with open(filename, 'wb') as f:
            f.write(response.content)
        
        print(f"[SUCCESS] ✓ 下载完成: {filename}")
        return True
    except Exception as e:
        print(f"[ERROR] ✗ 下载失败: {e}")
        return False

def main():
    """主函数"""
    print("🔍 IPv6 WireGuard Manager 一键检查工具 - 远程下载版本")
    print("=" * 60)
    print()
    
    # 设置下载URL
    base_url = "https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main"
    
    # 根据系统选择文件
    if sys.platform.startswith('win'):
        download_url = f"{base_url}/one_click_check_simple.bat"
        local_file = "one_click_check_simple.bat"
    else:
        download_url = f"{base_url}/one_click_check.sh"
        local_file = "one_click_check.sh"
    
    print(f"[INFO] 下载地址: {download_url}")
    print()
    
    # 下载文件
    if not download_file(download_url, local_file):
        print("[ERROR] 下载失败，请检查网络连接")
        return 1
    
    # 检查文件
    if not os.path.exists(local_file):
        print("[ERROR] 文件下载失败")
        return 1
    
    print(f"[SUCCESS] ✓ 文件下载成功: {local_file}")
    
    # 添加执行权限（Linux/macOS）
    if not sys.platform.startswith('win'):
        os.chmod(local_file, 0o755)
        print("[SUCCESS] ✓ 已添加执行权限")
    
    # 询问是否立即运行
    print()
    choice = input("[INFO] 是否立即运行检查工具? (y/n): ").lower()
    
    if choice in ['y', 'yes']:
        print()
        print("[INFO] 正在运行一键检查工具...")
        
        try:
            if sys.platform.startswith('win'):
                subprocess.run([local_file], check=True)
            else:
                subprocess.run([f"./{local_file}"], check=True)
        except subprocess.CalledProcessError as e:
            print(f"[ERROR] 运行失败: {e}")
            return 1
    else:
        print()
        print(f"[INFO] 文件已下载到当前目录: {local_file}")
        if sys.platform.startswith('win'):
            print(f"[INFO] 您可以稍后手动运行: {local_file}")
        else:
            print(f"[INFO] 您可以稍后手动运行: ./{local_file}")
    
    print()
    print("[INFO] 下载完成！")
    return 0

if __name__ == '__main__':
    sys.exit(main())
