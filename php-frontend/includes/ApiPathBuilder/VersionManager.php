<?php

/**
 * API版本管理器
 * 负责管理API版本，包括当前版本、支持版本和已弃用版本
 */

class VersionManager {
    /**
     * 当前API版本
     * @var string
     */
    private $currentVersion;
    
    /**
     * 支持的API版本集合
     * @var array
     */
    private $supportedVersions;
    
    /**
     * 已弃用的API版本集合
     * @var array
     */
    private $deprecatedVersions;
    
    /**
     * 各版本的端点映射
     * @var array
     */
    private $versionEndpoints;
    
    /**
     * 构造函数
     * 
     * @param string $currentVersion 当前API版本
     */
    public function __construct($currentVersion = 'v1') {
        $this->currentVersion = $currentVersion;
        $this->supportedVersions = ['v1'];
        $this->deprecatedVersions = [];
        $this->versionEndpoints = [];
        $this->initializeDefaultVersions();
    }
    
    /**
     * 初始化默认版本配置
     */
    private function initializeDefaultVersions() {
        $this->supportedVersions = ['v1'];
        $this->deprecatedVersions = [];
        
        // 初始化各版本支持的端点
        $this->versionEndpoints = [
            'v1' => [],
            'v2' => [],
            'v3' => []
        ];
    }
    
    /**
     * 设置当前API版本
     * 
     * @param string $version 要设置的API版本
     * @throws InvalidArgumentException 如果版本不被支持
     */
    public function setCurrentVersion($version) {
        if (!$this->isVersionSupported($version)) {
            throw new InvalidArgumentException("版本 {$version} 不被支持");
        }
        $this->currentVersion = $version;
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
     * 添加支持的API版本
     * 
     * @param string $version 要添加的API版本
     */
    public function addSupportedVersion($version) {
        if (!in_array($version, $this->supportedVersions)) {
            $this->supportedVersions[] = $version;
        }
        
        // 如果版本在已弃用列表中，则移除
        $key = array_search($version, $this->deprecatedVersions);
        if ($key !== false) {
            unset($this->deprecatedVersions[$key]);
            $this->deprecatedVersions = array_values($this->deprecatedVersions);
        }
        
        // 确保版本端点映射存在
        if (!isset($this->versionEndpoints[$version])) {
            $this->versionEndpoints[$version] = [];
        }
    }
    
    /**
     * 添加已弃用的API版本
     * 
     * @param string $version 要标记为已弃用的API版本
     */
    public function addDeprecatedVersion($version) {
        // 从支持版本中移除
        $key = array_search($version, $this->supportedVersions);
        if ($key !== false) {
            unset($this->supportedVersions[$key]);
            $this->supportedVersions = array_values($this->supportedVersions);
        }
        
        // 添加到已弃用列表
        if (!in_array($version, $this->deprecatedVersions)) {
            $this->deprecatedVersions[] = $version;
        }
    }
    
    /**
     * 完全移除API版本
     * 
     * @param string $version 要移除的API版本
     */
    public function removeVersion($version) {
        // 从支持版本中移除
        $key = array_search($version, $this->supportedVersions);
        if ($key !== false) {
            unset($this->supportedVersions[$key]);
            $this->supportedVersions = array_values($this->supportedVersions);
        }
        
        // 从已弃用版本中移除
        $key = array_search($version, $this->deprecatedVersions);
        if ($key !== false) {
            unset($this->deprecatedVersions[$key]);
            $this->deprecatedVersions = array_values($this->deprecatedVersions);
        }
        
        // 移除版本端点映射
        if (isset($this->versionEndpoints[$version])) {
            unset($this->versionEndpoints[$version]);
        }
    }
    
    /**
     * 检查版本是否被支持
     * 
     * @param string $version 要检查的API版本
     * @return bool 版本是否被支持
     */
    public function isVersionSupported($version) {
        return in_array($version, $this->supportedVersions);
    }
    
    /**
     * 检查版本是否已弃用
     * 
     * @param string $version 要检查的API版本
     * @return bool 版本是否已弃用
     */
    public function isVersionDeprecated($version) {
        return in_array($version, $this->deprecatedVersions);
    }
    
    /**
     * 获取所有支持的API版本
     * 
     * @return array 支持的API版本列表
     */
    public function getSupportedVersions() {
        sort($this->supportedVersions);
        return $this->supportedVersions;
    }
    
    /**
     * 获取所有已弃用的API版本
     * 
     * @return array 已弃用的API版本列表
     */
    public function getDeprecatedVersions() {
        sort($this->deprecatedVersions);
        return $this->deprecatedVersions;
    }
    
    /**
     * 为特定版本注册端点
     * 
     * @param string $version API版本
     * @param string $endpoint 端点路径
     */
    public function registerEndpoint($version, $endpoint) {
        if (!isset($this->versionEndpoints[$version])) {
            $this->versionEndpoints[$version] = [];
        }
        
        if (!in_array($endpoint, $this->versionEndpoints[$version])) {
            $this->versionEndpoints[$version][] = $endpoint;
        }
    }
    
    /**
     * 获取特定版本的所有端点
     * 
     * @param string $version API版本
     * @return array 端点路径数组
     */
    public function getEndpointsForVersion($version) {
        return isset($this->versionEndpoints[$version]) ? $this->versionEndpoints[$version] : [];
    }
    
    /**
     * 获取所有版本的端点
     * 
     * @return array 所有版本的端点映射
     */
    public function getAllEndpoints() {
        return $this->versionEndpoints;
    }
    
    /**
     * 验证端点是否属于特定版本
     * 
     * @param string $version API版本
     * @param string $endpoint 端点路径
     * @return bool 端点是否属于该版本
     */
    public function validateEndpointForVersion($version, $endpoint) {
        $endpoints = $this->getEndpointsForVersion($version);
        return in_array($endpoint, $endpoints);
    }
    
    /**
     * 将端点从一个版本迁移到另一个版本
     * 
     * @param string $fromVersion 源版本
     * @param string $toVersion 目标版本
     * @param string $endpoint 要迁移的端点
     */
    public function migrateEndpoint($fromVersion, $toVersion, $endpoint) {
        $fromEndpoints = $this->getEndpointsForVersion($fromVersion);
        $key = array_search($endpoint, $fromEndpoints);
        
        if ($key !== false) {
            // 从源版本中移除
            unset($this->versionEndpoints[$fromVersion][$key]);
            $this->versionEndpoints[$fromVersion] = array_values($this->versionEndpoints[$fromVersion]);
            
            // 添加到目标版本
            $this->registerEndpoint($toVersion, $endpoint);
        }
    }
}

?>