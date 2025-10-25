<?php
/**
 * 权限检查中间件
 */
class PermissionMiddleware {
    private $auth;
    
    public function __construct() {
        $this->auth = new Auth();
    }
    
    /**
     * 要求登录
     */
    public function requireLogin() {
        if (!$this->auth->isLoggedIn()) {
            $this->redirectToLogin();
        }
    }
    
    /**
     * 要求特定权限
     */
    public function requirePermission($permission) {
        $this->requireLogin();
        
        if (!$this->auth->hasPermission($permission)) {
            $this->handlePermissionDenied($permission);
        }
    }
    
    /**
     * 要求管理员权限
     */
    public function requireAdmin() {
        $this->requireLogin();
        
        if (!$this->auth->isAdmin()) {
            $this->handlePermissionDenied('admin');
        }
    }
    
    /**
     * 要求操作员权限
     */
    public function requireOperator() {
        $this->requireLogin();
        
        if (!$this->auth->isOperator()) {
            $this->handlePermissionDenied('operator');
        }
    }
    
    /**
     * 处理权限拒绝
     */
    private function handlePermissionDenied($permission) {
        $user = $this->auth->getCurrentUser();
        $userRole = $user['role'] ?? 'user';
        $userName = $user['username'] ?? '未知用户';
        
        error_log("权限拒绝: 用户 {$userName} (角色: {$userRole}) 尝试访问需要权限 '{$permission}' 的资源");
        
        // 如果是AJAX请求，返回JSON错误
        if ($this->isAjaxRequest()) {
            http_response_code(403);
            header('Content-Type: application/json');
            echo json_encode([
                'error' => '权限不足',
                'message' => "您没有执行此操作的权限。需要权限: {$permission}",
                'user_role' => $userRole,
                'required_permission' => $permission
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
        
        // 否则重定向到错误页面
        $this->redirectToError('权限不足', "您没有执行此操作的权限。需要权限: {$permission}");
    }
    
    /**
     * 重定向到登录页面
     */
    private function redirectToLogin() {
        if ($this->isAjaxRequest()) {
            http_response_code(401);
            header('Content-Type: application/json');
            echo json_encode([
                'error' => '未登录',
                'message' => '请先登录',
                'redirect' => '/login'
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
        
        header('Location: /login');
        exit;
    }
    
    /**
     * 重定向到错误页面
     */
    private function redirectToError($title, $message) {
        $_SESSION['error_title'] = $title;
        $_SESSION['error_message'] = $message;
        header('Location: /error');
        exit;
    }
    
    /**
     * 检查是否为AJAX请求
     */
    private function isAjaxRequest() {
        return !empty($_SERVER['HTTP_X_REQUESTED_WITH']) && 
               strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest';
    }
    
    /**
     * 检查CSRF令牌
     */
    public function verifyCsrfToken($token) {
        if (!$this->auth->verifyCsrfToken($token)) {
            if ($this->isAjaxRequest()) {
                http_response_code(400);
                header('Content-Type: application/json');
                echo json_encode([
                    'error' => 'CSRF令牌验证失败',
                    'message' => '安全令牌验证失败，请刷新页面后重试'
                ], JSON_UNESCAPED_UNICODE);
                exit;
            }
            
            throw new Exception('安全令牌验证失败，请刷新页面后重试');
        }
    }
}
?>
