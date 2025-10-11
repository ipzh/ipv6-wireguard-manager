import { useEffect, useRef, useState, useCallback } from 'react';
import { getWebSocketService, WebSocketConfig, WebSocketMessage } from '../services/websocket';
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
  const wsServiceRef = useRef<ReturnType<typeof getWebSocketService> | null>(null);
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

      wsServiceRef.current = getWebSocketService();
      if (wsServiceRef.current) {
        wsServiceRef.current.connect(config);

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

        wsServiceRef.current.on('error', (err: Error) => {
          setError(err);
          setIsConnected(false);
          setConnectionState('ERROR');
          console.error('WebSocket错误:', err);
        });

        wsServiceRef.current.on('message', (message: WebSocketMessage) => {
          setLastMessage(message);
        });

        // 订阅指定的消息类型
        subscriptions.forEach(subscription => {
          wsServiceRef.current?.subscribe(subscription);
        });
      }
    } catch (err) {
      const error = err instanceof Error ? err : new Error('WebSocket连接失败');
      setError(error);
      setIsConnected(false);
      setConnectionState('ERROR');
      console.error('WebSocket连接失败:', error);
    }
  }, [user?.id, subscriptions]);

  const disconnect = useCallback(() => {
    if (wsServiceRef.current) {
      wsServiceRef.current.disconnect();
      wsServiceRef.current = null;
    }
    setIsConnected(false);
    setConnectionState('CLOSED');
  }, []);

  const send = useCallback((message: WebSocketMessage) => {
    if (wsServiceRef.current && isConnected) {
      wsServiceRef.current.send(message);
    } else {
      console.warn('WebSocket未连接，无法发送消息');
    }
  }, [isConnected]);

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
    if (wsServiceRef.current && isConnected) {
      wsServiceRef.current.ping();
    }
  }, [isConnected]);

  // 自动连接
  useEffect(() => {
    if (autoConnect && user?.id) {
      connect();
    }

    return () => {
      disconnect();
    };
  }, [autoConnect, user?.id, connect, disconnect]);

  // 重新连接
  useEffect(() => {
    if (reconnectOnMount && user?.id && !isConnected) {
      const timer = setTimeout(() => {
        connect();
      }, 1000);
      return () => clearTimeout(timer);
    }
  }, [reconnectOnMount, user?.id, isConnected, connect]);

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

// 预定义的WebSocket hooks
export const useMetricsWebSocket = () => {
  const { subscribe, unsubscribe, isConnected } = useWebSocket({
    subscriptions: ['metrics'],
  });

  const handleMetrics = (data: any) => {
    console.log('收到指标数据:', data);
  };

  return {
    subscribe,
    unsubscribe,
    isConnected,
    handleMetrics,
  };
};

export const useStatusWebSocket = () => {
  const { subscribe, unsubscribe, isConnected } = useWebSocket({
    subscriptions: ['status'],
  });

  const handleStatus = (data: any) => {
    console.log('收到状态数据:', data);
  };

  return {
    subscribe,
    unsubscribe,
    isConnected,
    handleStatus,
  };
};

export const useAlertsWebSocket = () => {
  const { subscribe, unsubscribe, isConnected } = useWebSocket({
    subscriptions: ['alerts'],
  });

  const handleAlerts = (data: any) => {
    console.log('收到告警数据:', data);
  };

  return {
    subscribe,
    unsubscribe,
    isConnected,
    handleAlerts,
  };
};