<?php

require_once __DIR__ . '/APIPathBuilder.php';

/**
 * API路径构建器集成类
 * 提供与现有前端代码的集成接口
 */

class ApiPathBuilderIntegration {
    /**
     * API路径构建器实例
     * @var APIPathBuilder
     */
    private static $instance = null;
    
    /**
     * API客户端实例
     * @var ApiClient
     */
    private $apiClient = null;
    
    /**
     * 获取单例实例
     * 
     * @param string $baseUrl 基础URL
     * @param string $version API版本
     * @return ApiPathBuilderIntegration 单例实例
     */
    public static function getInstance($baseUrl = '', $version = 'v1') {
        if (self::$instance === null) {
            self::$instance = new self($baseUrl, $version);
        }
        
        return self::$instance;
    }
    
    /**
     * 私有构造函数
     * 
     * @param string $baseUrl 基础URL
     * @param string $version API版本
     */
    private function __construct($baseUrl, $version) {
        $this->apiPathBuilder = new APIPathBuilder($baseUrl, $version);
    }
    
    /**
     * 设置API客户端
     * 
     * @param ApiClient $apiClient API客户端实例
     */
    public function setApiClient($apiClient) {
        $this->apiClient = $apiClient;
    }
    
    /**
     * 获取API路径构建器实例
     * 
     * @return APIPathBuilder API路径构建器实例
     */
    public function getApiPathBuilder() {
        return $this->apiPathBuilder;
    }
    
    /**
     * 构建API路径
     * 
     * @param string $pathName 路径名称
     * @param array $params 路径参数
     * @param string $version API版本
     * @return string 构建的路径
     */
    public function buildPath($pathName, $params = [], $version = null) {
        return $this->apiPathBuilder->buildPath($pathName, $params, $version);
    }
    
    /**
     * 构建API URL
     * 
     * @param string $pathName 路径名称
     * @param array $params 路径参数
     * @param array $queryParams 查询参数
     * @param string $version API版本
     * @return string 构建的URL
     */
    public function buildUrl($pathName, $params = [], $queryParams = [], $version = null) {
        return $this->apiPathBuilder->buildUrl($pathName, $params, $queryParams, $version);
    }
    
    /**
     * 执行GET请求
     * 
     * @param string $pathName 路径名称
     * @param array $params 路径参数
     * @param array $queryParams 查询参数
     * @param string $version API版本
     * @return array 请求结果
     */
    public function get($pathName, $params = [], $queryParams = [], $version = null) {
        $url = $this->buildUrl($pathName, $params, $queryParams, $version);
        return $this->executeRequest('GET', $url);
    }
    
    /**
     * 执行POST请求
     * 
     * @param string $pathName 路径名称
     * @param array $params 路径参数
     * @param array $data 请求数据
     * @param string $version API版本
     * @return array 请求结果
     */
    public function post($pathName, $params = [], $data = [], $version = null) {
        $url = $this->buildPath($pathName, $params, $version);
        return $this->executeRequest('POST', $url, $data);
    }
    
    /**
     * 执行PUT请求
     * 
     * @param string $pathName 路径名称
     * @param array $params 路径参数
     * @param array $data 请求数据
     * @param string $version API版本
     * @return array 请求结果
     */
    public function put($pathName, $params = [], $data = [], $version = null) {
        $url = $this->buildPath($pathName, $params, $version);
        return $this->executeRequest('PUT', $url, $data);
    }
    
    /**
     * 执行DELETE请求
     * 
     * @param string $pathName 路径名称
     * @param array $params 路径参数
     * @param string $version API版本
     * @return array 请求结果
     */
    public function delete($pathName, $params = [], $version = null) {
        $url = $this->buildPath($pathName, $params, $version);
        return $this->executeRequest('DELETE', $url);
    }
    
    /**
     * 执行HTTP请求
     * 
     * @param string $method HTTP方法
     * @param string $url 请求URL
     * @param array $data 请求数据
     * @return array 请求结果
     */
    private function executeRequest($method, $url, $data = []) {
        if ($this->apiClient === null) {
            throw new RuntimeException("API客户端未设置");
        }
        
        switch (strtoupper($method)) {
            case 'GET':
                return $this->apiClient->get($url);
            case 'POST':
                return $this->apiClient->post($url, $data);
            case 'PUT':
                return $this->apiClient->put($url, $data);
            case 'DELETE':
                return $this->apiClient->delete($url);
            default:
                throw new InvalidArgumentException("不支持的HTTP方法: {$method}");
        }
    }
    
    /**
     * 验证路径
     * 
     * @param string $pathName 路径名称
     * @param array $params 路径参数
     * @param string $version API版本
     * @return array 验证结果
     */
    public function validatePath($pathName, $params = [], $version = null) {
        return $this->apiPathBuilder->validatePath($pathName, $params, $version);
    }
    
