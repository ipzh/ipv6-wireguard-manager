/**
 * 前端API端点配置
 * 与后端API路径常量保持一致
 */

// 基础配置
const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || 'http://localhost:8000/api/v1';
const API_TIMEOUT = parseInt(process.env.REACT_APP_API_TIMEOUT) || 30000;

// API路径常量 - 与后端APIPaths类保持一致
const API_PATHS = {
  // 基础路径
  BASE: '/api/v1',
  
  // 认证相关
  AUTH: {
    LOGIN: '/auth/login',
    LOGOUT: '/auth/logout',
    REFRESH: '/auth/refresh',
    REGISTER: '/auth/register',
    VERIFY_EMAIL: '/auth/verify-email',
    RESET_PASSWORD: '/auth/reset-password',
    CHANGE_PASSWORD: '/auth/change-password',
    ME: '/auth/me'
  },
  
  // 用户管理
  USERS: {
    LIST: '/users',
    CREATE: '/users',
    GET: '/users/{user_id}',
    UPDATE: '/users/{user_id}',
    DELETE: '/users/{user_id}',
    LOCK: '/users/{user_id}/lock',
    UNLOCK: '/users/{user_id}/unlock',
    PROFILE: '/users/me/profile',
    AVATAR: '/users/me/avatar'
  },
  
  // 角色和权限管理
  ROLES: {
    LIST: '/roles',
    CREATE: '/roles',
    GET: '/roles/{role_id}',
    UPDATE: '/roles/{role_id}',
    DELETE: '/roles/{role_id}',
    PERMISSIONS: '/roles/{role_id}/permissions'
  },
  
  PERMISSIONS: {
    LIST: '/permissions',
    CREATE: '/permissions',
    GET: '/permissions/{permission_id}',
    UPDATE: '/permissions/{permission_id}',
    DELETE: '/permissions/{permission_id}'
  },
  
  // WireGuard管理
  WIREGUARD: {
    SERVERS: {
      LIST: '/wireguard/servers',
      CREATE: '/wireguard/servers',
      GET: '/wireguard/servers/{server_id}',
      UPDATE: '/wireguard/servers/{server_id}',
      DELETE: '/wireguard/servers/{server_id}',
      STATUS: '/wireguard/servers/{server_id}/status',
      START: '/wireguard/servers/{server_id}/start',
      STOP: '/wireguard/servers/{server_id}/stop',
      RESTART: '/wireguard/servers/{server_id}/restart',
      CONFIG: '/wireguard/servers/{server_id}/config',
      PEERS: '/wireguard/servers/{server_id}/peers'
    },
    CLIENTS: {
      LIST: '/wireguard/clients',
      CREATE: '/wireguard/clients',
      GET: '/wireguard/clients/{client_id}',
      UPDATE: '/wireguard/clients/{client_id}',
      DELETE: '/wireguard/clients/{client_id}',
      CONFIG: '/wireguard/clients/{client_id}/config',
      QR_CODE: '/wireguard/clients/{client_id}/qr-code',
      ENABLE: '/wireguard/clients/{client_id}/enable',
      DISABLE: '/wireguard/clients/{client_id}/disable'
    }
  },
  
  // BGP管理
  BGP: {
    SESSIONS: {
      LIST: '/bgp/sessions',
      CREATE: '/bgp/sessions',
      GET: '/bgp/sessions/{session_id}',
      UPDATE: '/bgp/sessions/{session_id}',
      DELETE: '/bgp/sessions/{session_id}',
      STATUS: '/bgp/sessions/{session_id}/status',
      START: '/bgp/sessions/{session_id}/start',
      STOP: '/bgp/sessions/{session_id}/stop',
      ROUTES: '/bgp/sessions/{session_id}/routes'
    },
    ROUTES: {
      LIST: '/bgp/routes',
      CREATE: '/bgp/routes',
      GET: '/bgp/routes/{route_id}',
      UPDATE: '/bgp/routes/{route_id}',
      DELETE: '/bgp/routes/{route_id}'
    }
  },
  
  // IPv6管理
  IPV6: {
    POOLS: {
      LIST: '/ipv6/pools',
      CREATE: '/ipv6/pools',
      GET: '/ipv6/pools/{pool_id}',
      UPDATE: '/ipv6/pools/{pool_id}',
      DELETE: '/ipv6/pools/{pool_id}',
      ALLOCATE: '/ipv6/pools/{pool_id}/allocate',
      RELEASE: '/ipv6/pools/{pool_id}/release'
    },
    ADDRESSES: {
      LIST: '/ipv6/addresses',
      CREATE: '/ipv6/addresses',
      GET: '/ipv6/addresses/{address_id}',
      UPDATE: '/ipv6/addresses/{address_id}',
      DELETE: '/ipv6/addresses/{address_id}'
    }
  },
  
  // 系统管理
  SYSTEM: {
    INFO: '/system/info',
    STATUS: '/system/status',
    HEALTH: '/system/health',
    METRICS: '/system/metrics',
    CONFIG: '/system/config',
    LOGS: '/system/logs',
    BACKUP: '/system/backup',
    RESTORE: '/system/restore'
  },
  
  // 监控
  MONITORING: {
    DASHBOARD: '/monitoring/dashboard',
    ALERTS: {
      LIST: '/monitoring/alerts',
      CREATE: '/monitoring/alerts',
      GET: '/monitoring/alerts/{alert_id}',
      UPDATE: '/monitoring/alerts/{alert_id}',
      DELETE: '/monitoring/alerts/{alert_id}',
      ACKNOWLEDGE: '/monitoring/alerts/{alert_id}/acknowledge'
    },
    METRICS: {
      LIST: '/monitoring/metrics',
      GET: '/monitoring/metrics/{metric_id}'
    }
  },
  
  // 日志
  LOGS: {
    LIST: '/logs',
    GET: '/logs/{log_id}',
    SEARCH: '/logs/search',
    EXPORT: '/logs/export',
    CLEANUP: '/logs/cleanup'
  },
  
  // 网络工具
  NETWORK: {
    PING: '/network/ping',
    TRACEROUTE: '/network/traceroute',
    NSLOOKUP: '/network/nslookup',
    WHOIS: '/network/whois'
  },
  
  // 审计日志
  AUDIT: {
    LIST: '/audit',
    GET: '/audit/{audit_id}',
    SEARCH: '/audit/search',
    EXPORT: '/audit/export'
  },
  
  // 文件上传
  UPLOAD: {
    FILE: '/upload/file',
    IMAGE: '/upload/image',
    AVATAR: '/upload/avatar'
  },
  
  // WebSocket
  WEBSOCKET: {
    NOTIFICATIONS: '/ws/notifications',
    LOGS: '/ws/logs',
    METRICS: '/ws/metrics'
  }
};

