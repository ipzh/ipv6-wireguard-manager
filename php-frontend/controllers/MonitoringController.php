<?php
/**
 * 系统监控控制器
 */
class MonitoringController {
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
     * 监控仪表板
     */
    public function index() {
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('monitoring.view');
            
            $metricsData = $this->apiClient->get('/monitoring/metrics');
            $alertsData = $this->apiClient->get('/monitoring/alerts');
            $systemInfoData = $this->apiClient->get('/monitoring/system');
            
            $metrics = $metricsData['metrics'] ?? null;
            $alerts = $alertsData['alerts'] ?? [];
            $systemInfo = $systemInfoData['system'] ?? null;
            $error = $metricsData['error'] ?? $alertsData['error'] ?? $systemInfoData['error'] ?? null;
            
        } catch (Exception $e) {
            $metrics = null;
            $alerts = [];
            $systemInfo = null;
            $error = $e->getMessage();
        }
        
        require __DIR__ . '/../views/monitoring/dashboard.php';
    }

    /**
     * 实时指标
     */
    public function metrics() {
        $metricsData = $this->apiClient->get('/monitoring/metrics');
        $metrics = $metricsData['metrics'] ?? null;
        $error = $metricsData['error'] ?? null;
        
        require __DIR__ . '/../views/monitoring/metrics.php';
    }

    /**
     * 告警管理
     */
    public function alerts() {
        $alertsData = $this->apiClient->get('/monitoring/alerts');
        $alerts = $alertsData['alerts'] ?? [];
        $error = $alertsData['error'] ?? null;
        
        require __DIR__ . '/../views/monitoring/alerts.php';
    }

    /**
     * 历史数据
     */
    public function history() {
        $startDate = $_GET['start_date'] ?? date('Y-m-d', strtotime('-7 days'));
        $endDate = $_GET['end_date'] ?? date('Y-m-d');
        $metric = $_GET['metric'] ?? 'cpu';
        
        $historyData = $this->apiClient->get("/monitoring/history?start_date=$startDate&end_date=$endDate&metric=$metric");
        $history = $historyData['history'] ?? [];
        $error = $historyData['error'] ?? null;
        
        require __DIR__ . '/../views/monitoring/history.php';
    }

    /**
     * 系统信息
     */
    public function system() {
        $systemData = $this->apiClient->get('/monitoring/system');
        $system = $systemData['system'] ?? null;
        $error = $systemData['error'] ?? null;
        
        require __DIR__ . '/../views/monitoring/system.php';
    }

    /**
     * 进程管理
     */
    public function processes() {
        $processesData = $this->apiClient->get('/monitoring/processes');
        $processes = $processesData['processes'] ?? [];
        $error = $processesData['error'] ?? null;
        
        require __DIR__ . '/../views/monitoring/processes.php';
    }

    /**
     * 网络监控
     */
    public function network() {
        $networkData = $this->apiClient->get('/monitoring/network');
        $network = $networkData['network'] ?? null;
        $error = $networkData['error'] ?? null;
        
        require __DIR__ . '/../views/monitoring/network.php';
    }

    /**
     * 磁盘监控
     */
    public function disk() {
        $diskData = $this->apiClient->get('/monitoring/disk');
        $disk = $diskData['disk'] ?? null;
        $error = $diskData['error'] ?? null;
        
        require __DIR__ . '/../views/monitoring/disk.php';
    }

    /**
     * 创建告警规则
     */
    public function createAlert() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'name' => $_POST['name'] ?? '',
                'description' => $_POST['description'] ?? '',
                'metric' => $_POST['metric'] ?? '',
                'operator' => $_POST['operator'] ?? '',
                'threshold' => (float)($_POST['threshold'] ?? 0),
                'severity' => $_POST['severity'] ?? 'warning',
                'enabled' => isset($_POST['enabled'])
            ];

            $result = $this->apiClient->post('/monitoring/alerts', $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                header('Location: /monitoring/alerts');
                exit();
            }
        }
        
        require __DIR__ . '/../views/monitoring/create_alert.php';
    }

    /**
     * 编辑告警规则
     */
    public function editAlert($alertId) {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'name' => $_POST['name'] ?? '',
                'description' => $_POST['description'] ?? '',
                'metric' => $_POST['metric'] ?? '',
                'operator' => $_POST['operator'] ?? '',
                'threshold' => (float)($_POST['threshold'] ?? 0),
                'severity' => $_POST['severity'] ?? 'warning',
                'enabled' => isset($_POST['enabled'])
            ];

            $result = $this->apiClient->put("/monitoring/alerts/$alertId", $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                header('Location: /monitoring/alerts');
                exit();
            }
        }

        $alertData = $this->apiClient->get("/monitoring/alerts/$alertId");
        $alert = $alertData['alert'] ?? null;
        $error = $alertData['error'] ?? null;
        
        require __DIR__ . '/../views/monitoring/edit_alert.php';
    }

    /**
     * 删除告警规则
     */
    public function deleteAlert($alertId) {
        $result = $this->apiClient->delete("/monitoring/alerts/$alertId");
        
        if (isset($result['error'])) {
            $_SESSION['error'] = $result['error'];
        } else {
            $_SESSION['success'] = '告警规则删除成功';
        }
        
        header('Location: /monitoring/alerts');
        exit();
    }

    /**
     * 确认告警
     */
    public function acknowledgeAlert($alertId) {
        $result = $this->apiClient->post("/monitoring/alerts/$alertId/acknowledge");
        
        if (isset($result['error'])) {
            $_SESSION['error'] = $result['error'];
        } else {
            $_SESSION['success'] = '告警已确认';
        }
        
        header('Location: /monitoring/alerts');
        exit();
    }

    /**
     * 获取实时数据 (AJAX)
     */
    public function getRealtimeData() {
        header('Content-Type: application/json');
        
        $metricsData = $this->apiClient->get('/monitoring/metrics');
        $alertsData = $this->apiClient->get('/monitoring/alerts');
        
        echo json_encode([
            'metrics' => $metricsData['metrics'] ?? null,
            'alerts' => $alertsData['alerts'] ?? [],
            'timestamp' => time()
        ]);
        exit();
    }
}
?>
