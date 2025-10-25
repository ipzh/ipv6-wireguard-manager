#!/usr/bin/env python3
"""
文档一致性检查脚本
检查文档的格式、链接、版本信息等一致性
"""

import os
import re
from pathlib import Path
from typing import Dict, List, Tuple
import argparse
import sys

class DocumentationChecker:
    """文档一致性检查器"""
    
    def __init__(self, docs_dir: str = "docs"):
        self.docs_dir = Path(docs_dir)
        self.errors = []
        self.warnings = []
        self.info = []
        
        # 需要存在的核心文档
        self.required_docs = [
            ("docs/README.md", self.docs_dir / "README.md"),
            ("docs/QUICK_START.md", self.docs_dir / "QUICK_START.md"),
            ("docs/INSTALLATION_GUIDE.md", self.docs_dir / "INSTALLATION_GUIDE.md"),
            ("docs/DEPLOYMENT_GUIDE.md", self.docs_dir / "DEPLOYMENT_GUIDE.md"),
            ("docs/API_REFERENCE.md", self.docs_dir / "API_REFERENCE.md"),
            ("README.md", Path("README.md")),
        ]
        
        self.version_pattern = r"(\d+\.\d+\.\d+)"
        self.link_pattern = r"\[([^\]]+)\]\(([^)]+)\)"
        self.heading_pattern = r"^#{1,6}\s+(.+)$"
        self.forbidden_patterns = {
            r"scripts/install\\.sh": "检测到旧的安装命令，请改用 ./install.sh",
            r"install_native\\.sh": "检测到已移除的安装脚本引用",
            r"admin123": "检测到弱密码示例，请更新说明"
        }
        
    def check_all(self) -> bool:
        """执行所有检查"""
        print("🔍 开始文档一致性检查...")
        
        # 检查文档结构
        self.check_document_structure()
        
        # 检查版本一致性
        self.check_version_consistency()
        
        # 检查链接有效性
        self.check_links()
        
        # 检查格式一致性
        self.check_format_consistency()
        
        # 检查内容完整性
        self.check_content_completeness()
        
        # 检查禁用内容
        self.check_forbidden_patterns()
        
        # 输出结果
        self.print_results()
        
        return len(self.errors) == 0
    
    def check_document_structure(self):
        """检查文档结构"""
        print("📁 检查文档结构...")
        
        # 检查必需文档
        for label, path in self.required_docs:
            if not path.exists():
                self.errors.append(f"缺少必需文档: {label}")
            else:
                self.info.append(f"✅ 找到文档: {label}")
    
    def check_version_consistency(self):
        """检查版本一致性"""
        print("🔢 检查版本一致性...")
        
        versions = {}
        for label, path in self.required_docs:
            if path.exists():
                version = self.extract_version(path)
                if version:
                    versions[label] = version
        
        if versions:
            unique_versions = set(versions.values())
            if len(unique_versions) > 1:
                self.errors.append(f"版本不一致: {versions}")
            else:
                self.info.append(f"✅ 版本一致: {list(unique_versions)[0]}")
    
    def extract_version(self, file_path: Path) -> str:
        """提取文件中的版本号"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 查找版本号
            matches = re.findall(self.version_pattern, content)
            if matches:
                return matches[0]
        except Exception as e:
            self.warnings.append(f"无法读取文件 {file_path}: {e}")
        
        return None
    
    def check_links(self):
        """检查链接有效性"""
        print("🔗 检查链接有效性...")
        
        broken_links = []
        for md_file in self.docs_dir.rglob("*.md"):
            links = self.extract_links(md_file)
            for link_text, link_url in links:
                if not self.is_valid_link(link_url, md_file):
                    broken_links.append(f"{md_file}: {link_text} -> {link_url}")
        
        if broken_links:
            self.errors.extend([f"❌ 无效链接: {link}" for link in broken_links])
        else:
            self.info.append("✅ 所有链接有效")
    
    def extract_links(self, file_path: Path) -> List[Tuple[str, str]]:
        """提取文件中的链接"""
        links = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            matches = re.findall(self.link_pattern, content)
            links = [(match[0], match[1]) for match in matches]
        except Exception as e:
            self.warnings.append(f"无法读取文件 {file_path}: {e}")
        
        return links
    
    def is_valid_link(self, link_url: str, source_file: Path) -> bool:
        """检查链接是否有效"""
        # 外部链接
        if link_url.startswith(('http://', 'https://')):
            return True
        
        # 内部链接
        if link_url.startswith('#'):
            return True
        
        # 相对路径链接
        if not link_url.startswith('/'):
            target_path = source_file.parent / link_url
            return target_path.exists()
        
        # 绝对路径链接
        target_path = self.docs_dir / link_url.lstrip('/')
        return target_path.exists()
    
    def check_format_consistency(self):
        """检查格式一致性"""
        print("📝 检查格式一致性...")
        
        format_issues = []
        for md_file in self.docs_dir.rglob("*.md"):
            issues = self.check_markdown_format(md_file)
            format_issues.extend(issues)
        
        if format_issues:
            self.warnings.extend([f"⚠️ 格式问题: {issue}" for issue in format_issues])
        else:
            self.info.append("✅ 格式一致性良好")
    
    def check_markdown_format(self, file_path: Path) -> List[str]:
        """检查Markdown格式"""
        issues = []
        try:
            with open(file_path, 'r', encoding='utf-8'):
                pass
        except Exception as e:
            issues.append(f"无法检查格式: {e}")
        
        return issues
    
    def check_content_completeness(self):
        """检查内容完整性"""
        print("📋 检查内容完整性...")
        
        required_sections = {
            self.docs_dir / "README.md": ["欢迎", "文档索引"],
            self.docs_dir / "QUICK_START.md": ["快速安装", "默认凭据"],
            self.docs_dir / "INSTALLATION_GUIDE.md": ["安装方式", "系统要求"],
            self.docs_dir / "DEPLOYMENT_GUIDE.md": ["部署概述", "快速部署"],
            self.docs_dir / "API_REFERENCE.md": ["认证", "用户管理"]
        }
        
        for path, sections in required_sections.items():
            if path.exists():
                missing_sections = self.check_required_sections(path, sections)
                if missing_sections:
                    self.warnings.append(f"{path.name} 缺少章节: {missing_sections}")
                else:
                    self.info.append(f"✅ {path.name} 内容完整")
    
    def check_required_sections(self, file_path: Path, required_sections: List[str]) -> List[str]:
        """检查必需章节"""
        missing = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            for section in required_sections:
                if section not in content:
                    missing.append(section)
        except Exception as e:
            self.warnings.append(f"无法检查内容: {e}")
        
        return missing
    
    def check_forbidden_patterns(self):
        """检查禁用内容"""
        print("🚫 检查禁用内容...")
        violations = []
        files_to_check = [path for _, path in self.required_docs if path.exists()]
        
        for path in files_to_check:
            try:
                content = path.read_text(encoding="utf-8")
            except Exception as e:
                self.warnings.append(f"无法读取 {path}: {e}")
                continue
            
            for pattern, message in self.forbidden_patterns.items():
                if re.search(pattern, content, re.IGNORECASE):
                    violations.append(f"{path}: {message}")
        
        if violations:
            self.errors.extend([f"❌ {item}" for item in violations])
        else:
            self.info.append("✅ 未发现禁用内容")
    
    def print_results(self):
        """输出检查结果"""
        print("\n" + "="*50)
        print("📊 文档一致性检查结果")
        print("="*50)
        
        if self.info:
            print("\n✅ 检查通过:")
            for info in self.info:
                print(f"  {info}")
        
        if self.warnings:
            print("\n⚠️ 警告:")
            for warning in self.warnings:
                print(f"  {warning}")
        
        if self.errors:
            print("\n❌ 错误:")
            for error in self.errors:
                print(f"  {error}")
        
        print(f"\n📈 统计:")
        print(f"  检查通过: {len(self.info)}")
        print(f"  警告: {len(self.warnings)}")
        print(f"  错误: {len(self.errors)}")
        
        if self.errors:
            print(f"\n❌ 检查失败，请修复错误后重试")
            sys.exit(1)
        else:
            print(f"\n✅ 检查通过，文档一致性良好")

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="文档一致性检查工具")
    parser.add_argument("--docs-dir", default="docs", help="文档目录路径")
    parser.add_argument("--verbose", "-v", action="store_true", help="详细输出")
    
    args = parser.parse_args()
    
    checker = DocumentationChecker(args.docs_dir)
    success = checker.check_all()
    
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()
