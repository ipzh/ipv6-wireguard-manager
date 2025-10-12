#!/bin/bash

# 环境配置脚本
echo "🔧 设置环境变量配置..."

# 前端环境配置
echo "📁 创建前端环境配置文件..."

# 开发环境配置
cat > frontend/.env.development << 'EOF'
# 开发环境配置
VITE_API_URL=http://127.0.0.1:8000
VITE_WS_URL=ws://127.0.0.1:8000/api/v1/ws
VITE_APP_TITLE=IPv6 WireGuard Manager (开发环境)
VITE_DEBUG=true
EOF

# 生产环境配置
cat > frontend/.env.production << 'EOF'
# 生产环境配置
VITE_API_URL=
VITE_WS_URL=ws://localhost/ws
VITE_APP_TITLE=IPv6 WireGuard Manager
VITE_DEBUG=false
EOF

# 环境变量示例文件
cat > frontend/.env.example << 'EOF'
# 环境变量配置示例
# 复制此文件为 .env.development 或 .env.production 并根据需要修改

# API配置
VITE_API_URL=http://127.0.0.1:8000
VITE_WS_URL=ws://127.0.0.1:8000/api/v1/ws

# 应用配置
VITE_APP_TITLE=IPv6 WireGuard Manager
VITE_DEBUG=false

# 生产环境配置示例
# VITE_API_URL=
# VITE_WS_URL=ws://your-domain.com/ws
# VITE_APP_TITLE=IPv6 WireGuard Manager
# VITE_DEBUG=false
EOF

# 后端环境配置
echo "📁 创建后端环境配置文件..."

# 开发环境配置
cat > backend/.env.development << 'EOF'
# 开发环境配置
DEBUG=true
DATABASE_URL=postgresql://ipv6wgm:ipv6wgm@localhost:5432/ipv6wgm
REDIS_URL=redis://localhost:6379/0
BACKEND_CORS_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:5173,http://localhost,http://127.0.0.1:3000,http://127.0.0.1:8080,http://127.0.0.1:5173,http://127.0.0.1
SECRET_KEY=your-secret-key-here
FIRST_SUPERUSER=admin
FIRST_SUPERUSER_PASSWORD=admin123
FIRST_SUPERUSER_EMAIL=admin@example.com
EOF

# 生产环境配置
cat > backend/.env.production << 'EOF'
# 生产环境配置
DEBUG=false
DATABASE_URL=postgresql://ipv6wgm:your-password@localhost:5432/ipv6wgm
REDIS_URL=redis://localhost:6379/0
BACKEND_CORS_ORIGINS=https://your-domain.com,http://your-domain.com
SECRET_KEY=your-production-secret-key-here
FIRST_SUPERUSER=admin
FIRST_SUPERUSER_PASSWORD=your-secure-password
FIRST_SUPERUSER_EMAIL=admin@your-domain.com
EOF

echo "✅ 环境配置文件创建完成"
echo ""
echo "📋 创建的文件:"
echo "   frontend/.env.development  - 前端开发环境配置"
echo "   frontend/.env.production   - 前端生产环境配置"
echo "   frontend/.env.example      - 前端环境变量示例"
echo "   backend/.env.development   - 后端开发环境配置"
echo "   backend/.env.production    - 后端生产环境配置"
echo ""
echo "🔧 使用方法:"
echo "   开发环境: 前端会自动使用 .env.development"
echo "   生产环境: 前端会自动使用 .env.production"
echo "   后端: 根据环境变量或手动指定配置文件"
echo ""
echo "⚠️  注意事项:"
echo "   1. 请根据实际情况修改数据库密码和密钥"
echo "   2. 生产环境请使用强密码和HTTPS"
echo "   3. 确保CORS配置包含所有需要的前端域名"
