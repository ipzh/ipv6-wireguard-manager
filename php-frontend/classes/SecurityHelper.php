<?php
/**
 * 安全助手类
 * 实现更强的输入验证、密码策略、XSS防护、SQL注入防护
 */

class SecurityHelper {
    
    // 密码策略配置 - 支持环境变量
    const PASSWORD_MIN_LENGTH = 8;
    const PASSWORD_REQUIRE_UPPERCASE = true;
    const PASSWORD_REQUIRE_LOWERCASE = true;
    const PASSWORD_REQUIRE_DIGITS = true;
    const PASSWORD_REQUIRE_SPECIAL = true;
    const PASSWORD_MAX_AGE_DAYS = 90;
    
    // API安全配置 - 支持环境变量
    const API_RATE_LIMIT_PER_MINUTE = 100;
    const API_RATE_LIMIT_BURST = 200;
    const MAX_LOGIN_ATTEMPTS = 5;
    const LOCKOUT_DURATION_MINUTES = 15;
    
    // 会话配置 - 支持环境变量
    const SESSION_TIMEOUT_MINUTES = 30;
    
    /**
     * 获取配置值，支持环境变量
     */
    private static function getConfig($key, $default = null) {
        $env_key = strtoupper($key);
        return getenv($env_key) ?: $default;
    }
    
    /**
     * 获取密码策略配置
     */
    private static function getPasswordConfig() {
        return [
            'min_length' => (int)self::getConfig('PASSWORD_MIN_LENGTH', self::PASSWORD_MIN_LENGTH),
            'require_uppercase' => filter_var(self::getConfig('PASSWORD_REQUIRE_UPPERCASE', self::PASSWORD_REQUIRE_UPPERCASE), FILTER_VALIDATE_BOOLEAN),
            'require_lowercase' => filter_var(self::getConfig('PASSWORD_REQUIRE_LOWERCASE', self::PASSWORD_REQUIRE_LOWERCASE), FILTER_VALIDATE_BOOLEAN),
            'require_digits' => filter_var(self::getConfig('PASSWORD_REQUIRE_DIGITS', self::PASSWORD_REQUIRE_DIGITS), FILTER_VALIDATE_BOOLEAN),
            'require_special' => filter_var(self::getConfig('PASSWORD_REQUIRE_SPECIAL', self::PASSWORD_REQUIRE_SPECIAL), FILTER_VALIDATE_BOOLEAN),
            'max_age_days' => (int)self::getConfig('PASSWORD_MAX_AGE_DAYS', self::PASSWORD_MAX_AGE_DAYS)
        ];
    }
    
    /**
     * 获取安全配置
     */
    private static function getSecurityConfig() {
        return [
            'rate_limit_per_minute' => (int)self::getConfig('API_RATE_LIMIT_PER_MINUTE', self::API_RATE_LIMIT_PER_MINUTE),
            'rate_limit_burst' => (int)self::getConfig('API_RATE_LIMIT_BURST', self::API_RATE_LIMIT_BURST),
            'max_login_attempts' => (int)self::getConfig('MAX_LOGIN_ATTEMPTS', self::MAX_LOGIN_ATTEMPTS),
            'lockout_duration_minutes' => (int)self::getConfig('LOCKOUT_DURATION_MINUTES', self::LOCKOUT_DURATION_MINUTES),
            'session_timeout_minutes' => (int)self::getConfig('SESSION_TIMEOUT_MINUTES', self::SESSION_TIMEOUT_MINUTES)
        ];
    }
    
