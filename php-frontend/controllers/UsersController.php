<?php
/**
 * 用户管理控制器
 */
class UsersController {
    private $auth;
    private $apiClient;
    private $permissionMiddleware;

    public function __construct(ApiClientJWT $apiClient = null) {
        $this->auth = new AuthJWT();
        $this->apiClient = $apiClient ?: new ApiClientJWT();
        $this->permissionMiddleware = new PermissionMiddleware();
        
        // 要求用户登录
        $this->permissionMiddleware->requireLogin();
    }

    /**
     * 用户列表
     */
    public function index() {
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('users.view');
            
            $usersData = $this->apiClient->get('/users');
            $users = $usersData['data'] ?? $usersData['users'] ?? [];
            $error = $usersData['error'] ?? null;
            
            $pageTitle = '用户管理';
            $showSidebar = true;
            
            include 'views/layout/header.php';
            include 'views/users/list.php';
            include 'views/layout/footer.php';
            
        } catch (Exception $e) {
            $this->handleError('加载用户列表失败: ' . $e->getMessage());
        }
    }

    /**
     * 创建用户
     */
    public function create() {
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('users.manage');
            
            if ($_SERVER['REQUEST_METHOD'] === 'POST') {
                // 验证CSRF令牌
                $this->permissionMiddleware->verifyCsrfToken($_POST['_token'] ?? '');
                
                $data = [
                    'username' => trim($_POST['username'] ?? ''),
                    'email' => trim($_POST['email'] ?? ''),
                    'password' => $_POST['password'] ?? '',
                    'full_name' => trim($_POST['full_name'] ?? ''),
                    'role' => $_POST['role'] ?? 'user',
                    'is_active' => isset($_POST['is_active'])
                ];

                // 验证输入
                if (empty($data['username'])) {
                    throw new Exception('用户名不能为空');
                }
                
                if (empty($data['email'])) {
                    throw new Exception('邮箱不能为空');
                }
                
                if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
                    throw new Exception('邮箱格式不正确');
                }
                
                if (empty($data['password'])) {
                    throw new Exception('密码不能为空');
                }
                
                if (strlen($data['password']) < 6) {
                    throw new Exception('密码长度不能少于6位');
                }

                $result = $this->apiClient->post('/users', $data);
                
                if (isset($result['error'])) {
                    throw new Exception($result['error']);
                } else {
                    $this->showMessage('用户创建成功', 'success');
                    Router::redirect('/users');
                    return;
                }
            }
            
            $pageTitle = '创建用户';
            $showSidebar = true;
            
            include 'views/layout/header.php';
            include 'views/users/create.php';
            include 'views/layout/footer.php';
            
        } catch (Exception $e) {
            $this->handleError('创建用户失败: ' . $e->getMessage());
        }
    }

    /**
     * 编辑用户
     */
    public function edit($userId) {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'email' => $_POST['email'] ?? '',
                'full_name' => $_POST['full_name'] ?? '',
                'role' => $_POST['role'] ?? 'user',
                'is_active' => isset($_POST['is_active'])
            ];

            // 如果提供了新密码，则更新密码
            if (!empty($_POST['password'])) {
                $data['password'] = $_POST['password'];
            }

            $result = $this->apiClient->put("/users/$userId", $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                header('Location: /users');
                exit();
            }
        }

        $userData = $this->apiClient->get("/users/$userId");
        $user = $userData['user'] ?? null;
        $error = $userData['error'] ?? null;
        
        require __DIR__ . '/../views/users/edit.php';
    }

    /**
     * 删除用户
     */
    public function delete($userId) {
        $result = $this->apiClient->delete("/users/$userId");
        
        if (isset($result['error'])) {
            $_SESSION['error'] = $result['error'];
        } else {
            $_SESSION['success'] = '用户删除成功';
        }
        
        header('Location: /users');
        exit();
    }

    /**
     * 用户详情
     */
    public function details($userId) {
        $userData = $this->apiClient->get("/users/$userId");
        $user = $userData['user'] ?? null;
        $error = $userData['error'] ?? null;
        
        require __DIR__ . '/../views/users/details.php';
    }

    /**
     * 角色管理
     */
    public function roles() {
        $rolesData = $this->apiClient->get('/users/roles');
        $roles = $rolesData['roles'] ?? [];
        $error = $rolesData['error'] ?? null;
        
        require __DIR__ . '/../views/users/roles.php';
    }

    /**
     * 创建角色
     */
    public function createRole() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'name' => $_POST['name'] ?? '',
                'description' => $_POST['description'] ?? '',
                'permissions' => $_POST['permissions'] ?? []
            ];

            $result = $this->apiClient->post('/users/roles', $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                header('Location: /users/roles');
                exit();
            }
        }
        
        require __DIR__ . '/../views/users/create_role.php';
    }

    /**
     * 编辑角色
     */
    public function editRole($roleId) {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'name' => $_POST['name'] ?? '',
                'description' => $_POST['description'] ?? '',
                'permissions' => $_POST['permissions'] ?? []
            ];

            $result = $this->apiClient->put("/users/roles/$roleId", $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                header('Location: /users/roles');
                exit();
            }
        }

        $roleData = $this->apiClient->get("/users/roles/$roleId");
        $role = $roleData['role'] ?? null;
        $error = $roleData['error'] ?? null;
        
        require __DIR__ . '/../views/users/edit_role.php';
    }

    /**
     * 删除角色
     */
    public function deleteRole($roleId) {
        $result = $this->apiClient->delete("/users/roles/$roleId");
        
        if (isset($result['error'])) {
            $_SESSION['error'] = $result['error'];
        } else {
            $_SESSION['success'] = '角色删除成功';
        }
        
        header('Location: /users/roles');
        exit();
    }

    /**
     * 用户权限管理
     */
    public function permissions($userId) {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'permissions' => $_POST['permissions'] ?? []
            ];

            $result = $this->apiClient->put("/users/$userId/permissions", $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                header('Location: /users');
                exit();
            }
        }

        $userData = $this->apiClient->get("/users/$userId");
        $user = $userData['user'] ?? null;
        $error = $userData['error'] ?? null;
        
        require __DIR__ . '/../views/users/permissions.php';
    }

    /**
     * 重置用户密码
     */
    public function resetPassword($userId) {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'new_password' => $_POST['new_password'] ?? ''
            ];

            $result = $this->apiClient->post("/users/$userId/reset-password", $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                $_SESSION['success'] = '密码重置成功';
                header('Location: /users');
                exit();
            }
        }

        $userData = $this->apiClient->get("/users/$userId");
        $user = $userData['user'] ?? null;
        $error = $userData['error'] ?? null;
        
        require __DIR__ . '/../views/users/reset_password.php';
    }

    /**
     * 用户活动日志
     */
    public function activity($userId) {
        $activityData = $this->apiClient->get("/users/$userId/activity");
        $activities = $activityData['activities'] ?? [];
        $error = $activityData['error'] ?? null;
        
        require __DIR__ . '/../views/users/activity.php';
    }

    /**
     * 批量操作
     */
    public function batch() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $action = $_POST['action'] ?? '';
            $userIds = $_POST['user_ids'] ?? [];

            if (empty($userIds)) {
                $_SESSION['error'] = '请选择要操作的用户';
                header('Location: /users');
                exit();
            }

            $data = [
                'action' => $action,
                'user_ids' => $userIds
            ];

            $result = $this->apiClient->post('/users/batch', $data);
            
            if (isset($result['error'])) {
                $_SESSION['error'] = $result['error'];
            } else {
                $_SESSION['success'] = '批量操作完成';
            }
            
            header('Location: /users');
            exit();
        }
    }
    
    /**
     * 显示消息
     */
    private function showMessage($message, $type = 'info') {
        $_SESSION['message'] = $message;
        $_SESSION['message_type'] = $type;
    }
    
    /**
     * 处理错误
     */
    private function handleError($message) {
        $pageTitle = '错误';
        $showSidebar = true;
        $error = $message;
        
        include 'views/layout/header.php';
        include 'views/errors/error.php';
        include 'views/layout/footer.php';
    }
}
?>
