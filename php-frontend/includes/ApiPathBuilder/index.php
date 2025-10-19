<?php

/**
 * API路径构建器模块初始化文件
 * 
 * 这个文件提供了API路径构建器模块的统一入口点，
 * 包含所有必要的类导入和便捷函数。
 */

// 导入所有必要的类
require_once __DIR__ . '/VersionManager.php';
require_once __DIR__ . '/PathConfig.php';
require_once __DIR__ . '/PathValidator.php';
require_once __DIR__ . '/APIPathBuilder.php';
require_once __DIR__ . '/ApiPathBuilderIntegration.php';

/**
 * 创建API路径构建器实例的便捷函数
 * 
 * @param string $baseUrl 基础URL
 * @param string $version API版本
 * @return APIPathBuilder API路径构建器实例
 */
function create_api_path_builder($baseUrl = '', $version = 'v1') {
    return new APIPathBuilder($baseUrl, $version);
}

/**
 * 获取默认API路径构建器实例的便捷函数
 * 
 * @param string $baseUrl 基础URL
 * @param string $version API版本
 * @return ApiPathBuilderIntegration API路径构建器集成实例
 */
function get_default_api_path_builder($baseUrl = '', $version = 'v1') {
    return ApiPathBuilderIntegration::getInstance($baseUrl, $version);
}

/**
 * 创建API路径构建器实例并设置API客户端的便捷函数
 * 
 * @param ApiClient $apiClient API客户端实例
 * @param string $baseUrl 基础URL
 * @param string $version API版本
 * @return ApiPathBuilderIntegration API路径构建器集成实例
 */
function create_api_path_builder_with_client($apiClient, $baseUrl = '', $version = 'v1') {
    $builder = ApiPathBuilderIntegration::getInstance($baseUrl, $version);
    $builder->setApiClient($apiClient);
    return $builder;
}

/**
 * 验证API路径的便捷函数
 * 
 * @param string $pathName 路径名称
 * @param array $params 路径参数
 * @param string $version API版本
 * @return bool 验证结果
 */
function validate_api_path($pathName, $params = [], $version = 'v1') {
    $builder = get_default_api_path_builder();
    $result = $builder->validatePath($pathName, $params, $version);
    return $result['valid'];
}

/**
 * 构建API路径的便捷函数
 * 
 * @param string $pathName 路径名称
 * @param array $params 路径参数
 * @param string $version API版本
 * @return string 构建的路径
 */
function build_api_path($pathName, $params = [], $version = 'v1') {
    $builder = get_default_api_path_builder();
    return $builder->buildPath($pathName, $params, $version);
}

/**
 * 构建API URL的便捷函数
 * 
 * @param string $pathName 路径名称
 * @param array $params 路径参数
 * @param array $queryParams 查询参数
 * @param string $version API版本
 * @return string 构建的URL
 */
function build_api_url($pathName, $params = [], $queryParams = [], $version = 'v1') {
    $builder = get_default_api_path_builder();
    return $builder->buildUrl($pathName, $params, $queryParams, $version);
}

/**
 * 执行API GET请求的便捷函数
 * 
 * @param string $pathName 路径名称
 * @param array $params 路径参数
 * @param array $queryParams 查询参数
 * @param string $version API版本
 * @return array 请求结果
 */
function api_get($pathName, $params = [], $queryParams = [], $version = 'v1') {
    $builder = get_default_api_path_builder();
    return $builder->get($pathName, $params, $queryParams, $version);
}

/**
 * 执行API POST请求的便捷函数
 * 
 * @param string $pathName 路径名称
 * @param array $params 路径参数
 * @param array $data 请求数据
 * @param string $version API版本
 * @return array 请求结果
 */
function api_post($pathName, $params = [], $data = [], $version = 'v1') {
    $builder = get_default_api_path_builder();
    return $builder->post($pathName, $params, $data, $version);
}

/**
 * 执行API PUT请求的便捷函数
 * 
 * @param string $pathName 路径名称
 * @param array $params 路径参数
 * @param array $data 请求数据
 * @param string $version API版本
 * @return array 请求结果
 */
function api_put($pathName, $params = [], $data = [], $version = 'v1') {
    $builder = get_default_api_path_builder();
    return $builder->put($pathName, $params, $data, $version);
}

/**
 * 执行API DELETE请求的便捷函数
 * 
 * @param string $pathName 路径名称
 * @param array $params 路径参数
 * @param string $version API版本
 * @return array 请求结果
 */
function api_delete($pathName, $params = [], $version = 'v1') {
    $builder = get_default_api_path_builder();
    return $builder->delete($pathName, $params, $version);
}

/**
 * 获取API路径参数的便捷函数
 * 
 * @param string $pathName 路径名称
 * @return array 路径参数数组
 */
function get_api_path_parameters($pathName) {
    $builder = get_default_api_path_builder();
    return $builder->getPathParameters($pathName);
}

/**
 * 检查API路径是否存在的便捷函数
 * 
 * @param string $pathName 路径名称
 * @return bool 路径是否存在
 */
function api_path_exists($pathName) {
    $builder = get_default_api_path_builder();
    return $builder->pathExists($pathName);
}

/**
 * 获取API路径支持版本的便捷函数
 * 
 * @param string $pathName 路径名称
 * @return array 支持的版本数组
 */
function get_api_path_supported_versions($pathName) {
    $builder = get_default_api_path_builder();
    return $builder->getSupportedVersionsForPath($pathName);
}

/**
 * 获取API路径支持方法的便捷函数
 * 
 * @param string $pathName 路径名称
 * @return array 支持的方法数组
 */
function get_api_path_supported_methods($pathName) {
    $builder = get_default_api_path_builder();
    return $builder->getSupportedMethodsForPath($pathName);
}

/**
 * 生成API文档的便捷函数
 * 
 * @param string $version API版本
 * @return array API文档数据
 */
function generate_api_documentation($version = 'v1') {
    $builder = get_default_api_path_builder();
    return $builder->generateApiDocumentation($version);
}

/**
 * 导出API路径配置的便捷函数
 * 
 * @return array 路径配置数据
 */
function export_api_path_configuration() {
    $builder = get_default_api_path_builder();
    return $builder->exportPathConfiguration();
}

/**
 * 导入API路径配置的便捷函数
 * 
 * @param array $config 路径配置数据
 */
function import_api_path_configuration($config) {
    $builder = get_default_api_path_builder();
    $builder->importPathConfiguration($config);
}

// 模块版本信息
define('API_PATH_BUILDER_VERSION', '1.0.0');
define('API_PATH_BUILDER_MODULE_NAME', 'API Path Builder');

?>