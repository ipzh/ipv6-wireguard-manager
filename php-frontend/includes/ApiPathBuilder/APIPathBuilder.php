<?php

require_once __DIR__ . '/VersionManager.php';
require_once __DIR__ . '/PathConfig.php';
require_once __DIR__ . '/PathValidator.php';

/**
 * API路径构建器
 * 负责构建、验证和管理API路径
 */

class APIPathBuilder {
    /**
     * 版本管理器实例
     * @var VersionManager
     */
    private $versionManager;
    
    /**
     * 路径配置实例
     * @var PathConfig
     */
    private $pathConfig;
    
    /**
     * 路径验证器实例
     * @var PathValidator
     */
    private $pathValidator;
    
    /**
     * 基础URL
     * @var string
     */
    private $baseUrl;
    
    /**
     * 当前API版本
     * @var string
     */
    private $currentVersion;
    
    /**
     * 路径构建缓存
     * @var array
     */
    private $pathCache;
    
    /**
     * 构造函数
     * 
     * @param string $baseUrl 基础URL
     * @param string $currentVersion 当前API版本
     */
    public function __construct($baseUrl = '', $currentVersion = 'v1') {
        $this->baseUrl = rtrim($baseUrl, '/');
        $this->currentVersion = $currentVersion;
        $this->pathCache = [];
        
        $this->versionManager = new VersionManager($currentVersion);
        $this->pathConfig = new PathConfig($this->versionManager);
        $this->pathValidator = new PathValidator($this->pathConfig);
    }
    
    /**
     * 构建API路径
     * 
     * @param string $pathName 路径名称
     * @param array $params 路径参数
     * @param string $version API版本
     * @return string 构建的路径
     * @throws InvalidArgumentException 如果路径无效
     */
    public function buildPath($pathName, $params = [], $version = null) {
        $version = $version ?: $this->currentVersion;
        
        // 检查缓存
        $cacheKey = $this->generateCacheKey($pathName, $params, $version);
        if (isset($this->pathCache[$cacheKey])) {
            return $this->pathCache[$cacheKey];
        }
        
        // 获取路径定义
        $pathInfo = $this->pathConfig->getPath($pathName);
        if (!$pathInfo) {
            throw new InvalidArgumentException("未知的路径名称: {$pathName}");
        }
        
        // 验证路径请求
        $validationResult = $this->pathValidator->validatePathRequest($pathName, $version, 'GET', $params);
        if (!$validationResult['valid']) {
            throw new InvalidArgumentException("路径验证失败: " . implode(', ', $validationResult['errors']));
        }
        
        // 构建路径
        $path = $pathInfo['path'];
        
        // 替换路径参数
        foreach ($params as $paramName => $paramValue) {
            $path = str_replace('{' . $paramName . '}', $paramValue, $path);
        }
        
        // 检查是否还有未替换的参数
        if (preg_match('/\{[^}]+\}/', $path)) {
            throw new InvalidArgumentException("路径包含未替换的参数");
        }
        
        // 构建完整URL
        $fullPath = $this->baseUrl . '/' . $version . $path;
        
        // 缓存结果
        $this->pathCache[$cacheKey] = $fullPath;
        
        return $fullPath;
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
        $path = $this->buildPath($pathName, $params, $version);
        
        if (empty($queryParams)) {
            return $path;
        }
        
        $queryString = http_build_query($queryParams);
        return $path . '?' . $queryString;
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
        $version = $version ?: $this->currentVersion;
        return $this->pathValidator->validatePathRequest($pathName, $version, 'GET', $params);
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
        // 验证路径定义
        $pathData = [
            'path' => $path,
            'versions' => $versions,
            'methods' => $methods
        ];
        
        $validationResult = $this->pathValidator->validatePathDefinition($name, $pathData);
        if (!$validationResult['valid']) {
            throw new InvalidArgumentException("路径定义无效: " . implode(', ', $validationResult['errors']));
        }
        
        $this->pathConfig->addPath($name, $path, $versions, $methods);
        
        // 清除相关缓存
        $this->clearCacheForPath($name);
    }
    
    /**
     * 更新路径定义
     * 
     * @param string $name 路径名称
     * @param array $data 新的路径数据
     */
    public function updatePath($name, $data) {
        $pathInfo = $this->pathConfig->getPath($name);
        if (!$pathInfo) {
            throw new InvalidArgumentException("未知的路径名称: {$name}");
        }
        
        $updatedData = array_merge($pathInfo, $data);
        $validationResult = $this->pathValidator->validatePathDefinition($name, $updatedData);
        if (!$validationResult['valid']) {
            throw new InvalidArgumentException("路径定义无效: " . implode(', ', $validationResult['errors']));
        }
        
        $this->pathConfig->updatePath($name, $data);
        
        // 清除相关缓存
        $this->clearCacheForPath($name);
    }
    
