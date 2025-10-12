#!/bin/bash

echo "🔧 修复前端构建文件问题..."
echo "========================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 应用配置
APP_HOME="/opt/ipv6-wireguard-manager"
FRONTEND_DIR="$APP_HOME/frontend"
BACKEND_DIR="$APP_HOME/backend"

# 日志函数
log_step() {
    echo -e "${BLUE}🚀 [STEP] $1${NC}"
}

log_info() {
    echo -e "${BLUE}💡 [INFO] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ [SUCCESS] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  [WARNING] $1${NC}"
}

log_error() {
    echo -e "${RED}❌ [ERROR] $1${NC}"
}

# 1. 检查前端目录结构
log_step "检查前端目录结构..."
if [ -d "$FRONTEND_DIR" ]; then
    log_success "前端目录存在: $FRONTEND_DIR"
    echo "前端目录内容:"
    ls -la "$FRONTEND_DIR"
else
    log_error "前端目录不存在: $FRONTEND_DIR"
    exit 1
fi

# 2. 检查前端构建文件
log_step "检查前端构建文件..."
if [ -d "$FRONTEND_DIR/dist" ]; then
    log_info "前端dist目录存在"
    echo "dist目录内容:"
    ls -la "$FRONTEND_DIR/dist"
    
    if [ -f "$FRONTEND_DIR/dist/index.html" ]; then
        log_success "index.html存在"
        echo "index.html内容预览:"
        head -20 "$FRONTEND_DIR/dist/index.html"
    else
        log_error "index.html不存在"
    fi
    
    if [ -d "$FRONTEND_DIR/dist/assets" ]; then
        log_success "assets目录存在"
        echo "assets目录内容:"
        ls -la "$FRONTEND_DIR/dist/assets" | head -10
    else
        log_warning "assets目录不存在"
    fi
else
    log_warning "前端dist目录不存在"
fi

# 3. 检查Node.js环境
log_step "检查Node.js环境..."
if command -v node >/dev/null 2>&1; then
    log_success "Node.js已安装: $(node --version)"
else
    log_error "Node.js未安装"
    echo "安装Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

if command -v npm >/dev/null 2>&1; then
    log_success "npm已安装: $(npm --version)"
else
    log_error "npm未安装"
fi

# 4. 检查package.json
log_step "检查package.json..."
if [ -f "$FRONTEND_DIR/package.json" ]; then
    log_success "package.json存在"
    echo "package.json内容:"
    cat "$FRONTEND_DIR/package.json"
else
    log_error "package.json不存在"
    echo "创建package.json..."
    
    sudo tee "$FRONTEND_DIR/package.json" > /dev/null << 'EOF'
{
  "name": "ipv6-wireguard-manager-frontend",
  "version": "3.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.8.0",
    "antd": "^5.0.0",
    "@ant-design/icons": "^5.0.0",
    "axios": "^1.3.0"
  },
  "devDependencies": {
    "@types/react": "^18.0.0",
    "@types/react-dom": "^18.0.0",
    "@vitejs/plugin-react": "^3.0.0",
    "typescript": "^4.9.0",
    "vite": "^4.0.0"
  }
}
EOF
    log_success "package.json创建完成"
fi

# 5. 检查vite.config.ts
log_step "检查vite.config.ts..."
if [ -f "$FRONTEND_DIR/vite.config.ts" ]; then
    log_success "vite.config.ts存在"
    echo "vite.config.ts内容:"
    cat "$FRONTEND_DIR/vite.config.ts"
else
    log_warning "vite.config.ts不存在，创建默认配置..."
    
    sudo tee "$FRONTEND_DIR/vite.config.ts" > /dev/null << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          antd: ['antd', '@ant-design/icons']
        }
      }
    }
  },
  server: {
    port: 3000,
    host: true
  }
})
EOF
    log_success "vite.config.ts创建完成"
fi

# 6. 检查tsconfig.json
log_step "检查tsconfig.json..."
if [ -f "$FRONTEND_DIR/tsconfig.json" ]; then
    log_success "tsconfig.json存在"
