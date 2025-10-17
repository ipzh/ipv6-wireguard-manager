<?php
/**
 * 输入验证类
 * 提供全面的输入验证和过滤功能
 */
class InputValidator {
    
    /**
     * 验证和清理输入数据
     */
    public static function validate($data, $rules) {
        $errors = [];
        $cleaned = [];
        
        foreach ($rules as $field => $rule) {
            $value = $data[$field] ?? null;
            
            // 基本清理
            if (is_string($value)) {
                $value = trim($value);
            }
            
            // 应用验证规则
            $result = self::applyRules($value, $rule, $field);
            
            if ($result['valid']) {
                $cleaned[$field] = $result['value'];
            } else {
                $errors[$field] = $result['error'];
            }
        }
        
        return [
            'valid' => empty($errors),
            'data' => $cleaned,
            'errors' => $errors
        ];
    }
    
    /**
     * 应用验证规则
     */
    private static function applyRules($value, $rules, $field) {
        $rules = is_string($rules) ? explode('|', $rules) : $rules;
        
        foreach ($rules as $rule) {
            $result = self::applyRule($value, $rule, $field);
            if (!$result['valid']) {
                return $result;
            }
            $value = $result['value'];
        }
        
        return ['valid' => true, 'value' => $value];
    }
    
    /**
     * 应用单个验证规则
     */
    private static function applyRule($value, $rule, $field) {
        $params = explode(':', $rule);
        $ruleName = $params[0];
        $ruleValue = $params[1] ?? null;
        
        switch ($ruleName) {
            case 'required':
                if (empty($value) && $value !== '0') {
                    return ['valid' => false, 'error' => "字段 {$field} 是必需的"];
                }
                break;
                
            case 'string':
                if (!is_string($value)) {
                    return ['valid' => false, 'error' => "字段 {$field} 必须是字符串"];
                }
                break;
                
            case 'integer':
                if (!is_numeric($value) || (int)$value != $value) {
                    return ['valid' => false, 'error' => "字段 {$field} 必须是整数"];
                }
                $value = (int)$value;
                break;
                
            case 'numeric':
                if (!is_numeric($value)) {
                    return ['valid' => false, 'error' => "字段 {$field} 必须是数字"];
                }
                $value = (float)$value;
                break;
                
            case 'email':
                if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
                    return ['valid' => false, 'error' => "字段 {$field} 必须是有效的邮箱地址"];
                }
                break;
                
            case 'url':
                if (!filter_var($value, FILTER_VALIDATE_URL)) {
                    return ['valid' => false, 'error' => "字段 {$field} 必须是有效的URL"];
                }
                break;
                
            case 'ip':
                if (!filter_var($value, FILTER_VALIDATE_IP)) {
                    return ['valid' => false, 'error' => "字段 {$field} 必须是有效的IP地址"];
                }
                break;
                
            case 'ipv6':
                if (!filter_var($value, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
                    return ['valid' => false, 'error' => "字段 {$field} 必须是有效的IPv6地址"];
                }
                break;
                
            case 'min':
                if (strlen($value) < $ruleValue) {
                    return ['valid' => false, 'error' => "字段 {$field} 长度不能少于 {$ruleValue} 个字符"];
                }
                break;
                
            case 'max':
                if (strlen($value) > $ruleValue) {
                    return ['valid' => false, 'error' => "字段 {$field} 长度不能超过 {$ruleValue} 个字符"];
                }
                break;
                
            case 'min_value':
                if ($value < $ruleValue) {
                    return ['valid' => false, 'error' => "字段 {$field} 值不能小于 {$ruleValue}"];
                }
                break;
                
            case 'max_value':
                if ($value > $ruleValue) {
                    return ['valid' => false, 'error' => "字段 {$field} 值不能大于 {$ruleValue}"];
                }
                break;
                
            case 'in':
                $allowedValues = explode(',', $ruleValue);
                if (!in_array($value, $allowedValues)) {
                    return ['valid' => false, 'error' => "字段 {$field} 必须是以下值之一: " . implode(', ', $allowedValues)];
                }
                break;
                
            case 'regex':
                if (!preg_match($ruleValue, $value)) {
                    return ['valid' => false, 'error' => "字段 {$field} 格式不正确"];
                }
                break;
                
            case 'alpha':
                if (!ctype_alpha($value)) {
                    return ['valid' => false, 'error' => "字段 {$field} 只能包含字母"];
                }
                break;
                
            case 'alpha_num':
                if (!ctype_alnum($value)) {
                    return ['valid' => false, 'error' => "字段 {$field} 只能包含字母和数字"];
                }
                break;
                
            case 'sanitize':
                $value = self::sanitize($value, $ruleValue);
                break;
                
            case 'xss':
                $value = self::preventXSS($value);
                break;
                
            case 'sql':
                $value = self::preventSQLInjection($value);
                break;
        }
        
        return ['valid' => true, 'value' => $value];
    }
    
