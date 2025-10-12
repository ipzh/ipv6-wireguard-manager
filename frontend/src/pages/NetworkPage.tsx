import React, { useState, useEffect } from 'react'
import { Card, Typography, Table, Tag, Button, Modal, Form, Input, InputNumber, message, Space, Popconfirm } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined, GlobalOutlined } from '@ant-design/icons'

const { Title } = Typography

interface BGPAnnouncement {
  id: number
  prefix: string
  asn: number
  status: string
  next_hop?: string
  description?: string
}

const NetworkPage: React.FC = () => {
  const [loading, setLoading] = useState(false)
  const [bgpAnnouncements, setBgpAnnouncements] = useState<BGPAnnouncement[]>([])
  const [modalVisible, setModalVisible] = useState(false)
  const [editingRecord, setEditingRecord] = useState<BGPAnnouncement | null>(null)
  const [form] = Form.useForm()

  const loadBGPAnnouncements = async () => {
    setLoading(true)
    try {
      const response = await fetch('/api/v1/bgp/announcements')
      if (response.ok) {
        const data = await response.json()
        setBgpAnnouncements(data.announcements || [])
      }
    } catch (error) {
      console.error('加载BGP宣告失败:', error)
      message.error('加载BGP宣告失败')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadBGPAnnouncements()
  }, [])

  const handleAdd = () => {
    setEditingRecord(null)
    form.resetFields()
    setModalVisible(true)
  }

  const handleEdit = (record: BGPAnnouncement) => {
    setEditingRecord(record)
    form.setFieldsValue(record)
    setModalVisible(true)
  }

  const handleDelete = async (id: number) => {
    try {
      const response = await fetch(`/api/v1/bgp/announcements/${id}`, {
        method: 'DELETE'
      })
      if (response.ok) {
        message.success('删除成功')
        loadBGPAnnouncements()
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
        ? `/api/v1/bgp/announcements/${editingRecord.id}`
        : '/api/v1/bgp/announcements'
      
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
        loadBGPAnnouncements()
      } else {
        message.error(editingRecord ? '更新失败' : '添加失败')
      }
    } catch (error) {
      console.error('操作失败:', error)
      message.error('操作失败')
    }
  }

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '前缀', dataIndex: 'prefix', key: 'prefix' },
    { title: 'ASN', dataIndex: 'asn', key: 'asn' },
    { title: '下一跳', dataIndex: 'next_hop', key: 'next_hop' },
    { title: '描述', dataIndex: 'description', key: 'description' },
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
    },
    {
      title: '操作',
      key: 'action',
      width: 150,
      render: (_, record: BGPAnnouncement) => (
        <Space size="small">
          <Button 
            type="link" 
            size="small" 
            icon={<EditOutlined />}
            onClick={() => handleEdit(record)}
          >
            编辑
          </Button>
          <Popconfirm
            title="确定要删除这个BGP宣告吗？"
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
          <Title level={2}>网络管理</Title>
          <p className="text-gray-600">管理BGP宣告和网络配置</p>
        </div>
        <Button 
          type="primary" 
          icon={<PlusOutlined />}
          onClick={handleAdd}
        >
          添加BGP宣告
        </Button>
      </div>

      <Card>
        <Table
          columns={columns}
          dataSource={bgpAnnouncements}
          rowKey="id"
          loading={loading}
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total) => `共 ${total} 条记录`
          }}
          locale={{ emptyText: '暂无BGP宣告' }}
        />
      </Card>

      <Modal
        title={editingRecord ? '编辑BGP宣告' : '添加BGP宣告'}
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
            name="prefix"
            label="IP前缀"
            rules={[
              { required: true, message: '请输入IP前缀' },
              { pattern: /^(\d{1,3}\.){3}\d{1,3}\/\d{1,2}$|^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\/\d{1,3}$/, message: '请输入有效的IP前缀格式' }
            ]}
          >
            <Input placeholder="例如: 192.168.1.0/24 或 2001:db8::/32" />
          </Form.Item>

          <Form.Item
            name="asn"
            label="ASN"
            rules={[
              { required: true, message: '请输入ASN' },
              { type: 'number', min: 1, max: 4294967295, message: '请输入有效的ASN' }
            ]}
          >
            <InputNumber 
              placeholder="例如: 65001" 
              style={{ width: '100%' }}
              min={1}
              max={4294967295}
            />
          </Form.Item>

          <Form.Item
            name="next_hop"
            label="下一跳"
            rules={[
              { pattern: /^(\d{1,3}\.){3}\d{1,3}$|^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$/, message: '请输入有效的IP地址' }
            ]}
          >
            <Input placeholder="例如: 192.168.1.1 或 2001:db8::1" />
          </Form.Item>

          <Form.Item
            name="description"
            label="描述"
          >
            <Input.TextArea 
              placeholder="BGP宣告的描述信息"
              rows={3}
            />
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
    </div>
  )
}

export default NetworkPage