    // 危险字符模式
    private static $dangerousPatterns = [
        // XSS攻击模式
        '/<script[^>]*>.*?<\/script>/i',
        '/javascript:/i',
        '/vbscript:/i',
        '/onload\s*=/i',
        '/onerror\s*=/i',
        '/onclick\s*=/i',
        '/onmouseover\s*=/i',
        '/onfocus\s*=/i',
        '/onblur\s*=/i',
        '/onchange\s*=/i',
        '/onsubmit\s*=/i',
        '/onreset\s*=/i',
        '/onselect\s*=/i',
        '/onkeydown\s*=/i',
        '/onkeyup\s*=/i',
        '/onkeypress\s*=/i',
        '/onmousedown\s*=/i',
        '/onmouseup\s*=/i',
        '/onmousemove\s*=/i',
        '/onmouseout\s*=/i',
        '/onmouseenter\s*=/i',
        '/onmouseleave\s*=/i',
        '/oncontextmenu\s*=/i',
        '/ondblclick\s*=/i',
        '/onwheel\s*=/i',
        '/oninput\s*=/i',
        '/oninvalid\s*=/i',
        '/onreset\s*=/i',
        '/onsearch\s*=/i',
        '/onselectstart\s*=/i',
        '/ontoggle\s*=/i',
        '/onvolumechange\s*=/i',
        '/onwaiting\s*=/i',
        '/onwebkitanimationend\s*=/i',
        '/onwebkitanimationiteration\s*=/i',
        '/onwebkitanimationstart\s*=/i',
        '/onwebkittransitionend\s*=/i',
        '/onabort\s*=/i',
        '/oncanplay\s*=/i',
        '/oncanplaythrough\s*=/i',
        '/ondurationchange\s*=/i',
        '/onemptied\s*=/i',
        '/onended\s*=/i',
        '/onerror\s*=/i',
        '/onloadeddata\s*=/i',
        '/onloadedmetadata\s*=/i',
        '/onloadstart\s*=/i',
        '/onpause\s*=/i',
        '/onplay\s*=/i',
        '/onplaying\s*=/i',
        '/onprogress\s*=/i',
        '/onratechange\s*=/i',
        '/onseeked\s*=/i',
        '/onseeking\s*=/i',
        '/onstalled\s*=/i',
        '/onsuspend\s*=/i',
        '/ontimeupdate\s*=/i',
        '/onunload\s*=/i',
        '/onbeforeunload\s*=/i',
        '/onhashchange\s*=/i',
        '/onmessage\s*=/i',
        '/onoffline\s*=/i',
        '/ononline\s*=/i',
        '/onpagehide\s*=/i',
        '/onpageshow\s*=/i',
        '/onpopstate\s*=/i',
        '/onresize\s*=/i',
        '/onstorage\s*=/i',
        '/onunload\s*=/i',
    ];
    
    // SQL注入模式
    private static $sqlInjectionPatterns = [
        '/(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|EXECUTE|UNION|SCRIPT)\b)/i',
        '/(\b(OR|AND)\s+\d+\s*=\s*\d+)/i',
        '/(\b(OR|AND)\s+\'.*\'=\s*\'.*\')/i',
        '/(\b(OR|AND)\s+\".*\"=\s*\".*\")/i',
        '/(\b(OR|AND)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*=\s*[a-zA-Z_][a-zA-Z0-9_]*)/i',
        '/(\b(OR|AND)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*LIKE\s*\'.*\')/i',
        '/(\b(OR|AND)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*LIKE\s*\".*\")/i',
        '/(\b(OR|AND)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*IN\s*\(.*\))/i',
        '/(\b(OR|AND)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*BETWEEN\s+.*\s+AND\s+.*)/i',
        '/(\b(OR|AND)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*IS\s+NULL)/i',
        '/(\b(OR|AND)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*IS\s+NOT\s+NULL)/i',
        '/(\b(OR|AND)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*>\s*\d+)/i',
        '/(\b(OR|AND)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*<\s*\d+)/i',
        '/(\b(OR|AND)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*>=\s*\d+)/i',
        '/(\b(OR|AND)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*<=\s*\d+)/i',
        '/(\b(OR|AND)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*!=\s*\d+)/i',
        '/(\b(OR|AND)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*<>\s*\d+)/i',
    ];
    
    /**
     * 清理输入数据
     */
    public static function sanitizeInput($input) {
        if (is_array($input)) {
            return array_map([self::class, 'sanitizeInput'], $input);
        }
        
        if (!is_string($input)) {
            return $input;
        }
        
        // 移除前后空格
        $input = trim($input);
        
        // 检查XSS攻击
        foreach (self::$dangerousPatterns as $pattern) {
            if (preg_match($pattern, $input)) {
                error_log("Potential XSS attack detected: " . $input);
                throw new SecurityException("Invalid input detected");
            }
        }
        
        // 检查SQL注入
        foreach (self::$sqlInjectionPatterns as $pattern) {
            if (preg_match($pattern, $input)) {
                error_log("Potential SQL injection detected: " . $input);
                throw new SecurityException("Invalid input detected");
            }
        }
        
        // HTML转义
        $input = htmlspecialchars($input, ENT_QUOTES, 'UTF-8');
        
        return $input;
    }
    
