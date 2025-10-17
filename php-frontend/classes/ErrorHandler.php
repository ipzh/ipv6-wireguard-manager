<?php
/**
 * 全局错误处理器
 */
class ErrorHandler {
    private static $logFile = 'logs/error.log';
    
    /**
     * 初始化错误处理
     */
    public static function init() {
        // 设置错误处理函数
        set_error_handler([self::class, 'handleError']);
        set_exception_handler([self::class, 'handleException']);
        register_shutdown_function([self::class, 'handleShutdown']);
        
        // 确保日志目录存在
        $logDir = dirname(self::$logFile);
        if (!is_dir($logDir)) {
            mkdir($logDir, 0755, true);
        }
    }
    
    /**
     * 处理PHP错误
     */
    public static function handleError($severity, $message, $file, $line) {
        if (!(error_reporting() & $severity)) {
            return false;
        }
        
        $errorType = self::getErrorType($severity);
        $errorData = [
            'type' => 'PHP Error',
            'severity' => $errorType,
            'message' => $message,
            'file' => $file,
            'line' => $line,
            'timestamp' => date('Y-m-d H:i:s'),
            'url' => $_SERVER['REQUEST_URI'] ?? '',
            'method' => $_SERVER['REQUEST_METHOD'] ?? '',
            'user' => $_SESSION['user']['username'] ?? '未登录',
            'ip' => $_SERVER['REMOTE_ADDR'] ?? '',
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? ''
        ];
        
        self::logError($errorData);
        
        // 如果是致命错误，显示错误页面
        if ($severity === E_ERROR || $severity === E_CORE_ERROR || $severity === E_COMPILE_ERROR) {
            self::showErrorPage('PHP错误', $message, $errorData);
        }
        
        return true;
    }
    
    /**
     * 处理未捕获的异常
     */
    public static function handleException($exception) {
        $errorData = [
            'type' => 'Exception',
            'severity' => 'Fatal',
            'message' => $exception->getMessage(),
            'file' => $exception->getFile(),
            'line' => $exception->getLine(),
            'trace' => $exception->getTraceAsString(),
            'timestamp' => date('Y-m-d H:i:s'),
            'url' => $_SERVER['REQUEST_URI'] ?? '',
            'method' => $_SERVER['REQUEST_METHOD'] ?? '',
            'user' => $_SESSION['user']['username'] ?? '未登录',
            'ip' => $_SERVER['REMOTE_ADDR'] ?? '',
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? ''
        ];
        
        self::logError($errorData);
        self::showErrorPage('系统异常', $exception->getMessage(), $errorData);
    }
    
    /**
     * 处理脚本结束时的错误
     */
    public static function handleShutdown() {
        $error = error_get_last();
        if ($error && in_array($error['type'], [E_ERROR, E_CORE_ERROR, E_COMPILE_ERROR, E_PARSE])) {
            $errorData = [
                'type' => 'Fatal Error',
                'severity' => 'Fatal',
                'message' => $error['message'],
                'file' => $error['file'],
                'line' => $error['line'],
                'timestamp' => date('Y-m-d H:i:s'),
                'url' => $_SERVER['REQUEST_URI'] ?? '',
                'method' => $_SERVER['REQUEST_METHOD'] ?? '',
                'user' => $_SESSION['user']['username'] ?? '未登录',
                'ip' => $_SERVER['REMOTE_ADDR'] ?? '',
                'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? ''
            ];
            
            self::logError($errorData);
            self::showErrorPage('致命错误', $error['message'], $errorData);
        }
    }
    
    /**
     * 记录错误到日志文件
     */
    public static function logError($errorData) {
        $logEntry = sprintf(
            "[%s] %s: %s in %s:%d\nURL: %s %s\nUser: %s\nIP: %s\n%s\n\n",
            $errorData['timestamp'],
            $errorData['type'],
            $errorData['message'],
            $errorData['file'],
            $errorData['line'],
            $errorData['method'],
            $errorData['url'],
            $errorData['user'],
            $errorData['ip'],
            isset($errorData['trace']) ? "Trace:\n" . $errorData['trace'] : ''
        );
        
        file_put_contents(self::$logFile, $logEntry, FILE_APPEND | LOCK_EX);
    }
    
    /**
     * 显示错误页面
     */
    public static function showErrorPage($title, $message, $errorData = null) {
        // 清除输出缓冲区
        if (ob_get_level()) {
            ob_clean();
        }
        
        // 设置错误信息到会话
        $_SESSION['error_title'] = $title;
        $_SESSION['error_message'] = $message;
        $_SESSION['error_data'] = $errorData;
        
        // 重定向到错误页面
        header('Location: /error');
        exit;
    }
    
    /**
     * 获取错误类型名称
     */
    private static function getErrorType($severity) {
        $types = [
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
        
        return $types[$severity] ?? 'Unknown Error';
    }
    
    /**
     * 记录自定义错误
     */
    public static function logCustomError($message, $context = []) {
        $errorData = [
            'type' => 'Custom Error',
            'severity' => 'Error',
            'message' => $message,
            'file' => $context['file'] ?? '',
            'line' => $context['line'] ?? 0,
            'timestamp' => date('Y-m-d H:i:s'),
            'url' => $_SERVER['REQUEST_URI'] ?? '',
            'method' => $_SERVER['REQUEST_METHOD'] ?? '',
            'user' => $_SESSION['user']['username'] ?? '未登录',
            'ip' => $_SERVER['REMOTE_ADDR'] ?? '',
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? '',
            'context' => $context
        ];
        
        self::logError($errorData);
    }
    
    /**
     * 获取错误日志
     */
    public static function getErrorLogs($limit = 100) {
        if (!file_exists(self::$logFile)) {
            return [];
        }
        
        $logs = [];
        $lines = file(self::$logFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        $lines = array_reverse($lines);
        
        $currentLog = [];
        foreach ($lines as $line) {
            if (preg_match('/^\[(.*?)\] (.*?): (.*?) in (.*?):(\d+)$/', $line, $matches)) {
                if (!empty($currentLog)) {
                    $logs[] = $currentLog;
                }
                
                $currentLog = [
                    'timestamp' => $matches[1],
                    'type' => $matches[2],
                    'message' => $matches[3],
                    'file' => $matches[4],
                    'line' => $matches[5],
                    'details' => []
                ];
            } elseif (!empty($currentLog) && !empty(trim($line))) {
                $currentLog['details'][] = $line;
            }
        }
        
        if (!empty($currentLog)) {
            $logs[] = $currentLog;
        }
        
        return array_slice($logs, 0, $limit);
    }
    
    /**
     * 清除错误日志
     */
    public static function clearErrorLog() {
        if (file_exists(self::$logFile)) {
            file_put_contents(self::$logFile, '');
        }
    }
}
?>
