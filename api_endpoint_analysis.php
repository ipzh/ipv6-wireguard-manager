<?php
/**
 * API端点对比分析脚本
 */

echo "🔍 IPv6 WireGuard Manager - API端点对比分析\n";
echo "==========================================\n\n";

// 前端调用的API端点（从控制器中提取）
$frontendEndpoints = [
    // 用户管理
    '/users' => ['GET', 'POST'],
    '/users/{id}' => ['GET', 'PUT', 'DELETE'],
    '/users/roles' => ['GET', 'POST'],
    '/users/roles/{id}' => ['GET', 'PUT', 'DELETE'],
    '/users/{id}/permissions' => ['PUT'],
    '/users/{id}/reset-password' => ['POST'],
    '/users/{id}/activity' => ['GET'],
    '/users/batch' => ['POST'],
    
    // 系统管理
    '/system/info' => ['GET'],
    '/system/config' => ['GET', 'PUT'],
    '/system/services' => ['GET'],
    '/system/services/{name}/start' => ['POST'],
    '/system/services/{name}/stop' => ['POST'],
    '/system/services/{name}/restart' => ['POST'],
    '/system/backup' => ['POST'],
    '/system/backups' => ['GET'],
    '/system/backups/{id}/restore' => ['POST'],
    '/system/backups/{id}' => ['GET', 'DELETE'],
    '/system/backups/{id}/download' => ['GET'],
    '/system/updates/check' => ['GET'],
    '/system/updates/install' => ['POST'],
    '/system/maintenance/clear-cache' => ['POST'],
    '/system/maintenance/optimize-database' => ['POST'],
    '/system/maintenance/clean-logs' => ['POST'],
    '/system/maintenance/reboot' => ['POST'],
    '/system/logs' => ['GET'],
    '/system/performance' => ['GET'],
    
    // 网络管理
    '/network/interfaces' => ['GET'],
    '/network/status' => ['GET'],
    '/network/routes' => ['GET'],
    '/network/diagnostics' => ['POST'],
    '/network/config' => ['GET', 'POST'],
    '/network/firewall' => ['GET', 'POST'],
    '/network/portscan' => ['POST'],
    '/network/traffic' => ['GET'],
    '/network/dns' => ['GET', 'POST'],
    '/network/topology' => ['GET'],
    '/network/bgp/announcements' => ['GET'],
    
    // 日志管理
    '/logs' => ['GET'],
    '/logs/{id}' => ['GET'],
    '/logs/export' => ['GET'],
    '/logs/cleanup' => ['POST'],
    '/logs/statistics' => ['GET'],
    
    // 监控
    '/monitoring/metrics' => ['GET'],
    '/monitoring/alerts' => ['GET', 'POST'],
    '/monitoring/alerts/{id}' => ['GET', 'PUT', 'DELETE'],
    '/monitoring/alerts/{id}/acknowledge' => ['POST'],
    '/monitoring/history' => ['GET'],
    '/monitoring/system' => ['GET'],
    '/monitoring/processes' => ['GET'],
    '/monitoring/network' => ['GET'],
    '/monitoring/disk' => ['GET'],
    
    // IPv6管理
    '/ipv6/pools' => ['GET', 'POST'],
    '/ipv6/pools/{id}' => ['GET', 'PUT', 'DELETE'],
    '/ipv6/allocations' => ['GET', 'POST'],
    '/ipv6/allocations/{id}' => ['GET', 'PUT', 'DELETE'],
    '/ipv6/statistics' => ['GET'],
    
    // BGP管理
    '/bgp/sessions' => ['GET', 'POST'],
    '/bgp/sessions/{id}' => ['GET', 'PUT', 'DELETE'],
    '/bgp/sessions/{id}/start' => ['POST'],
    '/bgp/sessions/{id}/stop' => ['POST'],
    '/bgp/announcements' => ['GET', 'POST'],
    '/bgp/announcements/{id}' => ['GET', 'PUT', 'DELETE'],
    '/bgp/status' => ['GET'],
    
    // WireGuard管理
    '/wireguard/servers' => ['GET', 'POST'],
    '/wireguard/servers/{id}' => ['GET', 'PUT', 'DELETE'],
    '/wireguard/servers/{id}/start' => ['POST'],
    '/wireguard/servers/{id}/stop' => ['POST'],
    '/wireguard/servers/{id}/config' => ['GET'],
    '/wireguard/clients' => ['GET', 'POST'],
    '/wireguard/clients/{id}' => ['GET', 'PUT', 'DELETE'],
    '/wireguard/clients/{id}/config' => ['GET'],
];

