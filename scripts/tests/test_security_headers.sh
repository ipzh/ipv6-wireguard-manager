#!/bin/bash
# 安全头测试脚本
# 用于验证安全头不重复设置，配置正确

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认配置
BASE_URL="${TEST_BASE_URL:-http://192.168.1.110}"
VERBOSE="${VERBOSE:-false}"

echo "=========================================="
echo "安全头测试脚本"
echo "=========================================="
echo "测试URL: $BASE_URL"
echo ""

# 测试结果计数
PASSED=0
FAILED=0
WARNINGS=0

# 测试函数
test_header() {
    local header_name=$1
    local expected_values=$2
    local url="${3:-$BASE_URL}"
    
    echo -n "测试 $header_name ... "
    
    # 获取响应头
    if command -v curl >/dev/null 2>&1; then
        header_value=$(curl -sI "$url" | grep -i "^$header_name:" | sed "s/^$header_name: //i" | tr -d '\r\n' || echo "")
    else
        echo -e "${RED}FAIL${NC} (curl未安装)"
        ((FAILED++))
        return 1
    fi
    
    if [ -z "$header_value" ]; then
        echo -e "${YELLOW}WARN${NC} (未设置)"
        ((WARNINGS++))
        return 0
    fi
    
    # 检查是否重复（包含逗号）
    if echo "$header_value" | grep -q ","; then
        echo -e "${RED}FAIL${NC}"
        echo "  错误：发现重复值: $header_value"
        echo "  应该只有一个值，但现在有多个值用逗号分隔"
        ((FAILED++))
        return 1
    fi
    
    # 检查是否为预期值之一
    local is_valid=false
    IFS=',' read -ra VALUES <<< "$expected_values"
    for expected in "${VALUES[@]}"; do
        if echo "$header_value" | grep -qiF "$expected"; then
            is_valid=true
            break
        fi
    done
    
    if [ "$is_valid" = true ]; then
        echo -e "${GREEN}PASS${NC}"
        if [ "$VERBOSE" = "true" ]; then
            echo "  值: $header_value"
        fi
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}WARN${NC}"
        echo "  值: $header_value (不在预期值列表中)"
        ((WARNINGS++))
        return 0
    fi
}

# 测试重复值检测
test_no_duplicates() {
    local url="${1:-$BASE_URL}"
    
    echo ""
    echo "=========================================="
    echo "测试1: 安全头重复检测"
    echo "=========================================="
    
    if command -v curl >/dev/null 2>&1; then
        headers=$(curl -sI "$url" | grep -iE "^(X-Frame-Options|X-Content-Type-Options|X-XSS-Protection|Referrer-Policy):" || true)
        
        echo "检查的安全头:"
        echo "$headers" | while IFS= read -r line; do
            if [ -n "$line" ]; then
                header_name=$(echo "$line" | cut -d: -f1)
                header_value=$(echo "$line" | cut -d: -f2- | sed 's/^ //')
                
                # 检查是否包含逗号（表示重复）
                if echo "$header_value" | grep -q ","; then
                    echo -e "${RED}❌ $header_name: 发现重复值${NC}"
                    echo "  值: $header_value"
                    ((FAILED++))
                else
                    echo -e "${GREEN}✅ $header_name: 单一值${NC}"
                    if [ "$VERBOSE" = "true" ]; then
                        echo "  值: $header_value"
                    fi
                fi
            fi
        done
    else
        echo -e "${RED}FAIL${NC} (curl未安装)"
        ((FAILED++))
    fi
}

# 测试特定安全头
test_specific_headers() {
    local url="${1:-$BASE_URL}"
    
    echo ""
    echo "=========================================="
    echo "测试2: 安全头值验证"
    echo "=========================================="
    
    # X-Frame-Options
    test_header "X-Frame-Options" "DENY,SAMEORIGIN" "$url"
    
    # X-Content-Type-Options
    test_header "X-Content-Type-Options" "nosniff" "$url"
    
    # X-XSS-Protection
    test_header "X-XSS-Protection" "1; mode=block" "$url"
    
    # Referrer-Policy
    test_header "Referrer-Policy" "strict-origin-when-cross-origin,no-referrer-when-downgrade" "$url"
}

# 测试健康检查端点
test_health_endpoints() {
    echo ""
    echo "=========================================="
    echo "测试3: 健康检查端点"
    echo "=========================================="
    
    # 测试 /api/v1/health
    echo -n "测试 /api/v1/health ... "
    if command -v curl >/dev/null 2>&1; then
        status_code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/v1/health" || echo "000")
        if [ "$status_code" = "200" ]; then
            echo -e "${GREEN}PASS${NC} (HTTP $status_code)"
            ((PASSED++))
        else
            echo -e "${RED}FAIL${NC} (HTTP $status_code)"
            ((FAILED++))
        fi
    else
        echo -e "${RED}FAIL${NC} (curl未安装)"
        ((FAILED++))
    fi
    
    # 测试 /health
    echo -n "测试 /health ... "
    if command -v curl >/dev/null 2>&1; then
        status_code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health" || echo "000")
        if [ "$status_code" = "200" ]; then
            echo -e "${GREEN}PASS${NC} (HTTP $status_code)"
            ((PASSED++))
        else
            echo -e "${RED}FAIL${NC} (HTTP $status_code)"
            ((FAILED++))
        fi
    else
        echo -e "${RED}FAIL${NC} (curl未安装)"
        ((FAILED++))
    fi
}

# 运行所有测试
main() {
    # 测试1: 重复检测
    test_no_duplicates
    
    # 测试2: 特定安全头
    test_specific_headers
    
    # 测试3: 健康检查端点
    test_health_endpoints
    
    # 总结
    echo ""
    echo "=========================================="
    echo "测试总结"
    echo "=========================================="
    echo -e "${GREEN}通过: $PASSED${NC}"
    echo -e "${YELLOW}警告: $WARNINGS${NC}"
    echo -e "${RED}失败: $FAILED${NC}"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✅ 所有测试通过！${NC}"
        exit 0
    else
        echo -e "${RED}❌ 部分测试失败，请检查配置${NC}"
        exit 1
    fi
}

# 运行主函数
main

