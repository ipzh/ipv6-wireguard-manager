import React, { useState, useEffect } from 'react'
import { Card, Typography, Tag, Space, Button, Collapse, Alert } from 'antd'
import { 
  InfoCircleOutlined, 
  GlobalOutlined, 
  ApiOutlined,
  WifiOutlined,
  CopyOutlined,
  ReloadOutlined
} from '@ant-design/icons'
import { getNetworkInfo, generateConfigReport, config } from '../utils/config'

const { Title, Text, Paragraph } = Typography
const { Panel } = Collapse

interface ConfigInfoProps {
  showDetails?: boolean
}

const ConfigInfo: React.FC<ConfigInfoProps> = ({ showDetails = false }) => {
  const [networkInfo, setNetworkInfo] = useState(getNetworkInfo())
  const [configReport, setConfigReport] = useState('')

  useEffect(() => {
    setNetworkInfo(getNetworkInfo())
    setConfigReport(generateConfigReport())
  }, [])

  const handleRefresh = () => {
    setNetworkInfo(getNetworkInfo())
    setConfigReport(generateConfigReport())
  }

  const handleCopyConfig = () => {
    navigator.clipboard.writeText(configReport)
  }

  const getNetworkTypeColor = () => {
    if (networkInfo.isIPv6) return 'blue'
    if (networkInfo.isIPv4) return 'green'
    if (networkInfo.isLocal) return 'orange'
    return 'default'
  }

  const getNetworkTypeText = () => {
    if (networkInfo.isIPv6) return 'IPv6'
    if (networkInfo.isIPv4) return 'IPv4'
    if (networkInfo.isLocal) return '本地'
    return '未知'
  }

  return (
    <Card 
      title={
        <Space>
          <InfoCircleOutlined />
          <span>网络配置信息</span>
        </Space>
      }
      extra={
        <Space>
          <Button 
            icon={<ReloadOutlined />} 
            size="small" 
            onClick={handleRefresh}
          >
            刷新
          </Button>
          {showDetails && (
            <Button 
              icon={<CopyOutlined />} 
              size="small" 
              onClick={handleCopyConfig}
            >
              复制配置
            </Button>
          )}
        </Space>
      }
      size="small"
    >
      <Space direction="vertical" style={{ width: '100%' }}>
        {/* 网络信息 */}
        <div>
          <Space>
            <GlobalOutlined />
            <Text strong>网络类型:</Text>
            <Tag color={getNetworkTypeColor()}>
              {getNetworkTypeText()}
            </Tag>
          </Space>
        </div>

        <div>
          <Space>
            <WifiOutlined />
            <Text strong>主机地址:</Text>
            <Text code>{networkInfo.hostname}</Text>
            {networkInfo.port && (
              <>
                <Text strong>端口:</Text>
                <Text code>{networkInfo.port}</Text>
              </>
            )}
          </Space>
        </div>

        <div>
          <Space>
            <ApiOutlined />
            <Text strong>协议:</Text>
            <Tag color={networkInfo.protocol === 'https:' ? 'green' : 'blue'}>
              {networkInfo.protocol === 'https:' ? 'HTTPS' : 'HTTP'}
            </Tag>
          </Space>
        </div>

        {/* API配置 */}
        <div>
          <Text strong>API地址:</Text>
          <br />
          <Text code style={{ fontSize: '12px' }}>
            {config.apiUrl}
          </Text>
        </div>

        <div>
          <Text strong>WebSocket地址:</Text>
          <br />
          <Text code style={{ fontSize: '12px' }}>
            {config.wsUrl}
          </Text>
        </div>

        {/* 网络状态提示 */}
        {networkInfo.isLocal && (
          <Alert
            message="本地访问模式"
            description="当前为本地网络访问，API和WebSocket将使用本地地址"
            type="info"
            showIcon
            size="small"
          />
        )}

        {networkInfo.isIPv6 && (
          <Alert
            message="IPv6网络"
            description="检测到IPv6网络环境，系统已自动适配IPv6协议"
            type="success"
            showIcon
            size="small"
          />
        )}

        {/* 详细配置 */}
        {showDetails && (
          <Collapse size="small">
            <Panel header="详细配置信息" key="1">
              <pre style={{ 
                fontSize: '11px', 
                background: '#f5f5f5', 
                padding: '8px',
                borderRadius: '4px',
                overflow: 'auto',
                maxHeight: '300px'
              }}>
                {configReport}
              </pre>
            </Panel>
          </Collapse>
        )}
      </Space>
    </Card>
  )
}

export default ConfigInfo
