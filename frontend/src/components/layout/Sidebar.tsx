import React from 'react'
import { Layout, Menu } from 'antd'
import { useNavigate, useLocation } from 'react-router-dom'
import {
  DashboardOutlined,
  UserOutlined,
  CloudServerOutlined,
  GlobalOutlined,
  ApiOutlined,
  DatabaseOutlined,
  MonitorOutlined,
  FileTextOutlined,
  TeamOutlined,
  SettingOutlined,
} from '@ant-design/icons'

const { Sider } = Layout

interface SidebarProps {
  collapsed: boolean
  onCollapse: (collapsed: boolean) => void
}

const Sidebar: React.FC<SidebarProps> = ({ collapsed }) => {
  const navigate = useNavigate()
  const location = useLocation()

  const menuItems = [
    {
      key: '/dashboard',
      icon: <DashboardOutlined />,
      label: '仪表板',
    },
    {
      key: '/clients',
      icon: <UserOutlined />,
      label: '客户端管理',
    },
    {
      key: '/servers',
      icon: <CloudServerOutlined />,
      label: '服务器管理',
    },
    {
      key: '/network',
      icon: <GlobalOutlined />,
      label: '网络管理',
    },
    {
      key: '/bgp-sessions',
      icon: <ApiOutlined />,
      label: 'BGP会话',
    },
    {
      key: '/ipv6-pools',
      icon: <DatabaseOutlined />,
      label: 'IPv6前缀池',
    },
    {
      key: '/monitoring',
      icon: <MonitorOutlined />,
      label: '系统监控',
    },
    {
      key: '/logs',
      icon: <FileTextOutlined />,
      label: '日志管理',
    },
    {
      key: '/users',
      icon: <TeamOutlined />,
      label: '用户管理',
    },
    {
      key: '/settings',
      icon: <SettingOutlined />,
      label: '系统设置',
    },
  ]

  const handleMenuClick = ({ key }: { key: string }) => {
    navigate(key)
  }

  return (
    <Sider
      trigger={null}
      collapsible
      collapsed={collapsed}
      className="bg-white shadow-sm border-r border-gray-200"
      width={240}
    >
      <div className="h-full flex flex-col">
        <div className="p-4 border-b border-gray-200">
          <div className="flex items-center justify-center">
            {!collapsed && (
              <div className="text-center">
                <div className="text-lg font-bold text-blue-600">IPv6 WG</div>
                <div className="text-xs text-gray-500">Manager</div>
              </div>
            )}
            {collapsed && (
              <div className="text-lg font-bold text-blue-600">WG</div>
            )}
          </div>
        </div>
        
        <Menu
          mode="inline"
          selectedKeys={[location.pathname]}
          items={menuItems}
          onClick={handleMenuClick}
          className="border-0 flex-1"
        />
      </div>
    </Sider>
  )
}

export default Sidebar
