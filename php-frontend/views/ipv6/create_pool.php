<?php
// views/ipv6/create_pool.php
require_once __DIR__ . '/../views/layout/header.php';
?>

<div class="container">
    <h2>创建IPv6前缀池</h2>

    <?php if (isset($error)): ?>
        <div class="alert alert-danger"><?php echo htmlspecialchars($error); ?></div>
    <?php endif; ?>

    <div class="card">
        <div class="card-header">
            <h5 class="mb-0">IPv6前缀池配置</h5>
        </div>
        <div class="card-body">
            <form method="POST" action="/ipv6/pools/create">
                <div class="row">
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label for="name" class="form-label">池名称 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="name" name="name" required>
                            <div class="form-text">为IPv6前缀池指定一个易于识别的名称</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label for="description" class="form-label">描述</label>
                            <input type="text" class="form-control" id="description" name="description">
                            <div class="form-text">前缀池的详细描述信息</div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label for="base_prefix" class="form-label">基础前缀 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="base_prefix" name="base_prefix" required 
                                   placeholder="2001:db8::/32">
                            <div class="form-text">IPv6基础网络前缀</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label for="prefix_len" class="form-label">前缀长度 <span class="text-danger">*</span></label>
                            <input type="number" class="form-control" id="prefix_len" name="prefix_len" required 
                                   min="1" max="128" value="32">
                            <div class="form-text">基础前缀的长度 (1-128)</div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label for="subnet_len" class="form-label">子网长度 <span class="text-danger">*</span></label>
                            <input type="number" class="form-control" id="subnet_len" name="subnet_len" required 
                                   min="1" max="128" value="48">
                            <div class="form-text">分配给客户端的子网长度</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="mb-3">
                            <div class="form-check mt-4">
                                <input class="form-check-input" type="checkbox" id="is_active" name="is_active" checked>
                                <label class="form-check-label" for="is_active">
                                    激活前缀池
                                </label>
                                <div class="form-text">创建后立即激活前缀池</div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 容量预览 -->
                <div class="row">
                    <div class="col-12">
                        <div class="alert alert-info">
                            <h6><i class="bi bi-info-circle"></i> 容量预览</h6>
                            <div id="capacity-preview">
                                <p>请填写前缀长度和子网长度以查看容量信息</p>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-12">
                        <div class="d-flex justify-content-between">
                            <a href="/ipv6/pools" class="btn btn-secondary">
                                <i class="bi bi-arrow-left"></i> 返回列表
                            </a>
                            <button type="submit" class="btn btn-primary">
                                <i class="bi bi-plus-circle"></i> 创建前缀池
                            </button>
                        </div>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- IPv6前缀池配置说明 -->
    <div class="card mt-4">
        <div class="card-header">
            <h5 class="mb-0">配置说明</h5>
        </div>
        <div class="card-body">
            <div class="row">
                <div class="col-md-6">
                    <h6>前缀长度说明</h6>
                    <ul>
                        <li><strong>/32</strong>: 大型ISP级别</li>
                        <li><strong>/40</strong>: 中型企业</li>
                        <li><strong>/48</strong>: 小型企业/家庭</li>
                        <li><strong>/56</strong>: 家庭网络</li>
                        <li><strong>/64</strong>: 单个子网</li>
                    </ul>
                </div>
                <div class="col-md-6">
                    <h6>容量计算</h6>
                    <ul>
                        <li><strong>总容量</strong>: 2^(子网长度-前缀长度)</li>
                        <li><strong>示例</strong>: /32 → /48 = 2^16 = 65,536个子网</li>
                        <li><strong>每个子网</strong>: 2^(64-子网长度)个主机</li>
                    </ul>
                </div>
            </div>
            <div class="row mt-3">
                <div class="col-md-12">
                    <h6>常见配置示例</h6>
                    <div class="table-responsive">
                        <table class="table table-sm">
                            <thead>
                                <tr>
                                    <th>基础前缀</th>
                                    <th>前缀长度</th>
                                    <th>子网长度</th>
                                    <th>总容量</th>
                                    <th>每个子网主机数</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td>2001:db8::/32</td>
                                    <td>32</td>
                                    <td>48</td>
                                    <td>65,536</td>
                                    <td>65,536</td>
                                </tr>
                                <tr>
                                    <td>2001:db8::/40</td>
                                    <td>40</td>
                                    <td>56</td>
                                    <td>65,536</td>
                                    <td>256</td>
                                </tr>
                                <tr>
                                    <td>2001:db8::/48</td>
                                    <td>48</td>
                                    <td>64</td>
                                    <td>65,536</td>
                                    <td>1</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
// 容量预览计算
function updateCapacityPreview() {
    const prefixLen = parseInt(document.getElementById('prefix_len').value) || 0;
    const subnetLen = parseInt(document.getElementById('subnet_len').value) || 0;
    const preview = document.getElementById('capacity-preview');
    
    if (prefixLen > 0 && subnetLen > 0 && subnetLen >= prefixLen) {
        const totalCapacity = Math.pow(2, subnetLen - prefixLen);
        const hostsPerSubnet = Math.pow(2, 64 - subnetLen);
        
        preview.innerHTML = `
            <div class="row">
                <div class="col-md-4">
                    <strong>总容量:</strong> ${totalCapacity.toLocaleString()} 个子网
                </div>
                <div class="col-md-4">
                    <strong>每个子网:</strong> ${hostsPerSubnet.toLocaleString()} 个主机
                </div>
                <div class="col-md-4">
                    <strong>总主机数:</strong> ${(totalCapacity * hostsPerSubnet).toLocaleString()}
                </div>
            </div>
        `;
    } else if (prefixLen > 0 && subnetLen > 0) {
        preview.innerHTML = '<p class="text-danger">子网长度必须大于等于前缀长度</p>';
    } else {
        preview.innerHTML = '<p>请填写前缀长度和子网长度以查看容量信息</p>';
    }
}

// 绑定事件
document.getElementById('prefix_len').addEventListener('input', updateCapacityPreview);
document.getElementById('subnet_len').addEventListener('input', updateCapacityPreview);
</script>

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

.table th {
    background-color: #f8f9fa;
    font-weight: 600;
}
</style>

<?php
require_once __DIR__ . '/../views/layout/footer.php';
?>