// 后端实际存在的API端点
$backendEndpoints = [
    // 认证
    '/auth/login' => ['POST'],
    '/auth/login-json' => ['POST'],
    '/auth/logout' => ['POST'],
    '/auth/me' => ['GET'],
    '/auth/refresh' => ['POST'],
    '/auth/health' => ['GET'],
    
    // 用户管理
    '/users' => ['GET', 'POST'],
    '/users/{user_id}' => ['GET', 'PUT', 'DELETE'],
    
    // WireGuard管理
    '/wireguard/config' => ['GET', 'POST'],
    '/wireguard/peers' => ['GET', 'POST'],
    '/wireguard/peers/{peer_id}' => ['GET', 'PUT', 'DELETE'],
    '/wireguard/peers/{peer_id}/restart' => ['POST'],
    '/wireguard/status' => ['GET'],
    '/wireguard/servers' => ['GET'],
    '/wireguard/clients' => ['GET'],
    
    // 网络管理
    '/network/interfaces' => ['GET'],
    '/network/status' => ['GET'],
    '/network/connections' => ['GET'],
    '/network/health' => ['GET'],
    
    // BGP管理
    '/bgp/sessions' => ['GET', 'POST'],
    '/bgp/sessions/{session_id}' => ['GET', 'PUT', 'DELETE'],
    '/bgp/routes' => ['GET'],
    '/bgp/status' => ['GET'],
    
    // IPv6管理
    '/ipv6/pools' => ['GET', 'POST'],
    '/ipv6/pools/{pool_id}' => ['GET', 'PUT', 'DELETE'],
    '/ipv6/allocations' => ['GET'],
    '/ipv6/allocations/allocate' => ['POST'],
    '/ipv6/allocations/{allocation_id}/release' => ['POST'],
    '/ipv6/health' => ['GET'],
    
    // 监控
    '/monitoring/dashboard' => ['GET'],
    '/monitoring/metrics/system' => ['GET'],
    '/monitoring/metrics/application' => ['GET'],
    '/monitoring/alerts/active' => ['GET'],
    '/monitoring/alerts/history' => ['GET'],
    '/monitoring/alerts/rules' => ['GET', 'POST'],
    '/monitoring/alerts/rules/{rule_id}' => ['PUT', 'DELETE'],
    '/monitoring/alerts/{rule_id}/acknowledge' => ['POST'],
    '/monitoring/alerts/{rule_id}/suppress' => ['POST'],
    '/monitoring/alerts/{rule_id}/resolve' => ['POST'],
    '/monitoring/health' => ['GET'],
    '/monitoring/cluster/status' => ['GET'],
    '/monitoring/cluster/sync' => ['POST'],
    '/monitoring/performance' => ['GET'],
    '/monitoring/metrics/collect' => ['POST'],
    '/monitoring/metrics/{metric_name}' => ['GET'],
    '/monitoring/alerts/stats' => ['GET'],
    
    // 日志管理
    '/logs' => ['GET'],
    '/logs/{log_id}' => ['GET', 'DELETE'],
    '/logs/health/check' => ['GET'],
    
    // 系统管理
    '/system/info' => ['GET'],
    '/system/processes' => ['GET'],
    '/system/restart' => ['POST'],
    '/system/shutdown' => ['POST'],
    '/system/health/check' => ['GET'],
    
    // 状态检查
    '/status' => ['GET'],
    '/status/health' => ['GET'],
    '/status/services' => ['GET'],
    
    // 健康检查
    '/health' => ['GET'],
    '/health/detailed' => ['GET'],
    '/health/readiness' => ['GET'],
    '/health/liveness' => ['GET'],
    '/metrics' => ['GET'],
    
    // 调试诊断
    '/debug/system-info' => ['GET'],
    '/debug/process-info' => ['GET'],
    '/debug/network-info' => ['GET'],
    '/debug/api-status' => ['GET'],
    '/debug/database-status' => ['GET'],
    '/debug/comprehensive-check' => ['GET'],
    '/debug/ping' => ['GET'],
];

