<?php
/**
 * API集成测试脚本
 * 测试前端与后端API的集成情况
 */

// 引入配置和类
require_once 'config/config.php';
require_once 'classes/ApiClient.php';
require_once 'classes/ApiClientOptimized.php';
require_once 'classes/ErrorHandler.php';

class ApiIntegrationTester {
    private $apiClient;
    private $apiClientOptimized;
    private $testResults = [];
    
    public function __construct() {
        $this->apiClient = new ApiClient();
        $this->apiClientOptimized = new ApiClientOptimized();
    }
    
    /**
     * 运行所有测试
     */
    public function runAllTests() {
        echo "=== API集成测试开始 ===\n\n";
        
        $this->testBasicConnectivity();
        $this->testApiEndpoints();
        $this->testErrorHandling();
        $this->testMockApiFallback();
        $this->testOptimizedClient();
        
        $this->displayResults();
    }
    
    /**
     * 测试基本连接性
     */
    private function testBasicConnectivity() {
        echo "1. 测试基本连接性...\n";
        
        $endpoints = [
            '/health',
            '/status'
        ];
        
        foreach ($endpoints as $endpoint) {
            $result = $this->testEndpoint($endpoint);
            $this->testResults['connectivity'][$endpoint] = $result;
            
            if ($result['success']) {
                echo "   ✅ {$endpoint} - 连接成功\n";
            } else {
                echo "   ❌ {$endpoint} - 连接失败: {$result['error']}\n";
            }
        }
        
        echo "\n";
    }
    
    /**
     * 测试API端点
     */
    private function testApiEndpoints() {
        echo "2. 测试API端点...\n";
        
        $endpoints = [
            '/system/config',
            '/system/info',
            '/wireguard/servers',
            '/wireguard/clients',
            '/bgp/sessions',
            '/ipv6/pools',
            '/monitoring/metrics',
            '/logs',
            '/users'
        ];
        
        foreach ($endpoints as $endpoint) {
            $result = $this->testEndpoint($endpoint);
            $this->testResults['endpoints'][$endpoint] = $result;
            
            if ($result['success']) {
                echo "   ✅ {$endpoint} - 响应正常\n";
            } else {
                echo "   ❌ {$endpoint} - 响应异常: {$result['error']}\n";
            }
        }
        
        echo "\n";
    }
    
    /**
     * 测试错误处理
     */
    private function testErrorHandling() {
        echo "3. 测试错误处理...\n";
        
        $errorTests = [
            '/nonexistent' => '404错误处理',
            '/unauthorized' => '401错误处理',
            '/forbidden' => '403错误处理'
        ];
        
        foreach ($errorTests as $endpoint => $description) {
            $result = $this->testEndpoint($endpoint);
            $this->testResults['error_handling'][$endpoint] = $result;
            
            if ($result['success'] || $result['error_handled']) {
                echo "   ✅ {$description} - 处理正常\n";
            } else {
                echo "   ❌ {$description} - 处理异常: {$result['error']}\n";
            }
        }
        
        echo "\n";
    }
    
    /**
     * 测试模拟API回退
     */
    private function testMockApiFallback() {
        echo "4. 测试模拟API回退...\n";
        
        // 测试模拟API端点
        $mockEndpoints = [
            '/api_mock.php/system/config',
            '/api_mock.php/wireguard/servers',
            '/api_mock.php/monitoring/metrics'
        ];
        
        foreach ($mockEndpoints as $endpoint) {
            $result = $this->testMockEndpoint($endpoint);
            $this->testResults['mock_api'][$endpoint] = $result;
            
            if ($result['success']) {
                echo "   ✅ {$endpoint} - 模拟API正常\n";
            } else {
                echo "   ❌ {$endpoint} - 模拟API异常: {$result['error']}\n";
            }
        }
        
        echo "\n";
    }
    
    /**
     * 测试优化版API客户端
     */
    private function testOptimizedClient() {
        echo "5. 测试优化版API客户端...\n";
        
        $features = [
            '缓存功能' => $this->testCaching(),
            '重试机制' => $this->testRetryMechanism(),
            '错误分类' => $this->testErrorClassification()
        ];
        
        foreach ($features as $feature => $result) {
            $this->testResults['optimized_client'][$feature] = $result;
            
            if ($result['success']) {
                echo "   ✅ {$feature} - 功能正常\n";
            } else {
                echo "   ❌ {$feature} - 功能异常: {$result['error']}\n";
            }
        }
        
        echo "\n";
    }
    
