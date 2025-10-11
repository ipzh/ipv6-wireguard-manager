# IPv6 WireGuard Manager - 前端设计文档

## 📋 设计概述

### 设计理念
- **现代化**: 采用最新的前端技术和设计趋势
- **用户友好**: 直观易用的界面设计
- **响应式**: 支持各种设备和屏幕尺寸
- **高性能**: 快速加载，流畅交互
- **可访问性**: 符合无障碍访问标准

### 技术栈选择

#### 核心框架
| 技术 | 版本 | 选择理由 |
|------|------|----------|
| **React** | 18.2+ | 成熟稳定，生态丰富，性能优秀 |
| **TypeScript** | 5.0+ | 类型安全，开发效率，代码质量 |
| **Vite** | 5.0+ | 快速构建，热更新，现代化工具链 |
| **React Router** | 6.8+ | 声明式路由，代码分割，懒加载 |

#### UI组件库
| 技术 | 版本 | 选择理由 |
|------|------|----------|
| **Ant Design** | 5.8+ | 企业级组件库，设计规范，功能完整 |
| **Ant Design Pro** | 2.0+ | 企业级模板，开箱即用 |
| **Styled Components** | 6.0+ | CSS-in-JS，组件化样式 |
| **Tailwind CSS** | 3.3+ | 原子化CSS，快速开发 |

#### 状态管理
| 技术 | 版本 | 选择理由 |
|------|------|----------|
| **Redux Toolkit** | 1.9+ | 状态管理，时间旅行调试 |
| **RTK Query** | 1.9+ | 服务端状态管理，缓存优化 |
| **Zustand** | 4.4+ | 轻量级状态管理，简单易用 |

#### 数据可视化
| 技术 | 版本 | 选择理由 |
|------|------|----------|
| **Chart.js** | 4.4+ | 轻量级图表库，易于使用 |
| **Recharts** | 2.8+ | React图表库，组件化 |
| **D3.js** | 7.8+ | 强大的数据可视化库 |

#### 开发工具
| 技术 | 版本 | 选择理由 |
|------|------|----------|
| **ESLint** | 8.50+ | 代码质量检查 |
| **Prettier** | 3.0+ | 代码格式化 |
| **Husky** | 8.0+ | Git钩子管理 |
| **Jest** | 29.7+ | 单元测试框架 |
| **Testing Library** | 14.0+ | React组件测试 |

---

## 🎨 设计系统

### 1. 色彩系统

#### 主色调
```css
:root {
  /* 主色 */
  --primary-color: #1890ff;
  --primary-hover: #40a9ff;
  --primary-active: #096dd9;
  
  /* 辅助色 */
  --secondary-color: #52c41a;
  --secondary-hover: #73d13d;
  --secondary-active: #389e0d;
  
  /* 功能色 */
  --success-color: #52c41a;
  --warning-color: #faad14;
  --error-color: #ff4d4f;
  --info-color: #1890ff;
  
  /* 中性色 */
  --text-primary: #262626;
  --text-secondary: #595959;
  --text-disabled: #bfbfbf;
  --border-color: #d9d9d9;
  --background-color: #f5f5f5;
}
```

#### 暗色主题
```css
[data-theme="dark"] {
  --primary-color: #177ddc;
  --text-primary: #ffffff;
  --text-secondary: #a6a6a6;
  --background-color: #141414;
  --border-color: #434343;
}
```

### 2. 字体系统

#### 字体族
```css
:root {
  --font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 
                 'Helvetica Neue', Arial, 'Noto Sans', sans-serif;
  --font-family-mono: 'SFMono-Regular', Consolas, 'Liberation Mono', 
                      Menlo, Courier, monospace;
}
```

#### 字体大小
```css
:root {
  --font-size-xs: 12px;
  --font-size-sm: 14px;
  --font-size-base: 16px;
  --font-size-lg: 18px;
  --font-size-xl: 20px;
  --font-size-2xl: 24px;
  --font-size-3xl: 30px;
  --font-size-4xl: 36px;
}
```

### 3. 间距系统

#### 间距规范
```css
:root {
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-base: 16px;
  --spacing-lg: 24px;
  --spacing-xl: 32px;
  --spacing-2xl: 48px;
  --spacing-3xl: 64px;
}
```

### 4. 阴影系统

#### 阴影层级
```css
:root {
  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow-base: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
}
```

---

## 🏗️ 项目结构

