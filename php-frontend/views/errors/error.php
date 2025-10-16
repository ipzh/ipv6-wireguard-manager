<div class="text-center py-5">
    <div class="error-template">
        <h1 class="display-1 text-danger">
            <i class="bi bi-exclamation-triangle"></i>
        </h1>
        <h2 class="mb-4">系统错误</h2>
        <div class="error-details mb-4">
            <div class="alert alert-danger">
                <strong>错误信息:</strong> <?= htmlspecialchars($error ?? '未知错误') ?>
            </div>
        </div>
        <div class="error-actions">
            <a href="/" class="btn btn-primary btn-lg">
                <i class="bi bi-house"></i> 返回首页
            </a>
            <a href="javascript:history.back()" class="btn btn-outline-secondary btn-lg">
                <i class="bi bi-arrow-left"></i> 返回上页
            </a>
            <button type="button" class="btn btn-outline-info btn-lg" onclick="window.location.reload()">
                <i class="bi bi-arrow-clockwise"></i> 刷新页面
            </button>
        </div>
    </div>
</div>
