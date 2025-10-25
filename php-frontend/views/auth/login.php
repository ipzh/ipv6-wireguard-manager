<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= APP_NAME ?> - 登录</title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <style>
        :root {
            --primary-color: #6366f1;
            --primary-dark: #4f46e5;
            --secondary-color: #64748b;
            --success-color: #10b981;
            --danger-color: #ef4444;
            --warning-color: #f59e0b;
            --info-color: #06b6d4;
            --light-color: #f8fafc;
            --dark-color: #1e293b;
            --border-color: #e2e8f0;
            --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
            --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
            --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
            --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 1rem;
            position: relative;
            overflow-x: hidden;
        }

        /* 背景动画 */
        body::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse"><path d="M 10 0 L 0 0 0 10" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="0.5"/></pattern></defs><rect width="100" height="100" fill="url(%23grid)"/></svg>');
            animation: float 20s ease-in-out infinite;
        }

        @keyframes float {
            0%, 100% { transform: translateY(0px) rotate(0deg); }
            50% { transform: translateY(-20px) rotate(1deg); }
        }

        /* 登录容器 */
        .login-container {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(20px);
            border-radius: 24px;
            box-shadow: var(--shadow-xl);
            border: 1px solid rgba(255, 255, 255, 0.2);
            width: 100%;
            max-width: 420px;
            padding: 2.5rem;
            position: relative;
            z-index: 10;
            animation: slideUp 0.6s ease-out;
        }

        @keyframes slideUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        /* 头部区域 */
        .login-header {
            text-align: center;
            margin-bottom: 2rem;
        }

        .logo-container {
            position: relative;
            display: inline-block;
            margin-bottom: 1.5rem;
        }

        .logo-icon {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, var(--primary-color), var(--primary-dark));
            border-radius: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 2rem;
            box-shadow: var(--shadow-lg);
            position: relative;
            overflow: hidden;
        }

        .logo-icon::before {
            content: '';
            position: absolute;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: linear-gradient(45deg, transparent, rgba(255,255,255,0.1), transparent);
            transform: rotate(45deg);
            animation: shine 3s ease-in-out infinite;
        }

        @keyframes shine {
            0% { transform: translateX(-100%) translateY(-100%) rotate(45deg); }
            50% { transform: translateX(100%) translateY(100%) rotate(45deg); }
            100% { transform: translateX(-100%) translateY(-100%) rotate(45deg); }
        }

        .app-title {
            font-size: 1.75rem;
            font-weight: 700;
            color: var(--dark-color);
            margin-bottom: 0.5rem;
            letter-spacing: -0.025em;
        }

        .app-subtitle {
            color: var(--secondary-color);
            font-size: 0.95rem;
            font-weight: 400;
        }

        /* 表单样式 */
        .form-group {
            margin-bottom: 1.5rem;
            position: relative;
        }

        .form-label {
            font-weight: 500;
            color: var(--dark-color);
            margin-bottom: 0.5rem;
            font-size: 0.875rem;
            letter-spacing: 0.025em;
        }

        .input-group {
            position: relative;
        }

        .input-group-text {
            background: var(--light-color);
            border: 2px solid var(--border-color);
            border-right: none;
            color: var(--secondary-color);
            padding: 0.875rem 1rem;
            transition: all 0.3s ease;
        }

        .form-control {
            border: 2px solid var(--border-color);
            border-left: none;
            padding: 0.875rem 1rem;
            font-size: 0.95rem;
            border-radius: 0 12px 12px 0;
            transition: all 0.3s ease;
            background: white;
        }

        .form-control:focus {
            border-color: var(--primary-color);
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
            outline: none;
        }

        .form-control:focus + .input-group-text {
            border-color: var(--primary-color);
        }

        .input-group:focus-within .input-group-text {
            border-color: var(--primary-color);
            background: rgba(99, 102, 241, 0.05);
            color: var(--primary-color);
        }

        /* 密码显示按钮 */
        .password-toggle {
            background: var(--light-color);
            border: 2px solid var(--border-color);
            border-left: none;
            color: var(--secondary-color);
            padding: 0.875rem 1rem;
            cursor: pointer;
            transition: all 0.3s ease;
            border-radius: 0 12px 12px 0;
        }

        .password-toggle:hover {
            background: rgba(99, 102, 241, 0.05);
            color: var(--primary-color);
            border-color: var(--primary-color);
        }

        /* 记住我 */
        .form-check {
            margin-bottom: 1.5rem;
        }

        .form-check-input {
            width: 1.125rem;
            height: 1.125rem;
            border: 2px solid var(--border-color);
            border-radius: 6px;
            margin-top: 0.125rem;
        }

        .form-check-input:checked {
            background-color: var(--primary-color);
            border-color: var(--primary-color);
        }

        .form-check-input:focus {
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
        }

        .form-check-label {
            color: var(--secondary-color);
            font-size: 0.875rem;
            font-weight: 400;
            margin-left: 0.5rem;
        }

        /* 登录按钮 */
        .login-btn {
            width: 100%;
            background: linear-gradient(135deg, var(--primary-color), var(--primary-dark));
            border: none;
            border-radius: 12px;
            padding: 0.875rem 1.5rem;
            font-size: 1rem;
            font-weight: 600;
            color: white;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
            box-shadow: var(--shadow-md);
        }

        .login-btn:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-lg);
            background: linear-gradient(135deg, var(--primary-dark), #3730a3);
        }

        .login-btn:active {
            transform: translateY(0);
        }

        .login-btn:disabled {
            opacity: 0.7;
            cursor: not-allowed;
            transform: none;
        }

        .btn-spinner {
            width: 1rem;
            height: 1rem;
            border: 2px solid transparent;
            border-top: 2px solid currentColor;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin-right: 0.5rem;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        /* 提示信息 */
        .help-text {
            text-align: center;
            margin-top: 1.5rem;
            padding: 1rem;
            background: rgba(99, 102, 241, 0.05);
            border-radius: 12px;
            border: 1px solid rgba(99, 102, 241, 0.1);
        }

        .help-text small {
            color: var(--secondary-color);
            font-size: 0.8rem;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.5rem;
        }

        /* 系统状态 */
        .status-card {
            background: rgba(255, 255, 255, 0.8);
            border-radius: 16px;
            padding: 1.25rem;
            margin-top: 1.5rem;
            border: 1px solid rgba(255, 255, 255, 0.2);
            backdrop-filter: blur(10px);
        }

        .status-title {
            font-size: 0.875rem;
            font-weight: 600;
            color: var(--dark-color);
            margin-bottom: 0.75rem;
            text-align: center;
        }

        .status-indicator {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.5rem;
            font-size: 0.875rem;
        }

        .status-success {
            color: var(--success-color);
        }

        .status-error {
            color: var(--danger-color);
        }

        .status-loading {
            color: var(--primary-color);
        }

        /* 错误提示 */
        .alert {
            border: none;
            border-radius: 12px;
            padding: 1rem;
            margin-bottom: 1.5rem;
            font-size: 0.875rem;
            animation: slideDown 0.3s ease-out;
        }

        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateY(-10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .alert-danger {
            background: rgba(239, 68, 68, 0.1);
            color: var(--danger-color);
            border: 1px solid rgba(239, 68, 68, 0.2);
        }

        /* 响应式设计 */
        @media (max-width: 480px) {
            .login-container {
                padding: 2rem 1.5rem;
                margin: 1rem;
                border-radius: 20px;
            }

            .logo-icon {
                width: 70px;
                height: 70px;
                font-size: 1.75rem;
            }

            .app-title {
                font-size: 1.5rem;
            }

            .form-control,
            .input-group-text,
            .password-toggle {
                padding: 0.75rem 0.875rem;
            }
        }

        @media (max-width: 360px) {
            .login-container {
                padding: 1.5rem 1rem;
            }

            .logo-icon {
                width: 60px;
                height: 60px;
                font-size: 1.5rem;
            }

            .app-title {
                font-size: 1.25rem;
            }
        }

        /* 深色模式支持 */
        @media (prefers-color-scheme: dark) {
            .login-container {
                background: rgba(30, 41, 59, 0.95);
                border: 1px solid rgba(255, 255, 255, 0.1);
            }

            .app-title {
                color: white;
            }

            .form-control {
                background: rgba(51, 65, 85, 0.8);
                border-color: rgba(255, 255, 255, 0.1);
                color: white;
            }

            .form-control:focus {
                background: rgba(51, 65, 85, 1);
                border-color: var(--primary-color);
            }

            .input-group-text {
                background: rgba(51, 65, 85, 0.8);
                border-color: rgba(255, 255, 255, 0.1);
                color: rgba(255, 255, 255, 0.7);
            }

            .password-toggle {
                background: rgba(51, 65, 85, 0.8);
                border-color: rgba(255, 255, 255, 0.1);
                color: rgba(255, 255, 255, 0.7);
            }

            .form-label {
                color: rgba(255, 255, 255, 0.9);
            }

            .form-check-label {
                color: rgba(255, 255, 255, 0.7);
            }

            .help-text {
                background: rgba(99, 102, 241, 0.1);
                border-color: rgba(99, 102, 241, 0.2);
            }

            .help-text small {
                color: rgba(255, 255, 255, 0.7);
            }

            .status-card {
                background: rgba(30, 41, 59, 0.8);
                border-color: rgba(255, 255, 255, 0.1);
            }

            .status-title {
                color: white;
            }
        }

        /* 高对比度模式 */
        @media (prefers-contrast: high) {
            .login-container {
                border: 2px solid var(--dark-color);
            }

            .form-control,
            .input-group-text,
            .password-toggle {
                border-width: 2px;
            }
        }

        /* 减少动画模式 */
        @media (prefers-reduced-motion: reduce) {
            * {
                animation-duration: 0.01ms !important;
                animation-iteration-count: 1 !important;
                transition-duration: 0.01ms !important;
            }
        }
    </style>
</head>
<body>
    <div class="login-container">
        <!-- 头部区域 -->
        <div class="login-header">
            <div class="logo-container">
                <div class="logo-icon">
                    <i class="bi bi-shield-lock"></i>
                </div>
            </div>
            <h1 class="app-title"><?= APP_NAME ?></h1>
            <p class="app-subtitle">安全登录到您的管理控制台</p>
        </div>

        <!-- 错误提示 -->
        <?php if (isset($error)): ?>
        <div class="alert alert-danger" role="alert">
            <i class="bi bi-exclamation-triangle me-2"></i>
            <?= htmlspecialchars($error) ?>
        </div>
        <?php endif; ?>

        <!-- 登录表单 -->
        <form method="POST" action="/login" id="loginForm" novalidate>
            <input type="hidden" name="_token" value="<?= $this->auth->generateCsrfToken() ?>">
            
            <!-- 用户名输入 -->
            <div class="form-group">
                <label for="username" class="form-label">用户名</label>
                <div class="input-group">
                    <span class="input-group-text">
                        <i class="bi bi-person"></i>
                    </span>
                    <input type="text" 
                           class="form-control" 
                           id="username" 
                           name="username" 
                           value="<?= htmlspecialchars($_POST['username'] ?? '') ?>" 
                           placeholder="请输入用户名"
                           required 
                           autofocus
                           autocomplete="username">
                </div>
            </div>
            
            <!-- 密码输入 -->
            <div class="form-group">
                <label for="password" class="form-label">密码</label>
                <div class="input-group">
                    <span class="input-group-text">
                        <i class="bi bi-lock"></i>
                    </span>
                    <input type="password" 
                           class="form-control" 
                           id="password" 
                           name="password" 
                           placeholder="请输入密码"
                           required
                           autocomplete="current-password">
                    <button class="password-toggle" 
                            type="button" 
                            id="togglePassword"
                            aria-label="显示/隐藏密码">
                        <i class="bi bi-eye" id="toggleIcon"></i>
                    </button>
                </div>
            </div>
            
            <!-- 记住我 -->
            <div class="form-check">
                <input type="checkbox" 
                       class="form-check-input" 
                       id="rememberMe" 
                       name="remember_me">
                <label class="form-check-label" for="rememberMe">
                    记住我
                </label>
            </div>
            
            <!-- 登录按钮 -->
            <button type="submit" class="login-btn" id="loginBtn">
                <span class="btn-spinner d-none" id="loginSpinner"></span>
                <i class="bi bi-box-arrow-in-right me-2"></i>
                <span id="loginText">登录</span>
            </button>
        </form>
        
        <!-- MFA验证表单 -->
        <form method="POST" action="/mfa-verify" id="mfaForm" class="d-none" novalidate>
            <input type="hidden" name="_token" value="<?= $this->auth->generateCsrfToken() ?>">
            <input type="hidden" name="session_id" id="mfaSessionId">
            
            <div class="form-group">
                <label for="mfaCode" class="form-label">验证码</label>
                <div class="input-group">
                    <span class="input-group-text">
                        <i class="bi bi-shield-check"></i>
                    </span>
                    <input type="text" 
                           class="form-control" 
                           id="mfaCode" 
                           name="mfa_code" 
                           placeholder="请输入6位验证码"
                           maxlength="6"
                           pattern="[0-9]{6}"
                           required
                           autocomplete="one-time-code">
                </div>
                <small class="form-text text-muted">
                    请输入您的身份验证器应用中的6位数字验证码
                </small>
            </div>
            
            <div class="form-group">
                <div class="row">
                    <div class="col-6">
                        <button type="button" class="btn btn-outline-secondary w-100" id="backToLogin">
                            <i class="bi bi-arrow-left me-2"></i>返回登录
                        </button>
                    </div>
                    <div class="col-6">
                        <button type="submit" class="login-btn w-100" id="mfaBtn">
                            <span class="btn-spinner d-none" id="mfaSpinner"></span>
                            <i class="bi bi-check-circle me-2"></i>
                            <span id="mfaText">验证</span>
                        </button>
                    </div>
                </div>
            </div>
            
            <div class="help-text">
                <small>
                    <i class="bi bi-info-circle"></i>
                    如果没有身份验证器，请联系管理员获取备份代码
                </small>
            </div>
        </form>
        
        <!-- 帮助信息 -->
        <div class="help-text">
            <small>
                <i class="bi bi-info-circle"></i>
                默认管理员账户: admin / admin123
            </small>
        </div>
        
        <!-- 系统状态 -->
        <div class="status-card">
            <div class="status-title">系统状态</div>
            <div class="status-indicator" id="apiStatus">
                <div class="spinner-border spinner-border-sm status-loading" role="status">
                    <span class="visually-hidden">检查中...</span>
                </div>
                <span>检查API连接...</span>
            </div>
        </div>
    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    <script>
        // API基础URL
        const API_BASE_URL = '<?= API_BASE_URL ?>';
        
        document.addEventListener('DOMContentLoaded', function() {
            // 密码显示/隐藏切换
            const togglePassword = document.getElementById('togglePassword');
            const passwordInput = document.getElementById('password');
            const toggleIcon = document.getElementById('toggleIcon');
            
            togglePassword.addEventListener('click', function() {
                const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
                passwordInput.setAttribute('type', type);
                
                if (type === 'text') {
                    toggleIcon.className = 'bi bi-eye-slash';
                    togglePassword.setAttribute('aria-label', '隐藏密码');
                } else {
                    toggleIcon.className = 'bi bi-eye';
                    togglePassword.setAttribute('aria-label', '显示密码');
                }
            });
            
            // 表单提交处理
            const loginForm = document.getElementById('loginForm');
            const loginBtn = document.getElementById('loginBtn');
            const loginSpinner = document.getElementById('loginSpinner');
            const loginText = document.getElementById('loginText');
            
            loginForm.addEventListener('submit', function(e) {
                e.preventDefault();
                
                // 显示加载状态
                loginBtn.disabled = true;
                loginSpinner.classList.remove('d-none');
                loginText.textContent = '登录中...';
                
                // 如果API连接失败，阻止提交
                if (!window.apiConnected) {
                    showMessage('API服务连接失败，请检查后端服务状态', 'error');
                    resetLoginButton();
                    return;
                }
                
                // 提交登录表单
                const formData = new FormData(loginForm);
                
                fetch(`${API_BASE_URL}/auth/login`, {
                    method: 'POST',
                    body: formData
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        if (data.requires_mfa) {
                            // 需要MFA验证
                            showMfaForm(data.session_id);
                        } else {
                            // 直接登录成功
                            window.location.href = '/dashboard';
                        }
                    } else {
                        showMessage(data.message || '登录失败', 'error');
                        resetLoginButton();
                    }
                })
                .catch(error => {
                    showMessage('登录请求失败: ' + error.message, 'error');
                    resetLoginButton();
                });
            });
            
            // 重置登录按钮状态
            function resetLoginButton() {
                loginBtn.disabled = false;
                loginSpinner.classList.add('d-none');
                loginText.textContent = '登录';
            }
            
            // 显示MFA表单
            function showMfaForm(sessionId) {
                document.getElementById('loginForm').classList.add('d-none');
                document.getElementById('mfaForm').classList.remove('d-none');
                document.getElementById('mfaSessionId').value = sessionId;
                document.getElementById('mfaCode').focus();
                
                // 重置登录按钮
                resetLoginButton();
            }
            
            // 返回登录表单
            function backToLogin() {
                document.getElementById('mfaForm').classList.add('d-none');
                document.getElementById('loginForm').classList.remove('d-none');
                document.getElementById('username').focus();
            }
            
            // MFA表单处理
            const mfaForm = document.getElementById('mfaForm');
            const mfaBtn = document.getElementById('mfaBtn');
            const mfaSpinner = document.getElementById('mfaSpinner');
            const mfaText = document.getElementById('mfaText');
            
            mfaForm.addEventListener('submit', function(e) {
                e.preventDefault();
                
                // 显示加载状态
                mfaBtn.disabled = true;
                mfaSpinner.classList.remove('d-none');
                mfaText.textContent = '验证中...';
                
                const formData = new FormData(mfaForm);
                
                fetch(`${API_BASE_URL}/mfa/verify`, {
                    method: 'POST',
                    body: formData
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        window.location.href = '/dashboard';
                    } else {
                        showMessage(data.message || '验证失败', 'error');
                        resetMfaButton();
                    }
                })
                .catch(error => {
                    showMessage('验证请求失败: ' + error.message, 'error');
                    resetMfaButton();
                });
            });
            
            // 重置MFA按钮状态
            function resetMfaButton() {
                mfaBtn.disabled = false;
                mfaSpinner.classList.add('d-none');
                mfaText.textContent = '验证';
            }
            
            // 返回登录按钮事件
            document.getElementById('backToLogin').addEventListener('click', backToLogin);
            
            // MFA验证码自动格式化
            document.getElementById('mfaCode').addEventListener('input', function(e) {
                let value = e.target.value.replace(/\D/g, ''); // 只保留数字
                if (value.length > 6) {
                    value = value.substring(0, 6);
                }
                e.target.value = value;
                
                // 自动提交
                if (value.length === 6) {
                    setTimeout(() => {
                        mfaForm.submit();
                    }, 500);
                }
            });
            
            // 检查API状态
            checkApiStatus();
            
            // 回车键登录
            document.addEventListener('keypress', function(e) {
                if (e.key === 'Enter' && !loginBtn.disabled) {
                    loginForm.submit();
                }
            });
            
            // 输入框焦点效果
            const inputs = document.querySelectorAll('.form-control');
            inputs.forEach(input => {
                input.addEventListener('focus', function() {
                    this.parentElement.classList.add('focused');
                });
                
                input.addEventListener('blur', function() {
                    this.parentElement.classList.remove('focused');
                });
            });
        });

        function checkApiStatus() {
            // 使用API代理端点
            fetch(`${API_BASE_URL}/health`)
                .then(response => {
                    if (!response.ok) {
                        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                    }
                    return response.json();
                })
                .then(data => {
                    const statusDiv = document.getElementById('apiStatus');
                    if (data.success !== false && data.status === 'healthy') {
                        statusDiv.innerHTML = `
                            <i class="bi bi-check-circle status-success"></i>
                            <span class="status-success">API连接正常</span>
                        `;
                        window.apiConnected = true;
                    } else {
                        statusDiv.innerHTML = `
                            <i class="bi bi-x-circle status-error"></i>
                            <span class="status-error">API状态异常</span>
                        `;
                        window.apiConnected = false;
                    }
                })
                .catch(error => {
                    const statusDiv = document.getElementById('apiStatus');
                    statusDiv.innerHTML = `
                        <i class="bi bi-x-circle status-error"></i>
                        <span class="status-error">API连接失败: ${error.message}</span>
                    `;
                    window.apiConnected = false;
                    console.error('API连接错误:', error);
                });
        }

        function showMessage(message, type = 'info') {
            // 创建消息提示
            const alertDiv = document.createElement('div');
            alertDiv.className = `alert alert-${type === 'error' ? 'danger' : type}`;
            alertDiv.innerHTML = `
                <i class="bi bi-${type === 'error' ? 'exclamation-triangle' : 'info-circle'} me-2"></i>
                ${message}
            `;
            
            // 插入到表单前面
            const form = document.getElementById('loginForm');
            form.parentNode.insertBefore(alertDiv, form);
            
            // 3秒后自动移除
            setTimeout(() => {
                alertDiv.remove();
            }, 3000);
        }
    </script>
</body>
</html>
