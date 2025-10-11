import React from 'react'
import { Card, Row, Col, Statistic, Typography } from 'antd'
import { 
  CheckCircleOutlined, 
  UserOutlined, 
  DesktopOutlined, 
  DatabaseOutlined 
} from '@ant-design/icons'

const { Title } = Typography

const DashboardPage: React.FC = () => {
  return (
    <div>
      <div className="mb-6">
        <Title level={2}>仪表板</Title>
        <p className="text-gray-600">系统概览和关键指标</p>
      </div>

      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="系统状态"
              value="健康"
              valueStyle={{ color: '#52c41a' }}
              prefix={<CheckCircleOutlined />}
            />
          </Card>
        </Col>
        
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="在线客户端"
              value={12}
              suffix="/ 25"
              prefix={<UserOutlined />}
            />
          </Card>
        </Col>
        
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="CPU使用率"
              value={45}
              suffix="%"
              prefix={<DesktopOutlined />}
            />
          </Card>
        </Col>
        
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="内存使用率"
              value={68}
              suffix="%"
              prefix={<DatabaseOutlined />}
            />
          </Card>
        </Col>
      </Row>

      <Row gutter={[16, 16]} className="mt-6">
        <Col xs={24} lg={16}>
          <Card title="系统性能" className="h-96">
            <div className="flex items-center justify-center h-full text-gray-500">
              性能图表开发中...
            </div>
          </Card>
        </Col>
        
        <Col xs={24} lg={8}>
          <Card title="客户端状态" className="h-96">
            <div className="flex items-center justify-center h-full text-gray-500">
              客户端状态图表开发中...
            </div>
          </Card>
        </Col>
      </Row>
    </div>
  )
}

export default DashboardPage
