import React, { useState, useEffect } from 'react'
import { Card, Typography, Table, Tag, Button, Modal, Form, Input, Select, message, Space, Popconfirm, Switch, Tooltip } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined, UserOutlined, MailOutlined, LockOutlined, CrownOutlined, TeamOutlined } from '@ant-design/icons'

const { Title } = Typography
const { Option } = Select

interface User {
  id: number
  username: string
  email: string
  role: string
  status: string
  created_at: string
  updated_at: string
  last_login?: string
  login_count: number
}

interface CreateUserData {
  username: string
  email: string
  password: string
  role: string
  status: string
}

const UsersPage: React.FC = () => {
  const [loading, setLoading] = useState(false)
  const [users, setUsers] = useState<User[]>([])
  const [modalVisible, setModalVisible] = useState(false)
  const [editingRecord, setEditingRecord] = useState<User | null>(null)
  const [form] = Form.useForm()

  const loadUsers = async () => {
    setLoading(true)
    try {
      // 模拟从API获取用户列表
      const mockUsers: User[] = [
        {
          id: 1,
          username: 'admin',
          email: 'admin@ipv6wg.local',
          role: 'admin',
          status: 'active',
          created_at: '2024-01-01T00:00:00Z',
          updated_at: '2024-01-01T00:00:00Z',
          last_login: '2024-01-15T10:30:00Z',
          login_count: 156
        },
        {
          id: 2,
          username: 'operator',
          email: 'operator@ipv6wg.local',
          role: 'operator',
          status: 'active',
          created_at: '2024-01-02T00:00:00Z',
          updated_at: '2024-01-02T00:00:00Z',
          last_login: '2024-01-14T15:20:00Z',
          login_count: 23
        },
        {
          id: 3,
          username: 'viewer',
          email: 'viewer@ipv6wg.local',
          role: 'viewer',
          status: 'inactive',
          created_at: '2024-01-03T00:00:00Z',
          updated_at: '2024-01-03T00:00:00Z',
          last_login: '2024-01-10T09:15:00Z',
          login_count: 8
        }
      ]
      setUsers(mockUsers)
    } catch (error) {
      console.error('加载用户列表失败:', error)
      message.error('加载用户列表失败')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadUsers()
  }, [])

  const handleAdd = () => {
    setEditingRecord(null)
    form.resetFields()
    setModalVisible(true)
  }

  const handleEdit = (record: User) => {
    setEditingRecord(record)
    form.setFieldsValue({
      ...record,
      password: '' // 编辑时不显示密码
    })
    setModalVisible(true)
  }

  const handleDelete = async (id: number) => {
    try {
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      setUsers(users.filter(user => user.id !== id))
      message.success('用户删除成功')
    } catch (error) {
      console.error('删除失败:', error)
      message.error('删除失败')
    }
  }

  const handleToggleStatus = async (id: number, currentStatus: string) => {
    try {
      const newStatus = currentStatus === 'active' ? 'inactive' : 'active'
      
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      setUsers(users.map(user => 
        user.id === id ? { ...user, status: newStatus } : user
      ))
      message.success(`用户已${newStatus === 'active' ? '激活' : '禁用'}`)
    } catch (error) {
      console.error('操作失败:', error)
      message.error('操作失败')
    }
  }

  const handleSubmit = async (values: any) => {
    try {
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      if (editingRecord) {
        // 更新用户
        const updatedUser = { ...editingRecord, ...values }
        setUsers(users.map(user => 
          user.id === editingRecord.id ? updatedUser : user
        ))
        message.success('用户更新成功')
      } else {
        // 创建用户
        const newUser: User = {
          id: Date.now(),
          ...values,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          login_count: 0
        }
        setUsers([...users, newUser])
        message.success('用户创建成功')
      }
      
      setModalVisible(false)
    } catch (error) {
      console.error('操作失败:', error)
      message.error('操作失败')
    }
  }

  const getRoleColor = (role: string) => {
    switch (role) {
      case 'admin': return 'red'
      case 'operator': return 'blue'
      case 'viewer': return 'green'
      default: return 'default'
    }
  }

  const getRoleIcon = (role: string) => {
    switch (role) {
      case 'admin': return <CrownOutlined />
      case 'operator': return <TeamOutlined />
      case 'viewer': return <UserOutlined />
      default: return <UserOutlined />
    }
  }

  const getStatusColor = (status: string) => {
    return status === 'active' ? 'green' : 'red'
  }

  const columns = [
    { 
      title: 'ID', 
      dataIndex: 'id', 
      key: 'id', 
      width: 60 
    },
    { 
      title: '用户名', 
      dataIndex: 'username', 
      key: 'username',
      render: (text: string, record: User) => (
        <Space>
          {getRoleIcon(record.role)}
          <span>{text}</span>
        </Space>
      )
    },
    { 
      title: '邮箱', 
      dataIndex: 'email', 
      key: 'email' 
    },
    { 
      title: '角色', 
      dataIndex: 'role', 
      key: 'role',
      render: (role: string) => (
        <Tag color={getRoleColor(role)} icon={getRoleIcon(role)}>
          {role === 'admin' ? '管理员' : role === 'operator' ? '操作员' : '查看者'}
        </Tag>
      )
    },
    { 
      title: '状态', 
      dataIndex: 'status', 
      key: 'status',
      render: (status: string) => (
        <Tag color={getStatusColor(status)}>
          {status === 'active' ? '活跃' : '禁用'}
        </Tag>
      )
    },
    { 
      title: '最后登录', 
      dataIndex: 'last_login', 
      key: 'last_login',
      render: (date: string) => date ? new Date(date).toLocaleString() : '从未登录'
    },
    { 
      title: '登录次数', 
      dataIndex: 'login_count', 
      key: 'login_count' 
    },
    {
      title: '操作',
      key: 'action',
      width: 200,
      render: (_, record: User) => (
        <Space size="small">
          <Tooltip title={record.status === 'active' ? '禁用用户' : '激活用户'}>
            <Button 
              type="link" 
              size="small" 
              onClick={() => handleToggleStatus(record.id, record.status)}
            >
              {record.status === 'active' ? '禁用' : '激活'}
            </Button>
          </Tooltip>
          <Button 
            type="link" 
            size="small" 
            icon={<EditOutlined />}
            onClick={() => handleEdit(record)}
          >
            编辑
          </Button>
          {record.role !== 'admin' && (
            <Popconfirm
              title="确定要删除这个用户吗？"
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
          )}
        </Space>
      )
    }
  ]

  return (
    <div>
      <div className="mb-6 flex justify-between items-center">
        <div>
          <Title level={2}>用户管理</Title>
          <p className="text-gray-600">管理系统用户和权限</p>
        </div>
        <Button 
          type="primary" 
          icon={<PlusOutlined />}
          onClick={handleAdd}
        >
          添加用户
        </Button>
      </div>

      <Card>
        <Table
          columns={columns}
          dataSource={users}
          rowKey="id"
          loading={loading}
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total) => `共 ${total} 个用户`
          }}
          locale={{ emptyText: '暂无用户' }}
        />
      </Card>

      <Modal
        title={editingRecord ? '编辑用户' : '添加用户'}
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
          <Form.Item
            name="username"
            label="用户名"
            rules={[
              { required: true, message: '请输入用户名' },
              { min: 3, max: 20, message: '用户名长度应为3-20个字符' },
              { pattern: /^[a-zA-Z0-9_]+$/, message: '用户名只能包含字母、数字和下划线' }
            ]}
          >
            <Input 
              prefix={<UserOutlined />} 
              placeholder="请输入用户名" 
              disabled={!!editingRecord}
            />
          </Form.Item>

          <Form.Item
            name="email"
            label="邮箱地址"
            rules={[
              { required: true, message: '请输入邮箱地址' },
              { type: 'email', message: '请输入有效的邮箱地址' }
            ]}
          >
            <Input prefix={<MailOutlined />} placeholder="请输入邮箱地址" />
          </Form.Item>

          {!editingRecord && (
            <Form.Item
              name="password"
              label="密码"
              rules={[
                { required: true, message: '请输入密码' },
                { min: 6, message: '密码长度至少6个字符' },
                { pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, message: '密码必须包含大小写字母和数字' }
              ]}
            >
              <Input.Password prefix={<LockOutlined />} placeholder="请输入密码" />
            </Form.Item>
          )}

          <Form.Item
            name="role"
            label="角色"
            rules={[{ required: true, message: '请选择角色' }]}
          >
            <Select placeholder="选择用户角色">
              <Option value="admin">
                <Space>
                  <CrownOutlined />
                  管理员 - 完全访问权限
                </Space>
              </Option>
              <Option value="operator">
                <Space>
                  <TeamOutlined />
                  操作员 - 管理服务器和客户端
                </Space>
              </Option>
              <Option value="viewer">
                <Space>
                  <UserOutlined />
                  查看者 - 只读权限
                </Space>
              </Option>
            </Select>
          </Form.Item>

          <Form.Item
            name="status"
            label="状态"
            rules={[{ required: true, message: '请选择状态' }]}
          >
            <Select placeholder="选择用户状态">
              <Option value="active">活跃</Option>
              <Option value="inactive">禁用</Option>
            </Select>
          </Form.Item>

          <Form.Item>
            <Space>
              <Button type="primary" htmlType="submit">
                {editingRecord ? '更新' : '创建'}
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

export default UsersPage
