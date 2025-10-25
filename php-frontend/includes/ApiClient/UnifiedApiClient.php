<?php

/**
 * 统一API客户端
 * 实现前后端API设计标准的一致性
 */

class UnifiedApiClient {
    /**
     * 基础URL
     * @var string
     */
    private $baseUrl;
    
    /**
     * 请求超时时间
     * @var int
     */
    private $timeout;
    
    /**
     * 访问令牌
     * @var string|null
     */
    private $accessToken;
    
    /**
     * 刷新令牌
     * @var string|null
     */
    private $refreshToken;
    
    /**
     * 用户代理
     * @var string
     */
    private $userAgent;
    
    /**
     * 请求头
     * @var array
     */
    private $headers;
    
    /**
     * 构造函数
     * 
     * @param string $baseUrl 基础URL
     * @param int $timeout 超时时间
     */
    public function __construct($baseUrl = null, $timeout = 30) {
        $this->baseUrl = $baseUrl ?: 'http://backend:8000';
        $this->timeout = $timeout;
        $this->userAgent = 'IPv6-WireGuard-Manager/3.1.0';
        $this->headers = [
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
            'User-Agent' => $this->userAgent
        ];
    }
    
    /**
     * 设置访问令牌
     * 
     * @param string $token 访问令牌
     */
    public function setAccessToken($token) {
        $this->accessToken = $token;
        $this->headers['Authorization'] = 'Bearer ' . $token;
    }
    
    /**
     * 设置刷新令牌
     * 
     * @param string $token 刷新令牌
     */
    public function setRefreshToken($token) {
        $this->refreshToken = $token;
    }
    
    /**
     * 清除令牌
     */
    public function clearTokens() {
        $this->accessToken = null;
        $this->refreshToken = null;
        unset($this->headers['Authorization']);
    }
    
    /**
     * 发送HTTP请求
     * 
     * @param string $method HTTP方法
     * @param string $endpoint 端点
     * @param array $data 请求数据
     * @param array $options 请求选项
     * @return array 响应数据
     * @throws Exception
     */
    public function request($method, $endpoint, $data = null, $options = []) {
        $url = $this->baseUrl . '/api/v1' . $endpoint;
        
        // 准备请求选项
        $requestOptions = [
            'http' => [
                'method' => $method,
                'header' => $this->buildHeaders(),
                'timeout' => $this->timeout,
                'ignore_errors' => true
            ]
        ];
        
        // 添加请求数据
        if ($data !== null) {
            $requestOptions['http']['content'] = json_encode($data);
        }
        
        // 发送请求
        $context = stream_context_create($requestOptions);
        $response = file_get_contents($url, false, $context);
        
        if ($response === false) {
            throw new Exception('请求失败: ' . error_get_last()['message']);
        }
        
        // 解析响应
        $responseData = json_decode($response, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new Exception('响应解析失败: ' . json_last_error_msg());
        }
        
        // 检查HTTP状态码
        $httpCode = $this->getHttpCode($http_response_header);
        if ($httpCode >= 400) {
            $this->handleError($responseData, $httpCode);
        }
        
        return $responseData;
    }
    
    /**
     * GET请求
     * 
     * @param string $endpoint 端点
     * @param array $params 查询参数
     * @return array 响应数据
     */
    public function get($endpoint, $params = []) {
        if (!empty($params)) {
            $endpoint .= '?' . http_build_query($params);
        }
        return $this->request('GET', $endpoint);
    }
    
    /**
     * POST请求
     * 
     * @param string $endpoint 端点
     * @param array $data 请求数据
     * @return array 响应数据
     */
    public function post($endpoint, $data = []) {
        return $this->request('POST', $endpoint, $data);
    }
    
    /**
     * PUT请求
     * 
     * @param string $endpoint 端点
     * @param array $data 请求数据
     * @return array 响应数据
     */
    public function put($endpoint, $data = []) {
        return $this->request('PUT', $endpoint, $data);
    }
    
    /**
     * PATCH请求
     * 
     * @param string $endpoint 端点
     * @param array $data 请求数据
     * @return array 响应数据
     */
    public function patch($endpoint, $data = []) {
        return $this->request('PATCH', $endpoint, $data);
    }
    
    /**
     * DELETE请求
     * 
     * @param string $endpoint 端点
     * @return array 响应数据
     */
    public function delete($endpoint) {
        return $this->request('DELETE', $endpoint);
    }
    
    /**
     * 构建请求头
     * 
     * @return string 请求头字符串
     */
    private function buildHeaders() {
        $headers = [];
        foreach ($this->headers as $key => $value) {
            $headers[] = $key . ': ' . $value;
        }
        return implode("\r\n", $headers);
    }
    
    /**
     * 获取HTTP状态码
     * 
     * @param array $headers HTTP响应头
     * @return int HTTP状态码
     */
    private function getHttpCode($headers) {
        if (empty($headers)) {
            return 0;
        }
        
        $statusLine = $headers[0];
        preg_match('/HTTP\/\d\.\d\s+(\d+)/', $statusLine, $matches);
        return isset($matches[1]) ? (int)$matches[1] : 0;
    }
    
