<?php
// views/system/config.php
?>

<div class="container-fluid">
    <h2>系统配置</h2>

    <?php if (isset($error)): ?>
        <div class="alert alert-danger"><?php echo htmlspecialchars($error); ?></div>
    <?php endif; ?>

    <?php if (isset($_SESSION['success'])): ?>
        <div class="alert alert-success"><?php echo htmlspecialchars($_SESSION['success']); unset($_SESSION['success']); ?></div>
    <?php endif; ?>

    <div class="row">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title mb-0">基本配置</h5>
                </div>
                <div class="card-body">
                    <form method="POST" action="/system/config">
                        <input type="hidden" name="_token" value="<?php echo $_SESSION['csrf_token'] ?? ''; ?>">
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="system_name" class="form-label">系统名称</label>
                                    <input type="text" class="form-control" id="system_name" name="system_name" 
                                           value="<?php echo htmlspecialchars($config['system_name'] ?? 'IPv6 WireGuard Manager'); ?>">
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="timezone" class="form-label">时区</label>
                                    <select class="form-select" id="timezone" name="timezone">
                                        <option value="Asia/Shanghai" <?php echo ($config['timezone'] ?? 'Asia/Shanghai') === 'Asia/Shanghai' ? 'selected' : ''; ?>>Asia/Shanghai</option>
                                        <option value="UTC" <?php echo ($config['timezone'] ?? '') === 'UTC' ? 'selected' : ''; ?>>UTC</option>
                                        <option value="America/New_York" <?php echo ($config['timezone'] ?? '') === 'America/New_York' ? 'selected' : ''; ?>>America/New_York</option>
                                    </select>
                                </div>
                            </div>
                        </div>
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="language" class="form-label">语言</label>
                                    <select class="form-select" id="language" name="language">
                                        <option value="zh-CN" <?php echo ($config['language'] ?? 'zh-CN') === 'zh-CN' ? 'selected' : ''; ?>>中文</option>
                                        <option value="en-US" <?php echo ($config['language'] ?? '') === 'en-US' ? 'selected' : ''; ?>>English</option>
                                    </select>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="log_level" class="form-label">日志级别</label>
                                    <select class="form-select" id="log_level" name="log_level">
                                        <option value="debug" <?php echo ($config['log_level'] ?? 'info') === 'debug' ? 'selected' : ''; ?>>Debug</option>
                                        <option value="info" <?php echo ($config['log_level'] ?? 'info') === 'info' ? 'selected' : ''; ?>>Info</option>
                                        <option value="warning" <?php echo ($config['log_level'] ?? '') === 'warning' ? 'selected' : ''; ?>>Warning</option>
                                        <option value="error" <?php echo ($config['log_level'] ?? '') === 'error' ? 'selected' : ''; ?>>Error</option>
                                    </select>
                                </div>
                            </div>
                        </div>
                        
                        <div class="mb-3">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" id="debug_mode" name="debug_mode" 
                                       <?php echo ($config['debug_mode'] ?? false) ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="debug_mode">
                                    调试模式
                                </label>
                            </div>
                        </div>
                        
                        <div class="d-flex justify-content-end">
                            <button type="submit" class="btn btn-primary">
                                <i class="bi bi-save"></i> 保存配置
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
        
        <div class="col-md-4">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title mb-0">系统状态</h5>
                </div>
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <span>API服务</span>
                        <span class="badge bg-success">运行中</span>
                    </div>
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <span>数据库</span>
                        <span class="badge bg-success">连接正常</span>
                    </div>
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <span>WireGuard</span>
                        <span class="badge bg-success">运行中</span>
                    </div>
                    <div class="d-flex justify-content-between align-items-center">
                        <span>BGP服务</span>
                        <span class="badge bg-warning">部分运行</span>
                    </div>
                </div>
            </div>
            
            <div class="card mt-3">
                <div class="card-header">
                    <h5 class="card-title mb-0">快速操作</h5>
                </div>
                <div class="card-body">
                    <div class="d-grid gap-2">
                        <button class="btn btn-outline-primary btn-sm" onclick="restartServices()">
                            <i class="bi bi-arrow-clockwise"></i> 重启服务
                        </button>
                        <button class="btn btn-outline-secondary btn-sm" onclick="clearCache()">
                            <i class="bi bi-trash"></i> 清除缓存
                        </button>
                        <button class="btn btn-outline-info btn-sm" onclick="exportConfig()">
                            <i class="bi bi-download"></i> 导出配置
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
function restartServices() {
    if (confirm('确定要重启所有服务吗？这可能会影响正在进行的连接。')) {
        // 这里应该调用重启服务的API
        alert('服务重启功能需要后端API支持');
    }
}

function clearCache() {
    if (confirm('确定要清除所有缓存吗？')) {
        // 这里应该调用清除缓存的API
        alert('缓存清除功能需要后端API支持');
    }
}

function exportConfig() {
    // 这里应该调用导出配置的API
    alert('配置导出功能需要后端API支持');
}
</script>

<style>
.card {
    box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
    border: 1px solid rgba(0, 0, 0, 0.125);
}

.card-header {
    background-color: #f8f9fa;
    border-bottom: 1px solid rgba(0, 0, 0, 0.125);
}

.badge {
    font-size: 0.75rem;
}

.form-check-input:checked {
    background-color: #0d6efd;
    border-color: #0d6efd;
}
</style>
