<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= APP_NAME ?> - BGP会话管理</title>
    
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
                <a class="nav-link active" href="/bgp/sessions">
                    <i class="bi bi-diagram-3 me-1"></i>BGP会话
                </a>
                <a class="nav-link" href="/bgp/announcements">
                    <i class="bi bi-broadcast me-1"></i>路由宣告
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
                            <i class="bi bi-diagram-3 me-2"></i>BGP会话管理
                        </h2>
                        <p class="text-muted mb-0">管理BGP对等会话和路由宣告</p>
                    </div>
                    <div>
                        <a href="/bgp/sessions/create" class="btn btn-primary">
                            <i class="bi bi-plus-circle me-2"></i>创建会话
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <!-- 会话列表 -->
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <h5 class="mb-0">
                            <i class="bi bi-list me-2"></i>BGP会话列表
                        </h5>
                    </div>
                    <div class="card-body">
                        <?php if (isset($error)): ?>
                        <div class="alert alert-danger" role="alert">
                            <i class="bi bi-exclamation-triangle me-2"></i>
                            <?= htmlspecialchars($error) ?>
                        </div>
                        <?php endif; ?>

                        <?php if (empty($sessions)): ?>
                        <div class="text-center py-5">
                            <i class="bi bi-diagram-3 text-muted" style="font-size: 3rem;"></i>
                            <h5 class="text-muted mt-3">暂无BGP会话</h5>
                            <p class="text-muted">点击上方按钮创建第一个BGP会话</p>
                        </div>
                        <?php else: ?>
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>名称</th>
                                        <th>邻居地址</th>
                                        <th>远程AS</th>
                                        <th>本地AS</th>
                                        <th>状态</th>
                                        <th>创建时间</th>
                                        <th>操作</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($sessions as $session): ?>
                                    <tr>
                                        <td>
                                            <strong><?= htmlspecialchars($session['name']) ?></strong>
                                        </td>
                                        <td>
                                            <code><?= htmlspecialchars($session['neighbor']) ?></code>
                                        </td>
                                        <td>
                                            <span class="badge bg-info">AS<?= $session['remote_as'] ?></span>
                                        </td>
                                        <td>
                                            <span class="badge bg-secondary">AS<?= $session['local_as'] ?></span>
                                        </td>
                                        <td>
                                            <?php if ($session['enabled']): ?>
                                                <span class="badge bg-success">启用</span>
                                            <?php else: ?>
                                                <span class="badge bg-secondary">禁用</span>
                                            <?php endif; ?>
                                        </td>
                                        <td>
                                            <?= date('Y-m-d H:i:s', strtotime($session['created_at'])) ?>
                                        </td>
                                        <td>
                                            <div class="btn-group btn-group-sm">
                                                <a href="/bgp/sessions/<?= $session['id'] ?>/edit" class="btn btn-outline-primary">
                                                    <i class="bi bi-pencil"></i>
                                                </a>
                                                <?php if ($session['enabled']): ?>
                                                    <a href="/bgp/sessions/<?= $session['id'] ?>/stop" class="btn btn-outline-warning">
                                                        <i class="bi bi-stop-circle"></i>
                                                    </a>
                                                <?php else: ?>
                                                    <a href="/bgp/sessions/<?= $session['id'] ?>/start" class="btn btn-outline-success">
                                                        <i class="bi bi-play-circle"></i>
                                                    </a>
                                                <?php endif; ?>
                                                <a href="/bgp/sessions/<?= $session['id'] ?>/delete" class="btn btn-outline-danger" 
                                                   onclick="return confirm('确定要删除此BGP会话吗？')">
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