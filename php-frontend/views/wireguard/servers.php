<!-- 页面标题和操作按钮 -->
<div class="d-flex justify-content-between align-items-center mb-4">
    <h2>WireGuard服务器管理</h2>
    <div>
        <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addServerModal">
            <i class="bi bi-plus-circle"></i> 添加服务器
        </button>
        <button type="button" class="btn btn-outline-secondary" onclick="refreshServers()">
            <i class="bi bi-arrow-clockwise"></i> 刷新
        </button>
    </div>
</div>

<!-- 服务器列表 -->
<div class="card">
    <div class="card-body">
        <?php if (empty($servers)): ?>
        <div class="text-center py-5">
            <i class="bi bi-shield-lock text-muted" style="font-size: 4rem;"></i>
            <h4 class="mt-3 text-muted">暂无WireGuard服务器</h4>
            <p class="text-muted">点击"添加服务器"按钮创建第一个服务器</p>
            <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addServerModal">
                <i class="bi bi-plus-circle"></i> 添加服务器
            </button>
        </div>
        <?php else: ?>
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>名称</th>
                        <th>接口</th>
                        <th>监听端口</th>
                        <th>IPv4地址</th>
                        <th>IPv6地址</th>
                        <th>状态</th>
                        <th>客户端数</th>
                        <th>操作</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($servers as $server): ?>
                    <tr data-id="<?= $server['id'] ?>">
                        <td>
                            <strong><?= htmlspecialchars($server['name'] ?? '') ?></strong>
                            <?php if (!empty($server['description'])): ?>
                            <br><small class="text-muted"><?= htmlspecialchars($server['description']) ?></small>
                            <?php endif; ?>
                        </td>
                        <td>
                            <code><?= htmlspecialchars($server['interface'] ?? '') ?></code>
                        </td>
                        <td><?= $server['listen_port'] ?? '' ?></td>
                        <td>
                            <?php if (!empty($server['ipv4_address'])): ?>
                            <code><?= htmlspecialchars($server['ipv4_address']) ?></code>
                            <?php else: ?>
                            <span class="text-muted">-</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?php if (!empty($server['ipv6_address'])): ?>
                            <code><?= htmlspecialchars($server['ipv6_address']) ?></code>
                            <?php else: ?>
                            <span class="text-muted">-</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <span class="badge bg-<?= ($server['status'] ?? '') === 'running' ? 'success' : 'danger' ?>">
                                <?= ($server['status'] ?? '') === 'running' ? '运行中' : '已停止' ?>
                            </span>
                        </td>
                        <td>
                            <span class="badge bg-info"><?= $server['client_count'] ?? 0 ?></span>
                        </td>
                        <td>
                            <div class="btn-group btn-group-sm" role="group">
                                <button type="button" class="btn btn-outline-primary" onclick="viewServer('<?= $server['id'] ?>')" title="查看详情">
                                    <i class="bi bi-eye"></i>
                                </button>
                                <button type="button" class="btn btn-outline-secondary" onclick="editServer('<?= $server['id'] ?>')" title="编辑">
                                    <i class="bi bi-pencil"></i>
                                </button>
                                <button type="button" class="btn btn-outline-success" onclick="exportServerConfig('<?= $server['id'] ?>')" title="导出配置">
                                    <i class="bi bi-download"></i>
                                </button>
                                <?php if (($server['status'] ?? '') === 'running'): ?>
                                <button type="button" class="btn btn-outline-warning" onclick="stopServer('<?= $server['id'] ?>')" title="停止">
                                    <i class="bi bi-stop"></i>
                                </button>
                                <?php else: ?>
                                <button type="button" class="btn btn-outline-success" onclick="startServer('<?= $server['id'] ?>')" title="启动">
                                    <i class="bi bi-play"></i>
                                </button>
                                <?php endif; ?>
                                <button type="button" class="btn btn-outline-danger" onclick="deleteServer('<?= $server['id'] ?>')" title="删除">
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

