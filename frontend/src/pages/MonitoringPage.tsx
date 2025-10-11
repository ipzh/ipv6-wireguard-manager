import React from 'react'
import { Card, Typography } from 'antd'

const { Title } = Typography

const MonitoringPage: React.FC = () => {
  return (
    <div>
      <div className="mb-6">
        <Title level={2}>系统监控</Title>
        <p className="text-gray-600">实时监控系统性能和状态</p>
      </div>

      <Card>
        <div className="text-center py-12 text-gray-500">
          <p>系统监控功能开发中...</p>
        </div>
      </Card>
    </div>
  )
}

export default MonitoringPage
