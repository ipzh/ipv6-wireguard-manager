/**
 * 统一的API客户端 - 简化版本
 * 提供统一的请求处理、错误处理和认证
 */

import axios from 'axios';
import { apiPathBuilder, API_CONFIG } from '../config/api_endpoints.js';

// 创建axios实例
const apiClient = axios.create({
  timeout: API_CONFIG.TIMEOUT,
  headers: API_CONFIG.DEFAULT_HEADERS,
  baseURL: API_CONFIG.BASE_URL,
});

// 请求拦截器 - 添加认证token
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 响应拦截器 - 处理认证错误
apiClient.interceptors.response.use(
  (response) => {
    return response;
  },
  async (error) => {
    const originalRequest = error.config;
    
    // 如果是401错误且不是刷新token的请求，尝试刷新token
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      try {
        const refreshToken = localStorage.getItem('refresh_token');
        if (refreshToken) {
          const refreshUrl = apiPathBuilder.buildUrl('auth.refresh');
          
          const response = await axios.post(refreshUrl, {
            refresh_token: refreshToken,
          });
          
          const { access_token } = response.data;
          localStorage.setItem('access_token', access_token);
          
          // 重新发送原始请求
          originalRequest.headers.Authorization = `Bearer ${access_token}`;
          return apiClient(originalRequest);
        }
      } catch (refreshError) {
        // 刷新token失败，清除本地存储并跳转到登录页
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }
    
    return Promise.reject(error);
  }
);

// API方法封装
class ApiClient {
  constructor(baseUrl = '') {
    // 初始化API路径构建器
    this.apiPathBuilder = apiPathBuilder;
    if (baseUrl) {
      this.apiPathBuilder.setApiBaseUrl(baseUrl);
      apiClient.defaults.baseURL = baseUrl;
    }
  }
  
  // 通用请求方法
  async request(pathName, method = 'GET', data = null, params = {}, config = {}) {
    try {
      // 验证路径
      const validation = this.apiPathBuilder.validatePath(pathName, params, method);
      if (!validation.valid) {
        throw new Error(`路径验证失败: ${validation.error}`);
      }
      
      // 构建URL
      const url = this.apiPathBuilder.buildUrl(pathName, params);
      
      // 发送请求
      const response = await apiClient({
        method,
        url,
        data,
        params: Object.keys(params).reduce((acc, key) => {
          // 路径参数不作为查询参数
          if (!url.includes(`{${key}}`)) {
            acc[key] = params[key];
          }
          return acc;
        }, {}),
        ...config,
      });
      
      return response.data;
    } catch (error) {
      this.handleError(error);
      throw error;
    }
  }
  
  // GET请求
  async get(pathName, params = {}, config = {}) {
    return this.request(pathName, 'GET', null, params, config);
  }
  
  // POST请求
  async post(pathName, data = null, params = {}, config = {}) {
    return this.request(pathName, 'POST', data, params, config);
  }
  
  // PUT请求
  async put(pathName, data = null, params = {}, config = {}) {
    return this.request(pathName, 'PUT', data, params, config);
  }
  
  // DELETE请求
  async delete(pathName, params = {}, config = {}) {
    return this.request(pathName, 'DELETE', null, params, config);
  }
  
  // PATCH请求
  async patch(pathName, data = null, params = {}, config = {}) {
    return this.request(pathName, 'PATCH', data, params, config);
  }
  
