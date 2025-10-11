import React from 'react'
import { Card, Typography } from 'antd'

const { Title } = Typography

const SettingsPage: React.FC = () => {
  return (
    <div>
      <div className="mb-6">
        <Title level={2}>系统设置</Title>
        <p className="text-gray-600">配置系统参数和选项</p>
      </div>

      <Card>
        <div className="text-center py-12 text-gray-500">
          <p>系统设置功能开发中...</p>
        </div>
      </Card>
    </div>
  )
}

export default SettingsPage
