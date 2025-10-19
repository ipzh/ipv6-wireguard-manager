<?php

require_once __DIR__ . '/PathConfig.php';

/**
 * 路径验证器
 * 负责验证API路径、参数和定义
 */

class PathValidator {
    /**
     * 路径配置实例
     * @var PathConfig
     */
    private $pathConfig;
    
    /**
     * 验证结果
     * @var array
     */
    private $validationResults;
    
    /**
     * 构造函数
     * 
     * @param PathConfig $pathConfig 路径配置实例
     */
    public function __construct(PathConfig $pathConfig) {
        $this->pathConfig = $pathConfig;
        $this->validationResults = [];
    }
    
    /**
     * 验证路径格式
     * 
     * @param string $path 要验证的路径
     * @return array 验证结果
     */
    public function validatePathFormat($path) {
        $result = [
            'valid' => true,
            'errors' => [],
            'warnings' => []
        ];
        
        // 检查路径是否以斜杠开头
        if (substr($path, 0, 1) !== '/') {
            $result['valid'] = false;
            $result['errors'][] = "路径必须以斜杠(/)开头";
        }
        
        // 检查路径是否包含非法字符
        if (preg_match('/[<>:"|?*]/', $path)) {
            $result['valid'] = false;
            $result['errors'][] = "路径包含非法字符: < > : \" | ? *";
        }
        
        // 检查路径是否包含连续斜杠
        if (strpos($path, '//') !== false) {
            $result['valid'] = false;
            $result['errors'][] = "路径不能包含连续斜杠(//)";
        }
        
        // 检查路径是否以斜杠结尾（除了根路径）
        if ($path !== '/' && substr($path, -1) === '/') {
            $result['warnings'][] = "路径不应以斜杠结尾";
        }
        
        return $result;
    }
    
    /**
     * 验证路径参数
     * 
     * @param string $pathName 路径名称
     * @param array $params 提供的参数
     * @return array 验证结果
     */
    public function validatePathParameters($pathName, $params) {
        $result = [
            'valid' => true,
            'errors' => [],
            'warnings' => []
        ];
        
        $pathInfo = $this->pathConfig->getPath($pathName);
        if (!$pathInfo) {
            $result['valid'] = false;
            $result['errors'][] = "未知的路径名称: {$pathName}";
            return $result;
        }
        
        // 获取路径中定义的参数
        $pathPattern = $pathInfo['path'];
        preg_match_all('/\{([^}]+)\}/', $pathPattern, $matches);
        $requiredParams = $matches[1];
        
        // 检查必需参数是否提供
        foreach ($requiredParams as $param) {
            if (!isset($params[$param])) {
                $result['valid'] = false;
                $result['errors'][] = "缺少必需参数: {$param}";
            }
        }
        
        // 检查提供的参数是否符合要求
        $pathParams = $this->pathConfig->getParameters($pathName);
        foreach ($params as $paramName => $paramValue) {
            if (isset($pathParams[$paramName])) {
                $paramDef = $pathParams[$paramName];
                
                // 检查类型
                if (isset($paramDef['type'])) {
                    $type = $paramDef['type'];
                    if ($type === 'int' && !is_numeric($paramValue)) {
                        $result['valid'] = false;
                        $result['errors'][] = "参数 {$paramName} 应为整数";
                    } elseif ($type === 'string' && !is_string($paramValue)) {
                        $result['valid'] = false;
                        $result['errors'][] = "参数 {$paramName} 应为字符串";
                    } elseif ($type === 'bool' && !is_bool($paramValue)) {
                        $result['valid'] = false;
                        $result['errors'][] = "参数 {$paramName} 应为布尔值";
                    }
                }
                
                // 检查长度
                if (isset($paramDef['maxLength']) && is_string($paramValue) && strlen($paramValue) > $paramDef['maxLength']) {
                    $result['valid'] = false;
                    $result['errors'][] = "参数 {$paramName} 长度超过最大限制 {$paramDef['maxLength']}";
                }
                
                // 检查最小值
                if (isset($paramDef['min']) && is_numeric($paramValue) && $paramValue < $paramDef['min']) {
                    $result['valid'] = false;
                    $result['errors'][] = "参数 {$paramName} 值小于最小值 {$paramDef['min']}";
                }
                
                // 检查最大值
                if (isset($paramDef['max']) && is_numeric($paramValue) && $paramValue > $paramDef['max']) {
                    $result['valid'] = false;
                    $result['errors'][] = "参数 {$paramName} 值大于最大值 {$paramDef['max']}";
                }
                
                // 检查枚举值
                if (isset($paramDef['enum']) && !in_array($paramValue, $paramDef['enum'])) {
                    $result['valid'] = false;
                    $result['errors'][] = "参数 {$paramName} 值不在允许的范围内: " . implode(', ', $paramDef['enum']);
                }
            }
        }
        
        return $result;
    }
    
