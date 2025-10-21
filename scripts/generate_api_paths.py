#!/usr/bin/env python3
"""
API路径生成脚本
从后端导出API路径配置，供前端使用
"""
import sys
import os
import json
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from backend.app.core.api_path_exporter import export_api_paths
from backend.app.api.api_v1.api import api_router

def main():
    """主函数"""
    print("🚀 开始生成API路径配置...")
    
    try:
        # 导出JSON格式
        json_config = export_api_paths(api_router, "json")
        
        # 保存到文件
        output_dir = project_root / "generated"
        output_dir.mkdir(exist_ok=True)
        
        # 保存JSON配置
        json_file = output_dir / "api_paths.json"
        with open(json_file, 'w', encoding='utf-8') as f:
            f.write(json_config)
        print(f"✅ JSON配置已保存到: {json_file}")
        
        # 导出PHP格式
        php_config = export_api_paths(api_router, "php")
        php_file = output_dir / "api_paths.php"
        with open(php_file, 'w', encoding='utf-8') as f:
            f.write(php_config)
        print(f"✅ PHP配置已保存到: {php_file}")
        
        # 导出JavaScript格式
        js_config = export_api_paths(api_router, "js")
        js_file = output_dir / "api_paths.js"
        with open(js_file, 'w', encoding='utf-8') as f:
            f.write(js_config)
        print(f"✅ JavaScript配置已保存到: {js_file}")
        
        # 复制到前端目录
        frontend_php_dir = project_root / "php-frontend" / "config"
        frontend_js_dir = project_root / "php-frontend" / "assets" / "js"
        
        if frontend_php_dir.exists():
            import shutil
            shutil.copy2(php_file, frontend_php_dir / "api_paths.php")
            print(f"✅ PHP配置已复制到前端目录: {frontend_php_dir}")
        
        if frontend_js_dir.exists():
            import shutil
            shutil.copy2(js_file, frontend_js_dir / "api_paths.js")
            print(f"✅ JavaScript配置已复制到前端目录: {frontend_js_dir}")
        
        print("🎉 API路径配置生成完成！")
        
    except Exception as e:
        print(f"❌ 生成API路径配置失败: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
