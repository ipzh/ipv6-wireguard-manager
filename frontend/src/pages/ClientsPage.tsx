import React from 'react'
import { Card, Typography } from 'antd'

const { Title } = Typography

const ClientsPage: React.FC = () => {
  return (
    <div>
      <div className="mb-6">
        <Title level={2}>客户端管理</Title>
        <p className="text-gray-600">管理WireGuard客户端配置</p>
      </div>

      <Card>
        <div className="text-center py-12 text-gray-500">
          <p>客户端管理功能开发中...</p>
        </div>
      </Card>
    </div>
  )
}

export default ClientsPage
