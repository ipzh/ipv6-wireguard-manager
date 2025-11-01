<?php
/**
 * Cookie方案测试页面
 * 用于验证HttpOnly Cookie方案是否正常工作
 */

// 启动会话
session_start();

// 引入必要的类
require_once '../classes/ApiClientJWT.php';
require_once '../classes/ApiPathBuilder.php';
require_once '../classes/SSLConfig.php';

// 创建API客户端实例
$apiClient = new ApiClientJWT();

// 处理登录请求
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $response = [];
    
    switch ($_POST['action']) {
        case 'login':
            try {
                $username = $_POST['username'] ?? '';
                $password = $_POST['password'] ?? '';
                $mfaCode = $_POST['mfa_code'] ?? '';
                
                // 执行登录
                $loginResult = $apiClient->login($username, $password, $mfaCode);
                
                if ($loginResult) {
                    $response['success'] = true;
                    $response['message'] = '登录成功';
                    
                    // 获取当前用户信息
                    $currentUser = $apiClient->getCurrentUser();
                    if ($currentUser) {
                        $response['user'] = $currentUser;
                    }
                    
                    // 验证令牌
                    $tokenValid = $apiClient->verifyToken();
                    $response['token_valid'] = $tokenValid;
                } else {
                    $response['success'] = false;
                    $response['message'] = '登录失败';
                }
            } catch (Exception $e) {
                $response['success'] = false;
                $response['message'] = '登录错误: ' . $e->getMessage();
            }
            break;
            
        case 'logout':
            try {
                $logoutResult = $apiClient->logout();
                $response['success'] = true;
                $response['message'] = $logoutResult ? '登出成功' : '登出失败';
            } catch (Exception $e) {
                $response['success'] = false;
                $response['message'] = '登出错误: ' . $e->getMessage();
            }
            break;
            
        case 'check_status':
            try {
                $currentUser = $apiClient->getCurrentUser();
                $tokenValid = $apiClient->verifyToken();
                
                $response['logged_in'] = !empty($currentUser);
                $response['token_valid'] = $tokenValid;
                $response['user'] = $currentUser;
                $response['cookies'] = $_COOKIE;
            } catch (Exception $e) {
                $response['success'] = false;
                $response['message'] = '状态检查错误: ' . $e->getMessage();
            }
            break;
    }
    
    header('Content-Type: application/json');
    echo json_encode($response);
    exit;
}