    /**
     * 删除路径定义
     * 
     * @param string $name 路径名称
     */
    public function removePath($name) {
        $this->pathConfig->removePath($name);
        
        // 清除相关缓存
        $this->clearCacheForPath($name);
    }
    
    /**
     * 添加路径参数定义
     * 
     * @param string $pathName 路径名称
     * @param string $paramName 参数名称
     * @param array $paramData 参数数据
     */
    public function addParameter($pathName, $paramName, $paramData) {
        $this->pathConfig->addParameter($pathName, $paramName, $paramData);
        
        // 清除相关缓存
        $this->clearCacheForPath($pathName);
    }
    
    /**
     * 添加路径元数据
     * 
     * @param string $pathName 路径名称
     * @param string $key 元数据键
     * @param mixed $value 元数据值
     */
    public function addMetadata($pathName, $key, $value) {
        $this->pathConfig->addMetadata($pathName, $key, $value);
    }
    
    /**
     * 设置当前API版本
     * 
     * @param string $version 要设置的API版本
     */
    public function setCurrentVersion($version) {
        $this->versionManager->setCurrentVersion($version);
        $this->currentVersion = $version;
        
        // 清除所有缓存，因为版本可能影响所有路径
        $this->pathCache = [];
    }
    
    /**
     * 获取当前API版本
     * 
     * @return string 当前API版本
     */
    public function getCurrentVersion() {
        return $this->currentVersion;
    }
    
    /**
     * 获取版本管理器
     * 
     * @return VersionManager 版本管理器实例
     */
    public function getVersionManager() {
        return $this->versionManager;
    }
    
    /**
     * 获取路径配置
     * 
     * @return PathConfig 路径配置实例
     */
    public function getPathConfig() {
        return $this->pathConfig;
    }
    
    /**
     * 获取路径验证器
     * 
     * @return PathValidator 路径验证器实例
     */
    public function getPathValidator() {
        return $this->pathValidator;
    }
    
    /**
     * 获取所有路径定义
     * 
     * @return array 所有路径定义
     */
    public function getAllPaths() {
        return $this->pathConfig->getAllPaths();
    }
    
    /**
     * 获取特定版本的路径定义
     * 
     * @param string $version API版本
     * @return array 特定版本的路径定义
     */
    public function getPathsForVersion($version) {
        return $this->pathConfig->getPathsForVersion($version);
    }
    
    /**
     * 获取路径信息
     * 
     * @param string $pathName 路径名称
     * @return array|null 路径信息或null
     */
    public function getPathInfo($pathName) {
        return $this->pathConfig->getPath($pathName);
    }
    
    /**
     * 清除路径缓存
     * 
     * @param string $pathName 路径名称，如果为null则清除所有缓存
     */
    public function clearCache($pathName = null) {
        if ($pathName === null) {
            $this->pathCache = [];
        } else {
            $this->clearCacheForPath($pathName);
        }
    }
    
    /**
     * 生成缓存键
     * 
     * @param string $pathName 路径名称
     * @param array $params 路径参数
     * @param string $version API版本
     * @return string 缓存键
     */
    private function generateCacheKey($pathName, $params, $version) {
        return $pathName . ':' . $version . ':' . md5(serialize($params));
    }
    
    /**
     * 清除特定路径的缓存
     * 
     * @param string $pathName 路径名称
     */
    private function clearCacheForPath($pathName) {
        foreach ($this->pathCache as $key => $value) {
            if (strpos($key, $pathName . ':') === 0) {
                unset($this->pathCache[$key]);
            }
        }
    }
    
    /**
     * 获取路径参数
     * 
     * @param string $pathName 路径名称
     * @return array 路径参数数组
     */
    public function getPathParameters($pathName) {
        $pathInfo = $this->pathConfig->getPath($pathName);
        if (!$pathInfo) {
            return [];
        }
        
        $pathPattern = $pathInfo['path'];
        preg_match_all('/\{([^}]+)\}/', $pathPattern, $matches);
        return $matches[1];
    }
    
    /**
     * 检查路径是否存在
     * 
     * @param string $pathName 路径名称
     * @return bool 路径是否存在
     */
    public function pathExists($pathName) {
        return $this->pathConfig->getPath($pathName) !== null;
    }
    
    /**
     * 获取支持版本的路径
     * 
     * @param string $pathName 路径名称
     * @return array 支持的版本数组
     */
    public function getSupportedVersionsForPath($pathName) {
        $pathInfo = $this->pathConfig->getPath($pathName);
        return $pathInfo ? $pathInfo['versions'] : [];
    }
    
    /**
     * 获取支持方法的路径
     * 
     * @param string $pathName 路径名称
     * @return array 支持的方法数组
     */
    public function getSupportedMethodsForPath($pathName) {
        $pathInfo = $this->pathConfig->getPath($pathName);
        return $pathInfo ? $pathInfo['methods'] : [];
    }
}

?>