### 目录结构
```
src/
├── components/           # 通用组件
│   ├── common/          # 基础组件
│   │   ├── Button/
│   │   ├── Input/
│   │   ├── Modal/
│   │   ├── Table/
│   │   └── Loading/
│   ├── layout/          # 布局组件
│   │   ├── Header/
│   │   ├── Sidebar/
│   │   ├── Footer/
│   │   └── Breadcrumb/
│   ├── forms/           # 表单组件
│   │   ├── ClientForm/
│   │   ├── ServerForm/
│   │   ├── UserForm/
│   │   └── ConfigForm/
│   ├── charts/          # 图表组件
│   │   ├── SystemMetrics/
│   │   ├── NetworkStats/
│   │   ├── ClientStats/
│   │   └── TrafficChart/
│   └── tables/          # 表格组件
│       ├── ClientTable/
│       ├── LogTable/
│       ├── UserTable/
│       └── AuditTable/
├── pages/               # 页面组件
│   ├── Dashboard/
│   ├── Clients/
│   ├── Servers/
│   ├── Network/
│   ├── Monitoring/
│   ├── Logs/
│   ├── Users/
│   ├── Settings/
│   └── Login/
├── hooks/               # 自定义Hooks
│   ├── useAuth.ts
│   ├── useWebSocket.ts
│   ├── useApi.ts
│   ├── useLocalStorage.ts
│   └── useDebounce.ts
├── services/            # API服务
│   ├── api.ts
│   ├── auth.ts
│   ├── wireguard.ts
│   ├── network.ts
│   ├── monitoring.ts
│   └── websocket.ts
├── store/               # 状态管理
│   ├── index.ts
│   ├── authSlice.ts
│   ├── clientSlice.ts
│   ├── serverSlice.ts
│   └── uiSlice.ts
├── utils/               # 工具函数
│   ├── constants.ts
│   ├── helpers.ts
│   ├── validators.ts
│   ├── formatters.ts
│   └── permissions.ts
├── types/               # 类型定义
│   ├── api.ts
│   ├── auth.ts
│   ├── wireguard.ts
│   ├── network.ts
│   └── common.ts
├── styles/              # 样式文件
│   ├── globals.css
│   ├── variables.css
│   ├── components.css
│   └── themes.css
├── assets/              # 静态资源
│   ├── images/
│   ├── icons/
│   └── fonts/
└── __tests__/           # 测试文件
    ├── components/
    ├── pages/
    ├── hooks/
    └── utils/
```

---

## 📱 页面设计

### 1. 登录页面

#### 设计要点
- **简洁设计**: 突出登录表单，减少干扰
- **品牌展示**: 显示产品logo和名称
- **响应式**: 适配各种屏幕尺寸
- **安全提示**: 显示安全相关信息

#### 组件结构
```tsx
// LoginPage.tsx
const LoginPage: React.FC = () => {
  const [form] = Form.useForm();
  const navigate = useNavigate();
  const dispatch = useAppDispatch();

  const handleLogin = async (values: LoginFormData) => {
    try {
      await dispatch(login(values)).unwrap();
      navigate('/dashboard');
    } catch (error) {
      message.error('登录失败，请检查用户名和密码');
    }
  };

  return (
    <div className="login-page">
      <div className="login-container">
        <div className="login-header">
          <img src="/logo.svg" alt="IPv6 WireGuard Manager" />
          <h1>IPv6 WireGuard Manager</h1>
          <p>企业级VPN管理平台</p>
        </div>
        
        <Card className="login-form-card">
          <Form
            form={form}
            name="login"
            onFinish={handleLogin}
            layout="vertical"
            size="large"
          >
            <Form.Item
              name="username"
              label="用户名"
              rules={[{ required: true, message: '请输入用户名' }]}
            >
              <Input
                prefix={<UserOutlined />}
                placeholder="请输入用户名"
                autoComplete="username"
              />
            </Form.Item>
            
            <Form.Item
              name="password"
              label="密码"
              rules={[{ required: true, message: '请输入密码' }]}
            >
              <Input.Password
                prefix={<LockOutlined />}
                placeholder="请输入密码"
                autoComplete="current-password"
              />
            </Form.Item>
            
            <Form.Item>
              <Button
                type="primary"
                htmlType="submit"
                className="login-button"
                block
                loading={isLoading}
              >
                登录
              </Button>
            </Form.Item>
          </Form>
          
          <div className="login-footer">
            <Checkbox>记住密码</Checkbox>
            <a href="/forgot-password">忘记密码？</a>
          </div>
        </Card>
      </div>
    </div>
  );
};
```

#### 样式设计
```css
.login-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--spacing-base);
}

.login-container {
  width: 100%;
  max-width: 400px;
}

.login-header {
  text-align: center;
  margin-bottom: var(--spacing-2xl);
  color: white;
}

.login-header img {
  width: 64px;
  height: 64px;
  margin-bottom: var(--spacing-base);
}

.login-header h1 {
  font-size: var(--font-size-2xl);
  font-weight: 600;
  margin-bottom: var(--spacing-sm);
}

.login-form-card {
  box-shadow: var(--shadow-xl);
  border-radius: 12px;
  padding: var(--spacing-2xl);
}

.login-button {
  height: 48px;
  font-size: var(--font-size-lg);
  font-weight: 500;
}

.login-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: var(--spacing-lg);
}
```

### 2. 仪表板页面

#### 设计要点
- **信息概览**: 显示关键系统信息
- **实时数据**: 实时更新系统状态
- **快捷操作**: 常用功能快捷入口
- **图表展示**: 可视化性能数据

