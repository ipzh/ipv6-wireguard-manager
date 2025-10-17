<?php
/**
 * 认证控制器
 */
class AuthController {
    private $auth;
    private $apiClient;
    
    public function __construct() {
        $this->auth = new AuthJWT();
        $this->apiClient = new ApiClientJWT();
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
        // 设置JSON响应头
        header('Content-Type: application/json; charset=utf-8');
        header('Cache-Control: no-cache, no-store, must-revalidate');
        
        try {
            // 首先尝试直接连接API健康检查端点
            $healthUrl = API_BASE_URL . '/health';
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $healthUrl);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 10);
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Accept: application/json',
                'Content-Type: application/json'
            ]);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $error = curl_error($ch);
            curl_close($ch);
            
            if ($error) {
                throw new Exception('连接失败: ' . $error);
            }
            
            if ($httpCode === 200) {
                $data = json_decode($response, true);
                echo json_encode([
                    'success' => true,
                    'status' => 'healthy',
                    'data' => $data,
                    'http_code' => $httpCode,
                    'backend_url' => $healthUrl
                ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            } else {
                echo json_encode([
                    'success' => false,
                    'status' => 'unhealthy',
                    'error' => 'HTTP错误: ' . $httpCode,
                    'http_code' => $httpCode,
                    'response' => substr($response, 0, 200),
                    'backend_url' => $healthUrl
                ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            }
            
        } catch (Exception $e) {
            echo json_encode([
                'success' => false,
                'status' => 'error',
                'error' => $e->getMessage(),
                'message' => '无法连接到后端API服务',
                'backend_url' => API_BASE_URL . '/health'
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        }
    }
}
?>
