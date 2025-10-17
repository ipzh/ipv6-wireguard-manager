<?php
/**
 * BGP管理控制器
 */
class BGPController {
    private $auth;
    private $apiClient;
    private $permissionMiddleware;

    public function __construct(ApiClient $apiClient = null) {
        $this->auth = new Auth();
        $this->apiClient = $apiClient ?: new ApiClient();
        $this->permissionMiddleware = new PermissionMiddleware();
        
        // 要求用户登录
        $this->permissionMiddleware->requireLogin();
    }

    /**
     * BGP会话管理页面
     */
    public function sessions() {
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('bgp.view');
            
            $sessionsResponse = $this->apiClient->get('/bgp/sessions');
            $sessionsData = $sessionsResponse['data'] ?? [];
            $sessions = $sessionsData;
            $error = null;
            
        } catch (Exception $e) {
            $sessions = [];
            $error = $e->getMessage();
        }
        
        require __DIR__ . '/../views/bgp/sessions.php';
    }

    /**
     * BGP宣告管理页面
     */
    public function announcements() {
        $announcementsResponse = $this->apiClient->get('/bgp/routes');
        $announcementsData = $announcementsResponse['data'] ?? [];
        $announcements = $announcementsData;
        $error = null;
        
        require __DIR__ . '/../views/bgp/announcements.php';
    }

    /**
     * BGP状态监控页面
     */
    public function status() {
        $statusData = $this->apiClient->get('/bgp/status');
        $status = $statusData['status'] ?? null;
        $error = $statusData['error'] ?? null;
        
        require __DIR__ . '/../views/bgp/status.php';
    }

    /**
     * 创建BGP会话
     */
    public function createSession() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'name' => $_POST['name'] ?? '',
                'neighbor' => $_POST['neighbor'] ?? '',
                'remote_as' => (int)($_POST['remote_as'] ?? 0),
                'local_as' => (int)($_POST['local_as'] ?? 0),
                'password' => $_POST['password'] ?? '',
                'enabled' => isset($_POST['enabled'])
            ];

            $result = $this->apiClient->post('/bgp/sessions', $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                header('Location: /bgp/sessions');
                exit();
            }
        }
        
        require __DIR__ . '/../views/bgp/create_session.php';
    }

    /**
     * 编辑BGP会话
     */
    public function editSession($sessionId) {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'name' => $_POST['name'] ?? '',
                'neighbor' => $_POST['neighbor'] ?? '',
                'remote_as' => (int)($_POST['remote_as'] ?? 0),
                'local_as' => (int)($_POST['local_as'] ?? 0),
                'password' => $_POST['password'] ?? '',
                'enabled' => isset($_POST['enabled'])
            ];

            $result = $this->apiClient->put("/bgp/sessions/$sessionId", $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                header('Location: /bgp/sessions');
                exit();
            }
        }

        $sessionData = $this->apiClient->get("/bgp/sessions/$sessionId");
        $session = $sessionData['session'] ?? null;
        $error = $sessionData['error'] ?? null;
        
        require __DIR__ . '/../views/bgp/edit_session.php';
    }

    /**
     * 删除BGP会话
     */
    public function deleteSession($sessionId) {
        $result = $this->apiClient->delete("/bgp/sessions/$sessionId");
        
        if (isset($result['error'])) {
            $_SESSION['error'] = $result['error'];
        } else {
            $_SESSION['success'] = 'BGP会话删除成功';
        }
        
        header('Location: /bgp/sessions');
        exit();
    }

    /**
     * 启动BGP会话
     */
    public function startSession($sessionId) {
        $result = $this->apiClient->post("/bgp/sessions/$sessionId/start");
        
        if (isset($result['error'])) {
            $_SESSION['error'] = $result['error'];
        } else {
            $_SESSION['success'] = 'BGP会话启动成功';
        }
        
        header('Location: /bgp/sessions');
        exit();
    }

    /**
     * 停止BGP会话
     */
    public function stopSession($sessionId) {
        $result = $this->apiClient->post("/bgp/sessions/$sessionId/stop");
        
        if (isset($result['error'])) {
            $_SESSION['error'] = $result['error'];
        } else {
            $_SESSION['success'] = 'BGP会话停止成功';
        }
        
        header('Location: /bgp/sessions');
        exit();
    }

    /**
     * 创建BGP宣告
     */
    public function createAnnouncement() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'prefix' => $_POST['prefix'] ?? '',
                'next_hop' => $_POST['next_hop'] ?? '',
                'as_path' => $_POST['as_path'] ?? '',
                'communities' => $_POST['communities'] ?? '',
                'enabled' => isset($_POST['enabled'])
            ];

            $result = $this->apiClient->post('/bgp/announcements', $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                header('Location: /bgp/announcements');
                exit();
            }
        }
        
        require __DIR__ . '/../views/bgp/create_announcement.php';
    }

    /**
     * 编辑BGP宣告
     */
    public function editAnnouncement($announcementId) {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'prefix' => $_POST['prefix'] ?? '',
                'next_hop' => $_POST['next_hop'] ?? '',
                'as_path' => $_POST['as_path'] ?? '',
                'communities' => $_POST['communities'] ?? '',
                'enabled' => isset($_POST['enabled'])
            ];

            $result = $this->apiClient->put("/bgp/announcements/$announcementId", $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                header('Location: /bgp/announcements');
                exit();
            }
        }

        $announcementData = $this->apiClient->get("/bgp/announcements/$announcementId");
        $announcement = $announcementData['announcement'] ?? null;
        $error = $announcementData['error'] ?? null;
        
        require __DIR__ . '/../views/bgp/edit_announcement.php';
    }

    /**
     * 删除BGP宣告
     */
    public function deleteAnnouncement($announcementId) {
        $result = $this->apiClient->delete("/bgp/announcements/$announcementId");
        
        if (isset($result['error'])) {
            $_SESSION['error'] = $result['error'];
        } else {
            $_SESSION['success'] = 'BGP宣告删除成功';
        }
        
        header('Location: /bgp/announcements');
        exit();
    }
}
?>
