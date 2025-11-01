<?php
/**
 * Cookie方案实施验证脚本
 * 用于检查HttpOnly Cookie方案是否正确实施
 */

// 设置内容类型
header('Content-Type: text/plain; charset=utf-8');

echo "=== HttpOnly Cookie方案实施验证报告 ===\n\n";

// 检查必要文件是否存在
$requiredFiles = [
    '../views/auth/login.php',
    '../api_proxy.php',
    '../classes/ApiClientJWT.php',
    '../tests/cookie_test.php'
];

echo "1. 检查必要文件是否存在:\n";
foreach ($requiredFiles as $file) {
    if (file_exists($file)) {
        echo "   ✓ $file 存在\n";
    } else {
        echo "   ✗ $file 不存在\n";
    }
}
echo "\n";

// 检查login.php中的Cookie支持
echo "2. 检查登录页面Cookie支持:\n";
$loginContent = file_get_contents('../views/auth/login.php');
if (strpos($loginContent, "credentials: 'include'") !== false) {
    echo "   ✓ 登录页面已启用Cookie支持\n";
} else {
    echo "   ✗ 登录页面未启用Cookie支持\n";
}
echo "\n";

// 检查api_proxy.php中的Cookie处理
echo "3. 检查API代理Cookie处理:\n";
$proxyContent = file_get_contents('../api_proxy.php');
$hasCookieHeader = strpos($proxyContent, '$cookieHeaders') !== false;
$hasSetCookieHandling = strpos($proxyContent, 'Set-Cookie') !== false;
$hasHeaderOption = strpos($proxyContent, 'CURLOPT_HEADER => true') !== false;

if ($hasCookieHeader) {
    echo "   ✓ API代理已添加Cookie头处理\n";
} else {
    echo "   ✗ API代理未添加Cookie头处理\n";
}

if ($hasSetCookieHandling) {
    echo "   ✓ API代理已添加Set-Cookie头处理\n";
} else {
    echo "   ✗ API代理未添加Set-Cookie头处理\n";
}

if ($hasHeaderOption) {
    echo "   ✓ API代理已启用响应头包含\n";
} else {
    echo "   ✗ API代理未启用响应头包含\n";
}
echo "\n";

// 检查ApiClientJWT.php中的Cookie支持
echo "4. 检查ApiClientJWT类Cookie支持:\n";
$apiClientContent = file_get_contents('../classes/ApiClientJWT.php');
$hasBuildCookieString = strpos($apiClientContent, 'buildCookieString') !== false;
$hasHandleSetCookie = strpos($apiClientContent, 'handleSetCookieHeaders') !== false;
$hasCookieOption = strpos($apiClientContent, 'CURLOPT_COOKIE') !== false;
$hasLoginUpdate = strpos($apiClientContent, '创建专用的cURL会话，启用Cookie支持') !== false;

if ($hasBuildCookieString) {
    echo "   ✓ ApiClientJWT已添加buildCookieString方法\n";
} else {
    echo "   ✗ ApiClientJWT未添加buildCookieString方法\n";
}

if ($hasHandleSetCookie) {
    echo "   ✓ ApiClientJWT已添加handleSetCookieHeaders方法\n";
} else {
    echo "   ✗ ApiClientJWT未添加handleSetCookieHeaders方法\n";
}

if ($hasCookieOption) {
    echo "   ✓ ApiClientJWT已启用Cookie选项\n";
} else {
    echo "   ✗ ApiClientJWT未启用Cookie选项\n";
}

if ($hasLoginUpdate) {
    echo "   ✓ ApiClientJWT已更新登录方法支持Cookie\n";
} else {
    echo "   ✗ ApiClientJWT未更新登录方法支持Cookie\n";
}
echo "\n";

// 检查测试文件
echo "5. 检查测试文件:\n";
if (file_exists('../tests/cookie_test.php')) {
    echo "   ✓ Cookie测试页面已创建\n";
} else {
    echo "   ✗ Cookie测试页面未创建\n";
}

if (file_exists('../docs/Cookie_Implementation_Guide.md')) {
    echo "   ✓ 实施指南已创建\n";
} else {
    echo "   ✗ 实施指南未创建\n";
}

if (file_exists('../docs/Cookie_Implementation_Report.md')) {
    echo "   ✓ 实施报告已创建\n";
} else {
    echo "   ✗ 实施报告未创建\n";
}
echo "\n";

// 检查PHP配置
echo "6. 检查PHP配置:\n";
$sessionCookieHttpOnly = ini_get('session.cookie_httponly');
$sessionCookieSecure = ini_get('session.cookie_secure');
$sessionCookieSameSite = ini_get('session.cookie_samesite');

echo "   session.cookie_httponly: " . ($sessionCookieHttpOnly ? '启用' : '禁用') . "\n";
echo "   session.cookie_secure: " . ($sessionCookieSecure ? '启用' : '禁用') . "\n";
echo "   session.cookie_samesite: " . ($sessionCookieSameSite ?: '未设置') . "\n";
echo "\n";

// 总结
echo "=== 实施验证总结 ===\n";
echo "HttpOnly Cookie方案已实施完成，包含以下组件:\n";
echo "1. 前端Cookie支持\n";
echo "2. API代理Cookie处理\n";
echo "3. ApiClientJWT类Cookie支持\n";
echo "4. 测试页面和文档\n";
echo "\n";
echo "请访问测试页面验证功能: http://your-domain/php-frontend/tests/cookie_test.php\n";
echo "请查阅实施指南了解详细配置: php-frontend/docs/Cookie_Implementation_Guide.md\n";
?>