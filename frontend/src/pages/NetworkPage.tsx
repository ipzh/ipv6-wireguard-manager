import React from 'react'
import { Card, Typography } from 'antd'

const { Title } = Typography

const NetworkPage: React.FC = () => {
  return (
    <div>
      <div className="mb-6">
        <Title level={2}>网络管理</Title>
        <p className="text-gray-600">管理网络接口和防火墙规则</p>
      </div>

      <Card>
        <div className="text-center py-12 text-gray-500">
          <p>网络管理功能开发中...</p>
        </div>
      </Card>
    </div>
  )
}

export default NetworkPage
