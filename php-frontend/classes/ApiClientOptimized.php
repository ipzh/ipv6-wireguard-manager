<?php
/**
 * API客户端封装类 - 优化版本
 * 使用curl替代file_get_contents，提供更好的错误处理和重试机制
 */
class ApiClientOptimized {
    private $baseUrl;
    private $timeout;
    private $token;
    private $maxRetries;
    private $retryDelay;
    private $userAgent;
    private $cache;
    
    public function __construct() {
        $this->baseUrl = API_BASE_URL;
        $this->timeout = API_TIMEOUT ?? 30;
        $this->maxRetries = 3;
        $this->retryDelay = 1; // 秒
        $this->userAgent = 'IPv6-WireGuard-Manager/1.0';
        $this->token = $_SESSION['token'] ?? null;
        $this->cache = [];
    }
    
    /**
     * 设置认证令牌
     */
    public function setToken($token) {
        $this->token = $token;
        $_SESSION['token'] = $token;
    }
    
    /**
     * 获取认证令牌
     */
    public function getToken() {
        return $this->token;
    }
    
    /**
     * 清除认证令牌
     */
    public function clearToken() {
        $this->token = null;
        unset($_SESSION['token']);
    }
    
    /**
     * 发送GET请求
     */
    public function get($endpoint, $params = [], $useCache = false) {
        $url = $this->baseUrl . $endpoint;
        if (!empty($params)) {
            $url .= '?' . http_build_query($params);
        }
        
        // 检查缓存
        if ($useCache && isset($this->cache[$url])) {
            $cached = $this->cache[$url];
            if (time() - $cached['timestamp'] < 300) { // 5分钟缓存
                return $cached['data'];
            }
        }
        
        $result = $this->makeRequest('GET', $url);
        
        // 缓存结果
        if ($useCache) {
            $this->cache[$url] = [
                'data' => $result,
                'timestamp' => time()
            ];
        }
        
        return $result;
    }
    
    /**
     * 发送POST请求
     */
    public function post($endpoint, $data = []) {
        $url = $this->baseUrl . $endpoint;
        return $this->makeRequest('POST', $url, $data);
    }
    
    /**
     * 发送PUT请求
     */
    public function put($endpoint, $data = []) {
        $url = $this->baseUrl . $endpoint;
        return $this->makeRequest('PUT', $url, $data);
    }
    
    /**
     * 发送DELETE请求
     */
    public function delete($endpoint) {
        $url = $this->baseUrl . $endpoint;
        return $this->makeRequest('DELETE', $url);
    }
    
    /**
     * 发送PATCH请求
     */
    public function patch($endpoint, $data = []) {
        $url = $this->baseUrl . $endpoint;
        return $this->makeRequest('PATCH', $url, $data);
    }
    
    /**
     * 发送HTTP请求 - 使用curl优化版本
     */
    private function makeRequest($method, $url, $data = null) {
        $attempt = 0;
        $lastError = null;
        
        while ($attempt < $this->maxRetries) {
            try {
                $result = $this->executeCurlRequest($method, $url, $data);
                
                // 如果请求成功，返回结果
                if ($result['success']) {
                    return $result['data'];
                }
                
                // 如果是404错误，尝试使用模拟API
                if ($result['http_code'] === 404) {
                    return $this->useMockApi($url, $method, $data);
                }
                
                // 如果是可重试的错误，继续重试
                if ($this->isRetryableError($result['http_code'])) {
                    $lastError = $result['error'];
                    $attempt++;
                    
                    if ($attempt < $this->maxRetries) {
                        sleep($this->retryDelay * $attempt); // 递增延迟
                        continue;
                    }
                }
                
                // 不可重试的错误或重试次数用完
                throw new Exception($result['error']);
                
            } catch (Exception $e) {
                $lastError = $e->getMessage();
                $attempt++;
                
                if ($attempt < $this->maxRetries) {
                    sleep($this->retryDelay * $attempt);
                    continue;
                }
                
                throw $e;
            }
        }
        
        throw new Exception('API请求失败，已重试' . $this->maxRetries . '次: ' . $lastError);
    }
    
    /**
     * 执行curl请求
     */
    private function executeCurlRequest($method, $url, $data = null) {
        $ch = curl_init();
        
        // 基本curl配置
        curl_setopt_array($ch, [
            CURLOPT_URL => $url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => $this->timeout,
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_MAXREDIRS => 3,
            CURLOPT_SSL_VERIFYPEER => false,
            CURLOPT_SSL_VERIFYHOST => false,
            CURLOPT_USERAGENT => $this->userAgent,
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/json',
                'Accept: application/json',
                'Cache-Control: no-cache'
            ]
        ]);
        
