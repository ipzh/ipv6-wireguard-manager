<?php
/**
 * IPv6前缀池管理控制器
 */
class IPv6Controller {
    private $apiClient;

    public function __construct(ApiClient $apiClient) {
        $this->apiClient = $apiClient;
    }

    /**
     * IPv6前缀池管理页面
     */
    public function pools() {
        $poolsData = $this->apiClient->get('/ipv6/pools');
        $pools = $poolsData['pools'] ?? [];
        $error = $poolsData['error'] ?? null;
        
        require __DIR__ . '/../views/ipv6/pools.php';
    }

    /**
     * IPv6前缀分配管理页面
     */
    public function allocations() {
        $allocationsData = $this->apiClient->get('/ipv6/allocations');
        $allocations = $allocationsData['allocations'] ?? [];
        $error = $allocationsData['error'] ?? null;
        
        require __DIR__ . '/../views/ipv6/allocations.php';
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
     * 创建IPv6前缀池
     */
    public function createPool() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'name' => $_POST['name'] ?? '',
                'description' => $_POST['description'] ?? '',
                'base_prefix' => $_POST['base_prefix'] ?? '',
                'prefix_len' => (int)($_POST['prefix_len'] ?? 0),
                'subnet_len' => (int)($_POST['subnet_len'] ?? 0),
                'is_active' => isset($_POST['is_active'])
            ];

            $result = $this->apiClient->post('/ipv6/pools', $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                header('Location: /ipv6/pools');
                exit();
            }
        }
        
        require __DIR__ . '/../views/ipv6/create_pool.php';
    }

    /**
     * 编辑IPv6前缀池
     */
    public function editPool($poolId) {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'name' => $_POST['name'] ?? '',
                'description' => $_POST['description'] ?? '',
                'base_prefix' => $_POST['base_prefix'] ?? '',
                'prefix_len' => (int)($_POST['prefix_len'] ?? 0),
                'subnet_len' => (int)($_POST['subnet_len'] ?? 0),
                'is_active' => isset($_POST['is_active'])
            ];

            $result = $this->apiClient->put("/ipv6/pools/$poolId", $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                header('Location: /ipv6/pools');
                exit();
            }
        }

        $poolData = $this->apiClient->get("/ipv6/pools/$poolId");
        $pool = $poolData['pool'] ?? null;
        $error = $poolData['error'] ?? null;
        
        require __DIR__ . '/../views/ipv6/edit_pool.php';
    }

    /**
     * 删除IPv6前缀池
     */
    public function deletePool($poolId) {
        $result = $this->apiClient->delete("/ipv6/pools/$poolId");
        
        if (isset($result['error'])) {
            $_SESSION['error'] = $result['error'];
        } else {
            $_SESSION['success'] = 'IPv6前缀池删除成功';
        }
        
        header('Location: /ipv6/pools');
        exit();
    }

    /**
     * 分配IPv6前缀
     */
    public function allocatePrefix() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'pool_id' => $_POST['pool_id'] ?? '',
                'client_name' => $_POST['client_name'] ?? '',
                'description' => $_POST['description'] ?? '',
                'subnet_len' => (int)($_POST['subnet_len'] ?? 0)
            ];

            $result = $this->apiClient->post('/ipv6/allocations', $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                header('Location: /ipv6/allocations');
                exit();
            }
        }

        // 获取前缀池列表
        $poolsData = $this->apiClient->get('/ipv6/pools');
        $pools = $poolsData['pools'] ?? [];
        
        require __DIR__ . '/../views/ipv6/allocate_prefix.php';
    }

    /**
     * 释放IPv6前缀
     */
    public function releasePrefix($allocationId) {
        $result = $this->apiClient->delete("/ipv6/allocations/$allocationId");
        
        if (isset($result['error'])) {
            $_SESSION['error'] = $result['error'];
        } else {
            $_SESSION['success'] = 'IPv6前缀释放成功';
        }
        
        header('Location: /ipv6/allocations');
        exit();
    }

    /**
     * 编辑IPv6前缀分配
     */
    public function editAllocation($allocationId) {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'client_name' => $_POST['client_name'] ?? '',
                'description' => $_POST['description'] ?? '',
                'is_active' => isset($_POST['is_active'])
            ];

            $result = $this->apiClient->put("/ipv6/allocations/$allocationId", $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                header('Location: /ipv6/allocations');
                exit();
            }
        }

        $allocationData = $this->apiClient->get("/ipv6/allocations/$allocationId");
        $allocation = $allocationData['allocation'] ?? null;
        $error = $allocationData['error'] ?? null;
        
        require __DIR__ . '/../views/ipv6/edit_allocation.php';
    }
}
?>