    /**
     * 验证路径定义
     * 
     * @param string $pathName 路径名称
     * @param array $pathData 路径数据
     * @return array 验证结果
     */
    public function validatePathDefinition($pathName, $pathData) {
        $result = [
            'valid' => true,
            'errors' => [],
            'warnings' => []
        ];
        
        // 检查路径名称
        if (empty($pathName)) {
            $result['valid'] = false;
            $result['errors'][] = "路径名称不能为空";
        }
        
        // 检查路径数据是否包含必需字段
        if (!isset($pathData['path'])) {
            $result['valid'] = false;
            $result['errors'][] = "路径定义必须包含路径字段";
        } else {
            $pathFormatResult = $this->validatePathFormat($pathData['path']);
            if (!$pathFormatResult['valid']) {
                $result['valid'] = false;
                $result['errors'] = array_merge($result['errors'], $pathFormatResult['errors']);
            }
            $result['warnings'] = array_merge($result['warnings'], $pathFormatResult['warnings']);
        }
        
        if (!isset($pathData['versions'])) {
            $result['valid'] = false;
            $result['errors'][] = "路径定义必须包含版本字段";
        } elseif (!is_array($pathData['versions']) || empty($pathData['versions'])) {
            $result['valid'] = false;
            $result['errors'][] = "版本字段必须是非空数组";
        }
        
        if (!isset($pathData['methods'])) {
            $result['valid'] = false;
            $result['errors'][] = "路径定义必须包含方法字段";
        } elseif (!is_array($pathData['methods']) || empty($pathData['methods'])) {
            $result['valid'] = false;
            $result['errors'][] = "方法字段必须是非空数组";
        }
        
        // 检查版本是否有效
        if (isset($pathData['versions']) && is_array($pathData['versions'])) {
            $versionManager = $this->pathConfig->getVersionManager();
            foreach ($pathData['versions'] as $version) {
                if (!$versionManager->isVersionSupported($version)) {
                    $result['warnings'][] = "版本 {$version} 不被支持";
                }
            }
        }
        
        // 检查HTTP方法是否有效
        if (isset($pathData['methods']) && is_array($pathData['methods'])) {
            $validMethods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];
            foreach ($pathData['methods'] as $method) {
                if (!in_array(strtoupper($method), $validMethods)) {
                    $result['valid'] = false;
                    $result['errors'][] = "无效的HTTP方法: {$method}";
                }
            }
        }
        
        return $result;
    }
    
    /**
     * 验证路径版本兼容性
     * 
     * @param string $pathName 路径名称
     * @param string $version API版本
     * @return array 验证结果
     */
    public function validatePathVersionCompatibility($pathName, $version) {
        $result = [
            'valid' => true,
            'errors' => [],
            'warnings' => []
        ];
        
        $versionManager = $this->pathConfig->getVersionManager();
        
        // 检查版本是否被支持
        if (!$versionManager->isVersionSupported($version)) {
            $result['valid'] = false;
            $result['errors'][] = "版本 {$version} 不被支持";
        }
        
        // 检查版本是否已弃用
        if ($versionManager->isVersionDeprecated($version)) {
            $result['warnings'][] = "版本 {$version} 已弃用";
        }
        
        // 检查路径是否支持该版本
        if (!$this->pathConfig->isPathSupportedInVersion($pathName, $version)) {
            $result['valid'] = false;
            $result['errors'][] = "路径 {$pathName} 不支持版本 {$version}";
        }
        
        return $result;
    }
    
    /**
     * 验证路径方法兼容性
     * 
     * @param string $pathName 路径名称
     * @param string $method HTTP方法
     * @return array 验证结果
     */
    public function validatePathMethodCompatibility($pathName, $method) {
        $result = [
            'valid' => true,
            'errors' => [],
            'warnings' => []
        ];
        
        // 检查HTTP方法是否有效
        $validMethods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];
        if (!in_array(strtoupper($method), $validMethods)) {
            $result['valid'] = false;
            $result['errors'][] = "无效的HTTP方法: {$method}";
        }
        
        // 检查路径是否支持该方法
        if (!$this->pathConfig->isPathSupportedForMethod($pathName, $method)) {
            $result['valid'] = false;
            $result['errors'][] = "路径 {$pathName} 不支持方法 {$method}";
        }
        
        return $result;
    }
    
    /**
     * 验证完整的路径请求
     * 
     * @param string $pathName 路径名称
     * @param string $version API版本
     * @param string $method HTTP方法
     * @param array $params 路径参数
     * @return array 综合验证结果
     */
    public function validatePathRequest($pathName, $version, $method, $params = []) {
        $result = [
            'valid' => true,
            'errors' => [],
            'warnings' => []
        ];
        
        // 验证路径版本兼容性
        $versionResult = $this->validatePathVersionCompatibility($pathName, $version);
        if (!$versionResult['valid']) {
            $result['valid'] = false;
        }
        $result['errors'] = array_merge($result['errors'], $versionResult['errors']);
        $result['warnings'] = array_merge($result['warnings'], $versionResult['warnings']);
        
        // 验证路径方法兼容性
        $methodResult = $this->validatePathMethodCompatibility($pathName, $method);
        if (!$methodResult['valid']) {
            $result['valid'] = false;
        }
        $result['errors'] = array_merge($result['errors'], $methodResult['errors']);
        $result['warnings'] = array_merge($result['warnings'], $methodResult['warnings']);
        
        // 验证路径参数
        $paramResult = $this->validatePathParameters($pathName, $params);
        if (!$paramResult['valid']) {
            $result['valid'] = false;
        }
        $result['errors'] = array_merge($result['errors'], $paramResult['errors']);
        $result['warnings'] = array_merge($result['warnings'], $paramResult['warnings']);
        
        return $result;
    }
    
    /**
     * 获取验证结果
     * 
     * @return array 所有验证结果
     */
    public function getValidationResults() {
        return $this->validationResults;
    }
    
    /**
     * 清除验证结果
     */
    public function clearValidationResults() {
        $this->validationResults = [];
    }
    
    /**
     * 添加验证结果
     * 
     * @param string $type 验证类型
     * @param array $result 验证结果
     */
    private function addValidationResult($type, $result) {
        if (!isset($this->validationResults[$type])) {
            $this->validationResults[$type] = [];
        }
        
        $this->validationResults[$type][] = $result;
    }
}

?>