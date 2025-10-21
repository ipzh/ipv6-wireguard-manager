#!/usr/bin/env python3
"""
文档一致性检查脚本
检查文档中引用的文件是否真实存在
"""
import os
import re
from pathlib import Path
from typing import List, Dict, Set

class DocsConsistencyChecker:
    """文档一致性检查器"""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.missing_files: Set[str] = set()
        self.missing_links: Set[str] = set()
        self.invalid_refs: Set[str] = set()
    
    def check_markdown_files(self) -> Dict[str, List[str]]:
        """检查Markdown文件中的链接和引用"""
        results = {
            "missing_files": [],
            "missing_links": [],
            "invalid_refs": []
        }
        
        # 查找所有Markdown文件
        md_files = list(self.project_root.rglob("*.md"))
        
        for md_file in md_files:
            print(f"检查文件: {md_file.relative_to(self.project_root)}")
            
            try:
                with open(md_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 检查文件链接
                file_links = re.findall(r'\[([^\]]+)\]\(([^)]+)\)', content)
                for link_text, link_path in file_links:
                    if not link_path.startswith('http'):
                        # 相对路径链接
                        if link_path.startswith('./'):
                            full_path = md_file.parent / link_path[2:]
                        elif link_path.startswith('/'):
                            full_path = self.project_root / link_path[1:]
                        else:
                            full_path = md_file.parent / link_path
                        
                        if not full_path.exists():
                            results["missing_files"].append(f"{md_file}: {link_path}")
                            self.missing_files.add(link_path)
                
                # 检查文档引用
                doc_refs = re.findall(r'PRODUCTION_DEPLOYMENT_GUIDE\.md|API_REFERENCE\.md|DEPLOYMENT_CONFIG\.md|CLI_MANAGEMENT_GUIDE\.md|API_INTEGRATION_SUMMARY\.md|INSTALL_SCRIPT_AUDIT_REPORT\.md', content)
                for ref in doc_refs:
                    if not (self.project_root / ref).exists():
                        results["invalid_refs"].append(f"{md_file}: {ref}")
                        self.invalid_refs.add(ref)
                
            except Exception as e:
                print(f"❌ 读取文件失败 {md_file}: {e}")
        
        return results
    
    def check_docker_compose_refs(self) -> List[str]:
        """检查Docker Compose文件中的引用"""
        issues = []
        
        # 检查docker-compose.yml中的挂载
        compose_file = self.project_root / "docker-compose.yml"
        if compose_file.exists():
            with open(compose_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 检查挂载的文件是否存在
            mount_patterns = [
                r'\./redis/redis\.conf',
                r'\./nginx/nginx\.conf',
                r'\./nginx/sites-available',
                r'\./nginx/ssl'
            ]
            
            for pattern in mount_patterns:
                if re.search(pattern, content):
                    mount_path = self.project_root / pattern[2:]  # 去掉 ./
                    if not mount_path.exists():
                        issues.append(f"docker-compose.yml 挂载的文件不存在: {pattern}")
        
        return issues
    
    def check_readme_consistency(self) -> List[str]:
        """检查README文件的一致性"""
        issues = []
        
        readme_file = self.project_root / "README.md"
        if readme_file.exists():
            with open(readme_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 检查提到的文件
            mentioned_files = [
                "docker-compose.microservices.yml",
                "PRODUCTION_DEPLOYMENT_GUIDE.md",
                "API_REFERENCE.md"
            ]
            
            for file_name in mentioned_files:
                if file_name in content:
                    if not (self.project_root / file_name).exists():
                        issues.append(f"README.md 中提到的文件不存在: {file_name}")
        
        return issues
    
    def generate_report(self) -> str:
        """生成检查报告"""
        report = []
        report.append("# 文档一致性检查报告")
        report.append("")
        
        # 检查Markdown文件
        md_results = self.check_markdown_files()
        if md_results["missing_files"]:
            report.append("## 缺失的文件链接")
            for item in md_results["missing_files"]:
                report.append(f"- {item}")
            report.append("")
        
        if md_results["invalid_refs"]:
            report.append("## 无效的文档引用")
            for item in md_results["invalid_refs"]:
                report.append(f"- {item}")
            report.append("")
        
        # 检查Docker Compose引用
        docker_issues = self.check_docker_compose_refs()
        if docker_issues:
            report.append("## Docker Compose 引用问题")
            for issue in docker_issues:
                report.append(f"- {issue}")
            report.append("")
        
        # 检查README一致性
        readme_issues = self.check_readme_consistency()
        if readme_issues:
            report.append("## README 一致性问题")
            for issue in readme_issues:
                report.append(f"- {issue}")
            report.append("")
        
        # 总结
        total_issues = len(md_results["missing_files"]) + len(md_results["invalid_refs"]) + len(docker_issues) + len(readme_issues)
        report.append(f"## 总结")
        report.append(f"发现 {total_issues} 个一致性问题")
        
        if total_issues == 0:
            report.append("✅ 所有文档引用都是一致的！")
        else:
            report.append("❌ 需要修复上述问题以保持文档一致性")
        
        return "\n".join(report)

def main():
    """主函数"""
    project_root = Path(__file__).parent.parent
    
    print("🔍 开始检查文档一致性...")
    
    checker = DocsConsistencyChecker(project_root)
    report = checker.generate_report()
    
    # 保存报告
    report_file = project_root / "DOCS_CONSISTENCY_REPORT.md"
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(report)
    
    print(f"📄 检查报告已保存到: {report_file}")
    print("\n" + "="*50)
    print(report)

if __name__ == "__main__":
    main()
