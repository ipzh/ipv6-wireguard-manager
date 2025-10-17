<?php
// 计算统计信息
$stats = [
    'totalServers' => count($dashboardData['servers']),
    'activeServers' => 0,
    'totalClients' => count($dashboardData['clients']),
    'activeClients' => 0,
    'totalBgpAnnouncements' => count($dashboardData['bgpAnnouncements']),
    'systemStatus' => 'unknown'
];

// 统计活跃服务器
foreach ($dashboardData['servers'] as $server) {
    if (($server['status'] ?? '') === 'running') {
        $stats['activeServers']++;
    }
}

// 统计活跃客户端
foreach ($dashboardData['clients'] as $client) {
    if (($client['status'] ?? '') === 'connected') {
        $stats['activeClients']++;
    }
}

// 系统状态
if ($dashboardData['apiStatus']) {
    $stats['systemStatus'] = $dashboardData['apiStatus']['status'] ?? 'unknown';
}
?>

<!-- 统计卡片 -->
<div class="row mb-4">
    <div class="col-xl-3 col-md-6 mb-4">
        <div class="card stats-card stats-card-primary h-100 fade-in-up" style="animation-delay: 0.1s;">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div class="stats-content">
                        <div class="stats-label">WireGuard服务器</div>
                        <div class="stats-value">
                            <span class="stats-number"><?= $stats['activeServers'] ?></span>
                            <span class="stats-separator">/</span>
                            <span class="stats-total"><?= $stats['totalServers'] ?></span>
                        </div>
                        <div class="stats-description">活跃 / 总数</div>
                    </div>
                    <div class="stats-icon">
                        <i class="bi bi-shield-lock"></i>
                    </div>
                </div>
                <div class="stats-progress">
                    <div class="progress-bar" style="width: <?= $stats['totalServers'] > 0 ? ($stats['activeServers'] / $stats['totalServers'] * 100) : 0 ?>%"></div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-xl-3 col-md-6 mb-4">
        <div class="card stats-card stats-card-success h-100 fade-in-up" style="animation-delay: 0.2s;">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div class="stats-content">
                        <div class="stats-label">WireGuard客户端</div>
                        <div class="stats-value">
                            <span class="stats-number"><?= $stats['activeClients'] ?></span>
                            <span class="stats-separator">/</span>
                            <span class="stats-total"><?= $stats['totalClients'] ?></span>
                        </div>
                        <div class="stats-description">连接 / 总数</div>
                    </div>
                    <div class="stats-icon">
                        <i class="bi bi-people"></i>
                    </div>
                </div>
                <div class="stats-progress">
                    <div class="progress-bar" style="width: <?= $stats['totalClients'] > 0 ? ($stats['activeClients'] / $stats['totalClients'] * 100) : 0 ?>%"></div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-xl-3 col-md-6 mb-4">
        <div class="card stats-card stats-card-info h-100 fade-in-up" style="animation-delay: 0.3s;">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div class="stats-content">
                        <div class="stats-label">BGP宣告</div>
                        <div class="stats-value">
                            <span class="stats-number"><?= $stats['totalBgpAnnouncements'] ?></span>
                        </div>
                        <div class="stats-description">活跃宣告</div>
                    </div>
                    <div class="stats-icon">
                        <i class="bi bi-diagram-3"></i>
                    </div>
                </div>
                <div class="stats-progress">
                    <div class="progress-bar" style="width: 100%"></div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-xl-3 col-md-6 mb-4">
        <div class="card stats-card stats-card-warning h-100 fade-in-up" style="animation-delay: 0.4s;">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div class="stats-content">
                        <div class="stats-label">系统状态</div>
                        <div class="stats-value">
                            <span class="status-badge status-<?= $stats['systemStatus'] === 'healthy' ? 'success' : 'danger' ?>">
                                <?= $stats['systemStatus'] === 'healthy' ? '正常' : '异常' ?>
                            </span>
                        </div>
                        <div class="stats-description">API服务状态</div>
                    </div>
                    <div class="stats-icon">
                        <i class="bi bi-activity"></i>
                    </div>
                </div>
                <div class="stats-progress">
                    <div class="progress-bar" style="width: <?= $stats['systemStatus'] === 'healthy' ? '100' : '0' ?>%"></div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- 主要内容区域 -->
