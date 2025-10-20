<?php
/**
 * 监控控制器
 */
class MonitoringController {
    private $auth;
    private $apiClient;

    public function __construct() {
        $this->auth = new AuthJWT();
        $this->apiClient = new ApiClientJWT();
    }
    
    /**
     * 显示监控仪表板
     */
    public function dashboard() {
        // 检查登录状态
        if (!$this->auth->isLoggedIn()) {
            Router::redirect('/login');
            return;
        }
        
        $pageTitle = '监控仪表板';
        $showSidebar = true;
        
        include 'views/layout/header.php';
        include 'views/monitoring/dashboard.php';
        include 'views/layout/footer.php';
    }
    
    /**
     * 获取系统指标
     */
    public function getMetrics() {
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => '方法不允许']);
            return;
        }
        
        try {
            $response = $this->apiClient->get('/monitoring/metrics');
            echo json_encode($response);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    }
    
    /**
     * 获取服务状态
     */
    public function getServices() {
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => '方法不允许']);
            return;
        }
        
        try {
            $response = $this->apiClient->get('/monitoring/services');
            echo json_encode($response);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    }
    
    /**
     * 获取性能历史数据
     */
    public function getPerformanceHistory() {
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => '方法不允许']);
            return;
        }
        
        $hours = $_GET['hours'] ?? 1;
        
        try {
            $response = $this->apiClient->get('/monitoring/performance-history', ['hours' => $hours]);
            echo json_encode($response);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    }
    
    /**
     * 获取WireGuard状态
     */
    public function getWireGuardStatus() {
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => '方法不允许']);
            return;
        }
        
        try {
            $response = $this->apiClient->get('/wireguard/status');
            echo json_encode($response);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    }
    
    /**
     * 获取活跃告警
     */
    public function getAlerts() {
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => '方法不允许']);
            return;
        }
        
        $severity = $_GET['severity'] ?? '';
        $status = $_GET['status'] ?? 'active';
        
        $params = ['status' => $status];
        if ($severity) $params['severity'] = $severity;
        
        try {
            $response = $this->apiClient->get('/monitoring/alerts', $params);
            echo json_encode($response);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    }
    
    /**
     * 获取最近日志
     */
    public function getRecentLogs() {
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => '方法不允许']);
            return;
        }
        
        $level = $_GET['level'] ?? '';
        $limit = $_GET['limit'] ?? 50;
        
        $params = ['limit' => $limit];
        if ($level) $params['level'] = $level;
        
        try {
            $response = $this->apiClient->get('/logs/recent', $params);
            echo json_encode($response);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    }
    
    /**
     * 获取系统健康状态
     */
    public function getHealth() {
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => '方法不允许']);
            return;
        }
        
        try {
            $response = $this->apiClient->get('/health');
            echo json_encode($response);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    }
    
    /**
     * 获取Prometheus指标
     */
    public function getPrometheusMetrics() {
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => '方法不允许']);
            return;
        }
        
        try {
            $response = $this->apiClient->get('/metrics');
            echo $response;
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    }
}
?>