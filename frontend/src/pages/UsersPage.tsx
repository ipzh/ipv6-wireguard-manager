import React from 'react'
import { Card, Typography } from 'antd'

const { Title } = Typography

const UsersPage: React.FC = () => {
  return (
    <div>
      <div className="mb-6">
        <Title level={2}>用户管理</Title>
        <p className="text-gray-600">管理系统用户和权限</p>
      </div>

      <Card>
        <div className="text-center py-12 text-gray-500">
          <p>用户管理功能开发中...</p>
        </div>
      </Card>
    </div>
  )
}

export default UsersPage
