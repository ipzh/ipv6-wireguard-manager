<div class="row justify-content-center">
    <div class="col-md-6 col-lg-4">
        <div class="card shadow">
            <div class="card-body p-5">
                <div class="text-center mb-4">
                    <i class="bi bi-shield-lock text-primary" style="font-size: 3rem;"></i>
                    <h3 class="mt-3"><?= APP_NAME ?></h3>
                    <p class="text-muted">请登录您的账户</p>
                </div>
                
                <?php if (isset($error)): ?>
                <div class="alert alert-danger" role="alert">
                    <i class="bi bi-exclamation-triangle"></i> <?= htmlspecialchars($error) ?>
                </div>
                <?php endif; ?>
                
                <form method="POST" action="/login" id="loginForm">
                    <input type="hidden" name="_token" value="<?= $this->auth->generateCsrfToken() ?>">
                    
                    <div class="mb-3">
                        <label for="username" class="form-label">用户名</label>
                        <div class="input-group">
                            <span class="input-group-text">
                                <i class="bi bi-person"></i>
                            </span>
                            <input type="text" class="form-control" id="username" name="username" 
                                   value="<?= htmlspecialchars($_POST['username'] ?? '') ?>" 
                                   required autofocus>
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        <label for="password" class="form-label">密码</label>
                        <div class="input-group">
                            <span class="input-group-text">
                                <i class="bi bi-lock"></i>
                            </span>
                            <input type="password" class="form-control" id="password" name="password" required>
                            <button class="btn btn-outline-secondary" type="button" id="togglePassword">
                                <i class="bi bi-eye" id="toggleIcon"></i>
                            </button>
                        </div>
                    </div>
                    
                    <div class="mb-3 form-check">
                        <input type="checkbox" class="form-check-input" id="rememberMe" name="remember_me">
                        <label class="form-check-label" for="rememberMe">
                            记住我
                        </label>
                    </div>
                    
                    <div class="d-grid">
                        <button type="submit" class="btn btn-primary btn-lg" id="loginBtn">
                            <span class="spinner-border spinner-border-sm me-2 d-none" id="loginSpinner"></span>
                            <i class="bi bi-box-arrow-in-right me-2"></i>
                            登录
                        </button>
                    </div>
                </form>
                
                <div class="text-center mt-4">
                    <small class="text-muted">
                        <i class="bi bi-info-circle"></i>
                        默认管理员账户: admin / admin123
                    </small>
                </div>
            </div>
        </div>
        
        <!-- API状态检查 -->
        <div class="card mt-3">
            <div class="card-body text-center">
                <h6 class="card-title">系统状态</h6>
                <div id="apiStatus">
                    <div class="spinner-border spinner-border-sm text-primary" role="status">
                        <span class="visually-hidden">检查中...</span>
                    </div>
                    <span class="ms-2">检查API连接...</span>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
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
        } else {
            toggleIcon.className = 'bi bi-eye';
        }
    });
    
    // 表单提交处理
    const loginForm = document.getElementById('loginForm');
    const loginBtn = document.getElementById('loginBtn');
    const loginSpinner = document.getElementById('loginSpinner');
    
    loginForm.addEventListener('submit', function(e) {
        // 显示加载状态
        loginBtn.disabled = true;
        loginSpinner.classList.remove('d-none');
        
        // 如果API连接失败，阻止提交
        if (!window.apiConnected) {
            e.preventDefault();
            showMessage('API服务连接失败，请检查后端服务状态', 'error');
            loginBtn.disabled = false;
            loginSpinner.classList.add('d-none');
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
});

function checkApiStatus() {
    fetch('/api/status')
        .then(response => response.json())
        .then(data => {
            const statusDiv = document.getElementById('apiStatus');
            if (data.success) {
                statusDiv.innerHTML = `
                    <i class="bi bi-check-circle text-success"></i>
                    <span class="ms-2 text-success">API连接正常</span>
                `;
                window.apiConnected = true;
            } else {
                statusDiv.innerHTML = `
                    <i class="bi bi-x-circle text-danger"></i>
                    <span class="ms-2 text-danger">API连接失败</span>
                `;
                window.apiConnected = false;
            }
        })
        .catch(error => {
            const statusDiv = document.getElementById('apiStatus');
            statusDiv.innerHTML = `
                <i class="bi bi-x-circle text-danger"></i>
                <span class="ms-2 text-danger">API连接失败</span>
            `;
            window.apiConnected = false;
        });
}
</script>
