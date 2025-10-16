<?php
// views/users/list.php
require_once __DIR__ . '/../views/layout/header.php';
?>

<div class="container-fluid">
    <h2>用户管理</h2>

    <?php if (isset($_SESSION['success'])): ?>
        <div class="alert alert-success"><?php echo htmlspecialchars($_SESSION['success']); unset($_SESSION['success']); ?></div>
    <?php endif; ?>

    <?php if (isset($_SESSION['error'])): ?>
        <div class="alert alert-danger"><?php echo htmlspecialchars($_SESSION['error']); unset($_SESSION['error']); ?></div>
    <?php endif; ?>

    <?php if (isset($error)): ?>
        <div class="alert alert-danger"><?php echo htmlspecialchars($error); ?></div>
    <?php endif; ?>

    <!-- 操作按钮 -->
    <div class="row mb-3">
        <div class="col-md-6">
            <div class="btn-group" role="group">
                <a href="/users/create" class="btn btn-primary">
                    <i class="bi bi-plus-circle"></i> 创建用户
                </a>
                <a href="/users/roles" class="btn btn-outline-secondary">
                    <i class="bi bi-shield-check"></i> 角色管理
                </a>
            </div>
        </div>
        <div class="col-md-6 text-end">
            <div class="btn-group" role="group">
                <button type="button" class="btn btn-outline-warning" onclick="batchAction('activate')">
                    <i class="bi bi-check-circle"></i> 批量激活
                </button>
                <button type="button" class="btn btn-outline-danger" onclick="batchAction('deactivate')">
                    <i class="bi bi-x-circle"></i> 批量禁用
                </button>
                <button type="button" class="btn btn-outline-danger" onclick="batchAction('delete')">
                    <i class="bi bi-trash"></i> 批量删除
                </button>
            </div>
        </div>
    </div>

    <!-- 用户列表 -->
    <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
            <h5 class="mb-0">用户列表 (共 <?php echo count($users); ?> 个用户)</h5>
            <div class="form-check">
                <input class="form-check-input" type="checkbox" id="selectAll" onchange="toggleSelectAll()">
                <label class="form-check-label" for="selectAll">
                    全选
                </label>
            </div>
        </div>
        
        <div class="card-body">
            <?php if (!empty($users)): ?>
                <form id="batchForm" method="POST" action="/users/batch">
                    <input type="hidden" name="action" id="batchAction">
                    <input type="hidden" name="user_ids" id="batchUserIds">
                    
                    <div class="table-responsive">
                        <table class="table table-striped table-hover">
                            <thead>
                                <tr>
                                    <th width="50">选择</th>
                                    <th>用户名</th>
                                    <th>邮箱</th>
                                    <th>全名</th>
                                    <th>角色</th>
                                    <th>状态</th>
                                    <th>最后登录</th>
                                    <th>创建时间</th>
                                    <th>操作</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($users as $user): ?>
                                    <tr>
                                        <td>
                                            <input class="form-check-input user-checkbox" type="checkbox" 
                                                   value="<?php echo $user['id']; ?>" name="user_ids[]">
                                        </td>
                                        <td>
                                            <strong><?php echo htmlspecialchars($user['username']); ?></strong>
                                        </td>
                                        <td><?php echo htmlspecialchars($user['email'] ?? 'N/A'); ?></td>
                                        <td><?php echo htmlspecialchars($user['full_name'] ?? 'N/A'); ?></td>
                                        <td>
                                            <span class="badge bg-<?php 
                                                echo match($user['role'] ?? 'user') {
                                                    'admin' => 'danger',
                                                    'manager' => 'warning',
                                                    'user' => 'info',
                                                    default => 'secondary'
                                                };
                                            ?>">
                                                <?php echo htmlspecialchars($user['role'] ?? 'user'); ?>
                                            </span>
                                        </td>
                                        <td>
                                            <span class="badge bg-<?php echo $user['is_active'] ? 'success' : 'danger'; ?>">
                                                <?php echo $user['is_active'] ? '活跃' : '禁用'; ?>
                                            </span>
                                        </td>
                                        <td>
                                            <?php if (!empty($user['last_login'])): ?>
                                                <small><?php echo htmlspecialchars($user['last_login']); ?></small>
                                            <?php else: ?>
                                                <span class="text-muted">从未登录</span>
                                            <?php endif; ?>
                                        </td>
                                        <td>
                                            <small><?php echo htmlspecialchars($user['created_at'] ?? 'N/A'); ?></small>
                                        </td>
                                        <td>
                                            <div class="btn-group" role="group">
                                                <a href="/users/<?php echo $user['id']; ?>/details" 
                                                   class="btn btn-sm btn-outline-info">
                                                    <i class="bi bi-eye"></i>
                                                </a>
                                                <a href="/users/<?php echo $user['id']; ?>/edit" 
                                                   class="btn btn-sm btn-outline-primary">
                                                    <i class="bi bi-pencil"></i>
                                                </a>
                                                <a href="/users/<?php echo $user['id']; ?>/reset-password" 
                                                   class="btn btn-sm btn-outline-warning">
                                                    <i class="bi bi-key"></i>
                                                </a>
                                                <a href="/users/<?php echo $user['id']; ?>/delete" 
                                                   class="btn btn-sm btn-outline-danger" 
                                                   onclick="return confirm('确定要删除用户 <?php echo htmlspecialchars($user['username']); ?> 吗？此操作不可撤销！')">
                                                    <i class="bi bi-trash"></i>
                                                </a>
                                            </div>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                </form>
            <?php else: ?>
                <div class="text-center py-4">
                    <i class="bi bi-people display-1 text-muted"></i>
                    <h5 class="text-muted mt-3">暂无用户</h5>
                    <p class="text-muted">点击上方按钮创建第一个用户</p>
                </div>
            <?php endif; ?>
        </div>
    </div>

    <!-- 用户统计 -->
    <div class="row mt-4">
        <div class="col-md-3">
            <div class="card bg-primary text-white">
                <div class="card-body">
                    <div class="d-flex justify-content-between">
                        <div>
                            <h4 class="mb-0"><?php echo count($users); ?></h4>
                            <p class="mb-0">总用户数</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-people fs-1"></i>
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
                                foreach ($users as $user) {
                                    if ($user['is_active']) $activeCount++;
                                }
                                echo $activeCount;
                                ?>
                            </h4>
                            <p class="mb-0">活跃用户</p>
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
                                $adminCount = 0;
                                foreach ($users as $user) {
                                    if (($user['role'] ?? '') === 'admin') $adminCount++;
                                }
                                echo $adminCount;
                                ?>
                            </h4>
                            <p class="mb-0">管理员</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-shield-check fs-1"></i>
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
                                $recentCount = 0;
                                $weekAgo = date('Y-m-d H:i:s', strtotime('-7 days'));
                                foreach ($users as $user) {
                                    if (!empty($user['last_login']) && $user['last_login'] > $weekAgo) {
                                        $recentCount++;
                                    }
                                }
                                echo $recentCount;
                                ?>
                            </h4>
                            <p class="mb-0">最近活跃</p>
                        </div>
                        <div class="align-self-center">
                            <i class="bi bi-clock fs-1"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
