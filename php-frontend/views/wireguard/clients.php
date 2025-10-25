<!-- 页面标题和操作按钮 -->
<div class="d-flex justify-content-between align-items-center mb-4">
    <h2>WireGuard客户端管理</h2>
    <div>
        <button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#addClientModal">
            <i class="bi bi-plus-circle"></i> 添加客户端
        </button>
        <button type="button" class="btn btn-outline-secondary" onclick="refreshClients()">
            <i class="bi bi-arrow-clockwise"></i> 刷新
        </button>
    </div>
</div>

<!-- 客户端列表 -->
<div class="card">
    <div class="card-body">
        <?php if (empty($clients)): ?>
        <div class="text-center py-5">
            <i class="bi bi-people text-muted" style="font-size: 4rem;"></i>
            <h4 class="mt-3 text-muted">暂无WireGuard客户端</h4>
            <p class="text-muted">点击"添加客户端"按钮创建第一个客户端</p>
            <button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#addClientModal">
                <i class="bi bi-plus-circle"></i> 添加客户端
            </button>
        </div>
        <?php else: ?>
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>名称</th>
                        <th>服务器</th>
                        <th>IPv4地址</th>
                        <th>IPv6地址</th>
                        <th>状态</th>
                        <th>最后连接</th>
                        <th>操作</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($clients as $client): ?>
                    <tr data-id="<?= $client['id'] ?>">
                        <td>
                            <strong><?= htmlspecialchars($client['name'] ?? '') ?></strong>
                            <?php if (!empty($client['description'])): ?>
                            <br><small class="text-muted"><?= htmlspecialchars($client['description']) ?></small>
                            <?php endif; ?>
                        </td>
                        <td>
                            <span class="badge bg-primary"><?= htmlspecialchars($client['server_name'] ?? '') ?></span>
                        </td>
                        <td>
                            <?php if (!empty($client['ipv4_address'])): ?>
                            <code><?= htmlspecialchars($client['ipv4_address']) ?></code>
                            <?php else: ?>
                            <span class="text-muted">-</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?php if (!empty($client['ipv6_address'])): ?>
                            <code><?= htmlspecialchars($client['ipv6_address']) ?></code>
                            <?php else: ?>
                            <span class="text-muted">-</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <span class="badge bg-<?= ($client['status'] ?? '') === 'connected' ? 'success' : 'secondary' ?>">
                                <?= ($client['status'] ?? '') === 'connected' ? '已连接' : '未连接' ?>
                            </span>
                        </td>
                        <td>
                            <?php if (!empty($client['last_handshake'])): ?>
                            <small><?= date('Y-m-d H:i:s', strtotime($client['last_handshake'])) ?></small>
                            <?php else: ?>
                            <span class="text-muted">从未连接</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <div class="btn-group btn-group-sm" role="group">
                                <button type="button" class="btn btn-outline-primary" onclick="viewClient('<?= $client['id'] ?>')" title="查看详情">
                                    <i class="bi bi-eye"></i>
                                </button>
                                <button type="button" class="btn btn-outline-secondary" onclick="editClient('<?= $client['id'] ?>')" title="编辑">
                                    <i class="bi bi-pencil"></i>
                                </button>
                                <button type="button" class="btn btn-outline-success" onclick="exportClientConfig('<?= $client['id'] ?>')" title="导出配置">
                                    <i class="bi bi-download"></i>
                                </button>
                                <button type="button" class="btn btn-outline-info" onclick="showQRCode('<?= $client['id'] ?>')" title="显示二维码">
                                    <i class="bi bi-qr-code"></i>
                                </button>
                                <button type="button" class="btn btn-outline-danger" onclick="deleteClient('<?= $client['id'] ?>')" title="删除">
                                    <i class="bi bi-trash"></i>
                                </button>
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

