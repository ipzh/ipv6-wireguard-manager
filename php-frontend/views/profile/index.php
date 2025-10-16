<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $pageTitle ?> - <?= APP_NAME ?></title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
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
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: var(--light-color);
            color: var(--dark-color);
            line-height: 1.6;
        }

        .profile-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 2rem;
        }

        .profile-header {
            background: white;
            border-radius: 12px;
            padding: 2rem;
            box-shadow: var(--shadow-sm);
            margin-bottom: 2rem;
            border: 1px solid var(--border-color);
        }

        .profile-avatar {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--primary-color), var(--primary-dark));
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 2rem;
            font-weight: 600;
            margin-bottom: 1rem;
        }

        .profile-info h1 {
            font-size: 1.875rem;
            font-weight: 700;
            color: var(--dark-color);
            margin-bottom: 0.5rem;
        }

        .profile-info p {
            color: var(--secondary-color);
            font-size: 1rem;
        }

        .profile-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin-top: 2rem;
        }

        .stat-card {
            background: white;
            border-radius: 8px;
            padding: 1.5rem;
            box-shadow: var(--shadow-sm);
            border: 1px solid var(--border-color);
            text-align: center;
        }

        .stat-number {
            font-size: 2rem;
            font-weight: 700;
            color: var(--primary-color);
            margin-bottom: 0.5rem;
        }

        .stat-label {
            color: var(--secondary-color);
            font-size: 0.875rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        .profile-actions {
            display: flex;
            gap: 1rem;
            margin-top: 2rem;
            flex-wrap: wrap;
        }

        .btn {
            padding: 0.75rem 1.5rem;
            border-radius: 8px;
            font-weight: 500;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            transition: all 0.2s ease;
            border: none;
            cursor: pointer;
        }

        .btn-primary {
            background: var(--primary-color);
            color: white;
        }

        .btn-primary:hover {
            background: var(--primary-dark);
            color: white;
            transform: translateY(-1px);
        }

        .btn-outline {
            background: transparent;
            color: var(--primary-color);
            border: 1px solid var(--primary-color);
        }

        .btn-outline:hover {
            background: var(--primary-color);
            color: white;
        }

        .btn-danger {
            background: var(--danger-color);
            color: white;
        }

        .btn-danger:hover {
            background: #dc2626;
            color: white;
        }

        .profile-details {
            background: white;
            border-radius: 12px;
            padding: 2rem;
            box-shadow: var(--shadow-sm);
            border: 1px solid var(--border-color);
        }

        .detail-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 1rem 0;
            border-bottom: 1px solid var(--border-color);
        }

        .detail-item:last-child {
            border-bottom: none;
        }

        .detail-label {
            font-weight: 500;
            color: var(--dark-color);
        }

        .detail-value {
            color: var(--secondary-color);
        }

        .status-badge {
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        .status-active {
            background: #dcfce7;
            color: #166534;
        }

        .alert {
            padding: 1rem;
            border-radius: 8px;
            margin-bottom: 1rem;
            border: 1px solid;
        }

        .alert-success {
            background: #dcfce7;
            color: #166534;
            border-color: #bbf7d0;
        }

        .alert-danger {
            background: #fef2f2;
            color: #dc2626;
            border-color: #fecaca;
        }

        @media (max-width: 768px) {
            .profile-container {
                padding: 1rem;
            }
            
            .profile-header {
                padding: 1.5rem;
            }
            
            .profile-actions {
                flex-direction: column;
            }
            
            .btn {
                width: 100%;
                justify-content: center;
            }
        }
    </style>
</head>
<body>
    <div class="profile-container">
        <!-- 消息提示 -->
        <?php if (isset($_SESSION['success'])): ?>
            <div class="alert alert-success">
                <i class="bi bi-check-circle"></i>
                <?= htmlspecialchars($_SESSION['success']) ?>
            </div>
            <?php unset($_SESSION['success']); ?>
        <?php endif; ?>

        <?php if (isset($_SESSION['error'])): ?>
            <div class="alert alert-danger">
                <i class="bi bi-exclamation-triangle"></i>
                <?= htmlspecialchars($_SESSION['error']) ?>
            </div>
            <?php unset($_SESSION['error']); ?>
        <?php endif; ?>

        <!-- 个人资料头部 -->
        <div class="profile-header">
            <div class="d-flex align-items-center">
                <div class="profile-avatar">
                    <?= strtoupper(substr($profile['username'] ?? 'A', 0, 1)) ?>
                </div>
                <div class="profile-info ms-3">
                    <h1><?= htmlspecialchars($profile['full_name'] ?? $profile['username'] ?? '用户') ?></h1>
                    <p><?= htmlspecialchars($profile['email'] ?? '') ?></p>
                    <span class="status-badge status-active">
                        <i class="bi bi-check-circle"></i>
                        活跃
                    </span>
                </div>
            </div>
            
            <div class="profile-actions">
                <a href="/profile/settings" class="btn btn-primary">
                    <i class="bi bi-gear"></i>
                    账户设置
                </a>
                <a href="/profile/change-password" class="btn btn-outline">
                    <i class="bi bi-key"></i>
                    修改密码
                </a>
                <a href="/profile/security" class="btn btn-outline">
                    <i class="bi bi-shield-check"></i>
                    安全设置
                </a>
            </div>
        </div>

        <!-- 统计信息 -->
        <div class="profile-stats">
            <div class="stat-card">
                <div class="stat-number"><?= date('Y-m-d', strtotime($profile['created_at'] ?? '2024-01-01')) ?></div>
                <div class="stat-label">注册日期</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><?= date('H:i', strtotime($profile['last_login'] ?? '2024-01-15 10:30:00')) ?></div>
                <div class="stat-label">最后登录</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">1</div>
                <div class="stat-label">活跃会话</div>
            </div>
        </div>

        <!-- 详细信息 -->
        <div class="profile-details">
            <h3 class="mb-3">账户信息</h3>
            <div class="detail-item">
                <span class="detail-label">用户名</span>
                <span class="detail-value"><?= htmlspecialchars($profile['username'] ?? '') ?></span>
            </div>
            <div class="detail-item">
                <span class="detail-label">邮箱地址</span>
                <span class="detail-value"><?= htmlspecialchars($profile['email'] ?? '') ?></span>
            </div>
            <div class="detail-item">
                <span class="detail-label">全名</span>
                <span class="detail-value"><?= htmlspecialchars($profile['full_name'] ?? '未设置') ?></span>
            </div>
            <div class="detail-item">
                <span class="detail-label">账户状态</span>
                <span class="status-badge status-active">活跃</span>
            </div>
        </div>
    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