<div class="row">
    <!-- WireGuard服务器状态 -->
    <div class="col-lg-6 mb-4">
        <div class="card shadow">
            <div class="card-header py-3 d-flex flex-row align-items-center justify-content-between">
                <h6 class="m-0 font-weight-bold text-primary">WireGuard服务器</h6>
                <a href="/wireguard/servers" class="btn btn-sm btn-primary">管理</a>
            </div>
            <div class="card-body">
                <?php if (empty($dashboardData['servers'])): ?>
                <div class="text-center text-muted py-4">
                    <i class="bi bi-shield-lock fa-3x mb-3"></i>
                    <p>暂无WireGuard服务器</p>
                    <a href="/wireguard/servers" class="btn btn-primary">添加服务器</a>
                </div>
                <?php else: ?>
                <div class="table-responsive">
                    <table class="table table-sm">
                        <thead>
                            <tr>
                                <th>名称</th>
                                <th>接口</th>
                                <th>状态</th>
                                <th>操作</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach (array_slice($dashboardData['servers'], 0, 5) as $server): ?>
                            <tr>
                                <td><?= htmlspecialchars($server['name'] ?? '') ?></td>
                                <td><?= htmlspecialchars($server['interface'] ?? '') ?></td>
                                <td>
                                    <span class="badge bg-<?= ($server['status'] ?? '') === 'running' ? 'success' : 'danger' ?>">
                                        <?= ($server['status'] ?? '') === 'running' ? '运行中' : '已停止' ?>
                                    </span>
                                </td>
                                <td>
                                    <a href="/wireguard/servers/<?= $server['id'] ?>" class="btn btn-sm btn-outline-primary">
                                        <i class="bi bi-eye"></i>
                                    </a>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
    
    <!-- WireGuard客户端状态 -->
    <div class="col-lg-6 mb-4">
        <div class="card shadow">
            <div class="card-header py-3 d-flex flex-row align-items-center justify-content-between">
                <h6 class="m-0 font-weight-bold text-success">WireGuard客户端</h6>
                <a href="/wireguard/clients" class="btn btn-sm btn-success">管理</a>
            </div>
            <div class="card-body">
                <?php if (empty($dashboardData['clients'])): ?>
                <div class="text-center text-muted py-4">
                    <i class="bi bi-people fa-3x mb-3"></i>
                    <p>暂无WireGuard客户端</p>
                    <a href="/wireguard/clients" class="btn btn-success">添加客户端</a>
                </div>
                <?php else: ?>
                <div class="table-responsive">
                    <table class="table table-sm">
                        <thead>
                            <tr>
                                <th>名称</th>
                                <th>IP地址</th>
                                <th>状态</th>
                                <th>操作</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach (array_slice($dashboardData['clients'], 0, 5) as $client): ?>
                            <tr>
                                <td><?= htmlspecialchars($client['name'] ?? '') ?></td>
                                <td><?= htmlspecialchars($client['ipv4_address'] ?? '') ?></td>
                                <td>
                                    <span class="badge bg-<?= ($client['status'] ?? '') === 'connected' ? 'success' : 'secondary' ?>">
                                        <?= ($client['status'] ?? '') === 'connected' ? '已连接' : '未连接' ?>
                                    </span>
                                </td>
                                <td>
                                    <a href="/wireguard/clients/<?= $client['id'] ?>" class="btn btn-sm btn-outline-success">
                                        <i class="bi bi-eye"></i>
                                    </a>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<!-- 系统监控和日志 -->
