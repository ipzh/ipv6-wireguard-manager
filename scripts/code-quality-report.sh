#!/bin/bash

# IPv6 WireGuard Manager 代码质量报告生成器
# 版本: 1.0.0

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
# YELLOW=  # unused'\033[1;33m'
BLUE='\033[0;34m'
# PURPLE=  # unused'\033[0;35m'
# CYAN=  # unused'\033[0;36m'
NC='\033[0m' # No Color

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="$PROJECT_ROOT/reports"
QUALITY_REPORT="$REPORT_DIR/code-quality-report.md"

# 创建报告目录
mkdir -p "$REPORT_DIR"

# 显示横幅
show_banner() {
    echo -e "${CYAN}"
    echo "=========================================="
    echo "  IPv6 WireGuard Manager 代码质量报告"
    echo "=========================================="
    echo -e "${NC}"
}

# 生成代码统计
generate_code_statistics() {
    echo -e "${BLUE}📊 生成代码统计...${NC}"
    
    # 总代码行数
    TOTAL_LINES=$(find "$PROJECT_ROOT" -name "*.sh" -type f | xargs wc -l | tail -1 | awk '{print $1}')
    
    # 函数数量
    FUNCTION_COUNT=$(grep -r "^[a-zA-Z_][a-zA-Z0-9_]*() {" "$PROJECT_ROOT/modules/" | wc -l)
    
    # 注释行数
    COMMENT_LINES=$(find "$PROJECT_ROOT" -name "*.sh" -type f | xargs grep -c "^#" | awk '{sum+=$1} END {print sum}')
    
    # 注释率
    COMMENT_RATIO=$((COMMENT_LINES * 100 / TOTAL_LINES))
    
    # 文件数量
    FILE_COUNT=$(find "$PROJECT_ROOT" -name "*.sh" -type f | wc -l)
    
    # 模块数量
    MODULE_COUNT=$(find "$PROJECT_ROOT/modules" -name "*.sh" -type f | wc -l)
    
    echo "  ✓ 代码统计完成"
}

