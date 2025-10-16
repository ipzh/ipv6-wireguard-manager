<?php
/**
 * 增强的API客户端 - 使用端点映射
 */
require_once 'ApiClient.php';
require_once '../config/api_endpoints.php';

class EnhancedApiClient extends ApiClient {
    private $endpoints;
    
    public function __construct($baseUrl = null, $timeout = 30, $retryCount = 3, $debugMode = false) {
        parent::__construct($baseUrl, $timeout, $retryCount, $debugMode);
        $this->endpoints = require '../config/api_endpoints.php';
    }
    
    /**
     * 获取端点路径
     */
    private function getEndpoint($category, $action, $params = []) {
        if (!isset($this->endpoints[$category][$action])) {
            throw new Exception("API端点不存在: $category.$action");
        }
        
        $endpoint = $this->endpoints[$category][$action];
        
        // 替换路径参数
        foreach ($params as $key => $value) {
            $endpoint = str_replace("{{$key}}", $value, $endpoint);
        }
        
        return $endpoint;
    }
    
    /**
     * 认证相关API
     */
    public function authLogin($credentials) {
        $endpoint = $this->getEndpoint('auth', 'login');
        return $this->post($endpoint, $credentials);
    }
    
    public function authLogout() {
        $endpoint = $this->getEndpoint('auth', 'logout');
        return $this->post($endpoint);
    }
    
    public function authMe() {
        $endpoint = $this->getEndpoint('auth', 'me');
        return $this->get($endpoint);
    }
    
    /**
     * WireGuard相关API
     */
    public function wireguardGetServers() {
        $endpoint = $this->getEndpoint('wireguard', 'servers');
        return $this->get($endpoint);
    }
    
    public function wireguardGetClients() {
        $endpoint = $this->getEndpoint('wireguard', 'clients');
        return $this->get($endpoint);
    }
    
    public function wireguardGetConfig() {
        $endpoint = $this->getEndpoint('wireguard', 'config');
        return $this->get($endpoint);
    }
    
    public function wireguardUpdateConfig($config) {
        $endpoint = $this->getEndpoint('wireguard', 'config');
        return $this->post($endpoint, $config);
    }
    
    public function wireguardGetStatus() {
        $endpoint = $this->getEndpoint('wireguard', 'status');
        return $this->get($endpoint);
    }
    
    /**
     * BGP相关API
     */
    public function bgpGetSessions() {
        $endpoint = $this->getEndpoint('bgp', 'sessions');
        return $this->get($endpoint);
    }
    
    public function bgpGetRoutes() {
        $endpoint = $this->getEndpoint('bgp', 'routes');
        return $this->get($endpoint);
    }
    
    public function bgpGetStatus() {
        $endpoint = $this->getEndpoint('bgp', 'status');
        return $this->get($endpoint);
    }
    
    /**
     * IPv6相关API
     */
    public function ipv6GetPools() {
        $endpoint = $this->getEndpoint('ipv6', 'pools');
        return $this->get($endpoint);
    }
    
    public function ipv6GetAllocations() {
        $endpoint = $this->getEndpoint('ipv6', 'allocations');
        return $this->get($endpoint);
    }
    
    /**
     * 监控相关API
     */
    public function monitoringGetDashboard() {
        $endpoint = $this->getEndpoint('monitoring', 'dashboard');
        return $this->get($endpoint);
    }
    
    public function monitoringGetSystemMetrics() {
        $endpoint = $this->getEndpoint('monitoring', 'metrics_system');
        return $this->get($endpoint);
    }
    
    public function monitoringGetApplicationMetrics() {
        $endpoint = $this->getEndpoint('monitoring', 'metrics_application');
        return $this->get($endpoint);
    }
    
    public function monitoringGetActiveAlerts() {
        $endpoint = $this->getEndpoint('monitoring', 'alerts_active');
        return $this->get($endpoint);
    }
    
    /**
     * 日志相关API
     */
    public function logsGetList($params = []) {
        $endpoint = $this->getEndpoint('logs', 'list');
        if (!empty($params)) {
            $endpoint .= '?' . http_build_query($params);
        }
        return $this->get($endpoint);
    }
    
    public function logsGetById($logId) {
        $endpoint = $this->getEndpoint('logs', 'get', ['id' => $logId]);
        return $this->get($endpoint);
    }
    
    /**
     * 系统相关API
     */
    public function systemGetInfo() {
        $endpoint = $this->getEndpoint('system', 'info');
        return $this->get($endpoint);
    }
    
    public function systemGetProcesses() {
        $endpoint = $this->getEndpoint('system', 'processes');
        return $this->get($endpoint);
    }
    
    /**
     * 网络相关API
     */
    public function networkGetInterfaces() {
        $endpoint = $this->getEndpoint('network', 'interfaces');
        return $this->get($endpoint);
    }
    
    public function networkGetStatus() {
        $endpoint = $this->getEndpoint('network', 'status');
        return $this->get($endpoint);
    }
    
    /**
     * 调试相关API
     */
    public function debugGetSystemInfo() {
        $endpoint = $this->getEndpoint('debug', 'system_info');
        return $this->get($endpoint);
    }
    
    public function debugGetComprehensiveCheck() {
        $endpoint = $this->getEndpoint('debug', 'comprehensive_check');
        return $this->get($endpoint);
    }
    
    /**
     * 获取所有可用的端点
     */
    public function getAvailableEndpoints() {
        return $this->endpoints;
    }
    
    /**
     * 测试所有端点连接
     */
    public function testAllEndpoints() {
        $results = [];
        
        foreach ($this->endpoints as $category => $actions) {
            $results[$category] = [];
            
            foreach ($actions as $action => $endpoint) {
                try {
                    // 只测试GET端点
                    if (strpos($endpoint, '{') === false) { // 不包含路径参数
                        $response = $this->get($endpoint);
                        $results[$category][$action] = [
                            'status' => 'success',
                            'endpoint' => $endpoint,
                            'response_code' => $response['status']
                        ];
                    } else {
                        $results[$category][$action] = [
                            'status' => 'skipped',
                            'endpoint' => $endpoint,
                            'reason' => 'Contains path parameters'
                        ];
                    }
                } catch (Exception $e) {
                    $results[$category][$action] = [
                        'status' => 'error',
                        'endpoint' => $endpoint,
                        'error' => $e->getMessage()
                    ];
                }
            }
        }
        
        return $results;
    }
}
?>
