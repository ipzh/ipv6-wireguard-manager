<?php
/**
 * 安全设置控制器
 */
class SecurityController {
    private $auth;
    private $apiClient;
    
    public function __construct() {
        $this->auth = new AuthJWT();
        $this->apiClient = new ApiClientJWT();
    }
    
    /**
     * 显示安全设置页面
     */
    public function index() {
        // 检查登录状态
        if (!$this->auth->isLoggedIn()) {
            Router::redirect('/login');
            return;
        }
        
        $pageTitle = '安全设置';
        $showSidebar = true;
        
        include 'views/layout/header.php';
        include 'views/security/index.php';
        include 'views/layout/footer.php';
    }
    
    /**
     * 处理密码修改请求
     */
    public function changePassword() {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => '方法不允许']);
            return;
        }
        
        $input = json_decode(file_get_contents('php://input'), true);
        $currentPassword = $input['current_password'] ?? '';
        $newPassword = $input['new_password'] ?? '';
        
        if (empty($currentPassword) || empty($newPassword)) {
            echo json_encode(['success' => false, 'message' => '密码不能为空']);
            return;
        }
        
        try {
            $response = $this->apiClient->post('/auth/change-password', [
                'current_password' => $currentPassword,
                'new_password' => $newPassword
            ]);
            
            echo json_encode($response);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    }
    
    /**
     * 处理MFA设置请求
     */
    public function setupMfa() {
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => '方法不允许']);
            return;
        }
        
        try {
            $response = $this->apiClient->get('/mfa/setup');
            echo json_encode($response);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    }
    
    /**
     * 处理MFA启用请求
     */
    public function enableMfa() {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => '方法不允许']);
            return;
        }
        
        $input = json_decode(file_get_contents('php://input'), true);
        $code = $input['code'] ?? '';
        
        if (empty($code)) {
            echo json_encode(['success' => false, 'message' => '验证码不能为空']);
            return;
        }
        
        try {
            $response = $this->apiClient->post('/mfa/enable', [
                'verification_code' => $code
            ]);
            
            echo json_encode($response);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    }
    
    /**
     * 处理备份代码生成请求
     */
    public function generateBackupCodes() {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => '方法不允许']);
            return;
        }
        
        try {
            $response = $this->apiClient->post('/mfa/backup-codes');
            echo json_encode($response);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    }
    
    /**
     * 获取用户会话列表
     */
    public function getSessions() {
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => '方法不允许']);
            return;
        }
        
        try {
            $response = $this->apiClient->get('/auth/sessions');
            echo json_encode($response);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    }
    
    /**
     * 终止用户会话
     */
    public function terminateSession($sessionId) {
        if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => '方法不允许']);
            return;
        }
        
        try {
            $response = $this->apiClient->delete("/auth/sessions/{$sessionId}");
            echo json_encode($response);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    }
    
    /**
     * 获取安全日志
     */
    public function getSecurityLogs() {
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => '方法不允许']);
            return;
        }
        
        $level = $_GET['level'] ?? '';
        $type = $_GET['type'] ?? '';
        $date = $_GET['date'] ?? '';
        
        $params = [];
        if ($level) $params['level'] = $level;
        if ($type) $params['type'] = $type;
        if ($date) $params['date'] = $date;
        
        try {
            $response = $this->apiClient->get('/logs/security', $params);
            echo json_encode($response);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    }
}
?>