<!-- 添加服务器模态框 -->
<div class="modal fade" id="addServerModal" tabindex="-1" aria-labelledby="addServerModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <form method="POST" action="/wireguard/servers" id="addServerForm">
                <div class="modal-header">
                    <h5 class="modal-title" id="addServerModalLabel">添加WireGuard服务器</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" name="_token" value="<?= $this->auth->generateCsrfToken() ?>">
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="name" class="form-label">服务器名称 <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" id="name" name="name" required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="interface" class="form-label">网络接口</label>
                                <input type="text" class="form-control" id="interface" name="interface" value="wg0">
                            </div>
                        </div>
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="listen_port" class="form-label">监听端口</label>
                                <input type="number" class="form-control" id="listen_port" name="listen_port" value="51820" min="1024" max="65535">
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="mtu" class="form-label">MTU</label>
                                <input type="number" class="form-control" id="mtu" name="mtu" value="1420" min="1280" max="1500">
                            </div>
                        </div>
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="ipv4_address" class="form-label">IPv4地址</label>
                                <input type="text" class="form-control" id="ipv4_address" name="ipv4_address" placeholder="10.0.0.1/24">
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="ipv6_address" class="form-label">IPv6地址</label>
                                <input type="text" class="form-control" id="ipv6_address" name="ipv6_address" placeholder="fd00::1/64">
                            </div>
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        <label for="dns_servers" class="form-label">DNS服务器</label>
                        <input type="text" class="form-control" id="dns_servers" name="dns_servers" placeholder="8.8.8.8, 8.8.4.4">
                        <div class="form-text">多个DNS服务器用逗号分隔</div>
                    </div>
                    
                    <div class="mb-3">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" id="is_active" name="is_active" checked>
                            <label class="form-check-label" for="is_active">
                                启用服务器
                            </label>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                    <button type="submit" class="btn btn-primary">创建服务器</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- 编辑服务器模态框 -->
<div class="modal fade" id="editServerModal" tabindex="-1" aria-labelledby="editServerModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <form method="POST" id="editServerForm">
                <div class="modal-header">
                    <h5 class="modal-title" id="editServerModalLabel">编辑WireGuard服务器</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" name="_token" value="<?= $this->auth->generateCsrfToken() ?>">
                    <input type="hidden" id="edit_server_id" name="server_id">
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="edit_name" class="form-label">服务器名称 <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" id="edit_name" name="name" required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="edit_interface" class="form-label">网络接口</label>
                                <input type="text" class="form-control" id="edit_interface" name="interface">
                            </div>
                        </div>
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="edit_listen_port" class="form-label">监听端口</label>
                                <input type="number" class="form-control" id="edit_listen_port" name="listen_port" min="1024" max="65535">
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="edit_mtu" class="form-label">MTU</label>
                                <input type="number" class="form-control" id="edit_mtu" name="mtu" min="1280" max="1500">
                            </div>
                        </div>
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
                        <label for="edit_dns_servers" class="form-label">DNS服务器</label>
                        <input type="text" class="form-control" id="edit_dns_servers" name="dns_servers">
                        <div class="form-text">多个DNS服务器用逗号分隔</div>
                    </div>
                    
                    <div class="mb-3">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" id="edit_is_active" name="is_active">
                            <label class="form-check-label" for="edit_is_active">
                                启用服务器
                            </label>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                    <button type="submit" class="btn btn-primary">更新服务器</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- 服务器详情模态框 -->
<div class="modal fade" id="serverDetailModal" tabindex="-1" aria-labelledby="serverDetailModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="serverDetailModalLabel">服务器详情</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body" id="serverDetailContent">
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

<script>
// 全局错误处理
window.addEventListener('error', function(e) {
    console.error('JavaScript错误:', e.error);
    showMessage('页面发生错误，请刷新页面重试', 'error');
});

