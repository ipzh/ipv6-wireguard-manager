<?php
// views/ipv6/pools.php
// 注意：此文件由控制器处理布局包含，不需要直接包含header.php
?>

<div class="container">
    <h2>IPv6前缀池管理</h2>

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
            <h5 class="mb-0">IPv6前缀池列表</h5>
            <a href="/ipv6/pools/create" class="btn btn-primary">
                <i class="bi bi-plus-circle"></i> 创建前缀池
            </a>
        </div>
        
        <div class="card-body">
            <?php if (!empty($pools)): ?>
                <div class="table-responsive">
                    <table class="table table-striped table-hover">
                        <thead>
                            <tr>
                                <th>名称</th>
                                <th>基础前缀</th>
                                <th>前缀长度</th>
                                <th>子网长度</th>
                                <th>总容量</th>
                                <th>已使用</th>
                                <th>可用</th>
                                <th>使用率</th>
                                <th>状态</th>
                                <th>创建时间</th>
                                <th>操作</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($pools as $pool): ?>
                                <?php 
                                $usagePercent = $pool['total_capacity'] > 0 ? 
                                    round(($pool['used_capacity'] / $pool['total_capacity']) * 100, 1) : 0;
                                ?>
                                <tr>
                                    <td>
                                        <strong><?php echo htmlspecialchars($pool['name']); ?></strong>
                                        <?php if (!empty($pool['description'])): ?>
                                            <br><small class="text-muted"><?php echo htmlspecialchars($pool['description']); ?></small>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <code><?php echo htmlspecialchars($pool['base_prefix']); ?></code>
                                    </td>
                                    <td>/<?php echo htmlspecialchars($pool['prefix_len']); ?></td>
                                    <td>/<?php echo htmlspecialchars($pool['subnet_len']); ?></td>
                                    <td><?php echo number_format($pool['total_capacity']); ?></td>
                                    <td><?php echo number_format($pool['used_capacity']); ?></td>
                                    <td><?php echo number_format($pool['available_capacity']); ?></td>
                                    <td>
                                        <div class="progress" style="height: 20px;">
                                            <div class="progress-bar bg-<?php echo $usagePercent > 80 ? 'danger' : ($usagePercent > 60 ? 'warning' : 'success'); ?>" 
                                                 role="progressbar" 
                                                 style="width: <?php echo $usagePercent; ?>%"
                                                 aria-valuenow="<?php echo $usagePercent; ?>" 
                                                 aria-valuemin="0" 
                                                 aria-valuemax="100">
                                                <?php echo $usagePercent; ?>%
                                            </div>
                                        </div>
                                    </td>
                                    <td>
                                        <span class="badge bg-<?php echo $pool['is_active'] ? 'success' : 'danger'; ?>">
                                            <?php echo $pool['is_active'] ? '活跃' : '禁用'; ?>
                                        </span>
                                    </td>
                                    <td><?php echo htmlspecialchars($pool['created_at'] ?? 'N/A'); ?></td>
                                    <td>
                                        <div class="btn-group" role="group">
                                            <a href="/ipv6/pools/<?php echo $pool['id']; ?>/edit" 
                                               class="btn btn-sm btn-primary">
                                                <i class="bi bi-pencil"></i> 编辑
                                            </a>
                                            
                                            <a href="/ipv6/allocations?pool_id=<?php echo $pool['id']; ?>" 
                                               class="btn btn-sm btn-info">
                                                <i class="bi bi-list"></i> 分配
                                            </a>
                                            
                                            <a href="/ipv6/pools/<?php echo $pool['id']; ?>/delete" 
                                               class="btn btn-sm btn-danger" 
                                               onclick="return confirm('确定要删除此前缀池吗？此操作不可撤销！')">
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
                    <i class="bi bi-diagram-3 display-1 text-muted"></i>
                    <h5 class="text-muted mt-3">暂无IPv6前缀池</h5>
                    <p class="text-muted">点击上方按钮创建第一个IPv6前缀池</p>
                </div>
            <?php endif; ?>
        </div>
    </div>

    <!-- IPv6前缀池统计 -->
    <div class="row mt-4">
        <div class="col-md-3">
            <div class="card bg-primary text-white">
                <div class="card-body">
                    <div class="d-flex justify-content-between">
                        <div>
                            <h4 class="mb-0"><?php echo count($pools); ?></h4>
                            <p class="mb-0">前缀池总数</p>
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
                                $totalCapacity = 0;
                                foreach ($pools as $pool) {
                                    $totalCapacity += $pool['total_capacity'];
                                }
                                echo number_format($totalCapacity);
                                ?>
                            </h4>
                            <p class="mb-0">总容量</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-hdd-stack fs-1"></i>
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
                                $usedCapacity = 0;
                                foreach ($pools as $pool) {
                                    $usedCapacity += $pool['used_capacity'];
                                }
                                echo number_format($usedCapacity);
                                ?>
                            </h4>
                            <p class="mb-0">已使用</p>
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
                                $availableCapacity = 0;
                                foreach ($pools as $pool) {
                                    $availableCapacity += $pool['available_capacity'];
                                }
                                echo number_format($availableCapacity);
                                ?>
                            </h4>
                            <p class="mb-0">可用</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-circle fs-1"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- IPv6前缀池说明 -->
    <div class="card mt-4">
        <div class="card-header">
            <h5 class="mb-0">IPv6前缀池说明</h5>
        </div>
        <div class="card-body">
            <div class="row">
                <div class="col-md-6">
                    <h6>前缀池配置</h6>
                    <ul>
                        <li><strong>基础前缀</strong>: 如 <code>2001:db8::/32</code></li>
                        <li><strong>前缀长度</strong>: 基础前缀的长度，如 <code>32</code></li>
                        <li><strong>子网长度</strong>: 分配给客户端的子网长度，如 <code>48</code></li>
                    </ul>
                </div>
                <div class="col-md-6">
                    <h6>容量计算</h6>
                    <ul>
                        <li><strong>总容量</strong>: 2^(子网长度-前缀长度)</li>
                        <li><strong>已使用</strong>: 已分配的子网数量</li>
                        <li><strong>可用</strong>: 总容量 - 已使用</li>
                    </ul>
                </div>
            </div>
            <div class="row mt-3">
                <div class="col-md-12">
                    <h6>示例</h6>
                    <p>基础前缀 <code>2001:db8::/32</code>，子网长度 <code>48</code>：</p>
                    <ul>
                        <li>总容量: 2^(48-32) = 65,536 个子网</li>
                        <li>每个子网: /48 (如 2001:db8:1::/48)</li>
                        <li>每个子网可容纳: 2^(64-48) = 65,536 个主机</li>
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

.progress {
    min-width: 80px;
}

.progress-bar {
    font-size: 0.75em;
    line-height: 20px;
}
</style>

<?php
require_once __DIR__ . '/../layout/footer.php';
?>
