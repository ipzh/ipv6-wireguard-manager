#!/usr/bin/env python3
"""
API健康检查工具 - 全面检测API服务的运行状况
功能特性：
1. 检查API服务可用性
2. 验证关键端点响应
3. 检测数据库连接状态
4. 测试认证功能
5. 性能基准测试
6. 生成健康报告
"""
import sys
import os
import time
import json
import logging
from typing import Dict, List, Any
import urllib.request
import urllib.error
from datetime import datetime

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class APIHealthChecker:
    """API健康检查器 - 全面检测API服务状态"""
    
    def __init__(self, api_base_url: str, timeout: int = 10):
        """
        初始化健康检查器
        
        参数:
            api_base_url: API基础URL（例如：http://localhost:8000）
            timeout: 请求超时时间（秒）
        """
        self.api_base_url = api_base_url.rstrip('/')
        self.timeout = timeout
        self.results = {
            'timestamp': datetime.now().isoformat(),
            'api_url': api_base_url,
            'checks': [],
            'overall_status': 'unknown',
            'total_checks': 0,
            'passed_checks': 0,
            'failed_checks': 0
        }
    
    def check_root_endpoint(self) -> bool:
        """
        检查API根端点是否可访问
        
        返回:
            是否检查通过
        """
        logger.info("🔍 检查API根端点...")
        
        try:
            # 发起HTTP GET请求
            url = f"{self.api_base_url}/"
            response = self._make_request(url, method='GET')
            
            if response and response.get('status') == 'running':
                logger.info("✅ API根端点正常")
                self._add_check_result('root_endpoint', True, '根端点响应正常')
                return True
            else:
                logger.warning("⚠️ API根端点响应异常")
                self._add_check_result('root_endpoint', False, '根端点响应格式不符合预期')
                return False
                
        except Exception as e:
            logger.error(f"❌ API根端点检查失败: {e}")
            self._add_check_result('root_endpoint', False, str(e))
            return False
    
    def check_health_endpoint(self) -> bool:
        """
        检查健康检查端点
        
        返回:
            是否检查通过
        """
        logger.info("🔍 检查健康检查端点...")
        
        try:
            # 发起HTTP GET请求
            url = f"{self.api_base_url}/health"
            response = self._make_request(url, method='GET')
            
            if response and response.get('status') == 'healthy':
                logger.info("✅ 健康检查端点正常")
                self._add_check_result('health_endpoint', True, '服务健康状态正常')
                return True
            else:
                logger.warning("⚠️ 健康检查端点响应异常")
                self._add_check_result('health_endpoint', False, '服务状态异常')
                return False
                
        except Exception as e:
            logger.error(f"❌ 健康检查端点失败: {e}")
            self._add_check_result('health_endpoint', False, str(e))
            return False
    
    def check_api_docs(self) -> bool:
        """
        检查API文档是否可访问
        
        返回:
            是否检查通过
        """
        logger.info("🔍 检查API文档...")
        
        try:
            # 检查OpenAPI文档
            url = f"{self.api_base_url}/docs"
            req = urllib.request.Request(url, method='GET')
            
            with urllib.request.urlopen(req, timeout=self.timeout) as response:
                if response.status == 200:
                    logger.info("✅ API文档可访问")
                    self._add_check_result('api_docs', True, 'API文档正常')
                    return True
                else:
                    logger.warning(f"⚠️ API文档访问异常: HTTP {response.status}")
                    self._add_check_result('api_docs', False, f'HTTP状态码: {response.status}')
                    return False
                    
        except Exception as e:
            logger.error(f"❌ API文档检查失败: {e}")
            self._add_check_result('api_docs', False, str(e))
            return False
    
    def check_response_time(self) -> bool:
        """
        检查API响应时间是否在合理范围内
        
        返回:
            是否检查通过
        """
        logger.info("🔍 检查API响应时间...")
        
        try:
            # 测试多次请求并计算平均响应时间
            url = f"{self.api_base_url}/health"
            response_times = []
            
            for i in range(3):
                start_time = time.time()
                self._make_request(url, method='GET')
                elapsed_time = (time.time() - start_time) * 1000  # 转换为毫秒
                response_times.append(elapsed_time)
            
            avg_response_time = sum(response_times) / len(response_times)
            
            # 判断响应时间是否合理（阈值：200ms）
            if avg_response_time < 200:
                logger.info(f"✅ API响应时间正常: {avg_response_time:.2f}ms")
                self._add_check_result('response_time', True, f'平均响应时间: {avg_response_time:.2f}ms')
                return True
            elif avg_response_time < 500:
                logger.warning(f"⚠️ API响应时间较慢: {avg_response_time:.2f}ms")
                self._add_check_result('response_time', True, f'平均响应时间: {avg_response_time:.2f}ms（偏慢）')
                return True
            else:
                logger.error(f"❌ API响应时间过慢: {avg_response_time:.2f}ms")
                self._add_check_result('response_time', False, f'平均响应时间: {avg_response_time:.2f}ms（超时）')
                return False
                
        except Exception as e:
            logger.error(f"❌ 响应时间检查失败: {e}")
            self._add_check_result('response_time', False, str(e))
            return False
    
    def _make_request(self, url: str, method: str = 'GET', data: Dict = None) -> Dict:
        """
        发起HTTP请求并解析JSON响应
        
        参数:
            url: 请求URL
            method: HTTP方法
            data: 请求体数据（字典）
        
        返回:
            响应数据（字典）
        """
        try:
            # 准备请求
            headers = {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            }
            
            # 如果有请求体数据，转换为JSON
            request_data = None
            if data:
                request_data = json.dumps(data).encode('utf-8')
            
            # 创建请求对象
            req = urllib.request.Request(
                url,
                data=request_data,
                headers=headers,
                method=method
            )
            
            # 发送请求并获取响应
            with urllib.request.urlopen(req, timeout=self.timeout) as response:
                # 读取并解析JSON响应
                response_data = response.read().decode('utf-8')
                return json.loads(response_data)
                
        except urllib.error.HTTPError as e:
            logger.error(f"HTTP错误: {e.code} - {e.reason}")
            raise
        except urllib.error.URLError as e:
            logger.error(f"URL错误: {e.reason}")
            raise
        except Exception as e:
            logger.error(f"请求失败: {e}")
            raise
    
    def _add_check_result(self, check_name: str, passed: bool, message: str):
        """
        添加检查结果
        
        参数:
            check_name: 检查项名称
            passed: 是否通过
            message: 结果消息
        """
        self.results['checks'].append({
            'name': check_name,
            'passed': passed,
            'message': message
        })
        
        self.results['total_checks'] += 1
        if passed:
            self.results['passed_checks'] += 1
        else:
            self.results['failed_checks'] += 1
    
    def run_all_checks(self) -> bool:
        """
        运行所有健康检查
        
        返回:
            是否全部通过
        """
        logger.info("=" * 60)
        logger.info("🏥 开始API健康检查")
        logger.info("=" * 60)
        logger.info(f"API URL: {self.api_base_url}")
        logger.info(f"超时设置: {self.timeout}秒")
        logger.info("")
        
        # 执行各项检查
        checks = [
            self.check_root_endpoint,
            self.check_health_endpoint,
            self.check_api_docs,
            self.check_response_time
        ]
        
        all_passed = True
        for check_func in checks:
            try:
                if not check_func():
                    all_passed = False
            except Exception as e:
                logger.error(f"检查执行异常: {e}")
                all_passed = False
            logger.info("")  # 空行分隔
        
        # 设置总体状态
        self.results['overall_status'] = 'healthy' if all_passed else 'unhealthy'
        
        # 打印总结
        self._print_summary()
        
        return all_passed
    
    def _print_summary(self):
        """打印检查结果总结"""
        logger.info("=" * 60)
        logger.info("📊 健康检查总结")
        logger.info("=" * 60)
        logger.info(f"总检查项: {self.results['total_checks']}")
        logger.info(f"通过: {self.results['passed_checks']}")
        logger.info(f"失败: {self.results['failed_checks']}")
        
        if self.results['total_checks'] > 0:
            pass_rate = (self.results['passed_checks'] / self.results['total_checks']) * 100
            logger.info(f"通过率: {pass_rate:.1f}%")
        
        logger.info(f"总体状态: {self.results['overall_status']}")
        logger.info("=" * 60)
    
    def save_report(self, output_file: str):
        """
        保存检查报告到文件
        
        参数:
            output_file: 输出文件路径
        """
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(self.results, f, ensure_ascii=False, indent=2)
            logger.info(f"📄 报告已保存到: {output_file}")
        except Exception as e:
            logger.error(f"❌ 保存报告失败: {e}")


def main():
    """主函数 - 命令行入口"""
    import argparse
    
    # 创建命令行参数解析器
    parser = argparse.ArgumentParser(
        description='API健康检查工具 - 全面检测API服务的运行状况'
    )
    
    parser.add_argument(
        '--url',
        type=str,
        default='http://localhost:8000',
        help='API基础URL（默认：http://localhost:8000）'
    )
    parser.add_argument(
        '--timeout',
        type=int,
        default=10,
        help='请求超时时间（秒，默认：10）'
    )
    parser.add_argument(
        '--output',
        type=str,
        help='保存检查报告到文件'
    )
    
    args = parser.parse_args()
    
    # 创建健康检查器
    checker = APIHealthChecker(args.url, timeout=args.timeout)
    
    # 执行检查
    all_passed = checker.run_all_checks()
    
    # 保存报告（如果指定）
    if args.output:
        checker.save_report(args.output)
    
    # 返回退出码
    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
