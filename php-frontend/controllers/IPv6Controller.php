<?php
/**
 * IPv6前缀池管理控制器
 */
class IPv6Controller {
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
     * IPv6前缀池管理页面
     */
    public function pools() {
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('ipv6.view');
            
            $poolsResponse = $this->apiClient->get('/ipv6/pools');
            $poolsData = $poolsResponse['data'] ?? [];
            $pools = $poolsData;
            $error = null;
            
        } catch (Exception $e) {
            $pools = [];
            $error = $e->getMessage();
        }
        
        require __DIR__ . '/../views/ipv6/pools.php';
    }

    /**
     * IPv6前缀分配管理页面
     */
    public function allocations() {
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('ipv6.view');
            
            $allocationsResponse = $this->apiClient->get('/ipv6/allocations');
            $allocationsData = $allocationsResponse['data'] ?? [];
            $allocations = $allocationsData;
            $error = null;
            
        } catch (Exception $e) {
            $allocations = [];
            $error = $e->getMessage();
        }
        
        require __DIR__ . '/../views/ipv6/allocations.php';
    }
    
    /**
     * 创建IPv6前缀池
     */
    public function createPool() {
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('ipv6.manage');
            
            if ($_SERVER['REQUEST_METHOD'] === 'POST') {
                // 验证CSRF令牌
                $this->permissionMiddleware->verifyCsrfToken($_POST['_token'] ?? '');
                
                // 验证输入
                $rules = [
                    'name' => 'required|string|min:3|max:50|alpha_num',
                    'prefix' => 'required|string|regex:/^[0-9a-fA-F:]+$/',
                    'description' => 'string|max:255'
                ];
                
                $validation = InputValidator::validate($_POST, $rules);
                if (!$validation['valid']) {
                    ResponseHandler::validationError($validation['errors']);
                }
                
                $poolData = [
                    'name' => $validation['data']['name'],
                    'prefix' => $validation['data']['prefix'],
                    'description' => $validation['data']['description'] ?? ''
                ];
                
                $result = $this->apiClient->post('/ipv6/pools', $poolData);
                
                if ($result['success']) {
                    ResponseHandler::redirect('/ipv6/pools', 'IPv6前缀池创建成功');
                } else {
                    ResponseHandler::error('创建失败: ' . ($result['message'] ?? '未知错误'));
                }
            }
            
            $pageTitle = '创建IPv6前缀池';
            $showSidebar = true;
            
            include 'views/layout/header.php';
            include 'views/ipv6/create_pool.php';
            include 'views/layout/footer.php';
            
        } catch (Exception $e) {
            ResponseHandler::showError('创建失败', $e->getMessage());
        }
    }
    
    /**
     * 编辑IPv6前缀池
     */
    public function editPool() {
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('ipv6.manage');
            
            $poolId = $_GET['id'] ?? null;
            if (!$poolId) {
                ResponseHandler::error('缺少池ID参数');
            }
            
            if ($_SERVER['REQUEST_METHOD'] === 'POST') {
                // 验证CSRF令牌
                $this->permissionMiddleware->verifyCsrfToken($_POST['_token'] ?? '');
                
                // 验证输入
                $rules = [
                    'name' => 'required|string|min:3|max:50|alpha_num',
                    'prefix' => 'required|string|regex:/^[0-9a-fA-F:]+$/',
                    'description' => 'string|max:255'
                ];
                
                $validation = InputValidator::validate($_POST, $rules);
                if (!$validation['valid']) {
                    ResponseHandler::validationError($validation['errors']);
                }
                
                $poolData = [
                    'name' => $validation['data']['name'],
                    'prefix' => $validation['data']['prefix'],
                    'description' => $validation['data']['description'] ?? ''
                ];
                
                $result = $this->apiClient->put("/ipv6/pools/{$poolId}", $poolData);
                
                if ($result['success']) {
                    ResponseHandler::redirect('/ipv6/pools', 'IPv6前缀池更新成功');
                } else {
                    ResponseHandler::error('更新失败: ' . ($result['message'] ?? '未知错误'));
                }
            }
            
            // 获取池信息
            $poolResponse = $this->apiClient->get("/ipv6/pools/{$poolId}");
            $pool = $poolResponse['data'] ?? null;
            
            if (!$pool) {
                ResponseHandler::notFound('IPv6前缀池不存在');
            }
            
            $pageTitle = '编辑IPv6前缀池';
            $showSidebar = true;
            
            include 'views/layout/header.php';
            include 'views/ipv6/edit_pool.php';
            include 'views/layout/footer.php';
            
        } catch (Exception $e) {
            ResponseHandler::showError('编辑失败', $e->getMessage());
        }
    }
    
    /**
     * 删除IPv6前缀池
     */
    public function deletePool() {
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('ipv6.manage');
            
            if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
                ResponseHandler::error('无效的请求方法');
            }
            
            // 验证CSRF令牌
            $this->permissionMiddleware->verifyCsrfToken($_POST['_token'] ?? '');
            
            $poolId = $_POST['id'] ?? null;
            if (!$poolId) {
                ResponseHandler::error('缺少池ID参数');
            }
            
            $result = $this->apiClient->delete("/ipv6/pools/{$poolId}");
            
            if ($result['success']) {
                ResponseHandler::redirect('/ipv6/pools', 'IPv6前缀池删除成功');
            } else {
                ResponseHandler::error('删除失败: ' . ($result['message'] ?? '未知错误'));
            }
            
        } catch (Exception $e) {
            ResponseHandler::showError('删除失败', $e->getMessage());
        }
    }
    
    /**
     * 分配IPv6前缀
     */
    public function allocatePrefix() {
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('ipv6.manage');
            
            if ($_SERVER['REQUEST_METHOD'] === 'POST') {
                // 验证CSRF令牌
                $this->permissionMiddleware->verifyCsrfToken($_POST['_token'] ?? '');
                
                // 验证输入
                $rules = [
                    'pool_id' => 'required|integer',
                    'client_id' => 'required|integer',
                    'prefix_length' => 'required|integer|min:48|max:128'
                ];
                
                $validation = InputValidator::validate($_POST, $rules);
                if (!$validation['valid']) {
                    ResponseHandler::validationError($validation['errors']);
                }
                
                $allocationData = [
                    'pool_id' => $validation['data']['pool_id'],
                    'client_id' => $validation['data']['client_id'],
                    'prefix_length' => $validation['data']['prefix_length']
                ];
                
                $result = $this->apiClient->post('/ipv6/allocations', $allocationData);
                
                if ($result['success']) {
                    ResponseHandler::redirect('/ipv6/allocations', 'IPv6前缀分配成功');
                } else {
                    ResponseHandler::error('分配失败: ' . ($result['message'] ?? '未知错误'));
                }
            }
            
            // 获取池列表和客户端列表
            $poolsResponse = $this->apiClient->get('/ipv6/pools');
            $clientsResponse = $this->apiClient->get('/wireguard/clients');
            
            $pools = $poolsResponse['data'] ?? [];
            $clients = $clientsResponse['data'] ?? [];
            
            $pageTitle = '分配IPv6前缀';
            $showSidebar = true;
            
            include 'views/layout/header.php';
            include 'views/ipv6/allocate_prefix.php';
            include 'views/layout/footer.php';
            
        } catch (Exception $e) {
            ResponseHandler::showError('分配失败', $e->getMessage());
        }
    }
    
    /**
     * 释放IPv6前缀
     */
    public function releasePrefix() {
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('ipv6.manage');
            
            if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
                ResponseHandler::error('无效的请求方法');
            }
            
            // 验证CSRF令牌
            $this->permissionMiddleware->verifyCsrfToken($_POST['_token'] ?? '');
            
            $allocationId = $_POST['id'] ?? null;
            if (!$allocationId) {
                ResponseHandler::error('缺少分配ID参数');
            }
            
            $result = $this->apiClient->delete("/ipv6/allocations/{$allocationId}");
            
            if ($result['success']) {
                ResponseHandler::redirect('/ipv6/allocations', 'IPv6前缀释放成功');
            } else {
                ResponseHandler::error('释放失败: ' . ($result['message'] ?? '未知错误'));
            }
            
        } catch (Exception $e) {
            ResponseHandler::showError('释放失败', $e->getMessage());
        }
    }

    /**
     * IPv6统计信息页面
     */
    public function statistics() {
        $statsData = $this->apiClient->get('/ipv6/statistics');
        $stats = $statsData['statistics'] ?? null;
        $error = $statsData['error'] ?? null;
        
        require __DIR__ . '/../views/ipv6/statistics.php';
    }

    /**
     * 编辑IPv6前缀分配
     */
    public function editAllocation() {
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('ipv6.manage');
            
            $allocationId = $_GET['id'] ?? null;
            if (!$allocationId) {
                ResponseHandler::error('缺少分配ID参数');
            }
            
            if ($_SERVER['REQUEST_METHOD'] === 'POST') {
                // 验证CSRF令牌
                $this->permissionMiddleware->verifyCsrfToken($_POST['_token'] ?? '');
                
                // 验证输入
                $rules = [
                    'client_name' => 'required|string|min:3|max:50',
                    'description' => 'string|max:255'
                ];
                
                $validation = InputValidator::validate($_POST, $rules);
                if (!$validation['valid']) {
                    ResponseHandler::validationError($validation['errors']);
                }
                
                $allocationData = [
                    'client_name' => $validation['data']['client_name'],
                    'description' => $validation['data']['description'] ?? '',
                    'is_active' => isset($_POST['is_active'])
                ];
                
                $result = $this->apiClient->put("/ipv6/allocations/{$allocationId}", $allocationData);
                
                if ($result['success']) {
                    ResponseHandler::redirect('/ipv6/allocations', 'IPv6前缀分配更新成功');
                } else {
                    ResponseHandler::error('更新失败: ' . ($result['message'] ?? '未知错误'));
                }
            }
            
            // 获取分配信息
            $allocationResponse = $this->apiClient->get("/ipv6/allocations/{$allocationId}");
            $allocation = $allocationResponse['data'] ?? null;
            
            if (!$allocation) {
                ResponseHandler::notFound('IPv6前缀分配不存在');
            }
            
            $pageTitle = '编辑IPv6前缀分配';
            $showSidebar = true;
            
            include 'views/layout/header.php';
            include 'views/ipv6/edit_allocation.php';
            include 'views/layout/footer.php';
            
        } catch (Exception $e) {
            ResponseHandler::showError('编辑失败', $e->getMessage());
        }
    }
}
?>