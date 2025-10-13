#!/bin/bash

echo "🧹 清理项目，专注于Linux环境..."

# 删除Windows相关文件
echo "删除Windows相关文件..."
rm -f *.bat
rm -f *.ps1
rm -f *.cmd
rm -f *.exe

# 删除临时文件
echo "删除临时文件..."
rm -f *.tmp
rm -f *.temp
rm -f *~

# 删除备份文件
echo "删除备份文件..."
rm -f *.bak
rm -f *.backup
rm -f *.old

# 删除日志文件
echo "删除日志文件..."
rm -f *.log
rm -f logs/*.log 2>/dev/null

# 删除编译文件
echo "删除编译文件..."
rm -rf __pycache__/
rm -rf *.pyc
rm -rf build/
rm -rf dist/
rm -rf *.egg-info/

# 删除IDE文件
echo "删除IDE文件..."
rm -rf .vscode/
rm -rf .idea/
rm -f *.swp
rm -f *.swo

# 删除系统文件
echo "删除系统文件..."
rm -f .DS_Store
rm -f Thumbs.db
rm -f desktop.ini

# 清理Git历史中的Windows文件
echo "清理Git历史..."
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch *.bat *.ps1 *.cmd *.exe' \
  --prune-empty --tag-name-filter cat -- --all

# 强制垃圾回收
git for-each-ref --format='delete %(refname)' refs/original | git update-ref --stdin
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "✅ 项目清理完成！"
echo ""
echo "现在项目专注于Linux环境："
echo "- 移除了所有Windows相关文件"
echo "- 清理了临时和备份文件"
echo "- 优化了Git仓库"
echo ""
echo "项目现在完全支持Linux环境！"