<div class="row">
    <!-- 系统指标 -->
    <div class="col-lg-8 mb-4">
        <div class="card shadow">
            <div class="card-header py-3 d-flex flex-row align-items-center justify-content-between">
                <h6 class="m-0 font-weight-bold text-info">系统监控</h6>
                <a href="/monitoring" class="btn btn-sm btn-info">详细监控</a>
            </div>
            <div class="card-body">
                <?php if ($dashboardData['systemMetrics']): ?>
                <div class="row">
                    <div class="col-md-4 text-center">
                        <div class="mb-3">
                            <h5 class="text-primary">CPU使用率</h5>
                            <div class="progress mb-2">
                                <div class="progress-bar" role="progressbar" 
                                     style="width: <?= $dashboardData['systemMetrics']['cpu_usage'] ?? 0 ?>%">
                                    <?= $dashboardData['systemMetrics']['cpu_usage'] ?? 0 ?>%
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-4 text-center">
                        <div class="mb-3">
                            <h5 class="text-success">内存使用率</h5>
                            <div class="progress mb-2">
                                <div class="progress-bar bg-success" role="progressbar" 
                                     style="width: <?= $dashboardData['systemMetrics']['memory_usage'] ?? 0 ?>%">
                                    <?= $dashboardData['systemMetrics']['memory_usage'] ?? 0 ?>%
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-4 text-center">
                        <div class="mb-3">
                            <h5 class="text-warning">磁盘使用率</h5>
                            <div class="progress mb-2">
                                <div class="progress-bar bg-warning" role="progressbar" 
                                     style="width: <?= $dashboardData['systemMetrics']['disk_usage'] ?? 0 ?>%">
                                    <?= $dashboardData['systemMetrics']['disk_usage'] ?? 0 ?>%
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <?php else: ?>
                <div class="text-center text-muted py-4">
                    <i class="bi bi-graph-up fa-3x mb-3"></i>
                    <p>暂无监控数据</p>
                </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
    
    <!-- 最近日志 -->
    <div class="col-lg-4 mb-4">
        <div class="card shadow">
            <div class="card-header py-3 d-flex flex-row align-items-center justify-content-between">
                <h6 class="m-0 font-weight-bold text-warning">最近日志</h6>
                <a href="/logs" class="btn btn-sm btn-warning">查看全部</a>
            </div>
            <div class="card-body">
                <?php if (empty($dashboardData['recentLogs'])): ?>
                <div class="text-center text-muted py-4">
                    <i class="bi bi-journal-text fa-3x mb-3"></i>
                    <p>暂无日志记录</p>
                </div>
                <?php else: ?>
                <div class="list-group list-group-flush">
                    <?php foreach (array_slice($dashboardData['recentLogs'], 0, 5) as $log): ?>
                    <div class="list-group-item px-0">
                        <div class="d-flex w-100 justify-content-between">
                            <h6 class="mb-1">
                                <span class="badge bg-<?= getLogLevelColor($log['level'] ?? 'info') ?> me-2">
                                    <?= strtoupper($log['level'] ?? 'INFO') ?>
                                </span>
                                <?= htmlspecialchars($log['message'] ?? '') ?>
                            </h6>
                            <small><?= date('H:i:s', strtotime($log['timestamp'] ?? 'now')) ?></small>
                        </div>
                        <small class="text-muted"><?= htmlspecialchars($log['source'] ?? '') ?></small>
                    </div>
                    <?php endforeach; ?>
                </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<!-- BGP宣告状态 -->
<?php if (!empty($dashboardData['bgpAnnouncements'])): ?>
<div class="row">
    <div class="col-12 mb-4">
        <div class="card shadow">
            <div class="card-header py-3 d-flex flex-row align-items-center justify-content-between">
                <h6 class="m-0 font-weight-bold text-primary">BGP宣告状态</h6>
                <a href="/bgp/sessions" class="btn btn-sm btn-primary">管理BGP</a>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-sm">
                        <thead>
                            <tr>
                                <th>前缀</th>
                                <th>下一跳</th>
                                <th>状态</th>
                                <th>社区</th>
                                <th>操作</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach (array_slice($dashboardData['bgpAnnouncements'], 0, 10) as $announcement): ?>
                            <tr>
                                <td><?= htmlspecialchars($announcement['prefix'] ?? '') ?></td>
                                <td><?= htmlspecialchars($announcement['next_hop'] ?? '') ?></td>
                                <td>
                                    <span class="badge bg-<?= ($announcement['status'] ?? '') === 'active' ? 'success' : 'secondary' ?>">
                                        <?= ($announcement['status'] ?? '') === 'active' ? '活跃' : '非活跃' ?>
                                    </span>
                                </td>
                                <td><?= htmlspecialchars($announcement['community'] ?? '') ?></td>
                                <td>
                                    <a href="/bgp/sessions/<?= $announcement['session_id'] ?? '' ?>" class="btn btn-sm btn-outline-primary">
                                        <i class="bi bi-eye"></i>
                                    </a>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
