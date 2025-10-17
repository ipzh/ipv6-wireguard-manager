<?php
/**
 * 日志管理控制器
 */
class LogsController {
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
     * 日志列表
     */
    public function index() {
        try {
            // 检查权限
            $this->permissionMiddleware->requirePermission('logs.view');
            
            $page = (int)($_GET['page'] ?? 1);
            $pageSize = (int)($_GET['page_size'] ?? 50);
            $level = $_GET['level'] ?? '';
            $source = $_GET['source'] ?? '';
            $startDate = $_GET['start_date'] ?? '';
            $endDate = $_GET['end_date'] ?? '';
            $search = $_GET['search'] ?? '';

            $params = [
                'page' => $page,
                'page_size' => $pageSize
            ];
            
            if ($level) $params['level'] = $level;
            if ($source) $params['source'] = $source;
            if ($startDate) $params['start_date'] = $startDate;
            if ($endDate) $params['end_date'] = $endDate;
            if ($search) $params['search'] = $search;

            $queryString = http_build_query($params);
            $logsData = $this->apiClient->get("/logs?$queryString");
            
            $logs = $logsData['logs'] ?? [];
            $total = $logsData['total'] ?? 0;
            $error = $logsData['error'] ?? null;
            
        } catch (Exception $e) {
            $logs = [];
            $total = 0;
            $error = $e->getMessage();
        }
        
        require __DIR__ . '/../views/logs/list.php';
    }

    /**
     * 日志搜索
     */
    public function search() {
        $query = $_GET['q'] ?? '';
        $level = $_GET['level'] ?? '';
        $source = $_GET['source'] ?? '';
        $startDate = $_GET['start_date'] ?? '';
        $endDate = $_GET['end_date'] ?? '';
        $page = (int)($_GET['page'] ?? 1);
        $pageSize = (int)($_GET['page_size'] ?? 50);

        $params = [
            'search' => $query,
            'page' => $page,
            'page_size' => $pageSize
        ];
        
        if ($level) $params['level'] = $level;
        if ($source) $params['source'] = $source;
        if ($startDate) $params['start_date'] = $startDate;
        if ($endDate) $params['end_date'] = $endDate;

        $queryString = http_build_query($params);
        $logsData = $this->apiClient->get("/logs?$queryString");
        
        $logs = $logsData['logs'] ?? [];
        $total = $logsData['total'] ?? 0;
        $error = $logsData['error'] ?? null;
        
        require __DIR__ . '/../views/logs/search.php';
    }

    /**
     * 日志详情
     */
    public function details($logId) {
        $logData = $this->apiClient->get("/logs/$logId");
        $log = $logData['log'] ?? null;
        $error = $logData['error'] ?? null;
        
        require __DIR__ . '/../views/logs/details.php';
    }

    /**
     * 导出日志
     */
    public function export() {
        $level = $_GET['level'] ?? '';
        $source = $_GET['source'] ?? '';
        $startDate = $_GET['start_date'] ?? '';
        $endDate = $_GET['end_date'] ?? '';
        $format = $_GET['format'] ?? 'json';

        $params = [
            'export' => 'true',
            'format' => $format
        ];
        
        if ($level) $params['level'] = $level;
        if ($source) $params['source'] = $source;
        if ($startDate) $params['start_date'] = $startDate;
        if ($endDate) $params['end_date'] = $endDate;

        $queryString = http_build_query($params);
        $exportData = $this->apiClient->get("/logs/export?$queryString");
        
        if (isset($exportData['error'])) {
            $_SESSION['error'] = $exportData['error'];
            header('Location: /logs');
            exit();
        }

        // 设置下载头
        $filename = 'logs_' . date('Y-m-d_H-i-s') . '.' . $format;
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . $filename . '"');
        
        if ($format === 'json') {
            header('Content-Type: application/json');
            echo json_encode($exportData['logs'] ?? [], JSON_PRETTY_PRINT);
        } else if ($format === 'csv') {
            header('Content-Type: text/csv');
            echo $this->arrayToCsv($exportData['logs'] ?? []);
        } else {
            header('Content-Type: text/plain');
            echo $this->arrayToText($exportData['logs'] ?? []);
        }
        exit();
    }

    /**
     * 清理日志
     */
    public function cleanup() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $days = (int)($_POST['days'] ?? 30);
            $level = $_POST['level'] ?? '';
            $source = $_POST['source'] ?? '';

            $data = ['days' => $days];
            if ($level) $data['level'] = $level;
            if ($source) $data['source'] = $source;

            $result = $this->apiClient->post('/logs/cleanup', $data);
            
            if (isset($result['error'])) {
                $_SESSION['error'] = $result['error'];
            } else {
                $_SESSION['success'] = '日志清理完成';
            }
            
            header('Location: /logs');
            exit();
        }
        
        require __DIR__ . '/../views/logs/cleanup.php';
    }

    /**
     * 实时日志流
     */
    public function stream() {
        require __DIR__ . '/../views/logs/stream.php';
    }

    /**
     * 获取日志统计
     */
    public function statistics() {
        $statsData = $this->apiClient->get('/logs/statistics');
        $stats = $statsData['statistics'] ?? null;
        $error = $statsData['error'] ?? null;
        
        require __DIR__ . '/../views/logs/statistics.php';
    }

    /**
     * 将数组转换为CSV格式
     */
    private function arrayToCsv($data) {
        if (empty($data)) return '';
        
        $output = fopen('php://temp', 'r+');
        
        // 写入标题行
        $headers = ['ID', '时间戳', '级别', '消息', '来源', '详情'];
        fputcsv($output, $headers);
        
        // 写入数据行
        foreach ($data as $row) {
            fputcsv($output, [
                $row['id'] ?? '',
                $row['timestamp'] ?? '',
                $row['level'] ?? '',
                $row['message'] ?? '',
                $row['source'] ?? '',
                json_encode($row['details'] ?? [])
            ]);
        }
        
        rewind($output);
        $csv = stream_get_contents($output);
        fclose($output);
        
        return $csv;
    }

    /**
     * 将数组转换为文本格式
     */
    private function arrayToText($data) {
        if (empty($data)) return '';
        
        $output = '';
        foreach ($data as $row) {
            $output .= sprintf(
                "[%s] %s %s: %s\n",
                $row['timestamp'] ?? '',
                $row['level'] ?? '',
                $row['source'] ?? '',
                $row['message'] ?? ''
            );
            
            if (!empty($row['details'])) {
                $output .= "详情: " . json_encode($row['details'], JSON_PRETTY_PRINT) . "\n";
            }
            $output .= "\n";
        }
        
        return $output;
    }
}
?>
