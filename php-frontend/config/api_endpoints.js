/**
 * API端点配置 - 使用统一API路径构建器
 * 
 * 本文件定义了前端应用中使用的所有API端点配置。
 * 现在使用统一API路径构建器来管理和构建API路径。
 */

// 导入API路径构建器
import { initApiPathBuilder } from '../public/js/ApiPathBuilder.js';

// API基础配置
const API_CONFIG = {
  // 基础URL，在生产环境中应该从环境变量获取
  BASE_URL: process.env.NODE_ENV === 'production' 
    ? '/api' 
    : 'http://localhost:8000/api',
  
  // 请求超时时间（毫秒）
  TIMEOUT: 30000,
  
  // API版本
  VERSION: 'v1',
  
  // 默认请求头
  DEFAULT_HEADERS: {
    'Content-Type': 'application/json',
  },
};

// 初始化API路径构建器
const apiPathBuilder = initApiPathBuilder(API_CONFIG.BASE_URL);

// 导出API配置
export {
  API_CONFIG,
  apiPathBuilder,
};

// 导出API路径构建器函数
export const {
  buildUrl,
  validatePath,
  getApiVersion,
  getApiBaseUrl,
  setApiBaseUrl,
  registerPath,
  getPathConfig,
  getAllPaths,
  clearCache,
} = apiPathBuilder;

// 为了向后兼容，保留一些旧的函数名
export const getApiUrl = buildUrl;
export const getApiVersion = getApiVersion;
export const getApiBaseUrl = getApiBaseUrl;

// 导出常用的路径名称常量
export const PATH_NAMES = {
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
  
  // 角色管理
  ROLES: 'roles',
  ROLES_GET: 'roles.get',
  ROLES_UPDATE: 'roles.update',
  ROLES_DELETE: 'roles.delete',
  ROLES_PERMISSIONS: 'roles.permissions',
  
  // 权限管理
  PERMISSIONS: 'permissions',
  PERMISSIONS_GET: 'permissions.get',
  PERMISSIONS_UPDATE: 'permissions.update',
  PERMISSIONS_DELETE: 'permissions.delete',
  
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
  
  // BGP会话
  BGP_SESSIONS: 'bgp.sessions',
  BGP_SESSIONS_GET: 'bgp.sessions.get',
  BGP_SESSIONS_UPDATE: 'bgp.sessions.update',
  BGP_SESSIONS_DELETE: 'bgp.sessions.delete',
  BGP_SESSIONS_STATUS: 'bgp.sessions.status',
  BGP_SESSIONS_START: 'bgp.sessions.start',
  BGP_SESSIONS_STOP: 'bgp.sessions.stop',
  BGP_SESSIONS_ROUTES: 'bgp.sessions.routes',
  
  // BGP路由
  BGP_ROUTES: 'bgp.routes',
  BGP_ROUTES_GET: 'bgp.routes.get',
  BGP_ROUTES_UPDATE: 'bgp.routes.update',
  BGP_ROUTES_DELETE: 'bgp.routes.delete',
  
  // IPv6地址池
  IPV6_POOLS: 'ipv6.pools',
  IPV6_POOLS_GET: 'ipv6.pools.get',
  IPV6_POOLS_UPDATE: 'ipv6.pools.update',
  IPV6_POOLS_DELETE: 'ipv6.pools.delete',
  IPV6_POOLS_ALLOCATE: 'ipv6.pools.allocate',
  IPV6_POOLS_RELEASE: 'ipv6.pools.release',
  
  // IPv6地址
  IPV6_ADDRESSES: 'ipv6.addresses',
  IPV6_ADDRESSES_GET: 'ipv6.addresses.get',
  IPV6_ADDRESSES_UPDATE: 'ipv6.addresses.update',
  IPV6_ADDRESSES_DELETE: 'ipv6.addresses.delete',
  
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
  
  // 网络工具
  NETWORK_PING: 'network.ping',
  NETWORK_TRACEROUTE: 'network.traceroute',
  NETWORK_NSLOOKUP: 'network.nslookup',
  NETWORK_WHOIS: 'network.whois',
  
  // 审计日志
  AUDIT: 'audit',
  AUDIT_GET: 'audit.get',
  AUDIT_SEARCH: 'audit.search',
  AUDIT_EXPORT: 'audit.export',
  
  // 文件上传
  UPLOAD_FILE: 'upload.file',
  UPLOAD_IMAGE: 'upload.image',
  UPLOAD_AVATAR: 'upload.avatar',
};

