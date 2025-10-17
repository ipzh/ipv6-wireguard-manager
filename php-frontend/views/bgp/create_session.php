<?php
// views/bgp/create_session.php
require_once __DIR__ . '/../layout/header.php';
?>

<div class="container">
    <h2>创建BGP会话</h2>

    <?php if (isset($error)): ?>
        <div class="alert alert-danger"><?php echo htmlspecialchars($error); ?></div>
    <?php endif; ?>

    <div class="card">
        <div class="card-header">
            <h5 class="mb-0">BGP会话配置</h5>
        </div>
        <div class="card-body">
            <form method="POST" action="/bgp/sessions/create">
                <div class="row">
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label for="name" class="form-label">会话名称 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="name" name="name" required>
                            <div class="form-text">为BGP会话指定一个易于识别的名称</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label for="neighbor" class="form-label">邻居地址 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="neighbor" name="neighbor" required>
                            <div class="form-text">BGP邻居的IP地址 (IPv4或IPv6)</div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label for="remote_as" class="form-label">远程AS号 <span class="text-danger">*</span></label>
                            <input type="number" class="form-control" id="remote_as" name="remote_as" required min="1" max="4294967295">
                            <div class="form-text">远程BGP邻居的AS号码</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label for="local_as" class="form-label">本地AS号 <span class="text-danger">*</span></label>
                            <input type="number" class="form-control" id="local_as" name="local_as" required min="1" max="4294967295">
                            <div class="form-text">本地BGP路由器的AS号码</div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label for="password" class="form-label">MD5密码</label>
                            <input type="password" class="form-control" id="password" name="password">
                            <div class="form-text">BGP会话的MD5认证密码 (可选)</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="mb-3">
                            <div class="form-check mt-4">
                                <input class="form-check-input" type="checkbox" id="enabled" name="enabled" checked>
                                <label class="form-check-label" for="enabled">
                                    启用会话
                                </label>
                                <div class="form-text">创建后立即启用BGP会话</div>
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
                                <i class="bi bi-plus-circle"></i> 创建会话
                            </button>
                        </div>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- BGP会话配置说明 -->
    <div class="card mt-4">
        <div class="card-header">
            <h5 class="mb-0">配置说明</h5>
        </div>
        <div class="card-body">
            <div class="row">
                <div class="col-md-6">
                    <h6>AS号码范围</h6>
                    <ul>
                        <li><strong>私有AS</strong>: 64512-65535</li>
                        <li><strong>公共AS</strong>: 1-64511</li>
                        <li><strong>扩展AS</strong>: 1-4294967295</li>
                    </ul>
                </div>
                <div class="col-md-6">
                    <h6>邻居地址格式</h6>
                    <ul>
                        <li><strong>IPv4</strong>: 192.168.1.1</li>
                        <li><strong>IPv6</strong>: 2001:db8::1</li>
                        <li><strong>域名</strong>: bgp.example.com</li>
                    </ul>
                </div>
            </div>
        </div>
    </div>
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
</style>

<?php
require_once __DIR__ . '/../layout/footer.php';
?>
