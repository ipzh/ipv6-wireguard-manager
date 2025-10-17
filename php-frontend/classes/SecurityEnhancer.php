<?php
/**
 * 安全增强类
 * 提供密码哈希、会话安全、敏感信息保护等功能
 */
class SecurityEnhancer {
    
    /**
     * 密码哈希配置
     */
    private static $passwordOptions = [
        'cost' => 12, // 计算成本
        'memory_cost' => 65536, // 内存成本 (64MB)
        'time_cost' => 4, // 时间成本
        'threads' => 3 // 线程数
    ];
    
    /**
     * 哈希密码
     */
    public static function hashPassword($password) {
        // 使用Argon2ID算法（PHP 7.2+）
        if (function_exists('password_hash') && defined('PASSWORD_ARGON2ID')) {
            return password_hash($password, PASSWORD_ARGON2ID, self::$passwordOptions);
        }
        
        // 回退到bcrypt
        return password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
    }
    
    /**
     * 验证密码
     */
    public static function verifyPassword($password, $hash) {
        return password_verify($password, $hash);
    }
    
    /**
     * 检查密码是否需要重新哈希
     */
    public static function needsRehash($hash) {
        if (function_exists('password_needs_rehash') && defined('PASSWORD_ARGON2ID')) {
            return password_needs_rehash($hash, PASSWORD_ARGON2ID, self::$passwordOptions);
        }
        
        return password_needs_rehash($hash, PASSWORD_BCRYPT, ['cost' => 12]);
    }
    
    /**
     * 生成安全的随机令牌
     */
    public static function generateSecureToken($length = 32) {
        if (function_exists('random_bytes')) {
            return bin2hex(random_bytes($length));
        }
        
        // 回退到openssl_random_pseudo_bytes
        if (function_exists('openssl_random_pseudo_bytes')) {
            return bin2hex(openssl_random_pseudo_bytes($length));
        }
        
        // 最后的回退方案（不够安全）
        return bin2hex(mcrypt_create_iv($length, MCRYPT_DEV_URANDOM));
    }
    
    /**
     * 生成CSRF令牌
     */
    public static function generateCSRFToken() {
        if (!isset($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = self::generateSecureToken(32);
        }
        
        return $_SESSION['csrf_token'];
    }
    
    /**
     * 验证CSRF令牌
     */
    public static function verifyCSRFToken($token) {
        if (!isset($_SESSION['csrf_token'])) {
            return false;
        }
        
        return hash_equals($_SESSION['csrf_token'], $token);
    }
    
    /**
     * 安全的会话启动
     */
    public static function startSecureSession() {
        // 设置安全的会话配置
        ini_set('session.cookie_httponly', 1);
        ini_set('session.cookie_secure', isset($_SERVER['HTTPS']));
        ini_set('session.use_strict_mode', 1);
        ini_set('session.cookie_samesite', 'Strict');
        
        // 设置会话名称
        session_name('IPV6_WG_SESSION');
        
        // 启动会话
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        
        // 会话固定攻击防护
        self::preventSessionFixation();
        
        // 会话劫持防护
        self::preventSessionHijacking();
    }
    
    /**
     * 防止会话固定攻击
     */
    private static function preventSessionFixation() {
        if (!isset($_SESSION['session_regenerated'])) {
            session_regenerate_id(true);
            $_SESSION['session_regenerated'] = true;
        }
    }
    
    /**
     * 防止会话劫持
     */
    private static function preventSessionHijacking() {
        // 检查用户代理
        if (!isset($_SESSION['user_agent'])) {
            $_SESSION['user_agent'] = $_SERVER['HTTP_USER_AGENT'] ?? '';
        } elseif ($_SESSION['user_agent'] !== ($_SERVER['HTTP_USER_AGENT'] ?? '')) {
            // 用户代理不匹配，可能是会话劫持
            self::destroySession();
            return;
        }
        
        // 检查IP地址（可选，可能影响移动用户）
        if (defined('SESSION_IP_CHECK') && SESSION_IP_CHECK) {
            if (!isset($_SESSION['user_ip'])) {
                $_SESSION['user_ip'] = self::getClientIP();
            } elseif ($_SESSION['user_ip'] !== self::getClientIP()) {
                // IP地址不匹配，可能是会话劫持
                self::destroySession();
                return;
            }
        }
        
        // 检查会话超时
        if (isset($_SESSION['last_activity'])) {
            $timeout = SESSION_LIFETIME ?? 3600; // 默认1小时
            if (time() - $_SESSION['last_activity'] > $timeout) {
                self::destroySession();
                return;
            }
        }
        
        $_SESSION['last_activity'] = time();
    }
    
    /**
     * 获取客户端真实IP
     */
    private static function getClientIP() {
        $ipKeys = ['HTTP_CF_CONNECTING_IP', 'HTTP_X_FORWARDED_FOR', 'HTTP_X_FORWARDED', 
                  'HTTP_X_CLUSTER_CLIENT_IP', 'HTTP_FORWARDED_FOR', 'HTTP_FORWARDED', 'REMOTE_ADDR'];
        
        foreach ($ipKeys as $key) {
            if (array_key_exists($key, $_SERVER) === true) {
                $ip = $_SERVER[$key];
                if (strpos($ip, ',') !== false) {
                    $ip = explode(',', $ip)[0];
                }
                $ip = trim($ip);
                if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
                    return $ip;
                }
            }
        }
        
        return $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
    }
    
    /**
     * 销毁会话
     */
    public static function destroySession() {
        // 清除会话数据
        $_SESSION = [];
        
        // 删除会话cookie
        if (ini_get("session.use_cookies")) {
            $params = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000,
                $params["path"], $params["domain"],
                $params["secure"], $params["httponly"]
            );
        }
        