<?php endif; ?>

<script>
// 实时数据更新
let refreshInterval;

function startRealTimeUpdate() {
    refreshInterval = setInterval(function() {
        updateDashboardData();
    }, 30000); // 每30秒更新一次
}

function stopRealTimeUpdate() {
    if (refreshInterval) {
        clearInterval(refreshInterval);
    }
}

function updateDashboardData() {
    fetch('/dashboard/realtime')
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                // 更新页面数据
                updateStatistics(data.data);
                updateSystemMetrics(data.data.systemMetrics);
            }
        })
        .catch(error => {
            console.error('更新数据失败:', error);
        });
}

function updateStatistics(data) {
    // 更新统计卡片
    const stats = calculateStatistics(data);
    
    // 更新服务器统计
    const serverStats = document.querySelector('.card:first-child .h5');
    if (serverStats) {
        serverStats.textContent = `${stats.activeServers} / ${stats.totalServers}`;
    }
    
    // 更新客户端统计
    const clientStats = document.querySelector('.card:nth-child(2) .h5');
    if (clientStats) {
        clientStats.textContent = `${stats.activeClients} / ${stats.totalClients}`;
    }
    
    // 更新BGP统计
    const bgpStats = document.querySelector('.card:nth-child(3) .h5');
    if (bgpStats) {
        bgpStats.textContent = stats.totalBgpAnnouncements;
    }
    
    // 更新系统状态
    const systemStatus = document.querySelector('.card:nth-child(4) .badge');
    if (systemStatus) {
        systemStatus.textContent = stats.systemStatus === 'healthy' ? '正常' : '异常';
        systemStatus.className = `badge bg-${stats.systemStatus === 'healthy' ? 'success' : 'danger'}`;
    }
}

function updateSystemMetrics(metrics) {
    if (!metrics) return;
    
    // 更新CPU使用率
    const cpuProgress = document.querySelector('.progress-bar:first-child');
    if (cpuProgress) {
        cpuProgress.style.width = `${metrics.cpu_usage || 0}%`;
        cpuProgress.textContent = `${metrics.cpu_usage || 0}%`;
    }
    
    // 更新内存使用率
    const memoryProgress = document.querySelector('.progress-bar.bg-success');
    if (memoryProgress) {
        memoryProgress.style.width = `${metrics.memory_usage || 0}%`;
        memoryProgress.textContent = `${metrics.memory_usage || 0}%`;
    }
    
    // 更新磁盘使用率
    const diskProgress = document.querySelector('.progress-bar.bg-warning');
    if (diskProgress) {
        diskProgress.style.width = `${metrics.disk_usage || 0}%`;
        diskProgress.textContent = `${metrics.disk_usage || 0}%`;
    }
}

function calculateStatistics(data) {
    const stats = {
        totalServers: data.servers?.length || 0,
        activeServers: 0,
        totalClients: data.clients?.length || 0,
        activeClients: 0,
        totalBgpAnnouncements: data.bgpAnnouncements?.length || 0,
        systemStatus: data.apiStatus?.status || 'unknown'
    };
    
    // 统计活跃服务器
    data.servers?.forEach(server => {
        if (server.status === 'running') {
            stats.activeServers++;
        }
    });
    
    // 统计活跃客户端
    data.clients?.forEach(client => {
        if (client.status === 'connected') {
            stats.activeClients++;
        }
    });
    
    return stats;
}

// 页面加载完成后启动实时更新
document.addEventListener('DOMContentLoaded', function() {
    startRealTimeUpdate();
});

// 页面卸载时停止实时更新
window.addEventListener('beforeunload', function() {
    stopRealTimeUpdate();
});
</script>

<style>
/* 统计卡片样式 */
.stats-card {
    position: relative;
    overflow: hidden;
    border: none;
    background: linear-gradient(135deg, rgba(255, 255, 255, 0.9), rgba(255, 255, 255, 0.7));
    backdrop-filter: blur(20px);
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.stats-card::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--primary-color), var(--primary-dark));
    transform: scaleX(0);
    transition: transform 0.3s ease;
}

.stats-card:hover::before {
    transform: scaleX(1);
}

