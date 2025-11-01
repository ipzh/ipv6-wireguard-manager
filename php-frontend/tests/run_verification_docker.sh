#!/bin/bash

# Docker版本的Cookie实施方案验证脚本

echo "=== HttpOnly Cookie方案实施验证报告 (Docker版本) ==="
echo

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "错误: Docker未运行，请启动Docker后重试"
    exit 1
fi

# 检查容器是否运行
if ! docker ps | grep -q "ipv6-wireguard-frontend"; then
    echo "错误: ipv6-wireguard-frontend容器未运行，请先启动项目"
    echo "运行命令: docker-compose up -d"
    exit 1
fi

# 运行验证脚本
echo "正在运行验证脚本..."
docker exec -it ipv6-wireguard-frontend php /var/www/html/tests/verify_cookie_implementation.php

echo
echo "验证完成！"
echo
echo "如需测试Cookie功能，请访问: http://localhost/tests/cookie_test.php"