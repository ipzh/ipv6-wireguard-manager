import React, { useState } from 'react'
import { Form, Input, Button, Card, Checkbox, message, Typography, Space, Divider } from 'antd'
import { 
  UserOutlined, 
  LockOutlined, 
  EyeInvisibleOutlined,
  EyeTwoTone
} from '@ant-design/icons'
import { useDispatch, useSelector } from 'react-redux'
import { useNavigate } from 'react-router-dom'

import { RootState, AppDispatch } from '@store'
import { login } from '@store/slices/authSlice'

const { Title, Text } = Typography

interface LoginFormProps {
  onQuickLogin?: (username: string, password: string) => void
}

const LoginForm: React.FC<LoginFormProps> = ({ onQuickLogin }) => {
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
      
      message.success('登录成功，欢迎回来！')
      navigate('/dashboard')
    } catch (err: any) {
      message.error(err?.message || error || '登录失败，请检查用户名和密码')
    }
  }

  const quickLogin = (username: string, password: string) => {
    form.setFieldsValue({ username, password })
    if (onQuickLogin) {
      onQuickLogin(username, password)
    } else {
      handleLogin({ username, password, remember: false })
    }
  }

  return (
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
            <LockOutlined className="mr-1" />
            默认账户仅用于演示，生产环境请修改密码
          </Text>
        </div>
      </div>
    </Card>
  )
}

export default LoginForm
