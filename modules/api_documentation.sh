#!/bin/bash

# API文档模块
# 实现OpenAPI/Swagger文档生成和管理

# API文档配置
API_DOCS_DIR="${WEB_INTERFACE_DIR}/api-docs"
SWAGGER_UI_DIR="${API_DOCS_DIR}/swagger-ui"
OPENAPI_SPEC_FILE="${API_DOCS_DIR}/openapi.yaml"

# 初始化API文档模块
init_api_documentation() {
    log_info "初始化API文档模块..."
    
    # 创建目录
    mkdir -p "$API_DOCS_DIR" "$SWAGGER_UI_DIR"
    
    # 下载Swagger UI
    download_swagger_ui
    
    # 生成OpenAPI规范
    generate_openapi_spec
    
    # 创建API文档页面
    create_api_docs_page
    
    log_info "API文档模块初始化完成"
}

# 下载Swagger UI
download_swagger_ui() {
    log_info "下载Swagger UI..."
    
    if [[ ! -d "${SWAGGER_UI_DIR}/dist" ]]; then
        local swagger_ui_url="https://github.com/swagger-api/swagger-ui/archive/refs/heads/master.tar.gz"
        local temp_dir="/tmp/swagger-ui"
        
        mkdir -p "$temp_dir"
        cd "$temp_dir"
        
        if command -v wget &> /dev/null; then
            wget -q "$swagger_ui_url" -O swagger-ui.tar.gz
        elif command -v curl &> /dev/null; then
            curl -L "$swagger_ui_url" -o swagger-ui.tar.gz
        else
            log_error "wget和curl都未安装，无法下载Swagger UI"
            return 1
        fi
        
        tar -xzf swagger-ui.tar.gz
        cp -r swagger-ui-master/dist/* "$SWAGGER_UI_DIR/"
        rm -rf "$temp_dir"
        
        log_info "Swagger UI下载完成"
    fi
}

# 生成OpenAPI规范
generate_openapi_spec() {
    log_info "生成OpenAPI规范..."
    
    cat > "$OPENAPI_SPEC_FILE" << 'EOF'
openapi: 3.0.3
info:
  title: IPv6 WireGuard Manager API
  description: IPv6 WireGuard VPN服务器管理API接口
  version: 1.0.0
  contact:
    name: IPv6 WireGuard Manager Team
    email: support@example.com
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT

servers:
  - url: http://localhost:8080/api
    description: 开发服务器
  - url: https://your-domain.com/api
    description: 生产服务器

security:
  - BearerAuth: []
  - ApiKeyAuth: []

paths:
  /auth/login:
    post:
      tags:
        - 认证
      summary: 用户登录
      description: 用户登录获取访问令牌
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - username
                - password
              properties:
                username:
                  type: string
                  description: 用户名
                password:
                  type: string
                  description: 密码
      responses:
        '200':
          description: 登录成功
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                  session_id:
                    type: string
                  user:
                    $ref: '#/components/schemas/User'
        '401':
          description: 认证失败
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'

  /auth/logout:
    post:
      tags:
        - 认证
      summary: 用户登出
      description: 用户登出，销毁会话
      responses:
        '200':
          description: 登出成功
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean

  /status/system:
    get:
      tags:
        - 系统状态
      summary: 获取系统状态
      description: 获取系统运行状态信息
      responses:
        '200':
          description: 系统状态
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SystemStatus'

  /status/wireguard:
    get:
      tags:
        - 系统状态
      summary: 获取WireGuard状态
      description: 获取WireGuard VPN服务状态
      responses:
        '200':
          description: WireGuard状态
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/WireGuardStatus'

  /status/bird:
    get:
      tags:
        - 系统状态
      summary: 获取BIRD状态
      description: 获取BIRD BGP路由服务状态
      responses:
        '200':
          description: BIRD状态
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/BirdStatus'

  /clients:
    get:
      tags:
        - 客户端管理
      summary: 获取客户端列表
      description: 获取所有客户端信息
      responses:
        '200':
          description: 客户端列表
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Client'
    post:
      tags:
        - 客户端管理
      summary: 创建客户端
      description: 创建新的客户端
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ClientCreate'
      responses:
        '201':
          description: 客户端创建成功
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Client'
        '400':
          description: 请求参数错误
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'

  /clients/{client_id}:
    get:
      tags:
        - 客户端管理
      summary: 获取客户端详情
      description: 获取指定客户端的详细信息
      parameters:
        - name: client_id
          in: path
          required: true
          schema:
            type: string
          description: 客户端ID
      responses:
        '200':
          description: 客户端详情
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Client'
        '404':
          description: 客户端不存在
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
    put:
      tags:
        - 客户端管理
      summary: 更新客户端
      description: 更新客户端信息
      parameters:
        - name: client_id
          in: path
          required: true
          schema:
            type: string
          description: 客户端ID
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ClientUpdate'
      responses:
        '200':
          description: 客户端更新成功
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Client'
        '404':
          description: 客户端不存在
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
    delete:
      tags:
        - 客户端管理
      summary: 删除客户端
      description: 删除指定客户端
      parameters:
        - name: client_id
          in: path
          required: true
          schema:
            type: string
          description: 客户端ID
      responses:
        '200':
          description: 客户端删除成功
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
        '404':
          description: 客户端不存在
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'

  /config/{config_type}:
    get:
      tags:
        - 配置管理
      summary: 获取配置
      description: 获取指定类型的配置
      parameters:
        - name: config_type
          in: path
          required: true
          schema:
            type: string
            enum: [main, wireguard, bird, firewall, client, monitoring]
          description: 配置类型
      responses:
        '200':
          description: 配置信息
          content:
            application/json:
              schema:
                type: object
        '404':
          description: 配置不存在
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
    put:
      tags:
        - 配置管理
      summary: 更新配置
      description: 更新指定类型的配置
      parameters:
        - name: config_type
          in: path
          required: true
          schema:
            type: string
            enum: [main, wireguard, bird, firewall, client, monitoring]
          description: 配置类型
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
      responses:
        '200':
          description: 配置更新成功
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
        '400':
          description: 配置验证失败
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'

  /network/topology:
    get:
      tags:
        - 网络管理
      summary: 获取网络拓扑
      description: 获取网络拓扑图数据
      responses:
        '200':
          description: 网络拓扑数据
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/NetworkTopology'

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key

  schemas:
    User:
      type: object
      properties:
        id:
          type: integer
        username:
          type: string
        role:
          type: string
        email:
          type: string
        created_at:
          type: string
          format: date-time
        last_login:
          type: string
          format: date-time

    SystemStatus:
      type: object
      properties:
        uptime:
          type: string
        cpu_usage:
          type: number
        memory_usage:
          type: number
        disk_usage:
          type: number
        load_average:
          type: array
          items:
            type: number

    WireGuardStatus:
      type: object
      properties:
        status:
          type: string
          enum: [running, stopped, error]
        interface:
          type: string
        port:
          type: integer
        public_key:
          type: string
        clients_count:
          type: integer

    BirdStatus:
      type: object
      properties:
        status:
          type: string
          enum: [running, stopped, error]
        version:
          type: string
        protocols:
          type: array
          items:
            type: string
        routes_count:
          type: integer

    Client:
      type: object
      properties:
        id:
          type: string
        name:
          type: string
        description:
          type: string
        email:
          type: string
        status:
          type: string
          enum: [online, offline, inactive]
        ipv4_address:
          type: string
        ipv6_address:
          type: string
        public_key:
          type: string
        created_at:
          type: string
          format: date-time
        last_handshake:
          type: string
          format: date-time

    ClientCreate:
      type: object
      required:
        - name
      properties:
        name:
          type: string
        description:
          type: string
        email:
          type: string

    ClientUpdate:
      type: object
      properties:
        name:
          type: string
        description:
          type: string
        email:
          type: string
        status:
          type: string
          enum: [active, inactive]

    NetworkTopology:
      type: object
      properties:
        nodes:
          type: array
          items:
            type: object
            properties:
              id:
                type: string
              name:
                type: string
              type:
                type: string
                enum: [server, client]
              x:
                type: number
              y:
                type: number
              status:
                type: string
                enum: [online, offline]
        connections:
          type: array
          items:
            type: object
            properties:
              from:
                type: string
              to:
                type: string
              type:
                type: string
              status:
                type: string
                enum: [active, inactive]

    Error:
      type: object
      properties:
        error:
          type: string
        message:
          type: string
        code:
          type: integer

tags:
  - name: 认证
    description: 用户认证相关接口
  - name: 系统状态
    description: 系统状态监控接口
  - name: 客户端管理
    description: 客户端管理接口
  - name: 配置管理
    description: 配置管理接口
  - name: 网络管理
    description: 网络管理接口
EOF
}

# 创建API文档页面
create_api_docs_page() {
    cat > "${API_DOCS_DIR}/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager API 文档</title>
    <link rel="stylesheet" type="text/css" href="./swagger-ui/swagger-ui.css" />
    <style>
        .swagger-ui .topbar { display: none; }
        .swagger-ui .info { margin: 20px 0; }
    </style>
</head>
<body>
    <div id="swagger-ui"></div>
    <script src="./swagger-ui/swagger-ui-bundle.js"></script>
    <script src="./swagger-ui/swagger-ui-standalone-preset.js"></script>
    <script>
        window.onload = function() {
            const ui = SwaggerUIBundle({
                url: './openapi.yaml',
                dom_id: '#swagger-ui',
                deepLinking: true,
                presets: [
                    SwaggerUIBundle.presets.apis,
                    SwaggerUIStandalonePreset
                ],
                plugins: [
                    SwaggerUIBundle.plugins.DownloadUrl
                ],
                layout: "StandaloneLayout",
                validatorUrl: null,
                docExpansion: "list",
                apisSorter: "alpha",
                operationsSorter: "alpha"
            });
        };
    </script>
</body>
</html>
EOF
}

# API文档菜单
api_documentation_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== API文档管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看API文档"
        echo -e "${GREEN}2.${NC} 重新生成文档"
        echo -e "${GREEN}3.${NC} 导出OpenAPI规范"
        echo -e "${GREEN}4.${NC} 验证API规范"
        echo -e "${GREEN}5.${NC} 文档设置"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -p "请选择操作 [0-5]: " choice
        
        case $choice in
            1) view_api_docs ;;
            2) regenerate_api_docs ;;
            3) export_openapi_spec ;;
            4) validate_api_spec ;;
            5) api_docs_settings ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 查看API文档
view_api_docs() {
    echo -e "${SECONDARY_COLOR}=== API文档 ===${NC}"
    echo
    
    if [[ -f "${API_DOCS_DIR}/index.html" ]]; then
        echo "API文档已生成，访问地址:"
        echo "http://localhost:8080/api-docs/"
        echo
        echo "按回车键在浏览器中打开..."
        read -p ""
        
        if command -v xdg-open &> /dev/null; then
            xdg-open "http://localhost:8080/api-docs/"
        elif command -v open &> /dev/null; then
            open "http://localhost:8080/api-docs/"
        else
            echo "请手动在浏览器中打开: http://localhost:8080/api-docs/"
        fi
    else
        show_error "API文档未生成"
    fi
}

# 重新生成API文档
regenerate_api_docs() {
    log_info "重新生成API文档..."
    
    generate_openapi_spec
    create_api_docs_page
    
    show_success "API文档已重新生成"
}

# 导出OpenAPI规范
export_openapi_spec() {
    local export_file=$(show_input "导出文件名" "openapi_spec.yaml")
    
    if [[ -n "$export_file" ]]; then
        cp "$OPENAPI_SPEC_FILE" "$export_file"
        show_success "OpenAPI规范已导出到: $export_file"
    fi
}

# 验证API规范
validate_api_spec() {
    log_info "验证OpenAPI规范..."
    
    if command -v swagger-codegen &> /dev/null; then
        swagger-codegen validate -i "$OPENAPI_SPEC_FILE"
        if [[ $? -eq 0 ]]; then
            show_success "OpenAPI规范验证通过"
        else
            show_error "OpenAPI规范验证失败"
        fi
    else
        show_warn "swagger-codegen未安装，跳过验证"
    fi
}

# API文档设置
api_docs_settings() {
    echo -e "${SECONDARY_COLOR}=== API文档设置 ===${NC}"
    echo
    
    local auto_generate=$(show_selection "自动生成文档" "启用" "禁用")
    local include_examples=$(show_selection "包含示例" "是" "否")
    local theme=$(show_selection "主题" "默认" "暗色" "浅色")
    
    # 保存设置
    cat > "${API_DOCS_DIR}/settings.json" << EOF
{
    "auto_generate": "$auto_generate",
    "include_examples": "$include_examples",
    "theme": "$theme"
}
EOF
    
    show_success "API文档设置已保存"
}

# 导出函数
export -f init_api_documentation download_swagger_ui generate_openapi_spec
export -f create_api_docs_page api_documentation_menu view_api_docs
export -f regenerate_api_docs export_openapi_spec validate_api_spec api_docs_settings
