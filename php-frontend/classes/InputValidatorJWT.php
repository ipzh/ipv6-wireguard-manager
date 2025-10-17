<?php
/**
 * JWT认证输入验证器 - 与后端验证规则完全兼容
 */
class InputValidatorJWT {
    
    /**
     * 验证规则定义
     */
    private static $rules = [
        'username' => [
            'required' => true,
            'min_length' => 3,
            'max_length' => 50,
            'pattern' => '/^[a-zA-Z0-9_]+$/',
            'message' => '用户名只能包含字母、数字和下划线，长度3-50位'
        ],
        'email' => [
            'required' => true,
            'type' => 'email',
            'max_length' => 255,
            'message' => '请输入有效的邮箱地址'
        ],
        'password' => [
            'required' => true,
            'min_length' => 8,
            'max_length' => 128,
            'pattern' => '/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/',
            'message' => '密码必须包含至少8位，包括大写字母、小写字母、数字和特殊字符'
        ],
        'full_name' => [
            'required' => false,
            'max_length' => 100,
            'pattern' => '/^[\p{L}\s]+$/u',
            'message' => '姓名只能包含字母和空格'
        ],
        'phone' => [
            'required' => false,
            'pattern' => '/^[\+]?[1-9][\d]{0,15}$/',
            'message' => '请输入有效的手机号码'
        ],
        'server_name' => [
            'required' => true,
            'min_length' => 3,
            'max_length' => 100,
            'pattern' => '/^[a-zA-Z0-9_-]+$/',
            'message' => '服务器名称只能包含字母、数字、下划线和连字符，长度3-100位'
        ],
        'server_description' => [
            'required' => false,
            'max_length' => 500,
            'message' => '描述不能超过500个字符'
        ],
        'listen_port' => [
            'required' => true,
            'type' => 'integer',
            'min' => 1024,
            'max' => 65535,
            'message' => '端口号必须是1024-65535之间的整数'
        ],
        'server_address' => [
            'required' => true,
            'type' => 'cidr',
            'message' => '请输入有效的IP地址和子网掩码'
        ],
        'dns_servers' => [
            'required' => false,
            'type' => 'ip_list',
            'message' => '请输入有效的DNS服务器地址'
        ],
        'client_name' => [
            'required' => true,
            'min_length' => 3,
            'max_length' => 100,
            'pattern' => '/^[a-zA-Z0-9_-]+$/',
            'message' => '客户端名称只能包含字母、数字、下划线和连字符，长度3-100位'
        ],
        'client_allowed_ips' => [
            'required' => true,
            'type' => 'cidr_list',
            'message' => '请输入有效的允许IP地址列表'
        ],
        'bgp_session_name' => [
            'required' => true,
            'min_length' => 3,
            'max_length' => 100,
            'pattern' => '/^[a-zA-Z0-9_-]+$/',
            'message' => 'BGP会话名称只能包含字母、数字、下划线和连字符，长度3-100位'
        ],
        'local_as' => [
            'required' => true,
            'type' => 'integer',
            'min' => 1,
            'max' => 4294967295,
            'message' => '本地AS号必须是1-4294967295之间的整数'
        ],
        'remote_as' => [
            'required' => true,
            'type' => 'integer',
            'min' => 1,
            'max' => 4294967295,
            'message' => '远程AS号必须是1-4294967295之间的整数'
        ],
        'local_ip' => [
            'required' => true,
            'type' => 'ip',
            'message' => '请输入有效的本地IP地址'
        ],
        'remote_ip' => [
            'required' => true,
            'type' => 'ip',
            'message' => '请输入有效的远程IP地址'
        ],
        'hold_time' => [
            'required' => false,
            'type' => 'integer',
            'min' => 3,
            'max' => 65535,
            'default' => 180,
            'message' => '保持时间必须是3-65535之间的整数'
        ],
        'keepalive_time' => [
            'required' => false,
            'type' => 'integer',
            'min' => 1,
            'max' => 65535,
            'default' => 60,
            'message' => '保活时间必须是1-65535之间的整数'
        ],
        'ipv6_pool_name' => [
            'required' => true,
            'min_length' => 3,
            'max_length' => 100,
            'pattern' => '/^[a-zA-Z0-9_-]+$/',
            'message' => 'IPv6前缀池名称只能包含字母、数字、下划线和连字符，长度3-100位'
        ],
        'ipv6_prefix' => [
            'required' => true,
            'type' => 'ipv6_cidr',
            'message' => '请输入有效的IPv6前缀'
        ],
        'prefix_length' => [
            'required' => true,
            'type' => 'integer',
            'min' => 1,
            'max' => 128,
            'message' => '前缀长度必须是1-128之间的整数'
        ]
    ];
    