    /**
     * 处理错误响应
     * 
     * @param array $responseData 响应数据
     * @param int $httpCode HTTP状态码
     * @throws Exception
     */
    private function handleError($responseData, $httpCode) {
        $errorMessage = '请求失败';
        $errorCode = 'UNKNOWN_ERROR';
        
        if (isset($responseData['error'])) {
            $error = $responseData['error'];
            $errorMessage = $error['message'] ?? $errorMessage;
            $errorCode = $error['code'] ?? $errorCode;
        }
        
        // 根据HTTP状态码设置错误信息
        switch ($httpCode) {
            case 400:
                $errorMessage = '请求参数错误';
                break;
            case 401:
                $errorMessage = '认证失败';
                break;
            case 403:
                $errorMessage = '权限不足';
                break;
            case 404:
                $errorMessage = '资源不存在';
                break;
            case 409:
                $errorMessage = '资源冲突';
                break;
            case 500:
                $errorMessage = '服务器内部错误';
                break;
        }
        
        throw new Exception($errorMessage, $httpCode);
    }
    
    /**
     * 用户认证
     * 
     * @param string $username 用户名
     * @param string $password 密码
     * @return array 认证响应
     * @throws Exception
     */
    public function login($username, $password) {
        $response = $this->post('/auth/login', [
            'username' => $username,
            'password' => $password
        ]);
        
        if ($response['success']) {
            $data = $response['data'];
            $this->setAccessToken($data['access_token']);
            $this->setRefreshToken($data['refresh_token']);
        }
        
        return $response;
    }
    
    /**
     * 刷新令牌
     * 
     * @return array 刷新响应
     * @throws Exception
     */
    public function refreshToken() {
        if (!$this->refreshToken) {
            throw new Exception('没有刷新令牌');
        }
        
        $response = $this->post('/auth/refresh', [
            'refresh_token' => $this->refreshToken
        ]);
        
        if ($response['success']) {
            $data = $response['data'];
            $this->setAccessToken($data['access_token']);
            $this->setRefreshToken($data['refresh_token']);
        }
        
        return $response;
    }
    
    /**
     * 用户登出
     * 
     * @return array 登出响应
     * @throws Exception
     */
    public function logout() {
        $response = $this->post('/auth/logout');
        $this->clearTokens();
        return $response;
    }
    
    /**
     * 获取当前用户信息
     * 
     * @return array 用户信息
     * @throws Exception
     */
    public function getCurrentUser() {
        return $this->get('/auth/me');
    }
    
    /**
     * 健康检查
     * 
     * @return array 健康检查响应
     * @throws Exception
     */
    public function healthCheck() {
        return $this->get('/health');
    }
    
    /**
     * 获取用户列表
     * 
     * @param array $params 查询参数
     * @return array 用户列表
     * @throws Exception
     */
    public function getUsers($params = []) {
        return $this->get('/users', $params);
    }
    
    /**
     * 创建用户
     * 
     * @param array $userData 用户数据
     * @return array 创建响应
     * @throws Exception
     */
    public function createUser($userData) {
        return $this->post('/users', $userData);
    }
    
    /**
     * 获取WireGuard服务器列表
     * 
     * @param array $params 查询参数
     * @return array 服务器列表
     * @throws Exception
     */
    public function getWireGuardServers($params = []) {
        return $this->get('/wireguard/servers', $params);
    }
    
    /**
     * 创建WireGuard服务器
     * 
     * @param array $serverData 服务器数据
     * @return array 创建响应
     * @throws Exception
     */
    public function createWireGuardServer($serverData) {
        return $this->post('/wireguard/servers', $serverData);
    }
    
    /**
     * 获取WireGuard客户端列表
     * 
     * @param array $params 查询参数
     * @return array 客户端列表
     * @throws Exception
     */
    public function getWireGuardClients($params = []) {
        return $this->get('/wireguard/clients', $params);
    }
    
    /**
     * 创建WireGuard客户端
     * 
     * @param array $clientData 客户端数据
     * @return array 创建响应
     * @throws Exception
     */
    public function createWireGuardClient($clientData) {
        return $this->post('/wireguard/clients', $clientData);
    }
    
    /**
     * 获取IPv6地址池列表
     * 
     * @param array $params 查询参数
     * @return array 地址池列表
     * @throws Exception
     */
    public function getIPv6Pools($params = []) {
        return $this->get('/ipv6/pools', $params);
    }
    
    /**
     * 创建IPv6地址池
     * 
     * @param array $poolData 地址池数据
     * @return array 创建响应
     * @throws Exception
     */
    public function createIPv6Pool($poolData) {
        return $this->post('/ipv6/pools', $poolData);
    }
    
    /**
     * 获取BGP会话列表
     * 
     * @param array $params 查询参数
     * @return array BGP会话列表
     * @throws Exception
     */
    public function getBGPSessions($params = []) {
        return $this->get('/bgp/sessions', $params);
    }
    
    /**
     * 创建BGP会话
     * 
     * @param array $sessionData 会话数据
     * @return array 创建响应
     * @throws Exception
     */
    public function createBGPSession($sessionData) {
        return $this->post('/bgp/sessions', $sessionData);
    }
}