// API端点URL生成函数
const getApiUrl = (path) => `${API_BASE_URL}${path}`;

// 认证相关API
const getAuthUrl = (action) => getApiUrl(API_PATHS.AUTH[action] || '');

// 用户管理API
const getUsersUrl = (action, params = {}) => {
  let path = API_PATHS.USERS[action] || '';
  // 替换路径参数
  Object.keys(params).forEach(key => {
    path = path.replace(`{${key}}`, params[key]);
  });
  return getApiUrl(path);
};

// 角色管理API
const getRolesUrl = (action, params = {}) => {
  let path = API_PATHS.ROLES[action] || '';
  // 替换路径参数
  Object.keys(params).forEach(key => {
    path = path.replace(`{${key}}`, params[key]);
  });
  return getApiUrl(path);
};

// 权限管理API
const getPermissionsUrl = (action, params = {}) => {
  let path = API_PATHS.PERMISSIONS[action] || '';
  // 替换路径参数
  Object.keys(params).forEach(key => {
    path = path.replace(`{${key}}`, params[key]);
  });
  return getApiUrl(path);
};

// WireGuard服务器API
const getWireguardServersUrl = (action, params = {}) => {
  let path = API_PATHS.WIREGUARD.SERVERS[action] || '';
  // 替换路径参数
  Object.keys(params).forEach(key => {
    path = path.replace(`{${key}}`, params[key]);
  });
  return getApiUrl(path);
};

