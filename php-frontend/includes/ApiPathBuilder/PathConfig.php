<?php

require_once __DIR__ . '/VersionManager.php';

/**
 * 路径配置管理器
 * 负责管理API路径配置，包括路径定义、参数和元数据
 */

class PathConfig {
    /**
     * 路径定义数组
     * @var array
     */
    private $paths;
    
    /**
     * 路径参数定义
     * @var array
     */
    private $parameters;
    
    /**
     * 路径元数据
     * @var array
     */
    private $metadata;
    
    /**
     * 版本管理器实例
     * @var VersionManager
     */
    private $versionManager;
    
    /**
     * 构造函数
     * 
     * @param VersionManager $versionManager 版本管理器实例
     */
    public function __construct(VersionManager $versionManager = null) {
        $this->paths = [];
        $this->parameters = [];
        $this->metadata = [];
        $this->versionManager = $versionManager ?: new VersionManager();
        $this->initializeDefaultPaths();
    }
    
    /**
     * 初始化默认路径配置
     */
    private function initializeDefaultPaths() {
        // 认证相关路径
        $this->addPath('login', '/auth/login', ['v1']);
        $this->addPath('logout', '/auth/logout', ['v1']);
        $this->addPath('refresh', '/auth/refresh', ['v1']);
        $this->addPath('register', '/auth/register', ['v1']);
        $this->addPath('verify', '/auth/verify', ['v1']);
        
        // 用户管理相关路径
        $this->addPath('users', '/users', ['v1']);
        $this->addPath('user_profile', '/users/{id}', ['v1']);
        $this->addPath('user_update', '/users/{id}', ['v1'], ['PUT', 'PATCH']);
        $this->addPath('user_delete', '/users/{id}', ['v1'], ['DELETE']);
        
        // WireGuard相关路径
        $this->addPath('wireguard_status', '/wireguard/status', ['v1']);
        $this->addPath('wireguard_peers', '/wireguard/peers', ['v1']);
        $this->addPath('wireguard_peer', '/wireguard/peers/{id}', ['v1']);
        $this->addPath('wireguard_peer_add', '/wireguard/peers', ['v1'], ['POST']);
        $this->addPath('wireguard_peer_update', '/wireguard/peers/{id}', ['v1'], ['PUT', 'PATCH']);
        $this->addPath('wireguard_peer_delete', '/wireguard/peers/{id}', ['v1'], ['DELETE']);
        $this->addPath('wireguard_config', '/wireguard/config', ['v1']);
        $this->addPath('wireguard_config_download', '/wireguard/config/download', ['v1']);
        
        // BGP相关路径
        $this->addPath('bgp_status', '/bgp/status', ['v1']);
        $this->addPath('bgp_neighbors', '/bgp/neighbors', ['v1']);
        $this->addPath('bgp_neighbor', '/bgp/neighbors/{id}', ['v1']);
        $this->addPath('bgp_neighbor_add', '/bgp/neighbors', ['v1'], ['POST']);
        $this->addPath('bgp_neighbor_update', '/bgp/neighbors/{id}', ['v1'], ['PUT', 'PATCH']);
        $this->addPath('bgp_neighbor_delete', '/bgp/neighbors/{id}', ['v1'], ['DELETE']);
        
        // IPv6相关路径
        $this->addPath('ipv6_status', '/ipv6/status', ['v1']);
        $this->addPath('ipv6_prefixes', '/ipv6/prefixes', ['v1']);
        $this->addPath('ipv6_prefix', '/ipv6/prefixes/{id}', ['v1']);
        $this->addPath('ipv6_prefix_add', '/ipv6/prefixes', ['v1'], ['POST']);
        $this->addPath('ipv6_prefix_update', '/ipv6/prefixes/{id}', ['v1'], ['PUT', 'PATCH']);
        $this->addPath('ipv6_prefix_delete', '/ipv6/prefixes/{id}', ['v1'], ['DELETE']);
        
        // 系统相关路径
        $this->addPath('system_info', '/system/info', ['v1']);
        $this->addPath('system_status', '/system/status', ['v1']);
        $this->addPath('system_logs', '/system/logs', ['v1']);
        $this->addPath('system_config', '/system/config', ['v1']);
        
        // 监控相关路径
        $this->addPath('monitoring_metrics', '/monitoring/metrics', ['v1']);
        $this->addPath('monitoring_alerts', '/monitoring/alerts', ['v1']);
        $this->addPath('monitoring_status', '/monitoring/status', ['v1']);
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
        $this->paths[$name] = [
            'path' => $path,
            'versions' => $versions,
            'methods' => $methods
        ];
        
        // 为每个版本注册端点
        foreach ($versions as $version) {
            $this->versionManager->registerEndpoint($version, $path);
        }
    }
    
