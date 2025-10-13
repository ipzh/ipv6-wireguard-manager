import React, { useState, useEffect } from 'react'
import { 
  Card, 
  Typography, 
  Table, 
  Tag, 
  Button, 
  Input, 
  Select, 
  DatePicker, 
  Space, 
  Modal, 
  message, 
  Spin, 
  Popconfirm,
  Row,
  Col,
  Tooltip,
  Badge
} from 'antd'
import { 
  SearchOutlined, 
  ReloadOutlined, 
  DeleteOutlined, 
  EyeOutlined,
  ClearOutlined,
  FilterOutlined,
  FileTextOutlined
} from '@ant-design/icons'
import { apiClient } from '../services/api'
import dayjs from 'dayjs'

const { Title } = Typography
const { Option } = Select
const { RangePicker } = DatePicker

interface LogEntry {
  id: string
  timestamp: string
  level: string
  source: string
  message: string
  details?: any
}

const LogsPage: React.FC = () => {
  const [loading, setLoading] = useState(true)
  const [logs, setLogs] = useState<LogEntry[]>([])
  const [total, setTotal] = useState(0)
  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 20,
    total: 0
  })
  const [filters, setFilters] = useState({
    level: '',
    source: '',
    keyword: '',
    startDate: '',
    endDate: ''
  })
  const [selectedLog, setSelectedLog] = useState<LogEntry | null>(null)
  const [detailModalVisible, setDetailModalVisible] = useState(false)

  const loadLogs = async (page = 1, pageSize = 20) => {
    setLoading(true)
    try {
      const params = new URLSearchParams({
        page: page.toString(),
        size: pageSize.toString(),
        ...(filters.level && { level: filters.level }),
        ...(filters.source && { source: filters.source }),
        ...(filters.keyword && { keyword: filters.keyword }),
        ...(filters.startDate && { start_date: filters.startDate }),
        ...(filters.endDate && { end_date: filters.endDate })
      })

      const response = await apiClient.get(`/logs?${params}`)
      setLogs(response.data.logs || [])
      setTotal(response.data.total || 0)
      setPagination({
        current: page,
        pageSize,
        total: response.data.total || 0
      })
    } catch (error) {
      console.error('加载日志失败:', error)
      message.error('加载日志失败')
    } finally {
      setLoading(false)
    }
  }

  const viewLogDetail = async (logId: string) => {
    try {
      const response = await apiClient.get(`/logs/${logId}`)
      setSelectedLog(response.data)
      setDetailModalVisible(true)
    } catch (error) {
      console.error('获取日志详情失败:', error)
      message.error('获取日志详情失败')
    }
  }

  const deleteLog = async (logId: string) => {
    try {
      await apiClient.delete(`/logs/${logId}`)
      message.success('日志删除成功')
      loadLogs(pagination.current, pagination.pageSize)
    } catch (error) {
      console.error('删除日志失败:', error)
      message.error('删除日志失败')
    }
  }

  const clearLogs = async () => {
    try {
      await apiClient.delete('/logs')
      message.success('日志清空成功')
      loadLogs(1, pagination.pageSize)
    } catch (error) {
      console.error('清空日志失败:', error)
      message.error('清空日志失败')
    }
  }

  const handleSearch = () => {
    loadLogs(1, pagination.pageSize)
  }

  const handleReset = () => {
    setFilters({
      level: '',
      source: '',
      keyword: '',
      startDate: '',
      endDate: ''
    })
    loadLogs(1, pagination.pageSize)
  }

  const handleTableChange = (pagination: any) => {
    loadLogs(pagination.current, pagination.pageSize)
  }

  useEffect(() => {
    loadLogs()
  }, [])

  const getLevelColor = (level: string) => {
    switch (level.toLowerCase()) {
      case 'error': return 'red'
      case 'warning': return 'orange'
      case 'info': return 'blue'
      case 'debug': return 'purple'
      default: return 'gray'
    }
  }

  const getLevelText = (level: string) => {
    switch (level.toLowerCase()) {
      case 'error': return '错误'
      case 'warning': return '警告'
      case 'info': return '信息'
      case 'debug': return '调试'
      default: return level
    }
  }

  const columns = [
    {
      title: '时间',
      dataIndex: 'timestamp',
      key: 'timestamp',
      width: 180,
      render: (timestamp: string) => dayjs(timestamp).format('YYYY-MM-DD HH:mm:ss')
    },
    {
      title: '级别',
      dataIndex: 'level',
      key: 'level',
      width: 100,
      render: (level: string) => (
        <Tag color={getLevelColor(level)}>
          {getLevelText(level)}
        </Tag>
      )
    },
    {
      title: '来源',
      dataIndex: 'source',
      key: 'source',
      width: 120
    },
    {
      title: '消息',
      dataIndex: 'message',
      key: 'message',
      ellipsis: true,
      render: (message: string) => (
        <Tooltip title={message}>
          <span>{message}</span>
        </Tooltip>
      )
    },
    {
      title: '操作',
      key: 'action',
      width: 120,
      render: (_, record: LogEntry) => (
        <Space size="small">
          <Button 
            type="link" 
            size="small" 
            icon={<EyeOutlined />}
            onClick={() => viewLogDetail(record.id)}
          >
            详情
          </Button>
          <Popconfirm
            title="确定删除这条日志吗？"
            onConfirm={() => deleteLog(record.id)}
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

  const levelCounts = logs.reduce((acc, log) => {
    acc[log.level] = (acc[log.level] || 0) + 1
    return acc
  }, {} as Record<string, number>)

  return (
    <div>
      <div className="mb-6 flex justify-between items-center">
        <div>
          <Title level={2}>日志管理</Title>
          <p className="text-gray-600">查看和管理系统日志</p>
        </div>
        <div className="flex items-center space-x-2">
          <Badge count={total} showZero>
            <Button 
              icon={<ReloadOutlined />} 
              onClick={() => loadLogs(pagination.current, pagination.pageSize)}
              loading={loading}
            >
              刷新
            </Button>
          </Badge>
          <Popconfirm
            title="确定清空所有日志吗？此操作不可恢复"
            onConfirm={clearLogs}
            okText="确定"
            cancelText="取消"
          >
            <Button 
              icon={<ClearOutlined />} 
              danger
            >
              清空日志
            </Button>
          </Popconfirm>
        </div>
      </div>

      {/* 统计信息 */}
      <Row gutter={16} className="mb-6">
        <Col span={6}>
          <Card size="small">
            <div className="flex justify-between items-center">
              <span>总日志数</span>
              <Badge count={total} showZero style={{ backgroundColor: '#1890ff' }} />
            </div>
          </Card>
        </Col>
        {Object.entries(levelCounts).map(([level, count]) => (
          <Col span={6} key={level}>
            <Card size="small">
              <div className="flex justify-between items-center">
                <span>{getLevelText(level)}</span>
                <Badge 
                  count={count} 
                  showZero 
                  style={{ backgroundColor: getLevelColor(level) }} 
                />
              </div>
            </Card>
          </Col>
        ))}
      </Row>

      {/* 筛选条件 */}
      <Card className="mb-6">
        <div className="flex flex-wrap gap-4 items-end">
          <div>
            <div className="text-sm text-gray-500 mb-1">级别</div>
            <Select
              value={filters.level}
              onChange={(value) => setFilters({...filters, level: value})}
              placeholder="选择级别"
              style={{ width: 120 }}
              allowClear
            >
              <Option value="error">错误</Option>
              <Option value="warning">警告</Option>
              <Option value="info">信息</Option>
              <Option value="debug">调试</Option>
            </Select>
          </div>
          
          <div>
            <div className="text-sm text-gray-500 mb-1">来源</div>
            <Input
              value={filters.source}
              onChange={(e) => setFilters({...filters, source: e.target.value})}
              placeholder="输入来源"
              style={{ width: 150 }}
            />
          </div>
          
          <div>
            <div className="text-sm text-gray-500 mb-1">关键词</div>
            <Input
              value={filters.keyword}
              onChange={(e) => setFilters({...filters, keyword: e.target.value})}
              placeholder="搜索消息内容"
              style={{ width: 200 }}
              prefix={<SearchOutlined />}
            />
          </div>
          
          <div>
            <div className="text-sm text-gray-500 mb-1">时间范围</div>
            <RangePicker
              showTime
              format="YYYY-MM-DD HH:mm:ss"
              onChange={(dates) => {
                setFilters({
                  ...filters,
                  startDate: dates?.[0]?.format('YYYY-MM-DD HH:mm:ss') || '',
                  endDate: dates?.[1]?.format('YYYY-MM-DD HH:mm:ss') || ''
                })
              }}
            />
          </div>
          
          <div className="flex space-x-2">
            <Button 
              type="primary" 
              icon={<FilterOutlined />}
              onClick={handleSearch}
            >
              筛选
            </Button>
            <Button 
              icon={<ReloadOutlined />}
              onClick={handleReset}
            >
              重置
            </Button>
          </div>
        </div>
      </Card>

      {/* 日志表格 */}
      <Card>
        <Table
          columns={columns}
          dataSource={logs}
          rowKey="id"
          loading={loading}
          pagination={{
            ...pagination,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total) => `共 ${total} 条日志`,
            pageSizeOptions: ['10', '20', '50', '100']
          }}
          onChange={handleTableChange}
          locale={{ emptyText: '暂无日志数据' }}
        />
      </Card>

      {/* 日志详情模态框 */}
      <Modal
        title={
          <span>
            <FileTextOutlined className="mr-2" />
            日志详情
          </span>
        }
        open={detailModalVisible}
        onCancel={() => setDetailModalVisible(false)}
        footer={[
          <Button key="close" onClick={() => setDetailModalVisible(false)}>
            关闭
          </Button>
        ]}
        width={800}
      >
        {selectedLog && (
          <div className="space-y-4">
            <div>
              <strong>时间:</strong> {dayjs(selectedLog.timestamp).format('YYYY-MM-DD HH:mm:ss')}
            </div>
            <div>
              <strong>级别:</strong> <Tag color={getLevelColor(selectedLog.level)}>
                {getLevelText(selectedLog.level)}
              </Tag>
            </div>
            <div>
              <strong>来源:</strong> {selectedLog.source}
            </div>
            <div>
              <strong>消息:</strong> 
              <div className="mt-2 p-3 bg-gray-50 rounded">
                {selectedLog.message}
              </div>
            </div>
            {selectedLog.details && (
              <div>
                <strong>详细信息:</strong>
                <pre className="mt-2 p-3 bg-gray-50 rounded text-sm overflow-auto">
                  {JSON.stringify(selectedLog.details, null, 2)}
                </pre>
              </div>
            )}
          </div>
        )}
      </Modal>
    </div>
  )
}

export default LogsPage