// 全选/取消全选
function toggleSelectAll() {
    const selectAll = document.getElementById('selectAll');
    const checkboxes = document.querySelectorAll('.user-checkbox');
    
    checkboxes.forEach(checkbox => {
        checkbox.checked = selectAll.checked;
    });
}

// 批量操作
function batchAction(action) {
    const checkboxes = document.querySelectorAll('.user-checkbox:checked');
    
    if (checkboxes.length === 0) {
        alert('请选择要操作的用户');
        return;
    }
    
    let confirmMessage = '';
    switch (action) {
        case 'activate':
            confirmMessage = `确定要激活选中的 ${checkboxes.length} 个用户吗？`;
            break;
        case 'deactivate':
            confirmMessage = `确定要禁用选中的 ${checkboxes.length} 个用户吗？`;
            break;
        case 'delete':
            confirmMessage = `确定要删除选中的 ${checkboxes.length} 个用户吗？此操作不可撤销！`;
            break;
    }
    
    if (confirm(confirmMessage)) {
        document.getElementById('batchAction').value = action;
        document.getElementById('batchForm').submit();
    }
}

// 监听单个复选框变化
document.addEventListener('DOMContentLoaded', function() {
    const checkboxes = document.querySelectorAll('.user-checkbox');
    const selectAll = document.getElementById('selectAll');
    
    checkboxes.forEach(checkbox => {
        checkbox.addEventListener('change', function() {
            const checkedCount = document.querySelectorAll('.user-checkbox:checked').length;
            const totalCount = checkboxes.length;
            
            if (checkedCount === 0) {
                selectAll.indeterminate = false;
                selectAll.checked = false;
            } else if (checkedCount === totalCount) {
                selectAll.indeterminate = false;
                selectAll.checked = true;
            } else {
                selectAll.indeterminate = true;
            }
        });
    });
});
</script>

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

.fs-1 {
    font-size: 2.5rem !important;
}

.form-check-input:indeterminate {
    background-color: #0d6efd;
    border-color: #0d6efd;
}
</style>

<?php
require_once __DIR__ . '/../views/layout/footer.php';
?>