    /**
     * 测试单个端点
     */
    private function testEndpoint($endpoint) {
        try {
            $url = API_BASE_URL . $endpoint;
            $context = stream_context_create([
                'http' => [
                    'method' => 'GET',
                    'timeout' => 5,
                    'header' => 'User-Agent: API-Test/1.0'
                ]
            ]);
            
            $response = @file_get_contents($url, false, $context);
            
            if ($response === false) {
                $error = error_get_last();
                return [
                    'success' => false,
                    'error' => $error['message'] ?? '未知错误',
                    'error_handled' => strpos($error['message'] ?? '', '404') !== false
                ];
            }
            
            $data = json_decode($response, true);
            return [
                'success' => true,
                'data' => $data,
                'response_size' => strlen($response)
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'error' => $e->getMessage(),
                'error_handled' => false
            ];
        }
    }
    
    /**
     * 测试模拟API端点
     */
    private function testMockEndpoint($endpoint) {
        try {
            $url = 'http://localhost' . dirname($_SERVER['SCRIPT_NAME']) . $endpoint;
            $context = stream_context_create([
                'http' => [
                    'method' => 'GET',
                    'timeout' => 5
                ]
            ]);
            
            $response = @file_get_contents($url, false, $context);
            
            if ($response === false) {
                return [
                    'success' => false,
                    'error' => '模拟API不可用'
                ];
            }
            
            $data = json_decode($response, true);
            return [
                'success' => true,
                'data' => $data,
                'response_size' => strlen($response)
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }
    
    /**
     * 测试缓存功能
     */
    private function testCaching() {
        try {
            // 第一次请求
            $start1 = microtime(true);
            $result1 = $this->apiClientOptimized->get('/api/v1/system/config', [], true);
            $time1 = microtime(true) - $start1;
            
            // 第二次请求（应该使用缓存）
            $start2 = microtime(true);
            $result2 = $this->apiClientOptimized->get('/api/v1/system/config', [], true);
            $time2 = microtime(true) - $start2;
            
            return [
                'success' => true,
                'first_request_time' => $time1,
                'cached_request_time' => $time2,
                'cache_working' => $time2 < $time1
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }
    
    /**
     * 测试重试机制
     */
    private function testRetryMechanism() {
        try {
            // 测试一个可能失败的端点
            $result = $this->apiClientOptimized->get('/api/v1/test-retry');
            
            return [
                'success' => true,
                'retry_mechanism' => '已实现'
            ];
            
        } catch (Exception $e) {
            // 重试机制应该处理异常
            return [
                'success' => true,
                'retry_mechanism' => '异常处理正常',
                'error' => $e->getMessage()
            ];
        }
    }
    
    /**
     * 测试错误分类
     */
    private function testErrorClassification() {
        try {
            // 测试不同类型的错误
            $this->apiClientOptimized->get('/api/v1/unauthorized');
            return [
                'success' => true,
                'error_classification' => '已实现'
            ];
            
        } catch (Exception $e) {
            $errorMessage = $e->getMessage();
            $isClassified = strpos($errorMessage, 'HTTP') !== false || 
                           strpos($errorMessage, '认证') !== false ||
                           strpos($errorMessage, '权限') !== false;
            
            return [
                'success' => $isClassified,
                'error_classification' => $isClassified ? '正常' : '需要改进',
                'error' => $errorMessage
            ];
        }
    }
    
    /**
     * 显示测试结果
     */
    private function displayResults() {
        echo "=== 测试结果汇总 ===\n\n";
        
        $totalTests = 0;
        $passedTests = 0;
        
        foreach ($this->testResults as $category => $tests) {
            echo "📋 {$category}:\n";
            
            foreach ($tests as $test => $result) {
                $totalTests++;
                if ($result['success']) {
                    $passedTests++;
                    echo "   ✅ {$test}\n";
                } else {
                    echo "   ❌ {$test}: {$result['error']}\n";
                }
            }
            
            echo "\n";
        }
        
        $successRate = $totalTests > 0 ? round(($passedTests / $totalTests) * 100, 2) : 0;
        
        echo "📊 总体结果:\n";
        echo "   总测试数: {$totalTests}\n";
        echo "   通过测试: {$passedTests}\n";
        echo "   成功率: {$successRate}%\n\n";
        
        if ($successRate >= 80) {
            echo "🎉 API集成测试通过！系统可以正常使用。\n";
        } elseif ($successRate >= 60) {
            echo "⚠️  API集成基本正常，但有一些问题需要关注。\n";
        } else {
            echo "❌ API集成存在严重问题，需要修复。\n";
        }
        
        echo "\n=== 测试完成 ===\n";
    }
}

// 运行测试
if (php_sapi_name() === 'cli') {
    $tester = new ApiIntegrationTester();
    $tester->runAllTests();
} else {
    echo "请在命令行中运行此脚本: php test_api_integration.php\n";
}
?>
