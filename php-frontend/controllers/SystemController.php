<?php
/**
 * 系统管理控制器
 */
class SystemController {
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
     * 系统信息
     */
    public function info() {
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('system.view');
            
            $systemData = $this->apiClient->get('/system/info');
            $system = $systemData['system'] ?? null;
            $error = $systemData['error'] ?? null;
            
        } catch (Exception $e) {
            $system = null;
            $error = $e->getMessage();
        }
        
        require __DIR__ . '/../views/system/info.php';
    }

    /**
     * 系统配置
     */
    public function config() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $data = [
                'app_name' => $_POST['app_name'] ?? '',
                'app_version' => $_POST['app_version'] ?? '',
                'debug_mode' => isset($_POST['debug_mode']),
                'log_level' => $_POST['log_level'] ?? 'INFO',
                'max_log_size' => (int)($_POST['max_log_size'] ?? 100),
                'backup_retention' => (int)($_POST['backup_retention'] ?? 30),
                'session_timeout' => (int)($_POST['session_timeout'] ?? 3600),
                'api_rate_limit' => (int)($_POST['api_rate_limit'] ?? 1000)
            ];

            $result = $this->apiClient->put('/system/config', $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                $_SESSION['success'] = '系统配置更新成功';
                header('Location: /system/config');
                exit();
            }
        }

        $configData = $this->apiClient->get('/system/config');
        $config = $configData['config'] ?? null;
        $error = $configData['error'] ?? null;
        
        require __DIR__ . '/../views/system/config.php';
    }

    /**
     * 服务管理
     */
    public function services() {
        $servicesData = $this->apiClient->get('/system/services');
        $services = $servicesData['services'] ?? [];
        $error = $servicesData['error'] ?? null;
        
        require __DIR__ . '/../views/system/services.php';
    }

    /**
     * 启动服务
     */
    public function startService($serviceName) {
        $result = $this->apiClient->post("/system/services/$serviceName/start");
        
        if (isset($result['error'])) {
            $_SESSION['error'] = $result['error'];
        } else {
            $_SESSION['success'] = "服务 $serviceName 启动成功";
        }
        
        header('Location: /system/services');
        exit();
    }

    /**
     * 停止服务
     */
    public function stopService($serviceName) {
        $result = $this->apiClient->post("/system/services/$serviceName/stop");
        
        if (isset($result['error'])) {
            $_SESSION['error'] = $result['error'];
        } else {
            $_SESSION['success'] = "服务 $serviceName 停止成功";
        }
        
        header('Location: /system/services');
        exit();
    }

    /**
     * 重启服务
     */
    public function restartService($serviceName) {
        $result = $this->apiClient->post("/system/services/$serviceName/restart");
        
        if (isset($result['error'])) {
            $_SESSION['error'] = $result['error'];
        } else {
            $_SESSION['success'] = "服务 $serviceName 重启成功";
        }
        
        header('Location: /system/services');
        exit();
    }

    /**
     * 备份管理
     */
    public function backup() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $backupType = $_POST['backup_type'] ?? 'full';
            $includeLogs = isset($_POST['include_logs']);
            $includeConfig = isset($_POST['include_config']);

            $data = [
                'backup_type' => $backupType,
                'include_logs' => $includeLogs,
                'include_config' => $includeConfig
            ];

            $result = $this->apiClient->post('/system/backup', $data);
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                $_SESSION['success'] = '备份创建成功';
                header('Location: /system/backup');
                exit();
            }
        }

        $backupsData = $this->apiClient->get('/system/backups');
        $backups = $backupsData['backups'] ?? [];
        $error = $backupsData['error'] ?? null;
        
        require __DIR__ . '/../views/system/backup.php';
    }

    /**
     * 恢复备份
     */
    public function restore($backupId) {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $confirm = $_POST['confirm'] ?? '';
            
            if ($confirm !== 'RESTORE') {
                $error = '请输入 "RESTORE" 确认恢复操作';
            } else {
                $result = $this->apiClient->post("/system/backups/$backupId/restore");
                
                if (isset($result['error'])) {
                    $error = $result['error'];
                } else {
                    $_SESSION['success'] = '备份恢复成功';
                    header('Location: /system/backup');
                    exit();
                }
            }
        }

        $backupData = $this->apiClient->get("/system/backups/$backupId");
        $backup = $backupData['backup'] ?? null;
        $error = $backupData['error'] ?? null;
        
        require __DIR__ . '/../views/system/restore.php';
    }

    /**
     * 删除备份
     */
    public function deleteBackup($backupId) {
        $result = $this->apiClient->delete("/system/backups/$backupId");
        
        if (isset($result['error'])) {
            $_SESSION['error'] = $result['error'];
        } else {
            $_SESSION['success'] = '备份删除成功';
        }
        
        header('Location: /system/backup');
        exit();
    }

    /**
     * 下载备份
     */
    public function downloadBackup($backupId) {
        $result = $this->apiClient->get("/system/backups/$backupId/download");
        
        if (isset($result['error'])) {
            $_SESSION['error'] = $result['error'];
            header('Location: /system/backup');
            exit();
        }

        // 设置下载头
        $filename = $result['filename'] ?? "backup_$backupId.tar.gz";
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . $filename . '"');
        header('Content-Length: ' . strlen($result['data']));
        
        echo base64_decode($result['data']);
        exit();
    }

    /**
     * 系统更新
     */
    public function update() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $updateType = $_POST['update_type'] ?? 'check';
            
            if ($updateType === 'check') {
                $result = $this->apiClient->get('/system/updates/check');
            } else {
                $result = $this->apiClient->post('/system/updates/install');
            }
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                if ($updateType === 'check') {
                    $updates = $result['updates'] ?? [];
                } else {
                    $_SESSION['success'] = '系统更新完成';
                    header('Location: /system/update');
                    exit();
                }
            }
        }

        $updateData = $this->apiClient->get('/system/updates/check');
        $updates = $updateData['updates'] ?? [];
        $error = $updateData['error'] ?? null;
        
        require __DIR__ . '/../views/system/update.php';
    }

    /**
     * 系统维护
     */
    public function maintenance() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $action = $_POST['action'] ?? '';
            
            switch ($action) {
                case 'clear_cache':
                    $result = $this->apiClient->post('/system/maintenance/clear-cache');
                    break;
                case 'optimize_database':
                    $result = $this->apiClient->post('/system/maintenance/optimize-database');
                    break;
                case 'clean_logs':
                    $result = $this->apiClient->post('/system/maintenance/clean-logs');
                    break;
                case 'reboot':
                    $result = $this->apiClient->post('/system/maintenance/reboot');
                    break;
                default:
                    $result = ['error' => '无效的操作'];
            }
            
            if (isset($result['error'])) {
                $error = $result['error'];
            } else {
                $_SESSION['success'] = '维护操作完成';
                header('Location: /system/maintenance');
                exit();
            }
        }
        
        require __DIR__ . '/../views/system/maintenance.php';
    }

    /**
     * 系统日志
     */
    public function logs() {
        $logsData = $this->apiClient->get('/system/logs');
        $logs = $logsData['logs'] ?? [];
        $error = $logsData['error'] ?? null;
        
        require __DIR__ . '/../views/system/logs.php';
    }

    /**
     * 性能监控
     */
    public function performance() {
        $performanceData = $this->apiClient->get('/system/performance');
        $performance = $performanceData['performance'] ?? null;
        $error = $performanceData['error'] ?? null;
        
        require __DIR__ . '/../views/system/performance.php';
    }
}
?>
