<?php
/**
 * 增强的API客户端 - 优化版本
 */
class ApiClient {
    private $baseUrl;
    private $timeout;
    private $retryCount;
    private $debugMode;
    
    public function __construct($baseUrl = null, $timeout = 30, $retryCount = 3, $debugMode = false) {
        $this->baseUrl = $baseUrl ?: getenv('API_BASE_URL') ?: 'http://localhost:8000/api/v1';
        $this->timeout = $timeout;
        $this->retryCount = $retryCount;
        $this->debugMode = $debugMode;
    }
    
    /**
     * 发送HTTP请求
     */
    public function request($method, $endpoint, $data = null, $headers = []) {
        $url = rtrim($this->baseUrl, '/') . '/' . ltrim($endpoint, '/');
        
        // 默认请求头
        $defaultHeaders = [
            'Content-Type: application/json',
            'Accept: application/json',
            'User-Agent: IPv6-WireGuard-Manager/3.0.0'
        ];
        
        $headers = array_merge($defaultHeaders, $headers);
        
        // 重试机制
        $lastError = null;
        for ($attempt = 1; $attempt <= $this->retryCount; $attempt++) {
            try {
                $response = $this->makeRequest($method, $url, $data, $headers);
                
                if ($this->debugMode) {
                    error_log("API Request: $method $url - Attempt $attempt - Status: " . $response['status']);
                }
                
                return $response;
                
            } catch (Exception $e) {
                $lastError = $e;
                
                if ($this->debugMode) {
                    error_log("API Request failed: $method $url - Attempt $attempt - Error: " . $e->getMessage());
                }
                
                // 如果不是最后一次尝试，等待后重试
                if ($attempt < $this->retryCount) {
                    sleep(pow(2, $attempt - 1)); // 指数退避
                }
            }
        }
        
        // 所有重试都失败
        throw new Exception("API request failed after {$this->retryCount} attempts. Last error: " . $lastError->getMessage());
    }
    
    /**
     * 执行HTTP请求
     */
    private function makeRequest($method, $url, $data, $headers) {
        $ch = curl_init();
        
        // 基本配置
        curl_setopt_array($ch, [
            CURLOPT_URL => $url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => $this->timeout,
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_MAXREDIRS => 3,
            CURLOPT_SSL_VERIFYPEER => false,
            CURLOPT_SSL_VERIFYHOST => false,
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_USERAGENT => 'IPv6-WireGuard-Manager/3.0.0'
        ]);
        
        // 根据请求方法设置参数
        switch (strtoupper($method)) {
            case 'POST':
            case 'PUT':
            case 'PATCH':
                curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
                if ($data) {
                    curl_setopt($ch, CURLOPT_POSTFIELDS, is_array($data) ? json_encode($data) : $data);
                }
                break;
            case 'DELETE':
                curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');
                break;
            case 'GET':
            default:
                // GET请求，无需额外设置
                break;
        }
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);
        
        if ($response === false) {
            throw new Exception("cURL error: $error");
        }
        
        // 解析响应
        $decodedResponse = json_decode($response, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new Exception("Invalid JSON response: " . json_last_error_msg());
        }
        
        return [
            'status' => $httpCode,
            'data' => $decodedResponse,
            'raw' => $response
        ];
    }
    
    /**
     * GET请求
     */
    public function get($endpoint, $headers = []) {
        return $this->request('GET', $endpoint, null, $headers);
    }
    
    /**
     * POST请求
     */
    public function post($endpoint, $data = null, $headers = []) {
        return $this->request('POST', $endpoint, $data, $headers);
    }
    
    /**
     * PUT请求
     */
    public function put($endpoint, $data = null, $headers = []) {
        return $this->request('PUT', $endpoint, $data, $headers);
    }
    
    /**
     * DELETE请求
     */
    public function delete($endpoint, $headers = []) {
        return $this->request('DELETE', $endpoint, null, $headers);
    }
    
    /**
     * 健康检查
     */
    public function healthCheck() {
        try {
            $response = $this->get('/health');
            return [
                'status' => 'healthy',
                'response' => $response
            ];
        } catch (Exception $e) {
            return [
                'status' => 'unhealthy',
                'error' => $e->getMessage()
            ];
        }
    }
    
    /**
     * 获取连接状态
     */
    public function getConnectionStatus() {
        $startTime = microtime(true);
        
        try {
            $response = $this->get('/health');
            $endTime = microtime(true);
            
            return [
                'connected' => true,
                'response_time' => round(($endTime - $startTime) * 1000, 2), // 毫秒
                'status_code' => $response['status'],
                'data' => $response['data']
            ];
        } catch (Exception $e) {
            $endTime = microtime(true);
            
            return [
                'connected' => false,
                'response_time' => round(($endTime - $startTime) * 1000, 2),
                'error' => $e->getMessage()
            ];
        }
    }
    
    /**
     * 获取API状态 - 兼容Dashboard控制器
     */
    public function getApiStatus() {
        try {
            $response = $this->get('/health');
            return [
                'status' => 'healthy',
                'connected' => true,
                'response_time' => $response['status'] === 200 ? 'fast' : 'slow',
                'data' => $response['data']
            ];
        } catch (Exception $e) {
            return [
                'status' => 'unhealthy',
                'connected' => false,
                'error' => $e->getMessage(),
                'message' => 'API连接失败: ' . $e->getMessage()
            ];
        }
    }
}
?>