// 检查当前登录状态
$currentUser = $apiClient->getCurrentUser();
$tokenValid = $apiClient->verifyToken();
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cookie方案测试</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
        }
        h1, h2 {
            color: #333;
        }
        .form-group {
            margin-bottom: 15px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
        input[type="text"], input[type="password"] {
            width: 100%;
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
        }
        button {
            background-color: #4CAF50;
            color: white;
            padding: 10px 15px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            margin-right: 10px;
        }
        button:hover {
            background-color: #45a049;
        }
        button.secondary {
            background-color: #f44336;
        }
        button.secondary:hover {
            background-color: #d32f2f;
        }
        .status {
            padding: 10px;
            margin: 10px 0;
            border-radius: 4px;
        }
        .status.success {
            background-color: #dff0d8;
            color: #3c763d;
            border: 1px solid #d6e9c6;
        }
        .status.error {
            background-color: #f2dede;
            color: #a94442;
            border: 1px solid #ebccd1;
        }
        .status.info {
            background-color: #d9edf7;
            color: #31708f;
            border: 1px solid #bce8f1;
        }
        .code {
            background-color: #f8f8f8;
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 10px;
            font-family: monospace;
            white-space: pre-wrap;
            overflow-x: auto;
        }
        .hidden {
            display: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Cookie方案测试页面</h1>
        <p>此页面用于测试HttpOnly Cookie方案是否正常工作。</p>
        
        <div id="status-container"></div>
        
        <?php if (empty($currentUser)): ?>
        <div id="login-form">
            <h2>登录测试</h2>
            <form id="login-form-element">
                <div class="form-group">
                    <label for="username">用户名:</label>
                    <input type="text" id="username" name="username" required>
                </div>
                <div class="form-group">
                    <label for="password">密码:</label>
                    <input type="password" id="password" name="password" required>
                </div>
                <div class="form-group">
                    <label for="mfa_code">MFA验证码 (可选):</label>
                    <input type="text" id="mfa_code" name="mfa_code">
                </div>
                <button type="submit">登录</button>
                <button type="button" id="check-status-btn">检查状态</button>
            </form>
        </div>
        <?php else: ?>
        <div id="user-info">
            <h2>当前用户信息</h2>
            <div class="code"><?php echo htmlspecialchars(json_encode($currentUser, JSON_PRETTY_PRINT)); ?></div>
            <p>令牌状态: <?php echo $tokenValid ? '有效' : '无效'; ?></p>
            <button id="logout-btn">登出</button>
            <button id="check-status-btn">检查状态</button>
        </div>
        <?php endif; ?>
        
        <div id="cookie-info" class="hidden">
            <h2>Cookie信息</h2>
            <div class="code" id="cookie-display"></div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const loginForm = document.getElementById('login-form-element');
            const logoutBtn = document.getElementById('logout-btn');
            const checkStatusBtn = document.getElementById('check-status-btn');
            const statusContainer = document.getElementById('status-container');
            const cookieInfo = document.getElementById('cookie-info');
            const cookieDisplay = document.getElementById('cookie-display');
            
            // 显示状态消息
            function showStatus(message, type = 'info') {
                statusContainer.innerHTML = `<div class="status ${type}">${message}</div>`;
                
                // 5秒后自动隐藏
                setTimeout(() => {
                    statusContainer.innerHTML = '';
                }, 5000);
            }
            
            // 处理登录
            if (loginForm) {
                loginForm.addEventListener('submit', function(e) {
                    e.preventDefault();
                    
                    const formData = new FormData(loginForm);
                    formData.append('action', 'login');
                    
                    fetch('cookie_test.php', {
                        method: 'POST',
                        body: formData,
                        credentials: 'include' // 确保发送Cookie
                    })
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            showStatus('登录成功！正在刷新页面...', 'success');
                            setTimeout(() => {
                                window.location.reload();
                            }, 1500);
                        } else {
                            showStatus('登录失败: ' + data.message, 'error');
                        }
                    })
                    .catch(error => {
                        showStatus('登录错误: ' + error.message, 'error');
                    });
                });
            }
            
            // 处理登出
            if (logoutBtn) {
                logoutBtn.addEventListener('click', function() {
                    const formData = new FormData();
                    formData.append('action', 'logout');
                    
                    fetch('cookie_test.php', {
                        method: 'POST',
                        body: formData,
                        credentials: 'include' // 确保发送Cookie
                    })
                    .then(response => response.json())
                    .then(data => {
                        showStatus(data.message, data.success ? 'success' : 'error');
                        if (data.success) {
                            setTimeout(() => {
                                window.location.reload();
                            }, 1500);
                        }
                    })
                    .catch(error => {
                        showStatus('登出错误: ' + error.message, 'error');
                    });
                });
            }
            
            // 检查状态
            if (checkStatusBtn) {
                checkStatusBtn.addEventListener('click', function() {
                    const formData = new FormData();
                    formData.append('action', 'check_status');
                    
                    fetch('cookie_test.php', {
                        method: 'POST',
                        body: formData,
                        credentials: 'include' // 确保发送Cookie
                    })
                    .then(response => response.json())
                    .then(data => {
                        let statusMessage = `登录状态: ${data.logged_in ? '已登录' : '未登录'}<br>`;
                        statusMessage += `令牌状态: ${data.token_valid ? '有效' : '无效'}`;
                        
                        showStatus(statusMessage, data.logged_in ? 'success' : 'info');
                        
                        // 显示Cookie信息
                        if (data.cookies) {
                            cookieDisplay.textContent = JSON.stringify(data.cookies, null, 2);
                            cookieInfo.classList.remove('hidden');
                        }
                    })
                    .catch(error => {
                        showStatus('状态检查错误: ' + error.message, 'error');
                    });
                });
            }
        });
    </script>
</body>
</html>