    /**
     * 添加路径定义
     * 
     * @param string $name 路径名称
     * @param string $path 路径模式
     * @param array $versions 支持的版本
     * @param array $methods 支持的HTTP方法
     */
    public function addPath($name, $path, $versions = ['v1'], $methods = ['GET']) {
        $this->apiPathBuilder->addPath($name, $path, $versions, $methods);
    }
    
    /**
     * 更新路径定义
     * 
     * @param string $name 路径名称
     * @param array $data 新的路径数据
     */
    public function updatePath($name, $data) {
        $this->apiPathBuilder->updatePath($name, $data);
    }
    
    /**
     * 删除路径定义
     * 
     * @param string $name 路径名称
     */
    public function removePath($name) {
        $this->apiPathBuilder->removePath($name);
    }
    
    /**
     * 设置当前API版本
     * 
     * @param string $version 要设置的API版本
     */
    public function setCurrentVersion($version) {
        $this->apiPathBuilder->setCurrentVersion($version);
    }
    
    /**
     * 获取当前API版本
     * 
     * @return string 当前API版本
     */
    public function getCurrentVersion() {
        return $this->apiPathBuilder->getCurrentVersion();
    }
    
    /**
     * 获取所有路径定义
     * 
     * @return array 所有路径定义
     */
    public function getAllPaths() {
        return $this->apiPathBuilder->getAllPaths();
    }
    
    /**
     * 获取特定版本的路径定义
     * 
     * @param string $version API版本
     * @return array 特定版本的路径定义
     */
    public function getPathsForVersion($version) {
        return $this->apiPathBuilder->getPathsForVersion($version);
    }
    
    /**
     * 获取路径信息
     * 
     * @param string $pathName 路径名称
     * @return array|null 路径信息或null
     */
    public function getPathInfo($pathName) {
        return $this->apiPathBuilder->getPathInfo($pathName);
    }
    
    /**
     * 检查路径是否存在
     * 
     * @param string $pathName 路径名称
     * @return bool 路径是否存在
     */
    public function pathExists($pathName) {
        return $this->apiPathBuilder->pathExists($pathName);
    }
    
    /**
     * 获取路径参数
     * 
     * @param string $pathName 路径名称
     * @return array 路径参数数组
     */
    public function getPathParameters($pathName) {
        return $this->apiPathBuilder->getPathParameters($pathName);
    }
    
    /**
     * 获取支持版本的路径
     * 
     * @param string $pathName 路径名称
     * @return array 支持的版本数组
     */
    public function getSupportedVersionsForPath($pathName) {
        return $this->apiPathBuilder->getSupportedVersionsForPath($pathName);
    }
    
    /**
     * 获取支持方法的路径
     * 
     * @param string $pathName 路径名称
     * @return array 支持的方法数组
     */
    public function getSupportedMethodsForPath($pathName) {
        return $this->apiPathBuilder->getSupportedMethodsForPath($pathName);
    }
    
    /**
     * 生成API文档
     * 
     * @param string $version API版本
     * @return array API文档数据
     */
    public function generateApiDocumentation($version = null) {
        $version = $version ?: $this->getCurrentVersion();
        $paths = $this->getPathsForVersion($version);
        $documentation = [
            'version' => $version,
            'baseUrl' => $this->apiPathBuilder->baseUrl,
            'paths' => []
        ];
        
        foreach ($paths as $name => $pathInfo) {
            $pathDoc = [
                'name' => $name,
                'path' => $pathInfo['path'],
                'methods' => $pathInfo['methods'],
                'parameters' => $this->getPathParameters($name),
                'metadata' => $this->apiPathBuilder->getPathConfig()->getAllMetadata($name)
            ];
            
            $documentation['paths'][] = $pathDoc;
        }
        
        return $documentation;
    }
    
    /**
     * 导出路径配置
     * 
     * @return array 路径配置数据
     */
    public function exportPathConfiguration() {
        return [
            'version' => $this->getCurrentVersion(),
            'baseUrl' => $this->apiPathBuilder->baseUrl,
            'paths' => $this->getAllPaths(),
            'supportedVersions' => $this->apiPathBuilder->getVersionManager()->getSupportedVersions(),
            'deprecatedVersions' => $this->apiPathBuilder->getVersionManager()->getDeprecatedVersions()
        ];
    }
    
    /**
     * 导入路径配置
     * 
     * @param array $config 路径配置数据
     */
    public function importPathConfiguration($config) {
        if (isset($config['version'])) {
            $this->setCurrentVersion($config['version']);
        }
        
        if (isset($config['paths'])) {
            foreach ($config['paths'] as $name => $pathInfo) {
                $this->addPath(
                    $name,
                    $pathInfo['path'],
                    $pathInfo['versions'],
                    $pathInfo['methods']
                );
            }
        }
    }
}

?>