#### 组件结构
```tsx
// DashboardPage.tsx
const DashboardPage: React.FC = () => {
  const { data: systemInfo, isLoading } = useGetSystemInfoQuery();
  const { data: metrics } = useGetMetricsQuery();
  const { data: clients } = useGetClientsQuery();

  return (
    <div className="dashboard-page">
      <PageHeader
        title="仪表板"
        subTitle="系统概览和关键指标"
        extra={[
          <Button key="refresh" icon={<ReloadOutlined />} onClick={() => window.location.reload()}>
            刷新
          </Button>
        ]}
      />
      
      <Row gutter={[16, 16]}>
        {/* 系统状态卡片 */}
        <Col xs={24} sm={12} lg={6}>
          <Card className="status-card">
            <Statistic
              title="系统状态"
              value={systemInfo?.status}
              valueStyle={{ color: systemInfo?.status === 'healthy' ? '#52c41a' : '#ff4d4f' }}
              prefix={<CheckCircleOutlined />}
            />
          </Card>
        </Col>
        
        <Col xs={24} sm={12} lg={6}>
          <Card className="status-card">
            <Statistic
              title="在线客户端"
              value={clients?.filter(c => c.status === 'connected').length}
              suffix={`/ ${clients?.length || 0}`}
              prefix={<UserOutlined />}
            />
          </Card>
        </Col>
        
        <Col xs={24} sm={12} lg={6}>
          <Card className="status-card">
            <Statistic
              title="CPU使用率"
              value={metrics?.cpu_usage}
              suffix="%"
              prefix={<CpuOutlined />}
            />
          </Card>
        </Col>
        
        <Col xs={24} sm={12} lg={6}>
          <Card className="status-card">
            <Statistic
              title="内存使用率"
              value={metrics?.memory_usage}
              suffix="%"
              prefix={<MemoryOutlined />}
            />
          </Card>
        </Col>
      </Row>
      
      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        {/* 性能图表 */}
        <Col xs={24} lg={16}>
          <Card title="系统性能" className="chart-card">
            <SystemMetricsChart data={metrics} />
          </Card>
        </Col>
        
        {/* 客户端状态 */}
        <Col xs={24} lg={8}>
          <Card title="客户端状态" className="chart-card">
            <ClientStatusChart data={clients} />
          </Card>
        </Col>
      </Row>
      
      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        {/* 快捷操作 */}
        <Col xs={24} lg={12}>
          <Card title="快捷操作" className="quick-actions-card">
            <QuickActions />
          </Card>
        </Col>
        
        {/* 最近活动 */}
        <Col xs={24} lg={12}>
          <Card title="最近活动" className="recent-activity-card">
            <RecentActivity />
          </Card>
        </Col>
      </Row>
    </div>
  );
};
```

### 3. 客户端管理页面

#### 设计要点
- **客户端列表**: 清晰的客户端信息展示
- **状态指示**: 连接状态可视化
- **操作按钮**: 便捷的操作入口
- **搜索过滤**: 快速查找客户端

#### 组件结构
```tsx
// ClientsPage.tsx
const ClientsPage: React.FC = () => {
  const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([]);
  const [searchText, setSearchText] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  
  const { data: clients, isLoading, refetch } = useGetClientsQuery();
  const [createClient] = useCreateClientMutation();
  const [deleteClient] = useDeleteClientMutation();

  const filteredClients = useMemo(() => {
    return clients?.filter(client => {
      const matchesSearch = client.name.toLowerCase().includes(searchText.toLowerCase());
      const matchesStatus = statusFilter === 'all' || client.status === statusFilter;
      return matchesSearch && matchesStatus;
    }) || [];
  }, [clients, searchText, statusFilter]);

  const columns: ColumnsType<Client> = [
    {
      title: '客户端名称',
      dataIndex: 'name',
      key: 'name',
      render: (text, record) => (
        <div className="client-name">
          <Avatar size="small" icon={<UserOutlined />} />
          <span style={{ marginLeft: 8 }}>{text}</span>
        </div>
      ),
    },
    {
      title: 'IPv4地址',
      dataIndex: 'ipv4_address',
      key: 'ipv4_address',
    },
    {
      title: 'IPv6地址',
      dataIndex: 'ipv6_address',
      key: 'ipv6_address',
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => (
        <Tag color={status === 'connected' ? 'green' : 'red'}>
          {status === 'connected' ? '已连接' : '未连接'}
        </Tag>
      ),
    },
    {
      title: '最后连接',
      dataIndex: 'last_seen',
      key: 'last_seen',
      render: (time: string) => time ? dayjs(time).format('YYYY-MM-DD HH:mm:ss') : '-',
    },
    {
      title: '流量统计',
      key: 'traffic',
      render: (_, record) => (
        <div className="traffic-stats">
          <div>↑ {formatBytes(record.bytes_sent)}</div>
          <div>↓ {formatBytes(record.bytes_received)}</div>
        </div>
      ),
    },
    {
      title: '操作',
      key: 'action',
      render: (_, record) => (
        <Space>
          <Button
            type="link"
            icon={<EyeOutlined />}
            onClick={() => handleViewClient(record)}
          >
            查看
          </Button>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEditClient(record)}
          >
            编辑
          </Button>
          <Button
            type="link"
            icon={<DownloadOutlined />}
            onClick={() => handleDownloadConfig(record)}
          >
            下载配置
          </Button>
          <Popconfirm
            title="确定要删除这个客户端吗？"
            onConfirm={() => handleDeleteClient(record.id)}
          >
            <Button type="link" danger icon={<DeleteOutlined />}>
              删除
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <div className="clients-page">
      <PageHeader
        title="客户端管理"
        subTitle="管理WireGuard客户端配置"
        extra={[
          <Button
            key="add"
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => setCreateModalVisible(true)}
          >
            添加客户端
          </Button>
        ]}
      />
      
      <Card>
        <div className="clients-toolbar">
          <Space>
            <Input.Search
              placeholder="搜索客户端"
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              style={{ width: 200 }}
            />
            <Select
              value={statusFilter}
              onChange={setStatusFilter}
              style={{ width: 120 }}
            >
              <Select.Option value="all">全部状态</Select.Option>
              <Select.Option value="connected">已连接</Select.Option>
              <Select.Option value="disconnected">未连接</Select.Option>
            </Select>
            <Button icon={<ReloadOutlined />} onClick={() => refetch()}>
              刷新
            </Button>
          </Space>
        </div>
        
        <Table
          columns={columns}
          dataSource={filteredClients}
          loading={isLoading}
          rowKey="id"
          rowSelection={{
            selectedRowKeys,
            onChange: setSelectedRowKeys,
          }}
          pagination={{
            total: filteredClients.length,
            pageSize: 10,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total) => `共 ${total} 个客户端`,
          }}
        />
      </Card>
      
      <CreateClientModal
        visible={createModalVisible}
        onCancel={() => setCreateModalVisible(false)}
        onSuccess={() => {
          setCreateModalVisible(false);
          refetch();
        }}
      />
    </div>
  );
};
```

