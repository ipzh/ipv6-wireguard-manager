<?php
/**
 * 仪表板控制器 - 使用统一API路径构建器
 */
require_once __DIR__ . '/../includes/ApiPathBuilder/index.php';

class DashboardController {
    private $auth;
    private $apiClient;
    private $permissionMiddleware;
    private $apiPathBuilder;
    
    public function __construct() {
        $this->auth = new AuthJWT();
        $this->apiClient = new ApiClientJWT();
        $this->permissionMiddleware = new PermissionMiddleware();
        
        // 获取API路径构建器实例
        $this->apiPathBuilder = get_default_api_path_builder();
        
        // 要求用户登录
        $this->permissionMiddleware->requireLogin();
    }
    
    /**
     * 显示仪表板
     */
    public function index() {
        // 检查用户是否已登录
        if (!$this->auth->isLoggedIn()) {
            // 如果未登录，显示登录提示
            $this->showLoginPrompt();
            return;
        }
        
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
            // 获取WireGuard服务器 - 使用路径构建器
            $serversUrl = $this->apiPathBuilder->buildUrl('wireguard.servers');
            $serversResponse = $this->apiClient->request('GET', $serversUrl);
            $data['servers'] = $serversResponse['data'] ?? [];
        } catch (Exception $e) {
            error_log('获取服务器列表失败: ' . $e->getMessage());
        }
        
        try {
            // 获取WireGuard客户端 - 使用路径构建器
            $clientsUrl = $this->apiPathBuilder->buildUrl('wireguard.clients');
            $clientsResponse = $this->apiClient->request('GET', $clientsUrl);
            $data['clients'] = $clientsResponse['data'] ?? [];
        } catch (Exception $e) {
            error_log('获取客户端列表失败: ' . $e->getMessage());
        }
        
        try {
            // 获取BGP宣告 - 使用路径构建器
            $bgpUrl = $this->apiPathBuilder->buildUrl('bgp.routes');
            $bgpResponse = $this->apiClient->request('GET', $bgpUrl);
            $data['bgpAnnouncements'] = $bgpResponse['data'] ?? [];
        } catch (Exception $e) {
            error_log('获取BGP宣告失败: ' . $e->getMessage());
        }
        
        try {
            // 获取系统指标 - 使用路径构建器
            $metricsUrl = $this->apiPathBuilder->buildUrl('monitoring.metrics.system');
            $metricsResponse = $this->apiClient->request('GET', $metricsUrl);
            $data['systemMetrics'] = $metricsResponse['data'] ?? [];
        } catch (Exception $e) {
            error_log('获取系统指标失败: ' . $e->getMessage());
        }
        
        try {
            // 获取最近日志 - 使用路径构建器
            $logsUrl = $this->apiPathBuilder->buildUrl('logs');
            $logsResponse = $this->apiClient->request('GET', $logsUrl);
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
            header('Content-Type: application/json');
            echo json_encode([
                'success' => true,
                'data' => $data
            ]);
        } catch (Exception $e) {
            header('Content-Type: application/json');
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
    }
    
    /**
     * 显示登录提示
     */
    private function showLoginPrompt() {
        $pageTitle = '需要登录';
        $showSidebar = false;
        
        include 'views/layout/header.php';
        echo '<div class="container mt-5">
            <div class="row justify-content-center">
                <div class="col-md-6">
                    <div class="card shadow">
                        <div class="card-body text-center">
                            <div class="mb-4">
                                <i class="bi bi-shield-lock text-primary" style="font-size: 4rem;"></i>
                            </div>
                            <h5 class="card-title">需要登录</h5>
                            <p class="card-text">请先登录以访问IPv6 WireGuard管理控制台。</p>
                            <div class="d-grid gap-2">
                                <a href="/login" class="btn btn-primary">
                                    <i class="bi bi-box-arrow-in-right me-2"></i>前往登录
                                </a>
                                <small class="text-muted">默认账户: admin / admin123</small>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>';
        include 'views/layout/footer.php';
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
        
        // 确定系统状态
        if ($stats['activeServers'] > 0 && $stats['activeClients'] > 0) {
            $stats['systemStatus'] = 'healthy';
        } elseif ($stats['activeServers'] > 0) {
            $stats['systemStatus'] = 'warning';
        } else {
            $stats['systemStatus'] = 'critical';
        }
        
        return $stats;
    }
    
    /**
     * 获取API路径构建器实例
     */
    public function getApiPathBuilder() {
        return $this->apiPathBuilder;
    }
    }
    ?>
