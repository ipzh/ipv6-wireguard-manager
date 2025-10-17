<?php
// views/bgp/sessions.php
// 注意：此文件由控制器处理布局包含，不需要直接包含header.php
?>

<div class="container">
    <h2>BGP会话管理</h2>

    <?php if (isset($_SESSION['success'])): ?>
        <div class="alert alert-success"><?php echo htmlspecialchars($_SESSION['success']); unset($_SESSION['success']); ?></div>
    <?php endif; ?>

    <?php if (isset($_SESSION['error'])): ?>
        <div class="alert alert-danger"><?php echo htmlspecialchars($_SESSION['error']); unset($_SESSION['error']); ?></div>
    <?php endif; ?>

    <?php if (isset($error)): ?>
        <div class="alert alert-danger"><?php echo htmlspecialchars($error); ?></div>
    <?php endif; ?>

    <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
            <h5 class="mb-0">BGP会话列表</h5>
            <a href="/bgp/sessions/create" class="btn btn-primary">
                <i class="bi bi-plus-circle"></i> 创建会话
            </a>
        </div>
        
        <div class="card-body">
            <?php if (!empty($sessions)): ?>
                <div class="table-responsive">
                    <table class="table table-striped table-hover">
                        <thead>
                            <tr>
                                <th>名称</th>
                                <th>邻居地址</th>
                                <th>远程AS</th>
                                <th>本地AS</th>
                                <th>状态</th>
                                <th>启用状态</th>
                                <th>创建时间</th>
                                <th>操作</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($sessions as $session): ?>
                                <tr>
                                    <td><?php echo htmlspecialchars($session['name']); ?></td>
                                    <td><?php echo htmlspecialchars($session['neighbor']); ?></td>
                                    <td><?php echo htmlspecialchars($session['remote_as']); ?></td>
                                    <td><?php echo htmlspecialchars($session['local_as']); ?></td>
                                    <td>
                                        <span class="badge bg-<?php echo $session['status'] === 'established' ? 'success' : 'secondary'; ?>">
                                            <?php echo htmlspecialchars($session['status'] ?? 'unknown'); ?>
                                        </span>
                                    </td>
                                    <td>
                                        <span class="badge bg-<?php echo $session['enabled'] ? 'success' : 'danger'; ?>">
                                            <?php echo $session['enabled'] ? '启用' : '禁用'; ?>
                                        </span>
                                    </td>
                                    <td><?php echo htmlspecialchars($session['created_at'] ?? 'N/A'); ?></td>
                                    <td>
                                        <div class="btn-group" role="group">
                                            <?php if ($session['enabled']): ?>
                                                <a href="/bgp/sessions/<?php echo $session['id']; ?>/stop" 
                                                   class="btn btn-sm btn-warning" 
                                                   onclick="return confirm('确定要停止此BGP会话吗？')">
                                                    <i class="bi bi-stop-circle"></i> 停止
                                                </a>
                                            <?php else: ?>
                                                <a href="/bgp/sessions/<?php echo $session['id']; ?>/start" 
                                                   class="btn btn-sm btn-success" 
                                                   onclick="return confirm('确定要启动此BGP会话吗？')">
                                                    <i class="bi bi-play-circle"></i> 启动
                                                </a>
                                            <?php endif; ?>
                                            
                                            <a href="/bgp/sessions/<?php echo $session['id']; ?>/edit" 
                                               class="btn btn-sm btn-primary">
                                                <i class="bi bi-pencil"></i> 编辑
                                            </a>
                                            
                                            <a href="/bgp/sessions/<?php echo $session['id']; ?>/delete" 
                                               class="btn btn-sm btn-danger" 
                                               onclick="return confirm('确定要删除此BGP会话吗？此操作不可撤销！')">
                                                <i class="bi bi-trash"></i> 删除
                                            </a>
                                        </div>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php else: ?>
                <div class="text-center py-4">
                    <i class="bi bi-router display-1 text-muted"></i>
                    <h5 class="text-muted mt-3">暂无BGP会话</h5>
                    <p class="text-muted">点击上方按钮创建第一个BGP会话</p>
                </div>
            <?php endif; ?>
        </div>
    </div>

    <!-- BGP会话统计 -->
    <div class="row mt-4">
        <div class="col-md-3">
            <div class="card bg-primary text-white">
                <div class="card-body">
                    <div class="d-flex justify-content-between">
                        <div>
                            <h4 class="mb-0"><?php echo count($sessions); ?></h4>
                            <p class="mb-0">总会话数</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-router fs-1"></i>
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
                            <h4 class="mb-0">
                                <?php 
                                $activeCount = 0;
                                foreach ($sessions as $session) {
                                    if ($session['enabled']) $activeCount++;
                                }
                                echo $activeCount;
                                ?>
                            </h4>
                            <p class="mb-0">活跃会话</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-check-circle fs-1"></i>
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
                            <h4 class="mb-0">
                                <?php 
                                $establishedCount = 0;
                                foreach ($sessions as $session) {
                                    if (($session['status'] ?? '') === 'established') $establishedCount++;
                                }
                                echo $establishedCount;
                                ?>
                            </h4>
                            <p class="mb-0">已建立</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-link-45deg fs-1"></i>
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
                            <h4 class="mb-0">
                                <?php 
                                $inactiveCount = count($sessions) - $activeCount;
                                echo $inactiveCount;
                                ?>
                            </h4>
                            <p class="mb-0">非活跃</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-pause-circle fs-1"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<style>
.table th {
    background-color: #f8f9fa;
    border-top: none;
    font-weight: 600;
}

.btn-group .btn {
    margin-right: 2px;
}

.btn-group .btn:last-child {
    margin-right: 0;
}

.card-header {
    background-color: #f8f9fa;
    border-bottom: 1px solid #dee2e6;
}

.badge {
    font-size: 0.75em;
}

.display-1 {
    font-size: 4rem;
}
</style>

<?php
require_once __DIR__ . '/../layout/footer.php';
?>
