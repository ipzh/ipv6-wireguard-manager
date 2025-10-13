import React, { useState, useEffect } from 'react';
import {
  Card,
  Row,
  Col,
  Statistic,
  Progress,
  Table,
  Tag,
  Button,
  DatePicker,
  Select,
  Space,
  Alert,
  Spin,
  Tooltip,
  Badge
} from 'antd';
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RechartsTooltip,
  Legend,
  ResponsiveContainer
} from 'recharts';
import {
  DashboardOutlined,
  ServerOutlined,
  NetworkOutlined,
  AlertOutlined,
  ReloadOutlined,
  DownloadOutlined,
  SettingOutlined
} from '@ant-design/icons';
import { useSystemMetrics, useWireGuardStatus, useAlerts } from '../hooks/useWebSocketOptimized';
import dayjs from 'dayjs';

const { RangePicker } = DatePicker;
const { Option } = Select;

interface DashboardData {
  systemMetrics: any;
  wireguardStatus: any;
  alerts: any[];
  historicalData: any[];
}

const AdvancedDashboard: React.FC = () => {
  const [dashboardData, setDashboardData] = useState<DashboardData>({
    systemMetrics: null,
    wireguardStatus: null,
    alerts: [],
    historicalData: []
  });
  const [timeRange, setTimeRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().subtract(1, 'hour'),
    dayjs()
  ]);
  const [refreshInterval, setRefreshInterval] = useState<number>(30);
  const [loading, setLoading] = useState<boolean>(false);
  const [autoRefresh, setAutoRefresh] = useState<boolean>(true);

  // WebSocket hooks
  const systemMetrics = useSystemMetrics();
  const wireguardStatus = useWireGuardStatus();
  const alerts = useAlerts();

  // 更新仪表板数据
  useEffect(() => {
    setDashboardData(prev => ({
      ...prev,
      systemMetrics: systemMetrics.metrics,
      wireguardStatus: wireguardStatus.status,
      alerts: alerts.alerts
    }));
  }, [systemMetrics.metrics, wireguardStatus.status, alerts.alerts]);

  // 自动刷新
  useEffect(() => {
    if (!autoRefresh) return;

    const interval = setInterval(() => {
      refreshData();
    }, refreshInterval * 1000);

    return () => clearInterval(interval);
  }, [autoRefresh, refreshInterval]);

  const refreshData = async () => {
    setLoading(true);
    try {
      // 这里可以添加获取历史数据的API调用
      await new Promise(resolve => setTimeout(resolve, 1000)); // 模拟API调用
    } catch (error) {
      console.error('刷新数据失败:', error);
    } finally {
      setLoading(false);
    }
  };

  const exportData = () => {
    const dataStr = JSON.stringify(dashboardData, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `dashboard-data-${dayjs().format('YYYY-MM-DD-HH-mm-ss')}.json`;
    link.click();
    URL.revokeObjectURL(url);
  };

  // 系统指标图表数据
  const systemChartData = dashboardData.systemMetrics ? [
    {
      name: 'CPU',
      value: dashboardData.systemMetrics.cpu?.percent || 0,
      color: '#1890ff'
    },
    {
      name: 'Memory',
      value: dashboardData.systemMetrics.memory?.percent || 0,
      color: '#52c41a'
    },
    {
      name: 'Disk',
      value: dashboardData.systemMetrics.disk?.percent || 0,
      color: '#faad14'
    }
  ] : [];

  // WireGuard状态数据
  const wireguardChartData = dashboardData.wireguardStatus ? [
    {
      name: 'Connected',
      value: dashboardData.wireguardStatus.connected_peers || 0,
      color: '#52c41a'
    },
    {
      name: 'Disconnected',
      value: (dashboardData.wireguardStatus.total_peers || 0) - (dashboardData.wireguardStatus.connected_peers || 0),
      color: '#ff4d4f'
    }
  ] : [];

  // 告警统计
  const alertStats = {
    total: dashboardData.alerts.length,
    critical: dashboardData.alerts.filter(alert => alert.severity === 'critical').length,
    high: dashboardData.alerts.filter(alert => alert.severity === 'high').length,
    medium: dashboardData.alerts.filter(alert => alert.severity === 'medium').length,
    low: dashboardData.alerts.filter(alert => alert.severity === 'low').length
  };

  return (
    <div style={{ padding: '24px' }}>
      {/* 头部控制栏 */}
      <Card style={{ marginBottom: '24px' }}>
        <Row justify="space-between" align="middle">
          <Col>
            <Space>
              <DashboardOutlined style={{ fontSize: '24px', color: '#1890ff' }} />
              <h2 style={{ margin: 0 }}>高级仪表板</h2>
            </Space>
          </Col>
          <Col>
            <Space>
              <RangePicker
                value={timeRange}
                onChange={(dates) => setTimeRange(dates as [dayjs.Dayjs, dayjs.Dayjs])}
                showTime
                format="YYYY-MM-DD HH:mm:ss"
              />
              <Select
                value={refreshInterval}
                onChange={setRefreshInterval}
                style={{ width: 120 }}
              >
                <Option value={10}>10秒</Option>
                <Option value={30}>30秒</Option>
                <Option value={60}>1分钟</Option>
                <Option value={300}>5分钟</Option>
              </Select>
              <Button
                type={autoRefresh ? 'primary' : 'default'}
                onClick={() => setAutoRefresh(!autoRefresh)}
                icon={<ReloadOutlined />}
              >
                {autoRefresh ? '自动刷新' : '手动刷新'}
              </Button>
              <Button
                onClick={refreshData}
                loading={loading}
                icon={<ReloadOutlined />}
              >
                刷新
              </Button>
              <Button
                onClick={exportData}
                icon={<DownloadOutlined />}
              >
                导出数据
              </Button>
              <Button icon={<SettingOutlined />}>
                设置
              </Button>
            </Space>
          </Col>
        </Row>
      </Card>

      {/* 系统概览 */}
      <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
        <Col xs={24} sm={12} md={6}>
          <Card>
            <Statistic
              title="系统状态"
              value={dashboardData.systemMetrics ? '正常' : '未知'}
              prefix={<ServerOutlined />}
              valueStyle={{ color: dashboardData.systemMetrics ? '#3f8600' : '#cf1322' }}
            />
            <Progress
              percent={dashboardData.systemMetrics?.cpu?.percent || 0}
              size="small"
              status={dashboardData.systemMetrics?.cpu?.percent > 80 ? 'exception' : 'normal'}
            />
            <div style={{ fontSize: '12px', color: '#666', marginTop: '8px' }}>
              CPU使用率
            </div>
          </Card>
        </Col>
        <Col xs={24} sm={12} md={6}>
          <Card>
            <Statistic
              title="WireGuard状态"
              value={dashboardData.wireguardStatus?.connected_peers || 0}
              suffix={`/ ${dashboardData.wireguardStatus?.total_peers || 0}`}
              prefix={<NetworkOutlined />}
              valueStyle={{ color: '#3f8600' }}
            />
            <Progress
              percent={dashboardData.wireguardStatus ? 
                (dashboardData.wireguardStatus.connected_peers / dashboardData.wireguardStatus.total_peers) * 100 : 0}
              size="small"
            />
            <div style={{ fontSize: '12px', color: '#666', marginTop: '8px' }}>
              连接状态
            </div>
          </Card>
        </Col>
        <Col xs={24} sm={12} md={6}>
          <Card>
            <Statistic
              title="活跃告警"
              value={alertStats.total}
              prefix={<AlertOutlined />}
              valueStyle={{ color: alertStats.total > 0 ? '#cf1322' : '#3f8600' }}
            />
            <div style={{ marginTop: '8px' }}>
              <Space size="small">
                {alertStats.critical > 0 && <Tag color="red">严重: {alertStats.critical}</Tag>}
                {alertStats.high > 0 && <Tag color="orange">高: {alertStats.high}</Tag>}
                {alertStats.medium > 0 && <Tag color="blue">中: {alertStats.medium}</Tag>}
                {alertStats.low > 0 && <Tag color="green">低: {alertStats.low}</Tag>}
              </Space>
            </div>
          </Card>
        </Col>
        <Col xs={24} sm={12} md={6}>
          <Card>
            <Statistic
              title="网络流量"
              value={dashboardData.wireguardStatus?.total_rx_formatted || '0 B'}
              suffix="接收"
              valueStyle={{ color: '#1890ff' }}
            />
            <div style={{ fontSize: '12px', color: '#666', marginTop: '8px' }}>
              发送: {dashboardData.wireguardStatus?.total_tx_formatted || '0 B'}
            </div>
          </Card>
        </Col>
      </Row>

      {/* 图表区域 */}
      <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
        <Col xs={24} lg={12}>
          <Card title="系统资源使用率" extra={<Badge status="processing" text="实时" />}>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={systemChartData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {systemChartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <RechartsTooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </Card>
        </Col>
        <Col xs={24} lg={12}>
          <Card title="WireGuard连接状态" extra={<Badge status="processing" text="实时" />}>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={wireguardChartData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {wireguardChartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <RechartsTooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </Card>
        </Col>
      </Row>

      {/* 历史趋势图 */}
      <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
        <Col xs={24}>
          <Card title="系统性能趋势" extra={<Badge status="processing" text="实时" />}>
            <ResponsiveContainer width="100%" height={400}>
              <LineChart data={dashboardData.historicalData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="time" />
                <YAxis />
                <RechartsTooltip />
                <Legend />
                <Line type="monotone" dataKey="cpu" stroke="#1890ff" strokeWidth={2} />
                <Line type="monotone" dataKey="memory" stroke="#52c41a" strokeWidth={2} />
                <Line type="monotone" dataKey="disk" stroke="#faad14" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </Card>
        </Col>
      </Row>

      {/* 告警列表 */}
      <Row gutter={[16, 16]}>
        <Col xs={24}>
          <Card title="最新告警" extra={<Badge count={alertStats.total} />}>
            <Table
              dataSource={dashboardData.alerts.slice(0, 10)}
              columns={[
                {
                  title: '时间',
                  dataIndex: 'timestamp',
                  key: 'timestamp',
                  render: (timestamp) => dayjs(timestamp).format('YYYY-MM-DD HH:mm:ss')
                },
                {
                  title: '严重程度',
                  dataIndex: 'severity',
                  key: 'severity',
                  render: (severity) => {
                    const colors = {
                      critical: 'red',
                      high: 'orange',
                      medium: 'blue',
                      low: 'green'
                    };
                    return <Tag color={colors[severity as keyof typeof colors]}>{severity}</Tag>;
                  }
                },
                {
                  title: '类型',
                  dataIndex: 'type',
                  key: 'type'
                },
                {
                  title: '描述',
                  dataIndex: 'message',
                  key: 'message',
                  ellipsis: true
                },
                {
                  title: '状态',
                  dataIndex: 'status',
                  key: 'status',
                  render: (status) => (
                    <Tag color={status === 'active' ? 'red' : 'green'}>{status}</Tag>
                  )
                },
                {
                  title: '操作',
                  key: 'action',
                  render: (_, record) => (
                    <Space>
                      <Button size="small" type="link">查看详情</Button>
                      <Button size="small" type="link">处理</Button>
                    </Space>
                  )
                }
              ]}
              pagination={false}
              size="small"
            />
          </Card>
        </Col>
      </Row>
    </div>
  );
};

export default AdvancedDashboard;
