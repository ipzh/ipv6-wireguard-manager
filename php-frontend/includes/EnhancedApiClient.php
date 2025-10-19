<?php
/**
 * 增强的API客户端
 * 集成路径管理和验证功能
 */

require_once __DIR__ . '/ApiPathManager.php';

class EnhancedApiClient {
    private $pathManager;
    private $timeout;
    private $retryAttempts;
    private $retryDelay;
    private $lastError;
    
    public function __construct() {
        $this->pathManager = ApiPathManager::getInstance();
        $this->timeout = Environment::get('api.timeout', 30);
        $this->retryAttempts = Environment::get('api.retry_attempts', 3);
        $this->retryDelay = Environment::get('api.retry_delay', 1000);
    }
    
    /**
     * 发送API请求
     */
    public function request($method, $category, $action = null, $params = [], $data = null, $version = null) {
        // 构建URL
        $url = $this->pathManager->buildUrl($category, $action, $params, $version);
        
        // 验证路径
        $path = parse_url($url, PHP_URL_PATH);
        $validation = $this->pathManager->validatePath($path);
        
        if (!$validation['valid']) {
            $this->lastError = "无效的API路径: " . implode(', ', $validation['errors']);
            return false;
        }
        
        // 记录警告
        if (!empty($validation['warnings'])) {
            error_log("API路径警告: " . implode(', ', $validation['warnings']));
        }
        
        // 准备请求
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, $this->timeout);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Accept: application/json'
        ]);
        
        // 添加请求数据
        if ($data !== null) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        }
        
        // 添加认证头
        if (isset($_SESSION['jwt_token'])) {
            curl_setopt($ch, CURLOPT_HTTPHEADER, array_merge(
                curl_getinfo($ch, CURLINFO_HEADER_OUT),
                ["Authorization: Bearer " . $_SESSION['jwt_token']]
            ));
        }
        
        // 执行请求（带重试）
        $attempts = 0;
        $response = false;
        
        while ($attempts < $this->retryAttempts && $response === false) {
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            
            if ($response === false) {
                $attempts++;
                if ($attempts < $this->retryAttempts) {
                    usleep($this->retryDelay * 1000); // 转换为微秒
                }
            }
        }
        
        if ($response === false) {
            $this->lastError = curl_error($ch);
            curl_close($ch);
            return false;
        }
        
        curl_close($ch);
        
        // 解析响应
        $responseData = json_decode($response, true);
        
        if ($responseData === null) {
            $this->lastError = "无效的JSON响应";
            return false;
        }
        
        // 检查API错误
        if ($httpCode >= 400) {
            $this->lastError = $responseData['detail'] ?? "API请求失败";
            return false;
        }
        
        return $responseData;
    }
    
    /**
     * GET请求
     */
    public function get($category, $action = null, $params = [], $version = null) {
        return $this->request('GET', $category, $action, $params, null, $version);
    }
    
    /**
     * POST请求
     */
    public function post($category, $action = null, $data = null, $params = [], $version = null) {
        return $this->request('POST', $category, $action, $params, $data, $version);
    }
    
    /**
     * PUT请求
     */
    public function put($category, $action = null, $data = null, $params = [], $version = null) {
        return $this->request('PUT', $category, $action, $params, $data, $version);
    }
    
    /**
     * DELETE请求
     */
    public function delete($category, $action = null, $params = [], $version = null) {
        return $this->request('DELETE', $category, $action, $params, null, $version);
    }
    
    /**
     * 获取最后的错误
     */
    public function getLastError() {
        return $this->lastError;
    }
}