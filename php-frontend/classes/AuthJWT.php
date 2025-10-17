<?php
/**
 * JWT认证管理类 - 与后端JWT认证系统完全兼容
 */
class AuthJWT {
    private $apiClient;
    private $permissions;
    private $roles;
    
    public function __construct() {
        $this->apiClient = new ApiClientJWT();
        $this->initializePermissions();
    }
    
    /**
     * 初始化权限和角色定义
     */
    private function initializePermissions() {
        $this->permissions = [
            // 用户管理权限
            'users.view' => '查看用户',
            'users.create' => '创建用户', 
            'users.edit' => '编辑用户',
            'users.delete' => '删除用户',
            'users.manage' => '管理用户',
            
            // WireGuard管理权限
            'wireguard.view' => '查看WireGuard',
            'wireguard.create' => '创建WireGuard',
            'wireguard.edit' => '编辑WireGuard',
            'wireguard.delete' => '删除WireGuard',
            'wireguard.manage' => '管理WireGuard',
            
            // BGP管理权限
            'bgp.view' => '查看BGP',
            'bgp.create' => '创建BGP',
            'bgp.edit' => '编辑BGP',
            'bgp.delete' => '删除BGP',
            'bgp.manage' => '管理BGP',
            
            // IPv6管理权限
            'ipv6.view' => '查看IPv6',
            'ipv6.create' => '创建IPv6',
            'ipv6.edit' => '编辑IPv6',
            'ipv6.delete' => '删除IPv6',
            'ipv6.manage' => '管理IPv6',
            
            // 系统管理权限
            'system.view' => '查看系统',
            'system.manage' => '管理系统',
            'system.config' => '系统配置',
            
            // 监控权限
            'monitoring.view' => '查看监控',
            'monitoring.manage' => '管理监控',
            
            // 日志权限
            'logs.view' => '查看日志',
            'logs.manage' => '管理日志',
            
            // 网络权限
            'network.view' => '查看网络',
            'network.manage' => '管理网络'
        ];
        
        $this->roles = [
            'admin' => [
                'name' => '管理员',
                'description' => '系统管理员，拥有所有权限',
                'permissions' => array_keys($this->permissions)
            ],
            'operator' => [
                'name' => '操作员', 
                'description' => '系统操作员，拥有大部分管理权限',
                'permissions' => [
                    'wireguard.manage', 'wireguard.view',
                    'bgp.manage', 'bgp.view', 
                    'ipv6.manage', 'ipv6.view',
                    'monitoring.view', 'logs.view',
                    'system.view', 'users.view', 'network.view'
                ]
            ],
            'user' => [
                'name' => '普通用户',
                'description' => '普通用户，只有查看权限',
                'permissions' => [
                    'wireguard.view', 'monitoring.view'
                ]
            ]
        ];
    }
    
    /**
     * 用户登录
     */
    public function login($username, $password) {
        try {
            $result = $this->apiClient->login($username, $password);
            
            if ($result['success']) {
                $_SESSION['login_time'] = time();
                $_SESSION['login_ip'] = $_SERVER['REMOTE_ADDR'] ?? '';
                $_SESSION['user_agent'] = $_SERVER['HTTP_USER_AGENT'] ?? '';
                
                // 记录登录成功日志
                error_log("用户登录成功: {$username} from " . ($_SERVER['REMOTE_ADDR'] ?? 'unknown'));
                
                return true;
            } else {
                // 记录登录失败日志
                error_log("用户登录失败: {$username} - " . ($result['error'] ?? '未知错误'));
                return false;
            }
            
        } catch (Exception $e) {
            error_log('登录异常: ' . $e->getMessage());
            return false;
        }
    }
    
    /**
     * 用户登出
     */
    public function logout() {
        try {
            $this->apiClient->logout();
            
            // 清除会话数据
            unset($_SESSION['user']);
            unset($_SESSION['login_time']);
            unset($_SESSION['login_ip']);
            unset($_SESSION['user_agent']);
            
            // 记录登出日志
            error_log("用户登出: " . ($_SESSION['user']['username'] ?? 'unknown'));
            
        } catch (Exception $e) {
            error_log('登出异常: ' . $e->getMessage());
        }
    }
    
