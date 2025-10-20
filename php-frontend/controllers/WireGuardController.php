<?php
/**
 * WireGuard管理控制器
 */
class WireGuardController {
    private $auth;
    private $apiClient;
    private $permissionMiddleware;
    
    public function __construct() {
        $this->auth = new AuthJWT();
        $this->apiClient = new ApiClientJWT();
        $this->permissionMiddleware = new PermissionMiddleware();
        
        // 要求用户登录
        $this->permissionMiddleware->requireLogin();
    }
    
    /**
     * 显示服务器列表
     */
    public function servers() {
        try {
            $this->permissionMiddleware->requirePermission('wireguard.view');
            
            $serversResponse = $this->apiClient->get('/wireguard/servers');
            $servers = [];
            if (is_array($serversResponse)) {
                if (isset($serversResponse['data']) && is_array($serversResponse['data'])) {
                    $servers = $serversResponse['data'];
                } else {
                    $servers = $serversResponse;
                }
            }
            
            $pageTitle = 'WireGuard服务器管理';
            $showSidebar = true;
            
            include 'views/layout/header.php';
            include 'views/wireguard/servers.php';
            include 'views/layout/footer.php';
            
        } catch (Exception $e) {
            ErrorHandlerJWT::logCustomError('加载服务器列表失败: ' . $e->getMessage(), [
                'file' => __FILE__,
                'line' => __LINE__,
                'method' => 'servers',
                'user' => $_SESSION['user']['username'] ?? '未登录'
            ]);
            $this->handleError('加载服务器列表失败: ' . $e->getMessage());
        }
    }
    
    /**
     * 显示客户端列表
     */
    public function clients() {
        try {
            $this->permissionMiddleware->requirePermission('wireguard.view');
            
            $clientsResponse = $this->apiClient->get('/wireguard/clients');
            $clients = [];
            if (is_array($clientsResponse)) {
                if (isset($clientsResponse['data']) && is_array($clientsResponse['data'])) {
                    $clients = $clientsResponse['data'];
                } else {
                    $clients = $clientsResponse;
                }
            }
            
            $pageTitle = 'WireGuard客户端管理';
            $showSidebar = true;
            
            include 'views/layout/header.php';
            include 'views/wireguard/clients.php';
            include 'views/layout/footer.php';
            
        } catch (Exception $e) {
            $this->handleError('加载客户端列表失败: ' . $e->getMessage());
        }
    }
    
    /**
     * 创建服务器
     */
    public function createServer() {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            Router::redirect('/wireguard/servers');
            return;
        }
        
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('wireguard.manage');
            
            // 验证CSRF令牌
            $this->permissionMiddleware->verifyCsrfToken($_POST['_token'] ?? '');
            
            $serverData = [
                'name' => trim($_POST['name'] ?? ''),
                'interface' => trim($_POST['interface'] ?? 'wg0'),
                'listen_port' => (int)($_POST['listen_port'] ?? 51820),
                'ipv4_address' => trim($_POST['ipv4_address'] ?? ''),
                'ipv6_address' => trim($_POST['ipv6_address'] ?? ''),
                'dns_servers' => array_filter(explode(',', $_POST['dns_servers'] ?? '')),
                'mtu' => (int)($_POST['mtu'] ?? 1420),
                'is_active' => isset($_POST['is_active'])
            ];
            
            // 验证必填字段
            if (empty($serverData['name'])) {
                throw new Exception('服务器名称不能为空');
            }
            
            if (empty($serverData['ipv4_address']) && empty($serverData['ipv6_address'])) {
                throw new Exception('至少需要配置一个IP地址');
            }
            
            $response = $this->apiClient->post('/wireguard/servers', $serverData);
            