// 创建便捷的URL生成函数
export const createUrlGenerator = (pathName) => (params = {}) => buildUrl(pathName, params);

// 导出便捷的URL生成函数
export const getAuthUrl = {
  login: createUrlGenerator(PATH_NAMES.AUTH_LOGIN),
  logout: createUrlGenerator(PATH_NAMES.AUTH_LOGOUT),
  refresh: createUrlGenerator(PATH_NAMES.AUTH_REFRESH),
  register: createUrlGenerator(PATH_NAMES.AUTH_REGISTER),
  verifyEmail: createUrlGenerator(PATH_NAMES.AUTH_VERIFY_EMAIL),
  resetPassword: createUrlGenerator(PATH_NAMES.AUTH_RESET_PASSWORD),
  changePassword: createUrlGenerator(PATH_NAMES.AUTH_CHANGE_PASSWORD),
  me: createUrlGenerator(PATH_NAMES.AUTH_ME),
};

export const getUsersUrl = {
  LIST: createUrlGenerator(PATH_NAMES.USERS),
  GET: createUrlGenerator(PATH_NAMES.USERS_GET),
  UPDATE: createUrlGenerator(PATH_NAMES.USERS_UPDATE),
  DELETE: createUrlGenerator(PATH_NAMES.USERS_DELETE),
  LOCK: createUrlGenerator(PATH_NAMES.USERS_LOCK),
  UNLOCK: createUrlGenerator(PATH_NAMES.USERS_UNLOCK),
  PROFILE: createUrlGenerator(PATH_NAMES.USERS_PROFILE),
  AVATAR: createUrlGenerator(PATH_NAMES.USERS_AVATAR),
};

export const getRolesUrl = {
  LIST: createUrlGenerator(PATH_NAMES.ROLES),
  GET: createUrlGenerator(PATH_NAMES.ROLES_GET),
  UPDATE: createUrlGenerator(PATH_NAMES.ROLES_UPDATE),
  DELETE: createUrlGenerator(PATH_NAMES.ROLES_DELETE),
  PERMISSIONS: createUrlGenerator(PATH_NAMES.ROLES_PERMISSIONS),
};

export const getPermissionsUrl = {
  LIST: createUrlGenerator(PATH_NAMES.PERMISSIONS),
  GET: createUrlGenerator(PATH_NAMES.PERMISSIONS_GET),
  UPDATE: createUrlGenerator(PATH_NAMES.PERMISSIONS_UPDATE),
  DELETE: createUrlGenerator(PATH_NAMES.PERMISSIONS_DELETE),
};

export const getWireguardServersUrl = {
  LIST: createUrlGenerator(PATH_NAMES.WIREGUARD_SERVERS),
  GET: createUrlGenerator(PATH_NAMES.WIREGUARD_SERVERS_GET),
  UPDATE: createUrlGenerator(PATH_NAMES.WIREGUARD_SERVERS_UPDATE),
  DELETE: createUrlGenerator(PATH_NAMES.WIREGUARD_SERVERS_DELETE),
  STATUS: createUrlGenerator(PATH_NAMES.WIREGUARD_SERVERS_STATUS),
  START: createUrlGenerator(PATH_NAMES.WIREGUARD_SERVERS_START),
  STOP: createUrlGenerator(PATH_NAMES.WIREGUARD_SERVERS_STOP),
  RESTART: createUrlGenerator(PATH_NAMES.WIREGUARD_SERVERS_RESTART),
  CONFIG: createUrlGenerator(PATH_NAMES.WIREGUARD_SERVERS_CONFIG),
  PEERS: createUrlGenerator(PATH_NAMES.WIREGUARD_SERVERS_PEERS),
};

