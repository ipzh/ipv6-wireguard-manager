import React from 'react'
import { Layout, Button, Dropdown, Avatar, Space, Typography } from 'antd'
import { 
  MenuFoldOutlined, 
  MenuUnfoldOutlined, 
  UserOutlined, 
  LogoutOutlined,
  SettingOutlined 
} from '@ant-design/icons'
import { useDispatch, useSelector } from 'react-redux'
import { useNavigate } from 'react-router-dom'

import { RootState, AppDispatch } from '@store'
import { logout } from '@store/slices/authSlice'

const { Header: AntHeader } = Layout
const { Text } = Typography

interface HeaderProps {
  collapsed: boolean
  onToggle: () => void
  isMobile?: boolean
}

const Header: React.FC<HeaderProps> = ({ collapsed, onToggle, isMobile = false }) => {
  const dispatch = useDispatch<AppDispatch>()
  const navigate = useNavigate()
  const { user } = useSelector((state: RootState) => state.auth)

  const handleLogout = () => {
    dispatch(logout())
    navigate('/login')
  }

  const userMenuItems = [
    {
      key: 'profile',
      icon: <UserOutlined />,
      label: '个人资料',
      onClick: () => navigate('/profile'),
    },
    {
      key: 'settings',
      icon: <SettingOutlined />,
      label: '设置',
      onClick: () => navigate('/settings'),
    },
    {
      type: 'divider' as const,
    },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: '退出登录',
      onClick: handleLogout,
    },
  ]

  return (
    <AntHeader className="bg-white shadow-sm border-b border-gray-200 px-4 sm:px-6 flex items-center justify-between">
      <div className="flex items-center">
        <Button
          type="text"
          icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
          onClick={onToggle}
          className="text-lg"
        />
        <div className="ml-2 sm:ml-4">
          <Text strong className="text-sm sm:text-lg hidden sm:block">
            IPv6 WireGuard Manager
          </Text>
          <Text strong className="text-sm sm:hidden">
            IPv6 WG
          </Text>
        </div>
      </div>

      <div className="flex items-center">
        <Space>
          <Dropdown
            menu={{ items: userMenuItems }}
            placement="bottomRight"
            arrow
          >
            <div className="flex items-center cursor-pointer hover:bg-gray-50 px-2 sm:px-3 py-2 rounded-lg">
              <Avatar 
                size="small" 
                icon={<UserOutlined />} 
                className="mr-1 sm:mr-2"
              />
              <div className="flex flex-col hidden sm:flex">
                <Text strong className="text-sm">{user?.username}</Text>
                <Text type="secondary" className="text-xs">
                  {user?.is_superuser ? '超级管理员' : '普通用户'}
                </Text>
              </div>
              <div className="sm:hidden">
                <Text strong className="text-sm">{user?.username}</Text>
              </div>
            </div>
          </Dropdown>
        </Space>
      </div>
    </AntHeader>
  )
}

export default Header
