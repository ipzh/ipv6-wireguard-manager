import { EventEmitter } from 'events';

export interface WebSocketMessage {
  type: string;
  data?: any;
  timestamp?: number;
  subscription_type?: string;
}

export interface WebSocketConfig {
  url: string;
  userId: string;
  connectionType?: string;
  reconnectInterval?: number;
  maxReconnectAttempts?: number;
}

class WebSocketService extends EventEmitter {
  private ws: WebSocket | null = null;
  private config: WebSocketConfig;
  private reconnectAttempts = 0;
  private reconnectTimer: NodeJS.Timeout | null = null;
  private isConnecting = false;
  private isConnected = false;

  constructor(config: WebSocketConfig) {
    super();
    this.config = {
      reconnectInterval: 5000,
      maxReconnectAttempts: 10,
      connectionType: 'general',
      ...config,
    };
  }

  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      if (this.isConnecting || this.isConnected) {
        resolve();
        return;
      }

      this.isConnecting = true;

      try {
        const wsUrl = `${this.config.url}/ws/${this.config.userId}?connection_type=${this.config.connectionType}`;
        this.ws = new WebSocket(wsUrl);

        this.ws.onopen = () => {
          console.log('WebSocket连接已建立');
          this.isConnecting = false;
          this.isConnected = true;
          this.reconnectAttempts = 0;
          this.emit('connected');
          resolve();
        };

        this.ws.onmessage = (event) => {
          try {
            const message: WebSocketMessage = JSON.parse(event.data);
            this.handleMessage(message);
          } catch (error) {
            console.error('解析WebSocket消息失败:', error);
          }
        };

        this.ws.onclose = (event) => {
          console.log('WebSocket连接已关闭:', event.code, event.reason);
          this.isConnecting = false;
          this.isConnected = false;
          this.emit('disconnected', event);
          
          if (!event.wasClean && this.reconnectAttempts < this.config.maxReconnectAttempts!) {
            this.scheduleReconnect();
          }
        };

        this.ws.onerror = (error) => {
          console.error('WebSocket错误:', error);
          this.isConnecting = false;
          this.emit('error', error);
          reject(error);
        };

      } catch (error) {
        this.isConnecting = false;
        reject(error);
      }
    });
  }

  disconnect(): void {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }

    if (this.ws) {
      this.ws.close(1000, '主动断开连接');
      this.ws = null;
    }

    this.isConnected = false;
    this.isConnecting = false;
  }

  send(message: WebSocketMessage): void {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(message));
    } else {
      console.warn('WebSocket未连接，无法发送消息');
    }
  }

  subscribe(subscriptionType: string): void {
    this.send({
      type: 'subscribe',
      subscription_type: subscriptionType,
      timestamp: Date.now(),
    });
  }

  unsubscribe(subscriptionType: string): void {
    this.send({
      type: 'unsubscribe',
      subscription_type: subscriptionType,
      timestamp: Date.now(),
    });
  }

  ping(): void {
    this.send({
      type: 'ping',
      timestamp: Date.now(),
    });
  }

  private handleMessage(message: WebSocketMessage): void {
    switch (message.type) {
      case 'pong':
        this.emit('pong', message);
        break;
      case 'system_metrics':
        this.emit('systemMetrics', message.data);
        break;
      case 'wireguard_status':
        this.emit('wireguardStatus', message.data);
        break;
      case 'network_status':
        this.emit('networkStatus', message.data);
        break;
      case 'alerts':
        this.emit('alerts', message.data);
        break;
      case 'error':
        this.emit('error', message.data);
        break;
      default:
        this.emit('message', message);
    }
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
    }

    this.reconnectTimer = setTimeout(() => {
      this.reconnectAttempts++;
      console.log(`尝试重连WebSocket (${this.reconnectAttempts}/${this.config.maxReconnectAttempts})`);
      this.connect().catch((error) => {
        console.error('重连失败:', error);
      });
    }, this.config.reconnectInterval);
  }

  // 获取连接状态
  getConnectionState(): string {
    if (!this.ws) return 'CLOSED';
    
    switch (this.ws.readyState) {
      case WebSocket.CONNECTING:
        return 'CONNECTING';
      case WebSocket.OPEN:
        return 'OPEN';
      case WebSocket.CLOSING:
        return 'CLOSING';
      case WebSocket.CLOSED:
        return 'CLOSED';
      default:
        return 'UNKNOWN';
    }
  }

  isConnectionOpen(): boolean {
    return this.ws?.readyState === WebSocket.OPEN;
  }
}

// 创建全局WebSocket服务实例
let wsService: WebSocketService | null = null;

export const createWebSocketService = (config: WebSocketConfig): WebSocketService => {
  if (wsService) {
    wsService.disconnect();
  }
  
  wsService = new WebSocketService(config);
  return wsService;
};

export const getWebSocketService = (): WebSocketService | null => {
  return wsService;
};

export const disconnectWebSocket = (): void => {
  if (wsService) {
    wsService.disconnect();
    wsService = null;
  }
};

export default WebSocketService;
