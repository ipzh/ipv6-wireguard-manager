import React from 'react'
import { Card, Typography } from 'antd'

const { Title } = Typography

const LogsPage: React.FC = () => {
  return (
    <div>
      <div className="mb-6">
        <Title level={2}>日志管理</Title>
        <p className="text-gray-600">查看和管理系统日志</p>
      </div>

      <Card>
        <div className="text-center py-12 text-gray-500">
          <p>日志管理功能开发中...</p>
        </div>
      </Card>
    </div>
  )
}

export default LogsPage
