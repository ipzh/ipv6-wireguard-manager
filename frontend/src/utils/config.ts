/**
 * 配置管理工具
 * 提供动态配置检测和环境变量管理
 */

export interface AppConfig {
  apiUrl: string
  wsUrl: string
  appName: string
  appVersion: string
  debug: boolean
  enableWebSocket: boolean
  enableMonitoring: boolean
  enableBGP: boolean
  theme: 'light' | 'dark'
  primaryColor: string
  tokenStorageKey: string
  refreshTokenKey: string
  defaultPageSize: number
  maxPageSize: number
  apiTimeout: number
  wsTimeout: number
}

/**
 * 动态获取API基础URL
 */
export const getApiBaseUrl = (): string => {
  // 1. 优先使用环境变量
  if (import.meta.env.VITE_API_URL) {
    return import.meta.env.VITE_API_URL
  }
  
  // 2. 自动检测当前主机和端口
  if (typeof window !== 'undefined') {
    const protocol = window.location.protocol
    const hostname = window.location.hostname
    const port = window.location.port
    
    // 如果是开发环境或本地访问
    if (isLocalHost(hostname)) {
      return `${protocol}//${hostname}:8000`
    }
    
    // 生产环境，使用相同的主机和协议，但端口8000
    return `${protocol}//${hostname}:8000`
  }
  
  // 3. 默认回退
  return 'http://localhost:8000'
}

/**
 * 动态获取WebSocket基础URL
 */
export const getWebSocketBaseUrl = (): string => {
  // 1. 优先使用环境变量
  if (import.meta.env.VITE_WS_URL) {
    return import.meta.env.VITE_WS_URL
  }
  
  // 2. 自动检测当前主机和端口
  if (typeof window !== 'undefined') {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const hostname = window.location.hostname
    
    // 如果是开发环境或本地访问
    if (isLocalHost(hostname)) {
      return `${protocol}//${hostname}:8000`
    }
    
    // 生产环境，使用相同的主机和协议，但端口8000
    return `${protocol}//${hostname}:8000`
  }
  
  // 3. 默认回退
  return 'ws://localhost:8000'
}

/**
 * 检查是否为本地主机
 */
export const isLocalHost = (hostname: string): boolean => {
  return (
    hostname === 'localhost' ||
    hostname === '127.0.0.1' ||
    hostname === '::1' ||
    hostname.startsWith('192.168.') ||
    hostname.startsWith('172.') ||
    hostname.startsWith('10.') ||
    hostname.startsWith('fd00:') ||
    hostname.startsWith('fe80:')
  )
}

/**
 * 检查是否为IPv6地址
 */
export const isIPv6 = (hostname: string): boolean => {
  return hostname.includes(':') && !hostname.includes('.')
}

/**
 * 检查是否为IPv4地址
 */
export const isIPv4 = (hostname: string): boolean => {
  const ipv4Regex = /^(\d{1,3}\.){3}\d{1,3}$/
  return ipv4Regex.test(hostname)
}

/**
 * 获取应用配置
 */
export const getAppConfig = (): AppConfig => {
  return {
    apiUrl: getApiBaseUrl(),
    wsUrl: getWebSocketBaseUrl(),
    appName: import.meta.env.VITE_APP_NAME || 'IPv6 WireGuard Manager',
    appVersion: import.meta.env.VITE_APP_VERSION || '3.0.0',
    debug: import.meta.env.VITE_DEBUG === 'true',
    enableWebSocket: import.meta.env.VITE_ENABLE_WEBSOCKET !== 'false',
    enableMonitoring: import.meta.env.VITE_ENABLE_MONITORING !== 'false',
    enableBGP: import.meta.env.VITE_ENABLE_BGP !== 'false',
    theme: (import.meta.env.VITE_THEME as 'light' | 'dark') || 'light',
    primaryColor: import.meta.env.VITE_PRIMARY_COLOR || '#3b82f6',
    tokenStorageKey: import.meta.env.VITE_TOKEN_STORAGE_KEY || 'ipv6wg_token',
    refreshTokenKey: import.meta.env.VITE_REFRESH_TOKEN_KEY || 'ipv6wg_refresh_token',
    defaultPageSize: parseInt(import.meta.env.VITE_DEFAULT_PAGE_SIZE || '10'),
    maxPageSize: parseInt(import.meta.env.VITE_MAX_PAGE_SIZE || '100'),
    apiTimeout: parseInt(import.meta.env.VITE_API_TIMEOUT || '10000'),
    wsTimeout: parseInt(import.meta.env.VITE_WEBSOCKET_TIMEOUT || '30000'),
  }
}

/**
 * 获取网络信息
 */
export const getNetworkInfo = () => {
  if (typeof window === 'undefined') {
    return {
      protocol: 'http:',
      hostname: 'localhost',
      port: '',
      isLocal: true,
      isIPv4: false,
      isIPv6: false,
    }
  }

  const protocol = window.location.protocol
  const hostname = window.location.hostname
  const port = window.location.port

  return {
    protocol,
    hostname,
    port,
    isLocal: isLocalHost(hostname),
    isIPv4: isIPv4(hostname),
    isIPv6: isIPv6(hostname),
  }
}

/**
 * 生成配置报告
 */
export const generateConfigReport = (): string => {
  const config = getAppConfig()
  const networkInfo = getNetworkInfo()
  
  return `
IPv6 WireGuard Manager 配置报告
================================

应用配置:
- 应用名称: ${config.appName}
- 应用版本: ${config.appVersion}
- 调试模式: ${config.debug}
- 主题: ${config.theme}
- 主色调: ${config.primaryColor}

网络配置:
- 协议: ${networkInfo.protocol}
- 主机名: ${networkInfo.hostname}
- 端口: ${networkInfo.port || '默认'}
- 本地访问: ${networkInfo.isLocal ? '是' : '否'}
- IPv4地址: ${networkInfo.isIPv4 ? '是' : '否'}
- IPv6地址: ${networkInfo.isIPv6 ? '是' : '否'}

API配置:
- API地址: ${config.apiUrl}
- WebSocket地址: ${config.wsUrl}
- API超时: ${config.apiTimeout}ms
- WebSocket超时: ${config.wsTimeout}ms

功能开关:
- WebSocket: ${config.enableWebSocket ? '启用' : '禁用'}
- 监控: ${config.enableMonitoring ? '启用' : '禁用'}
- BGP: ${config.enableBGP ? '启用' : '禁用'}

分页配置:
- 默认页大小: ${config.defaultPageSize}
- 最大页大小: ${config.maxPageSize}
`
}

// 导出默认配置
export const config = getAppConfig()
export default config
