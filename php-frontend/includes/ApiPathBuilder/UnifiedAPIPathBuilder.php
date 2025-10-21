<?php

/**
 * 统一API路径构建器
 * 使用JSON配置文件，支持前后端一致性
 */

class UnifiedAPIPathBuilder {
    /**
     * 配置文件路径
     * @var string
     */
    private $configPath;
    
    /**
     * 配置数据
     * @var array
     */
    private $config;
    
    /**
     * 基础URL
     * @var string
     */
    private $baseUrl;
    
    /**
     * API版本
     * @var string
     */
    private $version;
    
    /**
     * 请求超时时间
     * @var int
     */
    private $timeout;
    
    /**
     * 构造函数
     * 
     * @param string|null $configPath 配置文件路径
     */
    public function __construct($configPath = null) {
        if ($configPath === null) {
            // 默认配置文件路径
            $this->configPath = __DIR__ . '/../../../config/api_paths.json';
        } else {
            $this->configPath = $configPath;
        }
        
        $this->loadConfig();
    }
    
    /**
     * 加载配置文件
     */
    private function loadConfig() {
        if (!file_exists($this->configPath)) {
            throw new Exception("API路径配置文件不存在: " . $this->configPath);
        }
        
        $configContent = file_get_contents($this->configPath);
        $this->config = json_decode($configContent, true);
        
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new Exception("API路径配置文件格式错误: " . json_last_error_msg());
        }
        
        $this->baseUrl = $this->config['api']['base_url'];
        $this->version = $this->config['api']['version'];
        $this->timeout = $this->config['api']['timeout'];
    }
    
    /**
     * 获取端点信息
     * 
     * @param string $category 端点类别
     * @param string $action 端点动作
     * @return array 端点信息
     * @throws Exception
     */
    public function getEndpoint($category, $action) {
        if (!isset($this->config['endpoints'][$category])) {
            throw new Exception("未知的端点类别: " . $category);
        }
        
        if (!isset($this->config['endpoints'][$category][$action])) {
            throw new Exception("未知的端点动作: " . $category . "." . $action);
        }
        
        return $this->config['endpoints'][$category][$action];
    }
    
    /**
     * 构建完整的API URL
     * 
     * @param string $category 端点类别
     * @param string $action 端点动作
     * @param array $params URL参数
     * @return string 完整的API URL
     */
    public function buildUrl($category, $action, $params = []) {
        $endpoint = $this->getEndpoint($category, $action);
        $path = $endpoint['path'];
        
        // 替换路径参数
        foreach ($params as $key => $value) {
            $path = str_replace('{' . $key . '}', $value, $path);
        }
        
        // 构建完整URL
        $fullUrl = $this->baseUrl . '/api/' . $this->version . $path;
        return $fullUrl;
    }
    
    /**
     * 获取HTTP方法
     * 
     * @param string $category 端点类别
     * @param string $action 端点动作
     * @return string HTTP方法
     */
    public function getMethod($category, $action) {
        $endpoint = $this->getEndpoint($category, $action);
        return $endpoint['method'];
    }
    
    /**
     * 获取端点描述
     * 
     * @param string $category 端点类别
     * @param string $action 端点动作
     * @return string 端点描述
     */
    public function getDescription($category, $action) {
        $endpoint = $this->getEndpoint($category, $action);
        return $endpoint['description'];
    }
    
    /**
     * 列出所有端点
     * 
     * @param string|null $category 指定类别，null表示所有类别
     * @return array 端点列表
     */
    public function listEndpoints($category = null) {
        if ($category !== null) {
            if (!isset($this->config['endpoints'][$category])) {
                throw new Exception("未知的端点类别: " . $category);
            }
            return [$category => $this->config['endpoints'][$category]];
        } else {
            return $this->config['endpoints'];
        }
    }
    
    /**
     * 验证端点是否存在
     * 
     * @param string $category 端点类别
     * @param string $action 端点动作
     * @return bool 是否存在
     */
    public function validateEndpoint($category, $action) {
        try {
            $this->getEndpoint($category, $action);
            return true;
        } catch (Exception $e) {
            return false;
        }
    }
    
    /**
     * 获取所有端点类别
     * 
     * @return array 类别列表
     */
    public function getAllCategories() {
        return array_keys($this->config['endpoints']);
    }
    
    /**
     * 获取指定类别的所有动作
     * 
     * @param string $category 端点类别
     * @return array 动作列表
     */
    public function getCategoryActions($category) {
        if (!isset($this->config['endpoints'][$category])) {
            throw new Exception("未知的端点类别: " . $category);
        }
        
        return array_keys($this->config['endpoints'][$category]);
    }
    
    /**
     * 导出配置到文件
     * 
     * @param string|null $outputPath 输出文件路径
     * @return string 导出的文件路径
     */
    public function exportConfig($outputPath = null) {
        if ($outputPath === null) {
            $outputPath = $this->configPath;
        }
        
        $configJson = json_encode($this->config, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        file_put_contents($outputPath, $configJson);
        
        return $outputPath;
    }
    
    /**
     * 获取基础URL
     * 
     * @return string 基础URL
     */
    public function getBaseUrl() {
        return $this->baseUrl;
    }
    
    /**
     * 获取API版本
     * 
     * @return string API版本
     */
    public function getVersion() {
        return $this->version;
    }
    
    /**
     * 获取请求超时时间
     * 
     * @return int 超时时间
     */
    public function getTimeout() {
        return $this->timeout;
    }
}

// 创建全局实例
$unifiedApiPathBuilder = new UnifiedAPIPathBuilder();

/**
 * 便捷函数：构建API URL
 * 
 * @param string $category 端点类别
 * @param string $action 端点动作
 * @param array $params URL参数
 * @return string 完整的API URL
 */
function buildApiUrl($category, $action, $params = []) {
    global $unifiedApiPathBuilder;
    return $unifiedApiPathBuilder->buildUrl($category, $action, $params);
}

/**
 * 便捷函数：获取HTTP方法
 * 
 * @param string $category 端点类别
 * @param string $action 端点动作
 * @return string HTTP方法
 */
function getApiMethod($category, $action) {
    global $unifiedApiPathBuilder;
    return $unifiedApiPathBuilder->getMethod($category, $action);
}

/**
 * 便捷函数：获取API路径构建器实例
 * 
 * @return UnifiedAPIPathBuilder
 */
function getApiPathBuilder() {
    global $unifiedApiPathBuilder;
    return $unifiedApiPathBuilder;
}
