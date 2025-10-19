<?php
/**
 * 生产环境API配置
 */

return [
    'api' => [
        'base_url' => 'https://api.example.com',
        'timeout' => 60,
        'retry_attempts' => 5,
    ],
    
    'websocket' => [
        'system_status' => 'wss://api.example.com/ws/system/status',
        'monitoring_data' => 'wss://api.example.com/ws/monitoring/data',
        'logs_stream' => 'wss://api.example.com/ws/logs/stream',
    ]
];
