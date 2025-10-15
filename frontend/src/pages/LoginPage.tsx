import React, { useState, useEffect } from 'react'
import { Typography } from 'antd'
import { 
  SafetyCertificateOutlined,
  GlobalOutlined,
  CloudServerOutlined,
  SecurityScanOutlined
} from '@ant-design/icons'

import LoginForm from '@components/LoginForm'

const { Title, Text, Paragraph } = Typography

const LoginPage: React.FC = () => {
  const [currentTime, setCurrentTime] = useState(new Date())

  // 更新时间
  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date())
    }, 1000)
    return () => clearInterval(timer)
  }, [])

  return (
    <div className="min-h-screen relative overflow-hidden">
      {/* 动态背景 */}
      <div className="absolute inset-0 bg-gradient-to-br from-blue-600 via-purple-600 to-indigo-800">
        <div className="absolute inset-0 bg-black bg-opacity-20"></div>
        
        {/* 动态粒子效果 */}
        <div className="absolute inset-0">
          {[...Array(50)].map((_, i) => (
            <div
              key={i}
              className="absolute w-1 h-1 bg-white rounded-full opacity-30 animate-pulse"
              style={{
                left: `${Math.random() * 100}%`,
                top: `${Math.random() * 100}%`,
                animationDelay: `${Math.random() * 3}s`,
                animationDuration: `${2 + Math.random() * 3}s`
              }}
            />
          ))}
        </div>

        {/* 几何图形装饰 */}
        <div className="absolute top-20 left-20 w-32 h-32 border border-white border-opacity-20 rounded-full animate-spin" style={{ animationDuration: '20s' }}></div>
        <div className="absolute bottom-20 right-20 w-24 h-24 border border-white border-opacity-20 rounded-full animate-spin" style={{ animationDuration: '15s', animationDirection: 'reverse' }}></div>
        <div className="absolute top-1/2 left-10 w-16 h-16 border border-white border-opacity-20 transform rotate-45 animate-pulse"></div>
      </div>

      {/* 主要内容 */}
      <div className="relative z-10 min-h-screen flex items-center justify-center p-4">
        <div className="w-full max-w-6xl grid grid-cols-1 lg:grid-cols-2 gap-8 items-center">
          
          {/* 左侧品牌区域 */}
          <div className="text-white text-center lg:text-left space-y-6">
            <div className="space-y-4">
              <div className="flex items-center justify-center lg:justify-start space-x-3">
                <div className="w-12 h-12 bg-white bg-opacity-20 rounded-xl flex items-center justify-center backdrop-blur-sm">
                  <SecurityScanOutlined className="text-2xl text-white" />
                </div>
                <Title level={1} className="!text-white !mb-0 !text-4xl lg:!text-5xl font-bold">
                  IPv6 WireGuard
                </Title>
              </div>
              <Title level={2} className="!text-white !mb-0 !text-2xl lg:!text-3xl font-light">
                Manager
              </Title>
            </div>

            <Paragraph className="!text-blue-100 !text-lg !mb-6 max-w-md mx-auto lg:mx-0">
              企业级IPv6 VPN管理平台，提供安全、高效、智能的网络连接解决方案
            </Paragraph>

            {/* 特性展示 */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 max-w-lg mx-auto lg:mx-0">
              <div className="bg-white bg-opacity-10 rounded-lg p-4 backdrop-blur-sm">
                <GlobalOutlined className="text-2xl text-blue-300 mb-2" />
                <Text className="!text-white !text-sm">IPv6支持</Text>
              </div>
              <div className="bg-white bg-opacity-10 rounded-lg p-4 backdrop-blur-sm">
                <CloudServerOutlined className="text-2xl text-green-300 mb-2" />
                <Text className="!text-white !text-sm">云端管理</Text>
              </div>
              <div className="bg-white bg-opacity-10 rounded-lg p-4 backdrop-blur-sm">
                <SafetyCertificateOutlined className="text-2xl text-yellow-300 mb-2" />
                <Text className="!text-white !text-sm">安全加密</Text>
              </div>
            </div>

            {/* 当前时间 */}
            <div className="bg-white bg-opacity-10 rounded-lg p-4 backdrop-blur-sm max-w-sm mx-auto lg:mx-0">
              <Text className="!text-white !text-sm">
                {currentTime.toLocaleString('zh-CN', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                  hour: '2-digit',
                  minute: '2-digit',
                  second: '2-digit'
                })}
              </Text>
            </div>
          </div>

          {/* 右侧登录表单 */}
          <div className="flex justify-center">
            <LoginForm />
          </div>
        </div>
      </div>

      {/* 底部版权信息 */}
      <div className="absolute bottom-4 left-1/2 transform -translate-x-1/2 text-center">
        <Text className="text-white text-sm opacity-80">
          © 2024 IPv6 WireGuard Manager. All rights reserved.
        </Text>
      </div>
    </div>
  )
}

export default LoginPage
