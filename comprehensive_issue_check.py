#!/usr/bin/env python3
"""
IPv6 WireGuard Manager - 综合问题检查脚本
检查导入问题、编码问题、语法问题
"""

import os
import sys
import ast
import re
import chardet
from pathlib import Path
from typing import List, Dict, Tuple, Any

class IssueChecker:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.issues = []
        self.encoding_issues = []
        self.syntax_issues = []
        self.import_issues = []
        
    def check_all(self):
        """检查所有问题"""
        print("🔍 开始综合问题检查...")
        
        # 检查Python文件
        self.check_python_files()
        
        # 检查PHP文件
        self.check_php_files()
        
        # 检查配置文件
        self.check_config_files()
        
        # 检查脚本文件
        self.check_script_files()
        
        # 生成报告
        self.generate_report()
        
    def check_python_files(self):
        """检查Python文件"""
        print("📝 检查Python文件...")
        
        python_files = list(self.project_root.rglob("*.py"))
        for file_path in python_files:
            if "venv" in str(file_path) or "__pycache__" in str(file_path):
                continue
                
            try:
                # 检查编码
                self.check_file_encoding(file_path)
                
                # 检查语法
                self.check_python_syntax(file_path)
                
                # 检查导入
                self.check_python_imports(file_path)
                
            except Exception as e:
                self.issues.append({
                    'type': 'error',
                    'file': str(file_path),
                    'message': f'检查文件时出错: {str(e)}'
                })
    
    def check_php_files(self):
        """检查PHP文件"""
        print("🐘 检查PHP文件...")
        
        php_files = list(self.project_root.rglob("*.php"))
        for file_path in php_files:
            try:
                # 检查编码
                self.check_file_encoding(file_path)
                
                # 检查PHP语法
                self.check_php_syntax(file_path)
                
            except Exception as e:
                self.issues.append({
                    'type': 'error',
                    'file': str(file_path),
                    'message': f'检查PHP文件时出错: {str(e)}'
                })
    
    def check_config_files(self):
        """检查配置文件"""
        print("⚙️ 检查配置文件...")
        
        config_files = [
            "backend/requirements.txt",
            "docker-compose.yml",
            "docker-compose.production.yml",
            "php-frontend/config/config.php",
            "php-frontend/config/database.php"
        ]
        
        for config_file in config_files:
            file_path = self.project_root / config_file
            if file_path.exists():
                try:
                    self.check_file_encoding(file_path)
                except Exception as e:
                    self.issues.append({
                        'type': 'error',
                        'file': str(file_path),
                        'message': f'检查配置文件时出错: {str(e)}'
                    })
    
    def check_script_files(self):
        """检查脚本文件"""
        print("📜 检查脚本文件...")
        
        script_files = list(self.project_root.rglob("*.sh"))
        for file_path in script_files:
            try:
                self.check_file_encoding(file_path)
                self.check_shell_syntax(file_path)
            except Exception as e:
                self.issues.append({
                    'type': 'error',
                    'file': str(file_path),
                    'message': f'检查脚本文件时出错: {str(e)}'
                })
    
    def check_file_encoding(self, file_path: Path):
        """检查文件编码"""
        try:
            with open(file_path, 'rb') as f:
                raw_data = f.read()
                
            # 检测编码
            result = chardet.detect(raw_data)
            encoding = result['encoding']
            confidence = result['confidence']
            
            if confidence < 0.7:
                self.encoding_issues.append({
                    'file': str(file_path),
                    'encoding': encoding,
                    'confidence': confidence,
                    'message': '编码检测置信度较低'
                })
            
            # 尝试用检测到的编码读取文件
            try:
                with open(file_path, 'r', encoding=encoding) as f:
                    content = f.read()
            except UnicodeDecodeError:
                self.encoding_issues.append({
                    'file': str(file_path),
                    'encoding': encoding,
                    'confidence': confidence,
                    'message': '无法用检测到的编码读取文件'
                })
                
        except Exception as e:
            self.encoding_issues.append({
                'file': str(file_path),
                'encoding': 'unknown',
                'confidence': 0,
                'message': f'编码检查失败: {str(e)}'
            })
    
    def check_python_syntax(self, file_path: Path):
        """检查Python语法"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 尝试解析AST
            try:
                ast.parse(content)
            except SyntaxError as e:
                self.syntax_issues.append({
                    'file': str(file_path),
                    'line': e.lineno,
                    'column': e.offset,
                    'message': f'语法错误: {e.msg}',
                    'text': e.text
                })
            except Exception as e:
                self.syntax_issues.append({
                    'file': str(file_path),
                    'line': 0,
                    'column': 0,
                    'message': f'解析错误: {str(e)}',
                    'text': ''
                })
                
        except Exception as e:
            self.syntax_issues.append({
                'file': str(file_path),
                'line': 0,
                'column': 0,
                'message': f'读取文件失败: {str(e)}',
                'text': ''
            })
    
    def check_python_imports(self, file_path: Path):
        """检查Python导入"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 解析AST
            try:
                tree = ast.parse(content)
            except:
                return  # 语法错误已在语法检查中处理
            
            # 检查导入
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        self.check_import_path(file_path, alias.name, node.lineno)
                elif isinstance(node, ast.ImportFrom):
                    if node.module:
                        self.check_import_path(file_path, node.module, node.lineno)
                        
        except Exception as e:
            self.import_issues.append({
                'file': str(file_path),
                'import': 'unknown',
                'line': 0,
                'message': f'导入检查失败: {str(e)}'
            })
    
    def check_import_path(self, file_path: Path, import_name: str, line_no: int):
        """检查导入路径"""
        # 检查相对导入
        if import_name.startswith('.'):
            # 计算相对导入的绝对路径
            parts = import_name.split('.')
            current_dir = file_path.parent
            
            # 处理相对导入
            for part in parts:
                if part == '':
                    current_dir = current_dir.parent
                else:
                    current_dir = current_dir / part
            
            # 检查是否存在对应的模块
            possible_paths = [
                current_dir / '__init__.py',
                current_dir.with_suffix('.py')
            ]
            
            if not any(p.exists() for p in possible_paths):
                self.import_issues.append({
                    'file': str(file_path),
                    'import': import_name,
                    'line': line_no,
                    'message': f'相对导入路径不存在: {current_dir}'
                })
        
        # 检查绝对导入
        elif not import_name.startswith('.'):
            # 检查是否是标准库
            if import_name in sys.builtin_module_names:
                return
            
            # 检查是否是第三方库
            try:
                __import__(import_name)
            except ImportError:
                # 检查是否是项目内部模块
                module_path = self.project_root / import_name.replace('.', '/')
                if not (module_path.exists() or (module_path.with_suffix('.py')).exists()):
                    self.import_issues.append({
                        'file': str(file_path),
                        'import': import_name,
                        'line': line_no,
                        'message': f'导入模块不存在: {import_name}'
                    })
    
    def check_php_syntax(self, file_path: Path):
        """检查PHP语法"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 检查基本的PHP语法问题
            lines = content.split('\n')
            for i, line in enumerate(lines, 1):
                # 检查未闭合的PHP标签
                if '<?php' in line and '?>' not in line:
                    # 检查是否有对应的结束标签
                    remaining_content = '\n'.join(lines[i:])
                    if '?>' not in remaining_content and not line.strip().endswith('<?php'):
                        self.syntax_issues.append({
                            'file': str(file_path),
                            'line': i,
                            'column': 0,
                            'message': 'PHP标签可能未正确闭合',
                            'text': line.strip()
                        })
                
                # 检查常见的语法错误
                if line.strip().endswith(';') and not line.strip().startswith('//'):
                    # 检查是否有未闭合的字符串
                    if line.count('"') % 2 != 0 or line.count("'") % 2 != 0:
                        self.syntax_issues.append({
                            'file': str(file_path),
                            'line': i,
                            'column': 0,
                            'message': '可能的字符串未闭合',
                            'text': line.strip()
                        })
                        
        except Exception as e:
            self.syntax_issues.append({
                'file': str(file_path),
                'line': 0,
                'column': 0,
                'message': f'PHP语法检查失败: {str(e)}',
                'text': ''
            })
    
    def check_shell_syntax(self, file_path: Path):
        """检查Shell脚本语法"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 检查基本的Shell语法问题
            lines = content.split('\n')
            for i, line in enumerate(lines, 1):
                line = line.strip()
                
                # 检查未闭合的引号
                if line and not line.startswith('#'):
                    if line.count('"') % 2 != 0 or line.count("'") % 2 != 0:
                        self.syntax_issues.append({
                            'file': str(file_path),
                            'line': i,
                            'column': 0,
                            'message': 'Shell脚本中可能的引号未闭合',
                            'text': line
                        })
                
                # 检查变量引用
                if '$' in line and not line.startswith('#'):
                    # 检查变量引用语法
                    if re.search(r'\$\{[^}]*$', line):
                        self.syntax_issues.append({
                            'file': str(file_path),
                            'line': i,
                            'column': 0,
                            'message': 'Shell脚本中可能的变量引用未闭合',
                            'text': line
                        })
                        
        except Exception as e:
            self.syntax_issues.append({
                'file': str(file_path),
                'line': 0,
                'column': 0,
                'message': f'Shell语法检查失败: {str(e)}',
                'text': ''
            })
    
    def generate_report(self):
        """生成问题报告"""
        print("\n" + "="*80)
        print("📊 综合问题检查报告")
        print("="*80)
        
        # 编码问题
        if self.encoding_issues:
            print(f"\n🔤 编码问题 ({len(self.encoding_issues)}个):")
            for issue in self.encoding_issues:
                print(f"  ❌ {issue['file']}")
                print(f"     编码: {issue['encoding']} (置信度: {issue['confidence']:.2f})")
                print(f"     问题: {issue['message']}")
        else:
            print("\n✅ 编码检查通过")
        
        # 语法问题
        if self.syntax_issues:
            print(f"\n📝 语法问题 ({len(self.syntax_issues)}个):")
            for issue in self.syntax_issues:
                print(f"  ❌ {issue['file']}:{issue['line']}")
                print(f"     问题: {issue['message']}")
                if issue['text']:
                    print(f"     代码: {issue['text']}")
        else:
            print("\n✅ 语法检查通过")
        
        # 导入问题
        if self.import_issues:
            print(f"\n📦 导入问题 ({len(self.import_issues)}个):")
            for issue in self.import_issues:
                print(f"  ❌ {issue['file']}:{issue['line']}")
                print(f"     导入: {issue['import']}")
                print(f"     问题: {issue['message']}")
        else:
            print("\n✅ 导入检查通过")
        
        # 其他问题
        if self.issues:
            print(f"\n⚠️ 其他问题 ({len(self.issues)}个):")
            for issue in self.issues:
                print(f"  ❌ {issue['file']}")
                print(f"     问题: {issue['message']}")
        
        # 总结
        total_issues = len(self.encoding_issues) + len(self.syntax_issues) + len(self.import_issues) + len(self.issues)
        print(f"\n📈 问题统计:")
        print(f"  编码问题: {len(self.encoding_issues)}")
        print(f"  语法问题: {len(self.syntax_issues)}")
        print(f"  导入问题: {len(self.import_issues)}")
        print(f"  其他问题: {len(self.issues)}")
        print(f"  总计: {total_issues}")
        
        if total_issues == 0:
            print("\n🎉 所有检查通过！项目没有发现明显问题。")
        else:
            print(f"\n⚠️ 发现 {total_issues} 个问题，建议修复后再部署。")
        
        print("="*80)

def main():
    """主函数"""
    if len(sys.argv) > 1:
        project_root = sys.argv[1]
    else:
        project_root = "."
    
    checker = IssueChecker(project_root)
    checker.check_all()

if __name__ == "__main__":
    main()
