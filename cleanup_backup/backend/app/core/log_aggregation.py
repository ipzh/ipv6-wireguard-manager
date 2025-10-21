# 日志聚合和分析模块

import logging
import json
import asyncio
import time
from typing import Dict, List, Any, Optional, Union
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
from enum import Enum
import re
from collections import defaultdict, Counter
import threading
from queue import Queue, Empty
import elasticsearch
from elasticsearch import Elasticsearch
import redis
import hashlib

class LogLevel(Enum):
    """日志级别"""
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"

class LogSource(Enum):
    """日志来源"""
    APPLICATION = "application"
    SYSTEM = "system"
    DATABASE = "database"
    NETWORK = "network"
    SECURITY = "security"
    AUDIT = "audit"

@dataclass
class LogEntry:
    """日志条目"""
    timestamp: datetime
    level: LogLevel
    source: LogSource
    service: str
    message: str
    context: Dict[str, Any]
    trace_id: Optional[str] = None
    user_id: Optional[str] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None

class LogAggregator:
    """日志聚合器"""
    
    def __init__(self, elasticsearch_client: Elasticsearch = None, redis_client: redis.Redis = None):
        self.es_client = elasticsearch_client
        self.redis_client = redis_client
        self.log_queue = Queue(maxsize=10000)
        self.logger = logging.getLogger(__name__)
        
        # 日志处理线程
        self.processing_thread = None
        self.processing = False
        
        # 日志统计
        self.log_stats = {
            'total_logs': 0,
            'logs_by_level': Counter(),
            'logs_by_source': Counter(),
            'logs_by_service': Counter(),
            'error_rate': 0.0
        }
    
    def start_processing(self):
        """开始日志处理"""
        if self.processing:
            return
        
        self.processing = True
        self.processing_thread = threading.Thread(target=self._process_logs)
        self.processing_thread.daemon = True
        self.processing_thread.start()
        
        self.logger.info("日志聚合器已启动")
    
    def stop_processing(self):
        """停止日志处理"""
        self.processing = False
        if self.processing_thread:
            self.processing_thread.join()
        
        self.logger.info("日志聚合器已停止")
    
    def add_log(self, log_entry: LogEntry):
        """添加日志条目"""
        try:
            self.log_queue.put_nowait(log_entry)
        except:
            self.logger.warning("日志队列已满，丢弃日志条目")
    
    def _process_logs(self):
        """处理日志"""
        while self.processing:
            try:
                # 批量处理日志
                logs = []
                timeout = 1.0
                
                # 收集一批日志
                while len(logs) < 100:  # 批量大小
                    try:
                        log_entry = self.log_queue.get(timeout=timeout)
                        logs.append(log_entry)
                        timeout = 0.1  # 减少超时时间
                    except Empty:
                        break
                
                if logs:
                    self._process_log_batch(logs)
                
            except Exception as e:
                self.logger.error(f"日志处理错误: {e}")
                time.sleep(1)
    
    def _process_log_batch(self, logs: List[LogEntry]):
        """处理日志批次"""
        # 更新统计
        for log in logs:
            self.log_stats['total_logs'] += 1
            self.log_stats['logs_by_level'][log.level.value] += 1
            self.log_stats['logs_by_source'][log.source.value] += 1
            self.log_stats['logs_by_service'][log.service] += 1
        
        # 计算错误率
        error_count = sum(1 for log in logs if log.level in [LogLevel.ERROR, LogLevel.CRITICAL])
        self.log_stats['error_rate'] = error_count / len(logs) if logs else 0
        
        # 存储到Elasticsearch
        if self.es_client:
            self._store_logs_to_elasticsearch(logs)
        
        # 存储到Redis（用于实时分析）
        if self.redis_client:
            self._store_logs_to_redis(logs)
    
    def _store_logs_to_elasticsearch(self, logs: List[LogEntry]):
        """存储日志到Elasticsearch"""
        try:
            index_name = f"logs-{datetime.now().strftime('%Y.%m.%d')}"
            
            bulk_data = []
            for log in logs:
                doc = {
                    'timestamp': log.timestamp,
                    'level': log.level.value,
                    'source': log.source.value,
                    'service': log.service,
                    'message': log.message,
                    'context': log.context,
                    'trace_id': log.trace_id,
                    'user_id': log.user_id,
                    'ip_address': log.ip_address,
                    'user_agent': log.user_agent
                }
                
                bulk_data.append({
                    'index': {
                        '_index': index_name,
                        '_type': '_doc'
                    }
                })
                bulk_data.append(doc)
            
            if bulk_data:
                self.es_client.bulk(body=bulk_data)
                
        except Exception as e:
            self.logger.error(f"存储日志到Elasticsearch失败: {e}")
    
    def _store_logs_to_redis(self, logs: List[LogEntry]):
        """存储日志到Redis"""
        try:
            # 存储最近的日志（用于实时分析）
            for log in logs:
                log_key = f"recent_logs:{log.service}"
                log_data = {
                    'timestamp': log.timestamp.isoformat(),
                    'level': log.level.value,
                    'message': log.message,
                    'context': json.dumps(log.context)
                }
                
                # 使用Redis Stream
                self.redis_client.xadd(log_key, log_data, maxlen=1000)
            
            # 更新统计信息
            stats_key = f"log_stats:{datetime.now().strftime('%Y%m%d')}"
            self.redis_client.hset(stats_key, mapping={
                'total_logs': self.log_stats['total_logs'],
                'error_rate': self.log_stats['error_rate']
            })
            self.redis_client.expire(stats_key, 86400)  # 24小时过期
            
        except Exception as e:
            self.logger.error(f"存储日志到Redis失败: {e}")
    
    def get_log_stats(self) -> Dict[str, Any]:
        """获取日志统计"""
        return {
            'total_logs': self.log_stats['total_logs'],
            'logs_by_level': dict(self.log_stats['logs_by_level']),
            'logs_by_source': dict(self.log_stats['logs_by_source']),
            'logs_by_service': dict(self.log_stats['logs_by_service']),
            'error_rate': self.log_stats['error_rate']
        }