    /**
     * 验证密码强度
     */
    public static function validatePassword($password) {
        $errors = [];
        $strength = 'weak';
        $config = self::getPasswordConfig();
        
        // 检查长度
        if (strlen($password) < $config['min_length']) {
            $errors[] = "密码长度至少需要" . $config['min_length'] . "个字符";
        }
        
        // 检查复杂度
        if ($config['require_uppercase'] && !preg_match('/[A-Z]/', $password)) {
            $errors[] = "密码必须包含大写字母";
        }
        
        if ($config['require_lowercase'] && !preg_match('/[a-z]/', $password)) {
            $errors[] = "密码必须包含小写字母";
        }
        
        if ($config['require_digits'] && !preg_match('/\d/', $password)) {
            $errors[] = "密码必须包含数字";
        }
        
        if ($config['require_special'] && !preg_match('/[@$!%*?&]/', $password)) {
            $errors[] = "密码必须包含特殊字符(@$!%*?&)";
        }
        
        // 计算密码强度
        if (empty($errors)) {
            $strength = self::calculatePasswordStrength($password);
        }
        
        return [
            'valid' => empty($errors),
            'errors' => $errors,
            'strength' => $strength
        ];
    }
    
    /**
     * 计算密码强度
     */
    private static function calculatePasswordStrength($password) {
        $score = 0;
        
        // 长度评分
        if (strlen($password) >= 12) {
            $score += 2;
        } elseif (strlen($password) >= 8) {
            $score += 1;
        }
        
        // 复杂度评分
        if (preg_match('/[A-Z]/', $password)) $score += 1;
        if (preg_match('/[a-z]/', $password)) $score += 1;
        if (preg_match('/\d/', $password)) $score += 1;
        if (preg_match('/[@$!%*?&]/', $password)) $score += 1;
        if (preg_match('/[^A-Za-z0-9@$!%*?&]/', $password)) $score += 1;
        
        // 返回强度等级
        if ($score >= 6) return 'very_strong';
        if ($score >= 4) return 'strong';
        if ($score >= 2) return 'medium';
        return 'weak';
    }
    
    /**
     * 验证邮箱格式
     */
    public static function validateEmail($email) {
        return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }
    
    /**
     * 验证IP地址格式
     */
    public static function validateIpAddress($ip) {
        return filter_var($ip, FILTER_VALIDATE_IP) !== false;
    }
    
    /**
     * 验证端口号
     */
    public static function validatePort($port) {
        return is_numeric($port) && $port >= 1 && $port <= 65535;
    }
    
    /**
     * 生成安全的随机令牌
     */
    public static function generateToken($length = 32) {
        return bin2hex(random_bytes($length));
    }
    
    /**
     * 生成CSRF令牌
     */
    public static function generateCsrfToken() {
        if (!isset($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = self::generateToken();
        }
        return $_SESSION['csrf_token'];
    }
    
    /**
     * 验证CSRF令牌
     */
    public static function validateCsrfToken($token) {
        return isset($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], $token);
    }
    
    /**
     * 哈希密码
     */
    public static function hashPassword($password) {
        return password_hash($password, PASSWORD_DEFAULT);
    }
    
    /**
     * 验证密码
     */
    public static function verifyPassword($password, $hash) {
        return password_verify($password, $hash);
    }
    
    /**
     * 检查速率限制
     */
    public static function checkRateLimit($identifier, $limit = null, $window = 60) {
        $config = self::getSecurityConfig();
        $limit = $limit ?: $config['rate_limit_per_minute'];
        $key="${API_KEY}" . md5($identifier);
        
        if (!isset($_SESSION[$key])) {
            $_SESSION[$key] = ['count' => 0, 'reset_time' => time() + $window];
        }
        
        $data = $_SESSION[$key];
        
        // 检查是否需要重置
        if (time() > $data['reset_time']) {
            $_SESSION[$key] = ['count' => 0, 'reset_time' => time() + $window];
            $data = $_SESSION[$key];
        }
        
        // 检查是否超过限制
        if ($data['count'] >= $limit) {
            return false;
        }
        
        // 增加计数
        $_SESSION[$key]['count']++;
        
        return true;
    }
    
