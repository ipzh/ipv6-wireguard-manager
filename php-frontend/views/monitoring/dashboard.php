<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= APP_NAME ?> - 监控仪表板</title>
    
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

        .metric-card {
            border: none;
            border-radius: 16px;
            box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
            transition: all 0.3s ease;
            background: linear-gradient(135deg, #fff 0%, #f8fafc 100%);
        }

        .metric-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1);
        }

        .metric-icon {
            width: 60px;
            height: 60px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
            color: white;
        }

        .metric-value {
            font-size: 2rem;
            font-weight: 700;
            margin: 0;
        }

        .metric-label {
            color: var(--secondary-color);
            font-size: 0.875rem;
            margin: 0;
        }

        .metric-change {
            font-size: 0.75rem;
            font-weight: 600;
        }

        .change-positive {
            color: var(--success-color);
        }

        .change-negative {
            color: var(--danger-color);
        }

        .chart-container {
            position: relative;
            height: 300px;
        }

        .alert-card {
            border-left: 4px solid var(--warning-color);
            background: rgba(245, 158, 11, 0.1);
        }

        .alert-critical {
            border-left-color: var(--danger-color);
            background: rgba(239, 68, 68, 0.1);
        }

        .alert-info {
            border-left-color: var(--info-color);
            background: rgba(6, 182, 212, 0.1);
        }

        .status-indicator {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            display: inline-block;
            margin-right: 8px;
        }

        .status-healthy {
            background-color: var(--success-color);
            box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.2);
        }

        .status-warning {
            background-color: var(--warning-color);
            box-shadow: 0 0 0 2px rgba(245, 158, 11, 0.2);
        }

        .status-error {
            background-color: var(--danger-color);
            box-shadow: 0 0 0 2px rgba(239, 68, 68, 0.2);
        }

        .refresh-btn {
            position: fixed;
            bottom: 20px;
            right: 20px;
            z-index: 1000;
        }

        .auto-refresh {
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
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
                <a class="nav-link active" href="/monitoring">
                    <i class="bi bi-graph-up me-1"></i>监控
                </a>
                <a class="nav-link" href="/security">
                    <i class="bi bi-shield-check me-1"></i>安全
                </a>
                <a class="nav-link" href="/logout">
                    <i class="bi bi-box-arrow-right me-1"></i>退出
                </a>
            </div>
        </div>
    </nav>

    <div class="container-fluid py-4">
        <!-- 页面标题 -->
        <div class="row mb-4">
            <div class="col-12">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h2 class="mb-1">
                            <i class="bi bi-graph-up me-2"></i>监控仪表板
                        </h2>
                        <p class="text-muted mb-0">实时监控系统性能和健康状态</p>
                    </div>
                    <div class="d-flex gap-2">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" id="autoRefresh" checked>
                            <label class="form-check-label" for="autoRefresh">
                                自动刷新
                            </label>
                        </div>
                        <button class="btn btn-outline-primary" id="refreshBtn">
                            <i class="bi bi-arrow-clockwise me-2"></i>刷新
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 系统概览指标 -->
        <div class="row mb-4">
            <div class="col-lg-3 col-md-6 mb-3">
                <div class="card metric-card">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="metric-icon bg-primary me-3">
                                <i class="bi bi-cpu"></i>
                            </div>
                            <div class="flex-grow-1">
                                <p class="metric-value" id="cpuUsage">--</p>
                                <p class="metric-label">CPU使用率</p>
                                <small class="metric-change change-positive" id="cpuChange">
                                    <i class="bi bi-arrow-up"></i> +2.5%
                                </small>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="col-lg-3 col-md-6 mb-3">
                <div class="card metric-card">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="metric-icon bg-info me-3">
                                <i class="bi bi-memory"></i>
                            </div>
                            <div class="flex-grow-1">
                                <p class="metric-value" id="memoryUsage">--</p>
                                <p class="metric-label">内存使用率</p>
                                <small class="metric-change change-positive" id="memoryChange">
                                    <i class="bi bi-arrow-up"></i> +1.2%
                                </small>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="col-lg-3 col-md-6 mb-3">
                <div class="card metric-card">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="metric-icon bg-success me-3">
                                <i class="bi bi-hdd"></i>
                            </div>
                            <div class="flex-grow-1">
                                <p class="metric-value" id="diskUsage">--</p>
                                <p class="metric-label">磁盘使用率</p>
                                <small class="metric-change change-negative" id="diskChange">
                                    <i class="bi bi-arrow-down"></i> -0.5%
                                </small>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="col-lg-3 col-md-6 mb-3">
                <div class="card metric-card">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="metric-icon bg-warning me-3">
                                <i class="bi bi-activity"></i>
                            </div>
                            <div class="flex-grow-1">
                                <p class="metric-value" id="activeConnections">--</p>
                                <p class="metric-label">活跃连接</p>
                                <small class="metric-change change-positive" id="connectionsChange">
                                    <i class="bi bi-arrow-up"></i> +5
                                </small>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 图表区域 -->
        <div class="row mb-4">
            <div class="col-lg-8 mb-4">
                <div class="card metric-card">
                    <div class="card-header">
                        <h5 class="mb-0">
                            <i class="bi bi-graph-up me-2"></i>系统性能趋势
                        </h5>
                    </div>
                    <div class="card-body">
                        <div class="chart-container">
                            <canvas id="performanceChart"></canvas>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="col-lg-4 mb-4">
                <div class="card metric-card">
                    <div class="card-header">
                        <h5 class="mb-0">
                            <i class="bi bi-pie-chart me-2"></i>服务状态
                        </h5>
                    </div>
                    <div class="card-body">
                        <div id="serviceStatus">
                            <!-- 服务状态将在这里显示 -->
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 告警和日志 -->
        <div class="row">
            <div class="col-lg-6 mb-4">
                <div class="card metric-card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">
                            <i class="bi bi-exclamation-triangle me-2"></i>活跃告警
                        </h5>
                        <span class="badge bg-danger" id="alertCount">0</span>
                    </div>
                    <div class="card-body">
                        <div id="alertsList">
                            <!-- 告警列表将在这里显示 -->
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="col-lg-6 mb-4">
                <div class="card metric-card">
                    <div class="card-header">
                        <h5 class="mb-0">
                            <i class="bi bi-clock-history me-2"></i>最近日志
                        </h5>
                    </div>
                    <div class="card-body">
                        <div id="recentLogs">
                            <!-- 最近日志将在这里显示 -->
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- WireGuard状态 -->
        <div class="row">
            <div class="col-12">
                <div class="card metric-card">
                    <div class="card-header">
                        <h5 class="mb-0">
                            <i class="bi bi-shield-lock me-2"></i>WireGuard状态
                        </h5>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-3">
                                <div class="text-center">
                                    <div class="metric-icon bg-primary mx-auto mb-2">
                                        <i class="bi bi-server"></i>
                                    </div>
                                    <h4 id="wgServers">--</h4>
                                    <p class="text-muted">服务器</p>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="text-center">
                                    <div class="metric-icon bg-success mx-auto mb-2">
                                        <i class="bi bi-people"></i>
                                    </div>
                                    <h4 id="wgClients">--</h4>
                                    <p class="text-muted">客户端</p>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="text-center">
                                    <div class="metric-icon bg-info mx-auto mb-2">
                                        <i class="bi bi-wifi"></i>
                                    </div>
                                    <h4 id="wgSessions">--</h4>
                                    <p class="text-muted">活跃会话</p>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="text-center">
                                    <div class="metric-icon bg-warning mx-auto mb-2">
                                        <i class="bi bi-globe"></i>
                                    </div>
                                    <h4 id="wgTraffic">--</h4>
                                    <p class="text-muted">流量 (GB)</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 刷新按钮 -->
    <button class="btn btn-primary refresh-btn" id="floatingRefreshBtn">
        <i class="bi bi-arrow-clockwise"></i>
    </button>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    <script>
        let performanceChart;
        let autoRefreshInterval;
        
        document.addEventListener('DOMContentLoaded', function() {
            // 初始化图表
            initPerformanceChart();
            
            // 加载初始数据
            loadDashboardData();
            
            // 设置自动刷新
            setupAutoRefresh();
            
            // 绑定事件
            document.getElementById('refreshBtn').addEventListener('click', loadDashboardData);
            document.getElementById('floatingRefreshBtn').addEventListener('click', loadDashboardData);
            document.getElementById('autoRefresh').addEventListener('change', toggleAutoRefresh);
        });
        
        function initPerformanceChart() {
            const ctx = document.getElementById('performanceChart').getContext('2d');
            performanceChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'CPU使用率',
                        data: [],
                        borderColor: '#6366f1',
                        backgroundColor: 'rgba(99, 102, 241, 0.1)',
                        tension: 0.4
                    }, {
                        label: '内存使用率',
                        data: [],
                        borderColor: '#06b6d4',
                        backgroundColor: 'rgba(6, 182, 212, 0.1)',
                        tension: 0.4
                    }, {
                        label: '磁盘使用率',
                        data: [],
                        borderColor: '#10b981',
                        backgroundColor: 'rgba(16, 185, 129, 0.1)',
                        tension: 0.4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            beginAtZero: true,
                            max: 100,
                            ticks: {
                                callback: function(value) {
                                    return value + '%';
                                }
                            }
                        }
                    },
                    plugins: {
                        legend: {
                            position: 'top',
                        }
                    }
                }
            });
        }
        
        function loadDashboardData() {
            // 加载系统指标
            loadSystemMetrics();
            
            // 加载服务状态
            loadServiceStatus();
            
            // 加载告警
            loadAlerts();
            
            // 加载日志
            loadRecentLogs();
            
            // 加载WireGuard状态
            loadWireGuardStatus();
            
            // 更新图表
            updatePerformanceChart();
        }
        
        function loadSystemMetrics() {
            fetch('/api/v1/monitoring/metrics')
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    document.getElementById('cpuUsage').textContent = data.metrics.cpu_usage + '%';
                    document.getElementById('memoryUsage').textContent = data.metrics.memory_usage + '%';
                    document.getElementById('diskUsage').textContent = data.metrics.disk_usage + '%';
                    document.getElementById('activeConnections').textContent = data.metrics.active_connections;
                    
                    // 更新变化趋势
                    updateMetricChange('cpuChange', data.metrics.cpu_change);
                    updateMetricChange('memoryChange', data.metrics.memory_change);
                    updateMetricChange('diskChange', data.metrics.disk_change);
                    updateMetricChange('connectionsChange', data.metrics.connections_change);
                }
            })
            .catch(error => {
                console.error('加载系统指标失败:', error);
            });
        }
        
        function loadServiceStatus() {
            fetch('/api/v1/monitoring/services')
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    const container = document.getElementById('serviceStatus');
                    container.innerHTML = data.services.map(service => `
                        <div class="d-flex justify-content-between align-items-center mb-3">
                            <div>
                                <span class="status-indicator status-${service.status}"></span>
                                <strong>${service.name}</strong>
                            </div>
                            <span class="badge bg-${getStatusBadgeClass(service.status)}">
                                ${service.status}
                            </span>
                        </div>
                    `).join('');
                }
            });
        }
        
        function loadAlerts() {
            fetch('/api/v1/alerts')
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    document.getElementById('alertCount').textContent = data.alerts.length;
                    
                    const container = document.getElementById('alertsList');
                    if (data.alerts.length === 0) {
                        container.innerHTML = '<p class="text-muted text-center">暂无活跃告警</p>';
                    } else {
                        container.innerHTML = data.alerts.map(alert => `
                            <div class="alert-card p-3 mb-3 rounded">
                                <div class="d-flex justify-content-between align-items-start">
                                    <div>
                                        <h6 class="mb-1">${alert.title}</h6>
                                        <p class="mb-1 small">${alert.description}</p>
                                        <small class="text-muted">${new Date(alert.timestamp).toLocaleString()}</small>
                                    </div>
                                    <span class="badge bg-${getSeverityBadgeClass(alert.severity)}">
                                        ${alert.severity}
                                    </span>
                                </div>
                            </div>
                        `).join('');
                    }
                }
            });
        }
        
        function loadRecentLogs() {
            fetch('/api/v1/logs/recent')
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    const container = document.getElementById('recentLogs');
                    container.innerHTML = data.logs.map(log => `
                        <div class="d-flex justify-content-between align-items-start mb-3">
                            <div class="flex-grow-1">
                                <div class="d-flex align-items-center mb-1">
                                    <span class="badge bg-${getLogLevelBadgeClass(log.level)} me-2">
                                        ${log.level}
                                    </span>
                                    <small class="text-muted">${new Date(log.timestamp).toLocaleString()}</small>
                                </div>
                                <p class="mb-0 small">${log.message}</p>
                            </div>
                        </div>
                    `).join('');
                }
            });
        }
        
        function loadWireGuardStatus() {
            fetch('/api/v1/wireguard/status')
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    document.getElementById('wgServers').textContent = data.wireguard.servers;
                    document.getElementById('wgClients').textContent = data.wireguard.clients;
                    document.getElementById('wgSessions').textContent = data.wireguard.active_sessions;
                    document.getElementById('wgTraffic').textContent = data.wireguard.traffic_gb;
                }
            });
        }
        
        function updatePerformanceChart() {
            fetch('/api/v1/monitoring/performance-history')
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    const now = new Date();
                    const labels = data.history.map((_, index) => {
                        const time = new Date(now.getTime() - (data.history.length - index - 1) * 60000);
                        return time.toLocaleTimeString();
                    });
                    
                    performanceChart.data.labels = labels;
                    performanceChart.data.datasets[0].data = data.history.map(h => h.cpu);
                    performanceChart.data.datasets[1].data = data.history.map(h => h.memory);
                    performanceChart.data.datasets[2].data = data.history.map(h => h.disk);
                    
                    performanceChart.update();
                }
            });
        }
        
        function updateMetricChange(elementId, change) {
            const element = document.getElementById(elementId);
            const isPositive = change > 0;
            const icon = isPositive ? 'bi-arrow-up' : 'bi-arrow-down';
            const className = isPositive ? 'change-positive' : 'change-negative';
            
            element.innerHTML = `<i class="bi ${icon}"></i> ${isPositive ? '+' : ''}${change}%`;
            element.className = `metric-change ${className}`;
        }
        
        function getStatusBadgeClass(status) {
            switch(status) {
                case 'healthy': return 'success';
                case 'warning': return 'warning';
                case 'error': return 'danger';
                default: return 'secondary';
            }
        }
        
        function getSeverityBadgeClass(severity) {
            switch(severity) {
                case 'critical': return 'danger';
                case 'high': return 'warning';
                case 'medium': return 'info';
                case 'low': return 'secondary';
                default: return 'secondary';
            }
        }
        
        function getLogLevelBadgeClass(level) {
            switch(level) {
                case 'error': return 'danger';
                case 'warning': return 'warning';
                case 'info': return 'info';
                default: return 'secondary';
            }
        }
        
        function setupAutoRefresh() {
            if (document.getElementById('autoRefresh').checked) {
                autoRefreshInterval = setInterval(loadDashboardData, 30000); // 30秒刷新
                document.getElementById('floatingRefreshBtn').classList.add('auto-refresh');
            }
        }
        
        function toggleAutoRefresh() {
            if (document.getElementById('autoRefresh').checked) {
                setupAutoRefresh();
            } else {
                clearInterval(autoRefreshInterval);
                document.getElementById('floatingRefreshBtn').classList.remove('auto-refresh');
            }
        }
    </script>
</body>
</html>