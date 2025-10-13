import React, { useState, useEffect } from 'react'
import { Card, Typography, Row, Col, Statistic, Table, Tag, Button, Spin, Alert, Progress, Timeline, message } from 'antd'
import { 
  DashboardOutlined, 
  AlertOutlined, 
  LineChartOutlined, 
  ReloadOutlined,
  CheckCircleOutlined,
  ExclamationCircleOutlined,
  InfoCircleOutlined
} from '@ant-design/icons'
import { apiClient } from '../services/api'

const { Title } = Typography

interface SystemMetrics {
  timestamp: string
  cpu_usage: number
  memory_usage: number
  disk_usage: number
  network_sent: number
  network_recv: number
  load_average: {
    '1min': number
    '5min': number
    '15min': number
  }
}

interface Alert {
  id: string
  severity: string
  message: string
  source: string
  timestamp: string
  resolved: boolean
  details?: any
}

const MonitoringPage: React.FC = () => {
  const [loading, setLoading] = useState(true)
  const [metrics, setMetrics] = useState<SystemMetrics | null>(null)
  const [alerts, setAlerts] = useState<Alert[]>([])
  const [metricsHistory, setMetricsHistory] = useState<SystemMetrics[]>([])

  const loadData = async () => {
    setLoading(true)
    try {
      // 加载当前指标
      const metricsResponse = await apiClient.get('/monitoring/metrics')
      setMetrics(metricsResponse.data)

      // 加载告警信息
      const alertsResponse = await apiClient.get('/monitoring/alerts')
      setAlerts(alertsResponse.data.alerts || [])

      // 加载历史指标
      const historyResponse = await apiClient.get('/monitoring/metrics/history?hours=24')
      setMetricsHistory(historyResponse.data || [])
    } catch (error) {
      console.error('加载监控数据失败:', error)
      message.error('加载监控数据失败')
    } finally {
      setLoading(false)
    }
  }

  const resolveAlert = async (alertId: string) => {
    try {
      await apiClient.post(`/monitoring/alerts/${alertId}/resolve`)
      message.success('告警已解决')
      loadData()
    } catch (error) {
      console.error('解决告警失败:', error)
      message.error('解决告警失败')
    }
  }

  useEffect(() => {
    loadData()
    
    // 每30秒自动刷新数据
    const interval = setInterval(loadData, 30000)
    return () => clearInterval(interval)
  }, [])

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'red'
      case 'warning': return 'orange'
      case 'info': return 'blue'
      default: return 'gray'
    }
  }

  const getSeverityIcon = (severity: string) => {
    switch (severity) {
      case 'critical': return <ExclamationCircleOutlined />
      case 'warning': return <ExclamationCircleOutlined />
      case 'info': return <InfoCircleOutlined />
      default: return <InfoCircleOutlined />
    }
  }

  const alertColumns = [
    { 
      title: '严重程度', 
      dataIndex: 'severity', 
      key: 'severity',
      width: 100,
      render: (severity: string) => (
        <Tag color={getSeverityColor(severity)} icon={getSeverityIcon(severity)}>
          {severity === 'critical' ? '严重' : severity === 'warning' ? '警告' : '信息'}
        </Tag>
      )
    },
    { title: '消息', dataIndex: 'message', key: 'message' },
    { title: '来源', dataIndex: 'source', key: 'source', width: 100 },
    { 
      title: '时间', 
      dataIndex: 'timestamp', 
      key: 'timestamp',
      width: 180,
      render: (timestamp: string) => new Date(timestamp).toLocaleString()
    },
    { 
      title: '状态', 
      dataIndex: 'resolved', 
      key: 'resolved',
      width: 80,
      render: (resolved: boolean) => (
        <Tag color={resolved ? 'green' : 'red'}>
          {resolved ? '已解决' : '未解决'}
        </Tag>
      )
    },
    {
      title: '操作',
      key: 'action',
      width: 100,
      render: (_, record: Alert) => (
        !record.resolved && (
          <Button 
            type="link" 
            size="small" 
            onClick={() => resolveAlert(record.id)}
          >
            解决
          </Button>
        )
      )
    }
  ]

  if (loading && !metrics) {
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
          <Title level={2}>系统监控</Title>
          <p className="text-gray-600">实时监控系统性能和状态</p>
        </div>
        <Button 
          icon={<ReloadOutlined />} 
          onClick={loadData}
          loading={loading}
        >
          刷新
        </Button>
      </div>

      {/* 系统指标概览 */}
      <Row gutter={16} className="mb-6">
        <Col span={6}>
          <Card>
            <Statistic
              title="CPU使用率"
              value={metrics?.cpu_usage || 0}
              suffix="%"
              valueStyle={{ color: (metrics?.cpu_usage || 0) > 80 ? '#cf1322' : '#3f8600' }}
              prefix={<DashboardOutlined />}
            />
            <Progress 
              percent={metrics?.cpu_usage || 0} 
              status={(metrics?.cpu_usage || 0) > 80 ? 'exception' : 'normal'}
              size="small"
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card>
            <Statistic
              title="内存使用率"
              value={metrics?.memory_usage || 0}
              suffix="%"
              valueStyle={{ color: (metrics?.memory_usage || 0) > 80 ? '#cf1322' : '#3f8600' }}
              prefix={<DashboardOutlined />}
            />
            <Progress 
              percent={metrics?.memory_usage || 0} 
              status={(metrics?.memory_usage || 0) > 80 ? 'exception' : 'normal'}
              size="small"
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card>
            <Statistic
              title="磁盘使用率"
              value={metrics?.disk_usage || 0}
              suffix="%"
              valueStyle={{ color: (metrics?.disk_usage || 0) > 80 ? '#cf1322' : '#3f8600' }}
              prefix={<DashboardOutlined />}
            />
            <Progress 
              percent={metrics?.disk_usage || 0} 
              status={(metrics?.disk_usage || 0) > 80 ? 'exception' : 'normal'}
              size="small"
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card>
            <Statistic
              title="活跃告警"
              value={alerts.filter(a => !a.resolved).length}
              suffix={`/ ${alerts.length}`}
              valueStyle={{ color: alerts.filter(a => !a.resolved).length > 0 ? '#cf1322' : '#3f8600' }}
              prefix={<AlertOutlined />}
            />
          </Card>
        </Col>
      </Row>

      {/* 告警信息 */}
      <Card 
        title={
          <span>
            <AlertOutlined className="mr-2" />
            系统告警
          </span>
        }
        className="mb-6"
        extra={
          <span>
            严重: <Tag color="red">{alerts.filter(a => a.severity === 'critical' && !a.resolved).length}</Tag>
            警告: <Tag color="orange">{alerts.filter(a => a.severity === 'warning' && !a.resolved).length}</Tag>
          </span>
        }
      >
        <Table
          columns={alertColumns}
          dataSource={alerts}
          rowKey="id"
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total) => `共 ${total} 条告警`
          }}
          locale={{ emptyText: '暂无告警' }}
        />
      </Card>

      {/* 系统负载趋势 */}
      <Card 
        title={
          <span>
            <LineChartOutlined className="mr-2" />
            系统负载趋势 (24小时)
          </span>
        }
      >
        {metricsHistory.length > 0 ? (
          <Timeline>
            {metricsHistory.slice(-10).map((metric, index) => (
              <Timeline.Item key={index} color={metric.cpu_usage > 80 ? 'red' : 'green'}>
                <p>{new Date(metric.timestamp).toLocaleString()}</p>
                <p>CPU: {metric.cpu_usage}% | 内存: {metric.memory_usage}% | 磁盘: {metric.disk_usage}%</p>
              </Timeline.Item>
            ))}
          </Timeline>
        ) : (
          <div className="text-center py-8 text-gray-500">
            <p>暂无历史数据</p>
          </div>
        )}
      </Card>
    </div>
  )
}

export default MonitoringPage