    /**
     * 检查登录尝试限制
     */
    public static function checkLoginAttempts($identifier) {
        $config = self::getSecurityConfig();
        $key="${API_KEY}" . md5($identifier);
        
        if (!isset($_SESSION[$key])) {
            $_SESSION[$key] = ['count' => 0, 'lockout_until' => 0];
        }
        
        $data = $_SESSION[$key];
        
        // 检查是否在锁定期间
        if (time() < $data['lockout_until']) {
            return false;
        }
        
        // 检查是否超过最大尝试次数
        if ($data['count'] >= $config['max_login_attempts']) {
            $_SESSION[$key]['lockout_until'] = time() + ($config['lockout_duration_minutes'] * 60);
            return false;
        }
        
        return true;
    }
    
    /**
     * 记录登录尝试
     */
    public static function recordLoginAttempt($identifier, $success = false) {
        $key="${API_KEY}" . md5($identifier);
        
        if (!isset($_SESSION[$key])) {
            $_SESSION[$key] = ['count' => 0, 'lockout_until' => 0];
        }
        
        if ($success) {
            // 登录成功，重置计数
            $_SESSION[$key] = ['count' => 0, 'lockout_until' => 0];
        } else {
            // 登录失败，增加计数
            $_SESSION[$key]['count']++;
        }
    }
    
    /**
     * 获取客户端IP地址
     */
    public static function getClientIp() {
        $ipKeys = ['HTTP_X_FORWARDED_FOR', 'HTTP_X_REAL_IP', 'HTTP_CLIENT_IP', 'REMOTE_ADDR'];
        
        foreach ($ipKeys as $key) {
            if (!empty($_SERVER[$key])) {
                $ip = $_SERVER[$key];
                if (strpos($ip, ',') !== false) {
                    $ip = trim(explode(',', $ip)[0]);
                }
                if (self::validateIpAddress($ip)) {
                    return $ip;
                }
            }
        }
        
        return '0.0.0.0';
    }
    
    /**
     * 记录安全事件
     */
    public static function logSecurityEvent($event, $details = []) {
        $logData = [
            'timestamp' => date('Y-m-d H:i:s'),
            'event' => $event,
            'ip' => self::getClientIp(),
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? '',
            'details' => $details
        ];
        
        error_log("Security Event: " . json_encode($logData));
    }
    
    /**
     * 验证文件上传
     */
    public static function validateFileUpload($file, $allowedTypes = [], $maxSize = 10485760) {
        $errors = [];
        
        // 检查文件是否上传成功
        if ($file['error'] !== UPLOAD_ERR_OK) {
            $errors[] = "文件上传失败";
            return $errors;
        }
        
        // 检查文件大小
        if ($file['size'] > $maxSize) {
            $errors[] = "文件大小超过限制";
        }
        
        // 检查文件类型
        if (!empty($allowedTypes)) {
            $fileType = pathinfo($file['name'], PATHINFO_EXTENSION);
            if (!in_array(strtolower($fileType), $allowedTypes)) {
                $errors[] = "不允许的文件类型";
            }
        }
        
        // 检查文件内容
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mimeType = finfo_file($finfo, $file['tmp_name']);
        finfo_close($finfo);
        
        $allowedMimeTypes = [
            'text/plain',
            'application/octet-stream',
            'application/x-pem-file',
            'application/x-x509-ca-cert'
        ];
        
        if (!in_array($mimeType, $allowedMimeTypes)) {
            $errors[] = "不允许的文件内容类型";
        }
        
        return $errors;
    }
}

/**
 * 安全异常类
 */
class SecurityException extends Exception {
    public function __construct($message = "Security violation", $code = 0, Exception $previous = null) {
        parent::__construct($message, $code, $previous);
    }
}
?>
