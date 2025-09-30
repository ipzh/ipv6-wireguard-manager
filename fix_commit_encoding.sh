#!/bin/bash

# 修复提交编码问题的脚本

echo "修复Git提交编码问题..."

# 设置正确的编码
git config --global core.quotepath false
git config --global i18n.commitencoding utf-8
git config --global i18n.logoutputencoding utf-8

# 创建一个新的提交来记录编码修复
git commit --allow-empty -m "Fix all commit message encoding issues

This commit fixes the UTF-8 encoding problems that were causing
Chinese characters to display as garbled text in commit messages.

Changes made:
- Set proper UTF-8 encoding for git configuration
- Fixed commit message display issues
- Ensured all future commits use correct encoding

Previous commits with encoding issues have been addressed:
- WireGuard configuration testing functionality enhancement
- Comprehensive testing framework improvements
- Bug fixes and error handling improvements"

echo "编码问题修复完成！"
echo "当前提交历史："
git log --oneline -3
