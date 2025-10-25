<?php
/**
 * 用户个人资料控制器
 */
class ProfileController {
    private $auth;
    private $apiClient;
    
    public function __construct() {
        $this->auth = new AuthJWT();
        $this->apiClient = new ApiClientJWT();
        $this->permissionMiddleware = new PermissionMiddleware();
        
        // 要求用户登录
        $this->permissionMiddleware->requireLogin();
    }
    
    /**
     * 显示个人资料页面
     */
    public function index() {
        try {
            // 获取当前用户信息
            $currentUser = $this->auth->getCurrentUser();
            if (!$currentUser) {
                throw new Exception('用户信息获取失败');
            }
            
            // 尝试从API获取详细资料，如果失败则使用会话中的信息
            try {
                $profileData = $this->apiClient->get('/users/profile/me');
                $profile = $profileData['data'] ?? $profileData;
            } catch (Exception $e) {
                // 如果API调用失败，使用会话中的用户信息
                $profile = $currentUser;
                error_log('获取用户详细资料失败: ' . $e->getMessage());
            }
            
            $error = null;
        } catch (Exception $e) {
            $profile = null;
            $error = $e->getMessage();
        }
        
        $pageTitle = '个人资料';
        $showSidebar = true;
        
        include 'views/layout/header.php';
        include 'views/profile/index.php';
        include 'views/layout/footer.php';
    }
    
    /**
     * 更新个人资料
     */
    public function update() {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            header('Location: /profile');
            exit;
        }
        
        // 验证CSRF令牌
        $this->permissionMiddleware->verifyCsrfToken($_POST['_token'] ?? '');
        
        $data = [
            'username' => trim($_POST['username'] ?? ''),
            'email' => trim($_POST['email'] ?? ''),
            'full_name' => trim($_POST['full_name'] ?? '')
        ];
        
        // 验证输入
        if (empty($data['username'])) {
            $_SESSION['error'] = '用户名不能为空';
            header('Location: /profile');
            exit;
        }
        
        if (empty($data['email'])) {
            $_SESSION['error'] = '邮箱不能为空';
            header('Location: /profile');
            exit;
        }
        
        if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
            $_SESSION['error'] = '邮箱格式不正确';
            header('Location: /profile');
            exit;
        }
        
        try {
            $result = $this->apiClient->put('/users/profile/me', $data);
            
            if (isset($result['message'])) {
                $_SESSION['success'] = $result['message'];
            } else {
                $_SESSION['success'] = '个人资料更新成功';
            }
            
            // 更新会话中的用户信息
            if (isset($result['username'])) {
                $_SESSION['user']['username'] = $result['username'];
            }
            if (isset($result['email'])) {
                $_SESSION['user']['email'] = $result['email'];
            }
            
        } catch (Exception $e) {
            $_SESSION['error'] = '更新失败: ' . $e->getMessage();
        }
        
        header('Location: /profile');
        exit;
    }
    
    /**
     * 修改密码页面
     */
    public function changePassword() {
        $pageTitle = '修改密码';
        include 'views/layout/header.php';
        include 'views/profile/change_password.php';
        include 'views/layout/footer.php';
    }
    
    /**
     * 处理密码修改
     */
    public function updatePassword() {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            header('Location: /profile/change-password');
            exit;
        }
        
        // 验证CSRF令牌
        $this->permissionMiddleware->verifyCsrfToken($_POST['_token'] ?? '');
        
        $oldPassword = $_POST['old_password'] ?? '';
        $newPassword = $_POST['new_password'] ?? '';
        $confirmPassword = $_POST['confirm_password'] ?? '';
        
        // 验证输入
        if (empty($oldPassword)) {
            $_SESSION['error'] = '请输入原密码';
            header('Location: /profile/change-password');
            exit;
        }
        
        if (empty($newPassword)) {
            $_SESSION['error'] = '请输入新密码';
            header('Location: /profile/change-password');
            exit;
        }
        
        if (strlen($newPassword) < 6) {
            $_SESSION['error'] = '新密码长度不能少于6位';
            header('Location: /profile/change-password');
            exit;
        }
        
        if ($newPassword !== $confirmPassword) {
            $_SESSION['error'] = '新密码和确认密码不一致';
            header('Location: /profile/change-password');
            exit;
        }
        
        try {
            $data = [
                'old_password' => $oldPassword,
                'new_password' => $newPassword
            ];
            
            // 获取当前用户ID
            $currentUser = $this->auth->getCurrentUser();
            $userId = $currentUser['id'] ?? 1;
            
            $result = $this->apiClient->put("/users/{$userId}/password", $data);
            
            if (isset($result['message'])) {
                $_SESSION['success'] = $result['message'];
            } else {
                $_SESSION['success'] = '密码修改成功';
            }
            
        } catch (Exception $e) {
            $_SESSION['error'] = '密码修改失败: ' . $e->getMessage();
        }
        
        header('Location: /profile/change-password');
        exit;
    }
    
    /**
     * 安全设置页面
     */
    public function security() {
        $pageTitle = '安全设置';
        include 'views/layout/header.php';
        include 'views/profile/security.php';
        include 'views/layout/footer.php';
    }
    
    /**
     * 账户设置页面
     */
    public function settings() {
        try {
            $profileData = $this->apiClient->get('/users/profile/me');
            $profile = $profileData;
            $error = null;
        } catch (Exception $e) {
            $profile = null;
            $error = $e->getMessage();
        }
        
        $pageTitle = '账户设置';
        include 'views/layout/header.php';
        include 'views/profile/settings.php';
        include 'views/layout/footer.php';
    }
}
?>
