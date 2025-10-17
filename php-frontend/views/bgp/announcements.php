<?php
// views/bgp/announcements.php
require_once __DIR__ . '/../layout/header.php';
?>

<div class="container">
    <h2>BGP宣告管理</h2>

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
            <h5 class="mb-0">BGP宣告列表</h5>
            <a href="/bgp/announcements/create" class="btn btn-primary">
                <i class="bi bi-plus-circle"></i> 创建宣告
            </a>
        </div>
        
        <div class="card-body">
            <?php if (!empty($announcements)): ?>
                <div class="table-responsive">
                    <table class="table table-striped table-hover">
                        <thead>
                            <tr>
                                <th>前缀</th>
                                <th>下一跳</th>
                                <th>AS路径</th>
                                <th>社区属性</th>
                                <th>状态</th>
                                <th>启用状态</th>
                                <th>创建时间</th>
                                <th>操作</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($announcements as $announcement): ?>
                                <tr>
                                    <td>
                                        <code><?php echo htmlspecialchars($announcement['prefix']); ?></code>
                                    </td>
                                    <td><?php echo htmlspecialchars($announcement['next_hop'] ?? 'N/A'); ?></td>
                                    <td>
                                        <?php if (!empty($announcement['as_path'])): ?>
                                            <span class="badge bg-info"><?php echo htmlspecialchars($announcement['as_path']); ?></span>
                                        <?php else: ?>
                                            <span class="text-muted">N/A</span>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <?php if (!empty($announcement['communities'])): ?>
                                            <span class="badge bg-secondary"><?php echo htmlspecialchars($announcement['communities']); ?></span>
                                        <?php else: ?>
                                            <span class="text-muted">N/A</span>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <span class="badge bg-<?php echo $announcement['status'] === 'announced' ? 'success' : 'secondary'; ?>">
                                            <?php echo htmlspecialchars($announcement['status'] ?? 'unknown'); ?>
                                        </span>
                                    </td>
                                    <td>
                                        <span class="badge bg-<?php echo $announcement['enabled'] ? 'success' : 'danger'; ?>">
                                            <?php echo $announcement['enabled'] ? '启用' : '禁用'; ?>
                                        </span>
                                    </td>
                                    <td><?php echo htmlspecialchars($announcement['created_at'] ?? 'N/A'); ?></td>
                                    <td>
                                        <div class="btn-group" role="group">
                                            <a href="/bgp/announcements/<?php echo $announcement['id']; ?>/edit" 
                                               class="btn btn-sm btn-primary">
                                                <i class="bi bi-pencil"></i> 编辑
                                            </a>
                                            
                                            <a href="/bgp/announcements/<?php echo $announcement['id']; ?>/delete" 
                                               class="btn btn-sm btn-danger" 
                                               onclick="return confirm('确定要删除此BGP宣告吗？此操作不可撤销！')">
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
                    <i class="bi bi-broadcast display-1 text-muted"></i>
                    <h5 class="text-muted mt-3">暂无BGP宣告</h5>
                    <p class="text-muted">点击上方按钮创建第一个BGP宣告</p>
                </div>
            <?php endif; ?>
        </div>
    </div>

    <!-- BGP宣告统计 -->
    <div class="row mt-4">
        <div class="col-md-3">
            <div class="card bg-primary text-white">
                <div class="card-body">
                    <div class="d-flex justify-content-between">
                        <div>
                            <h4 class="mb-0"><?php echo count($announcements); ?></h4>
                            <p class="mb-0">总宣告数</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-broadcast fs-1"></i>
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
                                $announcedCount = 0;
                                foreach ($announcements as $announcement) {
                                    if (($announcement['status'] ?? '') === 'announced') $announcedCount++;
                                }
                                echo $announcedCount;
                                ?>
                            </h4>
                            <p class="mb-0">已宣告</p>
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
                                $enabledCount = 0;
                                foreach ($announcements as $announcement) {
                                    if ($announcement['enabled']) $enabledCount++;
                                }
                                echo $enabledCount;
                                ?>
                            </h4>
                            <p class="mb-0">已启用</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-power fs-1"></i>
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
                                $disabledCount = count($announcements) - $enabledCount;
                                echo $disabledCount;
                                ?>
                            </h4>
                            <p class="mb-0">已禁用</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-pause-circle fs-1"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- BGP宣告说明 -->
    <div class="card mt-4">
        <div class="card-header">
            <h5 class="mb-0">BGP宣告说明</h5>
        </div>
        <div class="card-body">
            <div class="row">
                <div class="col-md-6">
                    <h6>前缀格式</h6>
                    <ul>
                        <li>IPv4: <code>192.168.1.0/24</code></li>
                        <li>IPv6: <code>2001:db8::/32</code></li>
                    </ul>
                </div>
                <div class="col-md-6">
                    <h6>AS路径格式</h6>
                    <ul>
                        <li>简单路径: <code>65001</code></li>
                        <li>多跳路径: <code>65001 65002 65003</code></li>
                    </ul>
                </div>
            </div>
            <div class="row mt-3">
                <div class="col-md-6">
                    <h6>社区属性格式</h6>
                    <ul>
                        <li>标准社区: <code>65001:100</code></li>
                        <li>扩展社区: <code>65001:100:200</code></li>
                    </ul>
                </div>
                <div class="col-md-6">
                    <h6>下一跳格式</h6>
                    <ul>
                        <li>IPv4: <code>192.168.1.1</code></li>
                        <li>IPv6: <code>2001:db8::1</code></li>
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
require_once __DIR__ . '/../layout/footer.php';
?>
