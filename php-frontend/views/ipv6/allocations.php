<?php
// views/ipv6/allocations.php
require_once __DIR__ . '/../views/layout/header.php';
?>

<div class="container">
    <h2>IPv6前缀分配管理</h2>

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
            <h5 class="mb-0">IPv6前缀分配列表</h5>
            <a href="/ipv6/allocations/allocate" class="btn btn-primary">
                <i class="bi bi-plus-circle"></i> 分配前缀
            </a>
        </div>
        
        <div class="card-body">
            <?php if (!empty($allocations)): ?>
                <div class="table-responsive">
                    <table class="table table-striped table-hover">
                        <thead>
                            <tr>
                                <th>客户端名称</th>
                                <th>分配前缀</th>
                                <th>前缀池</th>
                                <th>子网长度</th>
                                <th>状态</th>
                                <th>分配时间</th>
                                <th>到期时间</th>
                                <th>操作</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($allocations as $allocation): ?>
                                <tr>
                                    <td>
                                        <strong><?php echo htmlspecialchars($allocation['client_name']); ?></strong>
                                        <?php if (!empty($allocation['description'])): ?>
                                            <br><small class="text-muted"><?php echo htmlspecialchars($allocation['description']); ?></small>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <code><?php echo htmlspecialchars($allocation['allocated_prefix']); ?></code>
                                    </td>
                                    <td><?php echo htmlspecialchars($allocation['pool_name'] ?? 'N/A'); ?></td>
                                    <td>/<?php echo htmlspecialchars($allocation['subnet_len']); ?></td>
                                    <td>
                                        <span class="badge bg-<?php echo $allocation['is_active'] ? 'success' : 'danger'; ?>">
                                            <?php echo $allocation['is_active'] ? '活跃' : '非活跃'; ?>
                                        </span>
                                    </td>
                                    <td><?php echo htmlspecialchars($allocation['allocated_at'] ?? 'N/A'); ?></td>
                                    <td>
                                        <?php if (!empty($allocation['expires_at'])): ?>
                                            <?php 
                                            $expiresAt = new DateTime($allocation['expires_at']);
                                            $now = new DateTime();
                                            $isExpired = $expiresAt < $now;
                                            ?>
                                            <span class="<?php echo $isExpired ? 'text-danger' : 'text-success'; ?>">
                                                <?php echo htmlspecialchars($allocation['expires_at']); ?>
                                            </span>
                                            <?php if ($isExpired): ?>
                                                <br><small class="text-danger">已过期</small>
                                            <?php endif; ?>
                                        <?php else: ?>
                                            <span class="text-muted">永不过期</span>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <div class="btn-group" role="group">
                                            <a href="/ipv6/allocations/<?php echo $allocation['id']; ?>/edit" 
                                               class="btn btn-sm btn-primary">
                                                <i class="bi bi-pencil"></i> 编辑
                                            </a>
                                            
                                            <a href="/ipv6/allocations/<?php echo $allocation['id']; ?>/release" 
                                               class="btn btn-sm btn-danger" 
                                               onclick="return confirm('确定要释放此前缀分配吗？此操作不可撤销！')">
                                                <i class="bi bi-trash"></i> 释放
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
                    <i class="bi bi-diagram-3 display-1 text-muted"></i>
                    <h5 class="text-muted mt-3">暂无IPv6前缀分配</h5>
                    <p class="text-muted">点击上方按钮分配第一个IPv6前缀</p>
                </div>
            <?php endif; ?>
        </div>
    </div>

    <!-- IPv6前缀分配统计 -->
    <div class="row mt-4">
        <div class="col-md-3">
            <div class="card bg-primary text-white">
                <div class="card-body">
                    <div class="d-flex justify-content-between">
                        <div>
                            <h4 class="mb-0"><?php echo count($allocations); ?></h4>
                            <p class="mb-0">总分配数</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-diagram-3 fs-1"></i>
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
                                foreach ($allocations as $allocation) {
                                    if ($allocation['is_active']) $activeCount++;
                                }
                                echo $activeCount;
                                ?>
                            </h4>
                            <p class="mb-0">活跃分配</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-check-circle fs-1"></i>
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
                                $expiredCount = 0;
                                foreach ($allocations as $allocation) {
                                    if (!empty($allocation['expires_at'])) {
                                        $expiresAt = new DateTime($allocation['expires_at']);
                                        $now = new DateTime();
                                        if ($expiresAt < $now) $expiredCount++;
                                    }
                                }
                                echo $expiredCount;
                                ?>
                            </h4>
                            <p class="mb-0">已过期</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-exclamation-triangle fs-1"></i>
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
                                $inactiveCount = count($allocations) - $activeCount;
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

    <!-- IPv6前缀分配说明 -->
    <div class="card mt-4">
        <div class="card-header">
            <h5 class="mb-0">前缀分配说明</h5>
        </div>
        <div class="card-body">
            <div class="row">
                <div class="col-md-6">
                    <h6>分配状态</h6>
                    <ul>
                        <li><strong>活跃</strong>: 前缀正在使用中</li>
                        <li><strong>非活跃</strong>: 前缀已分配但未使用</li>
                        <li><strong>已过期</strong>: 前缀分配已过期</li>
                    </ul>
                </div>
                <div class="col-md-6">
                    <h6>管理操作</h6>
                    <ul>
                        <li><strong>编辑</strong>: 修改客户端信息</li>
                        <li><strong>释放</strong>: 回收前缀到池中</li>
                        <li><strong>续期</strong>: 延长分配期限</li>
                    </ul>
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

code {
    background-color: #f8f9fa;
    padding: 2px 4px;
    border-radius: 3px;
    font-size: 0.9em;
}
</style>

<?php
require_once __DIR__ . '/../views/layout/footer.php';
?>