    /**
     * 验证输入数据
     */
    public static function validate($data, $fields = []) {
        $errors = [];
        $validatedData = [];
        
        // 如果没有指定字段，验证所有数据
        if (empty($fields)) {
            $fields = array_keys($data);
        }
        
        foreach ($fields as $field) {
            $value = $data[$field] ?? null;
            $rule = self::$rules[$field] ?? null;
            
            if (!$rule) {
                continue; // 跳过没有规则的字段
            }
            
            // 检查必填字段
            if ($rule['required'] && (is_null($value) || $value === '')) {
                $errors[$field] = $rule['message'] ?? "字段 {$field} 是必填的";
                continue;
            }
            
            // 如果字段为空且不是必填的，跳过验证
            if (is_null($value) || $value === '') {
                if (isset($rule['default'])) {
                    $validatedData[$field] = $rule['default'];
                }
                continue;
            }
            
            // 验证字段
            $validationResult = self::validateField($field, $value, $rule);
            if ($validationResult['valid']) {
                $validatedData[$field] = $validationResult['value'];
            } else {
                $errors[$field] = $validationResult['error'];
            }
        }
        
        return [
            'valid' => empty($errors),
            'errors' => $errors,
            'data' => $validatedData
        ];
    }
    
    /**
     * 验证单个字段
     */
    private static function validateField($field, $value, $rule) {
        // 长度验证
        if (isset($rule['min_length']) && strlen($value) < $rule['min_length']) {
            return [
                'valid' => false,
                'error' => $rule['message'] ?? "字段 {$field} 长度不能少于 {$rule['min_length']} 位"
            ];
        }
        
        if (isset($rule['max_length']) && strlen($value) > $rule['max_length']) {
            return [
                'valid' => false,
                'error' => $rule['message'] ?? "字段 {$field} 长度不能超过 {$rule['max_length']} 位"
            ];
        }
        
        // 类型验证
        if (isset($rule['type'])) {
            $typeResult = self::validateType($value, $rule['type']);
            if (!$typeResult['valid']) {
                return [
                    'valid' => false,
                    'error' => $rule['message'] ?? $typeResult['error']
                ];
            }
            $value = $typeResult['value'];
        }
        
        // 数值范围验证
        if (isset($rule['min']) && is_numeric($value) && $value < $rule['min']) {
            return [
                'valid' => false,
                'error' => $rule['message'] ?? "字段 {$field} 值不能小于 {$rule['min']}"
            ];
        }
        
        if (isset($rule['max']) && is_numeric($value) && $value > $rule['max']) {
            return [
                'valid' => false,
                'error' => $rule['message'] ?? "字段 {$field} 值不能大于 {$rule['max']}"
            ];
        }
        
        // 正则表达式验证
        if (isset($rule['pattern']) && !preg_match($rule['pattern'], $value)) {
            return [
                'valid' => false,
                'error' => $rule['message'] ?? "字段 {$field} 格式不正确"
            ];
        }
        
        return [
            'valid' => true,
            'value' => $value
        ];
    }
    
    /**
     * 验证数据类型
     */
    private static function validateType($value, $type) {
        switch ($type) {
            case 'email':
                if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
                    return [
                        'valid' => false,
                        'error' => '请输入有效的邮箱地址'
                    ];
                }
                return ['valid' => true, 'value' => $value];
                
            case 'integer':
                if (!is_numeric($value) || (int)$value != $value) {
                    return [
                        'valid' => false,
                        'error' => '必须是整数'
                    ];
                }
                return ['valid' => true, 'value' => (int)$value];
                
            case 'float':
                if (!is_numeric($value)) {
                    return [
                        'valid' => false,
                        'error' => '必须是数字'
                    ];
                }
                return ['valid' => true, 'value' => (float)$value];
                
            case 'boolean':
                if (is_bool($value)) {
                    return ['valid' => true, 'value' => $value];
                }
                if (in_array(strtolower($value), ['true', '1', 'yes', 'on'])) {
                    return ['valid' => true, 'value' => true];
                }
                if (in_array(strtolower($value), ['false', '0', 'no', 'off', ''])) {
                    return ['valid' => true, 'value' => false];
                }
                return [
                    'valid' => false,
                    'error' => '必须是布尔值'
                ];
                
            case 'ip':
                if (!filter_var($value, FILTER_VALIDATE_IP)) {
                    return [
                        'valid' => false,
                        'error' => '请输入有效的IP地址'
                    ];
                }
                return ['valid' => true, 'value' => $value];
                
            case 'ipv6':
                if (!filter_var($value, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
                    return [
                        'valid' => false,
                        'error' => '请输入有效的IPv6地址'
                    ];
                }
                return ['valid' => true, 'value' => $value];
                
            case 'cidr':
                if (!self::isValidCIDR($value)) {
                    return [
                        'valid' => false,
                        'error' => '请输入有效的CIDR格式（如：192.168.1.0/24）'
                    ];
                }
                return ['valid' => true, 'value' => $value];
                
            case 'ipv6_cidr':
                if (!self::isValidIPv6CIDR($value)) {
                    return [
                        'valid' => false,
                        'error' => '请输入有效的IPv6 CIDR格式（如：2001:db8::/48）'
                    ];
                }
                return ['valid' => true, 'value' => $value];
                
            case 'ip_list':
                $ips = explode(',', $value);
                foreach ($ips as $ip) {
                    $ip = trim($ip);
                    if (!filter_var($ip, FILTER_VALIDATE_IP)) {
                        return [
                            'valid' => false,
                            'error' => 'IP地址列表包含无效的IP地址：' . $ip
                        ];
                    }
                }
                return ['valid' => true, 'value' => $value];
                
            case 'cidr_list':
                $cidrs = explode(',', $value);
                foreach ($cidrs as $cidr) {
                    $cidr = trim($cidr);
                    if (!self::isValidCIDR($cidr)) {
                        return [
                            'valid' => false,
                            'error' => 'CIDR列表包含无效的CIDR：' . $cidr
                        ];
                    }
                }
                return ['valid' => true, 'value' => $value];
                
            default:
                return ['valid' => true, 'value' => $value];
        }
    }
    
