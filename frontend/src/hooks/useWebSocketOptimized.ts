import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from './useAuth';

interface WebSocketMessage {
  type: string;
  timestamp: number;
  data?: any;
}

interface WebSocketOptions {
  reconnectOnMount?: boolean;
  reconnectInterval?: number;
  maxReconnectAttempts?: number;
  heartbeatInterval?: number;
}

interface WebSocketState {
  isConnected: boolean;
  isConnecting: boolean;
  lastMessage: WebSocketMessage | null;
  error: string | null;
  reconnectAttempts: number;
}

interface WebSocketActions {
  connect: () => void;
  disconnect: () => void;
  sendMessage: (message: any) => void;
  subscribe: (subscriptionType: string) => void;
  unsubscribe: (subscriptionType: string) => void;
  ping: () => void;
}

export const useWebSocketOptimized = (
  url: string,
  options: WebSocketOptions = {}
): WebSocketState & WebSocketActions => {
  const {
    reconnectOnMount = true,
    reconnectInterval = 5000,
    maxReconnectAttempts = 5,
    heartbeatInterval = 30000
  } = options;

  const { user } = useAuth();
  const [state, setState] = useState<WebSocketState>({
    isConnected: false,
    isConnecting: false,
    lastMessage: null,
    error: null,
    reconnectAttempts: 0
  });

  const wsRef = useRef<WebSocket | null>(null);
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const heartbeatTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const subscriptionsRef = useRef<Set<string>>(new Set());
  const messageHandlersRef = useRef<Map<string, (data: any) => void>>(new Map());

  // 清理定时器
  const clearTimeouts = useCallback(() => {
    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current);
      reconnectTimeoutRef.current = null;
    }
    if (heartbeatTimeoutRef.current) {
      clearTimeout(heartbeatTimeoutRef.current);
      heartbeatTimeoutRef.current = null;
    }
  }, []);

  // 发送心跳
  const sendHeartbeat = useCallback(() => {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ type: 'ping' }));
    }
  }, []);

  // 启动心跳
  const startHeartbeat = useCallback(() => {
    clearTimeouts();
    heartbeatTimeoutRef.current = setTimeout(() => {
      sendHeartbeat();
      startHeartbeat();
    }, heartbeatInterval);
  }, [sendHeartbeat, heartbeatInterval, clearTimeouts]);

  // 处理消息
  const handleMessage = useCallback((event: MessageEvent) => {
    try {
      const message: WebSocketMessage = JSON.parse(event.data);
      
      setState(prev => ({
        ...prev,
        lastMessage: message,
        error: null
      }));

      // 根据消息类型处理不同的数据
      switch (message.type) {
        case 'system_metrics':
          // 更新系统指标状态
          const systemMetricsHandler = messageHandlersRef.current.get('system_metrics');
          if (systemMetricsHandler) {
            systemMetricsHandler(message.data);
          }
          break;
          
        case 'wireguard_status':
          // 更新WireGuard状态
          const wireguardHandler = messageHandlersRef.current.get('wireguard_status');
          if (wireguardHandler) {
            wireguardHandler(message.data);
          }
          break;
          
        case 'network_status':
          // 更新网络状态
          const networkHandler = messageHandlersRef.current.get('network_status');
          if (networkHandler) {
            networkHandler(message.data);
          }
          break;
          
        case 'alerts':
          // 处理告警
          const alertsHandler = messageHandlersRef.current.get('alerts');
          if (alertsHandler) {
            alertsHandler(message.data);
          }
          break;
          
        case 'pong':
          // 心跳响应
          console.log('收到心跳响应');
          break;
          
        case 'subscription_confirmed':
          console.log(`订阅确认: ${message.subscription}`);
          break;
          
        case 'unsubscription_confirmed':
          console.log(`取消订阅确认: ${message.subscription}`);
          break;
          
        default:
          console.log('未知消息类型:', message.type);
      }
    } catch (error) {
      console.error('解析WebSocket消息失败:', error);
      setState(prev => ({
        ...prev,
        error: '消息解析失败'
      }));
    }
  }, []);

  // 连接WebSocket
  const connect = useCallback(() => {
    if (wsRef.current?.readyState === WebSocket.OPEN || 
        wsRef.current?.readyState === WebSocket.CONNECTING) {
      return;
    }

    setState(prev => ({
      ...prev,
      isConnecting: true,
      error: null
    }));

    try {
      const ws = new WebSocket(url);
      wsRef.current = ws;

      ws.onopen = () => {
        console.log('WebSocket连接已建立');
        setState(prev => ({
          ...prev,
          isConnected: true,
          isConnecting: false,
          reconnectAttempts: 0,
          error: null
        }));

        // 启动心跳
        startHeartbeat();

        // 重新订阅之前的订阅
        subscriptionsRef.current.forEach(subscription => {
          ws.send(JSON.stringify({
            type: 'subscribe',
            subscription
          }));
        });
      };

      ws.onmessage = handleMessage;

      ws.onclose = (event) => {
        console.log('WebSocket连接已关闭:', event.code, event.reason);
        setState(prev => ({
          ...prev,
          isConnected: false,
          isConnecting: false
        }));

        clearTimeouts();

        // 自动重连
        if (state.reconnectAttempts < maxReconnectAttempts) {
          setState(prev => ({
            ...prev,
            reconnectAttempts: prev.reconnectAttempts + 1
          }));

          reconnectTimeoutRef.current = setTimeout(() => {
            console.log(`尝试重连 (${state.reconnectAttempts + 1}/${maxReconnectAttempts})`);
            connect();
          }, reconnectInterval);
        } else {
          setState(prev => ({
            ...prev,
            error: '连接失败，已达到最大重连次数'
          }));
        }
      };

      ws.onerror = (error) => {
        console.error('WebSocket错误:', error);
        setState(prev => ({
          ...prev,
          error: 'WebSocket连接错误',
          isConnecting: false
        }));
      };

    } catch (error) {
      console.error('创建WebSocket连接失败:', error);
      setState(prev => ({
        ...prev,
        error: '创建连接失败',
        isConnecting: false
      }));
    }
  }, [url, state.reconnectAttempts, maxReconnectAttempts, reconnectInterval, handleMessage, startHeartbeat, clearTimeouts]);

  // 断开连接
  const disconnect = useCallback(() => {
    clearTimeouts();
    
    if (wsRef.current) {
      wsRef.current.close();
      wsRef.current = null;
    }

    setState(prev => ({
      ...prev,
      isConnected: false,
      isConnecting: false,
      reconnectAttempts: 0
    }));
  }, [clearTimeouts]);

  // 发送消息
  const sendMessage = useCallback((message: any) => {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(message));
    } else {
      console.warn('WebSocket未连接，无法发送消息');
    }
  }, []);

  // 订阅
  const subscribe = useCallback((subscriptionType: string) => {
    subscriptionsRef.current.add(subscriptionType);
    sendMessage({
      type: 'subscribe',
      subscription: subscriptionType
    });
  }, [sendMessage]);

  // 取消订阅
  const unsubscribe = useCallback((subscriptionType: string) => {
    subscriptionsRef.current.delete(subscriptionType);
    sendMessage({
      type: 'unsubscribe',
      subscription: subscriptionType
    });
  }, [sendMessage]);

  // 发送ping
  const ping = useCallback(() => {
    sendMessage({ type: 'ping' });
  }, [sendMessage]);

  // 注册消息处理器
  const registerMessageHandler = useCallback((type: string, handler: (data: any) => void) => {
    messageHandlersRef.current.set(type, handler);
  }, []);

  // 注销消息处理器
  const unregisterMessageHandler = useCallback((type: string) => {
    messageHandlersRef.current.delete(type);
  }, []);

  // 组件挂载时连接
  useEffect(() => {
    if (reconnectOnMount && user?.id && !state.isConnected) {
      const timer = setTimeout(() => {
        connect();
      }, 1000);
      return () => clearTimeout(timer);
    }
  }, [reconnectOnMount, user?.id, state.isConnected, connect]);

  // 组件卸载时断开连接
  useEffect(() => {
    return () => {
      disconnect();
    };
  }, [disconnect]);

  // 清理定时器
  useEffect(() => {
    return () => {
      clearTimeouts();
    };
  }, [clearTimeouts]);

  return {
    ...state,
    connect,
    disconnect,
    sendMessage,
    subscribe,
    unsubscribe,
    ping,
    registerMessageHandler,
    unregisterMessageHandler
  };
};