export const getWireguardClientsUrl = {
  LIST: createUrlGenerator(PATH_NAMES.WIREGUARD_CLIENTS),
  GET: createUrlGenerator(PATH_NAMES.WIREGUARD_CLIENTS_GET),
  UPDATE: createUrlGenerator(PATH_NAMES.WIREGUARD_CLIENTS_UPDATE),
  DELETE: createUrlGenerator(PATH_NAMES.WIREGUARD_CLIENTS_DELETE),
  CONFIG: createUrlGenerator(PATH_NAMES.WIREGUARD_CLIENTS_CONFIG),
  QR_CODE: createUrlGenerator(PATH_NAMES.WIREGUARD_CLIENTS_QR_CODE),
  ENABLE: createUrlGenerator(PATH_NAMES.WIREGUARD_CLIENTS_ENABLE),
  DISABLE: createUrlGenerator(PATH_NAMES.WIREGUARD_CLIENTS_DISABLE),
};

export const getBgpSessionsUrl = {
  LIST: createUrlGenerator(PATH_NAMES.BGP_SESSIONS),
  GET: createUrlGenerator(PATH_NAMES.BGP_SESSIONS_GET),
  UPDATE: createUrlGenerator(PATH_NAMES.BGP_SESSIONS_UPDATE),
  DELETE: createUrlGenerator(PATH_NAMES.BGP_SESSIONS_DELETE),
  STATUS: createUrlGenerator(PATH_NAMES.BGP_SESSIONS_STATUS),
  START: createUrlGenerator(PATH_NAMES.BGP_SESSIONS_START),
  STOP: createUrlGenerator(PATH_NAMES.BGP_SESSIONS_STOP),
  ROUTES: createUrlGenerator(PATH_NAMES.BGP_SESSIONS_ROUTES),
};

export const getBgpRoutesUrl = {
  LIST: createUrlGenerator(PATH_NAMES.BGP_ROUTES),
  GET: createUrlGenerator(PATH_NAMES.BGP_ROUTES_GET),
  UPDATE: createUrlGenerator(PATH_NAMES.BGP_ROUTES_UPDATE),
  DELETE: createUrlGenerator(PATH_NAMES.BGP_ROUTES_DELETE),
};

export const getIpv6PoolsUrl = {
  LIST: createUrlGenerator(PATH_NAMES.IPV6_POOLS),
  GET: createUrlGenerator(PATH_NAMES.IPV6_POOLS_GET),
  UPDATE: createUrlGenerator(PATH_NAMES.IPV6_POOLS_UPDATE),
  DELETE: createUrlGenerator(PATH_NAMES.IPV6_POOLS_DELETE),
  ALLOCATE: createUrlGenerator(PATH_NAMES.IPV6_POOLS_ALLOCATE),
  RELEASE: createUrlGenerator(PATH_NAMES.IPV6_POOLS_RELEASE),
};

export const getIpv6AddressesUrl = {
  LIST: createUrlGenerator(PATH_NAMES.IPV6_ADDRESSES),
  GET: createUrlGenerator(PATH_NAMES.IPV6_ADDRESSES_GET),
  UPDATE: createUrlGenerator(PATH_NAMES.IPV6_ADDRESSES_UPDATE),
  DELETE: createUrlGenerator(PATH_NAMES.IPV6_ADDRESSES_DELETE),
};

