<?php
// views/monitoring/dashboard.php
// 注意：此文件由控制器处理布局包含，不需要直接包含header.php
?>

<div class="container-fluid">
    <h2>系统监控仪表板</h2>

    <?php if (isset($error)): ?>
        <div class="alert alert-danger"><?php echo htmlspecialchars($error); ?></div>
    <?php endif; ?>

    <!-- 系统概览卡片 -->
    <div class="row mb-4">
        <div class="col-md-3">
            <div class="card bg-primary text-white">
                <div class="card-body">
                    <div class="d-flex justify-content-between">
                        <div>
                            <h4 class="mb-0" id="cpu-usage">
                                <?php echo isset($metrics['cpu_usage']) ? round($metrics['cpu_usage'], 1) : '0'; ?>%
                            </h4>
                            <p class="mb-0">CPU使用率</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-cpu fs-1"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-md-3">
            <div class="card bg-success text-white">
                <div class="card-body">
                    <div class="d-flex justify-content-between">
                        <div>
                            <h4 class="mb-0" id="memory-usage">
                                <?php echo isset($metrics['memory_usage']) ? round($metrics['memory_usage'], 1) : '0'; ?>%
                            </h4>
                            <p class="mb-0">内存使用率</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-memory fs-1"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-md-3">
            <div class="card bg-warning text-white">
                <div class="card-body">
                    <div class="d-flex justify-content-between">
                        <div>
                            <h4 class="mb-0" id="disk-usage">
                                <?php echo isset($metrics['disk_usage']) ? round($metrics['disk_usage'], 1) : '0'; ?>%
                            </h4>
                            <p class="mb-0">磁盘使用率</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-hdd fs-1"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-md-3">
            <div class="card bg-info text-white">
                <div class="card-body">
                    <div class="d-flex justify-content-between">
                        <div>
                            <h4 class="mb-0" id="load-average">
                                <?php echo isset($metrics['load_average']['1m']) ? round($metrics['load_average']['1m'], 2) : '0'; ?>
                            </h4>
                            <p class="mb-0">负载平均值</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-speedometer2 fs-1"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 告警信息 -->
    <div class="row mb-4">
        <div class="col-12">
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0">系统告警</h5>
                    <div>
                        <span class="badge bg-danger" id="critical-alerts">0</span>
                        <span class="badge bg-warning" id="warning-alerts">0</span>
                        <span class="badge bg-info" id="info-alerts">0</span>
                    </div>
                </div>
                <div class="card-body">
                    <div id="alerts-container">
                        <?php if (!empty($alerts)): ?>
                            <?php foreach ($alerts as $alert): ?>
                                <div class="alert alert-<?php echo $alert['severity'] === 'critical' ? 'danger' : ($alert['severity'] === 'warning' ? 'warning' : 'info'); ?> alert-dismissible fade show">
                                    <i class="bi bi-<?php echo $alert['severity'] === 'critical' ? 'exclamation-triangle' : ($alert['severity'] === 'warning' ? 'exclamation-circle' : 'info-circle'); ?>"></i>
                                    <strong><?php echo htmlspecialchars($alert['message']); ?></strong>
                                    <small class="text-muted"> - <?php echo htmlspecialchars($alert['source']); ?> (<?php echo htmlspecialchars($alert['timestamp']); ?>)</small>
                                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                                </div>
                            <?php endforeach; ?>
                        <?php else: ?>
                            <div class="text-center text-muted">
                                <i class="bi bi-check-circle fs-1"></i>
                                <p class="mt-2">暂无系统告警</p>
                            </div>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 系统信息 -->
    <div class="row mb-4">
        <div class="col-md-6">
            <div class="card">
                <div class="card-header">
                    <h5 class="mb-0">系统信息</h5>
                </div>
                <div class="card-body">
                    <?php if ($systemInfo): ?>
                        <div class="row">
                            <div class="col-6">
                                <strong>主机名:</strong><br>
                                <?php echo htmlspecialchars($systemInfo['hostname'] ?? 'N/A'); ?>
                            </div>
                            <div class="col-6">
                                <strong>操作系统:</strong><br>
                                <?php echo htmlspecialchars($systemInfo['platform'] ?? 'N/A'); ?>
                            </div>
                        </div>
                        <hr>
                        <div class="row">
                            <div class="col-6">
                                <strong>CPU核心数:</strong><br>
                                <?php echo htmlspecialchars($systemInfo['cpu_count'] ?? 'N/A'); ?>
                            </div>
                            <div class="col-6">
                                <strong>总内存:</strong><br>
                                <?php echo isset($systemInfo['memory_total']) ? number_format($systemInfo['memory_total'] / 1024 / 1024 / 1024, 2) . ' GB' : 'N/A'; ?>
                            </div>
                        </div>
                        <hr>
                        <div class="row">
                            <div class="col-6">
                                <strong>运行时间:</strong><br>
                                <?php echo htmlspecialchars($systemInfo['uptime'] ?? 'N/A'); ?>
                            </div>
                            <div class="col-6">
                                <strong>Python版本:</strong><br>
                                <?php echo htmlspecialchars($systemInfo['python_version'] ?? 'N/A'); ?>
                            </div>
                        </div>
                    <?php else: ?>
                        <p class="text-muted">系统信息获取失败</p>
                    <?php endif; ?>
                </div>
            </div>
        </div>
        
        <div class="col-md-6">
            <div class="card">
                <div class="card-header">
                    <h5 class="mb-0">网络流量</h5>
                </div>
                <div class="card-body">
                    <?php if (isset($metrics['network_sent']) && isset($metrics['network_recv'])): ?>
                        <div class="row">
                            <div class="col-6">
                                <strong>发送:</strong><br>
                                <span id="network-sent"><?php echo number_format($metrics['network_sent'] / 1024 / 1024, 2); ?> MB</span>
                            </div>
                            <div class="col-6">
                                <strong>接收:</strong><br>
                                <span id="network-recv"><?php echo number_format($metrics['network_recv'] / 1024 / 1024, 2); ?> MB</span>
                            </div>
                        </div>
                        <hr>
                        <div class="row">
                            <div class="col-12">
                                <strong>总流量:</strong><br>
                                <span id="network-total"><?php echo number_format(($metrics['network_sent'] + $metrics['network_recv']) / 1024 / 1024, 2); ?> MB</span>
                            </div>
                        </div>
                    <?php else: ?>
                        <p class="text-muted">网络流量信息获取失败</p>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    </div>

    <!-- 快速操作 -->
    <div class="row">
        <div class="col-12">
            <div class="card">
                <div class="card-header">
                    <h5 class="mb-0">快速操作</h5>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-3">
                            <a href="/monitoring/metrics" class="btn btn-outline-primary w-100">
                                <i class="bi bi-graph-up"></i><br>详细指标
                            </a>
                        </div>
                        <div class="col-md-3">
                            <a href="/monitoring/alerts" class="btn btn-outline-warning w-100">
                                <i class="bi bi-exclamation-triangle"></i><br>告警管理
                            </a>
                        </div>
                        <div class="col-md-3">
                            <a href="/monitoring/processes" class="btn btn-outline-info w-100">
                                <i class="bi bi-list-task"></i><br>进程管理
                            </a>
                        </div>
                        <div class="col-md-3">
                            <a href="/monitoring/history" class="btn btn-outline-success w-100">
                                <i class="bi bi-clock-history"></i><br>历史数据
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
// 实时数据更新
function updateRealtimeData() {
    fetch('/monitoring/realtime-data')
        .then(response => response.json())
        .then(data => {
            if (data.metrics) {
                document.getElementById('cpu-usage').textContent = Math.round(data.metrics.cpu_usage || 0) + '%';
                document.getElementById('memory-usage').textContent = Math.round(data.metrics.memory_usage || 0) + '%';
                document.getElementById('disk-usage').textContent = Math.round(data.metrics.disk_usage || 0) + '%';
                document.getElementById('load-average').textContent = (data.metrics.load_average?.['1m'] || 0).toFixed(2);
                
                if (data.metrics.network_sent && data.metrics.network_recv) {
                    document.getElementById('network-sent').textContent = (data.metrics.network_sent / 1024 / 1024).toFixed(2) + ' MB';
                    document.getElementById('network-recv').textContent = (data.metrics.network_recv / 1024 / 1024).toFixed(2) + ' MB';
                    document.getElementById('network-total').textContent = ((data.metrics.network_sent + data.metrics.network_recv) / 1024 / 1024).toFixed(2) + ' MB';
                }
            }
            
            if (data.alerts) {
                let criticalCount = 0, warningCount = 0, infoCount = 0;
                data.alerts.forEach(alert => {
                    if (alert.severity === 'critical') criticalCount++;
                    else if (alert.severity === 'warning') warningCount++;
                    else infoCount++;
                });
                
                document.getElementById('critical-alerts').textContent = criticalCount;
                document.getElementById('warning-alerts').textContent = warningCount;
                document.getElementById('info-alerts').textContent = infoCount;
            }
        })
        .catch(error => {
            console.error('获取实时数据失败:', error);
        });
}

// 每5秒更新一次数据
setInterval(updateRealtimeData, 5000);

// 页面加载完成后立即更新一次
document.addEventListener('DOMContentLoaded', updateRealtimeData);
</script>

<style>
.card {
    box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
    border: 1px solid rgba(0, 0, 0, 0.125);
}

.card-header {
    background-color: #f8f9fa;
    border-bottom: 1px solid #dee2e6;
}

.fs-1 {
    font-size: 2.5rem !important;
}

.btn {
    padding: 1rem;
    text-align: center;
}

.btn i {
    font-size: 1.5rem;
    display: block;
    margin-bottom: 0.5rem;
}

.alert {
    margin-bottom: 0.5rem;
}

.badge {
    font-size: 0.75em;
    margin-left: 0.25rem;
}
</style>

<?php
require_once __DIR__ . '/../layout/footer.php';
?>
