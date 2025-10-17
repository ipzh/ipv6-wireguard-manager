<?php
/**
 * JWT认证错误处理器 - 与后端JWT认证系统完全兼容
 */
class ErrorHandlerJWT {
    private static $instance = null;
    private $logFile;
    private $debugMode;
    
    private function __construct() {
        $this->logFile = __DIR__ . '/../logs/error.log';
        $this->debugMode = defined('DEBUG') && DEBUG;
        
        // 确保日志目录存在
        $logDir = dirname($this->logFile);
        if (!is_dir($logDir)) {
            mkdir($logDir, 0755, true);
        }
        
        // 设置错误处理
        set_error_handler([$this, 'handleError']);
        set_exception_handler([$this, 'handleException']);
        register_shutdown_function([$this, 'handleShutdown']);
    }
    
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /**
     * 处理PHP错误
     */
    public function handleError($severity, $message, $file, $line) {
        if (!(error_reporting() & $severity)) {
            return false;
        }
        
        $errorTypes = [
            E_ERROR => 'Fatal Error',
            E_WARNING => 'Warning',
            E_PARSE => 'Parse Error',
            E_NOTICE => 'Notice',
            E_CORE_ERROR => 'Core Error',
            E_CORE_WARNING => 'Core Warning',
            E_COMPILE_ERROR => 'Compile Error',
            E_COMPILE_WARNING => 'Compile Warning',
            E_USER_ERROR => 'User Error',
            E_USER_WARNING => 'User Warning',
            E_USER_NOTICE => 'User Notice',
            E_STRICT => 'Strict Notice',
            E_RECOVERABLE_ERROR => 'Recoverable Error',
            E_DEPRECATED => 'Deprecated',
            E_USER_DEPRECATED => 'User Deprecated'
        ];
        
        $errorType = $errorTypes[$severity] ?? 'Unknown Error';
        
        $error = [
            'type' => $errorType,
            'severity' => $severity,
            'message' => $message,
            'file' => $file,
            'line' => $line,
            'timestamp' => date('Y-m-d H:i:s'),
            'request_uri' => $_SERVER['REQUEST_URI'] ?? '',
            'request_method' => $_SERVER['REQUEST_METHOD'] ?? '',
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? '',
            'ip_address' => $_SERVER['REMOTE_ADDR'] ?? ''
        ];
        
        $this->logError($error);
        
        // 如果是致命错误，显示错误页面
        if (in_array($severity, [E_ERROR, E_CORE_ERROR, E_COMPILE_ERROR, E_USER_ERROR])) {
            $this->displayError('系统错误', '发生了一个严重错误，请稍后重试。', 500);
        }
        
        return true;
    }
    
    /**
     * 处理未捕获的异常
     */
    public function handleException($exception) {
        $error = [
            'type' => 'Uncaught Exception',
            'message' => $exception->getMessage(),
            'file' => $exception->getFile(),
            'line' => $exception->getLine(),
            'trace' => $exception->getTraceAsString(),
            'timestamp' => date('Y-m-d H:i:s'),
            'request_uri' => $_SERVER['REQUEST_URI'] ?? '',
            'request_method' => $_SERVER['REQUEST_METHOD'] ?? '',
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? '',
            'ip_address' => $_SERVER['REMOTE_ADDR'] ?? ''
        ];
        
        $this->logError($error);
        
        // 根据异常类型显示不同的错误页面
        if ($exception instanceof AuthenticationException) {
            $this->displayError('认证失败', $exception->getMessage(), 401);
        } elseif ($exception instanceof AuthorizationException) {
            $this->displayError('权限不足', $exception->getMessage(), 403);
        } elseif ($exception instanceof ValidationException) {
            $this->displayError('数据验证失败', $exception->getMessage(), 400);
        } elseif ($exception instanceof ApiException) {
            $this->displayError('API错误', $exception->getMessage(), $exception->getCode());
        } else {
            $this->displayError('系统错误', '发生了一个未预期的错误，请稍后重试。', 500);
        }
    }
    
