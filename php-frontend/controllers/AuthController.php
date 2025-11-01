<?php
/**
 * 认证控制器
 */

// 引入SSL安全配置
require_once __DIR__ . '/../includes/ssl_security.php';
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
        
        // 传递auth对象和csrf token到视图（修复视图中的$this问题）
        $auth = $this->auth;
        $csrfToken = $this->auth->generateCsrfToken();
        
        // 使用绝对路径加载视图（修复相对路径问题）
        include __DIR__ . '/../views/layout/header.php';
        include __DIR__ . '/../views/auth/login.php';
        include __DIR__ . '/../views/layout/footer.php';
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
        
        // 传递auth对象和csrf token到视图（修复视图中的$this问题）
        $auth = $this->auth;
        $csrfToken = $this->auth->generateCsrfToken();
        
        // 使用绝对路径加载视图
        include __DIR__ . '/../views/layout/header.php';
        include __DIR__ . '/../views/auth/login.php';
        include __DIR__ . '/../views/layout/footer.php';
    }
    
    /**
     * 检查API连接状态
     */
    public function checkApiStatus() {
        // 设置JSON响应头
        header('Content-Type: application/json; charset=utf-8');
        header('Cache-Control: no-cache, no-store, must-revalidate');
        
        try {
            // 优先使用Nginx代理路径（通过前端访问，走Nginx代理）
            // 这样可以避免跨域问题和端口配置问题
            $healthUrl = null;
            
            // 方案1: 尝试通过Nginx代理访问 /api/v1/health
            $proxyHealthUrl = '/api/v1/health';
            
            // 方案2: 如果代理不可用，尝试直接访问后端
            // 确保API_BASE_URL已定义
            if (!defined('API_BASE_URL')) {
                // 如果未定义，使用默认值
                $apiHost = $_SERVER['HTTP_HOST'] ?? 'localhost';
                $apiHost = preg_replace('/:\d+$/', '', $apiHost);
                $apiBaseUrl = 'http://' . $apiHost . ':8000';
            } else {
                $apiBaseUrl = API_BASE_URL;
            }
            
            // 构建后端API健康检查URL
            $base = rtrim($apiBaseUrl, '/');
            // 确保包含 /api/v1 前缀
            if (strpos($base, '/api/v1') === false) {
                $base = rtrim($base, '/') . '/api/v1';
            }
            $directHealthUrl = $base . '/health';
            
            // 尝试通过Nginx代理访问（使用完整URL）
            $scheme = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
            $proxyUrl = $scheme . '://' . $host . $proxyHealthUrl;
            
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $proxyUrl);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 5); // 快速超时，优先尝试代理
            curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Accept: application/json',
                'Content-Type: application/json'
            ]);
            
            // 应用安全的SSL配置
            applySecureSSLConfig($ch);
            
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $error = curl_error($ch);
            curl_close($ch);
            
            // 如果代理失败，尝试直接访问后端
            $finalHealthUrl = $proxyUrl;
            $method = 'proxy';
            
            if ($error || $httpCode !== 200) {
                // 尝试直接访问后端
                $ch = curl_init();
                curl_setopt($ch, CURLOPT_URL, $directHealthUrl);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_TIMEOUT, 10);
                curl_setopt($ch, CURLOPT_HTTPHEADER, [
                    'Accept: application/json',
                    'Content-Type: application/json'
                ]);
                
                // 应用安全的SSL配置
                applySecureSSLConfig($ch);
                
                $response = curl_exec($ch);
                $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                $error = curl_error($ch);
                curl_close($ch);
                
                $finalHealthUrl = $directHealthUrl;
                $method = 'direct';
            }
            
            if ($error) {
                throw new Exception('连接失败: ' . $error . ' (代理URL: ' . $proxyUrl . ', 直接URL: ' . $directHealthUrl . ')');
            }
            
            if ($httpCode === 200) {
                $data = json_decode($response, true);
                echo json_encode([
                    'success' => true,
                    'status' => 'healthy',
                    'data' => $data,
                    'http_code' => $httpCode,
                    'backend_url' => $finalHealthUrl,
                    'method' => $method,
                    'proxy_url_tried' => $proxyUrl,
                    'direct_url_tried' => $directHealthUrl
                ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            } else {
                echo json_encode([
                    'success' => false,
                    'status' => 'unhealthy',
                    'error' => 'HTTP错误: ' . $httpCode,
                    'http_code' => $httpCode,
                    'response' => substr($response, 0, 200),
                    'backend_url' => $finalHealthUrl,
                    'method' => $method,
                    'proxy_url_tried' => $proxyUrl,
                    'direct_url_tried' => $directHealthUrl,
                    'note' => 'API可通过直接访问，但Nginx代理可能配置有问题'
                ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            }
            
        } catch (Exception $e) {
            // 确保API_BASE_URL已定义
            if (!defined('API_BASE_URL')) {
                $apiHost = $_SERVER['HTTP_HOST'] ?? 'localhost';
                $apiHost = preg_replace('/:\d+$/', '', $apiHost);
                $apiBaseUrl = 'http://' . $apiHost . ':8000';
            } else {
                $apiBaseUrl = API_BASE_URL;
            }
            
            // 构建正确的健康检查URL
            $base = rtrim($apiBaseUrl, '/');
            if (strpos($base, '/api/v1') === false) {
                $base = rtrim($base, '/') . '/api/v1';
            }
            $healthUrl = $base . '/health';
            
            // 也尝试代理路径
            $scheme = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
            $proxyUrl = $scheme . '://' . $host . '/api/v1/health';
            
            echo json_encode([
                'success' => false,
                'status' => 'error',
                'error' => $e->getMessage(),
                'message' => '无法连接到后端API服务',
                'tried_proxy_url' => $proxyUrl,
                'tried_direct_url' => $healthUrl,
                'suggestion' => '请检查：1) Nginx代理配置 2) 后端API服务是否运行 3) 防火墙设置'
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        }
    }
}
?>
