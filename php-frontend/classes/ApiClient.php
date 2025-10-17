<?php
/**
 * API客户端封装类
 */
class ApiClient {
    private $baseUrl;
    private $timeout;
    private $token;
    
    public function __construct() {
        $this->baseUrl = API_BASE_URL;
        $this->timeout = API_TIMEOUT;
        $this->token = $_SESSION['token'] ?? null;
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
    public function get($endpoint, $params = []) {
        $url = $this->baseUrl . $endpoint;
        if (!empty($params)) {
            $url .= '?' . http_build_query($params);
        }
        
        return $this->makeRequest('GET', $url);
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
     * 发送HTTP请求
     */
    private function makeRequest($method, $url, $data = null) {
        $headers = [
            'Content-Type: application/json',
            'Accept: application/json'
        ];
        
        if ($this->token) {
            $headers[] = 'Authorization: Bearer ' . $this->token;
        }
        
        $context = [
            'http' => [
                'method' => $method,
                'header' => implode("\r\n", $headers),
                'timeout' => $this->timeout
            ]
        ];
        
        if ($data && in_array($method, ['POST', 'PUT'])) {
            $context['http']['content'] = json_encode($data);
        }
        
        $context = stream_context_create($context);
        
        $response = @file_get_contents($url, false, $context);
        
        if ($response === false) {
            $error = error_get_last();
            throw new Exception('API请求失败: ' . ($error['message'] ?? '未知错误'));
        }
        
        // 检查HTTP状态码
        $httpCode = $this->getHttpCode($http_response_header ?? []);
        
        if ($httpCode >= 400) {
            $errorData = json_decode($response, true);
            $message = $errorData['detail'] ?? $errorData['message'] ?? '请求失败';
            
            // 特殊处理权限错误
            if ($httpCode === 403) {
                throw new Exception('权限不足：' . $message);
            } elseif ($httpCode === 401) {
                throw new Exception('认证失败：' . $message);
            } elseif ($httpCode === 404) {
                throw new Exception('资源不存在：' . $message);
            } else {
                throw new Exception('API错误 (' . $httpCode . '): ' . $message);
            }
        }
        
        $decoded = json_decode($response, true);
        
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new Exception('JSON解析失败: ' . json_last_error_msg());
        }
        
        return $decoded;
    }
    
    /**
     * 获取HTTP状态码
     */
    private function getHttpCode($headers) {
        if (empty($headers)) {
            return 200;
        }
        
        $statusLine = $headers[0];
        if (preg_match('/HTTP\/\d\.\d\s+(\d+)/', $statusLine, $matches)) {
            return (int)$matches[1];
        }
        
        return 200;
    }
    
    /**
     * 检查API连接
     */
    public function checkConnection() {
        try {
            $response = $this->get('/status/health');
            return $response['status'] === 'healthy';
        } catch (Exception $e) {
            return false;
        }
    }
    
    /**
     * 获取API状态
     */
    public function getApiStatus() {
        try {
            return $this->get('/status/');
        } catch (Exception $e) {
            return [
                'status' => 'error',
                'message' => $e->getMessage()
            ];
        }
    }
}
?>
