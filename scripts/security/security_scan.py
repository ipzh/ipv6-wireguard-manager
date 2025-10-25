#!/usr/bin/env python3
"""
安全扫描脚本
执行安全漏洞扫描和配置检查
"""

import os
import sys
import json
import subprocess
import re
from pathlib import Path
from typing import Dict, List, Any
import argparse

class SecurityScanner:
    """安全扫描器"""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.scan_results = {
            "timestamp": None,
            "vulnerabilities": [],
            "security_issues": [],
            "recommendations": []
        }
    
    def scan_dependencies(self) -> List[Dict[str, Any]]:
        """扫描依赖漏洞"""
        vulnerabilities = []
        
        try:
            # 检查Python依赖
            if (self.project_root / "requirements.txt").exists():
                result = subprocess.run(
                    ["safety", "check", "-r", "requirements.txt", "--json"],
                    capture_output=True,
                    text=True,
                    cwd=self.project_root
                )
                
                if result.returncode != 0:
                    try:
                        safety_results = json.loads(result.stdout)
                        for vuln in safety_results:
                            vulnerabilities.append({
                                "type": "DEPENDENCY_VULNERABILITY",
                                "severity": "HIGH",
                                "package": vuln.get("package", "unknown"),
                                "version": vuln.get("installed_version", "unknown"),
                                "vulnerability": vuln.get("vulnerability", "unknown"),
                                "description": vuln.get("description", "No description available")
                            })
                    except json.JSONDecodeError:
                        pass
            
            # 检查Node.js依赖（如果存在）
            if (self.project_root / "package.json").exists():
                result = subprocess.run(
                    ["npm", "audit", "--json"],
                    capture_output=True,
                    text=True,
                    cwd=self.project_root
                )
                
                if result.returncode != 0:
                    try:
                        npm_results = json.loads(result.stdout)
                        if "vulnerabilities" in npm_results:
                            for vuln_id, vuln_info in npm_results["vulnerabilities"].items():
                                vulnerabilities.append({
                                    "type": "NPM_VULNERABILITY",
                                    "severity": vuln_info.get("severity", "unknown").upper(),
                                    "package": vuln_info.get("name", "unknown"),
                                    "vulnerability": vuln_id,
                                    "description": vuln_info.get("description", "No description available")
                                })
                    except json.JSONDecodeError:
                        pass
        
        except FileNotFoundError:
            self.scan_results["recommendations"].append({
                "type": "TOOL_MISSING",
                "message": "安全扫描工具未安装，请安装safety和npm audit"
            })
        
        return vulnerabilities
    
    def scan_code_security(self) -> List[Dict[str, Any]]:
        """扫描代码安全问题"""
        issues = []
        
        # 扫描Python文件
        for py_file in self.project_root.rglob("*.py"):
            if "test" in str(py_file) or "__pycache__" in str(py_file):
                continue
            
            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 检查硬编码密码
                if re.search(r'password\s*=\s*["\'][^"\']+["\']', content, re.IGNORECASE):
                    issues.append({
                        "type": "HARDCODED_PASSWORD",
                        "severity": "HIGH",
                        "file": str(py_file.relative_to(self.project_root)),
                        "line": self._find_line_number(content, r'password\s*=\s*["\'][^"\']+["\']'),
                        "description": "发现硬编码密码"
                    })
                
                # 检查SQL注入风险
                if re.search(r'execute\s*\(\s*["\'][^"\']*%[^"\']*["\']', content):
                    issues.append({
                        "type": "SQL_INJECTION_RISK",
                        "severity": "MEDIUM",
                        "file": str(py_file.relative_to(self.project_root)),
                        "line": self._find_line_number(content, r'execute\s*\(\s*["\'][^"\']*%[^"\']*["\']'),
                        "description": "可能存在SQL注入风险"
                    })
                
                # 检查eval使用
                if re.search(r'\beval\s*\(', content):
                    issues.append({
                        "type": "EVAL_USAGE",
                        "severity": "HIGH",
                        "file": str(py_file.relative_to(self.project_root)),
                        "line": self._find_line_number(content, r'\beval\s*\('),
                        "description": "使用了危险的eval函数"
                    })
                
                # 检查exec使用
                if re.search(r'\bexec\s*\(', content):
                    issues.append({
                        "type": "EXEC_USAGE",
                        "severity": "HIGH",
                        "file": str(py_file.relative_to(self.project_root)),
                        "line": self._find_line_number(content, r'\bexec\s*\('),
                        "description": "使用了危险的exec函数"
                    })
                
                # 检查pickle使用
                if re.search(r'\bpickle\s*\.', content):
                    issues.append({
                        "type": "PICKLE_USAGE",
                        "severity": "MEDIUM",
                        "file": str(py_file.relative_to(self.project_root)),
                        "line": self._find_line_number(content, r'\bpickle\s*\.'),
                        "description": "使用了不安全的pickle模块"
                    })
                
                # 检查subprocess使用
                if re.search(r'subprocess\s*\.', content):
                    issues.append({
                        "type": "SUBPROCESS_USAGE",
                        "severity": "MEDIUM",
                        "file": str(py_file.relative_to(self.project_root)),
                        "line": self._find_line_number(content, r'subprocess\s*\.'),
                        "description": "使用了subprocess，需要验证输入"
                    })
            
            except Exception as e:
                issues.append({
                    "type": "SCAN_ERROR",
                    "severity": "LOW",
                    "file": str(py_file.relative_to(self.project_root)),
                    "description": f"扫描文件时出错: {e}"
                })
        
        return issues
    
    def scan_configuration_security(self) -> List[Dict[str, Any]]:
        """扫描配置安全问题"""
        issues = []
        
        # 检查环境变量文件
        env_files = [".env", "env.template", "env.example"]
        for env_file in env_files:
            env_path = self.project_root / env_file
            if env_path.exists():
                try:
                    with open(env_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # 检查硬编码密钥
                    if re.search(r'SECRET_KEY\s*=\s*["\'][^"\']+["\']', content):
                        issues.append({
                            "type": "HARDCODED_SECRET",
                            "severity": "HIGH",
                            "file": str(env_path.relative_to(self.project_root)),
                            "description": "发现硬编码密钥"
                        })
                    
                    # 检查弱密码
                    if re.search(r'PASSWORD\s*=\s*["\'](password|123456|admin)["\']', content, re.IGNORECASE):
                        issues.append({
                            "type": "WEAK_PASSWORD",
                            "severity": "HIGH",
                            "file": str(env_path.relative_to(self.project_root)),
                            "description": "发现弱密码"
                        })
                    
                    # 检查调试模式
                    if re.search(r'DEBUG\s*=\s*True', content):
                        issues.append({
                            "type": "DEBUG_MODE_ENABLED",
                            "severity": "MEDIUM",
                            "file": str(env_path.relative_to(self.project_root)),
                            "description": "生产环境不应启用调试模式"
                        })
                
                except Exception as e:
                    issues.append({
                        "type": "SCAN_ERROR",
                        "severity": "LOW",
                        "file": str(env_path.relative_to(self.project_root)),
                        "description": f"扫描配置文件时出错: {e}"
                    })
        
        # 检查Docker配置
        docker_files = ["Dockerfile", "docker-compose.yml", "docker-compose.production.yml"]
        for docker_file in docker_files:
            docker_path = self.project_root / docker_file
            if docker_path.exists():
                try:
                    with open(docker_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # 检查以root用户运行
                    if re.search(r'USER\s+root', content):
                        issues.append({
                            "type": "ROOT_USER",
                            "severity": "MEDIUM",
                            "file": str(docker_path.relative_to(self.project_root)),
                            "description": "容器以root用户运行，存在安全风险"
                        })
                    
                    # 检查暴露的端口
                    if re.search(r'EXPOSE\s+\d+', content):
                        issues.append({
                            "type": "EXPOSED_PORTS",
                            "severity": "LOW",
                            "file": str(docker_path.relative_to(self.project_root)),
                            "description": "检查暴露的端口是否必要"
                        })
                
                except Exception as e:
                    issues.append({
                        "type": "SCAN_ERROR",
                        "severity": "LOW",
                        "file": str(docker_path.relative_to(self.project_root)),
                        "description": f"扫描Docker文件时出错: {e}"
                    })
        
        return issues
    
    def scan_file_permissions(self) -> List[Dict[str, Any]]:
        """扫描文件权限"""
        issues = []
        
        # 检查敏感文件权限
        sensitive_files = [
            ".env",
            "config.json",
            "*.key",
            "*.pem",
            "*.crt"
        ]
        
        for pattern in sensitive_files:
            for file_path in self.project_root.rglob(pattern):
                try:
                    stat = file_path.stat()
                    mode = oct(stat.st_mode)[-3:]
                    
                    # 检查文件权限是否过于宽松
                    if int(mode) > 644:  # 644 = rw-r--r--
                        issues.append({
                            "type": "INSECURE_PERMISSIONS",
                            "severity": "MEDIUM",
                            "file": str(file_path.relative_to(self.project_root)),
                            "permissions": mode,
                            "description": f"文件权限过于宽松: {mode}"
                        })
                
                except Exception as e:
                    issues.append({
                        "type": "PERMISSION_CHECK_ERROR",
                        "severity": "LOW",
                        "file": str(file_path.relative_to(self.project_root)),
                        "description": f"检查文件权限时出错: {e}"
                    })
        
        return issues
    
    def _find_line_number(self, content: str, pattern: str) -> int:
        """查找模式在内容中的行号"""
        lines = content.split('\n')
        for i, line in enumerate(lines, 1):
            if re.search(pattern, line):
                return i
        return 0
    
    def generate_security_report(self) -> Dict[str, Any]:
        """生成安全报告"""
        import datetime
        
        self.scan_results["timestamp"] = datetime.datetime.now().isoformat()
        
        # 执行各种扫描
        self.scan_results["vulnerabilities"] = self.scan_dependencies()
        self.scan_results["security_issues"] = (
            self.scan_code_security() +
            self.scan_configuration_security() +
            self.scan_file_permissions()
        )
        
        # 生成建议
        self._generate_recommendations()
        
        return self.scan_results
    
    def _generate_recommendations(self):
        """生成安全建议"""
        recommendations = []
        
        # 基于扫描结果生成建议
        if any(issue["type"] == "HARDCODED_PASSWORD" for issue in self.scan_results["security_issues"]):
            recommendations.append({
                "type": "SECURITY_HARDENING",
                "priority": "HIGH",
                "title": "移除硬编码密码",
                "description": "将所有硬编码密码移动到环境变量或安全的配置文件中"
            })
        
        if any(issue["type"] == "DEPENDENCY_VULNERABILITY" for issue in self.scan_results["vulnerabilities"]):
            recommendations.append({
                "type": "DEPENDENCY_UPDATE",
                "priority": "HIGH",
                "title": "更新依赖包",
                "description": "更新存在安全漏洞的依赖包到最新版本"
            })
        
        if any(issue["type"] == "DEBUG_MODE_ENABLED" for issue in self.scan_results["security_issues"]):
            recommendations.append({
                "type": "PRODUCTION_CONFIG",
                "priority": "MEDIUM",
                "title": "禁用调试模式",
                "description": "在生产环境中禁用调试模式"
            })
        
        # 通用安全建议
        recommendations.extend([
            {
                "type": "SECURITY_HEADERS",
                "priority": "MEDIUM",
                "title": "添加安全头",
                "description": "在HTTP响应中添加安全头，如X-Content-Type-Options、X-Frame-Options等"
            },
            {
                "type": "HTTPS_ENFORCEMENT",
                "priority": "HIGH",
                "title": "强制HTTPS",
                "description": "在生产环境中强制使用HTTPS"
            },
            {
                "type": "INPUT_VALIDATION",
                "priority": "HIGH",
                "title": "输入验证",
                "description": "对所有用户输入进行验证和清理"
            },
            {
                "type": "AUTHENTICATION",
                "priority": "HIGH",
                "title": "强化认证",
                "description": "实施强密码策略、多因素认证和会话管理"
            }
        ])
        
        self.scan_results["recommendations"] = recommendations

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="安全扫描工具")
    parser.add_argument("--project-root", default=".", help="项目根目录")
    parser.add_argument("--output", help="输出文件路径")
    parser.add_argument("--format", choices=["json", "html", "text"], default="json", help="输出格式")
    
    args = parser.parse_args()
    
    # 创建扫描器
    scanner = SecurityScanner(args.project_root)
    
    # 执行扫描
    print("🔍 开始安全扫描...")
    report = scanner.generate_security_report()
    
    # 输出结果
    if args.output:
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        if args.format == "json":
            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump(report, f, indent=2, ensure_ascii=False)
        elif args.format == "html":
            # 生成HTML报告
            html_content = generate_html_report(report)
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(html_content)
        else:
            # 生成文本报告
            text_content = generate_text_report(report)
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(text_content)
        
        print(f"📄 安全报告已保存到: {output_path}")
    else:
        # 控制台输出
        print_security_summary(report)
    
    # 返回退出码
    high_severity_count = sum(1 for issue in report["security_issues"] if issue["severity"] == "HIGH")
    if high_severity_count > 0:
        print(f"⚠️ 发现 {high_severity_count} 个高危安全问题")
        return 1
    else:
        print("✅ 未发现高危安全问题")
        return 0

def generate_html_report(report: Dict[str, Any]) -> str:
    """生成HTML报告"""
    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>安全扫描报告</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 20px; }}
            .header {{ background-color: #f0f0f0; padding: 20px; border-radius: 5px; }}
            .section {{ margin: 20px 0; }}
            .vulnerability {{ background-color: #ffebee; padding: 10px; margin: 5px 0; border-radius: 3px; }}
            .issue {{ background-color: #fff3e0; padding: 10px; margin: 5px 0; border-radius: 3px; }}
            .recommendation {{ background-color: #e8f5e8; padding: 10px; margin: 5px 0; border-radius: 3px; }}
            .high {{ border-left: 5px solid #f44336; }}
            .medium {{ border-left: 5px solid #ff9800; }}
            .low {{ border-left: 5px solid #4caf50; }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>安全扫描报告</h1>
            <p>扫描时间: {report['timestamp']}</p>
        </div>
        
        <div class="section">
            <h2>漏洞统计</h2>
            <p>发现漏洞: {len(report['vulnerabilities'])} 个</p>
            <p>安全问题: {len(report['security_issues'])} 个</p>
            <p>安全建议: {len(report['recommendations'])} 个</p>
        </div>
        
        <div class="section">
            <h2>依赖漏洞</h2>
            {''.join([f'<div class="vulnerability {vuln["severity"].lower()}"><strong>{vuln["package"]}</strong>: {vuln["description"]}</div>' for vuln in report['vulnerabilities']])}
        </div>
        
        <div class="section">
            <h2>安全问题</h2>
            {''.join([f'<div class="issue {issue["severity"].lower()}"><strong>{issue["type"]}</strong> ({issue["file"]}): {issue["description"]}</div>' for issue in report['security_issues']])}
        </div>
        
        <div class="section">
            <h2>安全建议</h2>
            {''.join([f'<div class="recommendation"><strong>{rec["title"]}</strong>: {rec["description"]}</div>' for rec in report['recommendations']])}
        </div>
    </body>
    </html>
    """
    return html

def generate_text_report(report: Dict[str, Any]) -> str:
    """生成文本报告"""
    text = f"""
安全扫描报告
============

扫描时间: {report['timestamp']}

漏洞统计:
- 依赖漏洞: {len(report['vulnerabilities'])} 个
- 安全问题: {len(report['security_issues'])} 个
- 安全建议: {len(report['recommendations'])} 个

依赖漏洞:
{chr(10).join([f"- {vuln['package']}: {vuln['description']}" for vuln in report['vulnerabilities']])}

安全问题:
{chr(10).join([f"- {issue['type']} ({issue['file']}): {issue['description']}" for issue in report['security_issues']])}

安全建议:
{chr(10).join([f"- {rec['title']}: {rec['description']}" for rec in report['recommendations']])}
"""
    return text

def print_security_summary(report: Dict[str, Any]):
    """打印安全摘要"""
    print(f"\n📊 安全扫描摘要")
    print(f"扫描时间: {report['timestamp']}")
    print(f"依赖漏洞: {len(report['vulnerabilities'])} 个")
    print(f"安全问题: {len(report['security_issues'])} 个")
    print(f"安全建议: {len(report['recommendations'])} 个")
    
    # 按严重性统计
    severity_counts = {}
    for issue in report['security_issues']:
        severity = issue['severity']
        severity_counts[severity] = severity_counts.get(severity, 0) + 1
    
    if severity_counts:
        print(f"\n严重性分布:")
        for severity, count in severity_counts.items():
            print(f"  {severity}: {count} 个")

if __name__ == "__main__":
    sys.exit(main())