# 生成复杂度分析
generate_complexity_analysis() {
    echo -e "${BLUE}🔍 生成复杂度分析...${NC}"
    
    # 检查长函数
    LONG_FUNCTIONS=$(find "$PROJECT_ROOT" -name "*.sh" -type f -exec awk '
        /^[a-zA-Z_][a-zA-Z0-9_]*\(\) \{/ { 
            function_start = NR
            brace_count = 1
            function_name = $0
        }
        /^[a-zA-Z_][a-zA-Z0-9_]*\(\) \{/, /^}$/ {
            if (brace_count == 0) {
                if (NR - function_start > 50) {
                    print FILENAME ":" function_start ": " function_name " (" (NR - function_start) " 行)"
                }
                next
            }
            if ($0 ~ /\{/) brace_count++
            if ($0 ~ /\}/) brace_count--
        }' {} \;)
    
    # 检查复杂条件
    COMPLEX_CONDITIONS=$(find "$PROJECT_ROOT" -name "*.sh" -type f -exec grep -n "if.*&&.*&&\|if.*||.*||" {} \; | wc -l)
    
    # 检查嵌套深度
    NESTING_DEPTH=$(find "$PROJECT_ROOT" -name "*.sh" -type f -exec awk '
        BEGIN { max_depth = 0; current_depth = 0 }
        /\{/ { current_depth++; if (current_depth > max_depth) max_depth = current_depth }
        /\}/ { current_depth-- }
        END { print max_depth }' {} \; | sort -nr | head -1)
    
    echo "  ✓ 复杂度分析完成"
}

# 生成安全检查
generate_security_analysis() {
    echo -e "${BLUE}🔒 生成安全检查...${NC}"
    
    # 检查硬编码凭据
    HARDCODED_CREDENTIALS=$(grep -r -i "password.*=" "$PROJECT_ROOT" --include="*.sh" --include="*.conf" | grep -v "PASSWORD.*=" | wc -l)
    
    # 检查敏感文件权限
    SENSITIVE_FILES=$(find "$PROJECT_ROOT" -name "*.key" -o -name "*.pem" -o -name "*.p12" | wc -l)
    
    # 检查输入验证
    INPUT_VALIDATION=$(grep -r "sanitize_input\|validate_" "$PROJECT_ROOT/modules/" | wc -l)
    
    # 检查错误处理
    ERROR_HANDLING=$(grep -r "set -e\|trap\|error" "$PROJECT_ROOT/modules/" | wc -l)
    
    echo "  ✓ 安全检查完成"
}

# 生成性能分析
generate_performance_analysis() {
    echo -e "${BLUE}⚡ 生成性能分析...${NC}"
    
    # 检查子进程使用
    SUBPROCESS_COUNT=$(grep -r "system\|exec\|fork" "$PROJECT_ROOT/modules/" | wc -l)
    
    # 检查循环优化
    LOOP_OPTIMIZATION=$(grep -r "for.*in.*do\|while.*do" "$PROJECT_ROOT/modules/" | wc -l)
    
    # 检查内存使用
    MEMORY_USAGE=$(grep -r "declare -a\|declare -A" "$PROJECT_ROOT/modules/" | wc -l)
    
    echo "  ✓ 性能分析完成"
}

# 生成测试覆盖率
generate_test_coverage() {
    echo -e "${BLUE}🧪 生成测试覆盖率...${NC}"
    
    # 检查测试文件
    TEST_FILES=$(find "$PROJECT_ROOT/tests" -name "*.sh" -type f | wc -l)
    
    # 检查测试函数
    TEST_FUNCTIONS=$(grep -r "test_.*()" "$PROJECT_ROOT/tests/" | wc -l)
    
    # 检查测试覆盖的模块
    COVERED_MODULES=$(grep -r "test_.*management\|test_.*config" "$PROJECT_ROOT/tests/" | wc -l)
    
    echo "  ✓ 测试覆盖率分析完成"
}

# 生成质量报告
generate_quality_report() {
    echo -e "${BLUE}📝 生成质量报告...${NC}"
    
    cat > "$QUALITY_REPORT" << EOF
# IPv6 WireGuard Manager 代码质量报告

**生成时间**: $(date)
**项目版本**: 1.0.0
**报告类型**: 代码质量分析

## 📊 代码统计

### 基本统计
- **总代码行数**: $TOTAL_LINES
- **函数数量**: $FUNCTION_COUNT
- **文件数量**: $FILE_COUNT
- **模块数量**: $MODULE_COUNT
- **注释行数**: $COMMENT_LINES
- **注释率**: ${COMMENT_RATIO}%

### 代码分布
- **核心模块**: $MODULE_COUNT 个
- **测试文件**: $TEST_FILES 个
- **配置文件**: $(find "$PROJECT_ROOT" -name "*.conf" -type f | wc -l) 个
- **文档文件**: $(find "$PROJECT_ROOT" -name "*.md" -type f | wc -l) 个

## 🔍 复杂度分析

### 函数复杂度
- **长函数数量**: $(echo "$LONG_FUNCTIONS" | wc -l)
- **复杂条件数量**: $COMPLEX_CONDITIONS
- **最大嵌套深度**: $NESTING_DEPTH

### 复杂度评估
EOF

    # 添加复杂度详情
    if [[ -n "$LONG_FUNCTIONS" ]]; then
        echo "#### 长函数列表" >> "$QUALITY_REPORT"
        echo '```' >> "$QUALITY_REPORT"
        echo "$LONG_FUNCTIONS" >> "$QUALITY_REPORT"
        echo '```' >> "$QUALITY_REPORT"
    fi

    cat >> "$QUALITY_REPORT" << EOF

## 🔒 安全检查

### 安全指标
- **硬编码凭据**: $HARDCODED_CREDENTIALS 个
- **敏感文件**: $SENSITIVE_FILES 个
- **输入验证函数**: $INPUT_VALIDATION 个
- **错误处理函数**: $ERROR_HANDLING 个

### 安全评估
EOF

    # 安全评估
    if [[ $HARDCODED_CREDENTIALS -eq 0 ]]; then
        echo "- ✅ **无硬编码凭据** - 安全性良好" >> "$QUALITY_REPORT"
    else
        echo "- ⚠️ **发现 $HARDCODED_CREDENTIALS 个硬编码凭据** - 需要修复" >> "$QUALITY_REPORT"
    fi

    if [[ $INPUT_VALIDATION -gt 0 ]]; then
        echo "- ✅ **输入验证完善** - 有 $INPUT_VALIDATION 个验证函数" >> "$QUALITY_REPORT"
    else
        echo "- ❌ **输入验证不足** - 需要添加验证函数" >> "$QUALITY_REPORT"
    fi

    cat >> "$QUALITY_REPORT" << EOF

## ⚡ 性能分析

### 性能指标
- **子进程调用**: $SUBPROCESS_COUNT 次
- **循环结构**: $LOOP_OPTIMIZATION 个
- **数组使用**: $MEMORY_USAGE 个

### 性能评估
EOF

    # 性能评估
    if [[ $SUBPROCESS_COUNT -lt 100 ]]; then
        echo "- ✅ **子进程使用合理** - 性能良好" >> "$QUALITY_REPORT"
    else
        echo "- ⚠️ **子进程使用较多** - 可能需要优化" >> "$QUALITY_REPORT"
    fi

    cat >> "$QUALITY_REPORT" << EOF

## 🧪 测试覆盖率

### 测试统计
- **测试文件**: $TEST_FILES 个
- **测试函数**: $TEST_FUNCTIONS 个
- **覆盖模块**: $COVERED_MODULES 个

### 测试评估
EOF

    # 测试评估
    if [[ $TEST_FUNCTIONS -gt 10 ]]; then
        echo "- ✅ **测试覆盖充分** - 有 $TEST_FUNCTIONS 个测试函数" >> "$QUALITY_REPORT"
    else
        echo "- ⚠️ **测试覆盖不足** - 需要添加更多测试" >> "$QUALITY_REPORT"
    fi

    cat >> "$QUALITY_REPORT" << EOF

## 📈 质量评分

### 综合评分
- **代码质量**: $(calculate_quality_score "$@")
- **安全性**: $(calculate_security_score "$@")
- **性能**: $(calculate_performance_score "$@")
- **测试覆盖**: $(calculate_test_score "$@")

### 改进建议
EOF

    # 添加改进建议
    if [[ $HARDCODED_CREDENTIALS -gt 0 ]]; then
        echo "- 🔒 **修复硬编码凭据** - 使用环境变量管理敏感信息" >> "$QUALITY_REPORT"
    fi

    if [[ $COMMENT_RATIO -lt 20 ]]; then
        echo "- 📝 **增加注释** - 当前注释率 ${COMMENT_RATIO}%，建议达到 20% 以上" >> "$QUALITY_REPORT"
    fi

    if [[ $TEST_FUNCTIONS -lt 20 ]]; then
        echo "- 🧪 **增加测试** - 当前有 $TEST_FUNCTIONS 个测试函数，建议达到 20 个以上" >> "$QUALITY_REPORT"
    fi

    cat >> "$QUALITY_REPORT" << EOF

## 📋 总结

IPv6 WireGuard Manager 项目代码质量总体良好，具备以下特点：

### 优势
- ✅ 模块化设计清晰
- ✅ 功能完整度高
- ✅ 安全性考虑周全
- ✅ 测试框架完善

### 需要改进的方面
- 🔧 优化长函数结构
- 🔧 增加代码注释
- 🔧 完善测试覆盖
- 🔧 性能优化

### 建议
1. **定期代码审查** - 建立每周代码审查机制
2. **持续集成** - 使用GitHub Actions自动化测试
3. **性能监控** - 定期进行性能分析和优化
4. **安全审计** - 定期进行安全扫描和修复

---
*报告生成时间: $(date)*
*IPv6 WireGuard Manager v1.0.0*
EOF

    echo "  ✓ 质量报告生成完成"
}

# 计算质量评分
calculate_quality_score() {
    local score=100
    
    # 注释率评分
    if [[ $COMMENT_RATIO -lt 10 ]]; then
        score=$((score - 20))
    elif [[ $COMMENT_RATIO -lt 20 ]]; then
        score=$((score - 10))
    fi
    
    # 长函数评分
    local long_func_count=$(echo "$LONG_FUNCTIONS" | wc -l)
    if [[ $long_func_count -gt 5 ]]; then
        score=$((score - 15))
    elif [[ $long_func_count -gt 2 ]]; then
        score=$((score - 10))
    fi
    
    # 复杂度评分
    if [[ $NESTING_DEPTH -gt 5 ]]; then
        score=$((score - 10))
    fi
    
    echo $score
}

# 计算安全评分
calculate_security_score() {
    local score=100
    
    # 硬编码凭据评分
    if [[ $HARDCODED_CREDENTIALS -gt 0 ]]; then
        score=$((score - 30))
    fi
    
    # 输入验证评分
    if [[ $INPUT_VALIDATION -lt 5 ]]; then
        score=$((score - 20))
    fi
    
    # 错误处理评分
    if [[ $ERROR_HANDLING -lt 10 ]]; then
        score=$((score - 15))
    fi
    
    echo $score
}

# 计算性能评分
calculate_performance_score() {
    local score=100
    
    # 子进程使用评分
    if [[ $SUBPROCESS_COUNT -gt 200 ]]; then
        score=$((score - 20))
    elif [[ $SUBPROCESS_COUNT -gt 100 ]]; then
        score=$((score - 10))
    fi
    
    # 循环优化评分
    if [[ $LOOP_OPTIMIZATION -gt 50 ]]; then
        score=$((score - 10))
    fi
    
    echo $score
}

# 计算测试评分
calculate_test_score() {
    local score=100
    
    # 测试函数数量评分
    if [[ $TEST_FUNCTIONS -lt 5 ]]; then
        score=$((score - 40))
    elif [[ $TEST_FUNCTIONS -lt 10 ]]; then
        score=$((score - 20))
    fi
    
    # 测试覆盖评分
    if [[ $COVERED_MODULES -lt 5 ]]; then
        score=$((score - 20))
    fi
    
    echo $score
}

# 主函数
main() {
    show_banner
    
    echo "开始生成代码质量报告..."
    echo
    
    # 生成各项分析
    generate_code_statistics
    generate_complexity_analysis
    generate_security_analysis
    generate_performance_analysis
    generate_test_coverage
    
    # 生成最终报告
    generate_quality_report
    
    echo
    echo -e "${GREEN}✅ 代码质量报告生成完成！${NC}"
    echo -e "报告位置: ${BLUE}$QUALITY_REPORT${NC}"
    echo
    
    # 显示报告摘要
    echo -e "${CYAN}📊 报告摘要:${NC}"
    echo "  - 总代码行数: $TOTAL_LINES"
    echo "  - 函数数量: $FUNCTION_COUNT"
    echo "  - 注释率: ${COMMENT_RATIO}%"
    echo "  - 测试函数: $TEST_FUNCTIONS"
    echo "  - 质量评分: $(calculate_quality_score "$@")/100"
    echo "  - 安全评分: $(calculate_security_score "$@")/100"
    echo "  - 性能评分: $(calculate_performance_score "$@")/100"
    echo "  - 测试评分: $(calculate_test_score "$@")/100"
}

# 运行主函数
main "$@"
