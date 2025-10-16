<?php
/**
 * 认证管理类
 */
class Auth {
    private $apiClient;
    
    public function __construct() {
        $this->apiClient = new ApiClient();
    }
    
    /**
     * 用户登录
     */
    public function login($username, $password) {
        try {
            $response = $this->apiClient->post('/auth/login-json', [
                'username' => $username,
                'password' => $password
            ]);
            
            if (isset($response['access_token'])) {
                $this->apiClient->setToken($response['access_token']);
                $_SESSION['user'] = $response['user'];
                $_SESSION['login_time'] = time();
                return true;
            }
            
            return false;
        } catch (Exception $e) {
            error_log('登录失败: ' . $e->getMessage());
            return false;
        }
    }
    
    /**
     * 用户登出
     */
    public function logout() {
        try {
            $this->apiClient->post('/auth/logout');
        } catch (Exception $e) {
            // 忽略登出API错误
        }
        
        $this->apiClient->clearToken();
        unset($_SESSION['user']);
        unset($_SESSION['login_time']);
        session_destroy();
    }
    
    /**
     * 检查用户是否已登录
     */
    public function isLoggedIn() {
        if (!isset($_SESSION['user']) || !isset($_SESSION['token'])) {
            return false;
        }
        
        // 检查会话是否过期
        if (isset($_SESSION['login_time']) && 
            (time() - $_SESSION['login_time']) > SESSION_LIFETIME) {
            $this->logout();
            return false;
        }
        
        return true;
    }
    
    /**
     * 获取当前用户信息
     */
    public function getCurrentUser() {
        if (!$this->isLoggedIn()) {
            return null;
        }
        
        return $_SESSION['user'];
    }
    
    /**
     * 检查用户权限
     */
    public function hasPermission($permission) {
        $user = $this->getCurrentUser();
        if (!$user) {
            return false;
        }
        
        // 超级用户拥有所有权限
        if ($user['is_superuser'] ?? false) {
            return true;
        }
        
        // 检查角色权限
        $role = $user['role'] ?? 'user';
        
        $permissions = [
            'admin' => ['*'], // 管理员拥有所有权限
            'operator' => [
                'wireguard.manage',
                'bgp.manage',
                'ipv6.manage',
                'monitoring.view',
                'logs.view'
            ],
            'user' => [
                'wireguard.view',
                'monitoring.view'
            ]
        ];
        
        $userPermissions = $permissions[$role] ?? [];
        
        // 检查通配符权限
        if (in_array('*', $userPermissions)) {
            return true;
        }
        
        return in_array($permission, $userPermissions);
    }
    
    /**
     * 要求用户登录
     */
    public function requireLogin() {
        if (!$this->isLoggedIn()) {
            header('Location: /login');
            exit;
        }
    }
    
    /**
     * 要求特定权限
     */
    public function requirePermission($permission) {
        $this->requireLogin();
        
        if (!$this->hasPermission($permission)) {
            http_response_code(403);
            die('权限不足');
        }
    }
    
    /**
     * 刷新用户信息
     */
    public function refreshUserInfo() {
        if (!$this->isLoggedIn()) {
            return false;
        }
        
        try {
            $response = $this->apiClient->get('/auth/test-token');
            $_SESSION['user'] = $response;
            return true;
        } catch (Exception $e) {
            // 如果令牌无效，登出用户
            $this->logout();
            return false;
        }
    }
    
    /**
     * 生成CSRF令牌
     */
    public function generateCsrfToken() {
        if (!isset($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['csrf_token'];
    }
    
    /**
     * 验证CSRF令牌
     */
    public function verifyCsrfToken($token) {
        return isset($_SESSION['csrf_token']) && 
               hash_equals($_SESSION['csrf_token'], $token);
    }
}
?>
