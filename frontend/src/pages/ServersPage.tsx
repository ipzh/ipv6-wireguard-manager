import React, { useState, useEffect } from 'react'
import { Card, Typography, Table, Tag, Button, Modal, Form, Input, InputNumber, message, Space, Popconfirm, Switch } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined, PlayCircleOutlined, PauseCircleOutlined, CopyOutlined } from '@ant-design/icons'

const { Title } = Typography

interface WireGuardServer {
  id: number
  name: string
  description?: string
  status: string
  listen_port: number
  private_key?: string
  public_key?: string
  ipv4_address?: string
  ipv6_address?: string
  allowed_ips?: string
  dns_servers?: string
  mtu?: number
  persistent_keepalive?: number
}

const ServersPage: React.FC = () => {
  const [loading, setLoading] = useState(false)
  const [servers, setServers] = useState<WireGuardServer[]>([])
  const [modalVisible, setModalVisible] = useState(false)
  const [editingRecord, setEditingRecord] = useState<WireGuardServer | null>(null)
  const [form] = Form.useForm()

  const loadServers = async () => {
    setLoading(true)
    try {
      const response = await fetch('/api/v1/servers')
      if (response.ok) {
        const data = await response.json()
        setServers(data.servers || [])
      }
    } catch (error) {
      console.error('加载服务器失败:', error)
      message.error('加载服务器失败')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadServers()
  }, [])

  const handleAdd = () => {
    setEditingRecord(null)
    form.resetFields()
    setModalVisible(true)
  }

  const handleEdit = (record: WireGuardServer) => {
    setEditingRecord(record)
    form.setFieldsValue(record)
    setModalVisible(true)
  }

  const handleDelete = async (id: number) => {
    try {
      const response = await fetch(`/api/v1/servers/${id}`, {
        method: 'DELETE'
      })
      if (response.ok) {
        message.success('删除成功')
        loadServers()
      } else {
        message.error('删除失败')
      }
    } catch (error) {
      console.error('删除失败:', error)
      message.error('删除失败')
    }
  }

  const handleToggleStatus = async (id: number, currentStatus: string) => {
    try {
      const newStatus = currentStatus === 'running' ? 'stopped' : 'running'
      const response = await fetch(`/api/v1/servers/${id}/status`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ status: newStatus })
      })
      if (response.ok) {
        message.success(`服务器已${newStatus === 'running' ? '启动' : '停止'}`)
        loadServers()
      } else {
        message.error('操作失败')
      }
    } catch (error) {
      console.error('操作失败:', error)
      message.error('操作失败')
    }
  }

  const handleSubmit = async (values: any) => {
    try {
      const url = editingRecord 
        ? `/api/v1/servers/${editingRecord.id}`
        : '/api/v1/servers'
      
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
        loadServers()
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

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '名称', dataIndex: 'name', key: 'name' },
    { title: '描述', dataIndex: 'description', key: 'description' },
    { title: '监听端口', dataIndex: 'listen_port', key: 'listen_port' },
    { title: 'IPv4地址', dataIndex: 'ipv4_address', key: 'ipv4_address' },
    { title: 'IPv6地址', dataIndex: 'ipv6_address', key: 'ipv6_address' },
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
    },
    {
      title: '操作',
      key: 'action',
      width: 200,
      render: (_, record: WireGuardServer) => (
        <Space size="small">
          <Button 
            type="link" 
            size="small" 
            icon={record.status === 'running' ? <PauseCircleOutlined /> : <PlayCircleOutlined />}
            onClick={() => handleToggleStatus(record.id, record.status)}
          >
            {record.status === 'running' ? '停止' : '启动'}
          </Button>
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
          <Popconfirm
            title="确定要删除这个服务器吗？"
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
          <Title level={2}>服务器管理</Title>
          <p className="text-gray-600">管理WireGuard服务器配置</p>
        </div>
        <Button 
          type="primary" 
          icon={<PlusOutlined />}
          onClick={handleAdd}
        >
          添加服务器
        </Button>
      </div>

      <Card>
        <Table
          columns={columns}
          dataSource={servers}
          rowKey="id"
          loading={loading}
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total) => `共 ${total} 条记录`
          }}
          locale={{ emptyText: '暂无服务器' }}
        />
      </Card>

      <Modal
        title={editingRecord ? '编辑服务器' : '添加服务器'}
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
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Form.Item
              name="name"
              label="服务器名称"
              rules={[{ required: true, message: '请输入服务器名称' }]}
            >
              <Input placeholder="例如: wg0" />
            </Form.Item>

            <Form.Item
              name="listen_port"
              label="监听端口"
              rules={[
                { required: true, message: '请输入监听端口' },
                { type: 'number', min: 1024, max: 65535, message: '端口范围: 1024-65535' }
              ]}
            >
              <InputNumber 
                placeholder="例如: 51820" 
                style={{ width: '100%' }}
                min={1024}
                max={65535}
              />
            </Form.Item>
          </div>

          <Form.Item
            name="description"
            label="描述"
          >
            <Input.TextArea 
              placeholder="服务器描述信息"
              rows={2}
            />
          </Form.Item>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Form.Item
              name="ipv4_address"
              label="IPv4地址"
              rules={[
                { pattern: /^(\d{1,3}\.){3}\d{1,3}\/\d{1,2}$/, message: '请输入有效的IPv4 CIDR格式' }
              ]}
            >
              <Input placeholder="例如: 10.0.0.1/24" />
            </Form.Item>

            <Form.Item
              name="ipv6_address"
              label="IPv6地址"
              rules={[
                { pattern: /^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\/\d{1,3}$/, message: '请输入有效的IPv6 CIDR格式' }
              ]}
            >
              <Input placeholder="例如: fd00::1/64" />
            </Form.Item>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
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

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
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
    </div>
  )
}

export default ServersPage
