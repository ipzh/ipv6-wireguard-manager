<?php
/**
 * 静态资源路径配置
 * 统一管理所有静态资源的路径
 */

// 基础路径配置
define('ASSETS_BASE_URL', '/assets');
define('CSS_BASE_URL', ASSETS_BASE_URL . '/css');
define('JS_BASE_URL', ASSETS_BASE_URL . '/js');
define('IMG_BASE_URL', ASSETS_BASE_URL . '/img');

// 主题相关资源
define('THEME_CSS_URL', CSS_BASE_URL . '/theme.css');
define('THEME_JS_URL', JS_BASE_URL . '/theme.js');

// CDN资源（带本地回退）
define('BOOTSTRAP_CSS_CDN', 'https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css');
define('BOOTSTRAP_JS_CDN', 'https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js');
define('BOOTSTRAP_ICONS_CDN', 'https://cdn.jsdelivr.net/npm/bootstrap-icons@1.7.2/font/bootstrap-icons.css');
define('CHART_JS_CDN', 'https://cdn.jsdelivr.net/npm/chart.js');
define('JQUERY_CDN', 'https://code.jquery.com/jquery-3.6.0.min.js');

// 本地回退资源
define('BOOTSTRAP_CSS_LOCAL', CSS_BASE_URL . '/bootstrap.min.css');
define('BOOTSTRAP_JS_LOCAL', JS_BASE_URL . '/bootstrap.bundle.min.js');
define('BOOTSTRAP_ICONS_LOCAL', CSS_BASE_URL . '/bootstrap-icons.css');
define('CHART_JS_LOCAL', JS_BASE_URL . '/chart.min.js');
define('JQUERY_LOCAL', JS_BASE_URL . '/jquery.min.js');

/**
 * 获取资源URL（带CDN回退）
 */
function getAssetUrl($cdnUrl, $localUrl, $useCDN = true) {
    if ($useCDN) {
        return $cdnUrl;
    }
    return $localUrl;
}

/**
 * 检查本地资源是否存在
 */
function assetExists($path) {
    $fullPath = $_SERVER['DOCUMENT_ROOT'] . $path;
    return file_exists($fullPath);
}

/**
 * 获取主题CSS URL
 */
function getThemeCssUrl() {
    return THEME_CSS_URL;
}

/**
 * 获取主题JS URL
 */
function getThemeJsUrl() {
    return THEME_JS_URL;
}

/**
 * 获取Bootstrap CSS URL
 */
function getBootstrapCssUrl($useCDN = true) {
    return getAssetUrl(BOOTSTRAP_CSS_CDN, BOOTSTRAP_CSS_LOCAL, $useCDN);
}

/**
 * 获取Bootstrap JS URL
 */
function getBootstrapJsUrl($useCDN = true) {
    return getAssetUrl(BOOTSTRAP_JS_CDN, BOOTSTRAP_JS_LOCAL, $useCDN);
}

/**
 * 获取Bootstrap Icons URL
 */
function getBootstrapIconsUrl($useCDN = true) {
    return getAssetUrl(BOOTSTRAP_ICONS_CDN, BOOTSTRAP_ICONS_LOCAL, $useCDN);
}

/**
 * 获取Chart.js URL
 */
function getChartJsUrl($useCDN = true) {
    return getAssetUrl(CHART_JS_CDN, CHART_JS_LOCAL, $useCDN);
}

/**
 * 获取jQuery URL
 */
function getJQueryUrl($useCDN = true) {
    return getAssetUrl(JQUERY_CDN, JQUERY_LOCAL, $useCDN);
}

/**
 * 生成资源标签
 */
function generateCssLink($url, $integrity = null, $crossorigin = null) {
    $attributes = ['rel="stylesheet"', 'href="' . htmlspecialchars($url) . '"'];
    
    if ($integrity) {
        $attributes[] = 'integrity="' . htmlspecialchars($integrity) . '"';
    }
    
    if ($crossorigin) {
        $attributes[] = 'crossorigin="' . htmlspecialchars($crossorigin) . '"';
    }
    
    return '<link ' . implode(' ', $attributes) . '>';
}

function generateJsScript($url, $integrity = null, $crossorigin = null) {
    $attributes = ['src="' . htmlspecialchars($url) . '"'];
    
    if ($integrity) {
        $attributes[] = 'integrity="' . htmlspecialchars($integrity) . '"';
    }
    
    if ($crossorigin) {
        $attributes[] = 'crossorigin="' . htmlspecialchars($crossorigin) . '"';
    }
    
    return '<script ' . implode(' ', $attributes) . '></script>';
}

/**
 * 预加载关键资源
 */
function generatePreloadLinks() {
    $preloads = [
        getBootstrapCssUrl(),
        getThemeCssUrl(),
        getBootstrapIconsUrl()
    ];
    
    $links = [];
    foreach ($preloads as $url) {
        $links[] = '<link rel="preload" href="' . htmlspecialchars($url) . '" as="style" onload="this.onload=null;this.rel=\'stylesheet\'">';
    }
    
    return implode("\n    ", $links);
}

/**
 * 生成所有必需的CSS链接
 */
function generateCssLinks($useCDN = true) {
    $links = [
        generateCssLink(getBootstrapCssUrl($useCDN)),
        generateCssLink(getBootstrapIconsUrl($useCDN)),
        generateCssLink(getThemeCssUrl())
    ];
    
    return implode("\n    ", $links);
}

/**
 * 生成所有必需的JS脚本
 */
function generateJsScripts($useCDN = true) {
    $scripts = [
        generateJsScript(getBootstrapJsUrl($useCDN)),
        generateJsScript(getJQueryUrl($useCDN)),
        generateJsScript(getChartJsUrl($useCDN)),
        generateJsScript(getThemeJsUrl())
    ];
    
    return implode("\n    ", $scripts);
}
?>
