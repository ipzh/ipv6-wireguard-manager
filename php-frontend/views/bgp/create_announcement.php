<?php
// views/bgp/create_announcement.php
// 注意：此文件由控制器处理布局包含，不需要直接包含header.php
?>

<div class="container">
    <h2>创建BGP宣告</h2>

    <?php if (isset($error)): ?>
        <div class="alert alert-danger"><?php echo htmlspecialchars($error); ?></div>
    <?php endif; ?>

    <div class="card">
        <div class="card-header">
            <h5 class="mb-0">BGP宣告配置</h5>
        </div>
        <div class="card-body">
            <form method="POST" action="/bgp/announcements/create">
                <div class="row">
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label for="prefix" class="form-label">网络前缀 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="prefix" name="prefix" required 
                                   placeholder="192.168.1.0/24 或 2001:db8::/32">
                            <div class="form-text">要宣告的网络前缀 (IPv4或IPv6)</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label for="next_hop" class="form-label">下一跳地址</label>
                            <input type="text" class="form-control" id="next_hop" name="next_hop" 
                                   placeholder="192.168.1.1 或 2001:db8::1">
                            <div class="form-text">BGP路由的下一跳地址 (可选)</div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label for="as_path" class="form-label">AS路径</label>
                            <input type="text" class="form-control" id="as_path" name="as_path" 
                                   placeholder="65001 65002 65003">
                            <div class="form-text">AS路径属性 (空格分隔的AS号码)</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label for="communities" class="form-label">社区属性</label>
                            <input type="text" class="form-control" id="communities" name="communities" 
                                   placeholder="65001:100,65001:200">
                            <div class="form-text">BGP社区属性 (逗号分隔)</div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-md-6">
                        <div class="mb-3">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" id="enabled" name="enabled" checked>
                                <label class="form-check-label" for="enabled">
                                    启用宣告
                                </label>
                                <div class="form-text">创建后立即启用BGP宣告</div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-12">
                        <div class="d-flex justify-content-between">
                            <a href="/bgp/announcements" class="btn btn-secondary">
                                <i class="bi bi-arrow-left"></i> 返回列表
                            </a>
                            <button type="submit" class="btn btn-primary">
                                <i class="bi bi-plus-circle"></i> 创建宣告
                            </button>
                        </div>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- BGP宣告配置说明 -->
    <div class="card mt-4">
        <div class="card-header">
            <h5 class="mb-0">配置说明</h5>
        </div>
        <div class="card-body">
            <div class="row">
                <div class="col-md-6">
                    <h6>网络前缀格式</h6>
                    <ul>
                        <li><strong>IPv4</strong>: 192.168.1.0/24</li>
                        <li><strong>IPv6</strong>: 2001:db8::/32</li>
                        <li><strong>单主机</strong>: 192.168.1.1/32</li>
                    </ul>
                </div>
                <div class="col-md-6">
                    <h6>AS路径格式</h6>
                    <ul>
                        <li><strong>简单路径</strong>: 65001</li>
                        <li><strong>多跳路径</strong>: 65001 65002 65003</li>
                        <li><strong>AS_SET</strong>: {65001,65002}</li>
                    </ul>
                </div>
            </div>
            <div class="row mt-3">
                <div class="col-md-6">
                    <h6>社区属性格式</h6>
                    <ul>
                        <li><strong>标准社区</strong>: 65001:100</li>
                        <li><strong>扩展社区</strong>: 65001:100:200</li>
                        <li><strong>多个社区</strong>: 65001:100,65001:200</li>
                    </ul>
                </div>
                <div class="col-md-6">
                    <h6>下一跳格式</h6>
                    <ul>
                        <li><strong>IPv4</strong>: 192.168.1.1</li>
                        <li><strong>IPv6</strong>: 2001:db8::1</li>
                        <li><strong>自引用</strong>: 0.0.0.0 (IPv4)</li>
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