.stats-card:hover {
    transform: translateY(-8px);
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
}

.stats-card-primary::before {
    background: linear-gradient(90deg, var(--primary-color), var(--primary-dark));
}

.stats-card-success::before {
    background: linear-gradient(90deg, var(--success-color), #059669);
}

.stats-card-info::before {
    background: linear-gradient(90deg, var(--info-color), #0891b2);
}

.stats-card-warning::before {
    background: linear-gradient(90deg, var(--warning-color), #d97706);
}

.stats-content {
    flex: 1;
}

.stats-label {
    font-size: 0.875rem;
    font-weight: 600;
    color: var(--secondary-color);
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin-bottom: 0.5rem;
}

.stats-value {
    display: flex;
    align-items: baseline;
    margin-bottom: 0.25rem;
}

.stats-number {
    font-size: 2rem;
    font-weight: 700;
    color: var(--dark-color);
    line-height: 1;
}

.stats-separator {
    font-size: 1.5rem;
    font-weight: 400;
    color: var(--secondary-color);
    margin: 0 0.25rem;
}

.stats-total {
    font-size: 1.25rem;
    font-weight: 500;
    color: var(--secondary-color);
}

.stats-description {
    font-size: 0.75rem;
    color: var(--secondary-color);
    font-weight: 400;
}

.stats-icon {
    width: 60px;
    height: 60px;
    border-radius: 16px;
    display: flex;
    align-items: center;
    justify-content: center;
    background: rgba(99, 102, 241, 0.1);
    color: var(--primary-color);
    font-size: 1.5rem;
    transition: all 0.3s ease;
}

.stats-card-success .stats-icon {
    background: rgba(16, 185, 129, 0.1);
    color: var(--success-color);
}

.stats-card-info .stats-icon {
    background: rgba(6, 182, 212, 0.1);
    color: var(--info-color);
}

.stats-card-warning .stats-icon {
    background: rgba(245, 158, 11, 0.1);
    color: var(--warning-color);
}

.stats-card:hover .stats-icon {
    transform: scale(1.1) rotate(5deg);
}

.stats-progress {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    height: 3px;
    background: rgba(0, 0, 0, 0.05);
    overflow: hidden;
}

.stats-progress .progress-bar {
    height: 100%;
    background: linear-gradient(90deg, var(--primary-color), var(--primary-dark));
    transition: width 0.6s ease;
}

.stats-card-success .stats-progress .progress-bar {
    background: linear-gradient(90deg, var(--success-color), #059669);
}

.stats-card-info .stats-progress .progress-bar {
    background: linear-gradient(90deg, var(--info-color), #0891b2);
}

.stats-card-warning .stats-progress .progress-bar {
    background: linear-gradient(90deg, var(--warning-color), #d97706);
}

.status-badge {
    display: inline-block;
    padding: 0.5rem 1rem;
    border-radius: 20px;
    font-size: 0.875rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

.status-success {
    background: linear-gradient(135deg, var(--success-color), #059669);
    color: white;
    box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
}

.status-danger {
    background: linear-gradient(135deg, var(--danger-color), #dc2626);
    color: white;
    box-shadow: 0 4px 12px rgba(239, 68, 68, 0.3);
}

/* 深色模式支持 */
@media (prefers-color-scheme: dark) {
    .stats-card {
        background: linear-gradient(135deg, rgba(30, 41, 59, 0.9), rgba(30, 41, 59, 0.7));
    }

    .stats-number {
        color: #e2e8f0;
    }

    .stats-label {
        color: #94a3b8;
    }

    .stats-description {
        color: #94a3b8;
    }
}

/* 响应式设计 */
@media (max-width: 768px) {
    .stats-card {
        margin-bottom: 1rem;
    }

    .stats-number {
        font-size: 1.5rem;
    }

    .stats-icon {
        width: 50px;
        height: 50px;
        font-size: 1.25rem;
    }
}
</style>

<?php
// 辅助函数
function getLogLevelColor($level) {
    switch (strtolower($level)) {
        case 'error':
            return 'danger';
        case 'warning':
            return 'warning';
        case 'info':
            return 'info';
        case 'debug':
            return 'secondary';
        default:
            return 'secondary';
    }
}
?>
