<?php
/**
 * 统一的API路径配置
 * 此文件由后端自动生成，请勿手动修改
 */

// 如果自动生成的配置文件存在，则使用它
$auto_generated_file = __DIR__ . '/../generated/api_paths.php';
if (file_exists($auto_generated_file)) {
    return include $auto_generated_file;
}

// 回退到手动配置（向后兼容）
return [
    'version' => 'v1',
    'base_url' => '/api/v1',
    'endpoints' => [
        '认证' => [
            [
                'path' => '/auth/login',
                'methods' => ['POST'],
                'name' => 'login',
                'summary' => '用户登录',
                'description' => '用户登录接口'
            ],
            [
                'path' => '/auth/logout',
                'methods' => ['POST'],
                'name' => 'logout',
                'summary' => '用户登出',
                'description' => '用户登出接口'
            ]
        ],
        '用户管理' => [
            [
                'path' => '/users',
                'methods' => ['GET', 'POST'],
                'name' => 'users',
                'summary' => '用户管理',
                'description' => '用户列表和创建'
            ]
        ],
        'WireGuard管理' => [
            [
                'path' => '/wireguard/configs',
                'methods' => ['GET', 'POST'],
                'name' => 'wireguard_configs',
                'summary' => 'WireGuard配置',
                'description' => 'WireGuard配置管理'
            ]
        ],
        '健康检查' => [
            [
                'path' => '/health',
                'methods' => ['GET'],
                'name' => 'health',
                'summary' => '健康检查',
                'description' => 'API健康检查'
            ]
        ]
    ]
];
