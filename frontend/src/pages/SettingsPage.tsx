import React, { useState, useEffect } from 'react'
import { Card, Typography, Tabs, Form, Input, Button, message, Space, Divider, Switch, Select, InputNumber, Checkbox } from 'antd'
import { UserOutlined, LockOutlined, MailOutlined, SettingOutlined, SecurityScanOutlined, GlobalOutlined } from '@ant-design/icons'

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

  useEffect(() => {
    loadUserProfile()
    loadSystemSettings()
    loadDomainSettings()
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
      </Tabs>
    </div>
  )
}

export default SettingsPage
