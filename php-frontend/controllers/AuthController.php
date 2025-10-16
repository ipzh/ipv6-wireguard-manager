<?php
/**
 * 认证控制器
 */
class AuthController {
    private $auth;
    private $apiClient;
    
    public function __construct() {
        $this->auth = new Auth();
        $this->apiClient = new ApiClient();
    }
    
    /**
     * 显示登录页面
     */
    public function showLogin() {
        // 如果已经登录，重定向到仪表板
        if ($this->auth->isLoggedIn()) {
            Router::redirect('/');
            return;
        }
        
        $pageTitle = '用户登录';
        $showSidebar = false;
        
        include 'views/layout/header.php';
        include 'views/auth/login.php';
        include 'views/layout/footer.php';
    }
    
    /**
     * 处理登录请求
     */
    public function login() {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            Router::redirect('/login');
            return;
        }
        
        $username = trim($_POST['username'] ?? '');
        $password = $_POST['password'] ?? '';
        $csrfToken = $_POST['_token'] ?? '';
        
        // 验证CSRF令牌
        if (!$this->auth->verifyCsrfToken($csrfToken)) {
            $this->showLoginWithError('安全令牌验证失败');
            return;
        }
        
        // 验证输入
        if (empty($username) || empty($password)) {
            $this->showLoginWithError('用户名和密码不能为空');
            return;
        }
        
        // 尝试登录
        if ($this->auth->login($username, $password)) {
            // 登录成功，重定向到仪表板
            Router::redirect('/');
        } else {
            // 登录失败
            $this->showLoginWithError('用户名或密码错误');
        }
    }
    
    /**
     * 处理登出请求
     */
    public function logout() {
        $this->auth->logout();
        Router::redirect('/login');
    }
    
    /**
     * 显示带错误信息的登录页面
     */
    private function showLoginWithError($errorMessage) {
        $pageTitle = '用户登录';
        $showSidebar = false;
        $error = $errorMessage;
        
        include 'views/layout/header.php';
        include 'views/auth/login.php';
        include 'views/layout/footer.php';
    }
    
    /**
     * 检查API连接状态
     */
    public function checkApiStatus() {
        try {
            $status = $this->apiClient->getApiStatus();
            echo json_encode([
                'success' => true,
                'status' => $status
            ]);
        } catch (Exception $e) {
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
    }
}
?>
