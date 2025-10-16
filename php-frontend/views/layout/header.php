<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $pageTitle ?? APP_NAME ?></title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.7.2/font/bootstrap-icons.css" rel="stylesheet">
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    
    <style>
        .sidebar {
            min-height: 100vh;
            background-color: #343a40;
        }
        .sidebar .nav-link {
            color: #adb5bd;
        }
        .sidebar .nav-link:hover {
            color: #fff;
            background-color: #495057;
        }
        .sidebar .nav-link.active {
            color: #fff;
            background-color: #007bff;
        }
        .main-content {
            margin-left: 0;
            transition: margin-left 0.3s;
        }
        .sidebar-collapsed .main-content {
            margin-left: -250px;
        }
        .navbar-brand {
            font-weight: bold;
        }
        .card {
            box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
            border: 1px solid rgba(0, 0, 0, 0.125);
        }
        .table th {
            border-top: none;
            font-weight: 600;
        }
        .badge {
            font-size: 0.75em;
        }
        .btn-sm {
            padding: 0.25rem 0.5rem;
            font-size: 0.875rem;
        }
        .loading {
            display: none;
        }
        .loading.show {
            display: block;
        }
        .alert {
            border: none;
            border-radius: 0.375rem;
        }
        .form-control:focus {
            border-color: #80bdff;
            box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
        }
        .btn-primary {
            background-color: #007bff;
            border-color: #007bff;
        }
        .btn-primary:hover {
            background-color: #0056b3;
            border-color: #0056b3;
        }
        .text-success {
            color: #198754 !important;
        }
        .text-danger {
            color: #dc3545 !important;
        }
        .text-warning {
            color: #fd7e14 !important;
        }
        .text-info {
            color: #0dcaf0 !important;
        }
    </style>
