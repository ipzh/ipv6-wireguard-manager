<?php
/**
 * API连接问题诊断和修复脚本
 */
require_once 'php-frontend/config/config.php';
require_once 'php-frontend/includes/ApiClient.php';

echo "🔧 IPv6 WireGuard Manager - API连接问题诊断和修复\n";
echo "===============================================\n\n";

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

// 检查步骤
$checks = [
    'config' => '检查配置文件',
    'network' => '检查网络连接',
    'backend' => '检查后端服务',
    'api' => '检查API端点',
    'fix' => '尝试修复问题'
];

foreach ($checks as $key => $description) {
    echo colorize("📋 步骤: $description", 'blue') . "\n";
    echo str_repeat('-', 50) . "\n";
    
    switch ($key) {
        case 'config':
            checkConfig();
            break;
        case 'network':
            checkNetwork();
            break;
        case 'backend':
            checkBackend();
            break;
        case 'api':
            checkAPI();
            break;
        case 'fix':
            tryFix();
            break;
    }
    
    echo "\n";
}

function checkConfig() {
    echo "检查配置文件...\n";
    
    $configFile = 'php-frontend/config/config.php';
    if (file_exists($configFile)) {
        echo colorize("✅ 配置文件存在", 'green') . "\n";
        
        // 检查API_BASE_URL
        $config = file_get_contents($configFile);
        if (strpos($config, 'API_BASE_URL') !== false) {
            echo colorize("✅ API_BASE_URL配置存在", 'green') . "\n";
            echo "当前配置: " . API_BASE_URL . "\n";
        } else {
            echo colorize("❌ API_BASE_URL配置缺失", 'red') . "\n";
        }
    } else {
        echo colorize("❌ 配置文件不存在", 'red') . "\n";
    }
}

function checkNetwork() {
    echo "检查网络连接...\n";
    
    $hosts = [
        'localhost:8000',
        '127.0.0.1:8000',
        'backend:8000'
    ];
    
    foreach ($hosts as $host) {
        echo "测试 $host... ";
        
        $connection = @fsockopen($host, 8000, $errno, $errstr, 5);
        if ($connection) {
            echo colorize("✅ 可连接", 'green') . "\n";
            fclose($connection);
        } else {
            echo colorize("❌ 不可连接 - $errstr", 'red') . "\n";
        }
    }
}

function checkBackend() {
    echo "检查后端服务...\n";
    
    // 检查后端进程
    $processes = [];
    if (function_exists('exec')) {
        exec('ps aux | grep uvicorn', $processes);
    }
    
    if (!empty($processes)) {
        echo colorize("✅ 发现后端进程", 'green') . "\n";
        foreach ($processes as $process) {
            if (strpos($process, 'uvicorn') !== false) {
                echo "  $process\n";
            }
        }
    } else {
        echo colorize("❌ 未发现后端进程", 'red') . "\n";
    }
    
    // 检查systemd服务
    if (function_exists('exec')) {
        exec('systemctl is-active ipv6-wireguard-manager 2>/dev/null', $serviceStatus);
        if (!empty($serviceStatus)) {
            echo "systemd服务状态: " . $serviceStatus[0] . "\n";
        }
    }
}

function checkAPI() {
    echo "检查API端点...\n";
    
    $apiClient = new ApiClient();
    
    $endpoints = [
        '/health',
        '/health/detailed',
        '/debug/ping'
    ];
    
    foreach ($endpoints as $endpoint) {
        echo "测试 $endpoint... ";
        
        try {
            $response = $apiClient->get($endpoint);
            echo colorize("✅ 正常 (状态码: {$response['status']})", 'green') . "\n";
        } catch (Exception $e) {
            echo colorize("❌ 失败 - " . $e->getMessage(), 'red') . "\n";
        }
    }
}

function tryFix() {
    echo "尝试修复问题...\n";
    
    $fixes = [
        'restart_backend' => '重启后端服务',
        'check_firewall' => '检查防火墙设置',
        'update_config' => '更新配置文件',
        'test_alternative_urls' => '测试备用URL'
    ];
    
    foreach ($fixes as $fix => $description) {
        echo "尝试: $description... ";
        
        switch ($fix) {
            case 'restart_backend':
                if (function_exists('exec')) {
                    exec('sudo systemctl restart ipv6-wireguard-manager 2>/dev/null', $output, $returnCode);
                    if ($returnCode === 0) {
                        echo colorize("✅ 重启成功", 'green') . "\n";
                        sleep(3); // 等待服务启动
                    } else {
                        echo colorize("❌ 重启失败", 'red') . "\n";
                    }
                } else {
                    echo colorize("⚠️ 无法执行系统命令", 'yellow') . "\n";
                }
                break;
                
            case 'check_firewall':
                echo colorize("⚠️ 请手动检查防火墙设置", 'yellow') . "\n";
                break;
                
            case 'update_config':
                // 尝试更新配置文件
                $configFile = 'php-frontend/config/config.php';
                if (file_exists($configFile)) {
                    echo colorize("✅ 配置文件已存在", 'green') . "\n";
                } else {
                    echo colorize("❌ 配置文件不存在", 'red') . "\n";
                }
                break;
                
            case 'test_alternative_urls':
                $alternativeUrls = [
                    'http://127.0.0.1:8000/api/v1',
                    'http://localhost:8000/api/v1',
                    'http://backend:8000/api/v1'
                ];
                
                foreach ($alternativeUrls as $url) {
                    echo "  测试 $url... ";
                    $testClient = new ApiClient($url, 5, 1);
                    try {
                        $response = $testClient->get('/health');
                        echo colorize("✅ 可用", 'green') . "\n";
                        echo "  建议更新API_BASE_URL为: $url\n";
                        break;
                    } catch (Exception $e) {
                        echo colorize("❌ 不可用", 'red') . "\n";
                    }
                }
                break;
        }
    }
}

echo colorize("🎯 诊断完成！", 'blue') . "\n";
echo "\n建议操作:\n";
echo "1. 检查后端服务是否正在运行\n";
echo "2. 确认防火墙允许8000端口访问\n";
echo "3. 检查API_BASE_URL配置是否正确\n";
echo "4. 查看后端服务日志: sudo journalctl -u ipv6-wireguard-manager -f\n";
echo "5. 访问API状态页面: http://your-domain/api_status.php\n";
?>
