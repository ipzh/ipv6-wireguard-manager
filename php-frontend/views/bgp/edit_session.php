<?php
// views/bgp/edit_session.php
require_once __DIR__ . '/../layout/header.php';
?>

<div class="container">
    <h2>编辑BGP会话</h2>

    <?php if (isset($error)): ?>
        <div class="alert alert-danger"><?php echo htmlspecialchars($error); ?></div>
    <?php endif; ?>

    <?php if ($session): ?>
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">编辑BGP会话: <?php echo htmlspecialchars($session['name']); ?></h5>
            </div>
            <div class="card-body">
                <form method="POST" action="/bgp/sessions/<?php echo $session['id']; ?>/edit">
                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="name" class="form-label">会话名称 <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" id="name" name="name" 
                                       value="<?php echo htmlspecialchars($session['name']); ?>" required>
                                <div class="form-text">为BGP会话指定一个易于识别的名称</div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="neighbor" class="form-label">邻居地址 <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" id="neighbor" name="neighbor" 
                                       value="<?php echo htmlspecialchars($session['neighbor']); ?>" required>
                                <div class="form-text">BGP邻居的IP地址 (IPv4或IPv6)</div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="remote_as" class="form-label">远程AS号 <span class="text-danger">*</span></label>
                                <input type="number" class="form-control" id="remote_as" name="remote_as" 
                                       value="<?php echo htmlspecialchars($session['remote_as']); ?>" required min="1" max="4294967295">
                                <div class="form-text">远程BGP邻居的AS号码</div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="local_as" class="form-label">本地AS号 <span class="text-danger">*</span></label>
                                <input type="number" class="form-control" id="local_as" name="local_as" 
                                       value="<?php echo htmlspecialchars($session['local_as']); ?>" required min="1" max="4294967295">
                                <div class="form-text">本地BGP路由器的AS号码</div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="password" class="form-label">MD5密码</label>
                                <input type="password" class="form-control" id="password" name="password" 
                                       placeholder="留空表示不修改">
                                <div class="form-text">BGP会话的MD5认证密码 (留空表示不修改)</div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <div class="form-check mt-4">
                                    <input class="form-check-input" type="checkbox" id="enabled" name="enabled" 
                                           <?php echo $session['enabled'] ? 'checked' : ''; ?>>
                                    <label class="form-check-label" for="enabled">
                                        启用会话
                                    </label>
                                    <div class="form-text">启用或禁用BGP会话</div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-12">
                            <div class="d-flex justify-content-between">
                                <a href="/bgp/sessions" class="btn btn-secondary">
                                    <i class="bi bi-arrow-left"></i> 返回列表
                                </a>
                                <button type="submit" class="btn btn-primary">
                                    <i class="bi bi-check-circle"></i> 保存更改
                                </button>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
        </div>

        <!-- 会话状态信息 -->
        <div class="card mt-4">
            <div class="card-header">
                <h5 class="mb-0">会话状态信息</h5>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-3">
                        <strong>会话ID:</strong><br>
                        <code><?php echo htmlspecialchars($session['id']); ?></code>
                    </div>
                    <div class="col-md-3">
                        <strong>当前状态:</strong><br>
                        <span class="badge bg-<?php echo $session['status'] === 'established' ? 'success' : 'secondary'; ?>">
                            <?php echo htmlspecialchars($session['status'] ?? 'unknown'); ?>
                        </span>
                    </div>
                    <div class="col-md-3">
                        <strong>创建时间:</strong><br>
                        <?php echo htmlspecialchars($session['created_at'] ?? 'N/A'); ?>
                    </div>
                    <div class="col-md-3">
                        <strong>更新时间:</strong><br>
                        <?php echo htmlspecialchars($session['updated_at'] ?? 'N/A'); ?>
                    </div>
                </div>
            </div>
        </div>
    <?php else: ?>
        <div class="alert alert-danger">
            <i class="bi bi-exclamation-triangle"></i> 未找到指定的BGP会话
        </div>
        <a href="/bgp/sessions" class="btn btn-secondary">
            <i class="bi bi-arrow-left"></i> 返回列表
        </a>
    <?php endif; ?>
</div>

<style>
.form-label {
    font-weight: 600;
}

.text-danger {
    color: #dc3545 !important;
}

.form-text {
    font-size: 0.875em;
    color: #6c757d;
}

.card-header {
    background-color: #f8f9fa;
    border-bottom: 1px solid #dee2e6;
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
