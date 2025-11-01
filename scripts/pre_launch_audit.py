#!/usr/bin/env python3
"""
项目上线前全面审查脚本
技术总监级别的质量检查工具
"""
import os
import sys
import json
import subprocess
import importlib.util
import ast
from pathlib import Path
from typing import Dict, List, Tuple, Any
from datetime import datetime
from dataclasses import dataclass, asdict
from collections import defaultdict

# 添加项目根目录到路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root / "backend"))

@dataclass
class Issue:
    """问题记录"""
    category: str
    severity: str  # critical, high, medium, low
    file_path: str
    line: int = 0
    message: str = ""
    suggestion: str = ""

@dataclass
class AuditResult:
    """审查结果"""
    category: str
    total_issues: int
    critical: int = 0
    high: int = 0
    medium: int = 0
    low: int = 0
    issues: List[Issue] = None
    
    def __post_init__(self):
        if self.issues is None:
            self.issues = []

class PreLaunchAuditor:
    """上线前审查器"""
    
    def __init__(self):
        self.project_root = project_root
        self.backend_root = project_root / "backend"
        self.frontend_root = project_root / "php-frontend"
        self.results: Dict[str, AuditResult] = {}
        self.summary: Dict[str, Any] = {
            "total_files_checked": 0,
            "total_issues": 0,
            "by_category": {}
        }
        
    def log(self, level: str, message: str):
        """日志输出"""
        colors = {
            "INFO": "\033[94m",
            "SUCCESS": "\033[92m",
            "WARNING": "\033[93m",
            "ERROR": "\033[91m",
            "RESET": "\033[0m"
        }
        print(f"{colors.get(level, '')}[{level}]{colors['RESET']} {message}")
    
    def check_imports_and_dependencies(self):
        """检查导入和依赖问题"""
        self.log("INFO", "检查导入和依赖问题...")
        issues = []
        
        # 检查Python依赖
        requirements_files = [
            "requirements.txt",
            "requirements-production.txt",
            "requirements-minimal.txt",
            "requirements-simple.txt"
        ]
        
        for req_file in requirements_files:
            req_path = self.backend_root / req_file
            if req_path.exists():
                self.log("INFO", f"检查 {req_file}...")
                try:
                    with open(req_path, 'r', encoding='utf-8') as f:
                        for line_num, line in enumerate(f, 1):
                            line = line.strip()
                            if line and not line.startswith('#'):
                                # 检查依赖版本格式
                                if '==' not in line and '>=' not in line and '~=' not in line:
                                    if not line.startswith('-e '):
                                        issues.append(Issue(
                                            category="依赖管理",
                                            severity="low",
                                            file_path=str(req_path.relative_to(self.project_root)),
                                            line=line_num,
                                            message=f"依赖项缺少版本约束: {line}",
                                            suggestion="建议添加版本约束以确保可重复安装"
                                        ))
                except Exception as e:
                    issues.append(Issue(
                        category="依赖管理",
                        severity="high",
                        file_path=str(req_path.relative_to(self.project_root)),
                        message=f"无法读取依赖文件: {e}",
                        suggestion="检查文件权限和编码"
                    ))
        
        # 检查后端API导入
        self.log("INFO", "检查后端API导入...")
        api_dir = self.backend_root / "app" / "api"
        if api_dir.exists():
            for py_file in api_dir.rglob("*.py"):
                if py_file.name == "__init__.py":
                    continue
                
                try:
                    with open(py_file, 'r', encoding='utf-8') as f:
                        content = f.read()
                        tree = ast.parse(content, filename=str(py_file))
                        
                        # 检查导入语句
                        for node in ast.walk(tree):
                            if isinstance(node, (ast.Import, ast.ImportFrom)):
                                if isinstance(node, ast.ImportFrom):
                                    if node.module and node.module.startswith('app.'):
                                        # 检查相对导入路径是否正确
                                        full_path = py_file.relative_to(self.backend_root / "app")
                                        module_parts = full_path.parts
                                        depth = len([p for p in module_parts[:-1] if p != "__init__.py"])
                                        
                                        # 验证相对导入层次
                                        if depth > 0:
                                            expected_dots = depth
                                            actual_dots = len(node.level)
                                            if actual_dots != expected_dots:
                                                issues.append(Issue(
                                                    category="导入问题",
                                                    severity="critical",
                                                    file_path=str(py_file.relative_to(self.project_root)),
                                                    line=node.lineno,
                                                    message=f"相对导入层次不匹配，应有{expected_dots}个点，实际{actual_dots}个",
                                                    suggestion=f"修正为: {'.' * expected_dots}...{node.module}"
                                                ))
                except SyntaxError as e:
                    issues.append(Issue(
                        category="语法错误",
                        severity="critical",
                        file_path=str(py_file.relative_to(self.project_root)),
                        line=e.lineno or 0,
                        message=f"Python语法错误: {e.msg}",
                        suggestion="修复语法错误"
                    ))
                except Exception as e:
                    issues.append(Issue(
                        category="导入检查",
                        severity="medium",
                        file_path=str(py_file.relative_to(self.project_root)),
                        message=f"无法检查导入: {e}",
                        suggestion="手动检查文件"
                    ))
        
        self.results["导入和依赖"] = AuditResult(
            category="导入和依赖",
            total_issues=len(issues),
            issues=issues
        )
        self._update_summary(issues)
        
    def check_linux_compatibility(self):
        """检查Linux兼容性"""
        self.log("INFO", "检查Linux兼容性...")
        issues = []
        
        # 检查路径分隔符
        script_files = list(self.project_root.rglob("*.sh"))
        self.log("INFO", f"检查 {len(script_files)} 个Shell脚本...")
        
        for script_file in script_files:
            try:
                with open(script_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                    # 检查Windows路径
                    if '\\' in content and not content.count('\\\\') > 0:
                        # 可能包含Windows路径
                        for line_num, line in enumerate(content.split('\n'), 1):
                            if '\\' in line and not line.strip().startswith('#'):
                                if any(pattern in line for pattern in ['C:\\', 'D:\\', 'mkdir -p', 'rm -rf']):
                                    # 可能是跨平台问题
                                    issues.append(Issue(
                                        category="Linux兼容性",
                                        severity="medium",
                                        file_path=str(script_file.relative_to(self.project_root)),
                                        line=line_num,
                                        message="可能包含Windows路径分隔符",
                                        suggestion="使用正斜杠/或os.path.join"
                                    ))
                    
                    # 检查shebang
                    if not content.startswith('#!/'):
                        issues.append(Issue(
                            category="Linux兼容性",
                            severity="low",
                            file_path=str(script_file.relative_to(self.project_root)),
                            message="缺少shebang行",
                            suggestion="添加 #!/bin/bash 或 #!/usr/bin/env bash"
                        ))
                    
                    # 检查set -e
                    lines = content.split('\n')
                    has_set_e = any('set -e' in line or 'set -o errexit' in line 
                                   for line in lines[:10])
                    if not has_set_e:
                        issues.append(Issue(
                            category="Linux兼容性",
                            severity="medium",
                            file_path=str(script_file.relative_to(self.project_root)),
                            message="缺少错误处理设置",
                            suggestion="在脚本开头添加 'set -e'"
                        ))
                        
            except Exception as e:
                issues.append(Issue(
                    category="Linux兼容性",
                    severity="medium",
                    file_path=str(script_file.relative_to(self.project_root)),
                    message=f"无法读取脚本: {e}",
                    suggestion="检查文件权限和编码"
                ))
        
        self.results["Linux兼容性"] = AuditResult(
            category="Linux兼容性",
            total_issues=len(issues),
            issues=issues
        )
        self._update_summary(issues)
    
    def check_nginx_config(self):
        """检查Nginx配置"""
        self.log("INFO", "检查Nginx配置...")
        issues = []
        
        nginx_configs = [
            self.project_root / "nginx",
            self.project_root / "backend" / "nginx",
        ]
        
        for nginx_dir in nginx_configs:
            if nginx_dir.exists():
                for conf_file in nginx_dir.rglob("*.conf"):
                    try:
                        with open(conf_file, 'r', encoding='utf-8') as f:
                            content = f.read()
                            
                            # 检查基本配置
                            if 'listen' not in content and 'server{' in content:
                                issues.append(Issue(
                                    category="Nginx配置",
                                    severity="high",
                                    file_path=str(conf_file.relative_to(self.project_root)),
                                    message="缺少listen指令",
                                    suggestion="添加 listen 80 或 listen 443 指令"
                                ))
                            
                            # 检查安全头
                            if 'location' in content and 'X-Frame-Options' not in content:
                                issues.append(Issue(
                                    category="Nginx配置",
                                    severity="medium",
                                    file_path=str(conf_file.relative_to(self.project_root)),
                                    message="缺少安全头配置",
                                    suggestion="添加安全HTTP头配置"
                                ))
                                
                    except Exception as e:
                        issues.append(Issue(
                            category="Nginx配置",
                            severity="medium",
                            file_path=str(conf_file.relative_to(self.project_root)),
                            message=f"无法读取配置: {e}",
                            suggestion="检查文件权限"
                        ))
        
        self.results["Nginx配置"] = AuditResult(
            category="Nginx配置",
            total_issues=len(issues),
            issues=issues
        )
        self._update_summary(issues)
    
    def check_permissions(self):
        """检查权限配置"""
        self.log("INFO", "检查权限配置...")
        issues = []
        
        # 检查安装脚本中的权限设置
        install_script = self.project_root / "install.sh"
        if install_script.exists():
            try:
                with open(install_script, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                    # 检查是否有chmod设置
                    if 'chmod' in content:
                        # 检查是否有危险的权限设置
                        for line_num, line in enumerate(content.split('\n'), 1):
                            if 'chmod 777' in line:
                                issues.append(Issue(
                                    category="权限配置",
                                    severity="critical",
                                    file_path="install.sh",
                                    line=line_num,
                                    message="使用了极度危险的777权限",
                                    suggestion="使用最小权限原则，如755或750"
                                ))
                            elif 'chmod 666' in line:
                                issues.append(Issue(
                                    category="权限配置",
                                    severity="high",
                                    file_path="install.sh",
                                    line=line_num,
                                    message="使用了过于宽松的666权限",
                                    suggestion="考虑使用640或600"
                                ))
            except Exception as e:
                issues.append(Issue(
                    category="权限配置",
                    severity="medium",
                    file_path="install.sh",
                    message=f"无法检查权限配置: {e}",
                    suggestion="手动检查"
                ))
        
        self.results["权限配置"] = AuditResult(
            category="权限配置",
            total_issues=len(issues),
            issues=issues
        )
        self._update_summary(issues)
    
    def check_security(self):
        """安全检查"""
        self.log("INFO", "进行安全检查...")
        issues = []
        
        # 检查后端Python代码
        backend_dir = self.backend_root / "app"
        if backend_dir.exists():
            for py_file in backend_dir.rglob("*.py"):
                try:
                    with open(py_file, 'r', encoding='utf-8') as f:
                        content = f.read()
                        lines = content.split('\n')
                        
                        # 检查硬编码密码
                        for line_num, line in enumerate(lines, 1):
                            if any(keyword in line.lower() for keyword in 
                                  ['password', 'secret', 'token', 'api_key']):
                                # 检查是否是硬编码
                                if '=' in line and not any(env in line for env in 
                                  ['getenv', 'environ', 'settings', 'config']):
                                    if any(char in line for char in ['"', "'"]):
                                        # 可能是硬编码
                                        if not line.strip().startswith('#'):
                                            issues.append(Issue(
                                                category="安全",
                                                severity="critical",
                                                file_path=str(py_file.relative_to(self.project_root)),
                                                line=line_num,
                                                message="可能包含硬编码的敏感信息",
                                                suggestion="使用环境变量或配置文件"
                                            ))
                        
                        # 检查SQL注入风险
                        if 'execute(' in content or 'exec(' in content:
                            for line_num, line in enumerate(lines, 1):
                                if ('execute(' in line or 'exec(' in line) and '+' in line:
                                    if not line.strip().startswith('#'):
                                        issues.append(Issue(
                                            category="安全",
                                            severity="high",
                                            file_path=str(py_file.relative_to(self.project_root)),
                                            line=line_num,
                                            message="可能存在SQL注入风险",
                                            suggestion="使用参数化查询"
                                        ))
                        
                        # 检查eval
                        if 'eval(' in content:
                            for line_num, line in enumerate(lines, 1):
                                if 'eval(' in line:
                                    issues.append(Issue(
                                        category="安全",
                                        severity="critical",
                                        file_path=str(py_file.relative_to(self.project_root)),
                                        line=line_num,
                                        message="使用了eval()函数，存在安全风险",
                                        suggestion="使用更安全的替代方案"
                                    ))
                        
                except Exception as e:
                    pass  # 忽略读取错误
        
        # 检查PHP前端
        frontend_dir = self.frontend_root
        if frontend_dir.exists():
            for php_file in frontend_dir.rglob("*.php"):
                try:
                    with open(php_file, 'r', encoding='utf-8') as f:
                        content = f.read()
                        lines = content.split('\n')
                        
                        # 检查eval
                        for line_num, line in enumerate(lines, 1):
                            if 'eval(' in line or 'eval($_' in line:
                                issues.append(Issue(
                                    category="安全",
                                    severity="critical",
                                    file_path=str(php_file.relative_to(self.project_root)),
                                    line=line_num,
                                    message="使用了eval()函数",
                                    suggestion="移除eval()函数调用"
                                ))
                        
                        # 检查文件包含
                        for line_num, line in enumerate(lines, 1):
                            if ('include' in line or 'require' in line) and '$_GET' in line:
                                issues.append(Issue(
                                    category="安全",
                                    severity="high",
                                    file_path=str(php_file.relative_to(self.project_root)),
                                    line=line_num,
                                    message="可能存在文件包含漏洞",
                                    suggestion="验证文件路径"
                                ))
                except Exception as e:
                    pass
        
        self.results["安全"] = AuditResult(
            category="安全",
            total_issues=len(issues),
            issues=issues
        )
        self._update_summary(issues)
    
    def check_documentation(self):
        """检查文档"""
        self.log("INFO", "检查文档完整性...")
        issues = []
        
        required_docs = [
            "README.md",
            "docs/INSTALLATION_GUIDE.md",
            "docs/DEPLOYMENT_GUIDE.md",
            "docs/API_REFERENCE.md",
            "docs/TROUBLESHOOTING_GUIDE.md"
        ]
        
        for doc_path in required_docs:
            full_path = self.project_root / doc_path
            if not full_path.exists():
                issues.append(Issue(
                    category="文档",
                    severity="medium",
                    file_path=doc_path,
                    message="缺少必需文档",
                    suggestion=f"创建 {doc_path} 文档"
                ))
            else:
                # 检查文档大小
                size = full_path.stat().st_size
                if size < 1000:  # 小于1KB
                    issues.append(Issue(
                        category="文档",
                        severity="low",
                        file_path=doc_path,
                        message="文档内容可能过少",
                        suggestion="补充更多详细信息"
                    ))
        
        self.results["文档"] = AuditResult(
            category="文档",
            total_issues=len(issues),
            issues=issues
        )
        self._update_summary(issues)
    
    def _update_summary(self, issues: List[Issue]):
        """更新摘要"""
        if not issues:
            return
        
        for issue in issues:
            self.summary["total_issues"] += 1
            if issue.category not in self.summary["by_category"]:
                self.summary["by_category"][issue.category] = {
                    "critical": 0,
                    "high": 0,
                    "medium": 0,
                    "low": 0
                }
            
            result = self.results.get(issue.category)
            if result:
                if issue.severity == "critical":
                    result.critical += 1
                    self.summary["by_category"][issue.category]["critical"] += 1
                elif issue.severity == "high":
                    result.high += 1
                    self.summary["by_category"][issue.category]["high"] += 1
                elif issue.severity == "medium":
                    result.medium += 1
                    self.summary["by_category"][issue.category]["medium"] += 1
                else:
                    result.low += 1
                    self.summary["by_category"][issue.category]["low"] += 1
    
    def generate_report(self) -> str:
        """生成报告"""
        report_lines = []
        report_lines.append("=" * 80)
        report_lines.append("项目上线前审查报告")
        report_lines.append(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report_lines.append("=" * 80)
        report_lines.append("")
        
        # 摘要
        report_lines.append("📊 审查摘要")
        report_lines.append("-" * 80)
        report_lines.append(f"总问题数: {self.summary['total_issues']}")
        report_lines.append("")
        
        # 按严重程度
        total_critical = sum(r.critical for r in self.results.values())
        total_high = sum(r.high for r in self.results.values())
        total_medium = sum(r.medium for r in self.results.values())
        total_low = sum(r.low for r in self.results.values())
        
        report_lines.append(f"严重程度分布:")
        report_lines.append(f"  🔴 严重: {total_critical}")
        report_lines.append(f"  🟠 高:   {total_high}")
        report_lines.append(f"  🟡 中:   {total_medium}")
        report_lines.append(f"  🟢 低:   {total_low}")
        report_lines.append("")
        
        # 按类别
        report_lines.append("按类别统计:")
        for category, counts in self.summary["by_category"].items():
            total = sum(counts.values())
            report_lines.append(f"  {category}: {total} 个问题")
        report_lines.append("")
        report_lines.append("=" * 80)
        report_lines.append("")
        
        # 详细问题
        report_lines.append("📋 详细问题列表")
        report_lines.append("=" * 80)
        
        for category, result in self.results.items():
            if result.issues:
                report_lines.append("")
                report_lines.append(f"### {category} ({len(result.issues)} 个问题)")
                report_lines.append("")
                
                # 按严重程度排序
                sorted_issues = sorted(result.issues, key=lambda x: (
                    x.severity == "critical",
                    x.severity == "high",
                    x.severity == "medium",
                    x.severity == "low"
                ))
                
                for issue in sorted_issues:
                    severity_icon = {
                        "critical": "🔴",
                        "high": "🟠",
                        "medium": "🟡",
                        "low": "🟢"
                    }.get(issue.severity, "⚪")
                    
                    report_lines.append(f"{severity_icon} [{issue.severity.upper()}] {issue.file_path}")
                    if issue.line:
                        report_lines.append(f"   第 {issue.line} 行")
                    report_lines.append(f"   {issue.message}")
                    if issue.suggestion:
                        report_lines.append(f"   💡 建议: {issue.suggestion}")
                    report_lines.append("")
        
        report_lines.append("")
        report_lines.append("=" * 80)
        report_lines.append("审查完成")
        
        return "\n".join(report_lines)
    
    def run(self):
        """运行完整审查"""
        self.log("INFO", "开始项目上线前全面审查...")
        self.log("INFO", "")
        
        try:
            self.check_imports_and_dependencies()
            self.check_linux_compatibility()
            self.check_nginx_config()
            self.check_permissions()
            self.check_security()
            self.check_documentation()
            
            self.log("INFO", "")
            self.log("SUCCESS", "审查完成！")
            
            # 生成报告
            report = self.generate_report()
            print("\n" + report)
            
            # 保存报告
            report_file = self.project_root / "AUDIT_REPORT.txt"
            with open(report_file, 'w', encoding='utf-8') as f:
                f.write(report)
            
            self.log("SUCCESS", f"报告已保存到: {report_file}")
            
            # 返回状态码
            if self.summary["total_issues"] == 0:
                return 0
            elif any(r.critical > 0 for r in self.results.values()):
                return 2  # 有严重问题
            else:
                return 1  # 有问题但可修复
        
        except Exception as e:
            self.log("ERROR", f"审查过程中发生错误: {e}")
            import traceback
            traceback.print_exc()
            return 1

if __name__ == "__main__":
    auditor = PreLaunchAuditor()
    sys.exit(auditor.run())