// WireGuard客户端API
const getWireguardClientsUrl = (action, params = {}) => {
  let path = API_PATHS.WIREGUARD.CLIENTS[action] || '';
  // 替换路径参数
  Object.keys(params).forEach(key => {
    path = path.replace(`{${key}}`, params[key]);
  });
  return getApiUrl(path);
};

// BGP会话API
const getBgpSessionsUrl = (action, params = {}) => {
  let path = API_PATHS.BGP.SESSIONS[action] || '';
  // 替换路径参数
  Object.keys(params).forEach(key => {
    path = path.replace(`{${key}}`, params[key]);
  });
  return getApiUrl(path);
};

// BGP路由API
const getBgpRoutesUrl = (action, params = {}) => {
  let path = API_PATHS.BGP.ROUTES[action] || '';
  // 替换路径参数
  Object.keys(params).forEach(key => {
    path = path.replace(`{${key}}`, params[key]);
  });
  return getApiUrl(path);
};

// IPv6地址池API
const getIpv6PoolsUrl = (action, params = {}) => {
  let path = API_PATHS.IPV6.POOLS[action] || '';
  // 替换路径参数
  Object.keys(params).forEach(key => {
    path = path.replace(`{${key}}`, params[key]);
  });
  return getApiUrl(path);
};

// IPv6地址API
const getIpv6AddressesUrl = (action, params = {}) => {
  let path = API_PATHS.IPV6.ADDRESSES[action] || '';
  // 替换路径参数
  Object.keys(params).forEach(key => {
    path = path.replace(`{${key}}`, params[key]);
  });
  return getApiUrl(path);
};

// 系统管理API
const getSystemUrl = (action) => getApiUrl(API_PATHS.SYSTEM[action] || '');

// 监控API
const getMonitoringUrl = (action, subAction = null, params = {}) => {
  let path;
  if (subAction && (action === 'ALERTS' || action === 'METRICS')) {
    path = API_PATHS.MONITORING[action.toLowerCase()][subAction] || '';
  } else {
    path = API_PATHS.MONITORING[action.toLowerCase()] || '';
  }
  
  // 替换路径参数
  Object.keys(params).forEach(key => {
    path = path.replace(`{${key}}`, params[key]);
  });
  
  return getApiUrl(path);
};

// 日志API
const getLogsUrl = (action, params = {}) => {
  let path = API_PATHS.LOGS[action] || '';
  // 替换路径参数
  Object.keys(params).forEach(key => {
    path = path.replace(`{${key}}`, params[key]);
  });
  return getApiUrl(path);
};

// 网络工具API
const getNetworkUrl = (action) => getApiUrl(API_PATHS.NETWORK[action] || '');

// 审计日志API
const getAuditUrl = (action, params = {}) => {
  let path = API_PATHS.AUDIT[action] || '';
  // 替换路径参数
  Object.keys(params).forEach(key => {
    path = path.replace(`{${key}}`, params[key]);
  });
  return getApiUrl(path);
};

// 文件上传API
const getUploadUrl = (action) => getApiUrl(API_PATHS.UPLOAD[action] || '');

// WebSocket URL
const getWebSocketUrl = (action) => {
  const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const wsHost = process.env.REACT_APP_WS_HOST || window.location.host;
  return `${wsProtocol}//${wsHost}${API_PATHS.WEBSOCKET[action] || ''}`;
};

// 导出API端点配置
export {
  API_BASE_URL,
  API_TIMEOUT,
  API_PATHS,
  getApiUrl,
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
};

// 导出完整的API端点配置对象
export default {
  API_BASE_URL,
  API_TIMEOUT,
  API_PATHS,
  getApiUrl,
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
};
