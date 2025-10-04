#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "[TEST] 模块元数据校验——正常模块目录"
if ! bash "$PROJECT_ROOT/modules/module_metadata_checker.sh" "$PROJECT_ROOT/modules"; then
  echo "❌ 模块目录元数据校验失败"; exit 1
fi

echo "[TEST] 模块元数据校验——错误示例文件"
TMP_BAD_MODULE="$(mktemp)"
cat > "$TMP_BAD_MODULE" << 'EOF'
#!/usr/bin/env bash
# 这是一个错误的模块示例，不包含必要头部
echo "bad"
EOF

if bash "$PROJECT_ROOT/modules/module_metadata_checker.sh" "$TMP_BAD_MODULE"; then
  echo "❌ 错误示例未被检测到"; rm -f "$TMP_BAD_MODULE"; exit 1
fi

rm -f "$TMP_BAD_MODULE"
echo "✅ 模块元数据校验测试通过"
exit 0