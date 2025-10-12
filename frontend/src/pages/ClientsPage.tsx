import React, { useState, useEffect } from 'react'
import { Card, Typography, Table, Tag, Button, Modal, Form, Input, Select, message, Space, Popconfirm, QRCode } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined, CopyOutlined, QrcodeOutlined, DownloadOutlined } from '@ant-design/icons'

const { Title } = Typography
const { Option } = Select

interface WireGuardClient {
  id: number
  name: string
  description?: string
  status: string
  public_key?: string
  private_key?: string
  allowed_ips?: string
  server_id?: number
  server_name?: string
  ipv4_address?: string
  ipv6_address?: string
  dns_servers?: string
  mtu?: number
  persistent_keepalive?: number
  created_at?: string
  last_seen?: string
}

interface WireGuardServer {
  id: number
  name: string
  status: string
}

const ClientsPage: React.FC = () => {
  const [loading, setLoading] = useState(false)
  const [clients, setClients] = useState<WireGuardClient[]>([])
  const [servers, setServers] = useState<WireGuardServer[]>([])
  const [modalVisible, setModalVisible] = useState(false)
  const [qrModalVisible, setQrModalVisible] = useState(false)
  const [editingRecord, setEditingRecord] = useState<WireGuardClient | null>(null)
  const [selectedClient, setSelectedClient] = useState<WireGuardClient | null>(null)
  const [form] = Form.useForm()

  const loadClients = async () => {
    setLoading(true)
    try {
      const response = await fetch('/api/v1/clients')
      if (response.ok) {
        const data = await response.json()
        setClients(data.clients || [])
      }
    } catch (error) {
      console.error('加载客户端失败:', error)
      message.error('加载客户端失败')
    } finally {
      setLoading(false)
    }
  }

  const loadServers = async () => {
    try {
      const response = await fetch('/api/v1/servers')
      if (response.ok) {
        const data = await response.json()
        setServers(data.servers || [])
      }
    } catch (error) {
      console.error('加载服务器失败:', error)
    }
  }

  useEffect(() => {
    loadClients()
    loadServers()
  }, [])

  const handleAdd = () => {
    setEditingRecord(null)
    form.resetFields()
    setModalVisible(true)
  }

  const handleEdit = (record: WireGuardClient) => {
    setEditingRecord(record)
    form.setFieldsValue(record)
    setModalVisible(true)
  }

  const handleDelete = async (id: number) => {
    try {
      const response = await fetch(`/api/v1/clients/${id}`, {
        method: 'DELETE'
      })
      if (response.ok) {
        message.success('删除成功')
        loadClients()
      } else {
        message.error('删除失败')
      }
    } catch (error) {
      console.error('删除失败:', error)
      message.error('删除失败')
    }
  }

  const handleSubmit = async (values: any) => {
    try {
      const url = editingRecord 
        ? `/api/v1/clients/${editingRecord.id}`
        : '/api/v1/clients'
      
      const method = editingRecord ? 'PUT' : 'POST'
      
      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(values)
      })

      if (response.ok) {
        message.success(editingRecord ? '更新成功' : '添加成功')
        setModalVisible(false)
        loadClients()
      } else {
        message.error(editingRecord ? '更新失败' : '添加失败')
      }
    } catch (error) {
      console.error('操作失败:', error)
      message.error('操作失败')
    }
  }

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text).then(() => {
      message.success('已复制到剪贴板')
    }).catch(() => {
      message.error('复制失败')
    })
  }

  const showQRCode = (client: WireGuardClient) => {
    setSelectedClient(client)
    setQrModalVisible(true)
  }

  const downloadConfig = (client: WireGuardClient) => {
    const config = `[Interface]
PrivateKey = ${client.private_key}
Address = ${client.ipv4_address || ''}${client.ipv6_address ? ', ' + client.ipv6_address : ''}
DNS = ${client.dns_servers || '8.8.8.8'}
MTU = ${client.mtu || 1420}

[Peer]
PublicKey = ${client.public_key}
AllowedIPs = ${client.allowed_ips || '0.0.0.0/0, ::/0'}
Endpoint = your-server.com:51820
PersistentKeepalive = ${client.persistent_keepalive || 25}`

    const blob = new Blob([config], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${client.name}.conf`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
    message.success('配置文件已下载')
  }

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '名称', dataIndex: 'name', key: 'name' },
    { title: '描述', dataIndex: 'description', key: 'description' },
    { title: '服务器', dataIndex: 'server_name', key: 'server_name' },
    { title: 'IPv4地址', dataIndex: 'ipv4_address', key: 'ipv4_address' },
    { title: 'IPv6地址', dataIndex: 'ipv6_address', key: 'ipv6_address' },
    { 
      title: '状态', 
      dataIndex: 'status', 
      key: 'status', 
      width: 100,
      render: (status: string) => (
        <Tag color={status === 'connected' ? 'green' : 'gray'}>
          {status === 'connected' ? '已连接' : '未连接'}
        </Tag>
      )
    },
    {
      title: '操作',
      key: 'action',
      width: 250,
      render: (_, record: WireGuardClient) => (
        <Space size="small">
          <Button 
            type="link" 
            size="small" 
            icon={<EditOutlined />}
            onClick={() => handleEdit(record)}
          >
            编辑
          </Button>
          <Button 
            type="link" 
            size="small" 
            icon={<CopyOutlined />}
            onClick={() => copyToClipboard(record.public_key || '')}
          >
            复制公钥
          </Button>
          <Button 
            type="link" 
            size="small" 
            icon={<QrcodeOutlined />}
            onClick={() => showQRCode(record)}
          >
            QR码
          </Button>
          <Button 
            type="link" 
            size="small" 
            icon={<DownloadOutlined />}
            onClick={() => downloadConfig(record)}
          >
            下载配置
          </Button>
          <Popconfirm
            title="确定要删除这个客户端吗？"
            onConfirm={() => handleDelete(record.id)}
            okText="确定"
            cancelText="取消"
          >
            <Button 
              type="link" 
              size="small" 
              danger
              icon={<DeleteOutlined />}
            >
              删除
            </Button>
          </Popconfirm>
        </Space>
      )
    }
  ]

  return (
    <div>
      <div className="mb-6 flex justify-between items-center">
        <div>
          <Title level={2}>客户端管理</Title>
          <p className="text-gray-600">管理WireGuard客户端配置</p>
        </div>
        <Button 
          type="primary" 
          icon={<PlusOutlined />}
          onClick={handleAdd}
        >
          添加客户端
        </Button>
      </div>

      <Card>
        <Table
          columns={columns}
          dataSource={clients}
          rowKey="id"
          loading={loading}
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total) => `共 ${total} 条记录`
          }}
          locale={{ emptyText: '暂无客户端' }}
        />
      </Card>

      <Modal
        title={editingRecord ? '编辑客户端' : '添加客户端'}
        open={modalVisible}
        onCancel={() => setModalVisible(false)}
        footer={null}
        width={800}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSubmit}
        >
          <div className="grid grid-cols-2 gap-4">
            <Form.Item
              name="name"
              label="客户端名称"
              rules={[{ required: true, message: '请输入客户端名称' }]}
            >
              <Input placeholder="例如: client1" />
            </Form.Item>

            <Form.Item
              name="server_id"
              label="关联服务器"
              rules={[{ required: true, message: '请选择服务器' }]}
            >
              <Select placeholder="选择服务器">
                {servers.map(server => (
                  <Option key={server.id} value={server.id}>
                    {server.name} ({server.status === 'running' ? '运行中' : '已停止'})
                  </Option>
                ))}
              </Select>
            </Form.Item>
          </div>

          <Form.Item
            name="description"
            label="描述"
          >
            <Input.TextArea 
              placeholder="客户端描述信息"
              rows={2}
            />
          </Form.Item>

          <div className="grid grid-cols-2 gap-4">
            <Form.Item
              name="ipv4_address"
              label="IPv4地址"
              rules={[
                { pattern: /^(\d{1,3}\.){3}\d{1,3}\/\d{1,2}$/, message: '请输入有效的IPv4 CIDR格式' }
              ]}
            >
              <Input placeholder="例如: 10.0.0.2/32" />
            </Form.Item>

            <Form.Item
              name="ipv6_address"
              label="IPv6地址"
              rules={[
                { pattern: /^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\/\d{1,3}$/, message: '请输入有效的IPv6 CIDR格式' }
              ]}
            >
              <Input placeholder="例如: fd00::2/128" />
            </Form.Item>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Form.Item
              name="allowed_ips"
              label="允许的IP"
            >
              <Input placeholder="例如: 0.0.0.0/0, ::/0" />
            </Form.Item>

            <Form.Item
              name="dns_servers"
              label="DNS服务器"
            >
              <Input placeholder="例如: 8.8.8.8, 2001:4860:4860::8888" />
            </Form.Item>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Form.Item
              name="mtu"
              label="MTU"
              rules={[
                { type: 'number', min: 1280, max: 1500, message: 'MTU范围: 1280-1500' }
              ]}
            >
              <InputNumber 
                placeholder="例如: 1420" 
                style={{ width: '100%' }}
                min={1280}
                max={1500}
              />
            </Form.Item>

            <Form.Item
              name="persistent_keepalive"
              label="保持连接间隔"
              rules={[
                { type: 'number', min: 0, max: 65535, message: '间隔范围: 0-65535秒' }
              ]}
            >
              <InputNumber 
                placeholder="例如: 25" 
                style={{ width: '100%' }}
                min={0}
                max={65535}
              />
            </Form.Item>
          </div>

          <Form.Item>
            <Space>
              <Button type="primary" htmlType="submit">
                {editingRecord ? '更新' : '添加'}
              </Button>
              <Button onClick={() => setModalVisible(false)}>
                取消
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>

      <Modal
        title="客户端配置二维码"
        open={qrModalVisible}
        onCancel={() => setQrModalVisible(false)}
        footer={null}
        width={400}
      >
        {selectedClient && (
          <div className="text-center">
            <div className="mb-4">
              <p className="text-lg font-semibold">{selectedClient.name}</p>
              <p className="text-gray-600">{selectedClient.description}</p>
            </div>
            <div className="flex justify-center mb-4">
              <QRCode 
                value={`[Interface]
PrivateKey = ${selectedClient.private_key}
Address = ${selectedClient.ipv4_address || ''}${selectedClient.ipv6_address ? ', ' + selectedClient.ipv6_address : ''}
DNS = ${selectedClient.dns_servers || '8.8.8.8'}
MTU = ${selectedClient.mtu || 1420}

[Peer]
PublicKey = ${selectedClient.public_key}
AllowedIPs = ${selectedClient.allowed_ips || '0.0.0.0/0, ::/0'}
Endpoint = your-server.com:51820
PersistentKeepalive = ${selectedClient.persistent_keepalive || 25}`}
                size={200}
              />
            </div>
            <p className="text-sm text-gray-500">
              使用WireGuard客户端扫描此二维码即可导入配置
            </p>
          </div>
        )}
      </Modal>
    </div>
  )
}

export default ClientsPage
