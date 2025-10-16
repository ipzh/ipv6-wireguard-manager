                </div>
            </div>
        </div>
    </div>
    
    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <!-- jQuery -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    
    <script>
        // 全局JavaScript函数
        
        /**
         * 显示消息提示
         */
        function showMessage(message, type = 'info') {
            const messageArea = document.getElementById('messageArea');
            const alertClass = {
                'success': 'alert-success',
                'error': 'alert-danger',
                'warning': 'alert-warning',
                'info': 'alert-info'
            }[type] || 'alert-info';
            
            const alertHtml = `
                <div class="alert ${alertClass} alert-dismissible fade show" role="alert">
                    ${message}
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            `;
            
            messageArea.innerHTML = alertHtml;
            
            // 5秒后自动隐藏
            setTimeout(() => {
                const alert = messageArea.querySelector('.alert');
                if (alert) {
                    const bsAlert = new bootstrap.Alert(alert);
                    bsAlert.close();
                }
            }, 5000);
        }
        
        /**
         * 显示加载状态
         */
        function showLoading(element) {
            if (typeof element === 'string') {
                element = document.querySelector(element);
            }
            if (element) {
                element.classList.add('loading', 'show');
            }
        }
        
        /**
         * 隐藏加载状态
         */
        function hideLoading(element) {
            if (typeof element === 'string') {
                element = document.querySelector(element);
            }
            if (element) {
                element.classList.remove('loading', 'show');
            }
        }
        
        /**
         * 刷新页面
         */
        function refreshPage() {
            window.location.reload();
        }
        
        /**
         * 确认删除
         */
        function confirmDelete(message = '确定要删除吗？') {
            return confirm(message);
        }
        
        /**
         * 格式化时间
         */
        function formatTime(timestamp) {
            const date = new Date(timestamp * 1000);
            return date.toLocaleString('zh-CN');
        }
        
        /**
         * 格式化文件大小
         */
        function formatFileSize(bytes) {
            if (bytes === 0) return '0 Bytes';
            const k = 1024;
            const sizes = ['Bytes', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        }
        
        /**
         * 复制到剪贴板
         */
        function copyToClipboard(text) {
            navigator.clipboard.writeText(text).then(() => {
                showMessage('已复制到剪贴板', 'success');
            }).catch(() => {
                showMessage('复制失败', 'error');
            });
        }
        
        /**
         * AJAX请求封装
         */
        function apiRequest(url, method = 'GET', data = null) {
            return new Promise((resolve, reject) => {
                const options = {
                    method: method,
                    headers: {
                        'Content-Type': 'application/json',
                        'X-Requested-With': 'XMLHttpRequest'
                    }
                };
                
                if (data) {
                    options.body = JSON.stringify(data);
                }
                
                fetch(url, options)
                    .then(response => {
                        if (!response.ok) {
                            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                        }
                        return response.json();
                    })
                    .then(data => resolve(data))
                    .catch(error => reject(error));
            });
        }
        
        /**
         * 表格行点击事件
         */
        function initTableRowClick() {
            document.querySelectorAll('table tbody tr').forEach(row => {
                row.style.cursor = 'pointer';
                row.addEventListener('click', function() {
                    const id = this.dataset.id;
                    if (id) {
                        // 可以在这里添加行点击逻辑
                        console.log('点击行ID:', id);
                    }
                });
            });
        }
        
        /**
         * 初始化工具提示
         */
        function initTooltips() {
            const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
            tooltipTriggerList.map(function (tooltipTriggerEl) {
                return new bootstrap.Tooltip(tooltipTriggerEl);
            });
        }
        
        /**
         * 页面加载完成后初始化
         */
        document.addEventListener('DOMContentLoaded', function() {
            initTableRowClick();
            initTooltips();
            
            // 自动隐藏消息提示
            setTimeout(() => {
                const alerts = document.querySelectorAll('.alert');
                alerts.forEach(alert => {
                    const bsAlert = new bootstrap.Alert(alert);
                    bsAlert.close();
                });
            }, 5000);
        });
        
        /**
         * 错误处理
         */
        window.addEventListener('error', function(e) {
            console.error('JavaScript错误:', e.error);
            showMessage('页面发生错误，请刷新重试', 'error');
        });
        
        /**
         * 未处理的Promise拒绝
         */
        window.addEventListener('unhandledrejection', function(e) {
            console.error('未处理的Promise拒绝:', e.reason);
            showMessage('请求失败，请检查网络连接', 'error');
        });
    </script>
    
    <?php if (isset($customScripts)): ?>
        <?php foreach ($customScripts as $script): ?>
            <script src="<?= $script ?>"></script>
        <?php endforeach; ?>
    <?php endif; ?>
    
    <?php if (isset($inlineScripts)): ?>
        <script>
            <?= $inlineScripts ?>
        </script>
    <?php endif; ?>
</body>
</html>