<!-- 添加客户端模态框 -->
<div class="modal fade" id="addClientModal" tabindex="-1" aria-labelledby="addClientModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <form method="POST" action="/wireguard/clients" id="addClientForm">
                <div class="modal-header">
                    <h5 class="modal-title" id="addClientModalLabel">添加WireGuard客户端</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" name="_token" value="<?= $this->auth->generateCsrfToken() ?>">
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="name" class="form-label">客户端名称 <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" id="name" name="name" required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="server_id" class="form-label">所属服务器 <span class="text-danger">*</span></label>
                                <select class="form-select" id="server_id" name="server_id" required>
                                    <option value="">请选择服务器</option>
                                    <?php
                                        // 获取服务器列表
                                        try {
                                            $serversData = $this->apiClient->get('/wireguard/servers');
                                            $servers = [];
                                            if (is_array($serversData)) {
                                                if (isset($serversData['data']) && is_array($serversData['data'])) {
                                                    $servers = $serversData['data'];
                                                } else {
                                                    $servers = $serversData;
                                                }
                                            }
                                            foreach ($servers as $server) {
                                                echo '<option value="' . $server['id'] . '">' . htmlspecialchars($server['name']) . '</option>';
                                            }
                                        } catch (Exception $e) {
                                            echo '<option value="">加载服务器列表失败</option>';
                                        }
                                        ?>
                                </select>
                            </div>
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        <label for="description" class="form-label">描述</label>
                        <textarea class="form-control" id="description" name="description" rows="2"></textarea>
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="ipv4_address" class="form-label">IPv4地址</label>
                                <input type="text" class="form-control" id="ipv4_address" name="ipv4_address" placeholder="10.0.0.2/32">
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="ipv6_address" class="form-label">IPv6地址</label>
                                <input type="text" class="form-control" id="ipv6_address" name="ipv6_address" placeholder="fd00::2/128">
                            </div>
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        <label for="allowed_ips" class="form-label">允许的IP地址</label>
                        <input type="text" class="form-control" id="allowed_ips" name="allowed_ips" placeholder="0.0.0.0/0, ::/0">
                        <div class="form-text">多个IP地址用逗号分隔，留空则允许所有流量</div>
                    </div>
                    
                    <div class="mb-3">
                        <label for="persistent_keepalive" class="form-label">保持连接间隔</label>
                        <input type="number" class="form-control" id="persistent_keepalive" name="persistent_keepalive" value="25" min="0" max="65535">
                        <div class="form-text">秒，0表示禁用</div>
                    </div>
                    
                    <div class="mb-3">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" id="is_active" name="is_active" checked>
                            <label class="form-check-label" for="is_active">
                                启用客户端
                            </label>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                    <button type="submit" class="btn btn-success">创建客户端</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- 编辑客户端模态框 -->
<div class="modal fade" id="editClientModal" tabindex="-1" aria-labelledby="editClientModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <form method="POST" id="editClientForm">
                <div class="modal-header">
                    <h5 class="modal-title" id="editClientModalLabel">编辑WireGuard客户端</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" name="_token" value="<?= $this->auth->generateCsrfToken() ?>">
                    <input type="hidden" id="edit_client_id" name="client_id">
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="edit_name" class="form-label">客户端名称 <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" id="edit_name" name="name" required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="edit_server_id" class="form-label">所属服务器 <span class="text-danger">*</span></label>
                                <select class="form-select" id="edit_server_id" name="server_id" required>
                                    <option value="">请选择服务器</option>
                                    <?php
                                    try {
                                        $servers = $this->apiClient->get('/wireguard/servers');
                                        $servers = $servers['servers'] ?? [];
                                        foreach ($servers as $server) {
                                            echo '<option value="' . $server['id'] . '">' . htmlspecialchars($server['name']) . '</option>';
                                        }
                                    } catch (Exception $e) {
                                        echo '<option value="">加载服务器列表失败</option>';
                                    }
                                    ?>
                                </select>
                            </div>
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        <label for="edit_description" class="form-label">描述</label>
                        <textarea class="form-control" id="edit_description" name="description" rows="2"></textarea>
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="edit_ipv4_address" class="form-label">IPv4地址</label>
                                <input type="text" class="form-control" id="edit_ipv4_address" name="ipv4_address">
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="edit_ipv6_address" class="form-label">IPv6地址</label>
                                <input type="text" class="form-control" id="edit_ipv6_address" name="ipv6_address">
                            </div>
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        <label for="edit_allowed_ips" class="form-label">允许的IP地址</label>
                        <input type="text" class="form-control" id="edit_allowed_ips" name="allowed_ips">
                        <div class="form-text">多个IP地址用逗号分隔，留空则允许所有流量</div>
                    </div>
                    
                    <div class="mb-3">
                        <label for="edit_persistent_keepalive" class="form-label">保持连接间隔</label>
                        <input type="number" class="form-control" id="edit_persistent_keepalive" name="persistent_keepalive" min="0" max="65535">
                        <div class="form-text">秒，0表示禁用</div>
                    </div>
                    
                    <div class="mb-3">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" id="edit_is_active" name="is_active">
                            <label class="form-check-label" for="edit_is_active">
                                启用客户端
                            </label>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                    <button type="submit" class="btn btn-success">更新客户端</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- 客户端详情模态框 -->
