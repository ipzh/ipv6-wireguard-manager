<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= APP_NAME ?> - 安全设置</title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    
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
        }

        .security-card {
            border: none;
            border-radius: 16px;
            box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
            transition: all 0.3s ease;
        }

        .security-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1);
        }

        .security-icon {
            width: 60px;
            height: 60px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
            color: white;
        }

        .password-strength {
            height: 8px;
            border-radius: 4px;
            transition: all 0.3s ease;
        }

        .strength-weak { background-color: var(--danger-color); }
        .strength-medium { background-color: var(--warning-color); }
        .strength-strong { background-color: var(--success-color); }

        .mfa-qr-code {
            max-width: 200px;
            margin: 0 auto;
        }

        .backup-codes {
            background: var(--light-color);
            border-radius: 8px;
            padding: 1rem;
            font-family: 'Courier New', monospace;
            font-size: 0.9rem;
        }

        .security-alert {
            border-left: 4px solid var(--warning-color);
            background: rgba(245, 158, 11, 0.1);
        }

        .security-success {
            border-left: 4px solid var(--success-color);
            background: rgba(16, 185, 129, 0.1);
        }
    </style>
</head>
<body class="bg-light">
    <!-- 导航栏 -->
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
        <div class="container-fluid">
            <a class="navbar-brand" href="/dashboard">
                <i class="bi bi-shield-lock me-2"></i>
                <?= APP_NAME ?>
            </a>
            <div class="navbar-nav ms-auto">
                <a class="nav-link" href="/dashboard">
                    <i class="bi bi-house me-1"></i>仪表板
                </a>
                <a class="nav-link active" href="/security">
                    <i class="bi bi-shield-check me-1"></i>安全设置
                </a>
                <a class="nav-link" href="/logout">
                    <i class="bi bi-box-arrow-right me-1"></i>退出
                </a>
            </div>
        </div>
    </nav>

    <div class="container-fluid py-4">
        <div class="row">
            <!-- 侧边栏 -->
            <div class="col-md-3">
                <div class="card security-card">
                    <div class="card-header">
                        <h5 class="mb-0">
                            <i class="bi bi-gear me-2"></i>安全设置
                        </h5>
                    </div>
                    <div class="list-group list-group-flush">
                        <a href="#password" class="list-group-item list-group-item-action active" data-bs-toggle="tab">
                            <i class="bi bi-key me-2"></i>密码管理
                        </a>
                        <a href="#mfa" class="list-group-item list-group-item-action" data-bs-toggle="tab">
                            <i class="bi bi-shield-check me-2"></i>多因素认证
                        </a>
                        <a href="#sessions" class="list-group-item list-group-item-action" data-bs-toggle="tab">
                            <i class="bi bi-laptop me-2"></i>会话管理
                        </a>
                        <a href="#security-log" class="list-group-item list-group-item-action" data-bs-toggle="tab">
                            <i class="bi bi-clock-history me-2"></i>安全日志
                        </a>
                    </div>
                </div>
            </div>

            <!-- 主内容区 -->
            <div class="col-md-9">
                <div class="tab-content">
                    <!-- 密码管理 -->
                    <div class="tab-pane fade show active" id="password">
                        <div class="row">
                            <div class="col-12">
                                <div class="card security-card">
                                    <div class="card-header d-flex justify-content-between align-items-center">
                                        <h5 class="mb-0">
                                            <i class="bi bi-key me-2"></i>密码管理
                                        </h5>
                                        <span class="badge bg-success">已启用</span>
                                    </div>
                                    <div class="card-body">
                                        <!-- 密码策略状态 -->
                                        <div class="row mb-4">
                                            <div class="col-md-6">
                                                <div class="security-success p-3 rounded">
                                                    <h6 class="mb-2">
                                                        <i class="bi bi-check-circle me-2"></i>密码策略状态
                                                    </h6>
                                                    <ul class="list-unstyled mb-0">
                                                        <li><i class="bi bi-check text-success me-2"></i>最小长度: 12位</li>
                                                        <li><i class="bi bi-check text-success me-2"></i>包含大小写字母</li>
                                                        <li><i class="bi bi-check text-success me-2"></i>包含数字和特殊字符</li>
                                                        <li><i class="bi bi-check text-success me-2"></i>密码历史检查</li>
                                                    </ul>
                                                </div>
                                            </div>
                                            <div class="col-md-6">
                                                <div class="security-alert p-3 rounded">
                                                    <h6 class="mb-2">
                                                        <i class="bi bi-exclamation-triangle me-2"></i>密码强度
                                                    </h6>
                                                    <div class="mb-2">
                                                        <small class="text-muted">当前密码强度</small>
                                                        <div class="password-strength strength-medium w-100"></div>
                                                    </div>
                                                    <small class="text-muted">建议定期更新密码</small>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- 修改密码表单 -->
                                        <form id="changePasswordForm">
                                            <h6 class="mb-3">修改密码</h6>
                                            <div class="row">
                                                <div class="col-md-6">
                                                    <div class="mb-3">
                                                        <label for="currentPassword" class="form-label">当前密码</label>
                                                        <input type="password" class="form-control" id="currentPassword" required>
                                                    </div>
                                                </div>
                                                <div class="col-md-6">
                                                    <div class="mb-3">
                                                        <label for="newPassword" class="form-label">新密码</label>
                                                        <input type="password" class="form-control" id="newPassword" required>
                                                        <div class="password-strength mt-2" id="passwordStrength"></div>
                                                        <small class="form-text text-muted" id="passwordHint"></small>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="row">
                                                <div class="col-md-6">
                                                    <div class="mb-3">
                                                        <label for="confirmPassword" class="form-label">确认新密码</label>
                                                        <input type="password" class="form-control" id="confirmPassword" required>
                                                    </div>
                                                </div>
                                                <div class="col-md-6 d-flex align-items-end">
                                                    <button type="submit" class="btn btn-primary">
                                                        <i class="bi bi-check me-2"></i>更新密码
                                                    </button>
                                                </div>
                                            </div>
                                        </form>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 多因素认证 -->
                    <div class="tab-pane fade" id="mfa">
                        <div class="row">
                            <div class="col-12">
                                <div class="card security-card">
                                    <div class="card-header d-flex justify-content-between align-items-center">
                                        <h5 class="mb-0">
                                            <i class="bi bi-shield-check me-2"></i>多因素认证
                                        </h5>
                                        <span class="badge bg-success">已启用</span>
                                    </div>
                                    <div class="card-body">
                                        <!-- MFA状态 -->
                                        <div class="row mb-4">
                                            <div class="col-md-6">
                                                <div class="security-icon bg-success mb-3">
                                                    <i class="bi bi-shield-check"></i>
                                                </div>
                                                <h6>身份验证器应用</h6>
                                                <p class="text-muted">使用Google Authenticator、Authy等应用生成验证码</p>
                                                <button class="btn btn-outline-primary btn-sm" id="setupMfaBtn">
                                                    <i class="bi bi-gear me-2"></i>重新设置
                                                </button>
                                            </div>
                                            <div class="col-md-6">
                                                <div class="security-icon bg-info mb-3">
                                                    <i class="bi bi-key"></i>
                                                </div>
                                                <h6>备份代码</h6>
                                                <p class="text-muted">用于在无法使用身份验证器时登录</p>
                                                <button class="btn btn-outline-info btn-sm" id="generateBackupCodesBtn">
                                                    <i class="bi bi-arrow-clockwise me-2"></i>生成新代码
                                                </button>
                                            </div>
                                        </div>

                                        <!-- MFA设置模态框 -->
                                        <div class="modal fade" id="mfaSetupModal" tabindex="-1">
                                            <div class="modal-dialog modal-lg">
                                                <div class="modal-content">
                                                    <div class="modal-header">
                                                        <h5 class="modal-title">设置多因素认证</h5>
                                                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                                    </div>
                                                    <div class="modal-body">
                                                        <div class="text-center mb-4">
                                                            <h6>扫描二维码</h6>
                                                            <div class="mfa-qr-code" id="mfaQrCode">
                                                                <!-- QR码将在这里显示 -->
                                                            </div>
                                                            <p class="text-muted mt-2">使用身份验证器应用扫描此二维码</p>
                                                        </div>
                                                        <form id="mfaSetupForm">
                                                            <div class="mb-3">
                                                                <label for="mfaTestCode" class="form-label">验证码</label>
                                                                <input type="text" class="form-control" id="mfaTestCode" 
                                                                       placeholder="请输入6位验证码" maxlength="6" required>
                                                            </div>
                                                            <div class="d-grid">
                                                                <button type="submit" class="btn btn-primary">
                                                                    <i class="bi bi-check me-2"></i>完成设置
                                                                </button>
                                                            </div>
                                                        </form>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- 备份代码模态框 -->
                                        <div class="modal fade" id="backupCodesModal" tabindex="-1">
                                            <div class="modal-dialog">
                                                <div class="modal-content">
                                                    <div class="modal-header">
                                                        <h5 class="modal-title">备份代码</h5>
                                                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                                    </div>
                                                    <div class="modal-body">
                                                        <div class="alert alert-warning">
                                                            <i class="bi bi-exclamation-triangle me-2"></i>
                                                            请妥善保存这些代码，每个代码只能使用一次。
                                                        </div>
                                                        <div class="backup-codes" id="backupCodesList">
                                                            <!-- 备份代码将在这里显示 -->
                                                        </div>
                                                    </div>
                                                    <div class="modal-footer">
                                                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
                                                        <button type="button" class="btn btn-primary" onclick="printBackupCodes()">
                                                            <i class="bi bi-printer me-2"></i>打印
                                                        </button>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 会话管理 -->
                    <div class="tab-pane fade" id="sessions">
                        <div class="row">
                            <div class="col-12">
                                <div class="card security-card">
                                    <div class="card-header d-flex justify-content-between align-items-center">
                                        <h5 class="mb-0">
                                            <i class="bi bi-laptop me-2"></i>活跃会话
                                        </h5>
                                        <button class="btn btn-outline-danger btn-sm" id="terminateAllSessionsBtn">
                                            <i class="bi bi-x-circle me-2"></i>终止所有会话
                                        </button>
                                    </div>
                                    <div class="card-body">
                                        <div class="table-responsive">
                                            <table class="table table-hover">
                                                <thead>
                                                    <tr>
                                                        <th>设备</th>
                                                        <th>位置</th>
                                                        <th>IP地址</th>
                                                        <th>最后活动</th>
                                                        <th>状态</th>
                                                        <th>操作</th>
                                                    </tr>
                                                </thead>
                                                <tbody id="sessionsTable">
                                                    <!-- 会话数据将在这里显示 -->
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 安全日志 -->
                    <div class="tab-pane fade" id="security-log">
                        <div class="row">
                            <div class="col-12">
                                <div class="card security-card">
                                    <div class="card-header">
                                        <h5 class="mb-0">
                                            <i class="bi bi-clock-history me-2"></i>安全日志
                                        </h5>
                                    </div>
                                    <div class="card-body">
                                        <!-- 日志筛选 -->
                                        <div class="row mb-4">
                                            <div class="col-md-3">
                                                <select class="form-select" id="logLevelFilter">
                                                    <option value="">所有级别</option>
                                                    <option value="info">信息</option>
                                                    <option value="warning">警告</option>
                                                    <option value="error">错误</option>
                                                </select>
                                            </div>
                                            <div class="col-md-3">
                                                <select class="form-select" id="logTypeFilter">
                                                    <option value="">所有类型</option>
                                                    <option value="login">登录</option>
                                                    <option value="password">密码</option>
                                                    <option value="mfa">多因素认证</option>
                                                    <option value="security">安全</option>
                                                </select>
                                            </div>
                                            <div class="col-md-3">
                                                <input type="date" class="form-control" id="logDateFilter">
                                            </div>
                                            <div class="col-md-3">
                                                <button class="btn btn-outline-primary w-100" id="refreshLogsBtn">
                                                    <i class="bi bi-arrow-clockwise me-2"></i>刷新
                                                </button>
                                            </div>
                                        </div>

                                        <!-- 日志列表 -->
                                        <div class="table-responsive">
                                            <table class="table table-hover">
                                                <thead>
                                                    <tr>
                                                        <th>时间</th>
                                                        <th>级别</th>
                                                        <th>类型</th>
                                                        <th>描述</th>
                                                        <th>IP地址</th>
                                                        <th>状态</th>
                                                    </tr>
                                                </thead>
                                                <tbody id="securityLogsTable">
                                                    <!-- 日志数据将在这里显示 -->
                                                </tbody>
                                            </table>
                                        </div>

                                        <!-- 分页 -->
                                        <nav aria-label="日志分页">
                                            <ul class="pagination justify-content-center" id="logsPagination">
                                                <!-- 分页将在这里显示 -->
                                            </ul>
                                        </nav>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // 密码强度检查
            const newPasswordInput = document.getElementById('newPassword');
            const passwordStrength = document.getElementById('passwordStrength');
            const passwordHint = document.getElementById('passwordHint');
            
            newPasswordInput.addEventListener('input', function() {
                const password = this.value;
                const strength = calculatePasswordStrength(password);
                
                passwordStrength.className = 'password-strength mt-2';
                passwordStrength.classList.add(strength.class);
                
                passwordHint.textContent = strength.hint;
            });
            
            // 修改密码表单
            document.getElementById('changePasswordForm').addEventListener('submit', function(e) {
                e.preventDefault();
                
                const currentPassword = document.getElementById('currentPassword').value;
                const newPassword = document.getElementById('newPassword').value;
                const confirmPassword = document.getElementById('confirmPassword').value;
                
                if (newPassword !== confirmPassword) {
                    showAlert('新密码和确认密码不匹配', 'danger');
                    return;
                }
                
                // 提交密码修改请求
                fetch('/api/v1/auth/change-password', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        current_password: currentPassword,
                        new_password: newPassword
                    })
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showAlert('密码修改成功', 'success');
                        this.reset();
                    } else {
                        showAlert(data.message || '密码修改失败', 'danger');
                    }
                })
                .catch(error => {
                    showAlert('请求失败: ' + error.message, 'danger');
                });
            });
            
            // MFA设置
            document.getElementById('setupMfaBtn').addEventListener('click', function() {
                // 获取MFA设置数据
                fetch('/api/v1/mfa/setup')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // 显示QR码
                        document.getElementById('mfaQrCode').innerHTML = 
                            `<img src="${data.qr_code}" alt="MFA QR Code" class="img-fluid">`;
                        
                        // 显示模态框
                        new bootstrap.Modal(document.getElementById('mfaSetupModal')).show();
                    } else {
                        showAlert(data.message || '获取MFA设置失败', 'danger');
                    }
                });
            });
            
            // MFA设置表单
            document.getElementById('mfaSetupForm').addEventListener('submit', function(e) {
                e.preventDefault();
                
                const code = document.getElementById('mfaTestCode').value;
                
                fetch('/api/v1/mfa/enable', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        code: code
                    })
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showAlert('MFA设置成功', 'success');
                        bootstrap.Modal.getInstance(document.getElementById('mfaSetupModal')).hide();
                    } else {
                        showAlert(data.message || 'MFA设置失败', 'danger');
                    }
                });
            });
            
            // 生成备份代码
            document.getElementById('generateBackupCodesBtn').addEventListener('click', function() {
                fetch('/api/v1/mfa/backup-codes', {
                    method: 'POST'
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // 显示备份代码
                        const codesList = document.getElementById('backupCodesList');
                        codesList.innerHTML = data.codes.map(code => 
                            `<div class="text-center mb-2"><code>${code}</code></div>`
                        ).join('');
                        
                        new bootstrap.Modal(document.getElementById('backupCodesModal')).show();
                    } else {
                        showAlert(data.message || '生成备份代码失败', 'danger');
                    }
                });
            });
            
            // 加载会话数据
            loadSessions();
            
            // 加载安全日志
            loadSecurityLogs();
        });
        
        function calculatePasswordStrength(password) {
            let score = 0;
            let hints = [];
            
            if (password.length >= 12) score += 1;
            else hints.push('至少12个字符');
            
            if (/[a-z]/.test(password)) score += 1;
            else hints.push('包含小写字母');
            
            if (/[A-Z]/.test(password)) score += 1;
            else hints.push('包含大写字母');
            
            if (/[0-9]/.test(password)) score += 1;
            else hints.push('包含数字');
            
            if (/[^a-zA-Z0-9]/.test(password)) score += 1;
            else hints.push('包含特殊字符');
            
            if (password.length >= 16) score += 1;
            
            if (score < 3) {
                return { class: 'strength-weak', hint: '密码强度: 弱 - ' + hints.join(', ') };
            } else if (score < 5) {
                return { class: 'strength-medium', hint: '密码强度: 中等 - ' + hints.join(', ') };
            } else {
                return { class: 'strength-strong', hint: '密码强度: 强' };
            }
        }
        
        function loadSessions() {
            fetch('/api/v1/auth/sessions')
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    const tbody = document.getElementById('sessionsTable');
                    tbody.innerHTML = data.sessions.map(session => `
                        <tr>
                            <td>
                                <i class="bi bi-${session.device_type === 'mobile' ? 'phone' : 'laptop'} me-2"></i>
                                ${session.device_name}
                            </td>
                            <td>${session.location}</td>
                            <td><code>${session.ip_address}</code></td>
                            <td>${new Date(session.last_activity).toLocaleString()}</td>
                            <td>
                                <span class="badge bg-${session.is_current ? 'success' : 'secondary'}">
                                    ${session.is_current ? '当前会话' : '其他会话'}
                                </span>
                            </td>
                            <td>
                                ${!session.is_current ? `
                                    <button class="btn btn-outline-danger btn-sm" onclick="terminateSession('${session.id}')">
                                        <i class="bi bi-x-circle"></i>
                                    </button>
                                ` : ''}
                            </td>
                        </tr>
                    `).join('');
                }
            });
        }
        
        function loadSecurityLogs() {
            fetch('/api/v1/logs/security')
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    const tbody = document.getElementById('securityLogsTable');
                    tbody.innerHTML = data.logs.map(log => `
                        <tr>
                            <td>${new Date(log.timestamp).toLocaleString()}</td>
                            <td>
                                <span class="badge bg-${getLogLevelClass(log.level)}">
                                    ${log.level.toUpperCase()}
                                </span>
                            </td>
                            <td>${log.type}</td>
                            <td>${log.message}</td>
                            <td><code>${log.ip_address || '-'}</code></td>
                            <td>
                                <span class="badge bg-${log.status === 'success' ? 'success' : 'danger'}">
                                    ${log.status}
                                </span>
                            </td>
                        </tr>
                    `).join('');
                }
            });
        }
        
        function getLogLevelClass(level) {
            switch(level) {
                case 'info': return 'info';
                case 'warning': return 'warning';
                case 'error': return 'danger';
                default: return 'secondary';
            }
        }
        
        function terminateSession(sessionId) {
            if (confirm('确定要终止此会话吗？')) {
                fetch(`/api/v1/auth/sessions/${sessionId}`, {
                    method: 'DELETE'
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showAlert('会话已终止', 'success');
                        loadSessions();
                    } else {
                        showAlert(data.message || '终止会话失败', 'danger');
                    }
                });
            }
        }
        
        function showAlert(message, type) {
            const alertDiv = document.createElement('div');
            alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
            alertDiv.innerHTML = `
                ${message}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            `;
            
            document.querySelector('.container-fluid').insertBefore(alertDiv, document.querySelector('.row'));
            
            setTimeout(() => {
                alertDiv.remove();
            }, 5000);
        }
        
        function printBackupCodes() {
            window.print();
        }
    </script>
</body>
</html>
