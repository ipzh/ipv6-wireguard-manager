<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $pageTitle ?> - <?= APP_NAME ?></title>
    
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
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: var(--light-color);
            color: var(--dark-color);
            line-height: 1.6;
        }

        .password-container {
            max-width: 600px;
            margin: 2rem auto;
            padding: 0 1rem;
        }

        .password-card {
            background: white;
            border-radius: 12px;
            padding: 2rem;
            box-shadow: var(--shadow-md);
            border: 1px solid var(--border-color);
        }

        .password-header {
            text-align: center;
            margin-bottom: 2rem;
        }

        .password-header h1 {
            font-size: 1.875rem;
            font-weight: 700;
            color: var(--dark-color);
            margin-bottom: 0.5rem;
        }

        .password-header p {
            color: var(--secondary-color);
            font-size: 1rem;
        }

        .form-group {
            margin-bottom: 1.5rem;
        }

        .form-label {
            font-weight: 500;
            color: var(--dark-color);
            margin-bottom: 0.5rem;
            display: block;
        }

        .form-control {
            width: 100%;
            padding: 0.75rem 1rem;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            font-size: 1rem;
            transition: all 0.2s ease;
            background-color: white;
        }

        .form-control:focus {
            outline: none;
            border-color: var(--primary-color);
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
        }

        .form-control.is-invalid {
            border-color: var(--danger-color);
        }

        .form-control.is-valid {
            border-color: var(--success-color);
        }

        .invalid-feedback {
            color: var(--danger-color);
            font-size: 0.875rem;
            margin-top: 0.25rem;
            display: block;
        }

        .valid-feedback {
            color: var(--success-color);
            font-size: 0.875rem;
            margin-top: 0.25rem;
            display: block;
        }

        .password-strength {
            margin-top: 0.5rem;
        }

        .strength-bar {
            height: 4px;
            background-color: var(--border-color);
            border-radius: 2px;
            overflow: hidden;
            margin-bottom: 0.5rem;
        }

        .strength-fill {
            height: 100%;
            transition: all 0.3s ease;
            border-radius: 2px;
        }

        .strength-weak { background-color: var(--danger-color); width: 25%; }
        .strength-fair { background-color: var(--warning-color); width: 50%; }
        .strength-good { background-color: var(--info-color); width: 75%; }
        .strength-strong { background-color: var(--success-color); width: 100%; }

        .strength-text {
            font-size: 0.875rem;
            font-weight: 500;
        }

        .strength-weak-text { color: var(--danger-color); }
        .strength-fair-text { color: var(--warning-color); }
        .strength-good-text { color: var(--info-color); }
        .strength-strong-text { color: var(--success-color); }

        .btn {
            padding: 0.75rem 1.5rem;
            border-radius: 8px;
            font-weight: 500;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            transition: all 0.2s ease;
            border: none;
            cursor: pointer;
            font-size: 1rem;
        }

        .btn-primary {
            background: var(--primary-color);
            color: white;
        }

        .btn-primary:hover {
            background: var(--primary-dark);
            color: white;
            transform: translateY(-1px);
        }

        .btn-outline {
            background: transparent;
            color: var(--primary-color);
            border: 1px solid var(--primary-color);
        }

        .btn-outline:hover {
            background: var(--primary-color);
            color: white;
        }

        .btn:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none !important;
        }

        .alert {
            padding: 1rem;
            border-radius: 8px;
            margin-bottom: 1.5rem;
            border: 1px solid;
        }

        .alert-success {
            background: #dcfce7;
            color: #166534;
            border-color: #bbf7d0;
        }

        .alert-danger {
            background: #fef2f2;
            color: #dc2626;
            border-color: #fecaca;
        }

        .password-requirements {
            background: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 1rem;
            margin-top: 1rem;
        }

        .password-requirements h6 {
            font-weight: 600;
            color: var(--dark-color);
            margin-bottom: 0.5rem;
        }

        .requirement-item {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            margin-bottom: 0.25rem;
            font-size: 0.875rem;
        }

        .requirement-item.valid {
            color: var(--success-color);
        }

        .requirement-item.invalid {
            color: var(--secondary-color);
        }

        .form-actions {
            display: flex;
            gap: 1rem;
            justify-content: flex-end;
            margin-top: 2rem;
        }

        @media (max-width: 768px) {
            .password-container {
                margin: 1rem auto;
                padding: 0 0.5rem;
            }
            
            .password-card {
                padding: 1.5rem;
            }
            
            .form-actions {
                flex-direction: column;
            }
            
            .btn {
                width: 100%;
                justify-content: center;
            }
        }
    </style>
