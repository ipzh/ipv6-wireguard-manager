<?php
/**
 * API路径管理器
 * 提供统一的API路径构建和验证功能
 */

require_once __DIR__ . '/../config/environment.php';

class ApiPathManager {
    private static $instance = null;
    private $config;
    private $baseUrl;
    private $version;
    
    /**
     * 获取单例实例
     */
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /**
     * 私有构造函数
     */
    private function __construct() {
        $this->config = Environment::get('paths', []);
        $this->baseUrl = Environment::get('api.base_url');
        $this->version = Environment::get('api.version');
    }
    
    /**
     * 构建API URL
     */
    public function buildUrl($category, $action = null, $params = [], $version = null) {
        // 获取路径
        $path = $this->getPath($category, $action);
        
        if ($path === null) {
            throw new Exception("未知的API路径: {$category}" . ($action ? ".{$action}" : ""));
        }
        
        // 替换路径参数
        foreach ($params as $key => $value) {
            $path = str_replace('{' . $key . '}', $value, $path);
        }
        
        // 构建完整URL
        $apiVersion = $version ?: $this->version;
        $fullUrl = $this->baseUrl . '/api/' . $apiVersion . $path;
        
        return $fullUrl;
    }
    
    /**
     * 获取路径
     */
    private function getPath($category, $action = null) {
        if (!isset($this->config[$category])) {
            return null;
        }
        
        $categoryConfig = $this->config[$category];
        
        // 处理嵌套路径
        if ($action && strpos($action, '.') !== false) {
            $parts = explode('.', $action);
            $current = $categoryConfig;
            
            foreach ($parts as $part) {
                if (isset($current[$part])) {
                    $current = $current[$part];
                } else {
                    return null;
                }
            }
            
            return $current;
        }
        
        // 处理简单路径
        if ($action && isset($categoryConfig[$action])) {
            return $categoryConfig[$action];
        }
        
        // 如果没有指定action，返回整个分类配置
        return $categoryConfig;
    }
    
    /**
     * 验证API路径格式
     */
    public function validatePath($path) {
        $result = [
            'valid' => false,
            'errors' => [],
            'warnings' => [],
            'suggestions' => []
        ];
        
        // 检查基本格式
        if (!preg_match('/^\/api\/v\d+\/.+/', $path)) {
            $result['errors'][] = "路径必须以 /api/v{version}/ 开头";
            $result['suggestions'][] = "使用格式: /api/v1/resource";
            return $result;
        }
        
        // 检查版本号
        if (!preg_match('/^\/api\/v(\d+)\//', $path, $matches)) {
            $result['errors'][] = "版本号格式错误";
            $result['suggestions'][] = "使用格式: /api/v1/";
            return $result;
        }
        
        $version = (int)$matches[1];
        if ($version < 1) {
            $result['errors'][] = "版本号必须大于等于1";
            $result['suggestions'][] = "使用版本号: v1, v2, v3...";
            return $result;
        }
        
        // 检查路径模式
        $patterns = [
            'resource' => '/^\/api\/v\d+\/[a-z][a-z0-9]*(_[a-z0-9]+)*$/',
            'resource_id' => '/^\/api\/v\d+\/[a-z][a-z0-9]*(_[a-z0-9]+)*\/\d+$/',
            'nested_resource' => '/^\/api\/v\d+\/[a-z][a-z0-9]*(_[a-z0-9]+)*\/\d+\/[a-z][a-z0-9]*(_[a-z0-9]+)*$/',
            'action' => '/^\/api\/v\d+\/[a-z][a-z0-9]*(_[a-z0-9]+)*\/[a-z][a-z0-9]*(-[a-z0-9]+)*$/'
        ];
        
        $validPattern = null;
        foreach ($patterns as $name => $pattern) {
            if (preg_match($pattern, $path)) {
                $validPattern = $name;
                break;
            }
        }
        
        if ($validPattern) {
            $result['valid'] = true;
        } else {
            $result['errors'][] = "路径格式不符合RESTful规范";
            $result['suggestions'][] = "资源路径: /api/v1/users";
            $result['suggestions'][] = "资源ID路径: /api/v1/users/123";
            $result['suggestions'][] = "嵌套资源: /api/v1/users/123/posts";
            $result['suggestions'][] = "操作路径: /api/v1/users/search";
        }
        
        return $result;
    }
    
    /**
     * 标准化路径
     */
    public function normalizePath($path) {
        // 移除多余斜杠
        $normalized = preg_replace('/\/+/', '/', $path);
        
        // 确保以斜杠开头
        if (substr($normalized, 0, 1) !== '/') {
            $normalized = '/' . $normalized;
        }
        
        // 移除末尾斜杠（除非是根路径）
        if (strlen($normalized) > 1 && substr($normalized, -1) === '/') {
            $normalized = substr($normalized, 0, -1);
        }
        
        return $normalized;
    }
    
    /**
     * 获取WebSocket URL
     */
    public function getWebSocketUrl($type) {
        $wsUrls = Environment::get('websocket', []);
        
        if (!isset($wsUrls[$type])) {
            throw new Exception("未知的WebSocket类型: {$type}");
        }
        
        return $wsUrls[$type];
    }
    
    /**
     * 获取当前API版本
     */
    public function getCurrentVersion() {
        return $this->version;
    }
    
    /**
     * 获取基础URL
     */
    public function getBaseUrl() {
        return $this->baseUrl;
    }
}

// 便捷函数
function getApiUrl($category, $action = null, $params = [], $version = null) {
    return ApiPathManager::getInstance()->buildUrl($category, $action, $params, $version);
}

function getWebSocketUrl($type) {
    return ApiPathManager::getInstance()->getWebSocketUrl($type);
}