// HTML转义函数
function escapeHtml(text) {
    if (typeof text !== 'string') return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// 复制到剪贴板
function copyToClipboard(text) {
    try {
        if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard.writeText(text).then(() => {
                showMessage('已复制到剪贴板', 'success');
            }).catch(err => {
                console.error('复制失败:', err);
                fallbackCopyToClipboard(text);
            });
        } else {
            fallbackCopyToClipboard(text);
        }
    } catch (error) {
        console.error('复制到剪贴板错误:', error);
        showMessage('复制失败', 'error');
    }
}

// 备用复制方法
function fallbackCopyToClipboard(text) {
    try {
        const textArea = document.createElement('textarea');
        textArea.value = text;
        textArea.style.position = 'fixed';
        textArea.style.left = '-999999px';
        textArea.style.top = '-999999px';
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);
        showMessage('已复制到剪贴板', 'success');
    } catch (error) {
        console.error('备用复制方法失败:', error);
        showMessage('复制失败', 'error');
    }
}

// 显示消息
function showMessage(message, type = 'info') {
    try {
        // 检查是否存在消息容器
        let messageContainer = document.getElementById('messageContainer');
        if (!messageContainer) {
            messageContainer = document.createElement('div');
            messageContainer.id = 'messageContainer';
            messageContainer.style.position = 'fixed';
            messageContainer.style.top = '20px';
            messageContainer.style.right = '20px';
            messageContainer.style.zIndex = '9999';
            document.body.appendChild(messageContainer);
        }
        
        const alertClass = {
            'success': 'alert-success',
            'error': 'alert-danger',
            'warning': 'alert-warning',
            'info': 'alert-info'
        }[type] || 'alert-info';
        
        const alertElement = document.createElement('div');
        alertElement.className = `alert ${alertClass} alert-dismissible fade show`;
        alertElement.innerHTML = `
            ${escapeHtml(message)}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        `;
        
        messageContainer.appendChild(alertElement);
        
        // 自动隐藏
        setTimeout(() => {
            if (alertElement.parentNode) {
                alertElement.remove();
            }
        }, 5000);
    } catch (error) {
        console.error('显示消息错误:', error);
        alert(message); // 备用显示方法
    }
}

// 确认删除
function confirmDelete(message) {
    try {
        return confirm(message || '确定要删除吗？此操作不可撤销。');
    } catch (error) {
        console.error('确认删除错误:', error);
        return false;
    }
}

