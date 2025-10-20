/**
 * API端点配置 - ESM版本
 * 
 * 本文件定义了前端应用中使用的所有API端点配置。
 * 使用ESM格式，支持现代浏览器和打包器。
 */

// API基础配置
export const API_CONFIG = {
    // 基础URL，在生产环境中应该从环境变量获取
    BASE_URL: typeof window !== 'undefined' && window.location.hostname === 'localhost'
        ? 'http://localhost:8000/api'
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
export class ApiPathBuilder {
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
        this.registerPath('users.list', '/users', ['GET'], '获取用户列表');
        this.registerPath('users.create', '/users', ['POST'], '创建用户');
        this.registerPath('users.get', '/users/{id}', ['GET'], '获取用户详情');
        this.registerPath('users.update', '/users/{id}', ['PUT'], '更新用户');
        this.registerPath('users.delete', '/users/{id}', ['DELETE'], '删除用户');
        
        // WireGuard管理路径
        this.registerPath('wireguard.config', '/wireguard/config', ['GET', 'POST'], 'WireGuard配置');
        this.registerPath('wireguard.peers', '/wireguard/peers', ['GET', 'POST'], '对等节点管理');
        this.registerPath('wireguard.peer', '/wireguard/peers/{id}', ['GET', 'PUT', 'DELETE'], '对等节点详情');
        this.registerPath('wireguard.status', '/wireguard/status', ['GET'], 'WireGuard状态');
        this.registerPath('wireguard.start', '/wireguard/start', ['POST'], '启动WireGuard');
        this.registerPath('wireguard.stop', '/wireguard/stop', ['POST'], '停止WireGuard');
        this.registerPath('wireguard.restart', '/wireguard/restart', ['POST'], '重启WireGuard');
        
        // IPv6管理路径
        this.registerPath('ipv6.config', '/ipv6/config', ['GET', 'POST'], 'IPv6配置');
        this.registerPath('ipv6.addresses', '/ipv6/addresses', ['GET', 'POST'], 'IPv6地址管理');
        this.registerPath('ipv6.routes', '/ipv6/routes', ['GET', 'POST'], 'IPv6路由管理');
        this.registerPath('ipv6.status', '/ipv6/status', ['GET'], 'IPv6状态');
        
        // BGP管理路径
        this.registerPath('bgp.config', '/bgp/config', ['GET', 'POST'], 'BGP配置');
        this.registerPath('bgp.neighbors', '/bgp/neighbors', ['GET', 'POST'], 'BGP邻居管理');
        this.registerPath('bgp.status', '/bgp/status', ['GET'], 'BGP状态');
        
        // 系统监控路径
        this.registerPath('monitoring.dashboard', '/monitoring/dashboard', ['GET'], '监控仪表板');
        this.registerPath('monitoring.metrics', '/monitoring/metrics', ['GET'], '系统指标');
        this.registerPath('monitoring.health', '/monitoring/health', ['GET'], '健康检查');
        this.registerPath('monitoring.logs', '/monitoring/logs', ['GET'], '系统日志');
        
        // 系统管理路径
        this.registerPath('system.info', '/system/info', ['GET'], '系统信息');
        this.registerPath('system.config', '/system/config', ['GET', 'POST'], '系统配置');
        this.registerPath('system.backup', '/system/backup', ['POST'], '系统备份');
        this.registerPath('system.restore', '/system/restore', ['POST'], '系统恢复');
    }

    registerPath(name, path, methods = ['GET'], description = '') {
        this.paths.set(name, {
            path,
            methods,
            description,
            fullPath: this.buildFullPath(path)
        });
    }

    buildFullPath(path) {
        const baseUrl = this.baseUrl.endsWith('/') ? this.baseUrl.slice(0, -1) : this.baseUrl;
        const versionPath = this.version ? `/${this.version}` : '';
        const cleanPath = path.startsWith('/') ? path : `/${path}`;
        return `${baseUrl}${versionPath}${cleanPath}`;
    }

    getPath(name) {
        return this.paths.get(name);
    }

    buildUrl(name, params = {}) {
        const pathInfo = this.paths.get(name);
        if (!pathInfo) {
            throw new Error(`路径 '${name}' 未找到`);
        }

        let url = pathInfo.fullPath;
        
        // 替换路径参数
        Object.keys(params).forEach(key => {
            const placeholder = `{${key}}`;
            if (url.includes(placeholder)) {
                url = url.replace(placeholder, encodeURIComponent(params[key]));
            }
        });

        return url;
    }

    validatePath(name, params = {}, method = 'GET') {
        const pathInfo = this.paths.get(name);
        if (!pathInfo) {
            return { valid: false, error: `路径 '${name}' 未找到` };
        }

        if (!pathInfo.methods.includes(method)) {
            return { valid: false, error: `方法 '${method}' 不被支持，支持的方法: ${pathInfo.methods.join(', ')}` };
        }

        // 检查必需的路径参数
        const pathParams = pathInfo.path.match(/\{(\w+)\}/g);
        if (pathParams) {
            const requiredParams = pathParams.map(p => p.slice(1, -1));
            const missingParams = requiredParams.filter(param => !(param in params));
            if (missingParams.length > 0) {
                return { valid: false, error: `缺少必需的路径参数: ${missingParams.join(', ')}` };
            }
        }

        return { valid: true };
    }

    getAllPaths() {
        return Array.from(this.paths.entries()).map(([name, info]) => ({
            name,
            ...info
        }));
    }

    getPathsByCategory(category) {
        return this.getAllPaths().filter(path => path.name.startsWith(category + '.'));
    }

    // WebSocket连接构建
    buildWebSocketUrl(action = 'general') {
        const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsHost = window.location.host;
        
        const wsPath = {
            GENERAL: '/ws',
            LOGS: '/ws/logs',
            METRICS: '/ws/metrics',
        }[action] || '';
        
        return `${wsProtocol}//${wsHost}${wsPath}`;
    }
}

// 创建默认API路径构建器实例
export const apiPathBuilder = new ApiPathBuilder();

// 创建默认API路径构建器实例的工厂函数
export function getDefaultApiPathBuilder(baseUrl = null) {
    return new ApiPathBuilder(baseUrl);
}