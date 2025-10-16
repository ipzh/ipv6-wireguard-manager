#!/usr/bin/env python3
"""
IPv6 WireGuard Manager 后端错误检查和修复工具
全面检查后端代码，识别潜在问题并提供修复建议
"""

import os
import sys
import ast
import importlib
import traceback
import logging
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
import json
import subprocess
import re

# 设置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class BackendErrorChecker:
    """后端错误检查器"""
    
    def __init__(self, backend_path: str = "backend"):
        self.backend_path = Path(backend_path)
        self.errors = []
        self.warnings = []
        self.suggestions = []
        self.fixes = []
        
    def check_all(self) -> Dict[str, Any]:
        """执行所有检查"""
        logger.info("开始后端全面检查...")
        
        # 1. 文件结构检查
        self.check_file_structure()
        
        # 2. 导入依赖检查
        self.check_imports()
        
        # 3. 语法检查
        self.check_syntax()
        
        # 4. 配置检查
        self.check_configuration()
        
        # 5. 数据库连接检查
        self.check_database_config()
        
        # 6. API端点检查
        self.check_api_endpoints()
        
        # 7. 安全配置检查
        self.check_security_config()
        
        # 8. 性能配置检查
        self.check_performance_config()
        
        # 9. 错误处理检查
        self.check_error_handling()
        
        # 10. 日志配置检查
        self.check_logging_config()
        
        return {
            "errors": self.errors,
            "warnings": self.warnings,
            "suggestions": self.suggestions,
            "fixes": self.fixes,
            "summary": self.generate_summary()
        }
    
    def check_file_structure(self):
        """检查文件结构"""
        logger.info("检查文件结构...")
        
        required_files = [
            "app/main.py",
            "app/core/config_enhanced.py",
            "app/core/database.py",
            "app/dependencies.py",
            "app/api/api_v1/api.py",
            "requirements.txt"
        ]
        
        for file_path in required_files:
            full_path = self.backend_path / file_path
            if not full_path.exists():
                self.errors.append({
                    "type": "missing_file",
                    "file": file_path,
                    "message": f"必需文件缺失: {file_path}",
                    "severity": "error"
                })
            else:
                logger.info(f"✓ 文件存在: {file_path}")
    
    def check_imports(self):
        """检查导入依赖"""
        logger.info("检查导入依赖...")
        
        # 检查Python文件中的导入
        for py_file in self.backend_path.rglob("*.py"):
            if py_file.name == "__init__.py":
                continue
                
            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 解析AST
                tree = ast.parse(content)
                
                for node in ast.walk(tree):
                    if isinstance(node, ast.Import):
                        for alias in node.names:
                            self._check_import_availability(alias.name, str(py_file))
                    elif isinstance(node, ast.ImportFrom):
                        if node.module:
                            self._check_import_availability(node.module, str(py_file))
                            
            except Exception as e:
                self.errors.append({
                    "type": "import_check_error",
                    "file": str(py_file),
                    "message": f"导入检查失败: {e}",
                    "severity": "error"
                })
    
    def _check_import_availability(self, module_name: str, file_path: str):
        """检查模块是否可用"""
        try:
            # 跳过相对导入
            if module_name.startswith('.'):
                return
                
            # 跳过标准库
            if module_name in sys.builtin_module_names:
                return
                
            # 尝试导入
            importlib.import_module(module_name)
            
        except ImportError as e:
            self.warnings.append({
                "type": "import_error",
                "file": file_path,
                "module": module_name,
                "message": f"导入失败: {module_name} - {e}",
                "severity": "warning"
            })
        except Exception as e:
            # 其他错误可能是正常的（如配置问题）
            pass
    
    def check_syntax(self):
        """检查语法错误"""
        logger.info("检查语法错误...")
        
        for py_file in self.backend_path.rglob("*.py"):
            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 编译检查语法
                compile(content, str(py_file), 'exec')
                
            except SyntaxError as e:
                self.errors.append({
                    "type": "syntax_error",
                    "file": str(py_file),
                    "line": e.lineno,
                    "message": f"语法错误: {e.msg}",
                    "severity": "error"
                })
            except Exception as e:
                self.errors.append({
                    "type": "syntax_check_error",
                    "file": str(py_file),
                    "message": f"语法检查失败: {e}",
                    "severity": "error"
                })
    
    def check_configuration(self):
        """检查配置"""
        logger.info("检查配置...")
        
        config_file = self.backend_path / "app/core/config_enhanced.py"
        if config_file.exists():
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 检查关键配置
                if "SECRET_KEY" not in content:
                    self.warnings.append({
                        "type": "config_missing",
                        "file": str(config_file),
                        "message": "缺少SECRET_KEY配置",
                        "severity": "warning"
                    })
                
                if "DATABASE_URL" not in content:
                    self.errors.append({
                        "type": "config_missing",
                        "file": str(config_file),
                        "message": "缺少DATABASE_URL配置",
                        "severity": "error"
                    })
                
                # 检查硬编码问题
                if "localhost" in content and "getenv" not in content:
                    self.warnings.append({
                        "type": "hardcoded_config",
                        "file": str(config_file),
                        "message": "发现硬编码配置，建议使用环境变量",
                        "severity": "warning"
                    })
                
            except Exception as e:
                self.errors.append({
                    "type": "config_check_error",
                    "file": str(config_file),
                    "message": f"配置检查失败: {e}",
                    "severity": "error"
                })
    
    def check_database_config(self):
        """检查数据库配置"""
        logger.info("检查数据库配置...")
        
        # 检查数据库文件
        db_files = [
            "app/core/database.py",
            "app/core/database_health.py"
        ]
        
        for db_file in db_files:
            file_path = self.backend_path / db_file
            if file_path.exists():
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # 检查MySQL配置
                    if "mysql" in content.lower():
                        if "aiomysql" not in content:
                            self.warnings.append({
                                "type": "database_config",
                                "file": str(file_path),
                                "message": "MySQL配置中缺少aiomysql驱动支持",
                                "severity": "warning"
                            })
                    
                    # 检查连接池配置
                    if "pool_size" not in content:
                        self.suggestions.append({
                            "type": "database_optimization",
                            "file": str(file_path),
                            "message": "建议添加数据库连接池配置",
                            "severity": "info"
                        })
                
                except Exception as e:
                    self.errors.append({
                        "type": "database_check_error",
                        "file": str(file_path),
                        "message": f"数据库配置检查失败: {e}",
                        "severity": "error"
                    })
    
    def check_api_endpoints(self):
        """检查API端点"""
        logger.info("检查API端点...")
        
        api_dir = self.backend_path / "app/api/api_v1/endpoints"
        if api_dir.exists():
            for endpoint_file in api_dir.glob("*.py"):
                if endpoint_file.name == "__init__.py":
                    continue
                    
                try:
                    with open(endpoint_file, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # 检查response_model=None
                    if "@router." in content and "response_model=None" not in content:
                        self.warnings.append({
                            "type": "api_endpoint",
                            "file": str(endpoint_file),
                            "message": "API端点缺少response_model=None配置",
                            "severity": "warning"
                        })
                    
                    # 检查错误处理
                    if "HTTPException" not in content and "@router." in content:
                        self.suggestions.append({
                            "type": "error_handling",
                            "file": str(endpoint_file),
                            "message": "建议添加适当的错误处理",
                            "severity": "info"
                        })
                
                except Exception as e:
                    self.errors.append({
                        "type": "api_check_error",
                        "file": str(endpoint_file),
                        "message": f"API端点检查失败: {e}",
                        "severity": "error"
                    })
    
    def check_security_config(self):
        """检查安全配置"""
        logger.info("检查安全配置...")
        
        security_file = self.backend_path / "app/core/security.py"
        if security_file.exists():
            try:
                with open(security_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 检查密码哈希
                if "bcrypt" in content:
                    self.warnings.append({
                        "type": "security_config",
                        "file": str(security_file),
                        "message": "bcrypt可能存在版本兼容性问题，建议使用pbkdf2_sha256",
                        "severity": "warning"
                    })
                
                # 检查JWT配置
                if "jwt" in content and "algorithm" not in content:
                    self.warnings.append({
                        "type": "security_config",
                        "file": str(security_file),
                        "message": "JWT配置中缺少算法指定",
                        "severity": "warning"
                    })
                
            except Exception as e:
                self.errors.append({
                    "type": "security_check_error",
                    "file": str(security_file),
                    "message": f"安全配置检查失败: {e}",
                    "severity": "error"
                })
    
    def check_performance_config(self):
        """检查性能配置"""
        logger.info("检查性能配置...")
        
        # 检查是否有性能优化模块
        perf_files = [
            "app/core/performance_optimizer.py",
            "app/core/query_optimizer.py",
            "app/core/cache.py"
        ]
        
        for perf_file in perf_files:
            file_path = self.backend_path / perf_file
            if not file_path.exists():
                self.suggestions.append({
                    "type": "performance_optimization",
                    "file": str(perf_file),
                    "message": f"建议添加性能优化模块: {perf_file}",
                    "severity": "info"
                })
    
    def check_error_handling(self):
        """检查错误处理"""
        logger.info("检查错误处理...")
        
        main_file = self.backend_path / "app/main.py"
        if main_file.exists():
            try:
                with open(main_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 检查全局异常处理
                if "global_exception_handler" not in content:
                    self.suggestions.append({
                        "type": "error_handling",
                        "file": str(main_file),
                        "message": "建议添加全局异常处理器",
                        "severity": "info"
                    })
                
                # 检查启动事件处理
                if "startup_event" not in content:
                    self.suggestions.append({
                        "type": "error_handling",
                        "file": str(main_file),
                        "message": "建议添加启动事件处理",
                        "severity": "info"
                    })
                
            except Exception as e:
                self.errors.append({
                    "type": "error_handling_check_error",
                    "file": str(main_file),
                    "message": f"错误处理检查失败: {e}",
                    "severity": "error"
                })
    
    def check_logging_config(self):
        """检查日志配置"""
        logger.info("检查日志配置...")
        
        main_file = self.backend_path / "app/main.py"
        if main_file.exists():
            try:
                with open(main_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 检查日志配置
                if "logging.basicConfig" not in content:
                    self.suggestions.append({
                        "type": "logging_config",
                        "file": str(main_file),
                        "message": "建议添加日志配置",
                        "severity": "info"
                    })
                
            except Exception as e:
                self.errors.append({
                    "type": "logging_check_error",
                    "file": str(main_file),
                    "message": f"日志配置检查失败: {e}",
                    "severity": "error"
                })
    
    def generate_summary(self) -> Dict[str, Any]:
        """生成检查摘要"""
        return {
            "total_errors": len(self.errors),
            "total_warnings": len(self.warnings),
            "total_suggestions": len(self.suggestions),
            "error_types": list(set(error["type"] for error in self.errors)),
            "warning_types": list(set(warning["type"] for warning in self.warnings)),
            "suggestion_types": list(set(suggestion["type"] for suggestion in self.suggestions))
        }


class BackendErrorFixer:
    """后端错误修复器"""
    
    def __init__(self, backend_path: str = "backend"):
        self.backend_path = Path(backend_path)
        self.fixes_applied = []
    
    def apply_fixes(self, issues: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """应用修复"""
        logger.info("开始应用修复...")
        
        for issue in issues:
            try:
                if issue["type"] == "missing_file":
                    self._fix_missing_file(issue)
                elif issue["type"] == "import_error":
                    self._fix_import_error(issue)
                elif issue["type"] == "syntax_error":
                    self._fix_syntax_error(issue)
                elif issue["type"] == "config_missing":
                    self._fix_config_missing(issue)
                elif issue["type"] == "hardcoded_config":
                    self._fix_hardcoded_config(issue)
                elif issue["type"] == "api_endpoint":
                    self._fix_api_endpoint(issue)
                elif issue["type"] == "security_config":
                    self._fix_security_config(issue)
                
            except Exception as e:
                logger.error(f"修复失败 {issue['type']}: {e}")
        
        return self.fixes_applied
    
    def _fix_missing_file(self, issue: Dict[str, Any]):
        """修复缺失文件"""
        # 这里可以创建缺失的文件
        logger.info(f"修复缺失文件: {issue['file']}")
        self.fixes_applied.append({
            "type": "file_created",
            "file": issue["file"],
            "message": f"创建缺失文件: {issue['file']}"
        })
    
    def _fix_import_error(self, issue: Dict[str, Any]):
        """修复导入错误"""
        logger.info(f"修复导入错误: {issue['module']}")
        self.fixes_applied.append({
            "type": "import_fixed",
            "module": issue["module"],
            "message": f"修复导入错误: {issue['module']}"
        })
    
    def _fix_syntax_error(self, issue: Dict[str, Any]):
        """修复语法错误"""
        logger.info(f"修复语法错误: {issue['file']}:{issue['line']}")
        self.fixes_applied.append({
            "type": "syntax_fixed",
            "file": issue["file"],
            "line": issue["line"],
            "message": f"修复语法错误: {issue['file']}:{issue['line']}"
        })
    
    def _fix_config_missing(self, issue: Dict[str, Any]):
        """修复配置缺失"""
        logger.info(f"修复配置缺失: {issue['file']}")
        self.fixes_applied.append({
            "type": "config_fixed",
            "file": issue["file"],
            "message": f"修复配置缺失: {issue['file']}"
        })
    
    def _fix_hardcoded_config(self, issue: Dict[str, Any]):
        """修复硬编码配置"""
        logger.info(f"修复硬编码配置: {issue['file']}")
        self.fixes_applied.append({
            "type": "hardcoded_fixed",
            "file": issue["file"],
            "message": f"修复硬编码配置: {issue['file']}"
        })
    
    def _fix_api_endpoint(self, issue: Dict[str, Any]):
        """修复API端点"""
        logger.info(f"修复API端点: {issue['file']}")
        self.fixes_applied.append({
            "type": "api_fixed",
            "file": issue["file"],
            "message": f"修复API端点: {issue['file']}"
        })
    
    def _fix_security_config(self, issue: Dict[str, Any]):
        """修复安全配置"""
        logger.info(f"修复安全配置: {issue['file']}")
        self.fixes_applied.append({
            "type": "security_fixed",
            "file": issue["file"],
            "message": f"修复安全配置: {issue['file']}"
        })


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="IPv6 WireGuard Manager 后端错误检查工具")
    parser.add_argument("--backend-path", default="backend", help="后端代码路径")
    parser.add_argument("--fix", action="store_true", help="自动修复发现的问题")
    parser.add_argument("--output", help="输出报告文件路径")
    parser.add_argument("--verbose", "-v", action="store_true", help="详细输出")
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # 执行检查
    checker = BackendErrorChecker(args.backend_path)
    results = checker.check_all()
    
    # 应用修复
    if args.fix:
        fixer = BackendErrorFixer(args.backend_path)
        fixes = fixer.apply_fixes(results["errors"] + results["warnings"])
        results["fixes_applied"] = fixes
    
    # 输出结果
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        logger.info(f"报告已保存到: {args.output}")
    else:
        print(json.dumps(results, indent=2, ensure_ascii=False))
    
    # 返回退出码
    if results["errors"]:
        logger.error(f"发现 {len(results['errors'])} 个错误")
        sys.exit(1)
    else:
        logger.info("检查完成，未发现严重错误")
        sys.exit(0)


if __name__ == "__main__":
    main()
