<?php
/**
 * JWT认证API客户端 - 与后端JWT认证系统完全兼容
 */
class ApiClientJWT {
    private $baseUrl;
    private $timeout;
    private $accessToken;
    private $refreshToken;
    private $maxRetries;
    private $retryDelay;
    private $userAgent;
    private $tokenRefreshCallback;
    
    public function __construct() {
        $this->baseUrl = API_BASE_URL;
        $this->timeout = API_TIMEOUT ?? 30;
        $this->maxRetries = 3;
        $this->retryDelay = 1; // 秒
        $this->userAgent = 'IPv6-WireGuard-Manager/1.0';
        
        // 从会话中恢复令牌
        $this->accessToken = $_SESSION['access_token'] ?? null;
        $this->refreshToken = $_SESSION['refresh_token'] ?? null;
        
        // 设置令牌刷新回调
        $this->tokenRefreshCallback = function($newAccessToken, $newRefreshToken) {
            $this->setTokens($newAccessToken, $newRefreshToken);
        };
    }
    
    /**
     * 设置访问令牌和刷新令牌
     */
    public function setTokens($accessToken, $refreshToken = null) {
        $this->accessToken = $accessToken;
        if ($refreshToken) {
            $this->refreshToken = $refreshToken;
        }
        
        // 保存到会话
        $_SESSION['access_token'] = $this->accessToken;
        if ($this->refreshToken) {
            $_SESSION['refresh_token'] = $this->refreshToken;
        }
    }
    
    /**
     * 获取访问令牌
     */
    public function getAccessToken() {
        return $this->accessToken;
    }
    
    /**
     * 获取刷新令牌
     */
    public function getRefreshToken() {
        return $this->refreshToken;
    }
    
    /**
     * 清除所有令牌
     */
    public function clearTokens() {
        $this->accessToken = null;
        $this->refreshToken = null;
        unset($_SESSION['access_token'], $_SESSION['refresh_token']);
    }
    
    /**
     * 检查令牌是否有效
     */
    public function isTokenValid() {
        if (!$this->accessToken) {
            return false;
        }
        
        // 解析JWT令牌检查过期时间
        try {
            $payload = $this->decodeJWT($this->accessToken);
            if (!$payload || !isset($payload['exp'])) {
                return false;
            }
            
            // 检查是否在过期前5分钟
            $expiryTime = $payload['exp'];
            $currentTime = time();
            return ($expiryTime - $currentTime) > 300; // 5分钟缓冲
            
        } catch (Exception $e) {
            return false;
        }
    }
    
    /**
     * 刷新访问令牌
     */
    public function refreshAccessToken() {
        if (!$this->refreshToken) {
            throw new Exception('没有可用的刷新令牌');
        }
        
        try {
            $response = $this->makeRequest('POST', '/auth/refresh', [
                'refresh_token' => $this->refreshToken
            ], false); // 不自动刷新令牌，避免无限循环
            
            if ($response['success'] && isset($response['data']['access_token'])) {
                $newAccessToken = $response['data']['access_token'];
                $newRefreshToken = $response['data']['refresh_token'] ?? $this->refreshToken;
                
                $this->setTokens($newAccessToken, $newRefreshToken);
                
                return true;
            }
            
            return false;
            
        } catch (Exception $e) {
            // 刷新失败，清除令牌
            $this->clearTokens();
            throw $e;
        }
    }
    
