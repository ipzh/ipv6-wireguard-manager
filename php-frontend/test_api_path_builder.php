<?php
/**
 * API路径构建器测试脚本
 * 测试前端与后端API路径构建器的集成情况
 */

// 引入配置和类
require_once 'config/config.php';
require_once 'classes/ApiPathBuilder.php';

class ApiPathBuilderTester {
    private $testResults = [];
    
    /**
     * 运行所有测试
     */
    public function runAllTests() {
        echo "=== API路径构建器测试开始 ===\n\n";
        
        $this->testBackendPathBuilder();
        $this->testPathConsistency();
        $this->testPathParameters();
        $this->testPathValidation();
        $this->testPathGeneration();
        
        $this->displayResults();
    }
    
    /**
     * 测试后端路径构建器
     */
    private function testBackendPathBuilder() {
        echo "1. 测试后端路径构建器...\n";
        
        try {
            // 初始化路径构建器
            $pathBuilder = new ApiPathBuilder(API_BASE_URL);
            
            // 测试基本路径构建
            $loginPath = $pathBuilder->buildPath('auth.login');
            $this->testResults['backend_path_builder']['basic_path'] = [
                'success' => $loginPath === '/auth/login',
                'expected' => '/auth/login',
                'actual' => $loginPath
            ];
            
            // 测试带参数的路径构建
            $userPath = $pathBuilder->buildPath('users.get', ['user_id' => 123]);
            $this->testResults['backend_path_builder']['parameterized_path'] = [
                'success' => $userPath === '/users/123',
                'expected' => '/users/123',
                'actual' => $userPath
            ];
            
            // 测试完整URL构建
            $fullUrl = $pathBuilder->buildUrl('wireguard.servers.get', ['server_id' => 'wg-01']);
            $expectedUrl = API_BASE_URL . '/wireguard/servers/wg-01';
            $this->testResults['backend_path_builder']['full_url'] = [
                'success' => $fullUrl === $expectedUrl,
                'expected' => $expectedUrl,
                'actual' => $fullUrl
            ];
            
            // 测试路径验证
            $validPath = $pathBuilder->validatePath('auth.login');
            $invalidPath = $pathBuilder->validatePath('invalid.path');
            $this->testResults['backend_path_builder']['path_validation'] = [
                'success' => $validPath === true && $invalidPath === false,
                'valid_path_result' => $validPath,
                'invalid_path_result' => $invalidPath
            ];
            
            // 测试获取所有路径
            $allPaths = $pathBuilder->getAllPaths();
            $this->testResults['backend_path_builder']['get_all_paths'] = [
                'success' => is_array($allPaths) && count($allPaths) > 0,
                'paths_count' => count($allPaths)
            ];
            
            foreach ($this->testResults['backend_path_builder'] as $test => $result) {
                if ($result['success']) {
                    echo "   ✅ {$test} - 测试通过\n";
                } else {
                    echo "   ❌ {$test} - 测试失败\n";
                    if (isset($result['expected'])) {
                        echo "      期望: {$result['expected']}\n";
                        echo "      实际: {$result['actual']}\n";
                    }
                }
            }
            
        } catch (Exception $e) {
            $this->testResults['backend_path_builder']['exception'] = [
                'success' => false,
                'error' => $e->getMessage()
            ];
            echo "   ❌ 后端路径构建器测试异常: {$e->getMessage()}\n";
        }
        
        echo "\n";
    }
    