    /**
     * 处理脚本结束时的错误
     */
    public function handleShutdown() {
        $error = error_get_last();
        
        if ($error && in_array($error['type'], [E_ERROR, E_CORE_ERROR, E_COMPILE_ERROR, E_USER_ERROR])) {
            $errorData = [
                'type' => 'Fatal Error (Shutdown)',
                'message' => $error['message'],
                'file' => $error['file'],
                'line' => $error['line'],
                'timestamp' => date('Y-m-d H:i:s'),
                'request_uri' => $_SERVER['REQUEST_URI'] ?? '',
                'request_method' => $_SERVER['REQUEST_METHOD'] ?? '',
                'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? '',
                'ip_address' => $_SERVER['REMOTE_ADDR'] ?? ''
            ];
            
            $this->logError($errorData);
            $this->displayError('系统错误', '发生了一个严重错误，请稍后重试。', 500);
        }
    }
    
    /**
     * 记录错误到日志文件
     */
    private function logError($error) {
        $logEntry = json_encode($error, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT) . "\n" . str_repeat('-', 80) . "\n";
        
        // 确保日志目录存在
        $logDir = dirname($this->logFile);
        if (!is_dir($logDir)) {
            if (!mkdir($logDir, 0755, true)) {
                // 如果无法创建目录，使用系统临时目录
                $this->logFile = sys_get_temp_dir() . '/ipv6-wireguard-error.log';
            }
        }
        
        // 尝试写入日志文件
        if (!file_put_contents($this->logFile, $logEntry, FILE_APPEND | LOCK_EX)) {
            // 如果写入失败，尝试使用系统临时目录
            $this->logFile = sys_get_temp_dir() . '/ipv6-wireguard-error.log';
            file_put_contents($this->logFile, $logEntry, FILE_APPEND | LOCK_EX);
        }
    }
    
    /**
     * 显示错误页面
     */
    private function displayError($title, $message, $statusCode) {
        http_response_code($statusCode);
        
        // 如果是AJAX请求，返回JSON错误
        if (!empty($_SERVER['HTTP_X_REQUESTED_WITH']) && 
            strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest') {
            header('Content-Type: application/json');
            echo json_encode([
                'success' => false,
                'error' => $message,
                'code' => $statusCode,
                'title' => $title
            ]);
            exit;
        }
        
        // 显示HTML错误页面
        $this->renderErrorPage($title, $message, $statusCode);
    }
    
    /**
     * 渲染错误页面
     */
    private function renderErrorPage($title, $message, $statusCode) {
        $errorPages = [
            400 => '400.php',
            401 => '401.php',
            403 => '403.php',
            404 => '404.php',
            500 => '500.php'
        ];
        
        $errorPage = $errorPages[$statusCode] ?? '500.php';
        $errorPagePath = __DIR__ . '/../views/errors/' . $errorPage;
        
        if (file_exists($errorPagePath)) {
            include $errorPagePath;
        } else {
            // 默认错误页面
            $this->renderDefaultErrorPage($title, $message, $statusCode);
        }
        
        exit;
    }
    