// 查看服务器详情
function viewServer(serverId) {
    try {
        // 检查DOM元素是否存在
        const modalElement = document.getElementById('serverDetailModal');
        const contentElement = document.getElementById('serverDetailContent');
        
        if (!modalElement || !contentElement) {
            throw new Error('找不到服务器详情模态框元素');
        }
        
        const modal = new bootstrap.Modal(modalElement);
        
        // 显示加载状态
        contentElement.innerHTML = `
            <div class="text-center">
                <div class="spinner-border" role="status">
                    <span class="visually-hidden">加载中...</span>
                </div>
            </div>
        `;
        
        modal.show();
        
        // 获取服务器数据
        fetch(`/wireguard/servers/${serverId}`)
            .then(response => {
                if (!response.ok) {
                    throw new Error(`HTTP错误: ${response.status}`);
                }
                return response.json();
            })
            .then(data => {
                if (data.success) {
                    const server = data.data;
                    contentElement.innerHTML = `
                        <div class="row">
                            <div class="col-md-6">
                                <h6>基本信息</h6>
                                <table class="table table-sm">
                                    <tr><td>名称:</td><td>${escapeHtml(server.name || '')}</td></tr>
                                    <tr><td>接口:</td><td><code>${escapeHtml(server.interface || '')}</code></td></tr>
                                    <tr><td>监听端口:</td><td>${escapeHtml(server.listen_port || '')}</td></tr>
                                    <tr><td>MTU:</td><td>${escapeHtml(server.mtu || '')}</td></tr>
                                    <tr><td>状态:</td><td><span class="badge bg-${server.status === 'running' ? 'success' : 'danger'}">${server.status === 'running' ? '运行中' : '已停止'}</span></td></tr>
                                </table>
                            </div>
                            <div class="col-md-6">
                                <h6>网络配置</h6>
                                <table class="table table-sm">
                                    <tr><td>IPv4地址:</td><td><code>${escapeHtml(server.ipv4_address || '-')}</code></td></tr>
                                    <tr><td>IPv6地址:</td><td><code>${escapeHtml(server.ipv6_address || '-')}</code></td></tr>
                                    <tr><td>DNS服务器:</td><td><code>${escapeHtml(server.dns_servers ? server.dns_servers.join(', ') : '-')}</code></td></tr>
                                </table>
                            </div>
                        </div>
                        <div class="row mt-3">
                            <div class="col-12">
                                <h6>公钥</h6>
                                <div class="input-group">
                                    <input type="text" class="form-control" value="${escapeHtml(server.public_key || '')}" readonly>
                                    <button class="btn btn-outline-secondary" type="button" onclick="copyToClipboard('${escapeHtml(server.public_key || '')}')">
                                        <i class="bi bi-clipboard"></i>
                                    </button>
                                </div>
                            </div>
                        </div>
                    `;
                } else {
                    contentElement.innerHTML = `<div class="alert alert-danger">${escapeHtml(data.message || '加载失败')}</div>`;
                }
            })
            .catch(error => {
                console.error('查看服务器详情错误:', error);
                contentElement.innerHTML = `<div class="alert alert-danger">加载失败: ${escapeHtml(error.message)}</div>`;
            });
    } catch (error) {
        console.error('查看服务器详情初始化错误:', error);
        showMessage('初始化查看功能失败: ' + error.message, 'error');
    }
}

// 编辑服务器
function editServer(serverId) {
    try {
        const modal = new bootstrap.Modal(document.getElementById('editServerModal'));
        const form = document.getElementById('editServerForm');
        
        if (!modal || !form) {
            throw new Error('找不到编辑服务器所需的DOM元素');
        }
        
        // 获取服务器数据
        fetch(`/wireguard/servers/${serverId}`)
            .then(response => {
                if (!response.ok) {
                    throw new Error(`HTTP错误: ${response.status}`);
                }
                return response.json();
            })
            .then(data => {
                if (data.success) {
                    const server = data.data;
                    
                    // 设置表单值
                    const fields = {
                        'edit_server_id': serverId,
                        'edit_name': server.name || '',
                        'edit_interface': server.interface || '',
                        'edit_listen_port': server.listen_port || '',
                        'edit_mtu': server.mtu || '',
                        'edit_ipv4_address': server.ipv4_address || '',
                        'edit_ipv6_address': server.ipv6_address || '',
                        'edit_dns_servers': server.dns_servers ? server.dns_servers.join(', ') : '',
                        'edit_is_active': server.is_active || false
                    };
                    
                    Object.entries(fields).forEach(([fieldId, value]) => {
                        const element = document.getElementById(fieldId);
                        if (element) {
                            if (element.type === 'checkbox') {
                                element.checked = Boolean(value);
                            } else {
                                element.value = value;
                            }
                        }
                    });
                    
                    form.action = `/wireguard/servers/${serverId}/update`;
                    modal.show();
                } else {
                    showMessage(data.message || '加载服务器信息失败', 'error');
                }
            })
            .catch(error => {
                console.error('编辑服务器错误:', error);
                showMessage('加载服务器信息失败: ' + error.message, 'error');
            });
    } catch (error) {
        console.error('编辑服务器初始化错误:', error);
        showMessage('初始化编辑功能失败: ' + error.message, 'error');
    }
}