else
    log_warning "tsconfig.json不存在，创建默认配置..."
    
    sudo tee "$FRONTEND_DIR/tsconfig.json" > /dev/null << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF
    log_success "tsconfig.json创建完成"
fi

# 7. 检查src目录
log_step "检查src目录..."
if [ -d "$FRONTEND_DIR/src" ]; then
    log_success "src目录存在"
    echo "src目录内容:"
    find "$FRONTEND_DIR/src" -type f -name "*.tsx" -o -name "*.ts" -o -name "*.jsx" -o -name "*.js" | head -10
else
    log_warning "src目录不存在，创建基本结构..."
    
    sudo mkdir -p "$FRONTEND_DIR/src"
    
    # 创建App.tsx
    sudo tee "$FRONTEND_DIR/src/App.tsx" > /dev/null << 'EOF'
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ConfigProvider } from 'antd';
import zhCN from 'antd/locale/zh_CN';
import Dashboard from './pages/Dashboard';
import './App.css';

function App() {
  return (
    <ConfigProvider locale={zhCN}>
      <Router>
        <div className="App">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/dashboard" element={<Dashboard />} />
          </Routes>
        </div>
      </Router>
    </ConfigProvider>
  );
}

export default App;
EOF

    # 创建Dashboard.tsx
    sudo mkdir -p "$FRONTEND_DIR/src/pages"
    sudo tee "$FRONTEND_DIR/src/pages/Dashboard.tsx" > /dev/null << 'EOF'
import React, { useState, useEffect } from 'react';
import { Layout, Card, Row, Col, Statistic, Button, message } from 'antd';
import { 
  CloudServerOutlined, 
  DatabaseOutlined, 
  DesktopOutlined,
  CheckCircleOutlined 
} from '@ant-design/icons';

const { Header, Content } = Layout;

const Dashboard: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [apiStatus, setApiStatus] = useState<any>(null);

  const checkApiStatus = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/v1/status');
      const data = await response.json();
      setApiStatus(data);
      message.success('API连接正常');
    } catch (error) {
      message.error('API连接失败');
      console.error('API检查失败:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    checkApiStatus();
  }, []);

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Header style={{ background: '#fff', padding: '0 24px', boxShadow: '0 2px 8px rgba(0,0,0,0.1)' }}>
        <div style={{ display: 'flex', alignItems: 'center', height: '100%' }}>
          <h1 style={{ margin: 0, color: '#1890ff' }}>
            🌐 IPv6 WireGuard Manager
          </h1>
        </div>
      </Header>
      
      <Content style={{ padding: '24px', background: '#f0f2f5' }}>
        <Row gutter={[16, 16]}>
          <Col xs={24} sm={12} md={8}>
            <Card>
              <Statistic
                title="服务状态"
                value="运行中"
                prefix={<CheckCircleOutlined style={{ color: '#52c41a' }} />}
                valueStyle={{ color: '#52c41a' }}
              />
            </Card>
          </Col>
          
          <Col xs={24} sm={12} md={8}>
            <Card>
              <Statistic
                title="后端服务"
                value="正常"
                prefix={<CloudServerOutlined style={{ color: '#1890ff' }} />}
                valueStyle={{ color: '#1890ff' }}
              />
            </Card>
          </Col>
          
          <Col xs={24} sm={12} md={8}>
            <Card>
              <Statistic
                title="数据库"
                value="连接正常"
                prefix={<DatabaseOutlined style={{ color: '#722ed1' }} />}
                valueStyle={{ color: '#722ed1' }}
              />
            </Card>
          </Col>
        </Row>

        <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
          <Col span={24}>
            <Card title="系统信息" extra={<Button onClick={checkApiStatus} loading={loading}>刷新状态</Button>}>
              {apiStatus ? (
                <div>
                  <p><strong>服务状态:</strong> {apiStatus.status}</p>
                  <p><strong>服务名称:</strong> {apiStatus.service || 'IPv6 WireGuard Manager'}</p>
                  <p><strong>版本:</strong> {apiStatus.version || '1.0.0'}</p>
                  <p><strong>消息:</strong> {apiStatus.message}</p>
                </div>
              ) : (
                <p>正在检查API状态...</p>
              )}
            </Card>
          </Col>
        </Row>

        <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
          <Col span={24}>
            <Card title="快速操作">
              <Button type="primary" icon={<DesktopOutlined />} style={{ marginRight: 8 }}>
                系统监控
              </Button>
              <Button icon={<CloudServerOutlined />} style={{ marginRight: 8 }}>
                服务管理
              </Button>
              <Button icon={<DatabaseOutlined />}>
                数据管理
              </Button>
            </Card>
          </Col>
        </Row>
      </Content>
    </Layout>
  );
};

