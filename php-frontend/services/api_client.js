/**
 * 统一的API客户端
 * 提供统一的请求处理、错误处理和认证
 */

import axios from 'axios';
import {
  API_BASE_URL,
  API_TIMEOUT,
  getAuthUrl,
  getUsersUrl,
  getRolesUrl,
  getPermissionsUrl,
  getWireguardServersUrl,
  getWireguardClientsUrl,
  getBgpSessionsUrl,
  getBgpRoutesUrl,
  getIpv6PoolsUrl,
  getIpv6AddressesUrl,
  getSystemUrl,
  getMonitoringUrl,
  getLogsUrl,
  getNetworkUrl,
  getAuditUrl,
  getUploadUrl,
  getWebSocketUrl
} from '../config/api_endpoints';

// 创建axios实例
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: API_TIMEOUT,
  headers: {
    'Content-Type': 'application/json',
  },
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
          const response = await axios.post(getAuthUrl('refresh'), {
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
  // 通用请求方法
  async request(method, url, data = null, config = {}) {
    try {
      const response = await apiClient({
        method,
        url,
        data,
        ...config,
      });
      return response.data;
    } catch (error) {
      this.handleError(error);
      throw error;
    }
  }
  
  // GET请求
  async get(url, config = {}) {
    return this.request('get', url, null, config);
  }
  
  // POST请求
  async post(url, data = null, config = {}) {
    return this.request('post', url, data, config);
  }
  
  // PUT请求
  async put(url, data = null, config = {}) {
    return this.request('put', url, data, config);
  }
  
  // DELETE请求
  async delete(url, config = {}) {
    return this.request('delete', url, null, config);
  }
  
  // PATCH请求
  async patch(url, data = null, config = {}) {
    return this.request('patch', url, data, config);
  }
  
  // 文件上传
  async upload(url, file, onUploadProgress = null) {
    const formData = new FormData();
    formData.append('file', file);
    
    return this.request('post', url, formData, {
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
    return this.post(getAuthUrl('login'), credentials);
  }
  
  async logout() {
    return this.post(getAuthUrl('logout'));
  }
  
  async refreshToken(refreshToken) {
    return this.post(getAuthUrl('refresh'), { refresh_token: refreshToken });
  }
  
  async register(userData) {
    return this.post(getAuthUrl('register'), userData);
  }
  
  async verifyEmail(token) {
    return this.post(getAuthUrl('verify-email'), { token });
  }
  
  async resetPassword(email) {
    return this.post(getAuthUrl('reset-password'), { email });
  }
  
  async changePassword(passwordData) {
    return this.post(getAuthUrl('change-password'), passwordData);
  }
  
  async getCurrentUser() {
    return this.get(getAuthUrl('me'));
  }
  
  // 用户管理API
  async getUsers(params = {}) {
    return this.get(getUsersUrl('LIST'), { params });
  }
  
  async getUser(userId) {
    return this.get(getUsersUrl('GET', { user_id: userId }));
  }
  
  async createUser(userData) {
    return this.post(getUsersUrl('CREATE'), userData);
  }
  
  async updateUser(userId, userData) {
    return this.put(getUsersUrl('UPDATE', { user_id: userId }), userData);
  }
  
  async deleteUser(userId) {
    return this.delete(getUsersUrl('DELETE', { user_id: userId }));
  }
  
  async lockUser(userId) {
    return this.post(getUsersUrl('LOCK', { user_id: userId }));
  }
  
  async unlockUser(userId) {
    return this.post(getUsersUrl('UNLOCK', { user_id: userId }));
  }
  
  async updateUserProfile(profileData) {
    return this.put(getUsersUrl('PROFILE'), profileData);
  }
  
  async uploadAvatar(file) {
    return this.upload(getUsersUrl('AVATAR'), file);
  }
  
  // 角色管理API
  async getRoles(params = {}) {
    return this.get(getRolesUrl('LIST'), { params });
  }
  
  async getRole(roleId) {
    return this.get(getRolesUrl('GET', { role_id: roleId }));
  }
  
  async createRole(roleData) {
    return this.post(getRolesUrl('CREATE'), roleData);
  }
  
  async updateRole(roleId, roleData) {
    return this.put(getRolesUrl('UPDATE', { role_id: roleId }), roleData);
  }
  
  async deleteRole(roleId) {
    return this.delete(getRolesUrl('DELETE', { role_id: roleId }));
  }
  
  async getRolePermissions(roleId) {
    return this.get(getRolesUrl('PERMISSIONS', { role_id: roleId }));
  }
  
  // 权限管理API
  async getPermissions(params = {}) {
    return this.get(getPermissionsUrl('LIST'), { params });
  }
  
  async getPermission(permissionId) {
    return this.get(getPermissionsUrl('GET', { permission_id: permissionId }));
  }
  
  async createPermission(permissionData) {
    return this.post(getPermissionsUrl('CREATE'), permissionData);
  }
  
  async updatePermission(permissionId, permissionData) {
    return this.put(getPermissionsUrl('UPDATE', { permission_id: permissionId }), permissionData);
  }
  
  async deletePermission(permissionId) {
    return this.delete(getPermissionsUrl('DELETE', { permission_id: permissionId }));
  }
  
  // WireGuard服务器API
  async getWireguardServers(params = {}) {
    return this.get(getWireguardServersUrl('LIST'), { params });
  }
  
  async getWireguardServer(serverId) {
    return this.get(getWireguardServersUrl('GET', { server_id: serverId }));
  }
  
  async createWireguardServer(serverData) {
    return this.post(getWireguardServersUrl('CREATE'), serverData);
  }
  
  async updateWireguardServer(serverId, serverData) {
    return this.put(getWireguardServersUrl('UPDATE', { server_id: serverId }), serverData);
  }
  
  async deleteWireguardServer(serverId) {
    return this.delete(getWireguardServersUrl('DELETE', { server_id: serverId }));
  }
  
  async getWireguardServerStatus(serverId) {
    return this.get(getWireguardServersUrl('STATUS', { server_id: serverId }));
  }
  
  async startWireguardServer(serverId) {
    return this.post(getWireguardServersUrl('START', { server_id: serverId }));
  }
  
  async stopWireguardServer(serverId) {
    return this.post(getWireguardServersUrl('STOP', { server_id: serverId }));
  }
  
  async restartWireguardServer(serverId) {
    return this.post(getWireguardServersUrl('RESTART', { server_id: serverId }));
  }
  
  async getWireguardServerConfig(serverId) {
    return this.get(getWireguardServersUrl('CONFIG', { server_id: serverId }));
  }
  
  async getWireguardServerPeers(serverId) {
    return this.get(getWireguardServersUrl('PEERS', { server_id: serverId }));
  }
  
  // WireGuard客户端API
  async getWireguardClients(params = {}) {
    return this.get(getWireguardClientsUrl('LIST'), { params });
  }
  
  async getWireguardClient(clientId) {
    return this.get(getWireguardClientsUrl('GET', { client_id: clientId }));
  }
  
  async createWireguardClient(clientData) {
    return this.post(getWireguardClientsUrl('CREATE'), clientData);
  }
  
  async updateWireguardClient(clientId, clientData) {
    return this.put(getWireguardClientsUrl('UPDATE', { client_id: clientId }), clientData);
  }
  
  async deleteWireguardClient(clientId) {
    return this.delete(getWireguardClientsUrl('DELETE', { client_id: clientId }));
  }
  
  async getWireguardClientConfig(clientId) {
    return this.get(getWireguardClientsUrl('CONFIG', { client_id: clientId }));
  }
  
  async getWireguardClientQrCode(clientId) {
    return this.get(getWireguardClientsUrl('QR_CODE', { client_id: clientId }));
  }
  
  async enableWireguardClient(clientId) {
    return this.post(getWireguardClientsUrl('ENABLE', { client_id: clientId }));
  }
  
  async disableWireguardClient(clientId) {
    return this.post(getWireguardClientsUrl('DISABLE', { client_id: clientId }));
  }
  
  // BGP会话API
  async getBgpSessions(params = {}) {
    return this.get(getBgpSessionsUrl('LIST'), { params });
  }
  
  async getBgpSession(sessionId) {
    return this.get(getBgpSessionsUrl('GET', { session_id: sessionId }));
  }
  
  async createBgpSession(sessionData) {
    return this.post(getBgpSessionsUrl('CREATE'), sessionData);
  }
  
  async updateBgpSession(sessionId, sessionData) {
    return this.put(getBgpSessionsUrl('UPDATE', { session_id: sessionId }), sessionData);
  }
  
  async deleteBgpSession(sessionId) {
    return this.delete(getBgpSessionsUrl('DELETE', { session_id: sessionId }));
  }
  
  async getBgpSessionStatus(sessionId) {
    return this.get(getBgpSessionsUrl('STATUS', { session_id: sessionId }));
  }
  
  async startBgpSession(sessionId) {
    return this.post(getBgpSessionsUrl('START', { session_id: sessionId }));
  }
  
  async stopBgpSession(sessionId) {
    return this.post(getBgpSessionsUrl('STOP', { session_id: sessionId }));
  }
  
  async getBgpSessionRoutes(sessionId) {
    return this.get(getBgpSessionsUrl('ROUTES', { session_id: sessionId }));
  }
  
  // BGP路由API
  async getBgpRoutes(params = {}) {
    return this.get(getBgpRoutesUrl('LIST'), { params });
  }
  
  async getBgpRoute(routeId) {
    return this.get(getBgpRoutesUrl('GET', { route_id: routeId }));
  }
  
  async createBgpRoute(routeData) {
    return this.post(getBgpRoutesUrl('CREATE'), routeData);
  }
  
  async updateBgpRoute(routeId, routeData) {
    return this.put(getBgpRoutesUrl('UPDATE', { route_id: routeId }), routeData);
  }
  
  async deleteBgpRoute(routeId) {
    return this.delete(getBgpRoutesUrl('DELETE', { route_id: routeId }));
  }
  
  // IPv6地址池API
  async getIpv6Pools(params = {}) {
    return this.get(getIpv6PoolsUrl('LIST'), { params });
  }
  
  async getIpv6Pool(poolId) {
    return this.get(getIpv6PoolsUrl('GET', { pool_id: poolId }));
  }
  
  async createIpv6Pool(poolData) {
    return this.post(getIpv6PoolsUrl('CREATE'), poolData);
  }
  
  async updateIpv6Pool(poolId, poolData) {
    return this.put(getIpv6PoolsUrl('UPDATE', { pool_id: poolId }), poolData);
  }
  
  async deleteIpv6Pool(poolId) {
    return this.delete(getIpv6PoolsUrl('DELETE', { pool_id: poolId }));
  }
  
  async allocateIpv6Address(poolId) {
    return this.post(getIpv6PoolsUrl('ALLOCATE', { pool_id: poolId }));
  }
  
  async releaseIpv6Address(poolId, addressId) {
    return this.post(getIpv6PoolsUrl('RELEASE', { pool_id: poolId }), { address_id: addressId });
  }
  
  // IPv6地址API
  async getIpv6Addresses(params = {}) {
    return this.get(getIpv6AddressesUrl('LIST'), { params });
  }
  
  async getIpv6Address(addressId) {
    return this.get(getIpv6AddressesUrl('GET', { address_id: addressId }));
  }
  
  async createIpv6Address(addressData) {
    return this.post(getIpv6AddressesUrl('CREATE'), addressData);
  }
  
  async updateIpv6Address(addressId, addressData) {
    return this.put(getIpv6AddressesUrl('UPDATE', { address_id: addressId }), addressData);
  }
  
  async deleteIpv6Address(addressId) {
    return this.delete(getIpv6AddressesUrl('DELETE', { address_id: addressId }));
  }
  
  // 系统管理API
  async getSystemInfo() {
    return this.get(getSystemUrl('INFO'));
  }
  
  async getSystemStatus() {
    return this.get(getSystemUrl('STATUS'));
  }
  
  async getSystemHealth() {
    return this.get(getSystemUrl('HEALTH'));
  }
  
  async getSystemMetrics() {
    return this.get(getSystemUrl('METRICS'));
  }
  
  async getSystemConfig() {
    return this.get(getSystemUrl('CONFIG'));
  }
  
  async updateSystemConfig(configData) {
    return this.put(getSystemUrl('CONFIG'), configData);
  }
  
  async getSystemLogs(params = {}) {
    return this.get(getSystemUrl('LOGS'), { params });
  }
  
  async createSystemBackup() {
    return this.post(getSystemUrl('BACKUP'));
  }
  
  async restoreSystemBackup(backupData) {
    return this.post(getSystemUrl('RESTORE'), backupData);
  }
  
  // 监控API
  async getMonitoringDashboard() {
    return this.get(getMonitoringUrl('DASHBOARD'));
  }
  
  async getMonitoringAlerts(params = {}) {
    return this.get(getMonitoringUrl('ALERTS', 'LIST'), { params });
  }
  
  async getMonitoringAlert(alertId) {
    return this.get(getMonitoringUrl('ALERTS', 'GET', { alert_id: alertId }));
  }
  
  async createMonitoringAlert(alertData) {
    return this.post(getMonitoringUrl('ALERTS', 'CREATE'), alertData);
  }
  
  async updateMonitoringAlert(alertId, alertData) {
    return this.put(getMonitoringUrl('ALERTS', 'UPDATE', { alert_id: alertId }), alertData);
  }
  
  async deleteMonitoringAlert(alertId) {
    return this.delete(getMonitoringUrl('ALERTS', 'DELETE', { alert_id: alertId }));
  }
  
  async acknowledgeMonitoringAlert(alertId) {
    return this.post(getMonitoringUrl('ALERTS', 'ACKNOWLEDGE', { alert_id: alertId }));
  }
  
  async getMonitoringMetrics(params = {}) {
    return this.get(getMonitoringUrl('METRICS', 'LIST'), { params });
  }
  
  async getMonitoringMetric(metricId) {
    return this.get(getMonitoringUrl('METRICS', 'GET', { metric_id: metricId }));
  }
  
  // 日志API
  async getLogs(params = {}) {
    return this.get(getLogsUrl('LIST'), { params });
  }
  
  async getLog(logId) {
    return this.get(getLogsUrl('GET', { log_id: logId }));
  }
  
  async searchLogs(searchParams) {
    return this.post(getLogsUrl('SEARCH'), searchParams);
  }
  
  async exportLogs(exportParams) {
    return this.post(getLogsUrl('EXPORT'), exportParams);
  }
  
  async cleanupLogs(cleanupParams) {
    return this.post(getLogsUrl('CLEANUP'), cleanupParams);
  }
  
  // 网络工具API
  async ping(target) {
    return this.post(getNetworkUrl('PING'), { target });
  }
  
  async traceroute(target) {
    return this.post(getNetworkUrl('TRACEROUTE'), { target });
  }
  
  async nslookup(domain) {
    return this.post(getNetworkUrl('NSLOOKUP'), { domain });
  }
  
  async whois(domain) {
    return this.post(getNetworkUrl('WHOIS'), { domain });
  }
  
  // 审计日志API
  async getAuditLogs(params = {}) {
    return this.get(getAuditUrl('LIST'), { params });
  }
  
  async getAuditLog(auditId) {
    return this.get(getAuditUrl('GET', { audit_id: auditId }));
  }
  
  async searchAuditLogs(searchParams) {
    return this.post(getAuditUrl('SEARCH'), searchParams);
  }
  
  async exportAuditLogs(exportParams) {
    return this.post(getAuditUrl('EXPORT'), exportParams);
  }
  
  // 文件上传API
  async uploadFile(file) {
    return this.upload(getUploadUrl('FILE'), file);
  }
  
  async uploadImage(file) {
    return this.upload(getUploadUrl('IMAGE'), file);
  }
  
  async uploadAvatar(file) {
    return this.upload(getUploadUrl('AVATAR'), file);
  }
}

// 创建API客户端实例
const apiClientInstance = new ApiClient();

// 导出API客户端实例
export default apiClientInstance;

// 导出API客户端类
export { ApiClient };