// 删除服务器
function deleteServer(serverId) {
    if (confirmDelete('确定要删除这个服务器吗？此操作不可撤销。')) {
        window.location.href = `/wireguard/servers/${serverId}/delete`;
    }
}

// 启动服务器
function startServer(serverId) {
    if (confirm('确定要启动这个服务器吗？')) {
        window.location.href = `/wireguard/servers/${serverId}/start`;
    }
}

// 停止服务器
function stopServer(serverId) {
    if (confirm('确定要停止这个服务器吗？')) {
        window.location.href = `/wireguard/servers/${serverId}/stop`;
    }
}

// 导出服务器配置
function exportServerConfig(serverId) {
    window.open(`/wireguard/servers/${serverId}/export`, '_blank');
}

// 刷新服务器列表
function refreshServers() {
    window.location.reload();
}

// 表单验证
document.addEventListener('DOMContentLoaded', function() {
    try {
        // 添加服务器表单验证
        const addServerForm = document.getElementById('addServerForm');
        if (addServerForm) {
            addServerForm.addEventListener('submit', function(e) {
                try {
                    const name = document.getElementById('name');
                    const ipv4 = document.getElementById('ipv4_address');
                    const ipv6 = document.getElementById('ipv6_address');
                    
                    if (!name || !ipv4 || !ipv6) {
                        e.preventDefault();
                        showMessage('表单元素缺失，请刷新页面重试', 'error');
                        return;
                    }
                    
                    const nameValue = name.value.trim();
                    const ipv4Value = ipv4.value.trim();
                    const ipv6Value = ipv6.value.trim();
                    
                    if (!nameValue) {
                        e.preventDefault();
                        showMessage('服务器名称不能为空', 'error');
                        name.focus();
                        return;
                    }
                    
                    if (!ipv4Value && !ipv6Value) {
                        e.preventDefault();
                        showMessage('至少需要配置一个IP地址', 'error');
                        ipv4.focus();
                        return;
                    }
                } catch (error) {
                    console.error('表单验证错误:', error);
                    e.preventDefault();
                    showMessage('表单验证失败', 'error');
                }
            });
        }
        
        // 编辑服务器表单验证
        const editServerForm = document.getElementById('editServerForm');
        if (editServerForm) {
            editServerForm.addEventListener('submit', function(e) {
                try {
                    const name = document.getElementById('edit_name');
                    const ipv4 = document.getElementById('edit_ipv4_address');
                    const ipv6 = document.getElementById('edit_ipv6_address');
                    
                    if (!name || !ipv4 || !ipv6) {
                        e.preventDefault();
                        showMessage('表单元素缺失，请刷新页面重试', 'error');
                        return;
                    }
                    
                    const nameValue = name.value.trim();
                    const ipv4Value = ipv4.value.trim();
                    const ipv6Value = ipv6.value.trim();
                    
                    if (!nameValue) {
                        e.preventDefault();
                        showMessage('服务器名称不能为空', 'error');
                        name.focus();
                        return;
                    }
                    
                    if (!ipv4Value && !ipv6Value) {
                        e.preventDefault();
                        showMessage('至少需要配置一个IP地址', 'error');
                        ipv4.focus();
                        return;
                    }
                } catch (error) {
                    console.error('编辑表单验证错误:', error);
                    e.preventDefault();
                    showMessage('表单验证失败', 'error');
                }
            });
        }
        
        // 显示PHP消息
        <?php if (isset($_SESSION['message'])): ?>
        showMessage('<?= addslashes($_SESSION['message']) ?>', '<?= $_SESSION['message_type'] ?? 'info' ?>');
        <?php 
        unset($_SESSION['message']);
        unset($_SESSION['message_type']);
        ?>
        <?php endif; ?>
        
    } catch (error) {
        console.error('页面初始化错误:', error);
        showMessage('页面初始化失败，请刷新页面重试', 'error');
    }
});
</script>
