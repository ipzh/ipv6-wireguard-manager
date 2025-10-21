<?php
/**
 * 前端首页测试页面
 */

// 设置错误处理
error_reporting(E_ALL);
ini_set('display_errors', 1);

// 启动会话
session_start();

// 引入配置
if (file_exists('config/config.php')) {
    require_once 'config/config.php';
} else {
    // 默认配置
    define('APP_NAME', 'IPv6 WireGuard Manager');
    define('APP_VERSION', '3.0.0');
}

?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= APP_NAME ?> - 系统状态</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.7.2/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        .status-card {
            transition: transform 0.2s;
        }
        .status-card:hover {
            transform: translateY(-2px);
        }
        .status-indicator {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            display: inline-block;
            margin-right: 8px;
        }
        .status-success { background-color: #28a745; }
        .status-error { background-color: #dc3545; }
        .status-warning { background-color: #ffc107; }
        .status-info { background-color: #17a2b8; }
    </style>
</head>
<body class="bg-light">
    <div class="container mt-5">
        <div class="row justify-content-center">
            <div class="col-md-10">
                <div class="card shadow">
                    <div class="card-header bg-primary text-white">
                        <h4 class="mb-0">
                            <i class="bi bi-shield-lock me-2"></i>
                            <?= APP_NAME ?> - 系统状态检查
                        </h4>
                    </div>
                    <div class="card-body">
                        <!-- 系统信息 -->
                        <div class="row mb-4">
                            <div class="col-md-6">
                                <h5><i class="bi bi-info-circle text-primary me-2"></i>系统信息</h5>
                                <table class="table table-sm">
                                    <tr>
                                        <td><strong>PHP版本:</strong></td>
                                        <td><?= PHP_VERSION ?></td>
                                    </tr>
                                    <tr>
                                        <td><strong>服务器时间:</strong></td>
                                        <td><?= date('Y-m-d H:i:s') ?></td>
                                    </tr>
                                    <tr>
                                        <td><strong>服务器:</strong></td>
                                        <td><?= $_SERVER['SERVER_NAME'] ?? 'localhost' ?></td>
                                    </tr>
                                    <tr>
                                        <td><strong>请求URI:</strong></td>
                                        <td><?= $_SERVER['REQUEST_URI'] ?? '/' ?></td>
                                    </tr>
                                </table>
                            </div>
                            <div class="col-md-6">
                                <h5><i class="bi bi-gear text-success me-2"></i>应用信息</h5>
                                <table class="table table-sm">
                                    <tr>
                                        <td><strong>应用名称:</strong></td>
                                        <td><?= APP_NAME ?></td>
                                    </tr>
                                    <tr>
                                        <td><strong>版本:</strong></td>
                                        <td><?= APP_VERSION ?></td>
                                    </tr>
                                    <tr>
                                        <td><strong>调试模式:</strong></td>
                                        <td><?= defined('APP_DEBUG') && APP_DEBUG ? '开启' : '关闭' ?></td>
                                    </tr>
                                    <tr>
                                        <td><strong>会话状态:</strong></td>
                                        <td><?= session_status() === PHP_SESSION_ACTIVE ? '活跃' : '未启动' ?></td>
                                    </tr>
                                </table>
                            </div>
                        </div>

                        <!-- 文件检查 -->
                        <h5><i class="bi bi-folder-check text-info me-2"></i>文件检查</h5>
                        <div class="row mb-4">
                            <?php
                            $files = [
                                'config/config.php' => '配置文件',
                                'config/database.php' => '数据库配置',
                                'controllers/DashboardController.php' => '仪表板控制器',
                                'controllers/AuthController.php' => '认证控制器',
                                'views/auth/login.php' => '登录页面',
                                'views/dashboard/index.php' => '仪表板视图',
                                'views/layout/header.php' => '页面头部',
                                'views/layout/footer.php' => '页面底部',
                                'classes/Router.php' => '路由类',
                                'classes/Auth.php' => '认证类',
                                'classes/ApiClient.php' => 'API客户端',
                                'index.php' => '主入口文件'
                            ];

                            foreach ($files as $file => $description) {
                                $exists = file_exists($file);
                                $status = $exists ? 'success' : 'error';
                                $icon = $exists ? 'check-circle' : 'x-circle';
                                $color = $exists ? 'success' : 'danger';
                            ?>
                            <div class="col-md-6 col-lg-4 mb-2">
                                <div class="d-flex align-items-center">
                                    <span class="status-indicator status-<?= $status ?>"></span>
                                    <i class="bi bi-<?= $icon ?> text-<?= $color ?> me-2"></i>
                                    <small><?= $description ?></small>
                                </div>
                            </div>
                            <?php } ?>
                        </div>

                        <!-- 功能测试 -->
                        <h5><i class="bi bi-play-circle text-warning me-2"></i>功能测试</h5>
                        <div class="row mb-4">
                            <div class="col-md-4 mb-3">
                                <div class="card status-card h-100">
                                    <div class="card-body text-center">
                                        <i class="bi bi-house-door text-primary mb-2" style="font-size: 2rem;"></i>
                                        <h6>首页访问</h6>
                                        <p class="text-muted small">测试首页是否可以正常访问</p>
                                        <a href="/" class="btn btn-primary btn-sm">访问首页</a>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4 mb-3">
                                <div class="card status-card h-100">
                                    <div class="card-body text-center">
                                        <i class="bi bi-box-arrow-in-right text-success mb-2" style="font-size: 2rem;"></i>
                                        <h6>登录页面</h6>
                                        <p class="text-muted small">测试登录页面是否正常</p>
                                        <a href="/login" class="btn btn-success btn-sm">访问登录</a>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4 mb-3">
                                <div class="card status-card h-100">
                                    <div class="card-body text-center">
                                        <i class="bi bi-shield-lock text-info mb-2" style="font-size: 2rem;"></i>
                                        <h6>API状态</h6>
                                        <p class="text-muted small">检查后端API连接状态</p>
                                        <button class="btn btn-info btn-sm" onclick="checkApiStatus()">检查API</button>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- API状态检查 -->
                        <div id="apiStatusResult" class="mb-4" style="display: none;">
                            <h5><i class="bi bi-activity text-primary me-2"></i>API状态检查结果</h5>
                            <div id="apiStatusContent"></div>
                        </div>

                        <!-- 操作按钮 -->
                        <div class="text-center">
                            <a href="/" class="btn btn-primary me-2">
                                <i class="bi bi-house me-1"></i>返回首页
                            </a>
                            <a href="/login" class="btn btn-success me-2">
                                <i class="bi bi-box-arrow-in-right me-1"></i>前往登录
                            </a>
                            <button class="btn btn-info" onclick="location.reload()">
                                <i class="bi bi-arrow-clockwise me-1"></i>刷新页面
                            </button>
                        </div>
                    </div>
                    <div class="card-footer text-muted text-center">
                        <small>
                            <i class="bi bi-clock me-1"></i>
                            测试时间: <?= date('Y-m-d H:i:s') ?> | 
                            <i class="bi bi-code-slash me-1"></i>
                            <?= APP_NAME ?> v<?= APP_VERSION ?>
                        </small>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function checkApiStatus() {
            const resultDiv = document.getElementById('apiStatusResult');
            const contentDiv = document.getElementById('apiStatusContent');
            
            resultDiv.style.display = 'block';
            contentDiv.innerHTML = '<div class="text-center"><div class="spinner-border text-primary" role="status"><span class="visually-hidden">检查中...</span></div><p class="mt-2">正在检查API状态...</p></div>';
            
            // 使用API代理端点
            fetch('/api/health')
                .then(response => {
                    if (!response.ok) {
                        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                    }
                    return response.json();
                })
                .then(data => {
                    if (data.success !== false && data.status === 'healthy') {
                        contentDiv.innerHTML = `
                            <div class="alert alert-success">
                                <i class="bi bi-check-circle me-2"></i>
                                <strong>API连接正常</strong><br>
                                <small>服务: ${data.service || 'IPv6 WireGuard Manager'}</small><br>
                                <small>版本: ${data.version || '3.0.0'}</small><br>
                                <small>响应时间: ${new Date().toLocaleTimeString()}</small>
                            </div>
                        `;
                    } else {
                        contentDiv.innerHTML = `
                            <div class="alert alert-warning">
                                <i class="bi bi-exclamation-triangle me-2"></i>
                                <strong>API状态异常</strong><br>
                                <small>错误: ${data.error || data.message || '未知错误'}</small>
                            </div>
                        `;
                    }
                })
                .catch(error => {
                    contentDiv.innerHTML = `
                        <div class="alert alert-danger">
                            <i class="bi bi-x-circle me-2"></i>
                            <strong>API连接失败</strong><br>
                            <small>错误: ${error.message}</small><br>
                            <small>请检查后端服务是否运行</small>
                        </div>
                    `;
                });
        }
    </script>
</body>
</html>
