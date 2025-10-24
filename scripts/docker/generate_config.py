#!/usr/bin/env python3
"""
Docker配置生成脚本
从模板生成不同环境的Docker Compose配置
"""

import os
import sys
import yaml
import argparse
from pathlib import Path
from typing import Dict, Any

class DockerConfigGenerator:
    """Docker配置生成器"""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.template_file = self.project_root / "docker-compose.template.yml"
    
    def load_template(self) -> Dict[str, Any]:
        """加载Docker配置模板"""
        if not self.template_file.exists():
            raise FileNotFoundError(f"模板文件不存在: {self.template_file}")
        
        with open(self.template_file, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    
    def load_env_config(self, env_file: str) -> Dict[str, str]:
        """加载环境配置文件"""
        env_path = self.project_root / env_file
        if not env_path.exists():
            print(f"⚠️  环境文件不存在: {env_file}")
            return {}
        
        env_vars = {}
        with open(env_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key.strip()] = value.strip()
        
        return env_vars
    
    def generate_config(self, environment: str, output_file: str = None) -> Dict[str, Any]:
        """生成Docker配置"""
        print(f"🔧 生成 {environment} 环境配置...")
        
        # 加载模板
        template = self.load_template()
        
        # 加载环境配置
        env_file = f"env.{environment}" if environment != "local" else "env.local"
        env_vars = self.load_env_config(env_file)
        
        # 根据环境调整配置
        if environment == "development":
            template = self._configure_development(template, env_vars)
        elif environment == "production":
            template = self._configure_production(template, env_vars)
        elif environment == "microservices":
            template = self._configure_microservices(template, env_vars)
        else:
            template = self._configure_default(template, env_vars)
        
        # 保存配置
        if output_file:
            output_path = self.project_root / output_file
            with open(output_path, 'w', encoding='utf-8') as f:
                yaml.dump(template, f, default_flow_style=False, allow_unicode=True)
            print(f"✅ 配置已保存到: {output_file}")
        
        return template
    
    def _configure_development(self, template: Dict[str, Any], env_vars: Dict[str, str]) -> Dict[str, Any]:
        """配置开发环境"""
        # 启用调试模式
        if 'backend' in template['services']:
            template['services']['backend']['environment']['DEBUG'] = 'true'
            template['services']['backend']['environment']['LOG_LEVEL'] = 'DEBUG'
        
        # 添加开发工具
        template['services']['dev-tools'] = {
            'image': 'node:18-alpine',
            'container_name': 'ipv6-wireguard-dev-tools',
            'volumes': ['./:/app'],
            'working_dir': '/app',
            'command': 'tail -f /dev/null',
            'networks': ['wireguard-network']
        }
        
        return template
    
    def _configure_production(self, template: Dict[str, Any], env_vars: Dict[str, str]) -> Dict[str, Any]:
        """配置生产环境"""
        # 禁用调试模式
        if 'backend' in template['services']:
            template['services']['backend']['environment']['DEBUG'] = 'false'
            template['services']['backend']['environment']['LOG_LEVEL'] = 'INFO'
        
        # 添加生产环境限制
        for service_name, service in template['services'].items():
            if 'deploy' not in service:
                service['deploy'] = {}
            
            if 'resources' not in service['deploy']:
                service['deploy']['resources'] = {
                    'limits': {'memory': '512M', 'cpus': '0.5'},
                    'reservations': {'memory': '256M', 'cpus': '0.25'}
                }
        
        # 添加Nginx反向代理
        template['services']['nginx-proxy'] = {
            'image': 'nginx:alpine',
            'container_name': 'ipv6-wireguard-nginx-proxy',
            'ports': ['80:80', '443:443'],
            'volumes': [
                './nginx/nginx.production.conf:/etc/nginx/nginx.conf:ro',
                './nginx/ssl:/etc/nginx/ssl:ro'
            ],
            'depends_on': ['frontend', 'backend'],
            'networks': ['wireguard-network'],
            'restart': 'unless-stopped'
        }
        
        return template
    
    def _configure_microservices(self, template: Dict[str, Any], env_vars: Dict[str, str]) -> Dict[str, Any]:
        """配置微服务环境"""
        # 创建多个后端实例
        backend_service = template['services']['backend']
        
        for i in range(1, 4):  # 创建3个后端实例
            service_name = f'backend-{i}'
            template['services'][service_name] = backend_service.copy()
            template['services'][service_name]['container_name'] = f'ipv6-wireguard-backend-{i}'
            template['services'][service_name]['ports'] = [f'{8000 + i}:8000']
        
        # 删除原始后端服务
        del template['services']['backend']
        
        # 添加负载均衡器
        template['services']['haproxy'] = {
            'image': 'haproxy:alpine',
            'container_name': 'ipv6-wireguard-haproxy',
            'ports': ['8080:80', '8443:443'],
            'volumes': ['./haproxy/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg'],
            'depends_on': ['backend-1', 'backend-2', 'backend-3'],
            'networks': ['wireguard-network'],
            'restart': 'unless-stopped'
        }
        
        # 添加监控服务
        template['services']['prometheus'] = {
            'image': 'prom/prometheus:latest',
            'container_name': 'ipv6-wireguard-prometheus',
            'ports': ['9090:9090'],
            'volumes': [
                './monitoring/prometheus.yml:/etc/prometheus/prometheus.yml',
                'prometheus_data:/prometheus'
            ],
            'networks': ['wireguard-network'],
            'restart': 'unless-stopped'
        }
        
        template['services']['grafana'] = {
            'image': 'grafana/grafana:latest',
            'container_name': 'ipv6-wireguard-grafana',
            'ports': ['3000:3000'],
            'environment': {
                'GF_SECURITY_ADMIN_PASSWORD': '${GRAFANA_ADMIN_PASSWORD:-admin}'
            },
            'volumes': ['grafana_data:/var/lib/grafana'],
            'depends_on': ['prometheus'],
            'networks': ['wireguard-network'],
            'restart': 'unless-stopped'
        }
        
        # 添加监控数据卷
        template['volumes']['prometheus_data'] = {'driver': 'local'}
        template['volumes']['grafana_data'] = {'driver': 'local'}
        
        return template
    
    def _configure_default(self, template: Dict[str, Any], env_vars: Dict[str, str]) -> Dict[str, Any]:
        """默认配置"""
        return template
    
    def validate_config(self, config: Dict[str, Any]) -> bool:
        """验证生成的配置"""
        required_services = ['mysql', 'redis', 'backend', 'frontend']
        
        for service in required_services:
            if service not in config.get('services', {}):
                print(f"❌ 缺少必需服务: {service}")
                return False
        
        # 检查环境变量
        for service_name, service in config['services'].items():
            if 'environment' in service:
                env_vars = service['environment']
                if isinstance(env_vars, dict):
                    for key, value in env_vars.items():
                        if 'CHANGE_ME' in str(value):
                            print(f"⚠️  服务 {service_name} 包含未配置的占位符: {key}={value}")
        
        print("✅ 配置验证通过")
        return True

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="Docker配置生成工具")
    parser.add_argument("environment", choices=["development", "production", "microservices", "local"],
                       help="目标环境")
    parser.add_argument("--output", help="输出文件名")
    parser.add_argument("--project-root", default=".", help="项目根目录")
    parser.add_argument("--validate-only", action="store_true", help="仅验证配置")
    
    args = parser.parse_args()
    
    try:
        generator = DockerConfigGenerator(args.project_root)
        
        if args.validate_only:
            config = generator.load_template()
            generator.validate_config(config)
        else:
            output_file = args.output or f"docker-compose.{args.environment}.yml"
            config = generator.generate_config(args.environment, output_file)
            generator.validate_config(config)
        
        print(f"🎉 {args.environment} 环境配置生成完成！")
        
    except Exception as e:
        print(f"❌ 配置生成失败: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
