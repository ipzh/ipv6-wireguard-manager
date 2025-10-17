<?php
// views/network/interfaces.php
?>

<div class="container-fluid">
    <h2>网络接口管理</h2>

    <?php if (isset($error)): ?>
        <div class="alert alert-danger"><?php echo htmlspecialchars($error); ?></div>
    <?php endif; ?>

    <div class="row">
        <div class="col-12">
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="card-title mb-0">网络接口列表</h5>
                    <button type="button" class="btn btn-outline-secondary btn-sm" onclick="refreshInterfaces()">
                        <i class="bi bi-arrow-clockwise"></i> 刷新
                    </button>
                </div>
                <div class="card-body">
                    <?php if (!empty($interfaces)): ?>
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>接口名称</th>
                                        <th>状态</th>
                                        <th>IPv4地址</th>
                                        <th>IPv6地址</th>
                                        <th>MTU</th>
                                        <th>速度</th>
                                        <th>操作</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($interfaces as $interface): ?>
                                        <tr>
                                            <td>
                                                <strong><?php echo htmlspecialchars($interface['name'] ?? 'N/A'); ?></strong>
                                            </td>
                                            <td>
                                                <?php if (($interface['status'] ?? '') === 'up'): ?>
                                                    <span class="badge bg-success">启用</span>
                                                <?php else: ?>
                                                    <span class="badge bg-secondary">禁用</span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <code><?php echo htmlspecialchars($interface['ipv4'] ?? 'N/A'); ?></code>
                                            </td>
                                            <td>
                                                <code><?php echo htmlspecialchars($interface['ipv6'] ?? 'N/A'); ?></code>
                                            </td>
                                            <td><?php echo htmlspecialchars($interface['mtu'] ?? 'N/A'); ?></td>
                                            <td><?php echo htmlspecialchars($interface['speed'] ?? 'N/A'); ?></td>
                                            <td>
                                                <div class="btn-group btn-group-sm" role="group">
                                                    <button type="button" class="btn btn-outline-primary" 
                                                            onclick="viewInterfaceDetails('<?php echo htmlspecialchars($interface['name'] ?? ''); ?>')">
                                                        <i class="bi bi-eye"></i> 查看
                                                    </button>
                                                    <button type="button" class="btn btn-outline-secondary" 
                                                            onclick="configureInterface('<?php echo htmlspecialchars($interface['name'] ?? ''); ?>')">
                                                        <i class="bi bi-gear"></i> 配置
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                    <?php else: ?>
                        <div class="text-center py-4">
                            <i class="bi bi-wifi-off display-1 text-muted"></i>
                            <h5 class="mt-3 text-muted">暂无网络接口信息</h5>
                            <p class="text-muted">请检查后端服务是否正常运行</p>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    </div>
    
    <!-- 接口详情模态框 -->
    <div class="modal fade" id="interfaceDetailsModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">接口详情</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="interfaceDetailsContent">
                    <!-- 详情内容将通过JavaScript动态加载 -->
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
function refreshInterfaces() {
    location.reload();
}

function viewInterfaceDetails(interfaceName) {
    // 这里应该调用API获取接口详细信息
    const content = `
        <div class="row">
            <div class="col-md-6">
                <h6>基本信息</h6>
                <table class="table table-sm">
                    <tr><td>接口名称:</td><td>${interfaceName}</td></tr>
                    <tr><td>状态:</td><td><span class="badge bg-success">启用</span></td></tr>
                    <tr><td>类型:</td><td>以太网</td></tr>
                </table>
            </div>
            <div class="col-md-6">
                <h6>网络配置</h6>
                <table class="table table-sm">
                    <tr><td>IPv4:</td><td>192.168.1.100/24</td></tr>
                    <tr><td>IPv6:</td><td>2001:db8::1/64</td></tr>
                    <tr><td>网关:</td><td>192.168.1.1</td></tr>
                </table>
            </div>
        </div>
        <div class="row mt-3">
            <div class="col-12">
                <h6>统计信息</h6>
                <table class="table table-sm">
                    <tr><td>接收字节:</td><td>1.2 GB</td></tr>
                    <tr><td>发送字节:</td><td>856 MB</td></tr>
                    <tr><td>接收包:</td><td>1,234,567</td></tr>
                    <tr><td>发送包:</td><td>987,654</td></tr>
                </table>
            </div>
        </div>
    `;
    
    document.getElementById('interfaceDetailsContent').innerHTML = content;
    new bootstrap.Modal(document.getElementById('interfaceDetailsModal')).show();
}

function configureInterface(interfaceName) {
    alert(`配置接口 ${interfaceName} 的功能需要后端API支持`);
}
</script>

<style>
.card {
    box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
    border: 1px solid rgba(0, 0, 0, 0.125);
}

.card-header {
    background-color: #f8f9fa;
    border-bottom: 1px solid rgba(0, 0, 0, 0.125);
}

.table th {
    background-color: #f8f9fa;
    border-top: none;
    font-weight: 600;
}

.badge {
    font-size: 0.75rem;
}

code {
    font-size: 0.875rem;
    background-color: #f8f9fa;
    padding: 0.125rem 0.25rem;
    border-radius: 0.25rem;
}

.btn-group-sm .btn {
    padding: 0.25rem 0.5rem;
    font-size: 0.75rem;
}
</style>
