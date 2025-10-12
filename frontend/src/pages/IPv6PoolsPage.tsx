import React, { useState, useEffect } from 'react'
import { Card, Typography, Table, Tag, Button, Modal, Form, Input, InputNumber, message, Space, Popconfirm, Switch, Badge, Tooltip, Progress, Tabs } from 'antd'
import { 
  PlusOutlined, 
  EditOutlined, 
  DeleteOutlined, 
  GlobalOutlined,
  CheckCircleOutlined,
  ExclamationCircleOutlined,
  CloseCircleOutlined,
  UserOutlined,
  SettingOutlined,
  AlertOutlined
} from '@ant-design/icons'
import { apiClient } from '../services/api'

const { Title } = Typography
const { TabPane } = Tabs

interface IPv6PrefixPool {
  id: string
  name: string
  prefix: string
  prefix_length: number
  total_capacity: number
  used_count: number
  status: string
  description?: string
  auto_announce: boolean
  max_prefix_limit?: number
  whitelist_enabled: boolean
  rpki_enabled: boolean
  enabled: boolean
  created_at: string
  updated_at: string
}

interface IPv6Allocation {
  id: string
  pool_id: string
  client_id?: string
  allocated_prefix: string
  allocated_at: string
  released_at?: string
  is_active: boolean
}

interface IPv6Whitelist {
  id: string
  pool_id: string
  prefix: string
  description?: string
  enabled: boolean
  created_at: string
}

interface BGPAlert {
  id: string
  alert_type: string
  severity: string
  message: string
  prefix?: string
  is_resolved: boolean
  created_at: string
}