        // 销毁会话
        session_destroy();
    }
    
    /**
     * 敏感信息脱敏
     */
    public static function maskSensitiveData($data, $type = 'default') {
        switch ($type) {
            case 'email':
                if (strpos($data, '@') !== false) {
                    list($user, $domain) = explode('@', $data);
                    return substr($user, 0, 2) . '***@' . $domain;
                }
                return $data;
                
            case 'phone':
                return substr($data, 0, 3) . '****' . substr($data, -4);
                
            case 'ip':
                if (filter_var($data, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
                    $parts = explode('.', $data);
                    return $parts[0] . '.' . $parts[1] . '.***.' . $parts[3];
                }
                return $data;
                
            case 'password':
                return '***';
                
            case 'token':
                return substr($data, 0, 8) . '...' . substr($data, -8);
                
            default:
                return str_repeat('*', strlen($data));
        }
    }
    
    /**
     * 安全的错误信息处理
     */
    public static function sanitizeErrorMessage($message, $debug = false) {
        if ($debug) {
            return $message;
        }
        
        // 移除敏感信息
        $sensitivePatterns = [
            '/password[^"]*"[^"]*"/i',
            '/token[^"]*"[^"]*"/i',
            '/key[^"]*"[^"]*"/i',
            '/secret[^"]*"[^"]*"/i',
            '/\/[a-zA-Z0-9\/\.\-_]+\.php/i',
            '/\/[a-zA-Z0-9\/\.\-_]+\.log/i'
        ];
        
        foreach ($sensitivePatterns as $pattern) {
            $message = preg_replace($pattern, '[REDACTED]', $message);
        }
        
        return $message;
    }
    
    /**
     * 强制HTTPS重定向
     */
    public static function forceHTTPS() {
        if (!isset($_SERVER['HTTPS']) || $_SERVER['HTTPS'] !== 'on') {
            $redirectURL = 'https://' . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'];
            header("Location: $redirectURL", true, 301);
            exit;
        }
    }
    
    /**
     * 设置安全头
     */
    public static function setSecurityHeaders() {
        // 防止XSS攻击
        header('X-Content-Type-Options: nosniff');
        header('X-Frame-Options: DENY');
        header('X-XSS-Protection: 1; mode=block');
        
        // 内容安全策略
        $csp = "default-src 'self'; " .
               "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net; " .
               "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; " .
               "img-src 'self' data: https:; " .
               "font-src 'self' https://cdn.jsdelivr.net; " .
               "connect-src 'self'; " .
               "frame-ancestors 'none';";
        
        header("Content-Security-Policy: $csp");
        
        // 引用者策略
        header('Referrer-Policy: strict-origin-when-cross-origin');
        
        // 权限策略
        header('Permissions-Policy: geolocation=(), microphone=(), camera=()');
    }
    
    /**
     * 验证文件上传
     */
    public static function validateFileUpload($file, $allowedTypes = [], $maxSize = 5242880) {
        $errors = [];
        
        // 检查上传错误
        if ($file['error'] !== UPLOAD_ERR_OK) {
            $errors[] = '文件上传失败';
            return ['valid' => false, 'errors' => $errors];
        }
        
        // 检查文件大小
        if ($file['size'] > $maxSize) {
            $errors[] = '文件大小超过限制';
        }
        
        // 检查文件类型
        if (!empty($allowedTypes)) {
            $fileType = mime_content_type($file['tmp_name']);
            if (!in_array($fileType, $allowedTypes)) {
                $errors[] = '文件类型不允许';
            }
        }
        
        // 检查文件扩展名
        $extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        $dangerousExtensions = ['php', 'phtml', 'php3', 'php4', 'php5', 'pl', 'py', 'jsp', 'asp', 'sh', 'cgi'];
        if (in_array($extension, $dangerousExtensions)) {
            $errors[] = '危险的文件类型';
        }
        
        // 检查文件内容
        $fileContent = file_get_contents($file['tmp_name'], false, null, 0, 1024);
        if (strpos($fileContent, '<?php') !== false || strpos($fileContent, '<script') !== false) {
            $errors[] = '文件包含危险内容';
        }
        
        return [
            'valid' => empty($errors),
            'errors' => $errors
        ];
    }
    
    /**
     * 生成安全的文件名
     */
    public static function generateSecureFileName($originalName) {
        $extension = pathinfo($originalName, PATHINFO_EXTENSION);
        $name = pathinfo($originalName, PATHINFO_FILENAME);
        
        // 清理文件名
        $name = preg_replace('/[^a-zA-Z0-9\-_]/', '', $name);
        $name = substr($name, 0, 50); // 限制长度
        
        // 生成唯一标识
        $uniqueId = self::generateSecureToken(16);
        
        return $name . '_' . $uniqueId . '.' . $extension;
    }
    
    /**
     * 记录安全事件
     */
    public static function logSecurityEvent($event, $details = []) {
        $logData = [
            'timestamp' => date('Y-m-d H:i:s'),
            'event' => $event,
            'ip' => self::getClientIP(),
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? '',
            'user_id' => $_SESSION['user']['id'] ?? null,
            'details' => $details
        ];
        
        $logFile = 'logs/security.log';
        $logDir = dirname($logFile);
        
        if (!is_dir($logDir)) {
            mkdir($logDir, 0755, true);
        }
        
        file_put_contents($logFile, json_encode($logData) . "\n", FILE_APPEND | LOCK_EX);
    }
}
?>
