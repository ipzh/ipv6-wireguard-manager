/**
 * API端点配置 - 统一版本
 * 
 * 本文件定义了前端应用中使用的所有API端点配置。
 * 使用UMD格式确保浏览器兼容性。
 */

(function(global) {
    'use strict';
    
    // API基础配置
    const API_CONFIG = {
        // 基础URL，在生产环境中应该从环境变量获取
        BASE_URL: typeof window !== 'undefined' && window.location.hostname === 'localhost'
            ? 'http://localhost:${API_PORT}/api'
            : '/api',
        
        // 请求超时时间（毫秒）
        TIMEOUT: 30000,
        
        // API版本
        VERSION: 'v1',
        
        // 默认请求头
        DEFAULT_HEADERS: {
            'Content-Type': 'application/json',
        },
    };

    // 统一API路径构建器实现
    class ApiPathBuilder {
        constructor(baseUrl, version = 'v1') {
            this.baseUrl = baseUrl || API_CONFIG.BASE_URL;
            this.version = version;
            this.paths = new Map();
            this.cache = new Map();
            this.registerDefaultPaths();
        }

        registerDefaultPaths() {
            // 认证相关路径
            this.registerPath('auth.login', '/auth/login', ['POST'], '用户登录');
            this.registerPath('auth.logout', '/auth/logout', ['POST'], '用户登出');
            this.registerPath('auth.refresh', '/auth/refresh', ['POST'], '刷新令牌');
            this.registerPath('auth.register', '/auth/register', ['POST'], '用户注册');
            this.registerPath('auth.verify_email', '/auth/verify-email', ['POST'], '验证邮箱');
            this.registerPath('auth.reset_password', '/auth/reset-password', ['POST'], '重置密码');
            this.registerPath('auth.change_password', '/auth/change-password', ['POST'], '修改密码');
            this.registerPath('auth.me', '/auth/me', ['GET'], '获取当前用户信息');
            
            // 用户管理路径
            this.registerPath('users', '/users', ['GET', 'POST'], '用户列表/创建用户');
            this.registerPath('users.get', '/users/{user_id}', ['GET'], '获取用户详情', ['user_id']);
            this.registerPath('users.update', '/users/{user_id}', ['PUT', 'PATCH'], '更新用户信息', ['user_id']);
            this.registerPath('users.delete', '/users/{user_id}', ['DELETE'], '删除用户', ['user_id']);
            this.registerPath('users.lock', '/users/{user_id}/lock', ['POST'], '锁定用户', ['user_id']);
            this.registerPath('users.unlock', '/users/{user_id}/unlock', ['POST'], '解锁用户', ['user_id']);
            this.registerPath('users.profile', '/users/me/profile', ['GET', 'PUT'], '获取/更新个人资料');
            this.registerPath('users.avatar', '/users/me/avatar', ['GET', 'POST'], '获取/更新头像');
            
            // WireGuard管理路径
            this.registerPath('wireguard.servers', '/wireguard/servers', ['GET', 'POST'], 'WireGuard服务器列表/创建服务器');
            this.registerPath('wireguard.servers.get', '/wireguard/servers/{server_id}', ['GET'], '获取WireGuard服务器详情', ['server_id']);
            this.registerPath('wireguard.servers.update', '/wireguard/servers/{server_id}', ['PUT', 'PATCH'], '更新WireGuard服务器', ['server_id']);
            this.registerPath('wireguard.servers.delete', '/wireguard/servers/{server_id}', ['DELETE'], '删除WireGuard服务器', ['server_id']);
            this.registerPath('wireguard.servers.status', '/wireguard/servers/{server_id}/status', ['GET'], '获取服务器状态', ['server_id']);
            this.registerPath('wireguard.servers.start', '/wireguard/servers/{server_id}/start', ['POST'], '启动服务器', ['server_id']);
            this.registerPath('wireguard.servers.stop', '/wireguard/servers/{server_id}/stop', ['POST'], '停止服务器', ['server_id']);
            this.registerPath('wireguard.servers.restart', '/wireguard/servers/{server_id}/restart', ['POST'], '重启服务器', ['server_id']);
            this.registerPath('wireguard.servers.config', '/wireguard/servers/{server_id}/config', ['GET', 'PUT'], '获取/更新服务器配置', ['server_id']);
            this.registerPath('wireguard.servers.peers', '/wireguard/servers/{server_id}/peers', ['GET'], '获取服务器对等节点', ['server_id']);
            
            this.registerPath('wireguard.clients', '/wireguard/clients', ['GET', 'POST'], 'WireGuard客户端列表/创建客户端');
            this.registerPath('wireguard.clients.get', '/wireguard/clients/{client_id}', ['GET'], '获取WireGuard客户端详情', ['client_id']);
            this.registerPath('wireguard.clients.update', '/wireguard/clients/{client_id}', ['PUT', 'PATCH'], '更新WireGuard客户端', ['client_id']);
            this.registerPath('wireguard.clients.delete', '/wireguard/clients/{client_id}', ['DELETE'], '删除WireGuard客户端', ['client_id']);
            this.registerPath('wireguard.clients.config', '/wireguard/clients/{client_id}/config', ['GET'], '获取客户端配置', ['client_id']);
            this.registerPath('wireguard.clients.qr_code', '/wireguard/clients/{client_id}/qr-code', ['GET'], '获取客户端二维码', ['client_id']);
            this.registerPath('wireguard.clients.enable', '/wireguard/clients/{client_id}/enable', ['POST'], '启用客户端', ['client_id']);
            this.registerPath('wireguard.clients.disable', '/wireguard/clients/{client_id}/disable', ['POST'], '禁用客户端', ['client_id']);
            
            // 系统管理路径
            this.registerPath('system.info', '/system/info', ['GET'], '获取系统信息');
            this.registerPath('system.status', '/system/status', ['GET'], '获取系统状态');
            this.registerPath('system.health', '/system/health', ['GET'], '获取系统健康状态');
            this.registerPath('system.metrics', '/system/metrics', ['GET'], '获取系统指标');
            this.registerPath('system.config', '/system/config', ['GET', 'PUT'], '获取/更新系统配置');
            this.registerPath('system.logs', '/system/logs', ['GET'], '获取系统日志');
            this.registerPath('system.backup', '/system/backup', ['POST'], '创建系统备份');
            this.registerPath('system.restore', '/system/restore', ['POST'], '恢复系统备份');
            
            // 监控路径
            this.registerPath('monitoring.dashboard', '/monitoring/dashboard', ['GET'], '监控仪表板');
            this.registerPath('monitoring.alerts', '/monitoring/alerts', ['GET', 'POST'], '监控告警列表/创建告警');
            this.registerPath('monitoring.alerts.get', '/monitoring/alerts/{alert_id}', ['GET'], '获取监控告警详情', ['alert_id']);
            this.registerPath('monitoring.alerts.update', '/monitoring/alerts/{alert_id}', ['PUT', 'PATCH'], '更新监控告警', ['alert_id']);
            this.registerPath('monitoring.alerts.delete', '/monitoring/alerts/{alert_id}', ['DELETE'], '删除监控告警', ['alert_id']);
            this.registerPath('monitoring.alerts.acknowledge', '/monitoring/alerts/{alert_id}/acknowledge', ['POST'], '确认监控告警', ['alert_id']);
            
            this.registerPath('monitoring.metrics', '/monitoring/metrics', ['GET', 'POST'], '监控指标列表/添加指标');
            this.registerPath('monitoring.metrics.get', '/monitoring/metrics/{metric_id}', ['GET'], '获取监控指标详情', ['metric_id']);
            
            // 日志路径
            this.registerPath('logs', '/logs', ['GET'], '日志列表');
            this.registerPath('logs.get', '/logs/{log_id}', ['GET'], '获取日志详情', ['log_id']);
            this.registerPath('logs.search', '/logs/search', ['POST'], '搜索日志');
            this.registerPath('logs.export', '/logs/export', ['POST'], '导出日志');
            this.registerPath('logs.cleanup', '/logs/cleanup', ['POST'], '清理日志');
        }

        registerPath(name, path, methods = ['GET'], description = '', parameters = []) {
            // 支持旧格式兼容性：methods可以是字符串或数组
            if (typeof methods === 'string') {
                methods = [methods];
            }
            
            this.paths.set(name, { 
                path, 
                methods, 
                description,
                parameters
            });
        }

        buildUrl(pathName, params = {}) {
            // 检查缓存
            const cacheKey = `${pathName}:${JSON.stringify(params)}`;
            if (this.cache.has(cacheKey)) {
                return this.cache.get(cacheKey);
            }
            
            const pathConfig = this.paths.get(pathName);
            if (!pathConfig) {
                throw new Error(`路径 ${pathName} 未找到`);
            }

            let url = this.baseUrl + pathConfig.path;
            
            // 替换路径参数
            Object.keys(params).forEach(key => {
                const placeholder = `{${key}}`;
                if (url.includes(placeholder)) {
                    url = url.replace(placeholder, encodeURIComponent(params[key]));
                }
            });

            // 缓存结果
            this.cache.set(cacheKey, url);
            return url;
        }

        validatePath(pathName, params = {}, method = 'GET') {
            const pathConfig = this.paths.get(pathName);
            if (!pathConfig) {
                return { valid: false, error: `路径 ${pathName} 未找到` };
            }

            // 支持旧格式兼容性：method可能是字符串
            const methods = Array.isArray(pathConfig.methods) ? pathConfig.methods : [pathConfig.methods];
            
            if (!methods.includes(method)) {
                return { valid: false, error: `方法不匹配，期望 ${methods.join(', ')}，实际 ${method}` };
            }

            // 检查必需的路径参数
            const pathParams = pathConfig.path.match(/\{([^}]+)\}/g);
            if (pathParams) {
                for (const param of pathParams) {
                    const paramName = param.slice(1, -1);
                    if (!(paramName in params)) {
                        return { valid: false, error: `缺少必需的路径参数: ${paramName}` };
                    }
                }
            }

            return { valid: true };
        }

        getApiVersion() {
            return API_CONFIG.VERSION;
        }

        getApiBaseUrl() {
            return this.baseUrl;
        }

        setApiBaseUrl(newBaseUrl) {
            this.baseUrl = newBaseUrl;
        }

        getPathConfig(pathName) {
            const pathConfig = this.paths.get(pathName);
            if (!pathConfig) {
                throw new Error(`路径 ${pathName} 未找到`);
            }
            return pathConfig;
        }

        getAllPaths() {
            const paths = [];
            this.paths.forEach((config, name) => {
                paths.push({ name, ...config });
            });
            return paths;
        }

        clearCache() {
            this.cache.clear();
        }
    }

    // 创建API路径构建器实例
    const apiPathBuilder = new ApiPathBuilder(API_CONFIG.BASE_URL);
    
    // 导出到全局变量
    global.API_CONFIG = API_CONFIG;
    global.apiPathBuilder = apiPathBuilder;
    global.ApiPathBuilder = ApiPathBuilder;
    
    // 导出API路径构建器函数
    global.buildUrl = apiPathBuilder.buildUrl.bind(apiPathBuilder);
    global.validatePath = apiPathBuilder.validatePath.bind(apiPathBuilder);
    global.getApiVersion = apiPathBuilder.getApiVersion.bind(apiPathBuilder);
    global.getApiBaseUrl = apiPathBuilder.getApiBaseUrl.bind(apiPathBuilder);
    global.setApiBaseUrl = apiPathBuilder.setApiBaseUrl.bind(apiPathBuilder);
    global.registerPath = apiPathBuilder.registerPath.bind(apiPathBuilder);
    global.getPathConfig = apiPathBuilder.getPathConfig.bind(apiPathBuilder);
    global.getAllPaths = apiPathBuilder.getAllPaths.bind(apiPathBuilder);
    global.clearCache = apiPathBuilder.clearCache.bind(apiPathBuilder);
    
    // 为了向后兼容，保留一些旧的函数名
    global.getApiUrl = global.buildUrl;
    
    // 导出路径名称常量
    global.PATH_NAMES = {
        // 认证相关
        AUTH_LOGIN: 'auth.login',
        AUTH_LOGOUT: 'auth.logout',
        AUTH_REFRESH: 'auth.refresh',
        AUTH_REGISTER: 'auth.register',
        AUTH_VERIFY_EMAIL: 'auth.verify_email',
        AUTH_RESET_PASSWORD: 'auth.reset_password',
        AUTH_CHANGE_PASSWORD: 'auth.change_password',
        AUTH_ME: 'auth.me',
        
        // 用户管理
        USERS: 'users',
        USERS_GET: 'users.get',
        USERS_UPDATE: 'users.update',
        USERS_DELETE: 'users.delete',
        USERS_LOCK: 'users.lock',
        USERS_UNLOCK: 'users.unlock',
        USERS_PROFILE: 'users.profile',
        USERS_AVATAR: 'users.avatar',
        
        // WireGuard服务器
        WIREGUARD_SERVERS: 'wireguard.servers',
        WIREGUARD_SERVERS_GET: 'wireguard.servers.get',
        WIREGUARD_SERVERS_UPDATE: 'wireguard.servers.update',
        WIREGUARD_SERVERS_DELETE: 'wireguard.servers.delete',
        WIREGUARD_SERVERS_STATUS: 'wireguard.servers.status',
        WIREGUARD_SERVERS_START: 'wireguard.servers.start',
        WIREGUARD_SERVERS_STOP: 'wireguard.servers.stop',
        WIREGUARD_SERVERS_RESTART: 'wireguard.servers.restart',
        WIREGUARD_SERVERS_CONFIG: 'wireguard.servers.config',
        WIREGUARD_SERVERS_PEERS: 'wireguard.servers.peers',
        
        // WireGuard客户端
        WIREGUARD_CLIENTS: 'wireguard.clients',
        WIREGUARD_CLIENTS_GET: 'wireguard.clients.get',
        WIREGUARD_CLIENTS_UPDATE: 'wireguard.clients.update',
        WIREGUARD_CLIENTS_DELETE: 'wireguard.clients.delete',
        WIREGUARD_CLIENTS_CONFIG: 'wireguard.clients.config',
        WIREGUARD_CLIENTS_QR_CODE: 'wireguard.clients.qr_code',
        WIREGUARD_CLIENTS_ENABLE: 'wireguard.clients.enable',
        WIREGUARD_CLIENTS_DISABLE: 'wireguard.clients.disable',
        
        // 系统管理
        SYSTEM_INFO: 'system.info',
        SYSTEM_STATUS: 'system.status',
        SYSTEM_HEALTH: 'system.health',
        SYSTEM_METRICS: 'system.metrics',
        SYSTEM_CONFIG: 'system.config',
        SYSTEM_LOGS: 'system.logs',
        SYSTEM_BACKUP: 'system.backup',
        SYSTEM_RESTORE: 'system.restore',
        
        // 监控
        MONITORING_DASHBOARD: 'monitoring.dashboard',
        MONITORING_ALERTS: 'monitoring.alerts',
        MONITORING_ALERTS_GET: 'monitoring.alerts.get',
        MONITORING_ALERTS_UPDATE: 'monitoring.alerts.update',
        MONITORING_ALERTS_DELETE: 'monitoring.alerts.delete',
        MONITORING_ALERTS_ACKNOWLEDGE: 'monitoring.alerts.acknowledge',
        MONITORING_METRICS: 'monitoring.metrics',
        MONITORING_METRICS_GET: 'monitoring.metrics.get',
        
        // 日志
        LOGS: 'logs',
        LOGS_GET: 'logs.get',
        LOGS_SEARCH: 'logs.search',
        LOGS_EXPORT: 'logs.export',
        LOGS_CLEANUP: 'logs.cleanup',
    };
    
    // 导出便捷函数
    global.getAuthUrl = (pathName, params = {}) => apiPathBuilder.buildUrl(`auth.${pathName}`, params);
    global.getUsersUrl = (pathName, params = {}) => apiPathBuilder.buildUrl(`users.${pathName}`, params);
    global.getWireguardServersUrl = (pathName, params = {}) => apiPathBuilder.buildUrl(`wireguard.servers.${pathName}`, params);
    global.getWireguardClientsUrl = (pathName, params = {}) => apiPathBuilder.buildUrl(`wireguard.clients.${pathName}`, params);
    global.getSystemUrl = (pathName, params = {}) => apiPathBuilder.buildUrl(`system.${pathName}`, params);
    global.getMonitoringUrl = (pathName, params = {}) => apiPathBuilder.buildUrl(`monitoring.${pathName}`, params);
    global.getLogsUrl = (pathName, params = {}) => apiPathBuilder.buildUrl(`logs.${pathName}`, params);
    
    // WebSocket URL生成函数
    global.getWebSocketUrl = (action) => {
        if (typeof window === 'undefined') return '';
        
        const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsHost = window.location.host;
        const wsPath = {
            NOTIFICATIONS: '/ws/notifications',
            LOGS: '/ws/logs',
            METRICS: '/ws/metrics',
        }[action] || '';
        
        return `${wsProtocol}//${wsHost}${wsPath}`;
    };
    
})(typeof window !== 'undefined' ? window : this);