### 4. 监控页面

#### 设计要点
- **实时图表**: 实时性能数据展示
- **多维度**: 多维度数据对比
- **时间选择**: 灵活的时间范围选择
- **告警信息**: 系统告警状态显示

#### 组件结构
```tsx
// MonitoringPage.tsx
const MonitoringPage: React.FC = () => {
  const [timeRange, setTimeRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().subtract(1, 'hour'),
    dayjs()
  ]);
  const [refreshInterval, setRefreshInterval] = useState(30);
  
  const { data: metrics, isLoading } = useGetMetricsQuery({
    start_time: timeRange[0].toISOString(),
    end_time: timeRange[1].toISOString(),
  });

  return (
    <div className="monitoring-page">
      <PageHeader
        title="系统监控"
        subTitle="实时监控系统性能和状态"
        extra={[
          <RangePicker
            key="timeRange"
            value={timeRange}
            onChange={(dates) => setTimeRange(dates as [dayjs.Dayjs, dayjs.Dayjs])}
            showTime
          />,
          <Select
            key="refresh"
            value={refreshInterval}
            onChange={setRefreshInterval}
            style={{ width: 120 }}
          >
            <Select.Option value={10}>10秒</Select.Option>
            <Select.Option value={30}>30秒</Select.Option>
            <Select.Option value={60}>1分钟</Select.Option>
            <Select.Option value={300}>5分钟</Select.Option>
          </Select>
        ]}
      />
      
      <Row gutter={[16, 16]}>
        {/* 系统指标 */}
        <Col xs={24} lg={12}>
          <Card title="CPU使用率" className="metric-card">
            <CpuUsageChart data={metrics?.cpu_data} />
          </Card>
        </Col>
        
        <Col xs={24} lg={12}>
          <Card title="内存使用率" className="metric-card">
            <MemoryUsageChart data={metrics?.memory_data} />
          </Card>
        </Col>
      </Row>
      
      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col xs={24} lg={12}>
          <Card title="网络流量" className="metric-card">
            <NetworkTrafficChart data={metrics?.network_data} />
          </Card>
        </Col>
        
        <Col xs={24} lg={12}>
          <Card title="磁盘使用率" className="metric-card">
            <DiskUsageChart data={metrics?.disk_data} />
          </Card>
        </Col>
      </Row>
      
      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col xs={24}>
          <Card title="WireGuard连接状态" className="metric-card">
            <WireGuardStatusChart data={metrics?.wireguard_data} />
          </Card>
        </Col>
      </Row>
    </div>
  );
};
```

---

## 🎯 组件设计

### 1. 通用组件

#### Button组件
```tsx
// components/common/Button/Button.tsx
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
  size?: 'small' | 'medium' | 'large';
  loading?: boolean;
  disabled?: boolean;
  icon?: React.ReactNode;
  children: React.ReactNode;
  onClick?: () => void;
}

const Button: React.FC<ButtonProps> = ({
  variant = 'primary',
  size = 'medium',
  loading = false,
  disabled = false,
  icon,
  children,
  onClick,
  ...props
}) => {
  const buttonClass = classNames('custom-button', {
    [`button-${variant}`]: true,
    [`button-${size}`]: true,
    'button-loading': loading,
    'button-disabled': disabled,
  });

  return (
    <button
      className={buttonClass}
      disabled={disabled || loading}
      onClick={onClick}
      {...props}
    >
      {loading && <LoadingOutlined className="button-loading-icon" />}
      {icon && !loading && <span className="button-icon">{icon}</span>}
      <span className="button-text">{children}</span>
    </button>
  );
};
```