    /**
     * 获取路径定义
     * 
     * @param string $name 路径名称
     * @return array|null 路径定义或null
     */
    public function getPath($name) {
        return isset($this->paths[$name]) ? $this->paths[$name] : null;
    }
    
    /**
     * 获取所有路径定义
     * 
     * @return array 所有路径定义
     */
    public function getAllPaths() {
        return $this->paths;
    }
    
    /**
     * 更新路径定义
     * 
     * @param string $name 路径名称
     * @param array $data 新的路径数据
     */
    public function updatePath($name, $data) {
        if (isset($this->paths[$name])) {
            $this->paths[$name] = array_merge($this->paths[$name], $data);
        }
    }
    
    /**
     * 删除路径定义
     * 
     * @param string $name 路径名称
     */
    public function removePath($name) {
        if (isset($this->paths[$name])) {
            // 从版本管理器中移除端点
            $pathInfo = $this->paths[$name];
            foreach ($pathInfo['versions'] as $version) {
                $endpoints = $this->versionManager->getEndpointsForVersion($version);
                $key = array_search($pathInfo['path'], $endpoints);
                if ($key !== false) {
                    unset($endpoints[$key]);
                    $endpoints = array_values($endpoints);
                    // 更新版本管理器中的端点列表
                    $this->versionManager->versionEndpoints[$version] = $endpoints;
                }
            }
            
            unset($this->paths[$name]);
        }
    }
    
    /**
     * 添加路径参数定义
     * 
     * @param string $pathName 路径名称
     * @param string $paramName 参数名称
     * @param array $paramData 参数数据
     */
    public function addParameter($pathName, $paramName, $paramData) {
        if (!isset($this->parameters[$pathName])) {
            $this->parameters[$pathName] = [];
        }
        
        $this->parameters[$pathName][$paramName] = $paramData;
    }
    
    /**
     * 获取路径参数定义
     * 
     * @param string $pathName 路径名称
     * @param string $paramName 参数名称
     * @return array|null 参数定义或null
     */
    public function getParameter($pathName, $paramName) {
        return isset($this->parameters[$pathName][$paramName]) 
            ? $this->parameters[$pathName][$paramName] 
            : null;
    }
    
    /**
     * 获取路径的所有参数定义
     * 
     * @param string $pathName 路径名称
     * @return array 参数定义数组
     */
    public function getParameters($pathName) {
        return isset($this->parameters[$pathName]) ? $this->parameters[$pathName] : [];
    }
    
    /**
     * 添加路径元数据
     * 
     * @param string $pathName 路径名称
     * @param string $key 元数据键
     * @param mixed $value 元数据值
     */
    public function addMetadata($pathName, $key, $value) {
        if (!isset($this->metadata[$pathName])) {
            $this->metadata[$pathName] = [];
        }
        
        $this->metadata[$pathName][$key] = $value;
    }
    
    /**
     * 获取路径元数据
     * 
     * @param string $pathName 路径名称
     * @param string $key 元数据键
     * @return mixed 元数据值或null
     */
    public function getMetadata($pathName, $key) {
        return isset($this->metadata[$pathName][$key]) 
            ? $this->metadata[$pathName][$key] 
            : null;
    }
    
    /**
     * 获取路径的所有元数据
     * 
     * @param string $pathName 路径名称
     * @return array 元数据数组
     */
    public function getAllMetadata($pathName) {
        return isset($this->metadata[$pathName]) ? $this->metadata[$pathName] : [];
    }
    
    /**
     * 获取版本管理器实例
     * 
     * @return VersionManager 版本管理器实例
     */
    public function getVersionManager() {
        return $this->versionManager;
    }
    
    /**
     * 获取特定版本的路径定义
     * 
     * @param string $version API版本
     * @return array 特定版本的路径定义
     */
    public function getPathsForVersion($version) {
        $versionPaths = [];
        
        foreach ($this->paths as $name => $pathInfo) {
            if (in_array($version, $pathInfo['versions'])) {
                $versionPaths[$name] = $pathInfo;
            }
        }
        
        return $versionPaths;
    }
    
    /**
     * 检查路径是否支持特定版本
     * 
     * @param string $pathName 路径名称
     * @param string $version API版本
     * @return bool 是否支持该版本
     */
    public function isPathSupportedInVersion($pathName, $version) {
        $pathInfo = $this->getPath($pathName);
        return $pathInfo ? in_array($version, $pathInfo['versions']) : false;
    }
    
    /**
     * 检查路径是否支持特定HTTP方法
     * 
     * @param string $pathName 路径名称
     * @param string $method HTTP方法
     * @return bool 是否支持该方法
     */
    public function isPathSupportedForMethod($pathName, $method) {
        $pathInfo = $this->getPath($pathName);
        return $pathInfo ? in_array(strtoupper($method), $pathInfo['methods']) : false;
    }
}

?>