</head>
<body>
    <?php if (isset($showSidebar) && $showSidebar): ?>
    <div class="container-fluid">
        <div class="row">
            <!-- 侧边栏 -->
            <nav class="col-md-3 col-lg-2 d-md-block sidebar collapse" id="sidebar">
                <div class="position-sticky pt-3">
                    <div class="text-center mb-3">
                        <h5 class="text-white"><?= APP_NAME ?></h5>
                        <small class="text-muted">v<?= APP_VERSION ?></small>
                    </div>
                    
                    <ul class="nav flex-column">
                        <li class="nav-item">
                            <a class="nav-link <?= Router::currentPath() === '/' ? 'active' : '' ?>" href="/">
                                <i class="bi bi-speedometer2"></i> 仪表板
                            </a>
                        </li>
                        
                        <!-- WireGuard管理 -->
                        <li class="nav-item">
                            <a class="nav-link <?= strpos(Router::currentPath(), '/wireguard') === 0 ? 'active' : '' ?>" 
                               data-bs-toggle="collapse" href="#wireguardMenu" role="button">
                                <i class="bi bi-shield-lock"></i> WireGuard管理 <i class="bi bi-chevron-down"></i>
                            </a>
                            <div class="collapse <?= strpos(Router::currentPath(), '/wireguard') === 0 ? 'show' : '' ?>" id="wireguardMenu">
                                <ul class="nav flex-column ms-3">
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/wireguard/servers' ? 'active' : '' ?>" href="/wireguard/servers">
                                            <i class="bi bi-server"></i> 服务器管理
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/wireguard/clients' ? 'active' : '' ?>" href="/wireguard/clients">
                                            <i class="bi bi-people"></i> 客户端管理
                                        </a>
                                    </li>
                                </ul>
                            </div>
                        </li>
                        
                        <!-- BGP管理 -->
                        <li class="nav-item">
                            <a class="nav-link <?= strpos(Router::currentPath(), '/bgp') === 0 ? 'active' : '' ?>" 
                               data-bs-toggle="collapse" href="#bgpMenu" role="button">
                                <i class="bi bi-diagram-3"></i> BGP管理 <i class="bi bi-chevron-down"></i>
                            </a>
                            <div class="collapse <?= strpos(Router::currentPath(), '/bgp') === 0 ? 'show' : '' ?>" id="bgpMenu">
                                <ul class="nav flex-column ms-3">
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/bgp/sessions' ? 'active' : '' ?>" href="/bgp/sessions">
                                            <i class="bi bi-link-45deg"></i> 会话管理
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/bgp/announcements' ? 'active' : '' ?>" href="/bgp/announcements">
                                            <i class="bi bi-broadcast"></i> 宣告管理
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/bgp/status' ? 'active' : '' ?>" href="/bgp/status">
                                            <i class="bi bi-activity"></i> 状态监控
                                        </a>
                                    </li>
                                </ul>
                            </div>
                        </li>
                        
                        <!-- IPv6管理 -->
                        <li class="nav-item">
                            <a class="nav-link <?= strpos(Router::currentPath(), '/ipv6') === 0 ? 'active' : '' ?>" 
                               data-bs-toggle="collapse" href="#ipv6Menu" role="button">
                                <i class="bi bi-globe"></i> IPv6管理 <i class="bi bi-chevron-down"></i>
                            </a>
                            <div class="collapse <?= strpos(Router::currentPath(), '/ipv6') === 0 ? 'show' : '' ?>" id="ipv6Menu">
                                <ul class="nav flex-column ms-3">
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/ipv6/pools' ? 'active' : '' ?>" href="/ipv6/pools">
                                            <i class="bi bi-collection"></i> 前缀池管理
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/ipv6/allocations' ? 'active' : '' ?>" href="/ipv6/allocations">
                                            <i class="bi bi-diagram-2"></i> 前缀分配
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/ipv6/statistics' ? 'active' : '' ?>" href="/ipv6/statistics">
                                            <i class="bi bi-graph-up"></i> 统计分析
                                        </a>
                                    </li>
                                </ul>
                            </div>
                        </li>
                        
                        <!-- 系统监控 -->
                        <li class="nav-item">
                            <a class="nav-link <?= strpos(Router::currentPath(), '/monitoring') === 0 ? 'active' : '' ?>" 
                               data-bs-toggle="collapse" href="#monitoringMenu" role="button">
                                <i class="bi bi-graph-up"></i> 系统监控 <i class="bi bi-chevron-down"></i>
                            </a>
                            <div class="collapse <?= strpos(Router::currentPath(), '/monitoring') === 0 ? 'show' : '' ?>" id="monitoringMenu">
                                <ul class="nav flex-column ms-3">
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/monitoring' ? 'active' : '' ?>" href="/monitoring">
                                            <i class="bi bi-speedometer2"></i> 监控仪表板
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/monitoring/metrics' ? 'active' : '' ?>" href="/monitoring/metrics">
                                            <i class="bi bi-cpu"></i> 系统指标
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/monitoring/alerts' ? 'active' : '' ?>" href="/monitoring/alerts">
                                            <i class="bi bi-exclamation-triangle"></i> 告警管理
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/monitoring/processes' ? 'active' : '' ?>" href="/monitoring/processes">
                                            <i class="bi bi-list-task"></i> 进程管理
                                        </a>
                                    </li>
                                </ul>
                            </div>
                        </li>
                        
                        <!-- 日志管理 -->
                        <li class="nav-item">
                            <a class="nav-link <?= strpos(Router::currentPath(), '/logs') === 0 ? 'active' : '' ?>" 
                               data-bs-toggle="collapse" href="#logsMenu" role="button">
                                <i class="bi bi-journal-text"></i> 日志管理 <i class="bi bi-chevron-down"></i>
                            </a>
                            <div class="collapse <?= strpos(Router::currentPath(), '/logs') === 0 ? 'show' : '' ?>" id="logsMenu">
                                <ul class="nav flex-column ms-3">
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/logs' ? 'active' : '' ?>" href="/logs">
                                            <i class="bi bi-list"></i> 日志列表
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/logs/search' ? 'active' : '' ?>" href="/logs/search">
                                            <i class="bi bi-search"></i> 日志搜索
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/logs/stream' ? 'active' : '' ?>" href="/logs/stream">
                                            <i class="bi bi-broadcast"></i> 实时日志
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/logs/statistics' ? 'active' : '' ?>" href="/logs/statistics">
                                            <i class="bi bi-graph-up"></i> 日志统计
                                        </a>
                                    </li>
                                </ul>
                            </div>
                        </li>
                        
                        <!-- 用户管理 -->
                        <li class="nav-item">
                            <a class="nav-link <?= strpos(Router::currentPath(), '/users') === 0 ? 'active' : '' ?>" 
                               data-bs-toggle="collapse" href="#usersMenu" role="button">
                                <i class="bi bi-people"></i> 用户管理 <i class="bi bi-chevron-down"></i>
                            </a>
                            <div class="collapse <?= strpos(Router::currentPath(), '/users') === 0 ? 'show' : '' ?>" id="usersMenu">
                                <ul class="nav flex-column ms-3">
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/users' ? 'active' : '' ?>" href="/users">
                                            <i class="bi bi-person-lines-fill"></i> 用户列表
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/users/roles' ? 'active' : '' ?>" href="/users/roles">
                                            <i class="bi bi-shield-check"></i> 角色管理
                                        </a>
                                    </li>
                                </ul>
                            </div>
                        </li>
                        
                        <!-- 系统管理 -->
                        <li class="nav-item">
                            <a class="nav-link <?= strpos(Router::currentPath(), '/system') === 0 ? 'active' : '' ?>" 
                               data-bs-toggle="collapse" href="#systemMenu" role="button">
                                <i class="bi bi-gear"></i> 系统管理 <i class="bi bi-chevron-down"></i>
                            </a>
                            <div class="collapse <?= strpos(Router::currentPath(), '/system') === 0 ? 'show' : '' ?>" id="systemMenu">
                                <ul class="nav flex-column ms-3">
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/system/info' ? 'active' : '' ?>" href="/system/info">
                                            <i class="bi bi-info-circle"></i> 系统信息
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/system/config' ? 'active' : '' ?>" href="/system/config">
                                            <i class="bi bi-sliders"></i> 系统配置
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/system/services' ? 'active' : '' ?>" href="/system/services">
                                            <i class="bi bi-play-circle"></i> 服务管理
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/system/backup' ? 'active' : '' ?>" href="/system/backup">
                                            <i class="bi bi-archive"></i> 备份管理
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/system/update' ? 'active' : '' ?>" href="/system/update">
                                            <i class="bi bi-arrow-up-circle"></i> 系统更新
                                        </a>
                                    </li>
                                </ul>
                            </div>
                        </li>
                        
                        <!-- 网络管理 -->
                        <li class="nav-item">
                            <a class="nav-link <?= strpos(Router::currentPath(), '/network') === 0 ? 'active' : '' ?>" 
                               data-bs-toggle="collapse" href="#networkMenu" role="button">
                                <i class="bi bi-wifi"></i> 网络管理 <i class="bi bi-chevron-down"></i>
                            </a>
                            <div class="collapse <?= strpos(Router::currentPath(), '/network') === 0 ? 'show' : '' ?>" id="networkMenu">
                                <ul class="nav flex-column ms-3">
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/network/interfaces' ? 'active' : '' ?>" href="/network/interfaces">
                                            <i class="bi bi-ethernet"></i> 网络接口
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/network/routes' ? 'active' : '' ?>" href="/network/routes">
                                            <i class="bi bi-diagram-3"></i> 路由表
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/network/firewall' ? 'active' : '' ?>" href="/network/firewall">
                                            <i class="bi bi-shield"></i> 防火墙
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link <?= Router::currentPath() === '/network/diagnostics' ? 'active' : '' ?>" href="/network/diagnostics">
                                            <i class="bi bi-tools"></i> 网络诊断
                                        </a>
                                    </li>
                                </ul>
                            </div>
                        </li>
                    </ul>
                    
                    <hr class="text-white">
                    
                    <div class="dropdown">
                        <a href="#" class="d-flex align-items-center text-white text-decoration-none dropdown-toggle" id="dropdownUser1" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="bi bi-person-circle me-2"></i>
                            <strong><?= htmlspecialchars($_SESSION['user']['username'] ?? '用户') ?></strong>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-dark text-small shadow" aria-labelledby="dropdownUser1">
                            <li><a class="dropdown-item" href="/settings">设置</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="/logout">登出</a></li>
                        </ul>
                    </div>
                </div>
            </nav>
            
            <!-- 主内容区域 -->
            <main class="col-md-9 ms-sm-auto col-lg-10 px-md-4 main-content">
                <!-- 顶部导航栏 -->
                <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
                    <h1 class="h2"><?= $pageTitle ?? '仪表板' ?></h1>
                    <div class="btn-toolbar mb-2 mb-md-0">
                        <div class="btn-group me-2">
                            <button type="button" class="btn btn-sm btn-outline-secondary" onclick="refreshPage()">
                                <i class="bi bi-arrow-clockwise"></i> 刷新
                            </button>
                        </div>
                    </div>
                </div>
                
                <!-- 消息提示区域 -->
                <div id="messageArea"></div>
                
                <!-- 页面内容 -->
                <div class="content">
    <?php else: ?>
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-md-6">
                <!-- 消息提示区域 -->
                <div id="messageArea"></div>
                
                <!-- 页面内容 -->
                <div class="content">
    <?php endif; ?>
