/**
 * 统一的API客户端 - ESM版本
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
          
          if (response.data.success) {
            const { access_token, refresh_token } = response.data.data;
            localStorage.setItem('access_token', access_token);
            if (refresh_token) {
              localStorage.setItem('refresh_token', refresh_token);
            }
            
            // 重试原始请求
            originalRequest.headers.Authorization = `Bearer ${access_token}`;
            return apiClient(originalRequest);
          }
        }
      } catch (refreshError) {
        // 刷新失败，清除token并重定向到登录页
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }
    
    return Promise.reject(error);
  }
);

// API客户端类
export class ApiClient {
  constructor(baseUrl = null) {
    this.apiPathBuilder = baseUrl ? new ApiPathBuilder(baseUrl) : apiPathBuilder;
    this.client = apiClient;
  }

  // 通用请求方法
  async request(method, pathName, data = null, params = {}) {
    try {
      // 验证路径
      const validation = this.apiPathBuilder.validatePath(pathName, params, method);
      if (!validation.valid) {
        throw new Error(validation.error);
      }

      // 构建URL
      const url = this.apiPathBuilder.buildUrl(pathName, params);
      
      const config = {
        method,
        url,
        ...(data && { data }),
        ...(params && Object.keys(params).length > 0 && { params })
      };

      const response = await this.client(config);
      return response.data;
    } catch (error) {
      console.error(`API请求失败 [${method} ${pathName}]:`, error);
      throw error;
    }
  }

  // GET请求
  async get(pathName, params = {}) {
    return this.request('GET', pathName, null, params);
  }

  // POST请求
  async post(pathName, data = null, params = {}) {
    return this.request('POST', pathName, data, params);
  }

  // PUT请求
  async put(pathName, data = null, params = {}) {
    return this.request('PUT', pathName, data, params);
  }

  // DELETE请求
  async delete(pathName, params = {}) {
    return this.request('DELETE', pathName, null, params);
  }

  // 认证相关方法
  async login(credentials) {
    return this.post('auth.login', credentials);
  }

  async logout() {
    return this.post('auth.logout');
  }

  async refreshToken(refreshToken) {
    return this.post('auth.refresh', { refresh_token: refreshToken });
  }

  async getCurrentUser() {
    return this.get('auth.me');
  }

  // 用户管理方法
  async getUsers() {
    return this.get('users.list');
  }

  async getUser(userId) {
    return this.get('users.get', { id: userId });
  }

  async createUser(userData) {
    return this.post('users.create', userData);
  }

  async updateUser(userId, userData) {
    return this.put('users.update', userData, { id: userId });
  }

  async deleteUser(userId) {
    return this.delete('users.delete', { id: userId });
  }

  // WireGuard管理方法
  async getWireGuardConfig() {
    return this.get('wireguard.config');
  }

  async updateWireGuardConfig(config) {
    return this.post('wireguard.config', config);
  }

  async getWireGuardPeers() {
    return this.get('wireguard.peers');
  }

  async createWireGuardPeer(peerData) {
    return this.post('wireguard.peers', peerData);
  }

  async getWireGuardPeer(peerId) {
    return this.get('wireguard.peer', { id: peerId });
  }

  async updateWireGuardPeer(peerId, peerData) {
    return this.put('wireguard.peer', peerData, { id: peerId });
  }

  async deleteWireGuardPeer(peerId) {
    return this.delete('wireguard.peer', { id: peerId });
  }

  async getWireGuardStatus() {
    return this.get('wireguard.status');
  }

  async startWireGuard() {
    return this.post('wireguard.start');
  }

  async stopWireGuard() {
    return this.post('wireguard.stop');
  }

  async restartWireGuard() {
    return this.post('wireguard.restart');
  }

  // IPv6管理方法
  async getIPv6Config() {
    return this.get('ipv6.config');
  }

  async updateIPv6Config(config) {
    return this.post('ipv6.config', config);
  }

  async getIPv6Addresses() {
    return this.get('ipv6.addresses');
  }

  async createIPv6Address(addressData) {
    return this.post('ipv6.addresses', addressData);
  }

  async getIPv6Routes() {
    return this.get('ipv6.routes');
  }

  async createIPv6Route(routeData) {
    return this.post('ipv6.routes', routeData);
  }

  async getIPv6Status() {
    return this.get('ipv6.status');
  }

  // BGP管理方法
  async getBGPConfig() {
    return this.get('bgp.config');
  }

  async updateBGPConfig(config) {
    return this.post('bgp.config', config);
  }

  async getBGPNeighbors() {
    return this.get('bgp.neighbors');
  }

  async createBGPNeighbor(neighborData) {
    return this.post('bgp.neighbors', neighborData);
  }

  async getBGPStatus() {
    return this.get('bgp.status');
  }

  // 监控方法
  async getDashboard() {
    return this.get('monitoring.dashboard');
  }

  async getMetrics() {
    return this.get('monitoring.metrics');
  }

  async getHealth() {
    return this.get('monitoring.health');
  }

  async getLogs() {
    return this.get('monitoring.logs');
  }

  // 系统管理方法
  async getSystemInfo() {
    return this.get('system.info');
  }

  async getSystemConfig() {
    return this.get('system.config');
  }

  async updateSystemConfig(config) {
    return this.post('system.config', config);
  }

  async createBackup() {
    return this.post('system.backup');
  }

  async restoreBackup(backupData) {
    return this.post('system.restore', backupData);
  }

  // 工具方法
  setAuthToken(token) {
    localStorage.setItem('access_token', token);
  }

  getAuthToken() {
    return localStorage.getItem('access_token');
  }

  clearAuth() {
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
  }

  isAuthenticated() {
    return !!this.getAuthToken();
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
export const apiClient = new ApiClient();

// 导出默认实例
export default apiClient;