export const getSystemUrl = {
  INFO: createUrlGenerator(PATH_NAMES.SYSTEM_INFO),
  STATUS: createUrlGenerator(PATH_NAMES.SYSTEM_STATUS),
  HEALTH: createUrlGenerator(PATH_NAMES.SYSTEM_HEALTH),
  METRICS: createUrlGenerator(PATH_NAMES.SYSTEM_METRICS),
  CONFIG: createUrlGenerator(PATH_NAMES.SYSTEM_CONFIG),
  LOGS: createUrlGenerator(PATH_NAMES.SYSTEM_LOGS),
  BACKUP: createUrlGenerator(PATH_NAMES.SYSTEM_BACKUP),
  RESTORE: createUrlGenerator(PATH_NAMES.SYSTEM_RESTORE),
};

export const getMonitoringUrl = {
  DASHBOARD: createUrlGenerator(PATH_NAMES.MONITORING_DASHBOARD),
  ALERTS: {
    LIST: createUrlGenerator(PATH_NAMES.MONITORING_ALERTS),
    GET: createUrlGenerator(PATH_NAMES.MONITORING_ALERTS_GET),
    UPDATE: createUrlGenerator(PATH_NAMES.MONITORING_ALERTS_UPDATE),
    DELETE: createUrlGenerator(PATH_NAMES.MONITORING_ALERTS_DELETE),
    ACKNOWLEDGE: createUrlGenerator(PATH_NAMES.MONITORING_ALERTS_ACKNOWLEDGE),
  },
  METRICS: {
    LIST: createUrlGenerator(PATH_NAMES.MONITORING_METRICS),
    GET: createUrlGenerator(PATH_NAMES.MONITORING_METRICS_GET),
  },
};

export const getLogsUrl = {
  LIST: createUrlGenerator(PATH_NAMES.LOGS),
  GET: createUrlGenerator(PATH_NAMES.LOGS_GET),
  SEARCH: createUrlGenerator(PATH_NAMES.LOGS_SEARCH),
  EXPORT: createUrlGenerator(PATH_NAMES.LOGS_EXPORT),
  CLEANUP: createUrlGenerator(PATH_NAMES.LOGS_CLEANUP),
};

export const getNetworkUrl = {
  PING: createUrlGenerator(PATH_NAMES.NETWORK_PING),
  TRACEROUTE: createUrlGenerator(PATH_NAMES.NETWORK_TRACEROUTE),
  NSLOOKUP: createUrlGenerator(PATH_NAMES.NETWORK_NSLOOKUP),
  WHOIS: createUrlGenerator(PATH_NAMES.NETWORK_WHOIS),
};

export const getAuditUrl = {
  LIST: createUrlGenerator(PATH_NAMES.AUDIT),
  GET: createUrlGenerator(PATH_NAMES.AUDIT_GET),
  SEARCH: createUrlGenerator(PATH_NAMES.AUDIT_SEARCH),
  EXPORT: createUrlGenerator(PATH_NAMES.AUDIT_EXPORT),
};

export const getUploadUrl = {
  FILE: createUrlGenerator(PATH_NAMES.UPLOAD_FILE),
  IMAGE: createUrlGenerator(PATH_NAMES.UPLOAD_IMAGE),
  AVATAR: createUrlGenerator(PATH_NAMES.UPLOAD_AVATAR),
};

// WebSocket URL生成函数
export const getWebSocketUrl = (action) => {
  const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const wsHost = process.env.REACT_APP_WS_HOST || window.location.host;
  const wsPath = {
    NOTIFICATIONS: '/ws/notifications',
    LOGS: '/ws/logs',
    METRICS: '/ws/metrics',
  }[action] || '';
  
  return `${wsProtocol}//${wsHost}${wsPath}`;
};

// 默认导出
export default {
  API_CONFIG,
  apiPathBuilder,
  buildUrl,
  validatePath,
  getApiVersion,
  getApiBaseUrl,
  setApiBaseUrl,
  registerPath,
  getPathConfig,
  getAllPaths,
  clearCache,
  PATH_NAMES,
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
  getWebSocketUrl,
};