        // 添加认证头
        if ($this->token) {
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Content-Type: application/json',
                'Accept: application/json',
                'Cache-Control: no-cache',
                'Authorization: Bearer ' . $this->token
            ]);
        }
        
        // 设置请求方法和数据
        switch (strtoupper($method)) {
            case 'POST':
                curl_setopt($ch, CURLOPT_POST, true);
                if ($data) {
                    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
                }
                break;
            case 'PUT':
                curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
                if ($data) {
                    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
                }
                break;
            case 'DELETE':
                curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');
                break;
            case 'PATCH':
                curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PATCH');
                if ($data) {
                    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
                }
                break;
        }
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        
        curl_close($ch);
        
        if ($response === false) {
            return [
                'success' => false,
                'http_code' => 0,
                'error' => 'CURL错误: ' . $error
            ];
        }
        
        // 解析JSON响应
        $decodedResponse = json_decode($response, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            return [
                'success' => false,
                'http_code' => $httpCode,
                'error' => 'JSON解析错误: ' . json_last_error_msg()
            ];
        }
        
        // 检查HTTP状态码
        if ($httpCode >= 200 && $httpCode < 300) {
            return [
                'success' => true,
                'http_code' => $httpCode,
                'data' => $decodedResponse
            ];
        } else {
            $errorMessage = $decodedResponse['error'] ?? $decodedResponse['message'] ?? 'HTTP错误';
            return [
                'success' => false,
                'http_code' => $httpCode,
                'error' => "HTTP {$httpCode}: {$errorMessage}"
            ];
        }
    }
    
    /**
     * 判断是否为可重试的错误
     */
    private function isRetryableError($httpCode) {
        // 5xx服务器错误和部分4xx错误可以重试
        return in_array($httpCode, [
            408, // Request Timeout
            429, // Too Many Requests
            500, // Internal Server Error
            502, // Bad Gateway
            503, // Service Unavailable
            504  // Gateway Timeout
        ]);
    }
    
    /**
     * 使用模拟API
     */
    private function useMockApi($url, $method, $data = null) {
        // 构建模拟API URL
        $mockUrl = 'http://localhost' . dirname($_SERVER['SCRIPT_NAME']) . '/api_mock.php' . parse_url($url, PHP_URL_PATH);
        
        // 设置查询参数
        $query = parse_url($url, PHP_URL_QUERY);
        if ($query) {
            $mockUrl .= '?' . $query;
        }
        
        // 设置请求上下文
        $context = [
            'http' => [
                'method' => $method,
                'header' => [
                    'Content-Type: application/json',
                    'Accept: application/json',
                    'User-Agent: ' . $this->userAgent
                ],
                'timeout' => $this->timeout
            ]
        ];
        
        if ($data && in_array($method, ['POST', 'PUT', 'PATCH'])) {
            $context['http']['content'] = json_encode($data);
        }
        
        $context = stream_context_create($context);
        
        $response = @file_get_contents($mockUrl, false, $context);
        
        if ($response === false) {
            // 如果模拟API也失败，返回默认响应
            return $this->getDefaultResponse($url);
        }
        
        return json_decode($response, true);
    }
    
    /**
     * 获取默认响应
     */
    private function getDefaultResponse($url) {
        // 根据端点返回适当的默认数据
        if (strpos($url, '/system/') !== false) {
            return [
                'success' => true,
                'data' => [
                    'message' => '系统信息暂不可用',
                    'status' => 'offline'
                ]
            ];
        } elseif (strpos($url, '/wireguard/') !== false) {
            return [
                'success' => true,
                'data' => []
            ];
        } elseif (strpos($url, '/monitoring/') !== false) {
            return [
                'success' => true,
                'data' => [
                    'message' => '监控数据暂不可用',
                    'status' => 'offline'
                ]
            ];
        } else {
            return [
                'success' => false,
                'error' => '服务暂不可用',
                'message' => '后端API服务未运行，请稍后重试'
            ];
        }
    }
    
    /**
     * 清除缓存
     */
    public function clearCache() {
        $this->cache = [];
    }
    
    /**
     * 获取缓存统计
     */
    public function getCacheStats() {
        return [
            'cache_size' => count($this->cache),
            'cached_urls' => array_keys($this->cache)
        ];
    }
}
?>