    /**
     * 发送GET请求
     */
    public function get($endpoint, $params = [], $useCache = false) {
        $url = $this->baseUrl . $endpoint;
        if (!empty($params)) {
            $url .= '?' . http_build_query($params);
        }
        
        return $this->makeRequest('GET', $url, null, true, $useCache);
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
     * 发送PATCH请求
     */
    public function patch($endpoint, $data = []) {
        $url = $this->baseUrl . $endpoint;
        return $this->makeRequest('PATCH', $url, $data);
    }
    
    /**
     * 发送HTTP请求 - 支持JWT认证和自动令牌刷新
     */
    private function makeRequest($method, $url, $data = null, $autoRefresh = true, $useCache = false) {
        $attempt = 0;
        $lastError = null;
        
        while ($attempt < $this->maxRetries) {
            try {
                // 检查令牌有效性，如果需要则刷新
                if ($autoRefresh && !$this->isTokenValid() && $this->refreshToken) {
                    $this->refreshAccessToken();
                }
                
                $result = $this->executeCurlRequest($method, $url, $data);
                
                // 如果请求成功，返回结果
                if ($result['success']) {
                    return $result['data'];
                }
                
                // 如果是401错误且可以自动刷新令牌
                if ($result['http_code'] === 401 && $autoRefresh && $this->refreshToken) {
                    if ($this->refreshAccessToken()) {
                        $attempt++;
                        continue; // 重试请求
                    } else {
                        // 刷新失败，清除令牌并重定向到登录页
                        $this->clearTokens();
                        throw new Exception('认证失败，请重新登录');
                    }
                }
                
                // 如果是404错误，尝试使用模拟API
                if ($result['http_code'] === 404) {
                    return $this->useMockApi($url, $method, $data);
                }
                
                // 如果是可重试的错误，继续重试
                if ($this->isRetryableError($result['http_code'])) {
                    $lastError = $result['error'];
                    $attempt++;
                    
                    if ($attempt < $this->maxRetries) {
                        sleep($this->retryDelay * $attempt); // 递增延迟
                        continue;
                    }
                }
                
                // 不可重试的错误或重试次数用完
                throw new Exception($result['error']);
                
            } catch (Exception $e) {
                $lastError = $e->getMessage();
                $attempt++;
                
                if ($attempt < $this->maxRetries) {
                    sleep($this->retryDelay * $attempt);
                    continue;
                }
                
                throw $e;
            }
        }
        
        throw new Exception('API请求失败，已重试' . $this->maxRetries . '次: ' . $lastError);
    }
    
    /**
     * 执行curl请求
     */
    private function executeCurlRequest($method, $url, $data = null) {
        $ch = curl_init();
        
        // 基本curl配置
        curl_setopt_array($ch, [
            CURLOPT_URL => $url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => $this->timeout,
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_MAXREDIRS => 3,
            CURLOPT_SSL_VERIFYPEER => false,
            CURLOPT_SSL_VERIFYHOST => false,
            CURLOPT_USERAGENT => $this->userAgent,
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/json',
                'Accept: application/json',
                'Cache-Control: no-cache'
            ]
        ]);
        
        // 添加JWT认证头
        if ($this->accessToken) {
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Content-Type: application/json',
                'Accept: application/json',
                'Cache-Control: no-cache',
                'Authorization: Bearer ' . $this->accessToken
            ]);
        }
        
        // 设置请求方法和数据
        switch (strtoupper($method)) {
            case 'POST':
                curl_setopt($ch, CURLOPT_POST, true);
                if ($data) {
                    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
                }
                break;
            case 'PUT':
                curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
                if ($data) {
                    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
                }
                break;
            case 'DELETE':
                curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');
                break;
            case 'PATCH':
                curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PATCH');
                if ($data) {
                    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
                }
                break;
        }
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        
        curl_close($ch);
        
        if ($response === false) {
            return [
                'success' => false,
                'http_code' => 0,
                'error' => 'CURL错误: ' . $error
            ];
        }
        
        // 解析JSON响应
        $decodedResponse = json_decode($response, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            return [
                'success' => false,
                'http_code' => $httpCode,
                'error' => 'JSON解析错误: ' . json_last_error_msg()
            ];
        }
        
        // 检查HTTP状态码
        if ($httpCode >= 200 && $httpCode < 300) {
            return [
                'success' => true,
                'http_code' => $httpCode,
                'data' => $decodedResponse
            ];
        } else {
            $errorMessage = $decodedResponse['detail'] ?? $decodedResponse['message'] ?? 'HTTP错误';
            return [
                'success' => false,
                'http_code' => $httpCode,
                'error' => "HTTP {$httpCode}: {$errorMessage}"
            ];
        }
    }
    
    /**
     * 判断是否为可重试的错误
     */
    private function isRetryableError($httpCode) {
        return in_array($httpCode, [
            408, // Request Timeout
            429, // Too Many Requests
            500, // Internal Server Error
            502, // Bad Gateway
            503, // Service Unavailable
            504  // Gateway Timeout
        ]);
    }
    
    /**
     * 使用模拟API
     */
    private function useMockApi($url, $method, $data = null) {
        // 构建模拟API URL
        $mockUrl = 'http://' . ($_SERVER['HTTP_HOST'] ?? 'localhost') . dirname($_SERVER['SCRIPT_NAME']) . '/api_mock_jwt.php' . parse_url($url, PHP_URL_PATH);
        
        // 设置查询参数
        $query = parse_url($url, PHP_URL_QUERY);
        if ($query) {
            $mockUrl .= '?' . $query;
        }
        
        // 设置请求上下文
        $context = [
            'http' => [
                'method' => $method,
                'header' => [
                    'Content-Type: application/json',
                    'Accept: application/json',
                    'User-Agent: ' . $this->userAgent
                ],
                'timeout' => $this->timeout
            ]
        ];
        
        if ($data && in_array($method, ['POST', 'PUT', 'PATCH'])) {
            $context['http']['content'] = json_encode($data);
        }
        
        $context = stream_context_create($context);
        
        $response = @file_get_contents($mockUrl, false, $context);
        
        if ($response === false) {
            return $this->getDefaultResponse($url);
        }
        
        return json_decode($response, true);
    }
    
    /**
     * 获取默认响应
     */
    private function getDefaultResponse($url) {
        if (strpos($url, '/system/') !== false) {
            return [
                'success' => true,
                'data' => [
                    'message' => '系统信息暂不可用',
                    'status' => 'offline'
                ]
            ];
        } elseif (strpos($url, '/wireguard/') !== false) {
            return [
                'success' => true,
                'data' => []
            ];
        } elseif (strpos($url, '/monitoring/') !== false) {
            return [
                'success' => true,
                'data' => [
                    'message' => '监控数据暂不可用',
                    'status' => 'offline'
                ]
            ];
        } else {
            return [
                'success' => false,
                'error' => '服务暂不可用',
                'message' => '后端API服务未运行，请稍后重试'
            ];
        }
    }
    
    /**
     * 解码JWT令牌
     */
    private function decodeJWT($token) {
        try {
            // 分割JWT令牌
            $parts = explode('.', $token);
            if (count($parts) !== 3) {
                return null;
            }
            
            // 解码载荷部分
            $payload = $parts[1];
            $payload = str_replace(['-', '_'], ['+', '/'], $payload);
            $payload = base64_decode($payload);
            
            return json_decode($payload, true);
            
        } catch (Exception $e) {
            return null;
        }
    }
    
    /**
     * 用户登录
     */
    public function login($username, $password) {
        try {
            $response = $this->post('/auth/login', [
                'username' => $username,
                'password' => $password
            ]);
            
            if ($response['success'] && isset($response['data']['access_token'])) {
                $this->setTokens(
                    $response['data']['access_token'],
                    $response['data']['refresh_token']
                );
                
                // 保存用户信息到会话
                if (isset($response['data']['user'])) {
                    $_SESSION['user'] = $response['data']['user'];
                }
                
                return [
                    'success' => true,
                    'user' => $response['data']['user'] ?? null
                ];
            }
            
            return [
                'success' => false,
                'error' => $response['error'] ?? '登录失败'
            ];
            
        } catch (Exception $e) {
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }
    
    /**
     * 用户登出
     */
    public function logout() {
        try {
            if ($this->accessToken) {
                $this->post('/auth/logout');
            }
        } catch (Exception $e) {
            // 忽略登出错误
        } finally {
            $this->clearTokens();
            unset($_SESSION['user']);
        }
    }
    
    /**
     * 获取当前用户信息
     */
    public function getCurrentUser() {
        try {
            $response = $this->get('/auth/me');
            
            if ($response['success']) {
                $_SESSION['user'] = $response['data'];
                return $response['data'];
            }
            
            return null;
            
        } catch (Exception $e) {
            return null;
        }
    }
    
    /**
     * 验证令牌
     */
    public function verifyToken() {
        try {
            $response = $this->post('/auth/verify-token', [
                'token' => $this->accessToken
            ]);
            return $response['success'] && $response['data']['valid'];
        } catch (Exception $e) {
            return false;
        }
    }
}
?>
