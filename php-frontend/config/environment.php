<?php
/**
 * 环境配置管理
 * 根据不同环境加载不同的配置
 */

class Environment {
    const DEVELOPMENT = 'development';
    const TESTING = 'testing';
    const STAGING = 'staging';
    const PRODUCTION = 'production';
    
    private static $current;
    private static $config = [];
    
    /**
     * 初始化环境配置
     */
    public static function init() {
        // 从环境变量获取当前环境，默认为development
        self::$current = getenv('APP_ENV') ?: self::DEVELOPMENT;
        
        // 加载环境特定配置
        self::loadConfig();
    }
    
    /**
     * 获取当前环境
     */
    public static function getCurrent() {
        if (!self::$current) {
            self::init();
        }
        return self::$current;
    }
    
    /**
     * 加载配置
     */
    private static function loadConfig() {
        $baseConfig = require __DIR__ . '/api_config.php';
        
        // 根据环境加载特定配置
        $envConfigFile = __DIR__ . '/api_config_' . self::$current . '.php';
        if (file_exists($envConfigFile)) {
            $envConfig = require $envConfigFile;
            self::$config = array_merge_recursive($baseConfig, $envConfig);
        } else {
            self::$config = $baseConfig;
        }
    }
    
    /**
     * 获取配置值
     */
    public static function get($key, $default = null) {
        if (!self::$config) {
            self::init();
        }
        
        $keys = explode('.', $key);
        $value = self::$config;
        
        foreach ($keys as $k) {
            if (isset($value[$k])) {
                $value = $value[$k];
            } else {
                return $default;
            }
        }
        
        return $value;
    }
    
    /**
     * 检查是否为开发环境
     */
    public static function isDevelopment() {
        return self::getCurrent() === self::DEVELOPMENT;
    }
    
    /**
     * 检查是否为生产环境
     */
    public static function isProduction() {
        return self::getCurrent() === self::PRODUCTION;
    }
}
