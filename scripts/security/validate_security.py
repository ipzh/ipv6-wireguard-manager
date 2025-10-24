#!/usr/bin/env python3
"""
安全配置验证脚本
检查项目中的安全配置是否正确
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Dict, Any

class SecurityValidator:
    """安全配置验证器"""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.issues = []
        self.warnings = []
    
    def validate_env_file(self, env_file: Path) -> List[Dict[str, Any]]:
        """验证环境配置文件"""
        issues = []
        
        if not env_file.exists():
            return [{"type": "MISSING_FILE", "file": str(env_file), "severity": "HIGH"}]
        
        try:
            with open(env_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 检查弱密码
            weak_passwords = [
                "admin123", "admin", "password", "123456", "root", 
                "test", "guest", "user", "default"
            ]
            
            for weak_pwd in weak_passwords:
                if f"PASSWORD={weak_pwd}" in content or f"PASSWORD={weak_pwd}" in content:
                    issues.append({
                        "type": "WEAK_PASSWORD",
                        "file": str(env_file),
                        "severity": "HIGH",
                        "message": f"发现弱密码: {weak_pwd}"
                    })
            
            # 检查调试模式
            if "DEBUG=true" in content and "ENVIRONMENT=production" in content:
                issues.append({
                    "type": "DEBUG_IN_PRODUCTION",
                    "file": str(env_file),
                    "severity": "HIGH",
                    "message": "生产环境不应启用调试模式"
                })
            
            # 检查密钥长度
            secret_key_match = re.search(r'SECRET_KEY=([^\s\n]+)', content)
            if secret_key_match:
                secret_key = secret_key_match.group(1)
                if len(secret_key) < 32:
                    issues.append({
                        "type": "WEAK_SECRET_KEY",
                        "file": str(env_file),
                        "severity": "HIGH",
                        "message": f"密钥长度不足: {len(secret_key)} < 32"
                    })
            
            # 检查CORS配置
            if "*" in content and "ENVIRONMENT=production" in content:
                issues.append({
                    "type": "UNSAFE_CORS",
                    "file": str(env_file),
                    "severity": "MEDIUM",
                    "message": "生产环境不应使用CORS通配符"
                })
                
        except Exception as e:
            issues.append({
                "type": "FILE_READ_ERROR",
                "file": str(env_file),
                "severity": "MEDIUM",
                "message": f"无法读取文件: {e}"
            })
        
        return issues
    
    def validate_docker_configs(self) -> List[Dict[str, Any]]:
        """验证Docker配置文件"""
        issues = []
        docker_files = [
            "docker-compose.yml",
            "docker-compose.production.yml", 
            "docker-compose.microservices.yml"
        ]
        
        for docker_file in docker_files:
            file_path = self.project_root / docker_file
            if not file_path.exists():
                continue
            
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 检查硬编码密码
                hardcoded_passwords = [
                    "password", "admin123", "rootpassword", "redis123"
                ]
                
                for pwd in hardcoded_passwords:
                    if f":{pwd}" in content or f"={pwd}" in content:
                        issues.append({
                            "type": "HARDCODED_PASSWORD",
                            "file": str(file_path),
                            "severity": "HIGH",
                            "message": f"发现硬编码密码: {pwd}"
                        })
                
                # 检查是否使用占位符
                if "CHANGE_ME" not in content and "password" in content.lower():
                    issues.append({
                        "type": "MISSING_PASSWORD_PLACEHOLDER",
                        "file": str(file_path),
                        "severity": "MEDIUM",
                        "message": "建议使用CHANGE_ME_*占位符替代硬编码密码"
                    })
                    
            except Exception as e:
                issues.append({
                    "type": "FILE_READ_ERROR",
                    "file": str(file_path),
                    "severity": "MEDIUM",
                    "message": f"无法读取文件: {e}"
                })
        
        return issues
    
    def validate_code_security(self) -> List[Dict[str, Any]]:
        """验证代码安全问题"""
        issues = []
        
        # 检查Python文件
        for py_file in self.project_root.rglob("*.py"):
            if "test" in str(py_file) or "__pycache__" in str(py_file):
                continue
            
            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 检查硬编码密码
                if re.search(r'password\s*=\s*["\'][^"\']+["\']', content, re.IGNORECASE):
                    issues.append({
                        "type": "HARDCODED_PASSWORD_IN_CODE",
                        "file": str(py_file),
                        "severity": "HIGH",
                        "message": "代码中发现硬编码密码"
                    })
                
                # 检查SQL注入风险
                if re.search(r'execute\s*\(\s*["\'][^"\']*%[^"\']*["\']', content):
                    issues.append({
                        "type": "POTENTIAL_SQL_INJECTION",
                        "file": str(py_file),
                        "severity": "HIGH",
                        "message": "可能存在SQL注入风险"
                    })
                
                # 检查敏感信息泄露
                sensitive_patterns = [
                    r'print\s*\(\s*["\'][^"\']*password[^"\']*["\']',
                    r'print\s*\(\s*["\'][^"\']*secret[^"\']*["\']',
                    r'print\s*\(\s*["\'][^"\']*key[^"\']*["\']'
                ]
                
                for pattern in sensitive_patterns:
                    if re.search(pattern, content, re.IGNORECASE):
                        issues.append({
                            "type": "SENSITIVE_INFO_LEAK",
                            "file": str(py_file),
                            "severity": "MEDIUM",
                            "message": "可能存在敏感信息泄露"
                        })
                        
            except Exception as e:
                issues.append({
                    "type": "FILE_READ_ERROR",
                    "file": str(py_file),
                    "severity": "LOW",
                    "message": f"无法读取文件: {e}"
                })
        
        return issues
    
    def run_validation(self) -> Dict[str, Any]:
        """运行完整的安全验证"""
        print("🔍 开始安全配置验证...")
        
        # 验证环境文件
        env_files = ["env.local", ".env", "env.template"]
        for env_file in env_files:
            file_path = self.project_root / env_file
            if file_path.exists():
                print(f"📄 验证文件: {env_file}")
                self.issues.extend(self.validate_env_file(file_path))
        
        # 验证Docker配置
        print("🐳 验证Docker配置文件...")
        self.issues.extend(self.validate_docker_configs())
        
        # 验证代码安全
        print("🔒 验证代码安全问题...")
        self.issues.extend(self.validate_code_security())
        
        # 分类问题
        high_issues = [i for i in self.issues if i["severity"] == "HIGH"]
        medium_issues = [i for i in self.issues if i["severity"] == "MEDIUM"]
        low_issues = [i for i in self.issues if i["severity"] == "LOW"]
        
        return {
            "total_issues": len(self.issues),
            "high_priority": len(high_issues),
            "medium_priority": len(medium_issues),
            "low_priority": len(low_issues),
            "issues": self.issues,
            "high_issues": high_issues,
            "medium_issues": medium_issues,
            "low_issues": low_issues
        }
    
    def print_report(self, results: Dict[str, Any]):
        """打印验证报告"""
        print("\n" + "="*60)
        print("🔒 安全配置验证报告")
        print("="*60)
        
        print(f"📊 总问题数: {results['total_issues']}")
        print(f"🔴 高优先级: {results['high_priority']}")
        print(f"🟡 中优先级: {results['medium_priority']}")
        print(f"🟢 低优先级: {results['low_priority']}")
        
        if results['high_issues']:
            print("\n🔴 高优先级问题:")
            for issue in results['high_issues']:
                print(f"  ❌ {issue['type']}: {issue['message']}")
                print(f"     文件: {issue['file']}")
        
        if results['medium_issues']:
            print("\n🟡 中优先级问题:")
            for issue in results['medium_issues']:
                print(f"  ⚠️  {issue['type']}: {issue['message']}")
                print(f"     文件: {issue['file']}")
        
        if results['low_issues']:
            print("\n🟢 低优先级问题:")
            for issue in results['low_issues']:
                print(f"  ℹ️  {issue['type']}: {issue['message']}")
                print(f"     文件: {issue['file']}")
        
        if results['total_issues'] == 0:
            print("\n✅ 未发现安全问题！")
        else:
            print(f"\n⚠️  发现 {results['total_issues']} 个问题需要修复")

def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="安全配置验证工具")
    parser.add_argument("--project-root", default=".", help="项目根目录")
    parser.add_argument("--output", help="输出报告文件")
    
    args = parser.parse_args()
    
    validator = SecurityValidator(args.project_root)
    results = validator.run_validation()
    validator.print_report(results)
    
    if args.output:
        import json
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        print(f"\n📄 报告已保存到: {args.output}")
    
    # 如果有高优先级问题，退出码为1
    if results['high_priority'] > 0:
        sys.exit(1)
    else:
        sys.exit(0)

if __name__ == "__main__":
    main()
