<?php
/**
 * 仪表板控制器
 */
class DashboardController {
    private $auth;
    private $apiClient;
    
    public function __construct() {
        $this->auth = new Auth();
        $this->apiClient = new ApiClient();
        
        // 要求用户登录
        $this->auth->requireLogin();
    }
    
    /**
     * 显示仪表板
     */
    public function index() {
        try {
            // 获取仪表板数据
            $dashboardData = $this->getDashboardData();
            
            $pageTitle = '仪表板';
            $showSidebar = true;
            
            include 'views/layout/header.php';
            include 'views/dashboard/index.php';
            include 'views/layout/footer.php';
            
        } catch (Exception $e) {
            $this->handleError('加载仪表板数据失败: ' . $e->getMessage());
        }
    }
    
    /**
     * 获取仪表板数据
     */
    private function getDashboardData() {
        $data = [
            'apiStatus' => null,
            'servers' => [],
            'clients' => [],
            'bgpAnnouncements' => [],
            'systemMetrics' => null,
            'recentLogs' => []
        ];
        
        try {
            // 获取API状态
            $data['apiStatus'] = $this->apiClient->getApiStatus();
        } catch (Exception $e) {
            $data['apiStatus'] = [
                'status' => 'error',
                'message' => $e->getMessage()
            ];
        }
        
        try {
            // 获取WireGuard服务器
            $serversResponse = $this->apiClient->get('/wireguard/servers');
            $data['servers'] = $serversResponse['data'] ?? [];
        } catch (Exception $e) {
            error_log('获取服务器列表失败: ' . $e->getMessage());
        }
        
        try {
            // 获取WireGuard客户端
            $clientsResponse = $this->apiClient->get('/wireguard/clients');
            $data['clients'] = $clientsResponse['data'] ?? [];
        } catch (Exception $e) {
            error_log('获取客户端列表失败: ' . $e->getMessage());
        }
        
        try {
            // 获取BGP宣告
            $bgpResponse = $this->apiClient->get('/bgp/routes');
            $data['bgpAnnouncements'] = $bgpResponse['data'] ?? [];
        } catch (Exception $e) {
            error_log('获取BGP宣告失败: ' . $e->getMessage());
        }
        
        try {
            // 获取系统指标
            $metricsResponse = $this->apiClient->get('/monitoring/metrics/system');
            $data['systemMetrics'] = $metricsResponse['data'] ?? [];
        } catch (Exception $e) {
            error_log('获取系统指标失败: ' . $e->getMessage());
        }
        
        try {
            // 获取最近日志
            $logsResponse = $this->apiClient->get('/logs');
            $data['recentLogs'] = $logsResponse['data'] ?? [];
        } catch (Exception $e) {
            error_log('获取最近日志失败: ' . $e->getMessage());
        }
        
        return $data;
    }
    
    /**
     * 获取实时数据 (AJAX)
     */
    public function getRealtimeData() {
        try {
            $data = $this->getDashboardData();
            echo json_encode([
                'success' => true,
                'data' => $data
            ]);
        } catch (Exception $e) {
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
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
    
    /**
     * 获取统计信息
     */
    private function getStatistics($data) {
        $stats = [
            'totalServers' => count($data['servers']),
            'activeServers' => 0,
            'totalClients' => count($data['clients']),
            'activeClients' => 0,
            'totalBgpAnnouncements' => count($data['bgpAnnouncements']),
            'systemStatus' => 'unknown'
        ];
        
        // 统计活跃服务器
        foreach ($data['servers'] as $server) {
            if (($server['status'] ?? '') === 'running') {
                $stats['activeServers']++;
            }
        }
        
        // 统计活跃客户端
        foreach ($data['clients'] as $client) {
            if (($client['status'] ?? '') === 'connected') {
                $stats['activeClients']++;
            }
        }
        
        // 系统状态
        if ($data['apiStatus']) {
            $stats['systemStatus'] = $data['apiStatus']['status'] ?? 'unknown';
        }
        
        return $stats;
    }
}
?>