    /**
     * 检查用户是否已登录
     */
    public function isLoggedIn() {
        // 检查会话中是否有用户信息
        if (!isset($_SESSION['user']) || !isset($_SESSION['user']['id'])) {
            return false;
        }
        
        // 检查令牌是否有效
        if (!$this->apiClient->isTokenValid()) {
            // 尝试刷新令牌
            try {
                if ($this->apiClient->getRefreshToken()) {
                    $this->apiClient->refreshAccessToken();
                    return true;
                }
            } catch (Exception $e) {
                // 刷新失败，清除会话
                $this->logout();
                return false;
            }
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
        
        // 如果会话中的用户信息过期，从API获取最新信息
        if (!isset($_SESSION['user']['updated_at']) || 
            (time() - strtotime($_SESSION['user']['updated_at'])) > 300) { // 5分钟缓存
            
            try {
                $user = $this->apiClient->getCurrentUser();
                if ($user) {
                    $_SESSION['user'] = $user;
                }
            } catch (Exception $e) {
                error_log('获取用户信息失败: ' . $e->getMessage());
            }
        }
        
        return $_SESSION['user'] ?? null;
    }
    
    /**
     * 获取用户权限列表
     */
    public function getUserPermissions() {
        $user = $this->getCurrentUser();
        if (!$user) {
            return [];
        }
        
        // 如果是超级用户，返回所有权限
        if (isset($user['is_superuser']) && $user['is_superuser']) {
            return array_keys($this->permissions);
        }
        
        // 从用户角色获取权限
        $permissions = [];
        if (isset($user['roles']) && is_array($user['roles'])) {
            foreach ($user['roles'] as $role) {
                if (isset($this->roles[$role['name']])) {
                    $permissions = array_merge($permissions, $this->roles[$role['name']]['permissions']);
                }
            }
        }
        
        return array_unique($permissions);
    }
    
    /**
     * 检查用户是否具有指定权限
     */
    public function hasPermission($permission) {
        $userPermissions = $this->getUserPermissions();
        
        // 超级用户拥有所有权限
        $user = $this->getCurrentUser();
        if ($user && isset($user['is_superuser']) && $user['is_superuser']) {
            return true;
        }
        
        return in_array($permission, $userPermissions);
    }
    
    /**
     * 检查用户是否具有指定角色
     */
    public function hasRole($roleName) {
        $user = $this->getCurrentUser();
        if (!$user) {
            return false;
        }
        
        // 超级用户拥有所有角色
        if (isset($user['is_superuser']) && $user['is_superuser']) {
            return true;
        }
        
        if (isset($user['roles']) && is_array($user['roles'])) {
            foreach ($user['roles'] as $role) {
                if ($role['name'] === $roleName) {
                    return true;
                }
            }
        }
        
        return false;
    }
    
    /**
     * 检查用户是否为管理员
     */
    public function isAdmin() {
        return $this->hasRole('admin') || $this->hasPermission('users.manage');
    }
    
    /**
     * 检查用户是否为操作员
     */
    public function isOperator() {
        return $this->hasRole('operator') || $this->hasRole('admin');
    }
    
    /**
     * 要求用户登录
     */
    public function requireLogin() {
        if (!$this->isLoggedIn()) {
            // 如果是AJAX请求，返回JSON错误
            if (!empty($_SERVER['HTTP_X_REQUESTED_WITH']) && 
                strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest') {
                http_response_code(401);
                header('Content-Type: application/json');
                echo json_encode([
                    'success' => false,
                    'error' => '未登录',
                    'code' => 401
                ]);
                exit;
            }
            
            // 重定向到登录页
            header('Location: /login');
            exit;
        }
    }
    
    /**
     * 要求用户具有指定权限
     */
    public function requirePermission($permission) {
        $this->requireLogin();
        
        if (!$this->hasPermission($permission)) {
            $user = $this->getCurrentUser();
            $username = $user['username'] ?? 'unknown';
            
            // 记录权限拒绝日志
            error_log("权限拒绝: 用户 {$username} 尝试访问需要权限 {$permission} 的资源");
            
            // 如果是AJAX请求，返回JSON错误
            if (!empty($_SERVER['HTTP_X_REQUESTED_WITH']) && 
                strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest') {
                http_response_code(403);
                header('Content-Type: application/json');
                echo json_encode([
                    'success' => false,
                    'error' => '权限不足',
                    'code' => 403,
                    'required_permission' => $permission,
                    'user_role' => $user['roles'][0]['name'] ?? 'user'
                ]);
                exit;
            }
            
            // 显示权限不足页面
            http_response_code(403);
            include 'views/errors/403.php';
            exit;
        }
    }
    
    /**
     * 要求用户具有指定角色
     */
    public function requireRole($roleName) {
        $this->requireLogin();
        
        if (!$this->hasRole($roleName)) {
            $user = $this->getCurrentUser();
            $username = $user['username'] ?? 'unknown';
            
            // 记录角色拒绝日志
            error_log("角色拒绝: 用户 {$username} 尝试访问需要角色 {$roleName} 的资源");
            
            // 如果是AJAX请求，返回JSON错误
            if (!empty($_SERVER['HTTP_X_REQUESTED_WITH']) && 
                strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest') {
                http_response_code(403);
                header('Content-Type: application/json');
                echo json_encode([
                    'success' => false,
                    'error' => '权限不足',
                    'code' => 403,
                    'required_role' => $roleName,
                    'user_role' => $user['roles'][0]['name'] ?? 'user'
                ]);
                exit;
            }
            
            // 显示权限不足页面
            http_response_code(403);
            include 'views/errors/403.php';
            exit;
        }
    }
    
    /**
     * 验证CSRF令牌
     */
    public function verifyCsrfToken($token) {
        if (!isset($_SESSION['csrf_token'])) {
            throw new Exception('CSRF令牌未生成');
        }
        
        if (!hash_equals($_SESSION['csrf_token'], $token)) {
            throw new Exception('CSRF令牌验证失败');
        }
        
        return true;
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
     * 获取API客户端实例
     */
    public function getApiClient() {
        return $this->apiClient;
    }
    
    /**
     * 获取所有权限定义
     */
    public function getAllPermissions() {
        return $this->permissions;
    }
    
    /**
     * 获取所有角色定义
     */
    public function getAllRoles() {
        return $this->roles;
    }
    
    /**
     * 检查会话安全性
     */
    public function checkSessionSecurity() {
        if (!$this->isLoggedIn()) {
            return true;
        }
        
        $user = $this->getCurrentUser();
        if (!$user) {
            return false;
        }
        
        // 检查IP地址是否变化
        if (isset($_SESSION['login_ip']) && 
            $_SESSION['login_ip'] !== ($_SERVER['REMOTE_ADDR'] ?? '')) {
            error_log("会话安全警告: IP地址变化 - 用户: " . ($user['username'] ?? 'unknown'));
            // 可以选择要求重新登录
            // $this->logout();
            // return false;
        }
        
        // 检查User-Agent是否变化
        if (isset($_SESSION['user_agent']) && 
            $_SESSION['user_agent'] !== ($_SERVER['HTTP_USER_AGENT'] ?? '')) {
            error_log("会话安全警告: User-Agent变化 - 用户: " . ($user['username'] ?? 'unknown'));
            // 可以选择要求重新登录
            // $this->logout();
            // return false;
        }
        
        // 检查会话是否过期（24小时）
        if (isset($_SESSION['login_time']) && 
            (time() - $_SESSION['login_time']) > 86400) {
            error_log("会话过期: 用户: " . ($user['username'] ?? 'unknown'));
            $this->logout();
            return false;
        }
        
        return true;
    }
    
    /**
     * 更新用户最后活动时间
     */
    public function updateLastActivity() {
        if ($this->isLoggedIn()) {
            $_SESSION['last_activity'] = time();
        }
    }
    
    /**
     * 检查用户是否长时间未活动（2小时）
     */
    public function isSessionIdle() {
        if (!isset($_SESSION['last_activity'])) {
            $_SESSION['last_activity'] = time();
            return false;
        }
        
        return (time() - $_SESSION['last_activity']) > 7200; // 2小时
    }
}
?>
