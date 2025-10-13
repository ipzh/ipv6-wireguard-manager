import React, { useState, useEffect } from 'react'
import { Form, Input, Button, Card, Checkbox, message, Typography, Space, Divider } from 'antd'
import { 
  UserOutlined, 
  LockOutlined, 
  SafetyCertificateOutlined,
  GlobalOutlined,
  CloudServerOutlined,
  ShieldOutlined,
  EyeInvisibleOutlined,
  EyeTwoTone
} from '@ant-design/icons'
import { useDispatch, useSelector } from 'react-redux'
import { useNavigate } from 'react-router-dom'

import { RootState, AppDispatch } from '@store'
import { login } from '@store/slices/authSlice'

const { Title, Text, Paragraph } = Typography

const LoginPage: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>()
  const navigate = useNavigate()
  const { loading, error } = useSelector((state: RootState) => state.auth)
  const [form] = Form.useForm()
  const [showPassword, setShowPassword] = useState(false)
  const [currentTime, setCurrentTime] = useState(new Date())

  // 更新时间
  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date())
    }, 1000)
    return () => clearInterval(timer)
  }, [])

  const handleLogin = async (values: { username: string; password: string; remember: boolean }) => {
    try {
      await dispatch(login({
        username: values.username,
        password: values.password,
      })).unwrap()
      
      message.success('登录成功，欢迎回来！')
      navigate('/dashboard')
    } catch (err) {
      message.error(error || '登录失败，请检查用户名和密码')
    }
  }

  const quickLogin = (username: string, password: string) => {
    form.setFieldsValue({ username, password })
    handleLogin({ username, password, remember: false })
  }

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
                  <ShieldOutlined className="text-2xl text-white" />
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
            <Card 
              className="w-full max-w-md shadow-2xl border-0 bg-white bg-opacity-95 backdrop-blur-sm"
              bodyStyle={{ padding: '40px' }}
            >
              <div className="text-center mb-8">
                <div className="w-16 h-16 bg-gradient-to-r from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center mx-auto mb-4">
                  <UserOutlined className="text-2xl text-white" />
                </div>
                <Title level={2} className="!text-gray-800 !mb-2">欢迎回来</Title>
                <Text className="text-gray-600">请登录您的账户以继续</Text>
              </div>

              <Form
                form={form}
                name="login"
                onFinish={handleLogin}
                layout="vertical"
                size="large"
                autoComplete="off"
                className="space-y-6"
              >
                <Form.Item
                  name="username"
                  label={<Text strong>用户名</Text>}
                  rules={[
                    { required: true, message: '请输入用户名' },
                    { min: 3, message: '用户名至少3个字符' },
                  ]}
                >
                  <Input
                    prefix={<UserOutlined className="text-gray-400" />}
                    placeholder="请输入用户名"
                    autoComplete="username"
                    className="h-12 rounded-lg"
                  />
                </Form.Item>

                <Form.Item
                  name="password"
                  label={<Text strong>密码</Text>}
                  rules={[
                    { required: true, message: '请输入密码' },
                    { min: 6, message: '密码至少6个字符' },
                  ]}
                >
                  <Input.Password
                    prefix={<LockOutlined className="text-gray-400" />}
                    placeholder="请输入密码"
                    autoComplete="current-password"
                    className="h-12 rounded-lg"
                    iconRender={(visible) => (visible ? <EyeTwoTone /> : <EyeInvisibleOutlined />)}
                  />
                </Form.Item>

                <div className="flex justify-between items-center">
                  <Form.Item name="remember" valuePropName="checked" className="!mb-0">
                    <Checkbox>记住我</Checkbox>
                  </Form.Item>
                  <a href="/forgot-password" className="text-blue-600 hover:text-blue-800 text-sm">
                    忘记密码？
                  </a>
                </div>

                <Form.Item className="!mb-6">
                  <Button
                    type="primary"
                    htmlType="submit"
                    className="w-full h-12 text-lg font-medium rounded-lg bg-gradient-to-r from-blue-500 to-purple-600 border-0 hover:from-blue-600 hover:to-purple-700"
                    loading={loading}
                  >
                    {loading ? '登录中...' : '立即登录'}
                  </Button>
                </Form.Item>
              </Form>

              <Divider className="!my-6">
                <Text type="secondary" className="text-sm">快速登录</Text>
              </Divider>

              <div className="space-y-3">
                <Button
                  type="default"
                  className="w-full h-10 rounded-lg border-dashed"
                  onClick={() => quickLogin('admin', 'admin123')}
                  disabled={loading}
                >
                  <Space>
                    <UserOutlined />
                    <Text>管理员账户</Text>
                  </Space>
                </Button>
                
                <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3">
                  <Text className="text-yellow-800 text-xs">
                    <ShieldOutlined className="mr-1" />
                    默认账户仅用于演示，生产环境请修改密码
                  </Text>
                </div>
              </div>
            </Card>
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