    /**
     * 测试路径一致性
     */
    private function testPathConsistency() {
        echo "2. 测试前后端路径一致性...\n";
        
        try {
            $pathBuilder = new ApiPathBuilder(API_BASE_URL);
            
            // 定义需要测试的路径
            $testPaths = [
                'auth.login' => '/auth/login',
                'users.get' => '/users/{user_id}',
                'wireguard.servers.list' => '/wireguard/servers',
                'bgp.sessions.get' => '/bgp/sessions/{session_id}',
                'ipv6.pools.list' => '/ipv6/pools',
                'system.info' => '/system/info'
            ];
            
            foreach ($testPaths as $pathName => $expectedPath) {
                $actualPath = $pathBuilder->buildPath($pathName);
                $this->testResults['path_consistency'][$pathName] = [
                    'success' => $actualPath === $expectedPath,
                    'expected' => $expectedPath,
                    'actual' => $actualPath
                ];
                
                if ($actualPath === $expectedPath) {
                    echo "   ✅ {$pathName} - 路径一致\n";
                } else {
                    echo "   ❌ {$pathName} - 路径不一致\n";
                    echo "      期望: {$expectedPath}\n";
                    echo "      实际: {$actualPath}\n";
                }
            }
            
        } catch (Exception $e) {
            $this->testResults['path_consistency']['exception'] = [
                'success' => false,
                'error' => $e->getMessage()
            ];
            echo "   ❌ 路径一致性测试异常: {$e->getMessage()}\n";
        }
        
        echo "\n";
    }
    
    /**
     * 测试路径参数处理
     */
    private function testPathParameters() {
        echo "3. 测试路径参数处理...\n";
        
        try {
            $pathBuilder = new ApiPathBuilder(API_BASE_URL);
            
            // 测试单个参数
            $singleParam = $pathBuilder->buildPath('users.get', ['user_id' => 123]);
            $this->testResults['path_parameters']['single_parameter'] = [
                'success' => $singleParam === '/users/123',
                'expected' => '/users/123',
                'actual' => $singleParam
            ];
            
            // 测试多个参数
            $multiParam = $pathBuilder->buildPath('wireguard.clients.config', [
                'server_id' => 'wg-01',
                'client_id' => 'client-123'
            ]);
            $this->testResults['path_parameters']['multiple_parameters'] = [
                'success' => $multiParam === '/wireguard/servers/wg-01/clients/client-123/config',
                'expected' => '/wireguard/servers/wg-01/clients/client-123/config',
                'actual' => $multiParam
            ];
            
            // 测试缺少参数
            try {
                $missingParam = $pathBuilder->buildPath('users.get');
                $this->testResults['path_parameters']['missing_parameter'] = [
                    'success' => false,
                    'error' => '应该抛出异常但没有'
                ];
            } catch (Exception $e) {
                $this->testResults['path_parameters']['missing_parameter'] = [
                    'success' => true,
                    'error' => $e->getMessage()
                ];
            }
            
            // 测试额外参数
            $extraParam = $pathBuilder->buildPath('users.get', [
                'user_id' => 123,
                'extra_param' => 'value'
            ]);
            $this->testResults['path_parameters']['extra_parameter'] = [
                'success' => $extraParam === '/users/123',
                'expected' => '/users/123',
                'actual' => $extraParam
            ];
            
            foreach ($this->testResults['path_parameters'] as $test => $result) {
                if ($result['success']) {
                    echo "   ✅ {$test} - 测试通过\n";
                } else {
                    echo "   ❌ {$test} - 测试失败: {$result['error']}\n";
                    if (isset($result['expected'])) {
                        echo "      期望: {$result['expected']}\n";
                        echo "      实际: {$result['actual']}\n";
                    }
                }
            }
            
        } catch (Exception $e) {
            $this->testResults['path_parameters']['exception'] = [
                'success' => false,
                'error' => $e->getMessage()
            ];
            echo "   ❌ 路径参数测试异常: {$e->getMessage()}\n";
        }
        
        echo "\n";
    }
    
