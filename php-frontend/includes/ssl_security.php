<?php
/**
 * SSL/TLS安全配置工具
 */

/**
 * 获取安全的SSL配置选项
 * @return array SSL配置选项数组
 */
function getSecureSSLOptions() {
    // 从环境变量读取SSL验证设置
    $sslVerifyPeer = getenv('API_SSL_VERIFY') !== 'false' && getenv('API_SSL_VERIFY') !== '0';
    $sslVerifyHost = $sslVerifyPeer ? 2 : 0; // 2 = 严格验证主机名
    
    $options = [
        CURLOPT_SSL_VERIFYPEER => $sslVerifyPeer,
        CURLOPT_SSL_VERIFYHOST => $sslVerifyHost,
    ];
    
    // 如果启用SSL验证，设置CA证书路径
    if ($sslVerifyPeer) {
        $caPath = getenv('API_SSL_CA_PATH');
        if ($caPath && file_exists($caPath)) {
            $options[CURLOPT_CAINFO] = $caPath;
        }
    }
    
    return $options;
}

/**
 * 应用安全的SSL配置到cURL句柄
 * @param resource $ch cURL句柄
 */
function applySecureSSLConfig($ch) {
    $sslOptions = getSecureSSLOptions();
    curl_setopt_array($ch, $sslOptions);
}

/**
 * 检查SSL配置是否安全
 * @return array 检查结果
 */
function checkSSLConfiguration() {
    $sslVerifyPeer = getenv('API_SSL_VERIFY') !== 'false' && getenv('API_SSL_VERIFY') !== '0';
    $caPath = getenv('API_SSL_CA_PATH');
    
    return [
        'ssl_verify_enabled' => $sslVerifyPeer,
        'ca_path_set' => !empty($caPath),
        'ca_path_exists' => $caPath && file_exists($caPath),
        'recommendation' => $sslVerifyPeer ? 
            'SSL验证已启用，配置安全' : 
            '警告：SSL验证已禁用，仅应在开发环境使用'
    ];
}
?>