            if ($response['success'] ?? false) {
                $this->showMessage('服务器创建成功', 'success');
            } else {
                throw new Exception($response['message'] ?? '创建失败');
            }
            
        } catch (Exception $e) {
            $this->showMessage('创建服务器失败: ' . $e->getMessage(), 'error');
        }
        
        Router::redirect('/wireguard/servers');
    }
    
    /**
     * 创建客户端
     */
    public function createClient() {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            Router::redirect('/wireguard/clients');
            return;
        }
        
        try {
            $this->permissionMiddleware->requirePermission('wireguard.manage');
            
            // 验证CSRF令牌
            if (!$this->auth->verifyCsrfToken($_POST['_token'] ?? '')) {
                throw new Exception('安全令牌验证失败');
            }
            
            $clientData = [
                'name' => trim($_POST['name'] ?? ''),
                'description' => trim($_POST['description'] ?? ''),
                'server_id' => $_POST['server_id'] ?? '',
                'ipv4_address' => trim($_POST['ipv4_address'] ?? ''),
                'ipv6_address' => trim($_POST['ipv6_address'] ?? ''),
                'allowed_ips' => array_filter(explode(',', $_POST['allowed_ips'] ?? '')),
                'persistent_keepalive' => (int)($_POST['persistent_keepalive'] ?? 25),
                'is_active' => isset($_POST['is_active'])
            ];
            
            // 验证必填字段
            if (empty($clientData['name'])) {
                throw new Exception('客户端名称不能为空');
            }
            
            if (empty($clientData['server_id'])) {
                throw new Exception('请选择服务器');
            }
            
            $response = $this->apiClient->post('/wireguard/clients', $clientData);
            
            if ($response['success'] ?? false) {
                $this->showMessage('客户端创建成功', 'success');
            } else {
                throw new Exception($response['message'] ?? '创建失败');
            }
            
        } catch (Exception $e) {
            $this->showMessage('创建客户端失败: ' . $e->getMessage(), 'error');
        }
        
        Router::redirect('/wireguard/clients');
    }
    
    /**
     * 获取服务器详情
     */
    public function getServer($id) {
        try {
            $this->permissionMiddleware->requirePermission('wireguard.view');
            
            $server = $this->apiClient->get("/wireguard/servers/{$id}");
            
            echo json_encode([
                'success' => true,
                'data' => $server
            ]);
            
        } catch (Exception $e) {
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
    }
    
    /**
     * 获取客户端详情
     */
    public function getClient($id) {
        try {
            $this->permissionMiddleware->requirePermission('wireguard.view');
            
            $client = $this->apiClient->get("/wireguard/clients/{$id}");
            
            echo json_encode([
                'success' => true,
                'data' => $client
            ]);
            
        } catch (Exception $e) {
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
    }
    
    /**
     * 更新服务器
     */
    public function updateServer($id) {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            Router::redirect('/wireguard/servers');
            return;
        }
        
        try {
            $this->permissionMiddleware->requirePermission('wireguard.manage');
            
            // 验证CSRF令牌
            if (!$this->auth->verifyCsrfToken($_POST['_token'] ?? '')) {
                throw new Exception('安全令牌验证失败');
            }
            
            $serverData = [
                'name' => trim($_POST['name'] ?? ''),
                'interface' => trim($_POST['interface'] ?? 'wg0'),
                'listen_port' => (int)($_POST['listen_port'] ?? 51820),
                'ipv4_address' => trim($_POST['ipv4_address'] ?? ''),
                'ipv6_address' => trim($_POST['ipv6_address'] ?? ''),
                'dns_servers' => array_filter(explode(',', $_POST['dns_servers'] ?? '')),
                'mtu' => (int)($_POST['mtu'] ?? 1420),
                'is_active' => isset($_POST['is_active'])
            ];
            
            $response = $this->apiClient->put("/wireguard/servers/{$id}", $serverData);
            
            if ($response['success'] ?? false) {
                $this->showMessage('服务器更新成功', 'success');
            } else {
                throw new Exception($response['message'] ?? '更新失败');
            }
            
        } catch (Exception $e) {
            $this->showMessage('更新服务器失败: ' . $e->getMessage(), 'error');
        }
        
        Router::redirect('/wireguard/servers');
    }
    
    /**
     * 更新客户端
     */
    public function updateClient($id) {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            Router::redirect('/wireguard/clients');
            return;
        }
        
        try {
            $this->permissionMiddleware->requirePermission('wireguard.manage');
            
            // 验证CSRF令牌
            if (!$this->auth->verifyCsrfToken($_POST['_token'] ?? '')) {
                throw new Exception('安全令牌验证失败');
            }
            
            $clientData = [
                'name' => trim($_POST['name'] ?? ''),
                'description' => trim($_POST['description'] ?? ''),
                'server_id' => $_POST['server_id'] ?? '',
                'ipv4_address' => trim($_POST['ipv4_address'] ?? ''),
                'ipv6_address' => trim($_POST['ipv6_address'] ?? ''),
                'allowed_ips' => array_filter(explode(',', $_POST['allowed_ips'] ?? '')),
                'persistent_keepalive' => (int)($_POST['persistent_keepalive'] ?? 25),
                'is_active' => isset($_POST['is_active'])
            ];
            
            $response = $this->apiClient->put("/wireguard/clients/{$id}", $clientData);
            
            if ($response['success'] ?? false) {
                $this->showMessage('客户端更新成功', 'success');
            } else {
                throw new Exception($response['message'] ?? '更新失败');
            }
            
        } catch (Exception $e) {
            $this->showMessage('更新客户端失败: ' . $e->getMessage(), 'error');
        }
        
        Router::redirect('/wireguard/clients');
    }
    
    /**
     * 删除服务器
     */
    public function deleteServer($id) {
        try {
            $this->permissionMiddleware->requirePermission('wireguard.manage');
            
            $response = $this->apiClient->delete("/wireguard/servers/{$id}");
            
            if ($response['success'] ?? false) {
                $this->showMessage('服务器删除成功', 'success');
            } else {
                throw new Exception($response['message'] ?? '删除失败');
            }
            
        } catch (Exception $e) {
            $this->showMessage('删除服务器失败: ' . $e->getMessage(), 'error');
        }
        
        Router::redirect('/wireguard/servers');
    }
    
    /**
     * 删除客户端
     */
    public function deleteClient($id) {
        try {
            $this->permissionMiddleware->requirePermission('wireguard.manage');
            
            $response = $this->apiClient->delete("/wireguard/clients/{$id}");
            
            if ($response['success'] ?? false) {
                $this->showMessage('客户端删除成功', 'success');
            } else {
                throw new Exception($response['message'] ?? '删除失败');
            }
            
        } catch (Exception $e) {
            $this->showMessage('删除客户端失败: ' . $e->getMessage(), 'error');
        }
        
        Router::redirect('/wireguard/clients');
    }
    
    /**
     * 启动服务器
     */
    public function startServer($id) {
        try {
            $this->permissionMiddleware->requirePermission('wireguard.manage');
            
            $response = $this->apiClient->post("/wireguard/servers/{$id}/start");
            
            if ($response['success'] ?? false) {
                $this->showMessage('服务器启动成功', 'success');
            } else {
                throw new Exception($response['message'] ?? '启动失败');
            }
            
        } catch (Exception $e) {
            $this->showMessage('启动服务器失败: ' . $e->getMessage(), 'error');
        }
        
        Router::redirect('/wireguard/servers');
    }
    
    /**
     * 停止服务器
     */
    public function stopServer($id) {
        try {
            $this->permissionMiddleware->requirePermission('wireguard.manage');
            
            $response = $this->apiClient->post("/wireguard/servers/{$id}/stop");
            
            if ($response['success'] ?? false) {
                $this->showMessage('服务器停止成功', 'success');
            } else {
                throw new Exception($response['message'] ?? '停止失败');
            }
            
        } catch (Exception $e) {
            $this->showMessage('停止服务器失败: ' . $e->getMessage(), 'error');
        }
        
        Router::redirect('/wireguard/servers');
    }
    
    /**
     * 导出配置文件
     */
    public function exportConfig($id, $type = 'server') {
        try {
            $this->permissionMiddleware->requirePermission('wireguard.view');
            
            if ($type === 'server') {
                $response = $this->apiClient->get("/wireguard/servers/{$id}/config");
            } else {
                $response = $this->apiClient->get("/wireguard/clients/{$id}/config");
            }
            
            if ($response['config'] ?? false) {
                $filename = ($type === 'server' ? 'server' : 'client') . "_{$id}.conf";
                
                header('Content-Type: application/octet-stream');
                header('Content-Disposition: attachment; filename="' . $filename . '"');
                echo $response['config'];
                exit;
            } else {
                throw new Exception('配置文件生成失败');
            }
            
        } catch (Exception $e) {
            $this->showMessage('导出配置文件失败: ' . $e->getMessage(), 'error');
            Router::redirect('/wireguard/' . ($type === 'server' ? 'servers' : 'clients'));
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
