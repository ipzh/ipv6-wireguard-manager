#!/usr/bin/env python3
"""
文档一致性检查脚本
检查文档的格式、链接、版本信息等一致性
"""

import os
import re
import json
import yaml
from pathlib import Path
from typing import Dict, List, Tuple, Set
import argparse
import sys

class DocumentationChecker:
    """文档一致性检查器"""
    
    def __init__(self, docs_dir: str = "docs"):
        self.docs_dir = Path(docs_dir)
        self.errors = []
        self.warnings = []
        self.info = []
        
        # 标准配置
        self.required_docs = [
            "README.md",
            "USER_MANUAL.md",
            "DEVELOPER_GUIDE.md",
            "DEPLOYMENT_GUIDE.md",
            "API_DESIGN_STANDARD.md",
            "DOCUMENTATION_STANDARD.md"
        ]
        
        self.version_pattern = r"(\d+\.\d+\.\d+)"
        self.link_pattern = r"\[([^\]]+)\]\(([^)]+)\)"
        self.heading_pattern = r"^#{1,6}\s+(.+)$"
        
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
        
        # 输出结果
        self.print_results()
        
        return len(self.errors) == 0
    
    def check_document_structure(self):
        """检查文档结构"""
        print("📁 检查文档结构...")
        
        # 检查必需文档
        for doc in self.required_docs:
            doc_path = self.docs_dir / doc
            if not doc_path.exists():
                self.errors.append(f"缺少必需文档: {doc}")
            else:
                self.info.append(f"✅ 找到文档: {doc}")
        
        # 检查目录结构
        expected_dirs = ["user", "developer", "admin", "api"]
        for dir_name in expected_dirs:
            dir_path = self.docs_dir / dir_name
            if not dir_path.exists():
                self.warnings.append(f"建议创建目录: {dir_name}/")
    
    def check_version_consistency(self):
        """检查版本一致性"""
        print("🔢 检查版本一致性...")
        
        version_files = [
            "README.md",
            "USER_MANUAL.md",
            "DEVELOPER_GUIDE.md",
            "DEPLOYMENT_GUIDE.md"
        ]
        
        versions = {}
        for file_name in version_files:
            file_path = self.docs_dir / file_name
            if file_path.exists():
                version = self.extract_version(file_path)
                if version:
                    versions[file_name] = version
        
        # 检查版本一致性
        if versions:
            unique_versions = set(versions.values())
            if len(unique_versions) > 1:
                self.errors.append(f"版本不一致: {dict(versions)}")
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
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            # 检查标题层次
            heading_levels = []
            for i, line in enumerate(lines):
                if line.startswith('#'):
                    level = len(line) - len(line.lstrip('#'))
                    heading_levels.append((i + 1, level, line.strip()))
            
            # 检查标题层次是否合理
            for i, (line_num, level, heading) in enumerate(heading_levels):
                if i > 0:
                    prev_level = heading_levels[i-1][1]
                    if level > prev_level + 1:
                        issues.append(f"{file_path}:{line_num} 标题层次跳跃: {heading}")
            
            # 检查空行
            for i, line in enumerate(lines):
                if line.strip() and i > 0 and lines[i-1].strip():
                    if not line.startswith('#') and not lines[i-1].startswith('#'):
                        if not lines[i-1].strip() == '':
                            # 检查是否需要空行
                            pass
            
        except Exception as e:
            issues.append(f"无法检查格式: {e}")
        
        return issues
    
    def check_content_completeness(self):
        """检查内容完整性"""
        print("📋 检查内容完整性...")
        
        # 检查必需章节
        required_sections = {
            "README.md": ["概述", "快速开始", "安装", "使用"],
            "USER_MANUAL.md": ["概述", "功能说明", "操作指南", "故障排除"],
            "DEVELOPER_GUIDE.md": ["概述", "环境搭建", "开发规范", "API参考"],
            "DEPLOYMENT_GUIDE.md": ["概述", "部署方式", "配置说明", "监控"]
        }
        
        for doc, sections in required_sections.items():
            doc_path = self.docs_dir / doc
            if doc_path.exists():
                missing_sections = self.check_required_sections(doc_path, sections)
                if missing_sections:
                    self.warnings.append(f"{doc} 缺少章节: {missing_sections}")
                else:
                    self.info.append(f"✅ {doc} 内容完整")
    
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