</head>
<body>
    <div class="password-container">
        <div class="password-card">
            <!-- 消息提示 -->
            <?php if (isset($_SESSION['success'])): ?>
                <div class="alert alert-success">
                    <i class="bi bi-check-circle"></i>
                    <?= htmlspecialchars($_SESSION['success']) ?>
                </div>
                <?php unset($_SESSION['success']); ?>
            <?php endif; ?>

            <?php if (isset($_SESSION['error'])): ?>
                <div class="alert alert-danger">
                    <i class="bi bi-exclamation-triangle"></i>
                    <?= htmlspecialchars($_SESSION['error']) ?>
                </div>
                <?php unset($_SESSION['error']); ?>
            <?php endif; ?>

            <!-- 页面头部 -->
            <div class="password-header">
                <h1><i class="bi bi-key"></i> 修改密码</h1>
                <p>为了您的账户安全，请定期更新密码</p>
            </div>

            <!-- 修改密码表单 -->
            <form method="POST" action="/profile/change-password" id="changePasswordForm">
                <input type="hidden" name="_token" value="<?= $auth->generateCsrfToken() ?>">
                
                <div class="form-group">
                    <label for="old_password" class="form-label">
                        <i class="bi bi-lock"></i> 当前密码
                    </label>
                    <input type="password" 
                           class="form-control" 
                           id="old_password" 
                           name="old_password" 
                           required
                           placeholder="请输入当前密码">
                </div>

                <div class="form-group">
                    <label for="new_password" class="form-label">
                        <i class="bi bi-key"></i> 新密码
                    </label>
                    <input type="password" 
                           class="form-control" 
                           id="new_password" 
                           name="new_password" 
                           required
                           minlength="6"
                           placeholder="请输入新密码">
                    
                    <!-- 密码强度指示器 -->
                    <div class="password-strength">
                        <div class="strength-bar">
                            <div class="strength-fill" id="strengthFill"></div>
                        </div>
                        <div class="strength-text" id="strengthText">请输入密码</div>
                    </div>
                </div>

                <div class="form-group">
                    <label for="confirm_password" class="form-label">
                        <i class="bi bi-check-circle"></i> 确认新密码
                    </label>
                    <input type="password" 
                           class="form-control" 
                           id="confirm_password" 
                           name="confirm_password" 
                           required
                           placeholder="请再次输入新密码">
                    <div class="invalid-feedback" id="confirmError" style="display: none;">
                        两次输入的密码不一致
                    </div>
                </div>

                <!-- 密码要求 -->
                <div class="password-requirements">
                    <h6><i class="bi bi-info-circle"></i> 密码要求</h6>
                    <div class="requirement-item" id="req-length">
                        <i class="bi bi-circle"></i>
                        至少6个字符
                    </div>
                    <div class="requirement-item" id="req-match">
                        <i class="bi bi-circle"></i>
                        两次输入的密码一致
                    </div>
                </div>

                <!-- 表单操作按钮 -->
                <div class="form-actions">
                    <a href="/profile" class="btn btn-outline">
                        <i class="bi bi-arrow-left"></i>
                        返回
                    </a>
                    <button type="submit" class="btn btn-primary" id="submitBtn" disabled>
                        <i class="bi bi-check-lg"></i>
                        修改密码
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const oldPassword = document.getElementById('old_password');
            const newPassword = document.getElementById('new_password');
            const confirmPassword = document.getElementById('confirm_password');
            const submitBtn = document.getElementById('submitBtn');
            const strengthFill = document.getElementById('strengthFill');
            const strengthText = document.getElementById('strengthText');
            const reqLength = document.getElementById('req-length');
            const reqMatch = document.getElementById('req-match');
            const confirmError = document.getElementById('confirmError');

            // 密码强度检查
            function checkPasswordStrength(password) {
                let strength = 0;
                let strengthClass = '';
                let strengthTextContent = '';

                if (password.length >= 6) strength++;
                if (password.length >= 8) strength++;
                if (/[A-Z]/.test(password)) strength++;
                if (/[a-z]/.test(password)) strength++;
                if (/[0-9]/.test(password)) strength++;
                if (/[^A-Za-z0-9]/.test(password)) strength++;

                if (strength < 2) {
                    strengthClass = 'strength-weak';
                    strengthTextContent = '密码强度：弱';
                } else if (strength < 4) {
                    strengthClass = 'strength-fair';
                    strengthTextContent = '密码强度：一般';
                } else if (strength < 5) {
                    strengthClass = 'strength-good';
                    strengthTextContent = '密码强度：良好';
                } else {
                    strengthClass = 'strength-strong';
                    strengthTextContent = '密码强度：强';
                }

                strengthFill.className = 'strength-fill ' + strengthClass;
                strengthText.textContent = strengthTextContent;
                strengthText.className = 'strength-text ' + strengthClass.replace('strength-', 'strength-') + '-text';
            }

            // 检查密码匹配
            function checkPasswordMatch() {
                const match = newPassword.value === confirmPassword.value;
                const hasValue = confirmPassword.value.length > 0;
                
                if (hasValue && !match) {
                    confirmPassword.classList.add('is-invalid');
                    confirmError.style.display = 'block';
                    reqMatch.classList.remove('valid');
                    reqMatch.classList.add('invalid');
                    reqMatch.innerHTML = '<i class="bi bi-x-circle"></i> 两次输入的密码不一致';
                } else if (hasValue && match) {
                    confirmPassword.classList.remove('is-invalid');
                    confirmPassword.classList.add('is-valid');
                    confirmError.style.display = 'none';
                    reqMatch.classList.remove('invalid');
                    reqMatch.classList.add('valid');
                    reqMatch.innerHTML = '<i class="bi bi-check-circle"></i> 两次输入的密码一致';
                } else {
                    confirmPassword.classList.remove('is-invalid', 'is-valid');
                    confirmError.style.display = 'none';
                    reqMatch.classList.remove('valid', 'invalid');
                    reqMatch.innerHTML = '<i class="bi bi-circle"></i> 两次输入的密码一致';
                }
            }

            // 检查密码长度
            function checkPasswordLength() {
                const isValid = newPassword.value.length >= 6;
                
                if (newPassword.value.length > 0) {
                    if (isValid) {
                        newPassword.classList.remove('is-invalid');
                        newPassword.classList.add('is-valid');
                        reqLength.classList.remove('invalid');
                        reqLength.classList.add('valid');
                        reqLength.innerHTML = '<i class="bi bi-check-circle"></i> 至少6个字符';
                    } else {
                        newPassword.classList.remove('is-valid');
                        newPassword.classList.add('is-invalid');
                        reqLength.classList.remove('valid');
                        reqLength.classList.add('invalid');
                        reqLength.innerHTML = '<i class="bi bi-x-circle"></i> 至少6个字符';
                    }
                } else {
                    newPassword.classList.remove('is-invalid', 'is-valid');
                    reqLength.classList.remove('valid', 'invalid');
                    reqLength.innerHTML = '<i class="bi bi-circle"></i> 至少6个字符';
                }
            }

            // 检查表单有效性
            function checkFormValidity() {
                const isOldPasswordValid = oldPassword.value.length > 0;
                const isNewPasswordValid = newPassword.value.length >= 6;
                const isConfirmPasswordValid = confirmPassword.value === newPassword.value && confirmPassword.value.length > 0;
                
                submitBtn.disabled = !(isOldPasswordValid && isNewPasswordValid && isConfirmPasswordValid);
            }

            // 事件监听器
            newPassword.addEventListener('input', function() {
                checkPasswordStrength(this.value);
                checkPasswordLength();
                checkPasswordMatch();
                checkFormValidity();
            });

            confirmPassword.addEventListener('input', function() {
                checkPasswordMatch();
                checkFormValidity();
            });

            oldPassword.addEventListener('input', checkFormValidity);

            // 表单提交
            document.getElementById('changePasswordForm').addEventListener('submit', function(e) {
                if (submitBtn.disabled) {
                    e.preventDefault();
                    return false;
                }
                
                // 显示加载状态
                submitBtn.disabled = true;
                submitBtn.innerHTML = '<i class="bi bi-hourglass-split"></i> 修改中...';
            });
        });
    </script>
</body>
</html>
