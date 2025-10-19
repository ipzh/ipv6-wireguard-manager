<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= APP_NAME ?> - WireGuard服务器管理</title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
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
                <a class="nav-link active" href="/wireguard/servers">
                    <i class="bi bi-server me-1"></i>服务器
                </a>
                <a class="nav-link" href="/wireguard/clients">
                    <i class="bi bi-people me-1"></i>客户端
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
                            <i class="bi bi-server me-2"></i>WireGuard服务器管理
                        </h2>
                        <p class="text-muted mb-0">管理WireGuard VPN服务器配置</p>
                    </div>
    <div>
                        <a href="/wireguard/servers/create" class="btn btn-primary">
                            <i class="bi bi-plus-circle me-2"></i>创建服务器
                        </a>
                    </div>
                </div>
    </div>
</div>

<!-- 服务器列表 -->
        <div class="row">
            <div class="col-12">
<div class="card">
                    <div class="card-header">
                        <h5 class="mb-0">
                            <i class="bi bi-list me-2"></i>服务器列表
                        </h5>
                    </div>
    <div class="card-body">
        <?php if (empty($servers)): ?>
        <div class="text-center py-5">
                            <i class="bi bi-server text-muted" style="font-size: 3rem;"></i>
                            <h5 class="text-muted mt-3">暂无WireGuard服务器</h5>
                            <p class="text-muted">点击上方按钮创建第一个服务器</p>
        </div>
        <?php else: ?>
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>名称</th>
                        <th>接口</th>
                        <th>监听端口</th>
                        <th>IPv4地址</th>
                        <th>IPv6地址</th>
                        <th>状态</th>
                        <th>操作</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($servers as $server): ?>
                                    <tr>
                                        <td>
                                            <strong><?= htmlspecialchars($server['name']) ?></strong>
                                        </td>
                        <td>
                                            <code><?= htmlspecialchars($server['interface']) ?></code>
                        </td>
                        <td>
                                            <span class="badge bg-info"><?= $server['listen_port'] ?></span>
                        </td>
                        <td>
                            <code><?= htmlspecialchars($server['ipv4_address']) ?></code>
                        </td>
                        <td>
                            <code><?= htmlspecialchars($server['ipv6_address']) ?></code>
                                        </td>
                                        <td>
                                            <?php if ($server['is_active']): ?>
                                                <span class="badge bg-success">运行中</span>
                            <?php else: ?>
                                                <span class="badge bg-secondary">已停止</span>
                            <?php endif; ?>
                        </td>
                        <td>
                                            <div class="btn-group btn-group-sm">
                                                <a href="/wireguard/servers/<?= $server['id'] ?>" class="btn btn-outline-info">
                                    <i class="bi bi-eye"></i>
                                                </a>
                                                <a href="/wireguard/servers/<?= $server['id'] ?>/edit" class="btn btn-outline-primary">
                                    <i class="bi bi-pencil"></i>
                                                </a>
                                                <?php if ($server['is_active']): ?>
                                                    <a href="/wireguard/servers/<?= $server['id'] ?>/stop" class="btn btn-outline-warning">
                                                        <i class="bi bi-stop-circle"></i>
                                                    </a>
                                <?php else: ?>
                                                    <a href="/wireguard/servers/<?= $server['id'] ?>/start" class="btn btn-outline-success">
                                                        <i class="bi bi-play-circle"></i>
                                                    </a>
                                <?php endif; ?>
                                                <a href="/wireguard/servers/<?= $server['id'] ?>/export" class="btn btn-outline-secondary">
                                                    <i class="bi bi-download"></i>
                                                </a>
                                                <a href="/wireguard/servers/<?= $server['id'] ?>/delete" class="btn btn-outline-danger" 
                                                   onclick="return confirm('确定要删除此服务器吗？')">
                                    <i class="bi bi-trash"></i>
                                                </a>
                            </div>
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
    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>