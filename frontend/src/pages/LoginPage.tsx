import React from 'react'
import { Form, Input, Button, Card, Checkbox, message } from 'antd'
import { UserOutlined, LockOutlined } from '@ant-design/icons'
import { useDispatch, useSelector } from 'react-redux'
import { useNavigate } from 'react-router-dom'

import { RootState, AppDispatch } from '@store'
import { login } from '@store/slices/authSlice'

const LoginPage: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>()
  const navigate = useNavigate()
  const { loading, error } = useSelector((state: RootState) => state.auth)
  const [form] = Form.useForm()

  const handleLogin = async (values: { username: string; password: string; remember: boolean }) => {
    try {
      await dispatch(login({
        username: values.username,
        password: values.password,
      })).unwrap()
      
      message.success('登录成功')
      navigate('/dashboard')
    } catch (err) {
      message.error(error || '登录失败')
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-white mb-2">IPv6 WireGuard Manager</h1>
          <p className="text-blue-100">企业级VPN管理平台</p>
        </div>

        <Card className="shadow-2xl">
          <div className="text-center mb-6">
            <h2 className="text-2xl font-semibold text-gray-800">登录</h2>
            <p className="text-gray-600 mt-2">请输入您的凭据以继续</p>
          </div>

          <Form
            form={form}
            name="login"
            onFinish={handleLogin}
            layout="vertical"
            size="large"
            autoComplete="off"
          >
            <Form.Item
              name="username"
              label="用户名"
              rules={[
                { required: true, message: '请输入用户名' },
                { min: 3, message: '用户名至少3个字符' },
              ]}
            >
              <Input
                prefix={<UserOutlined className="text-gray-400" />}
                placeholder="请输入用户名"
                autoComplete="username"
              />
            </Form.Item>

            <Form.Item
              name="password"
              label="密码"
              rules={[
                { required: true, message: '请输入密码' },
                { min: 6, message: '密码至少6个字符' },
              ]}
            >
              <Input.Password
                prefix={<LockOutlined className="text-gray-400" />}
                placeholder="请输入密码"
                autoComplete="current-password"
              />
            </Form.Item>

            <Form.Item name="remember" valuePropName="checked">
              <Checkbox>记住密码</Checkbox>
            </Form.Item>

            <Form.Item>
              <Button
                type="primary"
                htmlType="submit"
                className="w-full h-12 text-lg font-medium"
                loading={loading}
              >
                登录
              </Button>
            </Form.Item>
          </Form>

          <div className="text-center mt-4">
            <a href="/forgot-password" className="text-blue-600 hover:text-blue-800">
              忘记密码？
            </a>
          </div>
        </Card>

        <div className="text-center mt-6 text-white text-sm">
          <p>© 2024 IPv6 WireGuard Manager. All rights reserved.</p>
        </div>
      </div>
    </div>
  )
}

export default LoginPage