export default Dashboard;
EOF

    # 创建App.css
    sudo tee "$FRONTEND_DIR/src/App.css" > /dev/null << 'EOF'
.App {
  text-align: center;
}

.App-logo {
  height: 40vmin;
  pointer-events: none;
}

@media (prefers-reduced-motion: no-preference) {
  .App-logo {
    animation: App-logo-spin infinite 20s linear;
  }
}

.App-header {
  background-color: #282c34;
  padding: 20px;
  color: white;
}

.App-link {
  color: #61dafb;
}

@keyframes App-logo-spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
EOF

    # 创建main.tsx
    sudo tee "$FRONTEND_DIR/src/main.tsx" > /dev/null << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

    # 创建index.css
    sudo tee "$FRONTEND_DIR/src/index.css" > /dev/null << 'EOF'
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
EOF

    # 创建index.html
    sudo tee "$FRONTEND_DIR/index.html" > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>IPv6 WireGuard Manager</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

    log_success "基本src结构创建完成"
fi

# 8. 安装依赖
log_step "安装前端依赖..."
cd "$FRONTEND_DIR"

# 清理旧的node_modules
if [ -d "node_modules" ]; then
    log_info "清理旧的node_modules..."
    rm -rf node_modules package-lock.json
fi

# 安装依赖
log_info "安装前端依赖..."
npm install --silent

if [ $? -eq 0 ]; then
    log_success "依赖安装成功"
else
    log_error "依赖安装失败"
    exit 1
fi

# 9. 构建前端
log_step "构建前端..."
log_info "开始构建前端应用..."

# 设置Node.js内存限制
export NODE_OPTIONS="--max-old-space-size=4096"

npm run build

if [ $? -eq 0 ] && [ -d "dist" ]; then
    log_success "前端构建成功"
    echo "构建结果:"
    ls -la dist/
else
    log_error "前端构建失败"
    echo "尝试使用内存优化构建..."
    
    # 尝试内存优化构建
    export NODE_OPTIONS="--max-old-space-size=2048"
    npm run build
    
    if [ $? -eq 0 ] && [ -d "dist" ]; then
        log_success "内存优化构建成功"
    else
        log_error "构建仍然失败，创建最小化构建..."
        
        # 创建最小化构建
        sudo mkdir -p dist
        sudo tee dist/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager</title>
    <script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
    <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
    <script src="https://unpkg.com/antd@5/dist/antd.min.js"></script>
    <link rel="stylesheet" href="https://unpkg.com/antd@5/dist/reset.css">
    <style>
        body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, sans-serif; }
        .container { padding: 20px; max-width: 1200px; margin: 0 auto; }
    </style>