#### Table组件
```tsx
// components/common/Table/Table.tsx
interface TableProps<T> {
  columns: ColumnsType<T>;
  dataSource: T[];
  loading?: boolean;
  pagination?: TablePaginationConfig;
  rowSelection?: TableRowSelection<T>;
  onRow?: (record: T) => RowProps;
}

const CustomTable = <T extends Record<string, any>>({
  columns,
  dataSource,
  loading = false,
  pagination,
  rowSelection,
  onRow,
  ...props
}: TableProps<T>) => {
  return (
    <div className="custom-table">
      <Table
        columns={columns}
        dataSource={dataSource}
        loading={loading}
        pagination={pagination}
        rowSelection={rowSelection}
        onRow={onRow}
        className="custom-table-content"
        {...props}
      />
    </div>
  );
};
```

### 2. 业务组件

#### ClientForm组件
```tsx
// components/forms/ClientForm/ClientForm.tsx
interface ClientFormProps {
  initialValues?: Partial<Client>;
  onSubmit: (values: ClientFormData) => Promise<void>;
  onCancel: () => void;
  loading?: boolean;
}

const ClientForm: React.FC<ClientFormProps> = ({
  initialValues,
  onSubmit,
  onCancel,
  loading = false,
}) => {
  const [form] = Form.useForm();

  const handleSubmit = async (values: ClientFormData) => {
    try {
      await onSubmit(values);
      form.resetFields();
    } catch (error) {
      console.error('Form submission error:', error);
    }
  };

  return (
    <Form
      form={form}
      layout="vertical"
      initialValues={initialValues}
      onFinish={handleSubmit}
      className="client-form"
    >
      <Form.Item
        name="name"
        label="客户端名称"
        rules={[
          { required: true, message: '请输入客户端名称' },
          { min: 2, max: 50, message: '名称长度应在2-50个字符之间' },
        ]}
      >
        <Input placeholder="请输入客户端名称" />
      </Form.Item>

      <Form.Item
        name="description"
        label="描述"
        rules={[{ max: 200, message: '描述不能超过200个字符' }]}
      >
        <Input.TextArea
          placeholder="请输入客户端描述"
          rows={3}
        />
      </Form.Item>

      <Form.Item
        name="ipv4_address"
        label="IPv4地址"
        rules={[
          { required: true, message: '请输入IPv4地址' },
          { pattern: /^(\d{1,3}\.){3}\d{1,3}$/, message: '请输入有效的IPv4地址' },
        ]}
      >
        <Input placeholder="例如: 10.0.0.2" />
      </Form.Item>

      <Form.Item
        name="ipv6_address"
        label="IPv6地址"
        rules={[
          { required: true, message: '请输入IPv6地址' },
          { pattern: /^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$/, message: '请输入有效的IPv6地址' },
        ]}
      >
        <Input placeholder="例如: fd00:1234::2" />
      </Form.Item>

      <Form.Item
        name="allowed_ips"
        label="允许的IP"
        rules={[{ required: true, message: '请输入允许的IP' }]}
      >
        <Select
          mode="tags"
          placeholder="例如: 0.0.0.0/0, ::/0"
          tokenSeparators={[',']}
        />
      </Form.Item>

      <Form.Item
        name="persistent_keepalive"
        label="保持连接间隔"
        rules={[{ required: true, message: '请输入保持连接间隔' }]}
      >
        <InputNumber
          min={0}
          max={65535}
          placeholder="25"
          style={{ width: '100%' }}
        />
      </Form.Item>

      <Form.Item className="form-actions">
        <Space>
          <Button onClick={onCancel}>
            取消
          </Button>
          <Button
            type="primary"
            htmlType="submit"
            loading={loading}
          >
            保存
          </Button>
        </Space>
      </Form.Item>
    </Form>
  );
};
```

### 3. 图表组件

#### SystemMetricsChart组件
```tsx
// components/charts/SystemMetricsChart/SystemMetricsChart.tsx
interface SystemMetricsChartProps {
  data?: SystemMetricsData;
  height?: number;
}

const SystemMetricsChart: React.FC<SystemMetricsChartProps> = ({
  data,
  height = 300,
}) => {
  const chartData = useMemo(() => {
    if (!data) return [];
    
    return [
      {
        name: 'CPU使用率',
        value: data.cpu_usage,
        color: '#1890ff',
      },
      {
        name: '内存使用率',
        value: data.memory_usage,
        color: '#52c41a',
      },
      {
        name: '磁盘使用率',
        value: data.disk_usage,
        color: '#faad14',
      },
    ];
  }, [data]);

  return (
    <div className="system-metrics-chart" style={{ height }}>
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={chartData}
            cx="50%"
            cy="50%"
            innerRadius={60}
            outerRadius={100}
            paddingAngle={5}
            dataKey="value"
          >
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={entry.color} />
            ))}
          </Pie>
          <Tooltip formatter={(value) => `${value}%`} />
          <Legend />
        </PieChart>
      </ResponsiveContainer>
    </div>
  );
};
```

---

## 🔄 状态管理

### 1. Redux Store结构

