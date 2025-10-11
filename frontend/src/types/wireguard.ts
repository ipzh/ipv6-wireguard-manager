export interface WireGuardServer {
  id: string;
  name: string;
  interface: string;
  listen_port: number;
  private_key: string;
  public_key: string;
  ipv4_address?: string;
  ipv6_address?: string;
  dns_servers?: string[];
  mtu: number;
  config_file_path?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface WireGuardServerCreate {
  name: string;
  interface: string;
  listen_port: number;
  ipv4_address?: string;
  ipv6_address?: string;
  dns_servers?: string[];
  mtu: number;
}

export interface WireGuardServerUpdate {
  name?: string;
  interface?: string;
  listen_port?: number;
  ipv4_address?: string;
  ipv6_address?: string;
  dns_servers?: string[];
  mtu?: number;
}

export interface WireGuardClient {
  id: string;
  server_id: string;
  name: string;
  description?: string;
  private_key: string;
  public_key: string;
  ipv4_address?: string;
  ipv6_address?: string;
  allowed_ips?: string[];
  persistent_keepalive: number;
  qr_code?: string;
  config_file_path?: string;
  is_active: boolean;
  last_seen?: string;
  bytes_received: number;
  bytes_sent: number;
  created_at: string;
  updated_at: string;
}

export interface WireGuardClientCreate {
  server_id: string;
  name: string;
  description?: string;
  ipv4_address?: string;
  ipv6_address?: string;
  allowed_ips?: string[];
  persistent_keepalive: number;
}

export interface WireGuardClientUpdate {
  server_id?: string;
  name?: string;
  description?: string;
  ipv4_address?: string;
  ipv6_address?: string;
  allowed_ips?: string[];
  persistent_keepalive?: number;
}

export interface WireGuardInterfaceStatus {
  interface: string;
  public_key: string;
  private_key: string;
  listening_port: number;
  peers: number;
}

export interface WireGuardPeerStatus {
  public_key: string;
  preshared_key: string;
  endpoint?: string;
  allowed_ips: string[];
  latest_handshake?: string;
  transfer_rx: number;
  transfer_tx: number;
  persistent_keepalive: number;
}

export interface WireGuardStatus {
  interface: WireGuardInterfaceStatus;
  peers: WireGuardPeerStatus[];
}

export interface QRCodeResponse {
  qr_code: string;
  config: string;
}