<div class="modal fade" id="clientDetailModal" tabindex="-1" aria-labelledby="clientDetailModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="clientDetailModalLabel">客户端详情</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body" id="clientDetailContent">
                <div class="text-center">
                    <div class="spinner-border" role="status">
                        <span class="visually-hidden">加载中...</span>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
            </div>
        </div>
    </div>
</div>

<!-- 二维码模态框 -->
<div class="modal fade" id="qrCodeModal" tabindex="-1" aria-labelledby="qrCodeModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="qrCodeModalLabel">客户端配置二维码</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body text-center" id="qrCodeContent">
                <div class="spinner-border" role="status">
                    <span class="visually-hidden">生成中...</span>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
            </div>
        </div>
    </div>
</div>

<script>
// 查看客户端详情
function viewClient(clientId) {
    const modal = new bootstrap.Modal(document.getElementById('clientDetailModal'));
    const content = document.getElementById('clientDetailContent');
    
    content.innerHTML = `
        <div class="text-center">
            <div class="spinner-border" role="status">
                <span class="visually-hidden">加载中...</span>
            </div>
        </div>
    `;
    
    modal.show();
    
    fetch(`/wireguard/clients/${clientId}`)
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                const client = data.data;
                content.innerHTML = `
                    <div class="row">
                        <div class="col-md-6">
                            <h6>基本信息</h6>
                            <table class="table table-sm">
                                <tr><td>名称:</td><td>${client.name}</td></tr>
                                <tr><td>服务器:</td><td><span class="badge bg-primary">${client.server_name}</span></td></tr>
                                <tr><td>状态:</td><td><span class="badge bg-${client.status === 'connected' ? 'success' : 'secondary'}">${client.status === 'connected' ? '已连接' : '未连接'}</span></td></tr>
                                <tr><td>最后连接:</td><td>${client.last_handshake ? new Date(client.last_handshake).toLocaleString() : '从未连接'}</td></tr>
                            </table>
                        </div>
                        <div class="col-md-6">
                            <h6>网络配置</h6>
                            <table class="table table-sm">
                                <tr><td>IPv4地址:</td><td><code>${client.ipv4_address || '-'}</code></td></tr>
                                <tr><td>IPv6地址:</td><td><code>${client.ipv6_address || '-'}</code></td></tr>
                                <tr><td>允许的IP:</td><td><code>${client.allowed_ips ? client.allowed_ips.join(', ') : '0.0.0.0/0'}</code></td></tr>
                                <tr><td>保持连接:</td><td>${client.persistent_keepalive || 0}秒</td></tr>
                            </table>
                        </div>
                    </div>
                    <div class="row mt-3">
                        <div class="col-12">
                            <h6>公钥</h6>
                            <div class="input-group">
                                <input type="text" class="form-control" value="${client.public_key || ''}" readonly>
                                <button class="btn btn-outline-secondary" type="button" onclick="copyToClipboard('${client.public_key || ''}')">
                                    <i class="bi bi-clipboard"></i>
                                </button>
                            </div>
                        </div>
                    </div>
                `;
            } else {
                content.innerHTML = `<div class="alert alert-danger">${data.message}</div>`;
            }
        })
        .catch(error => {
            content.innerHTML = `<div class="alert alert-danger">加载失败: ${error.message}</div>`;
        });
}