#### Store配置
```tsx
// store/index.ts
import { configureStore } from '@reduxjs/toolkit';
import { setupListeners } from '@reduxjs/toolkit/query';
import { api } from '../services/api';
import authSlice from './authSlice';
import clientSlice from './clientSlice';
import serverSlice from './serverSlice';
import uiSlice from './uiSlice';

export const store = configureStore({
  reducer: {
    [api.reducerPath]: api.reducer,
    auth: authSlice,
    clients: clientSlice,
    servers: serverSlice,
    ui: uiSlice,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: [FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER],
      },
    }).concat(api.middleware),
});

setupListeners(store.dispatch);

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
```

#### Auth Slice
```tsx
// store/authSlice.ts
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { authApi } from '../services/auth';

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  loading: boolean;
  error: string | null;
}

const initialState: AuthState = {
  user: null,
  token: localStorage.getItem('token'),
  isAuthenticated: false,
  loading: false,
  error: null,
};

export const login = createAsyncThunk(
  'auth/login',
  async (credentials: LoginCredentials, { rejectWithValue }) => {
    try {
      const response = await authApi.login(credentials);
      localStorage.setItem('token', response.token);
      return response;
    } catch (error) {
      return rejectWithValue(error.message);
    }
  }
);

export const logout = createAsyncThunk(
  'auth/logout',
  async (_, { rejectWithValue }) => {
    try {
      await authApi.logout();
      localStorage.removeItem('token');
    } catch (error) {
      return rejectWithValue(error.message);
    }
  }
);

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
    setUser: (state, action: PayloadAction<User>) => {
      state.user = action.payload;
      state.isAuthenticated = true;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(login.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(login.fulfilled, (state, action) => {
        state.loading = false;
        state.user = action.payload.user;
        state.token = action.payload.token;
        state.isAuthenticated = true;
      })
      .addCase(login.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
        state.isAuthenticated = false;
      })
      .addCase(logout.fulfilled, (state) => {
        state.user = null;
        state.token = null;
        state.isAuthenticated = false;
      });
  },
});

export const { clearError, setUser } = authSlice.actions;
export default authSlice.reducer;
```

### 2. RTK Query API

#### API配置
```tsx
// services/api.ts
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

export const api = createApi({
  reducerPath: 'api',
  baseQuery: fetchBaseQuery({
    baseUrl: '/api/v1',
    prepareHeaders: (headers, { getState }) => {
      const token = (getState() as RootState).auth.token;
      if (token) {
        headers.set('authorization', `Bearer ${token}`);
      }
      return headers;
    },
  }),
  tagTypes: ['User', 'Client', 'Server', 'Network', 'Monitoring'],
  endpoints: (builder) => ({
    // 认证相关
    login: builder.mutation<AuthResponse, LoginCredentials>({
      query: (credentials) => ({
        url: '/auth/login',
        method: 'POST',
        body: credentials,
      }),
    }),
    
    // 客户端相关
    getClients: builder.query<Client[], void>({
      query: () => '/wireguard/clients',
      providesTags: ['Client'],
    }),
    
    createClient: builder.mutation<Client, CreateClientRequest>({
      query: (client) => ({
        url: '/wireguard/clients',
        method: 'POST',
        body: client,
      }),
      invalidatesTags: ['Client'],
    }),
    
    // 服务器相关
    getServers: builder.query<Server[], void>({
      query: () => '/wireguard/servers',
      providesTags: ['Server'],
    }),
    
    // 监控相关
    getMetrics: builder.query<MetricsData, MetricsQuery>({
      query: (params) => ({
        url: '/monitoring/metrics',
        params,
      }),
      providesTags: ['Monitoring'],
    }),
  }),
});

export const {
  useLoginMutation,
  useGetClientsQuery,
  useCreateClientMutation,
  useGetServersQuery,
  useGetMetricsQuery,
} = api;
```

---

## 🔌 实时通信

### 1. WebSocket连接

#### WebSocket Hook
```tsx
// hooks/useWebSocket.ts
import { useEffect, useRef, useState } from 'react';
import { useAppSelector } from '../store';

interface WebSocketMessage {
  type: string;
  data: any;
  timestamp: string;
}

export const useWebSocket = (url: string) => {
  const [socket, setSocket] = useState<WebSocket | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [lastMessage, setLastMessage] = useState<WebSocketMessage | null>(null);
  const token = useAppSelector((state) => state.auth.token);
  const reconnectTimeoutRef = useRef<NodeJS.Timeout>();

  useEffect(() => {
    if (!token) return;

    const connect = () => {
      const ws = new WebSocket(`${url}?token=${token}`);
      
      ws.onopen = () => {
        setIsConnected(true);
        setSocket(ws);
        console.log('WebSocket connected');
      };
      
      ws.onmessage = (event) => {
        try {
          const message: WebSocketMessage = JSON.parse(event.data);
          setLastMessage(message);
        } catch (error) {
          console.error('Failed to parse WebSocket message:', error);
        }
      };
      
      ws.onclose = () => {
        setIsConnected(false);
        setSocket(null);
        console.log('WebSocket disconnected');
        
        // 自动重连
        reconnectTimeoutRef.current = setTimeout(() => {
          connect();
        }, 3000);
      };
      
      ws.onerror = (error) => {
        console.error('WebSocket error:', error);
      };
    };

    connect();

    return () => {
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current);
      }
      if (socket) {
        socket.close();
      }
    };
  }, [url, token]);

  const sendMessage = (message: any) => {
    if (socket && isConnected) {
      socket.send(JSON.stringify(message));
    }
  };

  return {
    socket,
    isConnected,
    lastMessage,
    sendMessage,
  };
};
```

