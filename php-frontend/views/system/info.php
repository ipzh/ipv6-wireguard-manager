<?php
// views/system/info.php
?>

<div class="container-fluid">
    <h2>系统信息</h2>

    <?php if (isset($error)): ?>
        <div class="alert alert-danger"><?php echo htmlspecialchars($error); ?></div>
    <?php endif; ?>

    <?php if ($system): ?>
        <div class="row">
            <div class="col-md-6">
                <div class="card">
                    <div class="card-header">
                        <h5 class="card-title mb-0">基本信息</h5>
                    </div>
                    <div class="card-body">
                        <table class="table table-borderless">
                            <tr>
                                <td><strong>主机名:</strong></td>
                                <td><?php echo htmlspecialchars($system['hostname'] ?? 'N/A'); ?></td>
                            </tr>
                            <tr>
                                <td><strong>操作系统:</strong></td>
                                <td><?php echo htmlspecialchars($system['os'] ?? 'N/A'); ?></td>
                            </tr>
                            <tr>
                                <td><strong>内核版本:</strong></td>
                                <td><?php echo htmlspecialchars($system['kernel'] ?? 'N/A'); ?></td>
                            </tr>
                            <tr>
                                <td><strong>运行时间:</strong></td>
                                <td><?php echo htmlspecialchars($system['uptime'] ?? 'N/A'); ?></td>
                            </tr>
                        </table>
                    </div>
                </div>
            </div>
            
            <div class="col-md-6">
                <div class="card">
                    <div class="card-header">
                        <h5 class="card-title mb-0">资源使用情况</h5>
                    </div>
                    <div class="card-body">
                        <div class="mb-3">
                            <label class="form-label">CPU使用率</label>
                            <div class="progress">
                                <div class="progress-bar" role="progressbar" 
                                     style="width: <?php echo $system['cpu_usage'] ?? 0; ?>%"
                                     aria-valuenow="<?php echo $system['cpu_usage'] ?? 0; ?>" 
                                     aria-valuemin="0" aria-valuemax="100">
                                    <?php echo $system['cpu_usage'] ?? 0; ?>%
                                </div>
                            </div>
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">内存使用率</label>
                            <div class="progress">
                                <div class="progress-bar bg-warning" role="progressbar" 
                                     style="width: <?php echo $system['memory_usage'] ?? 0; ?>%"
                                     aria-valuenow="<?php echo $system['memory_usage'] ?? 0; ?>" 
                                     aria-valuemin="0" aria-valuemax="100">
                                    <?php echo $system['memory_usage'] ?? 0; ?>%
                                </div>
                            </div>
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">磁盘使用率</label>
                            <div class="progress">
                                <div class="progress-bar bg-info" role="progressbar" 
                                     style="width: <?php echo $system['disk_usage'] ?? 0; ?>%"
                                     aria-valuenow="<?php echo $system['disk_usage'] ?? 0; ?>" 
                                     aria-valuemin="0" aria-valuemax="100">
                                    <?php echo $system['disk_usage'] ?? 0; ?>%
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    <?php else: ?>
        <div class="alert alert-warning">
            <i class="bi bi-exclamation-triangle"></i>
            无法获取系统信息，请检查后端服务是否正常运行。
        </div>
    <?php endif; ?>
</div>

<style>
.progress {
    height: 1.5rem;
}

.progress-bar {
    font-size: 0.875rem;
    font-weight: 500;
}

.card {
    box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
    border: 1px solid rgba(0, 0, 0, 0.125);
}

.card-header {
    background-color: #f8f9fa;
    border-bottom: 1px solid rgba(0, 0, 0, 0.125);
}

.table-borderless td {
    border: none;
    padding: 0.5rem 0;
}

.table-borderless td:first-child {
    width: 30%;
    color: #6c757d;
}
</style>