    /**
     * 验证CIDR格式
     */
    private static function isValidCIDR($cidr) {
        if (!preg_match('/^(\d{1,3}\.){3}\d{1,3}\/\d{1,2}$/', $cidr)) {
            return false;
        }
        
        list($ip, $prefix) = explode('/', $cidr);
        
        if (!filter_var($ip, FILTER_VALIDATE_IP)) {
            return false;
        }
        
        $prefix = (int)$prefix;
        if ($prefix < 0 || $prefix > 32) {
            return false;
        }
        
        return true;
    }
    
    /**
     * 验证IPv6 CIDR格式
     */
    private static function isValidIPv6CIDR($cidr) {
        if (!preg_match('/^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\/\d{1,3}$/', $cidr) &&
            !preg_match('/^([0-9a-fA-F]{1,4}:)*::([0-9a-fA-F]{1,4}:)*[0-9a-fA-F]{1,4}\/\d{1,3}$/', $cidr)) {
            return false;
        }
        
        list($ip, $prefix) = explode('/', $cidr);
        
        if (!filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
            return false;
        }
        
        $prefix = (int)$prefix;
        if ($prefix < 0 || $prefix > 128) {
            return false;
        }
        
        return true;
    }
    
    /**
     * 验证用户注册数据
     */
    public static function validateUserRegistration($data) {
        return self::validate($data, ['username', 'email', 'password', 'full_name', 'phone']);
    }
    
    /**
     * 验证用户登录数据
     */
    public static function validateUserLogin($data) {
        return self::validate($data, ['username', 'password']);
    }
    
    /**
     * 验证密码修改数据
     */
    public static function validatePasswordChange($data) {
        $result = self::validate($data, ['old_password', 'new_password']);
        
        // 额外验证：新密码不能与旧密码相同
        if ($result['valid'] && isset($data['old_password']) && isset($data['new_password'])) {
            if ($data['old_password'] === $data['new_password']) {
                $result['valid'] = false;
                $result['errors']['new_password'] = '新密码不能与旧密码相同';
            }
        }
        
        return $result;
    }
    
    /**
     * 验证WireGuard服务器数据
     */
    public static function validateWireGuardServer($data) {
        return self::validate($data, [
            'server_name', 'server_description', 'listen_port', 
            'server_address', 'dns_servers'
        ]);
    }
    
    /**
     * 验证WireGuard客户端数据
     */
    public static function validateWireGuardClient($data) {
        return self::validate($data, [
            'client_name', 'client_allowed_ips'
        ]);
    }
    
    /**
     * 验证BGP会话数据
     */
    public static function validateBGPSession($data) {
        return self::validate($data, [
            'bgp_session_name', 'local_as', 'remote_as', 
            'local_ip', 'remote_ip', 'hold_time', 'keepalive_time'
        ]);
    }
    
    /**
     * 验证IPv6前缀池数据
     */
    public static function validateIPv6Pool($data) {
        return self::validate($data, [
            'ipv6_pool_name', 'ipv6_prefix', 'prefix_length'
        ]);
    }
    
    /**
     * 清理和转义输入数据
     */
    public static function sanitize($data) {
        if (is_array($data)) {
            return array_map([self::class, 'sanitize'], $data);
        }
        
        if (is_string($data)) {
            // 移除HTML标签
            $data = strip_tags($data);
            
            // 转义特殊字符
            $data = htmlspecialchars($data, ENT_QUOTES, 'UTF-8');
            
            // 移除多余的空白字符
            $data = trim($data);
        }
        
        return $data;
    }
    
    /**
     * 验证CSRF令牌
     */
    public static function validateCsrfToken($token) {
        if (!isset($_SESSION['csrf_token'])) {
            return false;
        }
        
        return hash_equals($_SESSION['csrf_token'], $token);
    }
    
    /**
     * 生成CSRF令牌
     */
    public static function generateCsrfToken() {
        if (!isset($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['csrf_token'];
    }
    
    /**
     * 获取验证规则
     */
    public static function getRules($field = null) {
        if ($field) {
            return self::$rules[$field] ?? null;
        }
        return self::$rules;
    }
    
    /**
     * 添加自定义验证规则
     */
    public static function addRule($field, $rule) {
        self::$rules[$field] = $rule;
    }
    
    /**
     * 移除验证规则
     */
    public static function removeRule($field) {
        unset(self::$rules[$field]);
    }
}
?>