const IPv6PoolsPage: React.FC = () => {
  const [loading, setLoading] = useState(false)
  const [pools, setPools] = useState<IPv6PrefixPool[]>([])
  const [allocations, setAllocations] = useState<IPv6Allocation[]>([])
  const [whitelist, setWhitelist] = useState<IPv6Whitelist[]>([])
  const [alerts, setAlerts] = useState<BGPAlert[]>([])
  const [modalVisible, setModalVisible] = useState(false)
  const [whitelistModalVisible, setWhitelistModalVisible] = useState(false)
  const [selectedPool, setSelectedPool] = useState<IPv6PrefixPool | null>(null)
  const [editingRecord, setEditingRecord] = useState<IPv6PrefixPool | null>(null)
  const [form] = Form.useForm()
  const [whitelistForm] = Form.useForm()

  const loadPools = async () => {
    setLoading(true)
    try {
      const response = await apiClient.get('/ipv6/pools')
      setPools(response.data)
    } catch (error) {
      console.error('加载IPv6前缀池失败:', error)
      message.error('加载IPv6前缀池失败')
    } finally {
      setLoading(false)
    }
  }

  const loadPoolDetails = async (poolId: string) => {
    try {
      const [allocationsRes, whitelistRes, alertsRes] = await Promise.all([
        apiClient.get(`/ipv6/pools/${poolId}/allocations`),
        apiClient.get(`/ipv6/pools/${poolId}/whitelist`),
        apiClient.get(`/ipv6/pools/${poolId}/alerts`)
      ])
      
      setAllocations(allocationsRes.data)
      setWhitelist(whitelistRes.data)
      setAlerts(alertsRes.data)
    } catch (error) {
      console.error('加载前缀池详情失败:', error)
      message.error('加载前缀池详情失败')
    }
  }

  useEffect(() => {
    loadPools()
  }, [])

  const handleAdd = () => {
    setEditingRecord(null)
    form.resetFields()
    setModalVisible(true)
  }

  const handleEdit = (record: IPv6PrefixPool) => {
    setEditingRecord(record)
    form.setFieldsValue(record)
    setModalVisible(true)
  }

  const handleDelete = async (id: string) => {
    try {
      await apiClient.delete(`/ipv6/pools/${id}`)
      message.success('删除成功')
      loadPools()
    } catch (error) {
      console.error('删除失败:', error)
      message.error('删除失败')
    }
  }

  const handleSubmit = async (values: any) => {
    try {
      if (editingRecord) {
        await apiClient.put(`/ipv6/pools/${editingRecord.id}`, values)
        message.success('更新成功')
      } else {
        await apiClient.post('/ipv6/pools', values)
        message.success('添加成功')
      }
      setModalVisible(false)
      loadPools()
    } catch (error) {
      console.error('操作失败:', error)
      message.error('操作失败')
    }
  }

  const handleAllocate = async (poolId: string, clientId: string, autoAnnounce: boolean = false) => {
    try {
      const response = await apiClient.post(`/ipv6/pools/${poolId}/allocate`, {
        client_id: clientId,
        auto_announce: autoAnnounce
      })
      message.success(response.data.message)
      loadPoolDetails(poolId)
    } catch (error) {
      console.error('分配前缀失败:', error)
      message.error('分配前缀失败')
    }
  }

  const handleRelease = async (allocationId: string, poolId: string) => {
    try {
      const response = await apiClient.post(`/ipv6/pools/${poolId}/release/${allocationId}`)
      message.success(response.data.message)
      loadPoolDetails(poolId)
    } catch (error) {
      console.error('释放前缀失败:', error)
      message.error('释放前缀失败')
    }
  }

  const handleAddWhitelist = async (values: any) => {
    if (!selectedPool) return

    try {
      await apiClient.post(`/ipv6/pools/${selectedPool.id}/whitelist`, values)
      message.success('白名单条目添加成功')
      setWhitelistModalVisible(false)
      whitelistForm.resetFields()
      loadPoolDetails(selectedPool.id)
    } catch (error) {
      console.error('添加白名单失败:', error)
      message.error('添加白名单失败')
    }
  }

  const handleRemoveWhitelist = async (whitelistId: string) => {
    if (!selectedPool) return

    try {
      await apiClient.delete(`/ipv6/pools/${selectedPool.id}/whitelist/${whitelistId}`)
      message.success('白名单条目删除成功')
      loadPoolDetails(selectedPool.id)
    } catch (error) {
      console.error('删除白名单失败:', error)
      message.error('删除白名单失败')
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'green'
      case 'depleted':
        return 'red'
      case 'maintenance':
        return 'orange'
      case 'disabled':
        return 'default'
      default:
        return 'default'
    }
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active':
        return <CheckCircleOutlined />
      case 'depleted':
        return <CloseCircleOutlined />
      case 'maintenance':
        return <ExclamationCircleOutlined />
      default:
        return <InfoCircleOutlined />
    }
  }

  const getUsagePercentage = (used: number, total: number) => {
    return Math.round((used / total) * 100)
  }

  const getUsageColor = (percentage: number) => {
    if (percentage >= 90) return 'red'
    if (percentage >= 70) return 'orange'
    return 'green'
  }

  const columns = [
    { title: '名称', dataIndex: 'name', key: 'name' },
    { title: '前缀', dataIndex: 'prefix', key: 'prefix' },
    { title: '前缀长度', dataIndex: 'prefix_length', key: 'prefix_length' },
    { 
      title: '使用情况', 
      key: 'usage',
      render: (_: any, record: IPv6PrefixPool) => (
        <div>
          <Progress 
            percent={getUsagePercentage(record.used_count, record.total_capacity)}
            status={record.used_count >= record.total_capacity ? 'exception' : 'active'}
            strokeColor={getUsageColor(getUsagePercentage(record.used_count, record.total_capacity))}
            size="small"
          />
          <div className="text-xs text-gray-500 mt-1">
            {record.used_count} / {record.total_capacity}
          </div>
        </div>
      )
    },
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
      title: '功能', 
      key: 'features',
      render: (_: any, record: IPv6PrefixPool) => (
        <Space direction="vertical" size="small">
          {record.auto_announce && <Tag color="blue" size="small">自动宣告</Tag>}
          {record.whitelist_enabled && <Tag color="green" size="small">白名单</Tag>}
          {record.rpki_enabled && <Tag color="purple" size="small">RPKI</Tag>}
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
      render: (_: any, record: IPv6PrefixPool) => (
        <Space size="small">
          <Tooltip title="查看详情">
            <Button 
              type="link" 
              size="small" 
              icon={<GlobalOutlined />}
              onClick={() => {
                setSelectedPool(record)
                loadPoolDetails(record.id)
              }}
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
            title="确定要删除这个前缀池吗？"
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

  const allocationColumns = [
    { title: '分配前缀', dataIndex: 'allocated_prefix', key: 'allocated_prefix' },
    { title: '客户端ID', dataIndex: 'client_id', key: 'client_id' },
    { title: '分配时间', dataIndex: 'allocated_at', key: 'allocated_at' },
    { title: '释放时间', dataIndex: 'released_at', key: 'released_at' },
    { 
      title: '状态', 
      dataIndex: 'is_active', 
      key: 'is_active',
      render: (isActive: boolean) => (
        <Badge status={isActive ? 'success' : 'default'} text={isActive ? '活跃' : '已释放'} />
      )
    },
    {
      title: '操作',
      key: 'action',
      render: (_: any, record: IPv6Allocation) => (
        record.is_active && selectedPool ? (
          <Popconfirm
            title="确定要释放这个前缀吗？"
            onConfirm={() => handleRelease(record.id, selectedPool.id)}
            okText="确定"
            cancelText="取消"
          >
            <Button type="link" size="small" danger>
              释放
            </Button>
          </Popconfirm>
        ) : null
      )
    }
  ]

  const whitelistColumns = [
    { title: '前缀', dataIndex: 'prefix', key: 'prefix' },
    { title: '描述', dataIndex: 'description', key: 'description' },
    { 
      title: '状态', 
      dataIndex: 'enabled', 
      key: 'enabled',
      render: (enabled: boolean) => (
        <Badge status={enabled ? 'success' : 'default'} text={enabled ? '启用' : '禁用'} />
      )
    },
    { title: '创建时间', dataIndex: 'created_at', key: 'created_at' },
    {
      title: '操作',
      key: 'action',
      render: (_: any, record: IPv6Whitelist) => (
        <Popconfirm
          title="确定要删除这个白名单条目吗？"
          onConfirm={() => handleRemoveWhitelist(record.id)}
          okText="确定"
          cancelText="取消"
        >
          <Button type="link" size="small" danger>
            删除
          </Button>
        </Popconfirm>
      )
    }
  ]

  const alertColumns = [
    { title: '类型', dataIndex: 'alert_type', key: 'alert_type' },
    { 
      title: '严重程度', 
      dataIndex: 'severity', 
      key: 'severity',
      render: (severity: string) => (
        <Tag color={severity === 'CRITICAL' ? 'red' : severity === 'ERROR' ? 'orange' : 'blue'}>
          {severity}
        </Tag>
      )
    },
    { title: '消息', dataIndex: 'message', key: 'message' },
    { title: '前缀', dataIndex: 'prefix', key: 'prefix' },
    { 
      title: '状态', 
      dataIndex: 'is_resolved', 
      key: 'is_resolved',
      render: (isResolved: boolean) => (
        <Badge status={isResolved ? 'success' : 'error'} text={isResolved ? '已解决' : '未解决'} />
      )
    },
    { title: '创建时间', dataIndex: 'created_at', key: 'created_at' }
  ]

  return (
    <div>
      <div className="mb-6 flex justify-between items-center">
        <div>
          <Title level={2}>IPv6前缀池管理</Title>
          <p className="text-gray-600">管理IPv6前缀池和地址分配</p>
        </div>
        <Button 
          type="primary" 
          icon={<PlusOutlined />}
          onClick={handleAdd}
        >
          添加前缀池
        </Button>
      </div>

      <Card>
        <Table
          columns={columns}
          dataSource={pools}
          rowKey="id"
          loading={loading}
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total) => `共 ${total} 条记录`
          }}
          locale={{ emptyText: '暂无IPv6前缀池' }}
        />
      </Card>

      <Modal
        title={editingRecord ? '编辑IPv6前缀池' : '添加IPv6前缀池'}
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
              label="前缀池名称"
              rules={[{ required: true, message: '请输入前缀池名称' }]}
            >
              <Input placeholder="例如: pool-1" />
            </Form.Item>

            <Form.Item
              name="prefix"
              label="基础前缀"
              rules={[{ required: true, message: '请输入基础前缀' }]}
            >
              <Input placeholder="例如: 2001:db8::/48" />
            </Form.Item>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Form.Item
              name="prefix_length"
              label="分配前缀长度"
              rules={[{ required: true, message: '请输入分配前缀长度' }]}
            >
              <InputNumber 
                placeholder="例如: 64" 
                style={{ width: '100%' }}
                min={1}
                max={128}
              />
            </Form.Item>

            <Form.Item
              name="total_capacity"
              label="总容量"
              rules={[{ required: true, message: '请输入总容量' }]}
            >
              <InputNumber 
                placeholder="例如: 1000" 
                style={{ width: '100%' }}
                min={1}
              />
            </Form.Item>
          </div>

          <Form.Item
            name="description"
            label="描述"
          >
            <Input.TextArea 
              placeholder="前缀池描述信息"
              rows={3}
            />
          </Form.Item>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Form.Item
              name="max_prefix_limit"
              label="最大前缀限制"
            >
              <InputNumber 
                placeholder="例如: 100" 
                style={{ width: '100%' }}
                min={1}
              />
            </Form.Item>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <Form.Item
              name="auto_announce"
              label="自动宣告"
              valuePropName="checked"
            >
              <Switch />
            </Form.Item>

            <Form.Item
              name="whitelist_enabled"
              label="启用白名单"
              valuePropName="checked"
            >
              <Switch />
            </Form.Item>

            <Form.Item
              name="rpki_enabled"
              label="启用RPKI"
              valuePropName="checked"
            >
              <Switch />
            </Form.Item>
          </div>

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
        title={`前缀池详情 - ${selectedPool?.name}`}
        open={!!selectedPool}
        onCancel={() => setSelectedPool(null)}
        footer={null}
        width={1000}
      >
        {selectedPool && (
          <Tabs defaultActiveKey="allocations">
            <TabPane tab="分配记录" key="allocations">
              <div className="mb-4 flex justify-between items-center">
                <span>分配记录</span>
                <Button 
                  type="primary" 
                  size="small"
                  onClick={() => {
                    // 这里应该弹出客户端选择对话框
                    message.info('请选择要分配前缀的客户端')
                  }}
                >
                  分配前缀
                </Button>
              </div>
              <Table
                columns={allocationColumns}
                dataSource={allocations}
                rowKey="id"
                pagination={false}
                size="small"
              />
            </TabPane>
            
            <TabPane tab="白名单" key="whitelist">
              <div className="mb-4 flex justify-between items-center">
                <span>白名单条目</span>
                <Button 
                  type="primary" 
                  size="small"
                  onClick={() => setWhitelistModalVisible(true)}
                >
                  添加白名单
                </Button>
              </div>
              <Table
                columns={whitelistColumns}
                dataSource={whitelist}
                rowKey="id"
                pagination={false}
                size="small"
              />
            </TabPane>
            
            <TabPane tab="告警" key="alerts">
              <Table
                columns={alertColumns}
                dataSource={alerts}
                rowKey="id"
                pagination={false}
                size="small"
              />
            </TabPane>
          </Tabs>
        )}
      </Modal>

      <Modal
        title="添加白名单条目"
        open={whitelistModalVisible}
        onCancel={() => setWhitelistModalVisible(false)}
        footer={null}
        width={500}
      >
        <Form
          form={whitelistForm}
          layout="vertical"
          onFinish={handleAddWhitelist}
        >
          <Form.Item
            name="prefix"
            label="前缀"
            rules={[{ required: true, message: '请输入前缀' }]}
          >
            <Input placeholder="例如: 2001:db8::/64" />
          </Form.Item>

          <Form.Item
            name="description"
            label="描述"
          >
            <Input.TextArea 
              placeholder="白名单条目描述"
              rows={3}
            />
          </Form.Item>

          <Form.Item
            name="enabled"
            label="启用状态"
            valuePropName="checked"
            initialValue={true}
          >
            <Switch />
          </Form.Item>

          <Form.Item>
            <Space>
              <Button type="primary" htmlType="submit">
                添加
              </Button>
              <Button onClick={() => setWhitelistModalVisible(false)}>
                取消
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  )
}

export default IPv6PoolsPage