    /**
     * 防止XSS攻击
     */
    public static function preventXSS($input) {
        if (is_string($input)) {
            return htmlspecialchars($input, ENT_QUOTES | ENT_HTML5, 'UTF-8');
        }
        return $input;
    }
    
    /**
     * 防止SQL注入
     */
    public static function preventSQLInjection($input) {
        if (is_string($input)) {
            // 移除危险字符
            $dangerous = ['--', '/*', '*/', 'xp_', 'sp_', 'exec', 'execute', 'select', 'insert', 'update', 'delete', 'drop', 'create', 'alter'];
            foreach ($dangerous as $pattern) {
                $input = str_ireplace($pattern, '', $input);
            }
        }
        return $input;
    }
    
    /**
     * 数据清理
     */
    public static function sanitize($input, $type = 'string') {
        switch ($type) {
            case 'string':
                return filter_var($input, FILTER_SANITIZE_STRING, FILTER_FLAG_NO_ENCODE_QUOTES);
            case 'email':
                return filter_var($input, FILTER_SANITIZE_EMAIL);
            case 'url':
                return filter_var($input, FILTER_SANITIZE_URL);
            case 'int':
                return filter_var($input, FILTER_SANITIZE_NUMBER_INT);
            case 'float':
                return filter_var($input, FILTER_SANITIZE_NUMBER_FLOAT, FILTER_FLAG_ALLOW_FRACTION);
            case 'html':
                return strip_tags($input);
            default:
                return $input;
        }
    }
    
    /**
     * 验证CSRF令牌
     */
    public static function validateCSRF($token) {
        if (!isset($_SESSION['csrf_token'])) {
            return false;
        }
        
        return hash_equals($_SESSION['csrf_token'], $token);
    }
    
    /**
     * 生成CSRF令牌
     */
    public static function generateCSRF() {
        if (!isset($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['csrf_token'];
    }
    
    /**
     * 验证文件上传
     */
    public static function validateFileUpload($file, $allowedTypes = [], $maxSize = 5242880) { // 5MB
        $errors = [];
        
        if ($file['error'] !== UPLOAD_ERR_OK) {
            $errors[] = '文件上传失败';
            return ['valid' => false, 'errors' => $errors];
        }
        
        if ($file['size'] > $maxSize) {
            $errors[] = '文件大小超过限制';
        }
        
        if (!empty($allowedTypes)) {
            $fileType = mime_content_type($file['tmp_name']);
            if (!in_array($fileType, $allowedTypes)) {
                $errors[] = '文件类型不允许';
            }
        }
        
        return [
            'valid' => empty($errors),
            'errors' => $errors
        ];
    }
    
    /**
     * 验证密码强度
     */
    public static function validatePassword($password) {
        $errors = [];
        
        if (strlen($password) < 8) {
            $errors[] = '密码长度至少8个字符';
        }
        
        if (!preg_match('/[A-Z]/', $password)) {
            $errors[] = '密码必须包含至少一个大写字母';
        }
        
        if (!preg_match('/[a-z]/', $password)) {
            $errors[] = '密码必须包含至少一个小写字母';
        }
        
        if (!preg_match('/[0-9]/', $password)) {
            $errors[] = '密码必须包含至少一个数字';
        }
        
        if (!preg_match('/[^A-Za-z0-9]/', $password)) {
            $errors[] = '密码必须包含至少一个特殊字符';
        }
        
        return [
            'valid' => empty($errors),
            'errors' => $errors
        ];
    }
    
    /**
     * 验证IPv6地址
     */
    public static function validateIPv6($ip) {
        if (!filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
            return false;
        }
        
        // 检查是否为有效的IPv6地址格式
        return preg_match('/^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$/', $ip) ||
               preg_match('/^::1$/', $ip) ||
               preg_match('/^::$/', $ip);
    }
    
    /**
     * 验证CIDR格式
     */
    public static function validateCIDR($cidr) {
        if (!preg_match('/^([0-9]{1,3}\.){3}[0-9]{1,3}\/[0-9]{1,2}$/', $cidr) &&
            !preg_match('/^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\/[0-9]{1,3}$/', $cidr)) {
            return false;
        }
        
        list($ip, $prefix) = explode('/', $cidr);
        
        if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
            return $prefix >= 0 && $prefix <= 32;
        } elseif (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
            return $prefix >= 0 && $prefix <= 128;
        }
        
        return false;
    }
}
?>