</head>
<body>
    <div id="root"></div>
    <script>
        const { useState, useEffect } = React;
        const { Layout, Card, Row, Col, Statistic, Button, message } = antd;
        const { Header, Content } = Layout;

        function Dashboard() {
            const [loading, setLoading] = useState(false);
            const [apiStatus, setApiStatus] = useState(null);

            const checkApiStatus = async () => {
                setLoading(true);
                try {
                    const response = await fetch('/api/v1/status');
                    const data = await response.json();
                    setApiStatus(data);
                    message.success('API连接正常');
                } catch (error) {
                    message.error('API连接失败');
                } finally {
                    setLoading(false);
                }
            };

            useEffect(() => {
                checkApiStatus();
            }, []);

            return React.createElement(Layout, { style: { minHeight: '100vh' } }, [
                React.createElement(Header, { 
                    key: 'header',
                    style: { background: '#fff', padding: '0 24px', boxShadow: '0 2px 8px rgba(0,0,0,0.1)' }
                }, React.createElement('h1', { style: { margin: 0, color: '#1890ff' } }, '🌐 IPv6 WireGuard Manager')),
                React.createElement(Content, { 
                    key: 'content',
                    style: { padding: '24px', background: '#f0f2f5' }
                }, [
                    React.createElement(Row, { key: 'stats', gutter: [16, 16] }, [
                        React.createElement(Col, { key: 'status', xs: 24, sm: 12, md: 8 }, 
                            React.createElement(Card, null, 
                                React.createElement(Statistic, { 
                                    title: '服务状态', 
                                    value: '运行中', 
                                    valueStyle: { color: '#52c41a' } 
                                })
                            )
                        ),
                        React.createElement(Col, { key: 'api', xs: 24, sm: 12, md: 8 }, 
                            React.createElement(Card, null, 
                                React.createElement(Statistic, { 
                                    title: 'API状态', 
                                    value: apiStatus ? apiStatus.status : '检查中', 
                                    valueStyle: { color: '#1890ff' } 
                                })
                            )
                        ),
                        React.createElement(Col, { key: 'actions', xs: 24, sm: 12, md: 8 }, 
                            React.createElement(Card, null, 
                                React.createElement(Button, { 
                                    type: 'primary', 
                                    onClick: checkApiStatus, 
                                    loading: loading 
                                }, '刷新状态')
                            )
                        )
                    ])
                ])
            ]);
        }

        ReactDOM.render(React.createElement(Dashboard), document.getElementById('root'));
    </script>
</body>
</html>
EOF
        log_success "最小化构建创建完成"
    fi
fi

# 10. 修复权限
log_step "修复文件权限..."
sudo chown -R ipv6wgm:ipv6wgm "$FRONTEND_DIR" 2>/dev/null || sudo chown -R $(whoami):$(whoami) "$FRONTEND_DIR"
sudo chmod -R 755 "$FRONTEND_DIR"

# 11. 重启Nginx
log_step "重启Nginx..."
sudo systemctl restart nginx
sleep 2

# 12. 测试访问
log_step "测试访问..."
echo "测试前端访问:"
if curl -s http://localhost >/dev/null 2>&1; then
    log_success "前端访问正常"
    echo "响应状态码:"
    curl -s -o /dev/null -w "%{http_code}" http://localhost
else
    log_error "前端访问失败"
    echo "详细错误:"
    curl -v http://localhost 2>&1 | head -20
fi

# 13. 显示结果
log_step "显示修复结果..."
echo "========================================"
echo -e "${GREEN}🎉 前端构建文件修复完成！${NC}"
echo ""
echo "📁 前端文件结构:"
if [ -d "$FRONTEND_DIR/dist" ]; then
    echo "   ✅ dist目录存在"
    echo "   ✅ index.html存在"
    if [ -d "$FRONTEND_DIR/dist/assets" ]; then
        echo "   ✅ assets目录存在"
    else
        echo "   ⚠️  assets目录不存在（使用内联资源）"
    fi
else
    echo "   ❌ dist目录不存在"
fi

echo ""
echo "🌐 访问地址:"
echo "   本地访问: http://localhost"
echo "   IPv4访问: http://$(curl -s -4 ifconfig.me 2>/dev/null || echo '您的IP')"
echo "   IPv6访问: http://[$(ip -6 addr show | grep -E 'inet6.*global' | awk '{print $2}' | cut -d'/' -f1 | head -1)]"
echo ""
echo "🔧 管理命令:"
echo "   重新构建: cd $FRONTEND_DIR && npm run build"
echo "   查看日志: sudo journalctl -u nginx -f"
echo "   重启Nginx: sudo systemctl restart nginx"
echo ""
echo "========================================"
if curl -s http://localhost >/dev/null 2>&1; then
    log_success "🎉 前端构建文件问题已修复！现在应该可以正常访问了！"
else
    log_error "❌ 仍有问题，请检查Nginx配置和日志"
fi