#### 实时数据更新
```tsx
// hooks/useRealtimeData.ts
import { useEffect, useState } from 'react';
import { useWebSocket } from './useWebSocket';

export const useRealtimeData = () => {
  const { lastMessage, isConnected } = useWebSocket('/ws/realtime');
  const [systemMetrics, setSystemMetrics] = useState<SystemMetrics | null>(null);
  const [clientStatus, setClientStatus] = useState<ClientStatus[]>([]);

  useEffect(() => {
    if (!lastMessage) return;

    switch (lastMessage.type) {
      case 'system_metrics':
        setSystemMetrics(lastMessage.data);
        break;
      case 'client_status':
        setClientStatus(lastMessage.data);
        break;
      default:
        break;
    }
  }, [lastMessage]);

  return {
    isConnected,
    systemMetrics,
    clientStatus,
  };
};
```

---

## 📱 响应式设计

### 1. 断点系统

#### 断点定义
```css
/* 断点定义 */
:root {
  --breakpoint-xs: 480px;
  --breakpoint-sm: 576px;
  --breakpoint-md: 768px;
  --breakpoint-lg: 992px;
  --breakpoint-xl: 1200px;
  --breakpoint-xxl: 1600px;
}

/* 媒体查询 */
@media (max-width: 575px) {
  /* 手机 */
}

@media (min-width: 576px) and (max-width: 767px) {
  /* 平板 */
}

@media (min-width: 768px) and (max-width: 991px) {
  /* 小桌面 */
}

@media (min-width: 992px) and (max-width: 1199px) {
  /* 桌面 */
}

@media (min-width: 1200px) {
  /* 大桌面 */
}
```

### 2. 响应式组件

#### 响应式布局
```tsx
// components/layout/ResponsiveLayout.tsx
const ResponsiveLayout: React.FC = () => {
  const [collapsed, setCollapsed] = useState(false);
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const checkIsMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };

    checkIsMobile();
    window.addEventListener('resize', checkIsMobile);

    return () => window.removeEventListener('resize', checkIsMobile);
  }, []);

  return (
    <Layout className="responsive-layout">
      <Sider
        collapsible
        collapsed={collapsed}
        onCollapse={setCollapsed}
        breakpoint="md"
        collapsedWidth={isMobile ? 0 : 80}
        className="layout-sider"
      >
        <Sidebar collapsed={collapsed} />
      </Sider>
      
      <Layout>
        <Header className="layout-header">
          <HeaderContent />
        </Header>
        
        <Content className="layout-content">
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  );
};
```

---

## 🧪 测试策略

### 1. 单元测试

#### 组件测试
```tsx
// __tests__/components/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from '../../components/common/Button';

describe('Button Component', () => {
  it('renders button with text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });

  it('handles click events', () => {
    const handleClick = jest.fn();
    render(<Button onClick={handleClick}>Click me</Button>);
    
    fireEvent.click(screen.getByText('Click me'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('shows loading state', () => {
    render(<Button loading>Click me</Button>);
    expect(screen.getByTestId('loading-icon')).toBeInTheDocument();
  });

  it('is disabled when loading', () => {
    render(<Button loading>Click me</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

### 2. 集成测试

#### 页面测试
```tsx
// __tests__/pages/LoginPage.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { Provider } from 'react-redux';
import { BrowserRouter } from 'react-router-dom';
import { store } from '../../store';
import { LoginPage } from '../../pages/LoginPage';

const renderWithProviders = (component: React.ReactElement) => {
  return render(
    <Provider store={store}>
      <BrowserRouter>
        {component}
      </BrowserRouter>
    </Provider>
  );
};

describe('LoginPage', () => {
  it('renders login form', () => {
    renderWithProviders(<LoginPage />);
    
    expect(screen.getByLabelText('用户名')).toBeInTheDocument();
    expect(screen.getByLabelText('密码')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: '登录' })).toBeInTheDocument();
  });

  it('validates required fields', async () => {
    renderWithProviders(<LoginPage />);
    
    fireEvent.click(screen.getByRole('button', { name: '登录' }));
    
    await waitFor(() => {
      expect(screen.getByText('请输入用户名')).toBeInTheDocument();
      expect(screen.getByText('请输入密码')).toBeInTheDocument();
    });
  });

  it('submits form with valid data', async () => {
    renderWithProviders(<LoginPage />);
    
    fireEvent.change(screen.getByLabelText('用户名'), {
      target: { value: 'admin' }
    });
    fireEvent.change(screen.getByLabelText('密码'), {
      target: { value: 'password' }
    });
    
    fireEvent.click(screen.getByRole('button', { name: '登录' }));
    
    await waitFor(() => {
      // 验证登录逻辑
    });
  });
});
```

### 3. E2E测试

#### Cypress测试
```typescript
// cypress/e2e/login.cy.ts
describe('Login Flow', () => {
  beforeEach(() => {
    cy.visit('/login');
  });

  it('should login successfully with valid credentials', () => {
    cy.get('[data-testid="username-input"]').type('admin');
    cy.get('[data-testid="password-input"]').type('password');
    cy.get('[data-testid="login-button"]').click();
    
    cy.url().should('include', '/dashboard');
    cy.get('[data-testid="user-menu"]').should('contain', 'admin');
  });

  it('should show error with invalid credentials', () => {
    cy.get('[data-testid="username-input"]').type('invalid');
    cy.get('[data-testid="password-input"]').type('invalid');
    cy.get('[data-testid="login-button"]').click();
    
    cy.get('[data-testid="error-message"]').should('be.visible');
  });
});
```

---

## 🚀 性能优化

### 1. 代码分割

#### 路由懒加载
```tsx
// App.tsx
import { lazy, Suspense } from 'react';
import { Routes, Route } from 'react-router-dom';
import { Spin } from 'antd';

