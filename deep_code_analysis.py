#!/usr/bin/env python3
"""
IPv6 WireGuard Manager - 深度代码分析脚本
检查API服务的代码层面问题
"""

import os
import sys
import ast
import importlib.util
import traceback
from pathlib import Path
from typing import List, Dict, Any

# 添加项目路径
PROJECT_ROOT = Path(__file__).parent.absolute()
sys.path.insert(0, str(PROJECT_ROOT))

class CodeAnalyzer:
    """代码分析器"""
    
    def __init__(self):
        self.install_dir = "/opt/ipv6-wireguard-manager"
        self.errors = []
        self.warnings = []
        self.info = []
    
    def log_error(self, message: str):
        """记录错误"""
        print(f"❌ [ERROR] {message}")
        self.errors.append(message)
    
    def log_warning(self, message: str):
        """记录警告"""
        print(f"⚠️  [WARNING] {message}")
        self.warnings.append(message)
    
    def log_info(self, message: str):
        """记录信息"""
        print(f"ℹ️  [INFO] {message}")
        self.info.append(message)
    
    def log_success(self, message: str):
        """记录成功"""
        print(f"✅ [SUCCESS] {message}")
    
    def check_python_syntax(self, file_path: Path) -> bool:
        """检查Python文件语法"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 尝试解析AST
            ast.parse(content)
            return True
        except SyntaxError as e:
            self.log_error(f"语法错误 {file_path}: {e}")
            return False
        except Exception as e:
            self.log_error(f"解析错误 {file_path}: {e}")
            return False
    
    def check_imports(self, file_path: Path) -> List[str]:
        """检查导入语句"""
        missing_imports = []
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            tree = ast.parse(content)
            
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        try:
                            importlib.import_module(alias.name)
                        except ImportError:
                            missing_imports.append(alias.name)
                elif isinstance(node, ast.ImportFrom):
                    if node.module:
                        try:
                            importlib.import_module(node.module)
                        except ImportError:
                            missing_imports.append(node.module)
        
        except Exception as e:
            self.log_error(f"导入检查失败 {file_path}: {e}")
        
        return missing_imports
    
    def check_config_file(self) -> bool:
        """检查配置文件"""
        config_file = Path(self.install_dir) / "backend" / "app" / "core" / "config_enhanced.py"
        
        if not config_file.exists():
            self.log_error(f"配置文件不存在: {config_file}")
            return False
        
        self.log_success(f"配置文件存在: {config_file}")
        
        # 检查语法
        if not self.check_python_syntax(config_file):
            return False
        
        # 检查导入
        missing_imports = self.check_imports(config_file)
        if missing_imports:
            for imp in missing_imports:
                self.log_error(f"缺少导入: {imp}")
            return False
        
        # 尝试导入配置
        try:
            sys.path.insert(0, str(config_file.parent))
            spec = importlib.util.spec_from_file_location("config_enhanced", config_file)
            config_module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(config_module)
            
            # 检查设置类
            if hasattr(config_module, 'Settings'):
                settings_class = getattr(config_module, 'Settings')
                self.log_success("Settings类存在")
                
                # 尝试实例化
                try:
                    settings = settings_class()
                    self.log_success("Settings实例化成功")
                    
                    # 检查关键属性
                    required_attrs = [
                        'DATABASE_URL', 'SECRET_KEY', 'HOST', 'PORT',
                        'UPLOAD_DIR', 'WIREGUARD_CONFIG_DIR'
                    ]
                    
                    for attr in required_attrs:
                        if hasattr(settings, attr):
                            value = getattr(settings, attr)
                            self.log_success(f"配置项 {attr}: {value}")
                        else:
                            self.log_error(f"缺少配置项: {attr}")
                    
                except Exception as e:
                    self.log_error(f"Settings实例化失败: {e}")
                    self.log_error(f"错误详情: {traceback.format_exc()}")
                    return False
            else:
                self.log_error("Settings类不存在")
                return False
                
        except Exception as e:
            self.log_error(f"配置文件导入失败: {e}")
            self.log_error(f"错误详情: {traceback.format_exc()}")
            return False
        
        return True
    
    def check_main_app(self) -> bool:
        """检查主应用文件"""
        main_file = Path(self.install_dir) / "backend" / "app" / "main.py"
        
        if not main_file.exists():
            self.log_error(f"主应用文件不存在: {main_file}")
            return False
        
        self.log_success(f"主应用文件存在: {main_file}")
        
        # 检查语法
        if not self.check_python_syntax(main_file):
            return False
        
        # 检查导入
        missing_imports = self.check_imports(main_file)
        if missing_imports:
            for imp in missing_imports:
                self.log_error(f"缺少导入: {imp}")
            return False
        
        # 尝试导入主应用
        try:
            sys.path.insert(0, str(main_file.parent))
            spec = importlib.util.spec_from_file_location("main", main_file)
            main_module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(main_module)
            
            # 检查app对象
            if hasattr(main_module, 'app'):
                app = getattr(main_module, 'app')
                self.log_success("FastAPI应用对象存在")
                
                # 检查应用类型
                if hasattr(app, 'routes'):
                    self.log_success(f"应用路由数量: {len(app.routes)}")
                else:
                    self.log_warning("应用没有routes属性")
                
            else:
                self.log_error("FastAPI应用对象不存在")
                return False
                
        except Exception as e:
            self.log_error(f"主应用导入失败: {e}")
            self.log_error(f"错误详情: {traceback.format_exc()}")
            return False
        
        return True
    
    def check_database_models(self) -> bool:
        """检查数据库模型"""
        models_dir = Path(self.install_dir) / "backend" / "app" / "models"
        
        if not models_dir.exists():
            self.log_warning(f"模型目录不存在: {models_dir}")
            return True
        
        model_files = list(models_dir.glob("*.py"))
        if not model_files:
            self.log_warning("没有找到模型文件")
            return True
        
        self.log_success(f"找到 {len(model_files)} 个模型文件")
        
        for model_file in model_files:
            if model_file.name == "__init__.py":
                continue
            
            self.log_info(f"检查模型文件: {model_file.name}")
            
            # 检查语法
            if not self.check_python_syntax(model_file):
                continue
            
            # 检查导入
            missing_imports = self.check_imports(model_file)
            if missing_imports:
                for imp in missing_imports:
                    self.log_error(f"模型文件 {model_file.name} 缺少导入: {imp}")
        
        return True
    
    def check_api_routes(self) -> bool:
        """检查API路由"""
        routes_dir = Path(self.install_dir) / "backend" / "app" / "api"
        
        if not routes_dir.exists():
            self.log_warning(f"API路由目录不存在: {routes_dir}")
            return True
        
        route_files = list(routes_dir.glob("**/*.py"))
        if not route_files:
            self.log_warning("没有找到API路由文件")
            return True
        
        self.log_success(f"找到 {len(route_files)} 个API路由文件")
        
        for route_file in route_files:
            if route_file.name == "__init__.py":
                continue
            
            self.log_info(f"检查路由文件: {route_file.relative_to(routes_dir)}")
            
            # 检查语法
            if not self.check_python_syntax(route_file):
                continue
            
            # 检查导入
            missing_imports = self.check_imports(route_file)
            if missing_imports:
                for imp in missing_imports:
                    self.log_error(f"路由文件 {route_file.name} 缺少导入: {imp}")
        
        return True
    
    def check_environment_file(self) -> bool:
        """检查环境文件"""
        env_file = Path(self.install_dir) / ".env"
        
        if not env_file.exists():
            self.log_error(f"环境文件不存在: {env_file}")
            return False
        
        self.log_success(f"环境文件存在: {env_file}")
        
        # 检查环境文件内容
        try:
            with open(env_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 检查关键配置项
            required_configs = [
                'DATABASE_URL', 'SECRET_KEY', 'HOST', 'PORT'
            ]
            
            for config in required_configs:
                if f"{config}=" in content:
                    self.log_success(f"配置项存在: {config}")
                else:
                    self.log_error(f"配置项缺失: {config}")
            
        except Exception as e:
            self.log_error(f"环境文件读取失败: {e}")
            return False
        
        return True
    
    def check_requirements(self) -> bool:
        """检查依赖文件"""
        req_file = Path(self.install_dir) / "backend" / "requirements.txt"
        
        if not req_file.exists():
            self.log_error(f"依赖文件不存在: {req_file}")
            return False
        
        self.log_success(f"依赖文件存在: {req_file}")
        
        # 检查关键依赖
        try:
            with open(req_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            required_packages = [
                'fastapi', 'uvicorn', 'sqlalchemy', 'pymysql', 'aiomysql'
            ]
            
            for package in required_packages:
                if package in content:
                    self.log_success(f"依赖包存在: {package}")
                else:
                    self.log_warning(f"依赖包缺失: {package}")
            
        except Exception as e:
            self.log_error(f"依赖文件读取失败: {e}")
            return False
        
        return True
    
    def run_analysis(self) -> bool:
        """运行完整分析"""
        print("🔍 开始深度代码分析...")
        print("=" * 50)
        
        # 检查配置文件
        print("\n📋 检查配置文件...")
        config_ok = self.check_config_file()
        
        # 检查主应用
        print("\n🚀 检查主应用...")
        main_ok = self.check_main_app()
        
        # 检查数据库模型
        print("\n🗄️  检查数据库模型...")
        models_ok = self.check_database_models()
        
        # 检查API路由
        print("\n🛣️  检查API路由...")
        routes_ok = self.check_api_routes()
        
        # 检查环境文件
        print("\n⚙️  检查环境文件...")
        env_ok = self.check_environment_file()
        
        # 检查依赖文件
        print("\n📦 检查依赖文件...")
        req_ok = self.check_requirements()
        
        # 显示结果
        print("\n" + "=" * 50)
        print("📊 分析结果汇总:")
        print(f"✅ 成功: {len(self.info)} 项")
        print(f"⚠️  警告: {len(self.warnings)} 项")
        print(f"❌ 错误: {len(self.errors)} 项")
        
        if self.errors:
            print("\n❌ 发现的错误:")
            for error in self.errors:
                print(f"  - {error}")
        
        if self.warnings:
            print("\n⚠️  发现的警告:")
            for warning in self.warnings:
                print(f"  - {warning}")
        
        if not self.errors:
            print("\n🎉 代码分析完成，没有发现错误！")
            return True
        else:
            print(f"\n❌ 代码分析完成，发现 {len(self.errors)} 个错误")
            return False

def main():
    """主函数"""
    analyzer = CodeAnalyzer()
    
    try:
        success = analyzer.run_analysis()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⏹️  分析被用户中断")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ 分析过程中发生错误: {e}")
        print(f"错误详情: {traceback.format_exc()}")
        sys.exit(1)

if __name__ == "__main__":
    main()
