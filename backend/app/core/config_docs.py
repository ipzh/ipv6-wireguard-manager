"""
配置文档生成器
自动生成配置项文档和环境变量说明
"""

import os
from typing import Dict, Any, List
from pathlib import Path
import logging
from .config_manager import config_manager, ConfigMetadata
from .environment import EnvironmentType

logger = logging.getLogger(__name__)

class ConfigDocumentationGenerator:
    """配置文档生成器"""
    
    def __init__(self, output_dir: str = "docs"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
    
    def generate_all_docs(self):
        """生成所有配置文档"""
        # 生成配置项文档
        self.generate_config_items_doc()
        
        # 生成环境变量文档
        self.generate_environment_variables_doc()
        
        # 生成环境特定配置文档
        self.generate_environment_specific_doc()
        
        # 生成配置示例文档
        self.generate_config_examples_doc()
        
        logger.info(f"配置文档已生成到: {self.output_dir}")
    
    def generate_config_items_doc(self):
        """生成配置项文档"""
        doc = "# 配置项文档\n\n"
        doc += "本文档描述了IPv6 WireGuard Manager的所有配置项及其用途。\n\n"
        
        # 按类别组织配置项
        categories = {
            "应用配置": ["APP_NAME", "APP_VERSION", "DEBUG", "ENVIRONMENT"],
            "API配置": ["API_V1_STR", "SECRET_KEY", "ACCESS_TOKEN_EXPIRE_MINUTES", "ALGORITHM"],
            "服务器配置": ["SERVER_NAME", "SERVER_HOST", "SERVER_PORT"],
            "数据库配置": [
                "DATABASE_URL", "DATABASE_HOST", "DATABASE_PORT", "DATABASE_USER", 
                "DATABASE_PASSWORD", "DATABASE_NAME", "DATABASE_POOL_SIZE", 
                "DATABASE_MAX_OVERFLOW", "DATABASE_CONNECT_TIMEOUT", 
                "DATABASE_STATEMENT_TIMEOUT", "DATABASE_IDLE_IN_TRANSACTION_SESSION_TIMEOUT",
                "DATABASE_POOL_RECYCLE", "DATABASE_POOL_PRE_PING", "AUTO_CREATE_DATABASE"
            ],
            "Redis配置": ["REDIS_URL", "REDIS_POOL_SIZE", "USE_REDIS"],
            "安全配置": ["BACKEND_CORS_ORIGINS"],
            "文件上传配置": ["MAX_FILE_SIZE", "UPLOAD_DIR", "ALLOWED_EXTENSIONS"],
            "WireGuard配置": ["WIREGUARD_CONFIG_DIR", "WIREGUARD_CLIENTS_DIR"],
            "监控配置": ["ENABLE_METRICS", "METRICS_PORT", "ENABLE_HEALTH_CHECK", "HEALTH_CHECK_INTERVAL"],
            "日志配置": ["LOG_LEVEL", "LOG_FORMAT", "LOG_FILE", "LOG_ROTATION", "LOG_RETENTION"],
            "性能配置": ["MAX_WORKERS", "WORKER_CLASS", "KEEP_ALIVE", "MAX_REQUESTS", "MAX_REQUESTS_JITTER"],
            "邮件配置": [
                "SMTP_TLS", "SMTP_PORT", "SMTP_HOST", "SMTP_USER", 
                "SMTP_PASSWORD", "EMAILS_FROM_EMAIL", "EMAILS_FROM_NAME"
            ],
            "超级用户配置": ["FIRST_SUPERUSER", "FIRST_SUPERUSER_PASSWORD", "FIRST_SUPERUSER_EMAIL"]
        }
        
        for category, keys in categories.items():
            doc += f"## {category}\n\n"
            
            for key in keys:
                if key in config_manager.config_metadata:
                    metadata = config_manager.config_metadata[key]
                    doc += f"### {key}\n\n"
                    doc += f"**描述**: {metadata.description}\n\n"
                    doc += f"**类型**: {metadata.type.__name__}\n\n"
                    doc += f"**默认值**: `{metadata.default}`\n\n"
                    doc += f"**必需**: {'是' if metadata.required else '否'}\n\n"
                    doc += f"**敏感**: {'是' if metadata.sensitive else '否'}\n\n"
                    doc += f"**环境变量**: `{metadata.env_var}`\n\n"
                    
                    if key in config_manager.config_data:
                        value = config_manager.config_data[key]
                        if metadata.sensitive and value:
                            value = '*' * len(str(value))
                        doc += f"**当前值**: `{value}`\n\n"
                    
                    doc += "---\n\n"
        
        # 写入文件
        output_path = self.output_dir / "config_items.md"
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(doc)
        
        logger.info(f"配置项文档已生成: {output_path}")
    
    def generate_environment_variables_doc(self):
        """生成环境变量文档"""
        doc = "# 环境变量文档\n\n"
        doc += "本文档描述了可以通过环境变量设置的配置项。\n\n"
        
        # 按类别组织环境变量
        categories = {
            "应用环境变量": {
                "APP_NAME": "应用名称",
                "APP_VERSION": "应用版本",
                "DEBUG": "调试模式 (true/false)",
                "ENVIRONMENT": "运行环境 (development/testing/staging/production)"
            },
            "API环境变量": {
                "API_V1_STR": "API路径前缀",
                "SECRET_KEY": "JWT密钥",
                "ACCESS_TOKEN_EXPIRE_MINUTES": "访问令牌过期时间(分钟)",
                "ALGORITHM": "加密算法"
            },
            "服务器环境变量": {
                "SERVER_NAME": "服务器名称",
                "SERVER_HOST": "服务器主机",
                "SERVER_PORT": "服务器端口"
            },
            "数据库环境变量": {
                "DATABASE_URL": "数据库连接URL",
                "DATABASE_HOST": "数据库主机",
                "DATABASE_PORT": "数据库端口",
                "DATABASE_USER": "数据库用户名",
                "DATABASE_PASSWORD": "数据库密码",
                "DATABASE_NAME": "数据库名称",
                "DATABASE_POOL_SIZE": "数据库连接池大小",
                "DATABASE_MAX_OVERFLOW": "数据库连接池最大溢出",
                "DATABASE_CONNECT_TIMEOUT": "数据库连接超时(秒)",
                "DATABASE_STATEMENT_TIMEOUT": "数据库语句超时(毫秒)",
                "DATABASE_IDLE_IN_TRANSACTION_SESSION_TIMEOUT": "空闲事务超时(毫秒)",
                "DATABASE_POOL_RECYCLE": "数据库连接回收时间(秒)",
                "DATABASE_POOL_PRE_PING": "数据库连接预检查 (true/false)",
                "AUTO_CREATE_DATABASE": "自动创建数据库 (true/false)"
            },
            "Redis环境变量": {
                "REDIS_URL": "Redis连接URL",
                "REDIS_POOL_SIZE": "Redis连接池大小",
                "USE_REDIS": "是否使用Redis (true/false)"
            },
            "安全环境变量": {
                "BACKEND_CORS_ORIGINS": "CORS允许的源 (逗号分隔)"
            },
            "文件上传环境变量": {
                "MAX_FILE_SIZE": "最大文件大小(字节)",
                "UPLOAD_DIR": "上传目录",
                "ALLOWED_EXTENSIONS": "允许的文件扩展名 (逗号分隔)"
            },
            "WireGuard环境变量": {
                "WIREGUARD_CONFIG_DIR": "WireGuard配置目录",
                "WIREGUARD_CLIENTS_DIR": "WireGuard客户端配置目录"
            },
            "监控环境变量": {
                "ENABLE_METRICS": "是否启用指标 (true/false)",
                "METRICS_PORT": "指标端口",
                "ENABLE_HEALTH_CHECK": "是否启用健康检查 (true/false)",
                "HEALTH_CHECK_INTERVAL": "健康检查间隔(秒)"
            },
            "日志环境变量": {
                "LOG_LEVEL": "日志级别 (DEBUG/INFO/WARNING/ERROR/CRITICAL)",
                "LOG_FORMAT": "日志格式 (json/text)",
                "LOG_FILE": "日志文件路径",
                "LOG_ROTATION": "日志轮转",
                "LOG_RETENTION": "日志保留时间"
            },
            "性能环境变量": {
                "MAX_WORKERS": "最大工作进程数",
                "WORKER_CLASS": "工作进程类",
                "KEEP_ALIVE": "连接保持时间(秒)",
                "MAX_REQUESTS": "最大请求数",
                "MAX_REQUESTS_JITTER": "最大请求数抖动"
            },
            "邮件环境变量": {
                "SMTP_TLS": "SMTP是否使用TLS (true/false)",
                "SMTP_PORT": "SMTP端口",
                "SMTP_HOST": "SMTP主机",
                "SMTP_USER": "SMTP用户名",
                "SMTP_PASSWORD": "SMTP密码",
                "EMAILS_FROM_EMAIL": "发件人邮箱",
                "EMAILS_FROM_NAME": "发件人名称"
            },
            "超级用户环境变量": {
                "FIRST_SUPERUSER": "超级用户名",
                "FIRST_SUPERUSER_PASSWORD": "超级用户密码",
                "FIRST_SUPERUSER_EMAIL": "超级用户邮箱"
            }
        }
        
        for category, vars in categories.items():
            doc += f"## {category}\n\n"
            
            for var, desc in vars.items():
                doc += f"### {var}\n\n"
                doc += f"**描述**: {desc}\n\n"
                
                # 获取当前值
                if var in config_manager.config_data:
                    value = config_manager.config_data[var]
                    metadata = config_manager.config_metadata.get(var)
                    if metadata and metadata.sensitive and value:
                        value = '*' * len(str(value))
                    doc += f"**当前值**: `{value}`\n\n"
                
                doc += "**示例**:\n\n"
                doc += "```bash\n"
                doc += f"export {var}=<value>\n"
                doc += "```\n\n"
                
                doc += "---\n\n"
        
        # 写入文件
        output_path = self.output_dir / "environment_variables.md"
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(doc)
        
        logger.info(f"环境变量文档已生成: {output_path}")
    
    def generate_environment_specific_doc(self):
        """生成环境特定配置文档"""
        doc = "# 环境特定配置文档\n\n"
        doc += "本文档描述了不同环境下的特定配置。\n\n"
        
        # 环境特定配置
        env_configs = {
            EnvironmentType.DEVELOPMENT.value: {
                "描述": "开发环境配置",
                "特点": [
                    "启用调试模式",
                    "详细日志输出",
                    "较小的数据库连接池",
                    "宽松的安全设置"
                ],
                "配置": {
                    "DEBUG": "true",
                    "LOG_LEVEL": "DEBUG",
                    "DATABASE_POOL_SIZE": "5",
                    "DATABASE_MAX_OVERFLOW": "10",
                    "BACKEND_CORS_ORIGINS": "*"
                }
            },
            EnvironmentType.TESTING.value: {
                "描述": "测试环境配置",
                "特点": [
                    "启用调试模式",
                    "详细日志输出",
                    "使用测试数据库",
                    "模拟生产环境设置"
                ],
                "配置": {
                    "DEBUG": "true",
                    "LOG_LEVEL": "DEBUG",
                    "DATABASE_NAME": "ipv6wgm_test",
                    "AUTO_CREATE_DATABASE": "true"
                }
            },
            EnvironmentType.STAGING.value: {
                "描述": "预发布环境配置",
                "特点": [
                    "禁用调试模式",
                    "中等详细日志",
                    "接近生产的数据库设置",
                    "受限的安全设置"
                ],
                "配置": {
                    "DEBUG": "false",
                    "LOG_LEVEL": "INFO",
                    "DATABASE_POOL_SIZE": "20",
                    "DATABASE_MAX_OVERFLOW": "40",
                    "BACKEND_CORS_ORIGINS": "https://staging.yourdomain.com"
                }
            },
            EnvironmentType.PRODUCTION.value: {
                "描述": "生产环境配置",
                "特点": [
                    "禁用调试模式",
                    "最小日志输出",
                    "优化的数据库设置",
                    "严格的安全设置"
                ],
                "配置": {
                    "DEBUG": "false",
                    "LOG_LEVEL": "WARNING",
                    "DATABASE_POOL_SIZE": "50",
                    "DATABASE_MAX_OVERFLOW": "100",
                    "DATABASE_CONNECT_TIMEOUT": "60",
                    "BACKEND_CORS_ORIGINS": "https://yourdomain.com"
                }
            }
        }
        
        for env, config in env_configs.items():
            doc += f"## {env.upper()} 环境\n\n"
            doc += f"**描述**: {config['描述']}\n\n"
            doc += "**特点**:\n\n"
            
            for feature in config['特点']:
                doc += f"- {feature}\n"
            
            doc += "\n**配置**:\n\n"
            
            for key, value in config['配置'].items():
                doc += f"- `{key}`: `{value}`\n"
            
            doc += "\n---\n\n"
        
        # 写入文件
        output_path = self.output_dir / "environment_specific.md"
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(doc)
        
        logger.info(f"环境特定配置文档已生成: {output_path}")
    
    def generate_config_examples_doc(self):
        """生成配置示例文档"""
        doc = "# 配置示例文档\n\n"
        doc += "本文档提供了各种配置场景的示例。\n\n"
        
        # .env文件示例
        doc += "## .env文件示例\n\n"
        doc += "```bash\n"
        doc += "# 应用配置\n"
        doc += "APP_NAME=\"IPv6 WireGuard Manager\"\n"
        doc += "APP_VERSION=\"3.0.0\"\n"
        doc += "DEBUG=true\n"
        doc += "ENVIRONMENT=\"development\"\n\n"
        
        doc += "# API配置\n"
        doc += "API_V1_STR=\"/api/v1\"\n"
        doc += "SECRET_KEY=\"your-secret-key-here-change-in-production\"\n"
        doc += "ACCESS_TOKEN_EXPIRE_MINUTES=1440\n\n"
        
        doc += "# 服务器配置\n"
        doc += "SERVER_HOST=\"${SERVER_HOST}\"\n"
        doc += "SERVER_PORT=8000\n\n"
        
        doc += "# 数据库配置\n"
        doc += "DATABASE_URL=\"sqlite:///./ipv6_wireguard.db\"\n"
        doc += "DATABASE_HOST=\"localhost\"\n"
        doc += "DATABASE_PORT=3306\n"
        doc += "DATABASE_USER=\"ipv6wgm\"\n"
        doc += "DATABASE_PASSWORD=\"password\"\n"
        doc += "DATABASE_NAME=\"ipv6wgm\"\n\n"
        
        doc += "# Redis配置（可选）\n"
        doc += "REDIS_URL=\"redis://localhost:${REDIS_PORT}/0\"\n"
        doc += "USE_REDIS=false\n\n"
        
        doc += "# 日志配置\n"
        doc += "LOG_LEVEL=\"INFO\"\n"
        doc += "LOG_FORMAT=\"json\"\n\n"
        
        doc += "# 超级用户配置\n"
        doc += "FIRST_SUPERUSER=\"admin\"\n"
        doc += "FIRST_SUPERUSER_PASSWORD=\"admin123\"\n"
        doc += "FIRST_SUPERUSER_EMAIL=\"admin@example.com\"\n\n"
        
        doc += "# CORS配置\n"
        doc += "BACKEND_CORS_ORIGINS=\"http://localhost:${FRONTEND_PORT},http://localhost:${ADMIN_PORT}\"\n"
        doc += "```\n\n"
        
        # 配置文件示例
        doc += "## 配置文件示例\n\n"
        doc += "### config/development.json\n\n"
        doc += "```json\n"
        doc += "{\n"
        doc += "  \"app\": {\n"
        doc += "    \"debug\": true\n"
        doc += "  },\n"
        doc += "  \"database\": {\n"
        doc += "    \"password\": \"password\"\n"
        doc += "  },\n"
        doc += "  \"logging\": {\n"
        doc += "    \"level\": \"DEBUG\"\n"
        doc += "  }\n"
        doc += "}\n"
        doc += "```\n\n"
        
        doc += "### config/production.json\n\n"
        doc += "```json\n"
        doc += "{\n"
        doc += "  \"app\": {\n"
        doc += "    \"debug\": false\n"
        doc += "  },\n"
        doc += "  \"database\": {\n"
        doc += "    \"pool_size\": 50,\n"
        doc += "    \"max_overflow\": 100,\n"
        doc += "    \"connect_timeout\": 60\n"
        doc += "  },\n"
        doc += "  \"security\": {\n"
        doc += "    \"cors_origins\": [\n"
        doc += "      \"https://yourdomain.com\"\n"
        doc += "    ]\n"
        doc += "  },\n"
        doc += "  \"logging\": {\n"
        doc += "    \"level\": \"WARNING\"\n"
        doc += "  }\n"
        doc += "}\n"
        doc += "```\n\n"
        
        # Docker环境变量示例
        doc += "## Docker环境变量示例\n\n"
        doc += "```bash\n"
        doc += "docker run -d \\\n"
        doc += "  -e ENVIRONMENT=\"production\" \\\n"
        doc += "  -e DATABASE_URL=\"sqlite:///./ipv6_wireguard.db" \\\n"
        doc += "  -e SECRET_KEY=\"your-secret-key\" \\\n"
        doc += "  -e FIRST_SUPERUSER_PASSWORD=\"secure-password\" \\\n"
        doc += "  -p 8000:${API_PORT} \\\n"
        doc += "  ipv6-wireguard-manager\n"
        doc += "```\n\n"
        
        # Kubernetes ConfigMap示例
        doc += "## Kubernetes ConfigMap示例\n\n"
        doc += "```yaml\n"
        doc += "apiVersion: v1\n"
        doc += "kind: ConfigMap\n"
        doc += "metadata:\n"
        doc += "  name: ipv6-wireguard-config\n"
        doc += "data:\n"
        doc += "  ENVIRONMENT: \"production\"\n"
        doc += "  LOG_LEVEL: \"INFO\"\n"
        doc += "  DATABASE_HOST: \"mysql-service\"\n"
        doc += "  DATABASE_PORT: \"3306\"\n"
        doc += "  DATABASE_NAME: \"ipv6wgm\"\n"
        doc += "  REDIS_URL: \"redis://redis-service:${REDIS_PORT}/0\"\n"
        doc += "  USE_REDIS: \"true\"\n"
        doc += "```\n\n"
        
        # 写入文件
        output_path = self.output_dir / "config_examples.md"
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(doc)
        
        logger.info(f"配置示例文档已生成: {output_path}")

# 创建全局配置文档生成器实例
config_docs_generator = ConfigDocumentationGenerator()

# 导出便捷函数
def generate_all_config_docs():
    """生成所有配置文档"""
    config_docs_generator.generate_all_docs()

# 导出主要组件
__all__ = [
    "ConfigDocumentationGenerator", "config_docs_generator",
    "generate_all_config_docs"
]