// 分析差异
echo "📊 端点对比分析\n";
echo str_repeat('=', 50) . "\n\n";

$frontendOnly = [];
$backendOnly = [];
$common = [];

// 检查前端独有的端点
foreach ($frontendEndpoints as $endpoint => $methods) {
    if (!isset($backendEndpoints[$endpoint])) {
        $frontendOnly[$endpoint] = $methods;
    } else {
        $common[$endpoint] = [
            'frontend' => $methods,
            'backend' => $backendEndpoints[$endpoint]
        ];
    }
}

// 检查后端独有的端点
foreach ($backendEndpoints as $endpoint => $methods) {
    if (!isset($frontendEndpoints[$endpoint])) {
        $backendOnly[$endpoint] = $methods;
    }
}

echo "🔴 前端调用但后端不存在的端点 (" . count($frontendOnly) . "个):\n";
echo str_repeat('-', 50) . "\n";
foreach ($frontendOnly as $endpoint => $methods) {
    echo "  $endpoint [" . implode(', ', $methods) . "]\n";
}

echo "\n🟢 后端存在但前端未调用的端点 (" . count($backendOnly) . "个):\n";
echo str_repeat('-', 50) . "\n";
foreach ($backendOnly as $endpoint => $methods) {
    echo "  $endpoint [" . implode(', ', $methods) . "]\n";
}

echo "\n🟡 共同端点但方法不匹配 (" . count($common) . "个):\n";
echo str_repeat('-', 50) . "\n";
foreach ($common as $endpoint => $methods) {
    $frontendMethods = $methods['frontend'];
    $backendMethods = $methods['backend'];
    
    $missingInBackend = array_diff($frontendMethods, $backendMethods);
    $missingInFrontend = array_diff($backendMethods, $frontendMethods);
    
    if (!empty($missingInBackend) || !empty($missingInFrontend)) {
        echo "  $endpoint\n";
        if (!empty($missingInBackend)) {
            echo "    前端有但后端无: [" . implode(', ', $missingInBackend) . "]\n";
        }
        if (!empty($missingInFrontend)) {
            echo "    后端有但前端无: [" . implode(', ', $missingInFrontend) . "]\n";
        }
    }
}

echo "\n📈 统计信息:\n";
echo str_repeat('-', 50) . "\n";
echo "前端调用端点总数: " . count($frontendEndpoints) . "\n";
echo "后端提供端点总数: " . count($backendEndpoints) . "\n";
echo "完全匹配的端点: " . (count($common) - count(array_filter($common, function($m) { 
    return !empty(array_diff($m['frontend'], $m['backend'])) || !empty(array_diff($m['backend'], $m['frontend'])); 
}))) . "\n";
echo "需要修复的端点: " . (count($frontendOnly) + count(array_filter($common, function($m) { 
    return !empty(array_diff($m['frontend'], $m['backend'])) || !empty(array_diff($m['backend'], $m['frontend'])); 
}))) . "\n";

echo "\n🎯 修复建议:\n";
echo str_repeat('-', 50) . "\n";
echo "1. 在后端添加缺失的端点\n";
echo "2. 修改前端调用以匹配后端实际端点\n";
echo "3. 统一API设计规范\n";
echo "4. 添加API文档和测试\n";
?>