    /**
     * 渲染默认错误页面
     */
    private function renderDefaultErrorPage($title, $message, $statusCode) {
        ?>
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title><?= htmlspecialchars($title) ?> - IPv6 WireGuard Manager</title>
            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
            <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.7.2/font/bootstrap-icons.css" rel="stylesheet">
            <style>
                body {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                .error-container {
                    background: rgba(255, 255, 255, 0.95);
                    backdrop-filter: blur(10px);
                    border-radius: 20px;
                    padding: 3rem;
                    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
                    text-align: center;
                    max-width: 500px;
                    width: 90%;
                }
                .error-icon {
                    font-size: 4rem;
                    color: #dc3545;
                    margin-bottom: 1rem;
                }
                .error-title {
                    color: #333;
                    margin-bottom: 1rem;
                }
                .error-message {
                    color: #666;
                    margin-bottom: 2rem;
                }
                .btn-home {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    border: none;
                    padding: 12px 30px;
                    border-radius: 25px;
                    color: white;
                    text-decoration: none;
                    transition: transform 0.3s ease;
                }
                .btn-home:hover {
                    transform: translateY(-2px);
                    color: white;
                }
            </style>
        </head>
        <body>
            <div class="error-container">
                <div class="error-icon">
                    <?php if ($statusCode === 401): ?>
                        <i class="bi bi-shield-exclamation"></i>
                    <?php elseif ($statusCode === 403): ?>
                        <i class="bi bi-lock"></i>
                    <?php elseif ($statusCode === 404): ?>
                        <i class="bi bi-search"></i>
                    <?php else: ?>
                        <i class="bi bi-exclamation-triangle"></i>
                    <?php endif; ?>
                </div>
                <h1 class="error-title"><?= htmlspecialchars($title) ?></h1>
                <p class="error-message"><?= htmlspecialchars($message) ?></p>
                <a href="/" class="btn btn-home">
                    <i class="bi bi-house"></i> 返回首页
                </a>
            </div>
        </body>
        </html>
        <?php
    }
    
    /**
     * 处理API错误响应
     */
    public function handleApiError($response, $endpoint) {
        $errorData = [
            'type' => 'API Error',
            'endpoint' => $endpoint,
            'response' => $response,
            'timestamp' => date('Y-m-d H:i:s'),
            'request_uri' => $_SERVER['REQUEST_URI'] ?? '',
            'request_method' => $_SERVER['REQUEST_METHOD'] ?? '',
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? '',
            'ip_address' => $_SERVER['REMOTE_ADDR'] ?? ''
        ];
        
        $this->logError($errorData);
        
        // 根据API错误类型处理
        if (isset($response['http_code'])) {
            $statusCode = $response['http_code'];
            
            switch ($statusCode) {
                case 401:
                    // 认证失败，重定向到登录页
                    if (!empty($_SERVER['HTTP_X_REQUESTED_WITH']) && 
                        strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest') {
                        header('Content-Type: application/json');
                        echo json_encode([
                            'success' => false,
                            'error' => '认证失败，请重新登录',
                            'code' => 401,
                            'redirect' => '/login'
                        ]);
                        exit;
                    } else {
                        header('Location: /login');
                        exit;
                    }
                    break;
                    
                case 403:
                    // 权限不足
                    $this->displayError('权限不足', '您没有权限访问此资源', 403);
                    break;
                    
                case 404:
                    // 资源不存在
                    $this->displayError('资源不存在', '请求的资源不存在', 404);
                    break;
                    
                case 422:
                    // 数据验证失败
                    $message = '数据验证失败';
                    if (isset($response['data']['detail'])) {
                        if (is_array($response['data']['detail'])) {
                            $message = implode(', ', $response['data']['detail']);
                        } else {
                            $message = $response['data']['detail'];
                        }
                    }
                    $this->displayError('数据验证失败', $message, 422);
                    break;
                    
                case 500:
                    // 服务器错误
                    $this->displayError('服务器错误', '服务器内部错误，请稍后重试', 500);
                    break;
                    
                default:
                    // 其他错误
                    $message = $response['error'] ?? '未知错误';
                    $this->displayError('请求失败', $message, $statusCode);
                    break;
            }
        }
    }
    
    /**
     * 记录自定义错误
     */
    public function logCustomError($type, $message, $context = []) {
        $error = [
            'type' => $type,
            'message' => $message,
            'context' => $context,
            'timestamp' => date('Y-m-d H:i:s'),
            'request_uri' => $_SERVER['REQUEST_URI'] ?? '',
            'request_method' => $_SERVER['REQUEST_METHOD'] ?? '',
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? '',
            'ip_address' => $_SERVER['REMOTE_ADDR'] ?? ''
        ];
        
        $this->logError($error);
    }
    
    /**
     * 获取错误日志
     */
    public function getErrorLogs($limit = 100) {
        if (!file_exists($this->logFile)) {
            return [];
        }
        
        $logs = [];
        $content = file_get_contents($this->logFile);
        $entries = explode(str_repeat('-', 80), $content);
        
        foreach (array_reverse($entries) as $entry) {
            if (empty(trim($entry))) continue;
            
            $log = json_decode(trim($entry), true);
            if ($log) {
                $logs[] = $log;
                if (count($logs) >= $limit) break;
            }
        }
        
        return $logs;
    }
    
    /**
     * 清除错误日志
     */
    public function clearErrorLogs() {
        if (file_exists($this->logFile)) {
            file_put_contents($this->logFile, '');
        }
    }
}

// 自定义异常类
class AuthenticationException extends Exception {
    public function __construct($message = "认证失败", $code = 401) {
        parent::__construct($message, $code);
    }
}

class AuthorizationException extends Exception {
    public function __construct($message = "权限不足", $code = 403) {
        parent::__construct($message, $code);
    }
}

class ValidationException extends Exception {
    public function __construct($message = "数据验证失败", $code = 400) {
        parent::__construct($message, $code);
    }
}

class ApiException extends Exception {
    public function __construct($message = "API错误", $code = 500) {
        parent::__construct($message, $code);
    }
}
?>
