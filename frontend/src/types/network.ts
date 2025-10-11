export interface NetworkInterface {
  id: string;
  name: string;
  type: string;
  ipv4_address?: string;
  ipv6_address?: string;
  mac_address?: string;
  mtu?: number;
  is_up: boolean;
  created_at: string;
  updated_at: string;
}

export interface NetworkInterfaceCreate {
  name: string;
  type: string;
  ipv4_address?: string;
  ipv6_address?: string;
  mac_address?: string;
  mtu?: number;
}

export interface NetworkInterfaceUpdate {
  name?: string;
  type?: string;
  ipv4_address?: string;
  ipv6_address?: string;
  mac_address?: string;
  mtu?: number;
}

export interface FirewallRule {
  id: string;
  name: string;
  table_name: string;
  chain_name: string;
  rule_spec: string;
  action: string;
  priority: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface FirewallRuleCreate {
  name: string;
  table_name: string;
  chain_name: string;
  rule_spec: string;
  action: string;
  priority: number;
}

export interface FirewallRuleUpdate {
  name?: string;
  table_name?: string;
  chain_name?: string;
  rule_spec?: string;
  action?: string;
  priority?: number;
}

export interface NetworkStatus {
  interfaces: NetworkInterface[];
  firewall_rules: FirewallRule[];
  routing_table: any[];
}

export interface InterfaceStats {
  interface: string;
  rx_bytes: number;
  tx_bytes: number;
  rx_packets: number;
  tx_packets: number;
  rx_errors: number;
  tx_errors: number;
}