// 编辑客户端
function editClient(clientId) {
    const modal = new bootstrap.Modal(document.getElementById('editClientModal'));
    const form = document.getElementById('editClientForm');
    
    // 获取客户端数据
    fetch(`/wireguard/clients/${clientId}`)
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                const client = data.data;
                document.getElementById('edit_client_id').value = clientId;
                document.getElementById('edit_name').value = client.name || '';
                document.getElementById('edit_server_id').value = client.server_id || '';
                document.getElementById('edit_description').value = client.description || '';
                document.getElementById('edit_ipv4_address').value = client.ipv4_address || '';
                document.getElementById('edit_ipv6_address').value = client.ipv6_address || '';
                document.getElementById('edit_allowed_ips').value = client.allowed_ips ? client.allowed_ips.join(', ') : '';
                document.getElementById('edit_persistent_keepalive').value = client.persistent_keepalive || '';
                document.getElementById('edit_is_active').checked = client.is_active || false;
                
                form.action = `/wireguard/clients/${clientId}/update`;
                modal.show();
            } else {
                showMessage(data.message, 'error');
            }
        })
        .catch(error => {
            showMessage('加载客户端信息失败: ' + error.message, 'error');
        });
}

// 删除客户端
function deleteClient(clientId) {
    if (confirmDelete('确定要删除这个客户端吗？此操作不可撤销。')) {
        window.location.href = `/wireguard/clients/${clientId}/delete`;
    }
}

// 导出客户端配置
function exportClientConfig(clientId) {
    window.open(`/wireguard/clients/${clientId}/export`, '_blank');
}

// 显示二维码
function showQRCode(clientId) {
    const modal = new bootstrap.Modal(document.getElementById('qrCodeModal'));
    const content = document.getElementById('qrCodeContent');
    
    content.innerHTML = `
        <div class="spinner-border" role="status">
            <span class="visually-hidden">生成中...</span>
        </div>
    `;
    
    modal.show();
    
    // 获取客户端配置并生成二维码
    fetch(`/wireguard/clients/${clientId}/config`)
        .then(response => response.json())
        .then(data => {
            if (data.success && data.config) {
                // 这里需要集成二维码生成库，如 qrcode.js
                content.innerHTML = `
                    <div class="mb-3">
                        <img src="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(data.config)}" 
                             alt="配置二维码" class="img-fluid">
                    </div>
                    <p class="text-muted">使用WireGuard客户端扫描此二维码快速配置</p>
                    <div class="input-group">
                        <input type="text" class="form-control" value="${data.config}" readonly>
                        <button class="btn btn-outline-secondary" type="button" onclick="copyToClipboard('${data.config}')">
                            <i class="bi bi-clipboard"></i>
                        </button>
                    </div>
                `;
            } else {
                content.innerHTML = `<div class="alert alert-danger">${data.message || '生成二维码失败'}</div>`;
            }
        })
        .catch(error => {
            content.innerHTML = `<div class="alert alert-danger">生成二维码失败: ${error.message}</div>`;
        });
}

// 刷新客户端列表
function refreshClients() {
    window.location.reload();
}

// 表单验证
document.getElementById('addClientForm').addEventListener('submit', function(e) {
    const name = document.getElementById('name').value.trim();
    const serverId = document.getElementById('server_id').value;
    
    if (!name) {
        e.preventDefault();
        showMessage('客户端名称不能为空', 'error');
        return;
    }
    
    if (!serverId) {
        e.preventDefault();
        showMessage('请选择所属服务器', 'error');
        return;
    }
});

// 页面加载完成后显示消息
document.addEventListener('DOMContentLoaded', function() {
    <?php if (isset($_SESSION['message'])): ?>
    showMessage('<?= addslashes($_SESSION['message']) ?>', '<?= $_SESSION['message_type'] ?? 'info' ?>');
    <?php 
    unset($_SESSION['message']);
    unset($_SESSION['message_type']);
    ?>
    <?php endif; ?>
});
</script>
