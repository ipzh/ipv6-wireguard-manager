import React, { useState, useEffect } from 'react'
import { Card, Typography, Table, Tag, Button, Modal, Form, Input, InputNumber, message, Space, Popconfirm, Switch, Badge, Tooltip } from 'antd'
import { 
  PlusOutlined, 
  EditOutlined, 
  DeleteOutlined, 
  ReloadOutlined, 
  PlayCircleOutlined, 
  PauseCircleOutlined,
  InfoCircleOutlined,
  HistoryOutlined,
  CheckCircleOutlined,
  ExclamationCircleOutlined,
  CloseCircleOutlined
} from '@ant-design/icons'
import { apiClient } from '../services/api'

const { Title } = Typography

interface BGPSession {
  id: string
  name: string
  neighbor: string
  remote_as: number
  hold_time?: number
  description?: string
  enabled: boolean
  status: string
  uptime: number
  prefixes_received: number
  prefixes_sent: number
  created_at: string
  updated_at: string
}

interface BGPOperation {
  id: string
  operation_type: string
  status: string
  message?: string
  error_details?: string
  started_at: string
  completed_at?: string
}

const BGPSessionsPage: React.FC = () => {
  const [loading, setLoading] = useState(false)
  const [sessions, setSessions] = useState<BGPSession[]>([])
  const [selectedSessions, setSelectedSessions] = useState<string[]>([])
  const [modalVisible, setModalVisible] = useState(false)
  const [operationsModalVisible, setOperationsModalVisible] = useState(false)
  const [editingRecord, setEditingRecord] = useState<BGPSession | null>(null)
  const [operations, setOperations] = useState<BGPOperation[]>([])
  const [form] = Form.useForm()

  const loadSessions = async () => {
    setLoading(true)
    try {
      const response = await apiClient.get('/bgp/sessions')
      setSessions(response.data)
    } catch (error) {
      console.error('加载BGP会话失败:', error)
      message.error('加载BGP会话失败')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadSessions()
  }, [])

  const handleAdd = () => {
    setEditingRecord(null)
    form.resetFields()
    setModalVisible(true)
  }

  const handleEdit = (record: BGPSession) => {
    setEditingRecord(record)
    form.setFieldsValue(record)
    setModalVisible(true)
  }

  const handleDelete = async (id: string) => {
    try {
      await apiClient.delete(`/bgp/sessions/${id}`)
      message.success('删除成功')
      loadSessions()
    } catch (error) {
      console.error('删除失败:', error)
      message.error('删除失败')
    }
  }

  const handleSubmit = async (values: any) => {
    try {
      if (editingRecord) {
        await apiClient.put(`/bgp/sessions/${editingRecord.id}`, values)
        message.success('更新成功')
      } else {
        await apiClient.post('/bgp/sessions', values)
        message.success('添加成功')
      }
      setModalVisible(false)
      loadSessions()
    } catch (error) {
      console.error('操作失败:', error)
      message.error('操作失败')
    }
  }

  const handleReload = async (id: string) => {
    try {
      const response = await apiClient.post(`/bgp/sessions/${id}/reload`)
      message.success(response.data.message)
      loadSessions()
    } catch (error) {
      console.error('重载失败:', error)
      message.error('重载失败')
    }
  }

  const handleRestart = async (id: string) => {
    try {
      const response = await apiClient.post(`/bgp/sessions/${id}/restart`)
      message.success(response.data.message)
      loadSessions()
    } catch (error) {
      console.error('重启失败:', error)
      message.error('重启失败')
    }
  }

  const handleBatchReload = async () => {
    if (selectedSessions.length === 0) {
      message.warning('请选择要重载的会话')
      return
    }

    try {
      const response = await apiClient.post('/bgp/sessions/batch/reload', selectedSessions)
      message.success('批量重载完成')
      loadSessions()
    } catch (error) {
      console.error('批量重载失败:', error)
      message.error('批量重载失败')
    }
  }

  const handleBatchRestart = async () => {
    if (selectedSessions.length === 0) {
      message.warning('请选择要重启的会话')
      return
    }

    try {
      const response = await apiClient.post('/bgp/sessions/batch/restart', selectedSessions)
      message.success('批量重启完成')
      loadSessions()
    } catch (error) {
      console.error('批量重启失败:', error)
      message.error('批量重启失败')
    }
  }

  const showOperations = async (sessionId: string) => {
    try {
      const response = await apiClient.get(`/bgp/sessions/${sessionId}/operations`)
      setOperations(response.data)
      setOperationsModalVisible(true)
    } catch (error) {
      console.error('加载操作历史失败:', error)
      message.error('加载操作历史失败')
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'established':
        return 'green'
      case 'idle':
        return 'red'
      case 'connect':
      case 'active':
        return 'orange'
      case 'opensent':
      case 'openconfirm':
        return 'blue'
      default:
        return 'default'
    }
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'established':
        return <CheckCircleOutlined />
      case 'idle':
        return <CloseCircleOutlined />
      case 'connect':
      case 'active':
        return <ExclamationCircleOutlined />
      default:
        return <InfoCircleOutlined />
    }
  }

  const formatUptime = (seconds: number) => {
    const days = Math.floor(seconds / 86400)
    const hours = Math.floor((seconds % 86400) / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    
    if (days > 0) {
      return `${days}天${hours}小时${minutes}分钟`
    } else if (hours > 0) {
      return `${hours}小时${minutes}分钟`
    } else {
      return `${minutes}分钟`
    }
  }

  const columns = [
    {
      title: '选择',
      key: 'select',
      width: 50,
      render: (_: any, record: BGPSession) => (
        <input
          type="checkbox"
          checked={selectedSessions.includes(record.id)}
          onChange={(e) => {
            if (e.target.checked) {
              setSelectedSessions([...selectedSessions, record.id])
            } else {
              setSelectedSessions(selectedSessions.filter(id => id !== record.id))
            }
          }}
        />
      )
    },
    { title: '名称', dataIndex: 'name', key: 'name' },
    { title: '邻居', dataIndex: 'neighbor', key: 'neighbor' },
    { title: '远程AS', dataIndex: 'remote_as', key: 'remote_as' },
    { 
      title: '状态', 
      dataIndex: 'status', 
      key: 'status',
      render: (status: string) => (
        <Tag color={getStatusColor(status)} icon={getStatusIcon(status)}>
          {status.toUpperCase()}
        </Tag>
      )
    },
    { 
      title: '运行时间', 
      dataIndex: 'uptime', 
      key: 'uptime',
      render: (uptime: number) => formatUptime(uptime)
    },
    { 
      title: '前缀统计', 
      key: 'prefixes',
      render: (_: any, record: BGPSession) => (
        <Space direction="vertical" size="small">
          <div>接收: {record.prefixes_received}</div>
          <div>发送: {record.prefixes_sent}</div>
        </Space>
      )
    },
    { 
      title: '启用状态', 
      dataIndex: 'enabled', 
      key: 'enabled',
      render: (enabled: boolean) => (
        <Badge status={enabled ? 'success' : 'default'} text={enabled ? '启用' : '禁用'} />
      )
    },
    {
      title: '操作',
      key: 'action',
      width: 200,
      render: (_: any, record: BGPSession) => (
        <Space size="small">
          <Tooltip title="重载配置">
            <Button 
              type="link" 
              size="small" 
              icon={<ReloadOutlined />}
              onClick={() => handleReload(record.id)}
            />
          </Tooltip>
          <Tooltip title="重启会话">
            <Button 
              type="link" 
              size="small" 
              icon={<PlayCircleOutlined />}
              onClick={() => handleRestart(record.id)}
            />
          </Tooltip>
          <Tooltip title="操作历史">
            <Button 
              type="link" 
              size="small" 
              icon={<HistoryOutlined />}
              onClick={() => showOperations(record.id)}
            />
          </Tooltip>
          <Tooltip title="编辑">
            <Button 
              type="link" 
              size="small" 
              icon={<EditOutlined />}
              onClick={() => handleEdit(record)}
            />
          </Tooltip>
          <Popconfirm
            title="确定要删除这个BGP会话吗？"
            onConfirm={() => handleDelete(record.id)}
            okText="确定"
            cancelText="取消"
          >
            <Tooltip title="删除">
              <Button 
                type="link" 
                size="small" 
                danger
                icon={<DeleteOutlined />}
              />
            </Tooltip>
          </Popconfirm>
        </Space>
      )
    }
  ]

  return (
    <div>
      <div className="mb-6 flex justify-between items-center">
        <div>
          <Title level={2}>BGP会话管理</Title>
          <p className="text-gray-600">管理BGP会话配置和状态</p>
        </div>
        <Space>
          <Button 
            type="default" 
            icon={<ReloadOutlined />}
            onClick={handleBatchReload}
            disabled={selectedSessions.length === 0}
          >
            批量重载
          </Button>
          <Button 
            type="default" 
            icon={<PlayCircleOutlined />}
            onClick={handleBatchRestart}
            disabled={selectedSessions.length === 0}
          >
            批量重启
          </Button>
          <Button 
            type="primary" 
            icon={<PlusOutlined />}
            onClick={handleAdd}
          >
            添加会话
          </Button>
        </Space>
      </div>

      <Card>
        <Table
          columns={columns}
          dataSource={sessions}
          rowKey="id"
          loading={loading}
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total) => `共 ${total} 条记录`
          }}
          locale={{ emptyText: '暂无BGP会话' }}
        />
      </Card>

      <Modal
        title={editingRecord ? '编辑BGP会话' : '添加BGP会话'}
        open={modalVisible}
        onCancel={() => setModalVisible(false)}
        footer={null}
        width={600}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSubmit}
        >
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Form.Item
              name="name"
              label="会话名称"
              rules={[{ required: true, message: '请输入会话名称' }]}
            >
              <Input placeholder="例如: peer-1" />
            </Form.Item>

            <Form.Item
              name="neighbor"
              label="邻居地址"
              rules={[{ required: true, message: '请输入邻居地址' }]}
            >
              <Input placeholder="例如: 192.168.1.2" />
            </Form.Item>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Form.Item
              name="remote_as"
              label="远程AS号"
              rules={[{ required: true, message: '请输入远程AS号' }]}
            >
              <InputNumber 
                placeholder="例如: 65002" 
                style={{ width: '100%' }}
                min={1}
                max={4294967295}
              />
            </Form.Item>

            <Form.Item
              name="hold_time"
              label="保持时间"
            >
              <InputNumber 
                placeholder="例如: 180" 
                style={{ width: '100%' }}
                min={0}
                max={65535}
              />
            </Form.Item>
          </div>

          <Form.Item
            name="password"
            label="密码"
          >
            <Input.Password placeholder="BGP会话密码（可选）" />
          </Form.Item>

          <Form.Item
            name="description"
            label="描述"
          >
            <Input.TextArea 
              placeholder="会话描述信息"
              rows={3}
            />
          </Form.Item>

          <Form.Item
            name="enabled"
            label="启用状态"
            valuePropName="checked"
          >
            <Switch />
          </Form.Item>

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
        title="操作历史"
        open={operationsModalVisible}
        onCancel={() => setOperationsModalVisible(false)}
        footer={null}
        width={800}
      >
        <Table
          columns={[
            { title: '操作类型', dataIndex: 'operation_type', key: 'operation_type' },
            { 
              title: '状态', 
              dataIndex: 'status', 
              key: 'status',
              render: (status: string) => (
                <Tag color={status === 'SUCCESS' ? 'green' : status === 'FAILED' ? 'red' : 'orange'}>
                  {status}
                </Tag>
              )
            },
            { title: '消息', dataIndex: 'message', key: 'message' },
            { title: '开始时间', dataIndex: 'started_at', key: 'started_at' },
            { title: '完成时间', dataIndex: 'completed_at', key: 'completed_at' }
          ]}
          dataSource={operations}
          rowKey="id"
          pagination={false}
          size="small"
        />
      </Modal>
    </div>
  )
}

export default BGPSessionsPage