// 专门用于系统指标的Hook
export const useSystemMetrics = () => {
  const [metrics, setMetrics] = useState<any>(null);
  const ws = useWebSocketOptimized(`${window.location.protocol === 'https:' ? 'wss:' : 'ws:'}//${window.location.host}/api/v1/ws`);

  useEffect(() => {
    ws.registerMessageHandler('system_metrics', (data) => {
      setMetrics(data);
    });

    ws.subscribe('system_metrics');

    return () => {
      ws.unsubscribe('system_metrics');
      ws.unregisterMessageHandler('system_metrics');
    };
  }, [ws]);

  return { metrics, ...ws };
};

// 专门用于WireGuard状态的Hook
export const useWireGuardStatus = () => {
  const [status, setStatus] = useState<any>(null);
  const ws = useWebSocketOptimized(`${window.location.protocol === 'https:' ? 'wss:' : 'ws:'}//${window.location.host}/api/v1/ws`);

  useEffect(() => {
    ws.registerMessageHandler('wireguard_status', (data) => {
      setStatus(data);
    });

    ws.subscribe('wireguard_status');

    return () => {
      ws.unsubscribe('wireguard_status');
      ws.unregisterMessageHandler('wireguard_status');
    };
  }, [ws]);

  return { status, ...ws };
};

// 专门用于告警的Hook
export const useAlerts = () => {
  const [alerts, setAlerts] = useState<any[]>([]);
  const ws = useWebSocketOptimized(`${window.location.protocol === 'https:' ? 'wss:' : 'ws:'}//${window.location.host}/api/v1/ws`);

  useEffect(() => {
    ws.registerMessageHandler('alerts', (data) => {
      setAlerts(prev => [...data, ...prev].slice(0, 100)); // 保留最近100条告警
    });

    ws.subscribe('alerts');

    return () => {
      ws.unsubscribe('alerts');
      ws.unregisterMessageHandler('alerts');
    };
  }, [ws]);

  return { alerts, ...ws };
};
