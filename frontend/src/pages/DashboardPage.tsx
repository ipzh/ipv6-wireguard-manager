import React, { useState, useEffect } from 'react'
import { Card, Row, Col, Statistic, Typography, Table, Tag, Button, message, Spin } from 'antd'
import { 
  CheckCircleOutlined, 
  UserOutlined, 
  DesktopOutlined, 
  DatabaseOutlined,
  GlobalOutlined,
  ReloadOutlined,
  PlayCircleOutlined,
  PauseCircleOutlined
} from '@ant-design/icons'
import { apiClient } from '../services/api'

const { Title } = Typography

interface ApiStatus {
  status: string
  service: string
  version: string
  message: string
}

interface Server {
  id: number
  name: string
  description?: string
  status: string
  ipv4?: string
  ipv6?: string
}

interface Client {
  id: number
  name: string
  description?: string
  status: string
  public_key?: string
  allowed_ips?: string
}

interface BGPAnnouncement {
  id: number
  prefix: string
  asn: number
  status: string
  next_hop?: string
}

const DashboardPage: React.FC = () => {
  const [loading, setLoading] = useState(true)
  const [apiStatus, setApiStatus] = useState<ApiStatus | null>(null)
  const [servers, setServers] = useState<Server[]>([])
  const [clients, setClients] = useState<Client[]>([])
  const [bgpAnnouncements, setBgpAnnouncements] = useState<BGPAnnouncement[]>([])

  const loadData = async () => {
    setLoading(true)
    try {
      // 加载API状态
      const statusResponse = await apiClient.get('/status/status')
      setApiStatus(statusResponse.data)

      // 加载服务器数据
      const serversResponse = await apiClient.get('/wireguard/servers')
      setServers(serversResponse.data.servers || [])

      // 加载客户端数据
      const clientsResponse = await apiClient.get('/wireguard/clients')
      setClients(clientsResponse.data.clients || [])

      // 加载BGP宣告数据
      const bgpResponse = await apiClient.get('/network/bgp/announcements')
      setBgpAnnouncements(bgpResponse.data.announcements || [])
    } catch (error) {
      console.error('加载数据失败:', error)
      message.error('加载数据失败')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadData()
  }, [])

  const serverColumns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '名称', dataIndex: 'name', key: 'name' },
    { title: '描述', dataIndex: 'description', key: 'description' },
    { title: 'IPv4', dataIndex: 'ipv4', key: 'ipv4' },
    { title: 'IPv6', dataIndex: 'ipv6', key: 'ipv6' },
    { 
      title: '状态', 
      dataIndex: 'status', 
      key: 'status', 
      width: 100,
      render: (status: string) => (
        <Tag color={status === 'running' ? 'green' : 'red'}>
          {status === 'running' ? '运行中' : '已停止'}
        </Tag>
      )
    }
  ]

  const clientColumns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '名称', dataIndex: 'name', key: 'name' },
    { title: '描述', dataIndex: 'description', key: 'description' },
    { title: '允许IP', dataIndex: 'allowed_ips', key: 'allowed_ips' },
    { 
      title: '状态', 
      dataIndex: 'status', 
      key: 'status', 
      width: 100,
      render: (status: string) => (
        <Tag color={status === 'connected' ? 'blue' : 'gray'}>
          {status === 'connected' ? '已连接' : '未连接'}
        </Tag>
      )
    }
  ]

  const bgpColumns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '前缀', dataIndex: 'prefix', key: 'prefix' },
    { title: 'ASN', dataIndex: 'asn', key: 'asn' },
    { title: '下一跳', dataIndex: 'next_hop', key: 'next_hop' },
    { 
      title: '状态', 
      dataIndex: 'status', 
      key: 'status', 
      width: 100,
      render: (status: string) => (
        <Tag color={status === 'announced' ? 'green' : 'orange'}>
          {status === 'announced' ? '已宣告' : '未宣告'}
        </Tag>
      )
    }
  ]

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <Spin size="large" />
      </div>
    )
  }

  return (
    <div>
      <div className="mb-6 flex justify-between items-center">
        <div>
          <Title level={2}>仪表板</Title>
          <p className="text-gray-600">系统概览和关键指标</p>
        </div>
        <Button 
          icon={<ReloadOutlined />} 
          onClick={loadData}
          loading={loading}
        >
          刷新
        </Button>
      </div>

      <div className="responsive-grid">
        <Card className="fade-in">
          <Statistic
            title="系统状态"
            value={apiStatus ? apiStatus.status : '检查中'}
            valueStyle={{ color: apiStatus ? '#52c41a' : '#faad14' }}
            prefix={<CheckCircleOutlined />}
          />
        </Card>
        
        <Card className="fade-in">
          <Statistic
            title="在线客户端"
            value={clients.filter(c => c.status === 'connected').length}
            suffix={`/ ${clients.length}`}
            prefix={<UserOutlined />}
          />
        </Card>
        
        <Card className="fade-in">
          <Statistic
            title="WireGuard服务器"
            value={servers.filter(s => s.status === 'running').length}
            suffix={`/ ${servers.length}`}
            prefix={<DesktopOutlined />}
          />
        </Card>
        
        <Card className="fade-in">
          <Statistic
            title="BGP宣告"
            value={bgpAnnouncements.filter(b => b.status === 'announced').length}
            suffix={`/ ${bgpAnnouncements.length}`}
            prefix={<GlobalOutlined />}
          />
        </Card>
      </div>

      <div className="mt-6 space-y-4">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <Card 
            title="WireGuard服务器" 
            extra={
              <Button 
                type="primary" 
                size="small"
                icon={<PlayCircleOutlined />}
                className="hidden sm:inline-flex"
              >
                管理
              </Button>
            }
            className="fade-in"
          >
            <Table 
              columns={serverColumns} 
              dataSource={servers} 
              rowKey="id"
              pagination={false}
              size="small"
              scroll={{ x: 'max-content' }}
              locale={{ emptyText: '暂无服务器' }}
            />
          </Card>
          
          <Card 
            title="WireGuard客户端" 
            extra={
              <Button 
                type="primary" 
                size="small"
                icon={<UserOutlined />}
                className="hidden sm:inline-flex"
              >
                管理
              </Button>
            }
            className="fade-in"
          >
            <Table 
              columns={clientColumns} 
              dataSource={clients} 
              rowKey="id"
              pagination={false}
              size="small"
              scroll={{ x: 'max-content' }}
              locale={{ emptyText: '暂无客户端' }}
            />
          </Card>
        </div>

        <Card 
          title="BGP宣告管理" 
          extra={
            <Button 
              type="primary" 
              size="small"
              icon={<GlobalOutlined />}
              className="hidden sm:inline-flex"
            >
              管理BGP
            </Button>
          }
          className="fade-in"
        >
          <Table 
            columns={bgpColumns} 
            dataSource={bgpAnnouncements} 
            rowKey="id"
            pagination={false}
            size="small"
            scroll={{ x: 'max-content' }}
            locale={{ emptyText: '暂无BGP宣告' }}
          />
        </Card>
      </div>
    </div>
  )
}

export default DashboardPage
