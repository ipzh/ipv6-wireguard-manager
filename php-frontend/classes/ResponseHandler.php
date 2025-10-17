<?php
/**
 * 统一响应处理类
 * 提供标准化的API响应格式
 */
class ResponseHandler {
    
    /**
     * 成功响应
     */
    public static function success($data = null, $message = '操作成功', $code = 200) {
        $response = [
            'success' => true,
            'message' => $message,
            'code' => $code,
            'timestamp' => date('Y-m-d H:i:s'),
            'data' => $data
        ];
        
        self::sendResponse($response, $code);
    }
    
    /**
     * 错误响应
     */
    public static function error($message = '操作失败', $code = 400, $errors = null) {
        $response = [
            'success' => false,
            'message' => $message,
            'code' => $code,
            'timestamp' => date('Y-m-d H:i:s'),
            'errors' => $errors
        ];
        
        self::sendResponse($response, $code);
    }
    
    /**
     * 验证错误响应
     */
    public static function validationError($errors, $message = '验证失败') {
        self::error($message, 422, $errors);
    }
    
    /**
     * 未授权响应
     */
    public static function unauthorized($message = '未授权访问') {
        self::error($message, 401);
    }
    
    /**
     * 禁止访问响应
     */
    public static function forbidden($message = '权限不足') {
        self::error($message, 403);
    }
    
    /**
     * 未找到响应
     */
    public static function notFound($message = '资源未找到') {
        self::error($message, 404);
    }
    
    /**
     * 服务器错误响应
     */
    public static function serverError($message = '服务器内部错误') {
        self::error($message, 500);
    }
    
    /**
     * 分页响应
     */
    public static function paginated($data, $pagination, $message = '获取成功') {
        $response = [
            'success' => true,
            'message' => $message,
            'code' => 200,
            'timestamp' => date('Y-m-d H:i:s'),
            'data' => $data,
            'pagination' => $pagination
        ];
        
        self::sendResponse($response, 200);
    }
    
    /**
     * 发送响应
     */
    private static function sendResponse($response, $httpCode) {
        // 设置HTTP状态码
        http_response_code($httpCode);
        
        // 设置响应头
        header('Content-Type: application/json; charset=utf-8');
        header('Cache-Control: no-cache, must-revalidate');
        header('Expires: Mon, 26 Jul 1997 05:00:00 GMT');
        
        // 输出JSON响应
        echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        exit;
    }
    
    /**
     * 重定向响应
     */
    public static function redirect($url, $message = null) {
        if ($message) {
            $_SESSION['flash_message'] = $message;
        }
        
        header('Location: ' . $url);
        exit;
    }
    
    /**
     * 显示消息页面
     */
    public static function showMessage($title, $message, $type = 'info', $redirectUrl = null) {
        $pageTitle = $title;
        $showSidebar = isset($_SESSION['user']);
        
        include 'views/layout/header.php';
        
        echo '<div class="container mt-5">';
        echo '<div class="row justify-content-center">';
        echo '<div class="col-md-8">';
        echo '<div class="card shadow-lg border-0">';
        echo '<div class="card-body text-center p-5">';
        
        // 图标
        $iconClass = match($type) {
            'success' => 'bi-check-circle text-success',
            'error' => 'bi-exclamation-triangle text-danger',
            'warning' => 'bi-exclamation-triangle text-warning',
            'info' => 'bi-info-circle text-info',
            default => 'bi-info-circle text-info'
        };
        
        echo '<div class="mb-4">';
        echo '<i class="bi ' . $iconClass . '" style="font-size: 5rem;"></i>';
        echo '</div>';
        
        echo '<h1 class="display-4 mb-3">' . htmlspecialchars($title) . '</h1>';
        echo '<p class="lead text-muted mb-4">' . htmlspecialchars($message) . '</p>';
        
        if ($redirectUrl) {
            echo '<div class="d-grid gap-2 d-md-flex justify-content-md-center">';
            echo '<a href="' . htmlspecialchars($redirectUrl) . '" class="btn btn-primary btn-lg">';
            echo '<i class="bi bi-arrow-left me-2"></i>返回';
            echo '</a>';
            echo '</div>';
        }
        
        echo '</div>';
        echo '</div>';
        echo '</div>';
        echo '</div>';
        echo '</div>';
        
        include 'views/layout/footer.php';
        exit;
    }
    
    /**
     * 显示错误页面
     */
    public static function showError($title, $message, $details = null) {
        $_SESSION['error_title'] = $title;
        $_SESSION['error_message'] = $message;
        $_SESSION['error_data'] = $details;
        
        header('Location: /error');
        exit;
    }
    
    /**
     * 显示JSON错误响应
     */
    public static function jsonError($message, $code = 400, $errors = null) {
        $response = [
            'success' => false,
            'message' => $message,
            'code' => $code,
            'timestamp' => date('Y-m-d H:i:s'),
            'errors' => $errors
        ];
        
        http_response_code($code);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    /**
     * 显示JSON成功响应
     */
    public static function jsonSuccess($data = null, $message = '操作成功') {
        $response = [
            'success' => true,
            'message' => $message,
            'code' => 200,
            'timestamp' => date('Y-m-d H:i:s'),
            'data' => $data
        ];
        
        http_response_code(200);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    /**
     * 处理异常
     */
    public static function handleException($exception) {
        $message = $exception->getMessage();
        $code = $exception->getCode() ?: 500;
        
        // 记录错误日志
        ErrorHandler::logCustomError($message, [
            'file' => $exception->getFile(),
            'line' => $exception->getLine(),
            'trace' => $exception->getTraceAsString()
        ]);
        
        // 根据请求类型返回响应
        if (self::isAjaxRequest()) {
            self::jsonError($message, $code);
        } else {
            self::showError('系统错误', $message);
        }
    }
    
    /**
     * 检查是否为AJAX请求
     */
    private static function isAjaxRequest() {
        return !empty($_SERVER['HTTP_X_REQUESTED_WITH']) && 
               strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest';
    }
    
    /**
     * 获取分页信息
     */
    public static function getPagination($page, $pageSize, $total) {
        $totalPages = ceil($total / $pageSize);
        
        return [
            'current_page' => $page,
            'page_size' => $pageSize,
            'total_items' => $total,
            'total_pages' => $totalPages,
            'has_next' => $page < $totalPages,
            'has_prev' => $page > 1,
            'next_page' => $page < $totalPages ? $page + 1 : null,
            'prev_page' => $page > 1 ? $page - 1 : null
        ];
    }
    
    /**
     * 格式化文件大小
     */
    public static function formatFileSize($bytes) {
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);
        
        $bytes /= pow(1024, $pow);
        
        return round($bytes, 2) . ' ' . $units[$pow];
    }
    
    /**
     * 格式化时间
     */
    public static function formatTime($timestamp) {
        $time = time() - $timestamp;
        
        if ($time < 60) {
            return '刚刚';
        } elseif ($time < 3600) {
            return floor($time / 60) . '分钟前';
        } elseif ($time < 86400) {
            return floor($time / 3600) . '小时前';
        } elseif ($time < 2592000) {
            return floor($time / 86400) . '天前';
        } else {
            return date('Y-m-d H:i:s', $timestamp);
        }
    }
}
?>
