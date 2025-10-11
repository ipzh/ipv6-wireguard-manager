import { useEffect, useRef, useState, useCallback } from 'react';
import { WebSocketService, WebSocketConfig, WebSocketMessage } from '../services/websocket';
import { useAppSelector } from '../store/hooks';

export interface UseWebSocketOptions {
  autoConnect?: boolean;
  reconnectOnMount?: boolean;
  subscriptions?: string[];
}

export interface UseWebSocketReturn {
  isConnected: boolean;
  connectionState: string;
  connect: () => Promise<void>;
  disconnect: () => void;
  send: (message: WebSocketMessage) => void;
  subscribe: (subscriptionType: string) => void;
  unsubscribe: (subscriptionType: string) => void;
  ping: () => void;
  lastMessage: WebSocketMessage | null;
  error: Error | null;
}

export const useWebSocket = (
  options: UseWebSocketOptions = {}
): UseWebSocketReturn => {
  const {
    autoConnect = true,
    reconnectOnMount = true,
    subscriptions = [],
  } = options;

  const user = useAppSelector((state) => state.auth.user);
  const wsServiceRef = useRef<WebSocketService | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [connectionState, setConnectionState] = useState('CLOSED');
  const [lastMessage, setLastMessage] = useState<WebSocketMessage | null>(null);
  const [error, setError] = useState<Error | null>(null);

  const connect = useCallback(async () => {
    if (!user?.id) {
      console.warn('用户未登录，无法建立WebSocket连接');
      return;
    }

    try {
      const config: WebSocketConfig = {
        url: import.meta.env.VITE_WS_URL || 'ws://localhost:8000',
        userId: user.id,
        connectionType: 'dashboard',
      };

      wsServiceRef.current = new WebSocketService(config);

      // 设置事件监听器
      wsServiceRef.current.on('connected', () => {
        setIsConnected(true);
        setConnectionState('OPEN');
        setError(null);
        console.log('WebSocket连接已建立');
      });

      wsServiceRef.current.on('disconnected', () => {
        setIsConnected(false);
        setConnectionState('CLOSED');
        console.log('WebSocket连接已断开');
      });

      wsServiceRef.current.on('error', (err) => {
        setError(err);
        console.error('WebSocket错误:', err);
      });

      wsServiceRef.current.on('message', (message) => {
        setLastMessage(message);
      });

      await wsServiceRef.current.connect();
    } catch (err) {
      setError(err as Error);
      console.error('WebSocket连接失败:', err);
    }
  }, [user?.id]);

  const disconnect = useCallback(() => {
    if (wsServiceRef.current) {
      wsServiceRef.current.disconnect();
      wsServiceRef.current = null;
    }
    setIsConnected(false);
    setConnectionState('CLOSED');
  }, []);

  const send = useCallback((message: WebSocketMessage) => {
    if (wsServiceRef.current) {
      wsServiceRef.current.send(message);
    }
  }, []);

  const subscribe = useCallback((subscriptionType: string) => {
    if (wsServiceRef.current) {
      wsServiceRef.current.subscribe(subscriptionType);
    }
  }, []);

  const unsubscribe = useCallback((subscriptionType: string) => {
    if (wsServiceRef.current) {
      wsServiceRef.current.unsubscribe(subscriptionType);
    }
  }, []);

  const ping = useCallback(() => {
    if (wsServiceRef.current) {
      wsServiceRef.current.ping();
    }
  }, []);

  // 自动连接
  useEffect(() => {
    if (autoConnect && user?.id) {
      connect();
    }

    return () => {
      if (wsServiceRef.current) {
        wsServiceRef.current.disconnect();
      }
    };
  }, [autoConnect, user?.id, connect]);

  // 自动订阅
  useEffect(() => {
    if (isConnected && subscriptions.length > 0) {
      subscriptions.forEach((subscription) => {
        subscribe(subscription);
      });
    }

    return () => {
      if (isConnected && subscriptions.length > 0) {
        subscriptions.forEach((subscription) => {
          unsubscribe(subscription);
        });
      }
    };
  }, [isConnected, subscriptions, subscribe, unsubscribe]);

  // 定期发送心跳
  useEffect(() => {
    if (!isConnected) return;

    const interval = setInterval(() => {
      ping();
    }, 30000); // 每30秒发送一次心跳

    return () => {
      clearInterval(interval);
    };
  }, [isConnected, ping]);

  return {
    isConnected,
    connectionState,
    connect,
    disconnect,
    send,
    subscribe,
    unsubscribe,
    ping,
    lastMessage,
    error,
  };
};

// 专门用于系统指标的Hook
export const useSystemMetrics = () => {
  const [metrics, setMetrics] = useState<any>(null);
  const { subscribe, unsubscribe, isConnected } = useWebSocket({
    subscriptions: ['system_metrics'],
  });

  useEffect(() => {
    if (isConnected) {
      const handleMetrics = (data: any) => {
        setMetrics(data);
      };

      // 这里需要从WebSocket服务获取事件监听器
      // 简化实现
      return () => {
        // 清理逻辑
      };
    }
  }, [isConnected]);

  return metrics;
};

// 专门用于WireGuard状态的Hook
export const useWireGuardStatus = () => {
  const [status, setStatus] = useState<any>(null);
  const { subscribe, unsubscribe, isConnected } = useWebSocket({
    subscriptions: ['wireguard_status'],
  });

  useEffect(() => {
    if (isConnected) {
      const handleStatus = (data: any) => {
        setStatus(data);
      };

      // 这里需要从WebSocket服务获取事件监听器
      // 简化实现
      return () => {
        // 清理逻辑
      };
    }
  }, [isConnected]);

  return status;
};

// 专门用于网络状态的Hook
export const useNetworkStatus = () => {
  const [status, setStatus] = useState<any>(null);
  const { subscribe, unsubscribe, isConnected } = useWebSocket({
    subscriptions: ['network_status'],
  });

  useEffect(() => {
    if (isConnected) {
      const handleStatus = (data: any) => {
        setStatus(data);
      };

      // 这里需要从WebSocket服务获取事件监听器
      // 简化实现
      return () => {
        // 清理逻辑
      };
    }
  }, [isConnected]);

  return status;
};

// 专门用于告警的Hook
export const useAlerts = () => {
  const [alerts, setAlerts] = useState<any[]>([]);
  const { subscribe, unsubscribe, isConnected } = useWebSocket({
    subscriptions: ['alerts'],
  });

  useEffect(() => {
    if (isConnected) {
      const handleAlerts = (data: any) => {
        setAlerts(data.alerts || []);
      };

      // 这里需要从WebSocket服务获取事件监听器
      // 简化实现
      return () => {
        // 清理逻辑
      };
    }
  }, [isConnected]);

  return alerts;
};
