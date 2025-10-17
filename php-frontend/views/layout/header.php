<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $pageTitle ?? APP_NAME ?></title>
    
    <!-- 静态资源 -->
    <?= generateCssLinks(true) ?>
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
            --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
            --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
            --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
            --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);
            --sidebar-width: 280px;
            --header-height: 70px;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
            min-height: 100vh;
            color: var(--dark-color);
        }

        .sidebar {
            min-height: 100vh;
            background: linear-gradient(180deg, #1e293b 0%, #0f172a 100%);
            width: var(--sidebar-width);
            position: fixed;
            left: 0;
            top: 0;
            z-index: 1000;
            box-shadow: var(--shadow-xl);
            border-right: 1px solid rgba(255, 255, 255, 0.1);
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .sidebar .nav-link {
            color: #cbd5e1;
            padding: 0.875rem 1.5rem;
            margin: 0.25rem 1rem;
            border-radius: 12px;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            position: relative;
            overflow: hidden;
        }

        .sidebar .nav-link::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.1), transparent);
            transition: left 0.5s;
        }

        .sidebar .nav-link:hover::before {
            left: 100%;
        }

        .sidebar .nav-link:hover {
            color: #fff;
            background: rgba(99, 102, 241, 0.1);
            transform: translateX(4px);
        }

        .sidebar .nav-link.active {
            color: #fff;
            background: linear-gradient(135deg, var(--primary-color), var(--primary-dark));
            box-shadow: var(--shadow-md);
        }

        .sidebar .nav-link i {
            margin-right: 0.75rem;
            width: 20px;
            text-align: center;
        }

        .main-content {
            margin-left: var(--sidebar-width);
            transition: margin-left 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            min-height: 100vh;
            padding: 2rem;
        }

        .sidebar-collapsed .main-content {
            margin-left: 0;
        }

        .sidebar-collapsed .sidebar {
            transform: translateX(-100%);
        }

        .navbar-brand {
            font-weight: 700;
            font-size: 1.5rem;
            background: linear-gradient(135deg, var(--primary-color), var(--primary-dark));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .card {
            background: rgba(255, 255, 255, 0.8);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 16px;
            box-shadow: var(--shadow-lg);
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .card:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-xl);
        }

        .card-header {
            background: rgba(255, 255, 255, 0.1);
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 16px 16px 0 0 !important;
            padding: 1.5rem;
        }

        .table {
            border-radius: 12px;
            overflow: hidden;
        }

        .table th {
            border-top: none;
            font-weight: 600;
            background: rgba(99, 102, 241, 0.05);
            color: var(--dark-color);
            padding: 1rem;
        }

        .table td {
            padding: 1rem;
            border-color: rgba(0, 0, 0, 0.05);
        }

        .table tbody tr {
            transition: all 0.2s ease;
        }

        .table tbody tr:hover {
            background: rgba(99, 102, 241, 0.05);
            transform: scale(1.01);
        }

        .badge {
            font-size: 0.75em;
            padding: 0.5rem 0.75rem;
            border-radius: 8px;
            font-weight: 500;
        }

        .btn {
            border-radius: 12px;
            font-weight: 500;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            position: relative;
            overflow: hidden;
        }

        .btn::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
            transition: left 0.5s;
        }

        .btn:hover::before {
            left: 100%;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-lg);
        }

        .btn-sm {
            padding: 0.5rem 1rem;
            font-size: 0.875rem;
        }

        .btn-primary {
            background: linear-gradient(135deg, var(--primary-color), var(--primary-dark));
            border: none;
        }

        .btn-primary:hover {
            background: linear-gradient(135deg, var(--primary-dark), #3730a3);
        }

        .btn-success {
            background: linear-gradient(135deg, var(--success-color), #059669);
            border: none;
        }

        .btn-danger {
            background: linear-gradient(135deg, var(--danger-color), #dc2626);
            border: none;
        }

        .btn-warning {
            background: linear-gradient(135deg, var(--warning-color), #d97706);
            border: none;
        }

        .btn-info {
            background: linear-gradient(135deg, var(--info-color), #0891b2);
            border: none;
        }

        .loading {
            display: none;
        }

        .loading.show {
            display: block;
        }

        .alert {
            border: none;
            border-radius: 12px;
            padding: 1rem 1.5rem;
            backdrop-filter: blur(10px);
        }

        .alert-success {
            background: rgba(16, 185, 129, 0.1);
            color: var(--success-color);
            border: 1px solid rgba(16, 185, 129, 0.2);
        }

        .alert-danger {
            background: rgba(239, 68, 68, 0.1);
            color: var(--danger-color);
            border: 1px solid rgba(239, 68, 68, 0.2);
        }

        .alert-warning {
            background: rgba(245, 158, 11, 0.1);
            color: var(--warning-color);
            border: 1px solid rgba(245, 158, 11, 0.2);
        }

        .alert-info {
            background: rgba(6, 182, 212, 0.1);
            color: var(--info-color);
            border: 1px solid rgba(6, 182, 212, 0.2);
        }

        .form-control {
            border: 2px solid var(--border-color);
            border-radius: 12px;
            padding: 0.875rem 1rem;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            background: rgba(255, 255, 255, 0.8);
            backdrop-filter: blur(10px);
        }

        .form-control:focus {
            border-color: var(--primary-color);
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
            background: rgba(255, 255, 255, 1);
        }

        .text-success {
            color: var(--success-color) !important;
        }

        .text-danger {
            color: var(--danger-color) !important;
        }

        .text-warning {
            color: var(--warning-color) !important;
        }

        .text-info {
            color: var(--info-color) !important;
        }

        .text-primary {
            color: var(--primary-color) !important;
        }

        /* 页面标题样式 */
        .page-header {
            background: rgba(255, 255, 255, 0.8);
            backdrop-filter: blur(20px);
            border-radius: 16px;
            padding: 2rem;
            margin-bottom: 2rem;
            border: 1px solid rgba(255, 255, 255, 0.2);
            box-shadow: var(--shadow-md);
        }

        .page-title {
            font-size: 2rem;
            font-weight: 700;
            background: linear-gradient(135deg, var(--primary-color), var(--primary-dark));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 0.5rem;
        }

        .page-subtitle {
            color: var(--secondary-color);
            font-size: 1rem;
        }

        /* 响应式设计 */
        @media (max-width: 768px) {
            .sidebar {
                transform: translateX(-100%);
                width: 100%;
                z-index: 1050;
            }

            .sidebar.show {
                transform: translateX(0);
            }

            .main-content {
                margin-left: 0;
                padding: 1rem;
            }

            .page-header {
                padding: 1.5rem;
                margin-bottom: 1rem;
            }

            .page-title {
                font-size: 1.5rem;
            }

            .page-subtitle {
                font-size: 0.875rem;
            }

            /* 移动端按钮组 */
            .btn-toolbar {
                flex-direction: column;
                gap: 0.5rem;
            }

            .btn-group {
                width: 100%;
            }

            .btn-group .btn {
                flex: 1;
            }

            /* 移动端卡片 */
            .card {
                margin-bottom: 1rem;
            }

            .card-body {
                padding: 1rem;
            }

            /* 移动端表格 */
            .table-responsive {
                border-radius: 12px;
            }

            .table th,
            .table td {
                padding: 0.75rem 0.5rem;
                font-size: 0.875rem;
            }

            /* 移动端模态框 */
            .modal-dialog {
                margin: 0.5rem;
            }

            .modal-content {
                border-radius: 16px;
            }

            /* 移动端表单 */
            .form-floating {
                margin-bottom: 1rem;
            }

            .form-section {
                padding: 1rem;
                margin-bottom: 1rem;
            }

            /* 移动端导航 */
            .nav-link {
                padding: 1rem;
                font-size: 1rem;
            }

            .nav-link i {
                font-size: 1.25rem;
            }
        }

        @media (max-width: 576px) {
            .main-content {
                padding: 0.5rem;
            }

            .page-header {
                padding: 1rem;
                text-align: center;
            }

            .page-title {
                font-size: 1.25rem;
            }

            .btn-toolbar {
                margin-top: 1rem;
            }

            .btn-group .btn {
                padding: 0.75rem;
                font-size: 0.875rem;
            }

            /* 小屏幕卡片 */
            .card-body {
                padding: 0.75rem;
            }

            /* 小屏幕表格 */
            .table th,
            .table td {
                padding: 0.5rem 0.25rem;
                font-size: 0.8rem;
            }

            /* 小屏幕模态框 */
            .modal-dialog {
                margin: 0.25rem;
            }

            .modal-header {
                padding: 1rem;
            }

            .modal-body {
                padding: 1rem;
            }

            .modal-footer {
                padding: 1rem;
                flex-direction: column;
            }

            .modal-footer .btn {
                width: 100%;
                margin-bottom: 0.5rem;
            }

            /* 小屏幕表单 */
            .form-section {
                padding: 0.75rem;
            }

            .form-floating {
                margin-bottom: 0.75rem;
            }
        }

        /* 横屏模式优化 */
        @media (max-width: 768px) and (orientation: landscape) {
            .page-header {
                padding: 1rem;
            }

            .page-title {
                font-size: 1.25rem;
            }

            .main-content {
                padding: 0.75rem;
            }

            .card-body {
                padding: 0.75rem;
            }
        }

        /* 触摸设备优化 */
        @media (hover: none) and (pointer: coarse) {
            .btn {
                min-height: 44px;
                padding: 0.75rem 1rem;
            }

            .nav-link {
                min-height: 44px;
                display: flex;
                align-items: center;
            }

            .form-control {
                min-height: 44px;
                padding: 0.75rem;
            }

            .table tbody tr {
                min-height: 44px;
            }

            /* 移除悬停效果 */
            .card:hover {
                transform: none;
            }

            .btn:hover {
                transform: none;
            }

            .nav-link:hover {
                transform: none;
            }
        }

        /* 深色模式支持 */
        @media (prefers-color-scheme: dark) {
            body {
                background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
                color: #e2e8f0;
            }

            .card {
                background: rgba(30, 41, 59, 0.8);
                border-color: rgba(255, 255, 255, 0.1);
            }

            .form-control {
                background: rgba(51, 65, 85, 0.8);
                border-color: rgba(255, 255, 255, 0.1);
                color: #e2e8f0;
            }

            .form-control:focus {
                background: rgba(51, 65, 85, 1);
            }

            .table th {
                background: rgba(99, 102, 241, 0.1);
                color: #e2e8f0;
            }

            .page-header {
                background: rgba(30, 41, 59, 0.8);
                border-color: rgba(255, 255, 255, 0.1);
            }
        }

        /* 动画效果 */
        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .fade-in-up {
            animation: fadeInUp 0.6s ease-out;
        }

        @keyframes slideInLeft {
            from {
                opacity: 0;
                transform: translateX(-30px);
            }
            to {
                opacity: 1;
                transform: translateX(0);
            }
        }

        .slide-in-left {
            animation: slideInLeft 0.6s ease-out;
        }

        /* 加载动画 */
        .spinner {
            width: 20px;
            height: 20px;
            border: 2px solid rgba(255, 255, 255, 0.3);
            border-top: 2px solid #fff;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        /* 页面过渡动画 */
        @keyframes pageTransition {
            from {
                opacity: 0;
                transform: translateY(20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .page-transition {
            animation: pageTransition 0.6s ease-out;
        }

        /* 卡片悬停效果 */
        .card-hover {
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .card-hover:hover {
            transform: translateY(-4px);
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
        }

        /* 按钮脉冲效果 */
        @keyframes pulse {
            0% {
                box-shadow: 0 0 0 0 rgba(99, 102, 241, 0.4);
            }
            70% {
                box-shadow: 0 0 0 10px rgba(99, 102, 241, 0);
            }
            100% {
                box-shadow: 0 0 0 0 rgba(99, 102, 241, 0);
            }
        }

        .btn-pulse {
            animation: pulse 2s infinite;
        }

        /* 加载骨架屏 */
        @keyframes shimmer {
            0% {
                background-position: -200px 0;
            }
            100% {
                background-position: calc(200px + 100%) 0;
            }
        }

        .skeleton {
            background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
            background-size: 200px 100%;
            animation: shimmer 1.5s infinite;
        }

        /* 表格行动画 */
        .table tbody tr {
            animation: slideInRow 0.3s ease-out;
        }

        @keyframes slideInRow {
            from {
                opacity: 0;
                transform: translateX(-20px);
            }
            to {
                opacity: 1;
                transform: translateX(0);
            }
        }

        /* 通知动画 */
        @keyframes slideInNotification {
            from {
                opacity: 0;
                transform: translateX(100%);
            }
            to {
                opacity: 1;
                transform: translateX(0);
            }
        }

        .notification-slide-in {
            animation: slideInNotification 0.3s ease-out;
        }

        /* 进度条动画 */
        @keyframes progressFill {
            from {
                width: 0%;
            }
            to {
                width: var(--progress-width);
            }
        }

        .progress-animated {
            animation: progressFill 1s ease-out;
        }

        /* 图标旋转动画 */
        @keyframes iconRotate {
            from {
                transform: rotate(0deg);
            }
            to {
                transform: rotate(360deg);
            }
        }

        .icon-rotate {
            animation: iconRotate 1s linear infinite;
        }

        /* 文字打字机效果 */
        @keyframes typewriter {
            from {
                width: 0;
            }
            to {
                width: 100%;
            }
        }

        .typewriter {
            overflow: hidden;
            border-right: 2px solid var(--primary-color);
            white-space: nowrap;
            animation: typewriter 3s steps(40, end);
        }

        /* 浮动动画 */
        @keyframes float {
            0%, 100% {
                transform: translateY(0px);
            }
            50% {
                transform: translateY(-10px);
            }
        }

        .float-animation {
            animation: float 3s ease-in-out infinite;
        }

        /* 渐变背景动画 */
        @keyframes gradientShift {
            0% {
                background-position: 0% 50%;
            }
            50% {
                background-position: 100% 50%;
            }
            100% {
                background-position: 0% 50%;
            }
        }

        .gradient-animated {
            background: linear-gradient(-45deg, var(--primary-color), var(--primary-dark), var(--info-color), var(--success-color));
            background-size: 400% 400%;
            animation: gradientShift 15s ease infinite;
        }

        /* 波纹效果 */
        .ripple {
            position: absolute;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.6);
            transform: scale(0);
            animation: ripple-animation 0.6s linear;
            pointer-events: none;
        }

        @keyframes ripple-animation {
            to {
                transform: scale(4);
                opacity: 0;
            }
        }

        /* 焦点状态样式 */
        .focused {
            transform: scale(1.02);
            transition: transform 0.2s ease;
        }

        /* 深色模式下的骨架屏 */
        @media (prefers-color-scheme: dark) {
            .skeleton {
                background: linear-gradient(90deg, #374151 25%, #4b5563 50%, #374151 75%);
                background-size: 200px 100%;
            }
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
                <!-- 页面标题区域 -->
                <div class="page-header fade-in-up">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <h1 class="page-title"><?= $pageTitle ?? '仪表板' ?></h1>
                            <p class="page-subtitle mb-0"><?= $pageSubtitle ?? '欢迎使用IPv6 WireGuard管理系统' ?></p>
                        </div>
                        <div class="btn-toolbar">
                            <div class="btn-group me-2">
                                <button type="button" class="btn btn-outline-primary" onclick="refreshPage()" title="刷新页面">
                                    <i class="bi bi-arrow-clockwise"></i>
                                </button>
                                <button type="button" class="btn btn-outline-secondary" onclick="toggleSidebar()" title="切换侧边栏">
                                    <i class="bi bi-list"></i>
                                </button>
                            </div>
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
