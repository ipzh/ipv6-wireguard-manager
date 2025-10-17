<?php
/**
 * 错误页面
 */
$errorTitle = $_SESSION['error_title'] ?? '发生错误';
$errorMessage = $_SESSION['error_message'] ?? '未知错误';
unset($_SESSION['error_title'], $_SESSION['error_message']);
?>

<div class="container mt-5">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card shadow-lg border-0">
                <div class="card-body text-center p-5">
                    <div class="mb-4">
                        <i class="bi bi-exclamation-triangle text-danger" style="font-size: 5rem;"></i>
                    </div>
                    
                    <h1 class="display-4 text-danger mb-3"><?= htmlspecialchars($errorTitle) ?></h1>
                    <p class="lead text-muted mb-4"><?= htmlspecialchars($errorMessage) ?></p>
                    
                    <div class="d-grid gap-2 d-md-flex justify-content-md-center">
                        <button type="button" class="btn btn-primary btn-lg" onclick="history.back()">
                            <i class="bi bi-arrow-left me-2"></i>返回上一页
                        </button>
                        <a href="/" class="btn btn-outline-secondary btn-lg">
                            <i class="bi bi-house me-2"></i>返回首页
                        </a>
                    </div>
                    
                    <?php if (APP_DEBUG): ?>
                    <div class="mt-5">
                        <details class="text-start">
                            <summary class="btn btn-outline-info">显示调试信息</summary>
                            <div class="mt-3 p-3 bg-light rounded">
                                <h6>错误详情:</h6>
                                <pre class="small"><?= htmlspecialchars($errorMessage) ?></pre>
                                
                                <h6 class="mt-3">请求信息:</h6>
                                <ul class="small">
                                    <li>URL: <?= htmlspecialchars($_SERVER['REQUEST_URI'] ?? '') ?></li>
                                    <li>方法: <?= htmlspecialchars($_SERVER['REQUEST_METHOD'] ?? '') ?></li>
                                    <li>时间: <?= date('Y-m-d H:i:s') ?></li>
                                    <li>用户: <?= htmlspecialchars($this->auth->getCurrentUser()['username'] ?? '未登录') ?></li>
                                </ul>
                            </div>
                        </details>
                    </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    </div>
</div>