    /**
     * 测试路径验证
     */
    private function testPathValidation() {
        echo "4. 测试路径验证...\n";
        
        try {
            $pathBuilder = new ApiPathBuilder(API_BASE_URL);
            
            // 测试有效路径
            $validPaths = [
                'auth.login',
                'users.list',
                'wireguard.servers.list',
                'bgp.sessions.list',
                'ipv6.pools.list',
                'system.info'
            ];
            
            foreach ($validPaths as $pathName) {
                $isValid = $pathBuilder->validatePath($pathName);
                $this->testResults['path_validation']["valid_{$pathName}"] = [
                    'success' => $isValid === true,
                    'path' => $pathName,
                    'result' => $isValid
                ];
                
                if ($isValid) {
                    echo "   ✅ {$pathName} - 有效路径验证通过\n";
                } else {
                    echo "   ❌ {$pathName} - 有效路径验证失败\n";
                }
            }
            
            // 测试无效路径
            $invalidPaths = [
                'invalid.path',
                'auth.invalid',
                'users.invalid.action',
                'nonexistent.module.path'
            ];
            
            foreach ($invalidPaths as $pathName) {
                $isValid = $pathBuilder->validatePath($pathName);
                $this->testResults['path_validation']["invalid_{$pathName}"] = [
                    'success' => $isValid === false,
                    'path' => $pathName,
                    'result' => $isValid
                ];
                
                if (!$isValid) {
                    echo "   ✅ {$pathName} - 无效路径验证通过\n";
                } else {
                    echo "   ❌ {$pathName} - 无效路径验证失败\n";
                }
            }
            
        } catch (Exception $e) {
            $this->testResults['path_validation']['exception'] = [
                'success' => false,
                'error' => $e->getMessage()
            ];
            echo "   ❌ 路径验证测试异常: {$e->getMessage()}\n";
        }
        
        echo "\n";
    }
    
    /**
     * 测试路径生成
     */
    private function testPathGeneration() {
        echo "5. 测试路径生成...\n";
        
        try {
            $pathBuilder = new ApiPathBuilder(API_BASE_URL);
            
            // 测试不同模块的路径生成
            $modules = [
                'auth' => ['login', 'logout', 'refresh', 'me'],
                'users' => ['list', 'get', 'create', 'update', 'delete'],
                'wireguard.servers' => ['list', 'get', 'create', 'update', 'delete', 'status'],
                'bgp.sessions' => ['list', 'get', 'create', 'update', 'delete', 'status'],
                'ipv6.pools' => ['list', 'get', 'create', 'update', 'delete'],
                'system' => ['info', 'status', 'health', 'metrics']
            ];
            
            foreach ($modules as $module => $actions) {
                foreach ($actions as $action) {
                    $pathName = "{$module}.{$action}";
                    $path = $pathBuilder->buildPath($pathName);
                    $this->testResults['path_generation'][$pathName] = [
                        'success' => !empty($path) && is_string($path),
                        'path' => $path
                    ];
                    
                    if (!empty($path) && is_string($path)) {
                        echo "   ✅ {$pathName} - 路径生成成功: {$path}\n";
                    } else {
                        echo "   ❌ {$pathName} - 路径生成失败\n";
                    }
                }
            }
            
        } catch (Exception $e) {
            $this->testResults['path_generation']['exception'] = [
                'success' => false,
                'error' => $e->getMessage()
            ];
            echo "   ❌ 路径生成测试异常: {$e->getMessage()}\n";
        }
        
        echo "\n";
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
                    echo "   ❌ {$test}";
                    if (isset($result['error'])) {
                        echo ": {$result['error']}";
                    }
                    echo "\n";
                }
            }
            
            echo "\n";
        }
        
        $successRate = $totalTests > 0 ? round(($passedTests / $totalTests) * 100, 2) : 0;
        
        echo "📊 总体结果:\n";
        echo "   总测试数: {$totalTests}\n";
        echo "   通过测试: {$passedTests}\n";
        echo "   成功率: {$successRate}%\n\n";
        
        if ($successRate >= 95) {
            echo "🎉 API路径构建器测试通过！系统可以正常使用。\n";
        } elseif ($successRate >= 80) {
            echo "⚠️  API路径构建器基本正常，但有一些问题需要关注。\n";
        } else {
            echo "❌ API路径构建器存在严重问题，需要修复。\n";
        }
        
        echo "\n=== 测试完成 ===\n";
    }
}

// 运行测试
if (php_sapi_name() === 'cli') {
    $tester = new ApiPathBuilderTester();
    $tester->runAllTests();
} else {
    echo "请在命令行中运行此脚本: php test_api_path_builder.php\n";
}
?>