  // 文件上传
  async upload(pathName, file, params = {}, onUploadProgress = null) {
    const formData = new FormData();
    formData.append('file', file);
    
    return this.request(pathName, 'POST', formData, params, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
      onUploadProgress,
    });
  }
  
  // 错误处理
  handleError(error) {
    if (error.response) {
      // 服务器响应错误
      const { status, data } = error.response;
      
      switch (status) {
        case 400:
          console.error('请求错误:', data.detail || '无效的请求参数');
          break;
        case 401:
          console.error('认证失败:', data.detail || '未授权访问');
          break;
        case 403:
          console.error('权限不足:', data.detail || '没有访问权限');
          break;
        case 404:
          console.error('资源不存在:', data.detail || '请求的资源不存在');
          break;
        case 500:
          console.error('服务器错误:', data.detail || '服务器内部错误');
          break;
        default:
          console.error('未知错误:', data.detail || '发生未知错误');
      }
    } else if (error.request) {
      // 请求发送失败
      console.error('网络错误:', '无法连接到服务器');
    } else {
      // 其他错误
      console.error('请求配置错误:', error.message);
    }
  }
  
  // 认证相关API
  async login(credentials) {
    return this.post('auth.login', credentials);
  }
  
  async logout() {
    return this.post('auth.logout');
  }
  
  async refreshToken(refreshToken) {
    return this.post('auth.refresh', { refresh_token: refreshToken });
  }
  
  async register(userData) {
    return this.post('auth.register', userData);
  }
  
  async verifyEmail(token) {
    return this.post('auth.verify_email', { token });
  }
  
  async resetPassword(email) {
    return this.post('auth.reset_password', { email });
  }
  
  async changePassword(passwordData) {
    return this.post('auth.change_password', passwordData);
  }
  
  async getCurrentUser() {
    return this.get('auth.me');
  }
  
  // 用户管理API
  async getUsers(params = {}) {
    return this.get('users', params);
  }
  
  async getUser(userId) {
    return this.get('users.get', { user_id: userId });
  }
  
  async createUser(userData) {
    return this.post('users', userData);
  }
  
  async updateUser(userId, userData) {
    return this.put('users.update', userData, { user_id: userId });
  }
  
  async deleteUser(userId) {
    return this.delete('users.delete', { user_id: userId });
  }
  
  async lockUser(userId) {
    return this.post('users.lock', {}, { user_id: userId });
  }
  
  async unlockUser(userId) {
    return this.post('users.unlock', {}, { user_id: userId });
  }
  
  async updateUserProfile(profileData) {
    return this.put('users.profile', profileData);
  }
  
  async uploadAvatar(file) {
    return this.upload('users.avatar', file);
  }
  
  // 角色管理API
  async getRoles(params = {}) {
    return this.get('roles', params);
  }
  
  async getRole(roleId) {
    return this.get('roles.get', { role_id: roleId });
  }
  
  async createRole(roleData) {
    return this.post('roles', roleData);
  }
  
  async updateRole(roleId, roleData) {
    return this.put('roles.update', roleData, { role_id: roleId });
  }
  
  async deleteRole(roleId) {
    return this.delete('roles.delete', { role_id: roleId });
  }
  
  async getRolePermissions(roleId) {
    return this.get('roles.permissions', { role_id: roleId });
  }
  
  // 权限管理API
  async getPermissions(params = {}) {
    return this.get('permissions', params);
  }
  
  async getPermission(permissionId) {
    return this.get('permissions.get', { permission_id: permissionId });
  }
  
  async createPermission(permissionData) {
    return this.post('permissions', permissionData);
  }
  
  async updatePermission(permissionId, permissionData) {
    return this.put('permissions.update', permissionData, { permission_id: permissionId });
  }
  
  async deletePermission(permissionId) {
    return this.delete('permissions.delete', { permission_id: permissionId });
  }
  
  // WireGuard服务器API
  async getWireguardServers(params = {}) {
    return this.get('wireguard.servers', params);
  }
  
  async getWireguardServer(serverId) {
    return this.get('wireguard.servers.get', { server_id: serverId });
  }
  
  async createWireguardServer(serverData) {
    return this.post('wireguard.servers', serverData);
  }
  
  async updateWireguardServer(serverId, serverData) {
    return this.put('wireguard.servers.update', serverData, { server_id: serverId });
  }
  
  async deleteWireguardServer(serverId) {
    return this.delete('wireguard.servers.delete', { server_id: serverId });
  }
  
  async getWireguardServerStatus(serverId) {
    return this.get('wireguard.servers.status', { server_id: serverId });
  }
  
  async startWireguardServer(serverId) {
    return this.post('wireguard.servers.start', {}, { server_id: serverId });
  }
  
  async stopWireguardServer(serverId) {
    return this.post('wireguard.servers.stop', {}, { server_id: serverId });
  }
  
  async restartWireguardServer(serverId) {
    return this.post('wireguard.servers.restart', {}, { server_id: serverId });
  }
  
  async getWireguardServerConfig(serverId) {
    return this.get('wireguard.servers.config', { server_id: serverId });
  }
  
  async getWireguardServerPeers(serverId) {
    return this.get('wireguard.servers.peers', { server_id: serverId });
  }
  
  // WireGuard客户端API
  async getWireguardClients(params = {}) {
    return this.get('wireguard.clients', params);
  }
  
  async getWireguardClient(clientId) {
    return this.get('wireguard.clients.get', { client_id: clientId });
  }
  
  async createWireguardClient(clientData) {
    return this.post('wireguard.clients', clientData);
  }
  
  async updateWireguardClient(clientId, clientData) {
    return this.put('wireguard.clients.update', clientData, { client_id: clientId });
  }
  
  async deleteWireguardClient(clientId) {
    return this.delete('wireguard.clients.delete', { client_id: clientId });
  }
  
  async getWireguardClientConfig(clientId) {
    return this.get('wireguard.clients.config', { client_id: clientId });
  }
  
  async getWireguardClientQrCode(clientId) {
    return this.get('wireguard.clients.qr_code', { client_id: clientId });
  }
  
  async enableWireguardClient(clientId) {
    return this.post('wireguard.clients.enable', {}, { client_id: clientId });
  }
  
  async disableWireguardClient(clientId) {
    return this.post('wireguard.clients.disable', {}, { client_id: clientId });
  }
  
  // BGP会话API
  async getBgpSessions(params = {}) {
    return this.get('bgp.sessions', params);
  }
  
  async getBgpSession(sessionId) {
    return this.get('bgp.sessions.get', { session_id: sessionId });
  }
  
  async createBgpSession(sessionData) {
    return this.post('bgp.sessions', sessionData);
  }
  
  async updateBgpSession(sessionId, sessionData) {
    return this.put('bgp.sessions.update', sessionData, { session_id: sessionId });
  }
  
  async deleteBgpSession(sessionId) {
    return this.delete('bgp.sessions.delete', { session_id: sessionId });
  }
  
  async getBgpSessionStatus(sessionId) {
    return this.get('bgp.sessions.status', { session_id: sessionId });
  }
  
  async startBgpSession(sessionId) {
    return this.post('bgp.sessions.start', {}, { session_id: sessionId });
  }
  
  async stopBgpSession(sessionId) {
    return this.post('bgp.sessions.stop', {}, { session_id: sessionId });
  }
  
  async getBgpSessionRoutes(sessionId) {
    return this.get('bgp.sessions.routes', { session_id: sessionId });
  }
  
  // BGP路由API
  async getBgpRoutes(params = {}) {
    return this.get('bgp.routes', params);
  }
  
  async getBgpRoute(routeId) {
    return this.get('bgp.routes.get', { route_id: routeId });
  }
  
  async createBgpRoute(routeData) {
    return this.post('bgp.routes', routeData);
  }
  
  async updateBgpRoute(routeId, routeData) {
    return this.put('bgp.routes.update', routeData, { route_id: routeId });
  }
  
  async deleteBgpRoute(routeId) {
    return this.delete('bgp.routes.delete', { route_id: routeId });
  }
  
  // IPv6地址池API
  async getIpv6Pools(params = {}) {
    return this.get('ipv6.pools', params);
  }
  
  async getIpv6Pool(poolId) {
    return this.get('ipv6.pools.get', { pool_id: poolId });
  }
  
  async createIpv6Pool(poolData) {
    return this.post('ipv6.pools', poolData);
  }
  
  async updateIpv6Pool(poolId, poolData) {
    return this.put('ipv6.pools.update', poolData, { pool_id: poolId });
  }
  
  async deleteIpv6Pool(poolId) {
    return this.delete('ipv6.pools.delete', { pool_id: poolId });
  }
  
  async allocateIpv6Address(poolId) {
    return this.post('ipv6.pools.allocate', {}, { pool_id: poolId });
  }
  
  async releaseIpv6Address(poolId, addressId) {
    return this.post('ipv6.pools.release', { address_id: addressId }, { pool_id: poolId });
  }
  
  // IPv6地址API
  async getIpv6Addresses(params = {}) {
    return this.get('ipv6.addresses', params);
  }
  
  async getIpv6Address(addressId) {
    return this.get('ipv6.addresses.get', { address_id: addressId });
  }
  
  async createIpv6Address(addressData) {
    return this.post('ipv6.addresses', addressData);
  }
  
  async updateIpv6Address(addressId, addressData) {
    return this.put('ipv6.addresses.update', addressData, { address_id: addressId });
  }
  
  async deleteIpv6Address(addressId) {
    return this.delete('ipv6.addresses.delete', { address_id: addressId });
  }
  
  // 系统管理API
  async getSystemInfo() {
    return this.get('system.info');
  }
  
  async getSystemStatus() {
    return this.get('system.status');
  }
  
  async getSystemHealth() {
    return this.get('system.health');
  }
  
  async getSystemMetrics() {
    return this.get('system.metrics');
  }
  
  async getSystemConfig() {
    return this.get('system.config');
  }
  
  async updateSystemConfig(configData) {
    return this.put('system.config', configData);
  }
  
  async getSystemLogs(params = {}) {
    return this.get('system.logs', params);
  }
  
  async createSystemBackup() {
    return this.post('system.backup');
  }
  
  async restoreSystemBackup(backupData) {
    return this.post('system.restore', backupData);
  }
  
  // 监控API
  async getMonitoringDashboard() {
    return this.get('monitoring.dashboard');
  }
  
  async getMonitoringAlerts(params = {}) {
    return this.get('monitoring.alerts', params);
  }
  
  async getMonitoringAlert(alertId) {
    return this.get('monitoring.alerts.get', { alert_id: alertId });
  }
  
  async createMonitoringAlert(alertData) {
    return this.post('monitoring.alerts', alertData);
  }
  
  async updateMonitoringAlert(alertId, alertData) {
    return this.put('monitoring.alerts.update', alertData, { alert_id: alertId });
  }
  
  async deleteMonitoringAlert(alertId) {
    return this.delete('monitoring.alerts.delete', { alert_id: alertId });
  }
  
  async acknowledgeMonitoringAlert(alertId) {
    return this.post('monitoring.alerts.acknowledge', {}, { alert_id: alertId });
  }
  
  async getMonitoringMetrics(params = {}) {
    return this.get('monitoring.metrics', params);
  }
  
  async getMonitoringMetric(metricId) {
    return this.get('monitoring.metrics.get', { metric_id: metricId });
  }
  
  // 日志API
  async getLogs(params = {}) {
    return this.get('logs', params);
  }
  
  async getLog(logId) {
    return this.get('logs.get', { log_id: logId });
  }
  
  async searchLogs(searchParams) {
    return this.post('logs.search', searchParams);
  }
  
  async exportLogs(exportParams) {
    return this.post('logs.export', exportParams);
  }
  
  async cleanupLogs(cleanupParams) {
    return this.post('logs.cleanup', cleanupParams);
  }
  
  // 网络工具API
  async ping(target) {
    return this.post('network.ping', { target });
  }
  
  async traceroute(target) {
    return this.post('network.traceroute', { target });
  }
  
  async nslookup(domain) {
    return this.post('network.nslookup', { domain });
  }
  
  async whois(domain) {
    return this.post('network.whois', { domain });
  }
  
  // 审计日志API
  async getAuditLogs(params = {}) {
    return this.get('audit', params);
  }
  
  async getAuditLog(auditId) {
    return this.get('audit.get', { audit_id: auditId });
  }
  
  async searchAuditLogs(searchParams) {
    return this.post('audit.search', searchParams);
  }
  
  async exportAuditLogs(exportParams) {
    return this.post('audit.export', exportParams);
  }
  
  // 文件上传API
  async uploadFile(file) {
    return this.upload('upload.file', file);
  }
  
  async uploadImage(file) {
    return this.upload('upload.image', file);
  }
  
  async uploadAvatar(file) {
    return this.upload('upload.avatar', file);
  }
  
  // 获取API路径构建器实例
  getApiPathBuilder() {
    return this.apiPathBuilder;
  }
  
  // 构建URL
  buildUrl(pathName, params = {}) {
    return this.apiPathBuilder.buildUrl(pathName, params);
  }
  
  // 验证路径
  validatePath(pathName, params = {}, method = 'GET') {
    return this.apiPathBuilder.validatePath(pathName, params, method);
  }
}

// 创建API客户端实例
const apiClientInstance = new ApiClient();

// 导出API客户端实例
export default apiClientInstance;

// 导出API客户端类
export { ApiClient };