class LogAnalyzer:
    """日志分析器"""
    
    def __init__(self, elasticsearch_client: Elasticsearch, redis_client: redis.Redis):
        self.es_client = elasticsearch_client
        self.redis_client = redis_client
        self.logger = logging.getLogger(__name__)
        
        # 分析模式
        self.patterns = {
            'error_patterns': [
                r'ERROR.*Exception',
                r'CRITICAL.*Fatal',
                r'Failed to.*',
                r'Connection.*failed',
                r'Timeout.*error'
            ],
            'security_patterns': [
                r'Unauthorized.*access',
                r'Failed.*login',
                r'Suspicious.*activity',
                r'Rate.*limit.*exceeded',
                r'Blocked.*IP'
            ],
            'performance_patterns': [
                r'Slow.*query',
                r'High.*memory.*usage',
                r'CPU.*usage.*high',
                r'Response.*time.*slow'
            ]
        }
    
    def analyze_logs(self, query: Dict[str, Any], time_range: Dict[str, str]) -> Dict[str, Any]:
        """分析日志"""
        try:
            # 构建Elasticsearch查询
            es_query = self._build_elasticsearch_query(query, time_range)
            
            # 执行查询
            response = self.es_client.search(
                index="logs-*",
                body=es_query,
                size=1000
            )
            
            logs = [hit['_source'] for hit in response['hits']['hits']]
            
            # 分析结果
            analysis = {
                'total_logs': len(logs),
                'error_analysis': self._analyze_errors(logs),
                'security_analysis': self._analyze_security(logs),
                'performance_analysis': self._analyze_performance(logs),
                'trend_analysis': self._analyze_trends(logs),
                'top_errors': self._get_top_errors(logs),
                'service_health': self._analyze_service_health(logs)
            }
            
            return analysis
            
        except Exception as e:
            self.logger.error(f"日志分析失败: {e}")
            return {}
    
    def _build_elasticsearch_query(self, query: Dict[str, Any], time_range: Dict[str, str]) -> Dict[str, Any]:
        """构建Elasticsearch查询"""
        must_clauses = []
        
        # 时间范围
        if 'start_time' in time_range and 'end_time' in time_range:
            must_clauses.append({
                'range': {
                    'timestamp': {
                        'gte': time_range['start_time'],
                        'lte': time_range['end_time']
                    }
                }
            })
        
        # 日志级别
        if 'level' in query:
            must_clauses.append({
                'term': {'level': query['level']}
            })
        
        # 服务
        if 'service' in query:
            must_clauses.append({
                'term': {'service': query['service']}
            })
        
        # 消息搜索
        if 'message' in query:
            must_clauses.append({
                'match': {'message': query['message']}
            })
        
        return {
            'query': {
                'bool': {
                    'must': must_clauses
                }
            },
            'sort': [{'timestamp': {'order': 'desc'}}]
        }
    
    def _analyze_errors(self, logs: List[Dict[str, Any]]) -> Dict[str, Any]:
        """分析错误"""
        error_logs = [log for log in logs if log['level'] in ['ERROR', 'CRITICAL']]
        
        if not error_logs:
            return {'error_count': 0, 'error_rate': 0, 'error_types': {}}
        
        error_types = Counter()
        error_services = Counter()
        
        for log in error_logs:
            # 提取错误类型
            message = log['message']
            for pattern in self.patterns['error_patterns']:
                if re.search(pattern, message, re.IGNORECASE):
                    error_types[pattern] += 1
                    break
            
            error_services[log['service']] += 1
        
        return {
            'error_count': len(error_logs),
            'error_rate': len(error_logs) / len(logs) if logs else 0,
            'error_types': dict(error_types),
            'error_services': dict(error_services)
        }
    
    def _analyze_security(self, logs: List[Dict[str, Any]]) -> Dict[str, Any]:
        """分析安全日志"""
        security_logs = []
        
        for log in logs:
            message = log['message']
            for pattern in self.patterns['security_patterns']:
                if re.search(pattern, message, re.IGNORECASE):
                    security_logs.append(log)
                    break
        
        if not security_logs:
            return {'security_events': 0, 'threat_level': 'low'}
        
        # 分析威胁级别
        threat_level = 'low'
        if len(security_logs) > 10:
            threat_level = 'high'
        elif len(security_logs) > 5:
            threat_level = 'medium'
        
        return {
            'security_events': len(security_logs),
            'threat_level': threat_level,
            'recent_events': security_logs[:10]
        }
    
    def _analyze_performance(self, logs: List[Dict[str, Any]]) -> Dict[str, Any]:
        """分析性能日志"""
        performance_logs = []
        
        for log in logs:
            message = log['message']
            for pattern in self.patterns['performance_patterns']:
                if re.search(pattern, message, re.IGNORECASE):
                    performance_logs.append(log)
                    break
        
        return {
            'performance_issues': len(performance_logs),
            'recent_issues': performance_logs[:10]
        }
    
    def _analyze_trends(self, logs: List[Dict[str, Any]]) -> Dict[str, Any]:
        """分析趋势"""
        # 按小时分组
        hourly_counts = defaultdict(int)
        
        for log in logs:
            timestamp = datetime.fromisoformat(log['timestamp'].replace('Z', '+00:00'))
            hour_key = timestamp.strftime('%Y-%m-%d %H:00')
            hourly_counts[hour_key] += 1
        
        return {
            'hourly_trends': dict(hourly_counts)
        }
    
    def _get_top_errors(self, logs: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """获取最常见的错误"""
        error_messages = Counter()
        
        for log in logs:
            if log['level'] in ['ERROR', 'CRITICAL']:
                error_messages[log['message']] += 1
        
        return [
            {'message': msg, 'count': count}
            for msg, count in error_messages.most_common(10)
        ]
    
    def _analyze_service_health(self, logs: List[Dict[str, Any]]) -> Dict[str, Any]:
        """分析服务健康状态"""
        service_stats = defaultdict(lambda: {'total': 0, 'errors': 0})
        
        for log in logs:
            service = log['service']
            service_stats[service]['total'] += 1
            
            if log['level'] in ['ERROR', 'CRITICAL']:
                service_stats[service]['errors'] += 1
        
        service_health = {}
        for service, stats in service_stats.items():
            error_rate = stats['errors'] / stats['total'] if stats['total'] > 0 else 0
            
            if error_rate > 0.1:
                health = 'unhealthy'
            elif error_rate > 0.05:
                health = 'warning'
            else:
                health = 'healthy'
            
            service_health[service] = {
                'health': health,
                'error_rate': error_rate,
                'total_logs': stats['total']
            }
        
        return service_health

class LogSearchEngine:
    """日志搜索引擎"""
    
    def __init__(self, elasticsearch_client: Elasticsearch):
        self.es_client = elasticsearch_client
        self.logger = logging.getLogger(__name__)
    
    def search_logs(self, search_query: str, filters: Dict[str, Any] = None, 
                   time_range: Dict[str, str] = None, limit: int = 100) -> Dict[str, Any]:
        """搜索日志"""
        try:
            # 构建查询
            query_body = self._build_search_query(search_query, filters, time_range, limit)
            
            # 执行搜索
            response = self.es_client.search(
                index="logs-*",
                body=query_body
            )
            
            # 处理结果
            results = {
                'total': response['hits']['total']['value'],
                'logs': [hit['_source'] for hit in response['hits']['hits']],
                'aggregations': response.get('aggregations', {})
            }
            
            return results
            
        except Exception as e:
            self.logger.error(f"日志搜索失败: {e}")
            return {'total': 0, 'logs': [], 'aggregations': {}}
    
    def _build_search_query(self, search_query: str, filters: Dict[str, Any], 
                          time_range: Dict[str, str], limit: int) -> Dict[str, Any]:
        """构建搜索查询"""
        must_clauses = []
        
        # 主搜索查询
        if search_query:
            must_clauses.append({
                'multi_match': {
                    'query': search_query,
                    'fields': ['message^2', 'context', 'service'],
                    'type': 'best_fields'
                }
            })
        
        # 过滤器
        if filters:
            for field, value in filters.items():
                if isinstance(value, list):
                    must_clauses.append({
                        'terms': {field: value}
                    })
                else:
                    must_clauses.append({
                        'term': {field: value}
                    })
        
        # 时间范围
        if time_range:
            must_clauses.append({
                'range': {
                    'timestamp': {
                        'gte': time_range.get('start_time'),
                        'lte': time_range.get('end_time')
                    }
                }
            })
        
        query_body = {
            'query': {
                'bool': {
                    'must': must_clauses
                }
            },
            'sort': [{'timestamp': {'order': 'desc'}}],
            'size': limit
        }
        
        # 添加聚合
        query_body['aggs'] = {
            'log_levels': {
                'terms': {'field': 'level'}
            },
            'services': {
                'terms': {'field': 'service'}
            },
            'sources': {
                'terms': {'field': 'source'}
            }
        }
        
        return query_body
    
    def get_log_suggestions(self, partial_query: str) -> List[str]:
        """获取日志搜索建议"""
        try:
            # 使用Elasticsearch的suggest功能
            suggest_query = {
                'suggest': {
                    'log_suggest': {
                        'prefix': partial_query,
                        'completion': {
                            'field': 'message.suggest',
                            'size': 10
                        }
                    }
                }
            }
            
            response = self.es_client.search(
                index="logs-*",
                body=suggest_query
            )
            
            suggestions = []
            for suggestion in response['suggest']['log_suggest'][0]['options']:
                suggestions.append(suggestion['text'])
            
            return suggestions
            
        except Exception as e:
            self.logger.error(f"获取搜索建议失败: {e}")
            return []

class LogAlertManager:
    """日志告警管理器"""
    
    def __init__(self, redis_client: redis.Redis):
        self.redis_client = redis_client
        self.logger = logging.getLogger(__name__)
        self.alerts = {}
        self.alert_rules = []
    
    def add_alert_rule(self, rule: Dict[str, Any]):
        """添加告警规则"""
        self.alert_rules.append(rule)
    
    def check_alerts(self, logs: List[Dict[str, Any]]):
        """检查告警"""
        for rule in self.alert_rules:
            if self._evaluate_rule(rule, logs):
                self._trigger_alert(rule)
    
    def _evaluate_rule(self, rule: Dict[str, Any], logs: List[Dict[str, Any]]) -> bool:
        """评估告警规则"""
        # 过滤日志
        filtered_logs = self._filter_logs(logs, rule.get('filters', {}))
        
        # 检查条件
        condition = rule.get('condition', {})
        condition_type = condition.get('type')
        
        if condition_type == 'count':
            return len(filtered_logs) >= condition.get('threshold', 0)
        elif condition_type == 'rate':
            total_logs = len(logs)
            if total_logs == 0:
                return False
            return len(filtered_logs) / total_logs >= condition.get('threshold', 0)
        
        return False
    
    def _filter_logs(self, logs: List[Dict[str, Any]], filters: Dict[str, Any]) -> List[Dict[str, Any]]:
        """过滤日志"""
        filtered_logs = logs
        
        for field, value in filters.items():
            if isinstance(value, list):
                filtered_logs = [log for log in filtered_logs if log.get(field) in value]
            else:
                filtered_logs = [log for log in filtered_logs if log.get(field) == value]
        
        return filtered_logs
    
    def _trigger_alert(self, rule: Dict[str, Any]):
        """触发告警"""
        alert_id = hashlib.md5(json.dumps(rule, sort_keys=True).encode()).hexdigest()
        
        alert = {
            'id': alert_id,
            'rule': rule,
            'timestamp': datetime.now().isoformat(),
            'status': 'active'
        }
        
        self.alerts[alert_id] = alert
        
        # 发送告警通知
        self._send_alert_notification(alert)
        
        self.logger.warning(f"告警触发: {rule.get('name', 'Unknown')}")
    
    def _send_alert_notification(self, alert: Dict[str, Any]):
        """发送告警通知"""
        # 这里可以集成各种通知方式
        # 例如：邮件、Slack、钉钉等
        pass

# 日志配置
LOG_CONFIG = {
    "elasticsearch": {
        "enabled": True,
        "hosts": ["localhost:9200"],
        "index_prefix": "logs",
        "index_pattern": "logs-*"
    },
    "redis": {
        "enabled": True,
        "host": "localhost",
        "port": 6379,
        "db": 0
    },
    "aggregation": {
        "batch_size": 100,
        "flush_interval": 5,
        "queue_size": 10000
    },
    "analysis": {
        "enabled": True,
        "interval": 300,  # 5分钟
        "retention_days": 30
    },
    "alerts": {
        "enabled": True,
        "rules": [
            {
                "name": "High Error Rate",
                "condition": {
                    "type": "rate",
                    "threshold": 0.1
                },
                "filters": {
                    "level": ["ERROR", "CRITICAL"]
                }
            },
            {
                "name": "Security Events",
                "condition": {
                    "type": "count",
                    "threshold": 5
                },
                "filters": {
                    "source": "security"
                }
            }
        ]
    }
}
