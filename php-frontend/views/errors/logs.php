<?php
// views/errors/logs.php
?>

<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2>错误日志</h2>
        <div>
            <button type="button" class="btn btn-outline-danger" onclick="clearLogs()">
                <i class="bi bi-trash"></i> 清除日志
            </button>
            <button type="button" class="btn btn-outline-secondary" onclick="refreshLogs()">
                <i class="bi bi-arrow-clockwise"></i> 刷新
            </button>
        </div>
    </div>

    <?php if (isset($_SESSION['success'])): ?>
        <div class="alert alert-success"><?php echo htmlspecialchars($_SESSION['success']); unset($_SESSION['success']); ?></div>
    <?php endif; ?>

    <?php if (isset($_SESSION['error'])): ?>
        <div class="alert alert-danger"><?php echo htmlspecialchars($_SESSION['error']); unset($_SESSION['error']); ?></div>
    <?php endif; ?>

    <div class="card">
        <div class="card-header">
            <h5 class="card-title mb-0">系统错误日志</h5>
        </div>
        <div class="card-body">
            <?php if (!empty($logs)): ?>
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>时间</th>
                                <th>类型</th>
                                <th>错误信息</th>
                                <th>文件</th>
                                <th>行号</th>
                                <th>用户</th>
                                <th>操作</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($logs as $log): ?>
                                <tr>
                                    <td>
                                        <small><?php echo htmlspecialchars($log['timestamp']); ?></small>
                                    </td>
                                    <td>
                                        <?php
                                        $badgeClass = 'bg-secondary';
                                        switch ($log['type']) {
                                            case 'Fatal Error':
                                            case 'Exception':
                                                $badgeClass = 'bg-danger';
                                                break;
                                            case 'Warning':
                                                $badgeClass = 'bg-warning';
                                                break;
                                            case 'Notice':
                                                $badgeClass = 'bg-info';
                                                break;
                                        }
                                        ?>
                                        <span class="badge <?php echo $badgeClass; ?>">
                                            <?php echo htmlspecialchars($log['type']); ?>
                                        </span>
                                    </td>
                                    <td>
                                        <div class="text-truncate" style="max-width: 300px;" title="<?php echo htmlspecialchars($log['message']); ?>">
                                            <?php echo htmlspecialchars($log['message']); ?>
                                        </div>
                                    </td>
                                    <td>
                                        <small class="text-muted">
                                            <?php echo htmlspecialchars(basename($log['file'])); ?>
                                        </small>
                                    </td>
                                    <td>
                                        <span class="badge bg-light text-dark">
                                            <?php echo htmlspecialchars($log['line']); ?>
                                        </span>
                                    </td>
                                    <td>
                                        <small><?php echo htmlspecialchars($log['details'][0] ?? 'N/A'); ?></small>
                                    </td>
                                    <td>
                                        <button type="button" class="btn btn-outline-primary btn-sm" 
                                                onclick="showLogDetails(<?php echo htmlspecialchars(json_encode($log)); ?>)">
                                            <i class="bi bi-eye"></i> 详情
                                        </button>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php else: ?>
                <div class="text-center py-5">
                    <i class="bi bi-check-circle display-1 text-success"></i>
                    <h5 class="mt-3 text-muted">暂无错误日志</h5>
                    <p class="text-muted">系统运行正常，没有发现错误</p>
                </div>
            <?php endif; ?>
        </div>
    </div>
</div>

<!-- 日志详情模态框 -->
<div class="modal fade" id="logDetailsModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">错误详情</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body" id="logDetailsContent">
                <!-- 详情内容将通过JavaScript动态加载 -->
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
            </div>
        </div>
    </div>
</div>

<script>
function refreshLogs() {
    location.reload();
}

function clearLogs() {
    if (confirm('确定要清除所有错误日志吗？此操作不可恢复。')) {
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = '/error/logs/clear';
        
        const token = document.createElement('input');
        token.type = 'hidden';
        token.name = '_token';
        token.value = '<?php echo $_SESSION['csrf_token'] ?? ''; ?>';
        form.appendChild(token);
        
        document.body.appendChild(form);
        form.submit();
    }
}

function showLogDetails(log) {
    const content = `
        <div class="row">
            <div class="col-md-6">
                <h6>基本信息</h6>
                <table class="table table-sm">
                    <tr><td><strong>时间:</strong></td><td>${log.timestamp}</td></tr>
                    <tr><td><strong>类型:</strong></td><td><span class="badge bg-danger">${log.type}</span></td></tr>
                    <tr><td><strong>文件:</strong></td><td>${log.file}</td></tr>
                    <tr><td><strong>行号:</strong></td><td>${log.line}</td></tr>
                </table>
            </div>
            <div class="col-md-6">
                <h6>请求信息</h6>
                <table class="table table-sm">
                    <tr><td><strong>用户:</strong></td><td>${log.details[0] || 'N/A'}</td></tr>
                    <tr><td><strong>IP:</strong></td><td>${log.details[1] || 'N/A'}</td></tr>
                    <tr><td><strong>URL:</strong></td><td>${log.details[2] || 'N/A'}</td></tr>
                    <tr><td><strong>方法:</strong></td><td>${log.details[3] || 'N/A'}</td></tr>
                </table>
            </div>
        </div>
        <div class="row mt-3">
            <div class="col-12">
                <h6>错误信息</h6>
                <div class="alert alert-danger">
                    <pre class="mb-0">${log.message}</pre>
                </div>
            </div>
        </div>
        ${log.details.length > 4 ? `
        <div class="row mt-3">
            <div class="col-12">
                <h6>详细信息</h6>
                <pre class="bg-light p-3 rounded">${log.details.slice(4).join('\n')}</pre>
            </div>
        </div>
        ` : ''}
    `;
    
    document.getElementById('logDetailsContent').innerHTML = content;
    new bootstrap.Modal(document.getElementById('logDetailsModal')).show();
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

.table th {
    background-color: #f8f9fa;
    border-top: none;
    font-weight: 600;
}

.badge {
    font-size: 0.75rem;
}

.text-truncate {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.btn-sm {
    padding: 0.25rem 0.5rem;
    font-size: 0.75rem;
}

pre {
    font-size: 0.875rem;
    max-height: 300px;
    overflow-y: auto;
}
</style>
