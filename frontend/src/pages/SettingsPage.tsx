import React, { useState, useEffect } from 'react'
import { Card, Typography, Tabs, Form, Input, Button, message, Space, Divider, Switch, Select, InputNumber, Checkbox, Modal, Progress, Alert } from 'antd'
import { UserOutlined, LockOutlined, MailOutlined, SettingOutlined, SecurityScanOutlined, GlobalOutlined, ToolOutlined, ExclamationCircleOutlined } from '@ant-design/icons'

const { Title } = Typography
const { TabPane } = Tabs

interface UserProfile {
  id: number
  username: string
  email: string
  role: string
  created_at: string
  updated_at: string
}

interface SystemSettings {
  default_mtu: number
  default_keepalive: number
  default_dns: string
  auto_start_servers: boolean
  log_level: string
  backup_enabled: boolean
  backup_interval: number
}

interface DomainSettings {
  custom_domain: string
  ssl_enabled: boolean
  ssl_cert_path: string
  ssl_key_path: string
  ssl_cert_content: string
  ssl_key_content: string
  auto_renew_ssl: boolean
  ssl_provider: string
  dns_provider: string
  dns_api_key: string
  dns_api_secret: string
}

const SettingsPage: React.FC = () => {
  const [loading, setLoading] = useState(false)
  const [profileLoading, setProfileLoading] = useState(false)
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null)
  const [systemSettings, setSystemSettings] = useState<SystemSettings>({
    default_mtu: 1420,
    default_keepalive: 25,
    default_dns: '8.8.8.8, 2001:4860:4860::8888',
    auto_start_servers: true,
    log_level: 'INFO',
    backup_enabled: false,
    backup_interval: 24
  })
  const [domainSettings, setDomainSettings] = useState<DomainSettings>({
    custom_domain: '',
    ssl_enabled: false,
    ssl_cert_path: '/etc/ssl/certs/ipv6wg.crt',
    ssl_key_path: '/etc/ssl/private/ipv6wg.key',
    ssl_cert_content: '',
    ssl_key_content: '',
    auto_renew_ssl: true,
    ssl_provider: 'letsencrypt',
    dns_provider: 'cloudflare',
    dns_api_key: '',
    dns_api_secret: ''
  })
  
  const [profileForm] = Form.useForm()
  const [passwordForm] = Form.useForm()
  const [settingsForm] = Form.useForm()
  const [domainForm] = Form.useForm()
  
  // 系统管理相关状态
  const [systemModalVisible, setSystemModalVisible] = useState(false)
  const [systemAction, setSystemAction] = useState<'uninstall' | 'reinstall' | null>(null)
  const [systemProgress, setSystemProgress] = useState(0)
  const [systemLogs, setSystemLogs] = useState<string[]>([])
  const [systemConfirmText, setSystemConfirmText] = useState('')
  const [systemInfo, setSystemInfo] = useState({
    version: 'v1.0.0',
    install_date: '2024-10-12',
    backend_status: '运行中',
    database_status: '正常',
    nginx_status: '运行中',
    uptime: '未知'
  })

  const loadUserProfile = async () => {
    setProfileLoading(true)
    try {
      // 模拟从API获取用户信息
      const mockProfile: UserProfile = {
        id: 1,
        username: 'admin',
        email: 'admin@ipv6wg.local',
        role: 'admin',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }
      setUserProfile(mockProfile)
      profileForm.setFieldsValue(mockProfile)
    } catch (error) {
      console.error('加载用户信息失败:', error)
      message.error('加载用户信息失败')
    } finally {
      setProfileLoading(false)
    }
  }

  const loadSystemSettings = async () => {
    try {
      // 模拟从API获取系统设置
      settingsForm.setFieldsValue(systemSettings)
    } catch (error) {
      console.error('加载系统设置失败:', error)
      message.error('加载系统设置失败')
    }
  }

  const loadDomainSettings = async () => {
    try {
      // 模拟从API获取域名设置
      domainForm.setFieldsValue(domainSettings)
    } catch (error) {
      console.error('加载域名设置失败:', error)
      message.error('加载域名设置失败')
    }
  }

  const loadSystemInfo = async () => {
    try {
      const response = await fetch('/api/v1/system/info', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        setSystemInfo(data)
      }
    } catch (error) {
      console.error('获取系统信息失败:', error)
    }
  }

  useEffect(() => {
    loadUserProfile()
    loadSystemSettings()
    loadDomainSettings()
    loadSystemInfo()
  }, [])

  const handleProfileUpdate = async (values: any) => {
    setLoading(true)
    try {
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      const updatedProfile = { ...userProfile, ...values }
      setUserProfile(updatedProfile)
      message.success('个人信息更新成功')
    } catch (error) {
      console.error('更新失败:', error)
      message.error('更新失败')
    } finally {
      setLoading(false)
    }
  }

  const handlePasswordChange = async (values: any) => {
    setLoading(true)
    try {
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      message.success('密码修改成功，请重新登录')
      passwordForm.resetFields()
      
      // 可选：自动登出
      setTimeout(() => {
        localStorage.removeItem('token')
        window.location.href = '/login'
      }, 2000)
    } catch (error) {
      console.error('密码修改失败:', error)
      message.error('密码修改失败')
    } finally {
      setLoading(false)
    }
  }

  const handleSettingsUpdate = async (values: any) => {
    setLoading(true)
    try {
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      setSystemSettings({ ...systemSettings, ...values })
      message.success('系统设置更新成功')
    } catch (error) {
      console.error('设置更新失败:', error)
      message.error('设置更新失败')
    } finally {
      setLoading(false)
    }
  }

  const handleDomainUpdate = async (values: any) => {
    setLoading(true)
    try {
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      setDomainSettings({ ...domainSettings, ...values })
      message.success('域名设置更新成功')
    } catch (error) {
      console.error('域名设置更新失败:', error)
      message.error('域名设置更新失败')
    } finally {
      setLoading(false)
    }
  }

  const testDomainConnection = async () => {
    const domain = domainForm.getFieldValue('custom_domain')
    if (!domain) {
      message.warning('请先输入域名')
      return
    }

    setLoading(true)
    try {
      // 模拟域名连接测试
      await new Promise(resolve => setTimeout(resolve, 2000))
      message.success(`域名 ${domain} 连接测试成功`)
    } catch (error) {
      message.error('域名连接测试失败')
    } finally {
      setLoading(false)
    }
  }

  const generateSSL = async () => {
    const domain = domainForm.getFieldValue('custom_domain')
    if (!domain) {
      message.warning('请先输入域名')
      return
    }

    setLoading(true)
    try {
      // 模拟SSL证书生成
      await new Promise(resolve => setTimeout(resolve, 3000))
      message.success('SSL证书生成成功')
    } catch (error) {
      message.error('SSL证书生成失败')
    } finally {
      setLoading(false)
    }
  }

  // 系统管理函数
  const handleSystemAction = (action: 'uninstall' | 'reinstall') => {
    setSystemAction(action)
    setSystemModalVisible(true)
    setSystemProgress(0)
    setSystemLogs([])
    setSystemConfirmText('')
  }

  const confirmSystemAction = async () => {
    if (!systemAction) return

    const requiredText = systemAction === 'uninstall' ? 'UNINSTALL' : 'REINSTALL'
    if (systemConfirmText !== requiredText) {
      message.error(`请输入 "${requiredText}" 确认操作`)
      return
    }

    setLoading(true)
    setSystemProgress(0)
    setSystemLogs([])

    try {
      // 调用后端API执行系统操作
      const response = await fetch('/api/v1/system/action', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        },
        body: JSON.stringify({
          action: systemAction,
          confirm_text: systemConfirmText
        })
      })

      if (!response.ok) {
        const error = await response.json()
        throw new Error(error.detail || '操作失败')
      }

      const result = await response.json()
      
      // 模拟操作进度
      const steps = systemAction === 'uninstall' 
        ? [
            '停止服务...',
            '备份配置文件...',
            '删除应用文件...',
            '清理数据库...',
            '卸载完成'
          ]
        : [
            '停止服务...',
            '备份当前配置...',
            '下载最新版本...',
            '重新安装依赖...',
            '恢复配置...',
            '启动服务...',
            '重新安装完成'
          ]

      for (let i = 0; i < steps.length; i++) {
        setSystemLogs(prev => [...prev, steps[i]])
        setSystemProgress((i + 1) * (100 / steps.length))
        await new Promise(resolve => setTimeout(resolve, 2000))
      }

      if (systemAction === 'uninstall') {
        message.success('系统卸载完成，页面将在5秒后跳转')
        setTimeout(() => {
          window.location.href = '/'
        }, 5000)
      } else {
        message.success('系统重新安装完成，页面将在3秒后刷新')
        setTimeout(() => {
          window.location.reload()
        }, 3000)
      }
    } catch (error) {
      message.error(`${systemAction === 'uninstall' ? '卸载' : '重新安装'}失败: ${error.message}`)
    } finally {
      setLoading(false)
      setSystemModalVisible(false)
    }
  }

  const cancelSystemAction = () => {
    setSystemModalVisible(false)
    setSystemAction(null)
    setSystemProgress(0)
    setSystemLogs([])
    setSystemConfirmText('')
  }

  return (
    <div>
      <div className="mb-6">
        <Title level={2}>系统设置</Title>
        <p className="text-gray-600">配置系统参数和个人信息</p>
      </div>

      <Tabs defaultActiveKey="profile" type="card">
        <TabPane 
          tab={
            <span>
              <UserOutlined />
              个人信息
            </span>
          } 
          key="profile"
        >
          <Card title="个人信息设置" loading={profileLoading}>
            <Form
              form={profileForm}
              layout="vertical"
              onFinish={handleProfileUpdate}
              style={{ maxWidth: 600 }}
            >
              <Form.Item
                name="username"
                label="用户名"
                rules={[
                  { required: true, message: '请输入用户名' },
                  { min: 3, max: 20, message: '用户名长度应为3-20个字符' },
                  { pattern: /^[a-zA-Z0-9_]+$/, message: '用户名只能包含字母、数字和下划线' }
                ]}
              >
                <Input prefix={<UserOutlined />} placeholder="请输入用户名" />
              </Form.Item>

              <Form.Item
                name="email"
                label="邮箱地址"
                rules={[
                  { required: true, message: '请输入邮箱地址' },
                  { type: 'email', message: '请输入有效的邮箱地址' }
                ]}
              >
                <Input prefix={<MailOutlined />} placeholder="请输入邮箱地址" />
              </Form.Item>

              <Form.Item>
                <Space>
                  <Button type="primary" htmlType="submit" loading={loading}>
                    更新个人信息
                  </Button>
                  <Button onClick={() => profileForm.resetFields()}>
                    重置
                  </Button>
                </Space>
              </Form.Item>
            </Form>
          </Card>
        </TabPane>

        <TabPane 
          tab={
            <span>
              <LockOutlined />
              修改密码
            </span>
          } 
          key="password"
        >
          <Card title="修改密码" style={{ maxWidth: 600 }}>
            <Form
              form={passwordForm}
              layout="vertical"
              onFinish={handlePasswordChange}
            >
              <Form.Item
                name="currentPassword"
                label="当前密码"
                rules={[{ required: true, message: '请输入当前密码' }]}
              >
                <Input.Password prefix={<LockOutlined />} placeholder="请输入当前密码" />
              </Form.Item>

              <Form.Item
                name="newPassword"
                label="新密码"
                rules={[
                  { required: true, message: '请输入新密码' },
                  { min: 6, message: '密码长度至少6个字符' },
                  { pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, message: '密码必须包含大小写字母和数字' }
                ]}
              >
                <Input.Password prefix={<LockOutlined />} placeholder="请输入新密码" />
              </Form.Item>

              <Form.Item
                name="confirmPassword"
                label="确认新密码"
                dependencies={['newPassword']}
                rules={[
                  { required: true, message: '请确认新密码' },
                  ({ getFieldValue }) => ({
                    validator(_, value) {
                      if (!value || getFieldValue('newPassword') === value) {
                        return Promise.resolve()
                      }
                      return Promise.reject(new Error('两次输入的密码不一致'))
                    }
                  })
                ]}
              >
                <Input.Password prefix={<LockOutlined />} placeholder="请再次输入新密码" />
              </Form.Item>

              <Form.Item>
                <Space>
                  <Button type="primary" htmlType="submit" loading={loading}>
                    修改密码
                  </Button>
                  <Button onClick={() => passwordForm.resetFields()}>
                    重置
                  </Button>
                </Space>
              </Form.Item>
            </Form>
          </Card>
        </TabPane>

        <TabPane 
          tab={
            <span>
              <SettingOutlined />
              系统设置
            </span>
          } 
          key="system"
        >
          <Card title="系统配置">
            <Form
              form={settingsForm}
              layout="vertical"
              onFinish={handleSettingsUpdate}
              style={{ maxWidth: 800 }}
            >
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div className="space-y-4">
                  <Title level={4}>网络设置</Title>
                  <Form.Item
                    name="default_mtu"
                    label="默认MTU"
                    rules={[
                      { required: true, message: '请输入默认MTU' },
                      { type: 'number', min: 1280, max: 1500, message: 'MTU范围: 1280-1500' }
                    ]}
                  >
                    <InputNumber 
                      style={{ width: '100%' }}
                      placeholder="例如: 1420"
                      min={1280}
                      max={1500}
                    />
                  </Form.Item>

                  <Form.Item
                    name="default_keepalive"
                    label="默认保持连接间隔(秒)"
                    rules={[
                      { required: true, message: '请输入保持连接间隔' },
                      { type: 'number', min: 0, max: 65535, message: '间隔范围: 0-65535秒' }
                    ]}
                  >
                    <InputNumber 
                      style={{ width: '100%' }}
                      placeholder="例如: 25"
                      min={0}
                      max={65535}
                    />
                  </Form.Item>

                  <Form.Item
                    name="default_dns"
                    label="默认DNS服务器"
                    rules={[{ required: true, message: '请输入默认DNS服务器' }]}
                  >
                    <Input placeholder="例如: 8.8.8.8, 2001:4860:4860::8888" />
                  </Form.Item>
                </div>

                <div className="space-y-4">
                  <Title level={4}>系统行为</Title>
                  <Form.Item
                    name="auto_start_servers"
                    label="自动启动服务器"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>

                  <Form.Item
                    name="log_level"
                    label="日志级别"
                    rules={[{ required: true, message: '请选择日志级别' }]}
                  >
                    <Select placeholder="选择日志级别">
                      <Select.Option value="DEBUG">DEBUG</Select.Option>
                      <Select.Option value="INFO">INFO</Select.Option>
                      <Select.Option value="WARNING">WARNING</Select.Option>
                      <Select.Option value="ERROR">ERROR</Select.Option>
                    </Select>
                  </Form.Item>

                  <Form.Item
                    name="backup_enabled"
                    label="启用自动备份"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>

                  <Form.Item
                    name="backup_interval"
                    label="备份间隔(小时)"
                    rules={[
                      { type: 'number', min: 1, max: 168, message: '备份间隔范围: 1-168小时' }
                    ]}
                  >
                    <InputNumber 
                      style={{ width: '100%' }}
                      placeholder="例如: 24"
                      min={1}
                      max={168}
                    />
                  </Form.Item>
                </div>
              </div>

              <Divider />

              <Form.Item>
                <Space>
                  <Button type="primary" htmlType="submit" loading={loading}>
                    保存设置
                  </Button>
                  <Button onClick={() => settingsForm.resetFields()}>
                    重置
                  </Button>
                </Space>
              </Form.Item>
            </Form>
          </Card>
        </TabPane>

        <TabPane 
          tab={
            <span>
              <SecurityScanOutlined />
              安全设置
            </span>
          } 
          key="security"
        >
          <Card title="安全配置">
            <div className="space-y-6">
              <div>
                <Title level={4}>登录安全</Title>
                <div className="space-y-4">
                  <div className="flex justify-between items-center p-4 border rounded">
                    <div>
                      <h5 className="font-semibold">强制HTTPS</h5>
                      <p className="text-gray-600 text-sm">强制使用HTTPS连接</p>
                    </div>
                    <Switch defaultChecked />
                  </div>
                  
                  <div className="flex justify-between items-center p-4 border rounded">
                    <div>
                      <h5 className="font-semibold">会话超时</h5>
                      <p className="text-gray-600 text-sm">30分钟无操作自动登出</p>
                    </div>
                    <Switch defaultChecked />
                  </div>
                  
                  <div className="flex justify-between items-center p-4 border rounded">
                    <div>
                      <h5 className="font-semibold">登录失败锁定</h5>
                      <p className="text-gray-600 text-sm">5次失败后锁定账户10分钟</p>
                    </div>
                    <Switch defaultChecked />
                  </div>
                </div>
              </div>

              <Divider />

              <div>
                <Title level={4}>API安全</Title>
                <div className="space-y-4">
                  <div className="flex justify-between items-center p-4 border rounded">
                    <div>
                      <h5 className="font-semibold">API访问限制</h5>
                      <p className="text-gray-600 text-sm">限制API访问频率</p>
                    </div>
                    <Switch defaultChecked />
                  </div>
                  
                  <div className="flex justify-between items-center p-4 border rounded">
                    <div>
                      <h5 className="font-semibold">CORS保护</h5>
                      <p className="text-gray-600 text-sm">启用跨域请求保护</p>
                    </div>
                    <Switch defaultChecked />
                  </div>
                </div>
              </div>
            </div>
          </Card>
        </TabPane>

        <TabPane 
          tab={
            <span>
              <GlobalOutlined />
              域名与SSL
            </span>
          } 
          key="domain"
        >
          <Card title="域名与SSL配置">
            <Form
              form={domainForm}
              layout="vertical"
              onFinish={handleDomainUpdate}
              style={{ maxWidth: 1000 }}
            >
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div>
                  <Title level={4}>域名配置</Title>
                  <Form.Item
                    name="custom_domain"
                    label="自定义域名"
                    rules={[
                      { pattern: /^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$/, message: '请输入有效的域名' }
                    ]}
                  >
                    <Input placeholder="example.com" />
                  </Form.Item>
                  
                  <Form.Item>
                    <Button onClick={testDomainConnection} loading={loading}>
                      测试域名连接
                    </Button>
                  </Form.Item>
                </div>

                <div>
                  <Title level={4}>SSL配置</Title>
                  <Form.Item name="ssl_enabled" valuePropName="checked">
                    <Checkbox>启用SSL</Checkbox>
                  </Form.Item>

                  <Form.Item
                    name="ssl_provider"
                    label="SSL提供商"
                    dependencies={['ssl_enabled']}
                  >
                    <Select disabled={!domainForm.getFieldValue('ssl_enabled')}>
                      <Select.Option value="letsencrypt">Let's Encrypt (免费)</Select.Option>
                      <Select.Option value="custom">自定义证书</Select.Option>
                      <Select.Option value="cloudflare">Cloudflare</Select.Option>
                    </Select>
                  </Form.Item>

                  <Form.Item
                    name="auto_renew_ssl"
                    valuePropName="checked"
                    dependencies={['ssl_enabled', 'ssl_provider']}
                  >
                    <Checkbox disabled={!domainForm.getFieldValue('ssl_enabled') || domainForm.getFieldValue('ssl_provider') === 'custom'}>
                      自动续期SSL证书
                    </Checkbox>
                  </Form.Item>
                </div>
              </div>

              <Divider />

              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div>
                  <Title level={4}>证书文件路径</Title>
                  <Form.Item
                    name="ssl_cert_path"
                    label="证书文件路径"
                    dependencies={['ssl_enabled', 'ssl_provider']}
                  >
                    <Input 
                      disabled={!domainForm.getFieldValue('ssl_enabled') || domainForm.getFieldValue('ssl_provider') !== 'custom'}
                      placeholder="/etc/ssl/certs/ipv6wg.crt"
                    />
                  </Form.Item>

                  <Form.Item
                    name="ssl_key_path"
                    label="私钥文件路径"
                    dependencies={['ssl_enabled', 'ssl_provider']}
                  >
                    <Input 
                      disabled={!domainForm.getFieldValue('ssl_enabled') || domainForm.getFieldValue('ssl_provider') !== 'custom'}
                      placeholder="/etc/ssl/private/ipv6wg.key"
                    />
                  </Form.Item>
                </div>

                <div>
                  <Title level={4}>证书内容</Title>
                  <Form.Item
                    name="ssl_cert_content"
                    label="SSL证书内容"
                    dependencies={['ssl_enabled', 'ssl_provider']}
                  >
                    <Input.TextArea
                      rows={6}
                      disabled={!domainForm.getFieldValue('ssl_enabled') || domainForm.getFieldValue('ssl_provider') !== 'custom'}
                      placeholder="-----BEGIN CERTIFICATE-----
MIIFjTCCA3WgAwIBAgIJAK...
-----END CERTIFICATE-----"
                    />
                  </Form.Item>

                  <Form.Item
                    name="ssl_key_content"
                    label="SSL私钥内容"
                    dependencies={['ssl_enabled', 'ssl_provider']}
                  >
                    <Input.TextArea
                      rows={6}
                      disabled={!domainForm.getFieldValue('ssl_enabled') || domainForm.getFieldValue('ssl_provider') !== 'custom'}
                      placeholder="-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0B...
-----END PRIVATE KEY-----"
                    />
                  </Form.Item>
                </div>
              </div>

              <Divider />

              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div>
                  <Title level={4}>DNS配置</Title>
                  <Form.Item
                    name="dns_provider"
                    label="DNS提供商"
                    dependencies={['ssl_enabled', 'ssl_provider']}
                  >
                    <Select disabled={!domainForm.getFieldValue('ssl_enabled') || domainForm.getFieldValue('ssl_provider') !== 'letsencrypt'}>
                      <Select.Option value="cloudflare">Cloudflare</Select.Option>
                      <Select.Option value="aliyun">阿里云DNS</Select.Option>
                      <Select.Option value="tencent">腾讯云DNS</Select.Option>
                      <Select.Option value="dnspod">DNSPod</Select.Option>
                    </Select>
                  </Form.Item>

                  <Form.Item
                    name="dns_api_key"
                    label="DNS API Key"
                    dependencies={['ssl_enabled', 'ssl_provider', 'dns_provider']}
                  >
                    <Input.Password 
                      disabled={!domainForm.getFieldValue('ssl_enabled') || domainForm.getFieldValue('ssl_provider') !== 'letsencrypt'}
                      placeholder="输入DNS API密钥"
                    />
                  </Form.Item>

                  <Form.Item
                    name="dns_api_secret"
                    label="DNS API Secret"
                    dependencies={['ssl_enabled', 'ssl_provider', 'dns_provider']}
                  >
                    <Input.Password 
                      disabled={!domainForm.getFieldValue('ssl_enabled') || domainForm.getFieldValue('ssl_provider') !== 'letsencrypt'}
                      placeholder="输入DNS API密钥"
                    />
                  </Form.Item>
                </div>

                <div>
                  <Title level={4}>操作</Title>
                  <Space direction="vertical" style={{ width: '100%' }}>
                    <Button 
                      type="primary" 
                      onClick={generateSSL} 
                      loading={loading}
                      disabled={!domainForm.getFieldValue('ssl_enabled')}
                      block
                    >
                      生成SSL证书
                    </Button>
                    
                    <Button 
                      htmlType="submit" 
                      loading={loading}
                      block
                    >
                      保存域名设置
                    </Button>
                  </Space>
                </div>
              </div>
            </Form>
          </Card>
        </TabPane>

        <TabPane 
          tab={
            <span>
              <ToolOutlined />
              系统管理
            </span>
          } 
          key="system-management"
        >
          <Card title="系统管理">
            <Alert
              message="危险操作警告"
              description="以下操作将影响整个系统，请谨慎操作。建议在执行前备份重要数据。"
              type="warning"
              showIcon
              style={{ marginBottom: 24 }}
            />

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <div>
                <Title level={4}>系统操作</Title>
                <div className="space-y-4">
                  <Card size="small" title="完全卸载系统">
                    <p className="text-gray-600 mb-4">
                      完全卸载IPv6 WireGuard Manager系统，包括：
                    </p>
                    <ul className="text-sm text-gray-600 mb-4 space-y-1">
                      <li>• 停止所有服务</li>
                      <li>• 删除应用文件</li>
                      <li>• 清理数据库</li>
                      <li>• 移除系统配置</li>
                    </ul>
                    <Button 
                      type="primary" 
                      danger 
                      onClick={() => handleSystemAction('uninstall')}
                      icon={<ExclamationCircleOutlined />}
                    >
                      完全卸载系统
                    </Button>
                  </Card>

                  <Card size="small" title="重新安装系统">
                    <p className="text-gray-600 mb-4">
                      重新安装IPv6 WireGuard Manager系统，包括：
                    </p>
                    <ul className="text-sm text-gray-600 mb-4 space-y-1">
                      <li>• 下载最新版本</li>
                      <li>• 重新安装依赖</li>
                      <li>• 恢复配置</li>
                      <li>• 重启服务</li>
                    </ul>
                    <Button 
                      type="primary" 
                      onClick={() => handleSystemAction('reinstall')}
                      icon={<ToolOutlined />}
                    >
                      重新安装系统
                    </Button>
                  </Card>
                </div>
              </div>

              <div>
                <Title level={4}>系统信息</Title>
                <div className="space-y-4">
                  <Card size="small" title="当前版本">
                    <p className="text-lg font-semibold">{systemInfo.version}</p>
                    <p className="text-sm text-gray-600">IPv6 WireGuard Manager</p>
                  </Card>

                  <Card size="small" title="安装时间">
                    <p className="text-lg font-semibold">{systemInfo.install_date}</p>
                    <p className="text-sm text-gray-600">系统首次安装时间</p>
                  </Card>

                  <Card size="small" title="系统状态">
                    <div className="space-y-2">
                      <div className="flex justify-between">
                        <span>后端服务</span>
                        <span className={systemInfo.backend_status === '运行中' ? 'text-green-600' : 'text-red-600'}>
                          {systemInfo.backend_status}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span>数据库</span>
                        <span className={systemInfo.database_status === '正常' ? 'text-green-600' : 'text-red-600'}>
                          {systemInfo.database_status}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span>Nginx</span>
                        <span className={systemInfo.nginx_status === '运行中' ? 'text-green-600' : 'text-red-600'}>
                          {systemInfo.nginx_status}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span>运行时间</span>
                        <span className="text-blue-600">{systemInfo.uptime}</span>
                      </div>
                    </div>
                  </Card>
                </div>
              </div>
            </div>

            <Divider />

            <div>
              <Title level={4}>备份与恢复</Title>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <Button 
                  type="default" 
                  block
                  onClick={() => message.info('备份功能开发中...')}
                >
                  创建备份
                </Button>
                <Button 
                  type="default" 
                  block
                  onClick={() => message.info('恢复功能开发中...')}
                >
                  恢复备份
                </Button>
                <Button 
                  type="default" 
                  block
                  onClick={() => message.info('导出功能开发中...')}
                >
                  导出配置
                </Button>
              </div>
            </div>
          </Card>
        </TabPane>
      </Tabs>

      {/* 系统操作确认模态框 */}
      <Modal
        title={
          <div className="flex items-center">
            <ExclamationCircleOutlined className="text-red-500 mr-2" />
            {systemAction === 'uninstall' ? '确认卸载系统' : '确认重新安装'}
          </div>
        }
        open={systemModalVisible}
        onCancel={cancelSystemAction}
        footer={null}
        width={600}
        closable={!loading}
        maskClosable={!loading}
      >
        <div className="space-y-4">
          <Alert
            message={systemAction === 'uninstall' ? '卸载警告' : '重新安装警告'}
            description={
              systemAction === 'uninstall' 
                ? '此操作将完全删除IPv6 WireGuard Manager系统，包括所有配置、用户数据和WireGuard配置。此操作不可逆！'
                : '此操作将重新安装IPv6 WireGuard Manager系统，当前配置将被备份并在安装后恢复。'
            }
            type="error"
            showIcon
          />

          <div>
            <p className="mb-2">
              请输入 <strong>{systemAction === 'uninstall' ? 'UNINSTALL' : 'REINSTALL'}</strong> 确认操作：
            </p>
            <Input
              value={systemConfirmText}
              onChange={(e) => setSystemConfirmText(e.target.value)}
              placeholder={`请输入 ${systemAction === 'uninstall' ? 'UNINSTALL' : 'REINSTALL'}`}
              disabled={loading}
            />
          </div>

          {loading && (
            <div>
              <Progress percent={systemProgress} status="active" />
              <div className="mt-2 max-h-32 overflow-y-auto">
                {systemLogs.map((log, index) => (
                  <div key={index} className="text-sm text-gray-600">
                    {log}
                  </div>
                ))}
              </div>
            </div>
          )}

          <div className="flex justify-end space-x-2">
            <Button onClick={cancelSystemAction} disabled={loading}>
              取消
            </Button>
            <Button
              type="primary"
              danger={systemAction === 'uninstall'}
              onClick={confirmSystemAction}
              loading={loading}
              disabled={systemConfirmText !== (systemAction === 'uninstall' ? 'UNINSTALL' : 'REINSTALL')}
            >
              {systemAction === 'uninstall' ? '确认卸载' : '确认重新安装'}
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  )
}

export default SettingsPage
