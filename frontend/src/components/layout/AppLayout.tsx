import React, { useState, useEffect } from 'react'
import { Layout, Drawer } from 'antd'

import Header from './Header'
import Sidebar from './Sidebar'

const { Content } = Layout

interface AppLayoutProps {
  children: React.ReactNode
}

const AppLayout: React.FC<AppLayoutProps> = ({ children }) => {
  const [collapsed, setCollapsed] = useState(false)
  const [isMobile, setIsMobile] = useState(false)
  const [mobileDrawerVisible, setMobileDrawerVisible] = useState(false)

  useEffect(() => {
    const checkIsMobile = () => {
      setIsMobile(window.innerWidth < 768)
    }
    
    checkIsMobile()
    window.addEventListener('resize', checkIsMobile)
    
    return () => window.removeEventListener('resize', checkIsMobile)
  }, [])

  const handleToggle = () => {
    if (isMobile) {
      setMobileDrawerVisible(!mobileDrawerVisible)
    } else {
      setCollapsed(!collapsed)
    }
  }

  const handleCollapse = (collapsed: boolean) => {
    setCollapsed(collapsed)
    if (isMobile) {
      setMobileDrawerVisible(false)
    }
  }

  return (
    <Layout className="min-h-screen">
      {!isMobile && (
        <Sidebar collapsed={collapsed} onCollapse={handleCollapse} />
      )}
      
      {isMobile && (
        <Drawer
          title="菜单"
          placement="left"
          closable={false}
          onClose={() => setMobileDrawerVisible(false)}
          open={mobileDrawerVisible}
          bodyStyle={{ padding: 0 }}
          width={256}
        >
          <Sidebar collapsed={false} onCollapse={handleCollapse} />
        </Drawer>
      )}
      
      <Layout>
        <Header collapsed={collapsed} onToggle={handleToggle} isMobile={isMobile} />
        <Content className="bg-gray-50 responsive-content">
          {children}
        </Content>
      </Layout>
    </Layout>
  )
}

export default AppLayout