const Dashboard = lazy(() => import('./pages/Dashboard'));
const Clients = lazy(() => import('./pages/Clients'));
const Servers = lazy(() => import('./pages/Servers'));
const Monitoring = lazy(() => import('./pages/Monitoring'));

const App: React.FC = () => {
  return (
    <Suspense fallback={<Spin size="large" />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/clients" element={<Clients />} />
        <Route path="/servers" element={<Servers />} />
        <Route path="/monitoring" element={<Monitoring />} />
      </Routes>
    </Suspense>
  );
};
```

### 2. 缓存策略

#### 组件缓存
```tsx
// hooks/useMemo.ts
import { useMemo } from 'react';

export const useExpensiveCalculation = (data: any[]) => {
  return useMemo(() => {
    return data.map(item => ({
      ...item,
      processed: expensiveCalculation(item)
    }));
  }, [data]);
};
```

#### API缓存
```tsx
// services/api.ts
export const api = createApi({
  // ... 其他配置
  endpoints: (builder) => ({
    getClients: builder.query<Client[], void>({
      query: () => '/wireguard/clients',
      providesTags: ['Client'],
      keepUnusedDataFor: 60, // 缓存60秒
    }),
  }),
});
```

### 3. 虚拟滚动

#### 大列表优化
```tsx
// components/common/VirtualTable.tsx
import { FixedSizeList as List } from 'react-window';

interface VirtualTableProps {
  items: any[];
  height: number;
  itemHeight: number;
  renderItem: (props: any) => React.ReactElement;
}

const VirtualTable: React.FC<VirtualTableProps> = ({
  items,
  height,
  itemHeight,
  renderItem,
}) => {
  return (
    <List
      height={height}
      itemCount={items.length}
      itemSize={itemHeight}
      itemData={items}
    >
      {renderItem}
    </List>
  );
};
```

---

## 🔧 开发工具

### 1. 构建配置

#### Vite配置
```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@components': path.resolve(__dirname, './src/components'),
      '@pages': path.resolve(__dirname, './src/pages'),
      '@hooks': path.resolve(__dirname, './src/hooks'),
      '@services': path.resolve(__dirname, './src/services'),
      '@utils': path.resolve(__dirname, './src/utils'),
      '@types': path.resolve(__dirname, './src/types'),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          antd: ['antd'],
          charts: ['recharts', 'chart.js'],
        },
      },
    },
  },
});
```

### 2. 代码质量

#### ESLint配置
```json
// .eslintrc.json
{
  "extends": [
    "eslint:recommended",
    "@typescript-eslint/recommended",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended",
    "plugin:jsx-a11y/recommended"
  ],
  "parser": "@typescript-eslint/parser",
  "plugins": [
    "@typescript-eslint",
    "react",
    "react-hooks",
    "jsx-a11y"
  ],
  "rules": {
    "react/react-in-jsx-scope": "off",
    "@typescript-eslint/no-unused-vars": "error",
    "react-hooks/rules-of-hooks": "error",
    "react-hooks/exhaustive-deps": "warn"
  },
  "settings": {
    "react": {
      "version": "detect"
    }
  }
}
```

#### Prettier配置
```json
// .prettierrc
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false
}
```

---

## 📦 部署配置

### 1. Docker配置

#### 前端Dockerfile
```dockerfile
# Dockerfile
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### Nginx配置
```nginx
# nginx.conf
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API代理
    location /api/ {
        proxy_pass http://backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket代理
    location /ws/ {
        proxy_pass http://backend:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

    # SPA路由支持
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 2. 环境配置

#### 环境变量
```bash
# .env.production
REACT_APP_API_URL=https://api.ipv6wgm.com
REACT_APP_WS_URL=wss://api.ipv6wgm.com/ws
REACT_APP_VERSION=3.0.0
REACT_APP_BUILD_TIME=2024-01-01T00:00:00Z
```

#### 构建脚本
```json
// package.json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "jest",
    "test:coverage": "jest --coverage",
    "lint": "eslint src --ext .ts,.tsx",
    "lint:fix": "eslint src --ext .ts,.tsx --fix",
    "format": "prettier --write src/**/*.{ts,tsx,css,md}"
  }
}
```

---

*本前端设计文档详细描述了IPv6 WireGuard Manager现代化Web界面的设计理念、技术实现和开发规范，为前端开发团队提供完整的设计指导。*
