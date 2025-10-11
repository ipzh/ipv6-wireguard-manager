import React from 'react'
import { Card, Typography } from 'antd'

const { Title } = Typography

const ServersPage: React.FC = () => {
  return (
    <div>
      <div className="mb-6">
        <Title level={2}>服务器管理</Title>
        <p className="text-gray-600">管理WireGuard服务器配置</p>
      </div>

      <Card>
        <div className="text-center py-12 text-gray-500">
          <p>服务器管理功能开发中...</p>
        </div>
      </Card>
    </div>
  )
}

export default ServersPage
