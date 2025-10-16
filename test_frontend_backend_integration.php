<?php
/**
 * 前端后端集成测试脚本
 */
require_once 'php-frontend/includes/EnhancedApiClient.php';

echo "🧪 IPv6 WireGuard Manager - 前端后端集成测试\n";
echo "==========================================\n\n";

// 颜色定义
function colorize($text, $color = 'white') {
    $colors = [
        'red' => "\033[31m",
        'green' => "\033[32m",
        'yellow' => "\033[33m",
        'blue' => "\033[34m",
        'white' => "\033[37m",
        'reset' => "\033[0m"
    ];
    return $colors[$color] . $text . $colors['reset'];
}

try {
    // 创建增强的API客户端
    $apiClient = new EnhancedApiClient();
    
    echo colorize("📋 测试配置:", 'blue') . "\n";
    echo "API基础URL: " . (getenv('API_BASE_URL') ?: 'http://localhost:8000/api/v1') . "\n";
    echo "超时时间: 30秒\n";
    echo "重试次数: 3次\n\n";
    
    // 1. 基础连接测试
    echo colorize("🔗 1. 基础连接测试", 'blue') . "\n";
    echo str_repeat('-', 50) . "\n";
    
    $healthCheck = $apiClient->healthCheck();
    if ($healthCheck['status'] === 'healthy') {
        echo colorize("✅ 基础连接正常", 'green') . "\n";
    } else {
        echo colorize("❌ 基础连接失败: " . $healthCheck['error'], 'red') . "\n";
        exit(1);
    }
    
    // 2. 核心功能测试
    echo colorize("\n🔧 2. 核心功能测试", 'blue') . "\n";
    echo str_repeat('-', 50) . "\n";
    
    $coreTests = [
        'WireGuard服务器' => function() use ($apiClient) {
            return $apiClient->wireguardGetServers();
        },
        'WireGuard客户端' => function() use ($apiClient) {
            return $apiClient->wireguardGetClients();
        },
        'WireGuard配置' => function() use ($apiClient) {
            return $apiClient->wireguardGetConfig();
        },
        'WireGuard状态' => function() use ($apiClient) {
            return $apiClient->wireguardGetStatus();
        },
        'BGP会话' => function() use ($apiClient) {
            return $apiClient->bgpGetSessions();
        },
        'BGP路由' => function() use ($apiClient) {
            return $apiClient->bgpGetRoutes();
        },
        'IPv6前缀池' => function() use ($apiClient) {
            return $apiClient->ipv6GetPools();
        },
        'IPv6分配' => function() use ($apiClient) {
            return $apiClient->ipv6GetAllocations();
        },
        '系统信息' => function() use ($apiClient) {
            return $apiClient->systemGetInfo();
        },
        '网络接口' => function() use ($apiClient) {
            return $apiClient->networkGetInterfaces();
        },
        '监控仪表板' => function() use ($apiClient) {
            return $apiClient->monitoringGetDashboard();
        },
        '系统指标' => function() use ($apiClient) {
            return $apiClient->monitoringGetSystemMetrics();
        },
        '日志列表' => function() use ($apiClient) {
            return $apiClient->logsGetList();
        }
    ];
    
    $testResults = [];
    foreach ($coreTests as $testName => $testFunction) {
        echo "测试 $testName... ";
        
        try {
            $startTime = microtime(true);
            $response = $testFunction();
            $endTime = microtime(true);
            
            $responseTime = round(($endTime - $startTime) * 1000, 2);
            
            if ($response['status'] === 200) {
                echo colorize("✅ 成功 ({$responseTime}ms)", 'green') . "\n";
                $testResults[$testName] = [
                    'status' => 'success',
                    'response_time' => $responseTime,
                    'data_size' => strlen(json_encode($response['data']))
                ];
            } else {
                echo colorize("⚠️ 状态码: {$response['status']}", 'yellow') . "\n";
                $testResults[$testName] = [
                    'status' => 'warning',
                    'response_code' => $response['status']
                ];
            }
        } catch (Exception $e) {
            echo colorize("❌ 失败: " . $e->getMessage(), 'red') . "\n";
            $testResults[$testName] = [
                'status' => 'error',
                'error' => $e->getMessage()
            ];
        }
    }
    
    // 3. 数据格式验证
    echo colorize("\n📊 3. 数据格式验证", 'blue') . "\n";
    echo str_repeat('-', 50) . "\n";
    
    $formatTests = [
        'WireGuard服务器数据格式' => function() use ($apiClient) {
            $response = $apiClient->wireguardGetServers();
            $data = $response['data'] ?? [];
            
            // 检查数据格式
            if (is_array($data)) {
                return ['valid' => true, 'count' => count($data)];
            }
            return ['valid' => false, 'error' => '数据不是数组格式'];
        },
        'BGP路由数据格式' => function() use ($apiClient) {
            $response = $apiClient->bgpGetRoutes();
            $data = $response['data'] ?? [];
            
            if (is_array($data)) {
                return ['valid' => true, 'count' => count($data)];
            }
            return ['valid' => false, 'error' => '数据不是数组格式'];
        },
        '系统信息数据格式' => function() use ($apiClient) {
            $response = $apiClient->systemGetInfo();
            $data = $response['data'] ?? [];
            
            if (is_array($data) && isset($data['system'])) {
                return ['valid' => true, 'has_system_info' => true];
            }
            return ['valid' => false, 'error' => '缺少系统信息'];
        }
    ];
    
    foreach ($formatTests as $testName => $testFunction) {
        echo "验证 $testName... ";
        
        try {
            $result = $testFunction();
            if ($result['valid']) {
                echo colorize("✅ 格式正确", 'green') . "\n";
            } else {
                echo colorize("❌ 格式错误: " . $result['error'], 'red') . "\n";
            }
        } catch (Exception $e) {
            echo colorize("❌ 验证失败: " . $e->getMessage(), 'red') . "\n";
        }
    }
    
    // 4. 性能测试
    echo colorize("\n⚡ 4. 性能测试", 'blue') . "\n";
    echo str_repeat('-', 50) . "\n";
    
    $performanceTests = [];
    foreach ($coreTests as $testName => $testFunction) {
        if (isset($testResults[$testName]) && $testResults[$testName]['status'] === 'success') {
            $performanceTests[$testName] = $testResults[$testName]['response_time'];
        }
    }
    
    if (!empty($performanceTests)) {
        $avgResponseTime = array_sum($performanceTests) / count($performanceTests);
        $maxResponseTime = max($performanceTests);
        $minResponseTime = min($performanceTests);
        
        echo "平均响应时间: " . round($avgResponseTime, 2) . "ms\n";
        echo "最大响应时间: " . round($maxResponseTime, 2) . "ms\n";
        echo "最小响应时间: " . round($minResponseTime, 2) . "ms\n";
        
        if ($avgResponseTime < 100) {
            echo colorize("✅ 性能优秀", 'green') . "\n";
        } elseif ($avgResponseTime < 500) {
            echo colorize("⚠️ 性能良好", 'yellow') . "\n";
        } else {
            echo colorize("❌ 性能需要优化", 'red') . "\n";
        }
    }
    
    // 5. 生成测试报告
    echo colorize("\n📋 5. 测试报告", 'blue') . "\n";
    echo str_repeat('-', 50) . "\n";
    
    $totalTests = count($testResults);
    $successfulTests = count(array_filter($testResults, function($result) {
        return $result['status'] === 'success';
    }));
    $failedTests = count(array_filter($testResults, function($result) {
        return $result['status'] === 'error';
    }));
    $warningTests = count(array_filter($testResults, function($result) {
        return $result['status'] === 'warning';
    }));
    
    echo "总测试数: $totalTests\n";
    echo colorize("成功: $successfulTests", 'green') . "\n";
    echo colorize("警告: $warningTests", 'yellow') . "\n";
    echo colorize("失败: $failedTests", 'red') . "\n";
    
    $successRate = round(($successfulTests / $totalTests) * 100, 2);
    echo "成功率: $successRate%\n";
    
    if ($successRate >= 90) {
        echo colorize("\n🎉 集成测试通过！前端后端联动正常", 'green') . "\n";
    } elseif ($successRate >= 70) {
        echo colorize("\n⚠️ 集成测试基本通过，但有一些问题需要修复", 'yellow') . "\n";
    } else {
        echo colorize("\n❌ 集成测试失败，需要修复大量问题", 'red') . "\n";
    }
    
} catch (Exception $e) {
    echo colorize("❌ 测试过程中发生错误: " . $e->getMessage(), 'red') . "\n";
    exit(1);
}

echo "\n" . str_repeat('=', 50) . "\n";
echo "测试完成时间: " . date('Y-m-d H:i:s') . "\n";
?>
