<?php
/**
 * 网络管理控制器
 */
class NetworkController {
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
     * 网络接口管理
     */
    public function interfaces() {
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('system.view');
            
            $interfacesData = $this->apiClient->get('/network/interfaces');
            $interfaces = $interfacesData['interfaces'] ?? [];
            $error = $interfacesData['error'] ?? null;
            
        } catch (Exception $e) {
            $interfaces = [];
            $error = $e->getMessage();
        }
        
        require __DIR__ . '/../views/network/interfaces.php';
    }

    /**
     * 网络状态
     */
    public function status() {
        $statusData = $this->apiClient->get('/network/status');
        $status = $statusData['status'] ?? null;
        $error = $statusData['error'] ?? null;
        
        require __DIR__ . '/../views/network/status.php';
    }

    /**
     * 路由表
     */
    public function routes() {
        $routesData = $this->apiClient->get('/network/routes');
        $routes = $routesData['routes'] ?? [];
        $error = $routesData['error'] ?? null;
        
        require __DIR__ . '/../views/network/routes.php';
    }

    /**
     * 网络诊断
     */
    public function diagnostics() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $action = $_POST['action'] ?? '';
            $target = $_POST['target'] ?? '';
            
            $data = [
                'action' => $action,
                'target' => $target
            ];

            $result = $this->apiClient->post('/network/diagnostics', $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                $diagnosticResult = $result['result'] ?? null;
            }
        }
        
        require __DIR__ . '/../views/network/diagnostics.php';
    }

    /**
     * 网络配置
     */
    public function config() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $interface = $_POST['interface'] ?? '';
            $action = $_POST['action'] ?? '';
            
            $data = [
                'interface' => $interface,
                'action' => $action
            ];

            if ($action === 'configure') {
                $data['ip_address'] = $_POST['ip_address'] ?? '';
                $data['netmask'] = $_POST['netmask'] ?? '';
                $data['gateway'] = $_POST['gateway'] ?? '';
                $data['dns_servers'] = $_POST['dns_servers'] ?? '';
            }

            $result = $this->apiClient->post('/network/config', $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                $_SESSION['success'] = '网络配置更新成功';
                header('Location: /network/config');
                exit();
            }
        }

        $configData = $this->apiClient->get('/network/config');
        $config = $configData['config'] ?? null;
        $error = $configData['error'] ?? null;
        
        require __DIR__ . '/../views/network/config.php';
    }

    /**
     * 防火墙管理
     */
    public function firewall() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $action = $_POST['action'] ?? '';
            
            switch ($action) {
                case 'add_rule':
                    $data = [
                        'action' => 'add_rule',
                        'rule' => [
                            'direction' => $_POST['direction'] ?? '',
                            'protocol' => $_POST['protocol'] ?? '',
                            'port' => $_POST['port'] ?? '',
                            'source' => $_POST['source'] ?? '',
                            'destination' => $_POST['destination'] ?? '',
                            'action' => $_POST['rule_action'] ?? ''
                        ]
                    ];
                    break;
                case 'delete_rule':
                    $data = [
                        'action' => 'delete_rule',
                        'rule_id' => $_POST['rule_id'] ?? ''
                    ];
                    break;
                case 'enable':
                case 'disable':
                    $data = ['action' => $action];
                    break;
                default:
                    $data = ['action' => $action];
            }

            $result = $this->apiClient->post('/network/firewall', $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                $_SESSION['success'] = '防火墙操作完成';
                header('Location: /network/firewall');
                exit();
            }
        }

        $firewallData = $this->apiClient->get('/network/firewall');
        $firewall = $firewallData['firewall'] ?? null;
        $error = $firewallData['error'] ?? null;
        
        require __DIR__ . '/../views/network/firewall.php';
    }

    /**
     * 端口扫描
     */
    public function portscan() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $target = $_POST['target'] ?? '';
            $ports = $_POST['ports'] ?? '';
            $scanType = $_POST['scan_type'] ?? 'tcp';
            
            $data = [
                'target' => $target,
                'ports' => $ports,
                'scan_type' => $scanType
            ];

            $result = $this->apiClient->post('/network/portscan', $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                $scanResult = $result['result'] ?? null;
            }
        }
        
        require __DIR__ . '/../views/network/portscan.php';
    }

    /**
     * 网络流量监控
     */
    public function traffic() {
        $trafficData = $this->apiClient->get('/network/traffic');
        $traffic = $trafficData['traffic'] ?? null;
        $error = $trafficData['error'] ?? null;
        
        require __DIR__ . '/../views/network/traffic.php';
    }

    /**
     * DNS管理
     */
    public function dns() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $action = $_POST['action'] ?? '';
            
            switch ($action) {
                case 'add_record':
                    $data = [
                        'action' => 'add_record',
                        'record' => [
                            'name' => $_POST['name'] ?? '',
                            'type' => $_POST['type'] ?? '',
                            'value' => $_POST['value'] ?? '',
                            'ttl' => (int)($_POST['ttl'] ?? 3600)
                        ]
                    ];
                    break;
                case 'delete_record':
                    $data = [
                        'action' => 'delete_record',
                        'record_id' => $_POST['record_id'] ?? ''
                    ];
                    break;
                case 'flush_cache':
                    $data = ['action' => 'flush_cache'];
                    break;
                default:
                    $data = ['action' => $action];
            }

            $result = $this->apiClient->post('/network/dns', $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                $_SESSION['success'] = 'DNS操作完成';
                header('Location: /network/dns');
                exit();
            }
        }

        $dnsData = $this->apiClient->get('/network/dns');
        $dns = $dnsData['dns'] ?? null;
        $error = $dnsData['error'] ?? null;
        
        require __DIR__ . '/../views/network/dns.php';
    }

    /**
     * 网络拓扑
     */
    public function topology() {
        $topologyData = $this->apiClient->get('/network/topology');
        $topology = $topologyData['topology'] ?? null;
        $error = $topologyData['error'] ?? null;
        
        require __DIR__ . '/../views/network/topology.php';
    }
}
?>
