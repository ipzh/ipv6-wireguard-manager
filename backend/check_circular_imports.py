#!/usr/bin/env python3
"""
导入循环依赖检查脚本
检查Python模块之间的循环依赖关系
"""

import ast
import sys
import os
from pathlib import Path
from typing import Dict, Set, List, Tuple
import importlib.util

class ImportAnalyzer:
    """导入分析器"""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.modules: Dict[str, Set[str]] = {}
        self.imports: Dict[str, Set[str]] = {}
        self.circular_deps: List[Tuple[str, str]] = []
    
    def analyze_file(self, file_path: Path) -> Set[str]:
        """分析单个文件的导入"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            tree = ast.parse(content)
            imports = set()
            
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        imports.add(alias.name.split('.')[0])
                elif isinstance(node, ast.ImportFrom):
                    if node.module:
                        imports.add(node.module.split('.')[0])
            
            return imports
        except Exception as e:
            print(f"警告: 无法分析文件 {file_path}: {e}")
            return set()
    
    def scan_project(self):
        """扫描整个项目"""
        print("🔍 扫描项目文件...")
        
        for py_file in self.project_root.rglob("*.py"):
            if py_file.name.startswith('__'):
                continue
            
            # 计算模块名
            rel_path = py_file.relative_to(self.project_root)
            module_name = str(rel_path.with_suffix('')).replace('/', '.').replace('\\', '.')
            
            # 分析导入
            imports = self.analyze_file(py_file)
            self.imports[module_name] = imports
            
            print(f"  📄 {module_name}: {len(imports)} 个导入")
    
    def find_circular_dependencies(self):
        """查找循环依赖"""
        print("\n🔍 查找循环依赖...")
        
        def dfs(module: str, visited: Set[str], rec_stack: Set[str], path: List[str]):
            visited.add(module)
            rec_stack.add(module)
            path.append(module)
            
            for imported_module in self.imports.get(module, set()):
                # 只检查项目内的模块
                if not any(imported_module.startswith(prefix) for prefix in ['app.', 'backend.', 'php-frontend.']):
                    continue
                
                if imported_module in rec_stack:
                    # 找到循环依赖
                    cycle_start = path.index(imported_module)
                    cycle = path[cycle_start:] + [imported_module]
                    self.circular_deps.append(tuple(cycle))
                    print(f"  ⚠️  发现循环依赖: {' -> '.join(cycle)}")
                elif imported_module not in visited:
                    dfs(imported_module, visited, rec_stack, path)
            
            rec_stack.remove(module)
            path.pop()
        
        visited = set()
        for module in self.imports:
            if module not in visited:
                dfs(module, visited, set(), [])
    
    def generate_report(self):
        """生成报告"""
        print("\n📊 导入分析报告")
        print("=" * 50)
        
        print(f"总模块数: {len(self.imports)}")
        print(f"循环依赖数: {len(self.circular_deps)}")
        
        if self.circular_deps:
            print("\n🚨 发现的循环依赖:")
            for i, cycle in enumerate(self.circular_deps, 1):
                print(f"  {i}. {' -> '.join(cycle)}")
        else:
            print("\n✅ 未发现循环依赖")
        
        # 统计导入最多的模块
        import_counts = {module: len(imports) for module, imports in self.imports.items()}
        top_imports = sorted(import_counts.items(), key=lambda x: x[1], reverse=True)[:10]
        
        print("\n📈 导入最多的模块:")
        for module, count in top_imports:
            print(f"  {module}: {count} 个导入")
    
    def suggest_fixes(self):
        """建议修复方案"""
        if not self.circular_deps:
            return
        
        print("\n🔧 修复建议:")
        print("=" * 50)
        
        for cycle in self.circular_deps:
            print(f"\n循环依赖: {' -> '.join(cycle)}")
            print("建议修复方案:")
            
            # 分析循环依赖的类型
            if len(cycle) == 2:
                print("  1. 使用延迟导入 (importlib.import_module)")
                print("  2. 重构模块结构，提取公共依赖")
                print("  3. 使用依赖注入模式")
            else:
                print("  1. 重构模块架构，减少模块间耦合")
                print("  2. 提取公共功能到独立模块")
                print("  3. 使用事件驱动架构")

def main():
    """主函数"""
    if len(sys.argv) > 1:
        project_root = sys.argv[1]
    else:
        project_root = "."
    
    print("🚀 开始导入循环依赖检查...")
    print(f"项目根目录: {project_root}")
    
    analyzer = ImportAnalyzer(project_root)
    analyzer.scan_project()
    analyzer.find_circular_dependencies()
    analyzer.generate_report()
    analyzer.suggest_fixes()
    
    if analyzer.circular_deps:
        print(f"\n❌ 发现 {len(analyzer.circular_deps)} 个循环依赖，需要修复")
        return 1
    else:
        print("\n✅ 未发现循环依赖，代码结构良好")
        return 0

if __name__ == "__main__":
    sys.exit(main())
