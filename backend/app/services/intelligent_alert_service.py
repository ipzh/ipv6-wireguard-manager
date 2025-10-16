"""
智能告警分析服务 - 基于机器学习的异常检测
"""
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import DBSCAN
import logging

from ..models.alert import Alert, AlertRule
from ..schemas.alert import AlertCreate
from ..core.config_enhanced import settings

logger = logging.getLogger(__name__)

class IntelligentAlertService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.anomaly_detector = IsolationForest(contamination=0.1, random_state=42)
        self.scaler = StandardScaler()
        self.historical_data = []
        self.patterns = {}
        self.is_trained = False

    async def collect_historical_data(self, days: int = 30) -> List[Dict[str, Any]]:
        """收集历史数据用于训练"""
        try:
            # 模拟收集历史系统指标数据
            # 实际实现中应该从监控数据库获取
            end_time = datetime.now()
            start_time = end_time - timedelta(days=days)
            
            # 生成模拟历史数据
            historical_data = []
            current_time = start_time
            
            while current_time < end_time:
                # 模拟正常的系统指标
                base_cpu = 30 + np.random.normal(0, 10)
                base_memory = 50 + np.random.normal(0, 15)
                base_disk = 40 + np.random.normal(0, 8)
                base_network = 1000 + np.random.normal(0, 200)
                
                # 添加一些周期性模式
                hour_factor = np.sin(current_time.hour * np.pi / 12) * 5
                day_factor = np.sin(current_time.weekday() * np.pi / 7) * 3
                
                data_point = {
                    'timestamp': current_time,
                    'cpu_percent': max(0, min(100, base_cpu + hour_factor + day_factor)),
                    'memory_percent': max(0, min(100, base_memory + hour_factor)),
                    'disk_percent': max(0, min(100, base_disk + day_factor)),
                    'network_bytes': max(0, base_network + np.random.normal(0, 100)),
                    'load_1min': max(0, 0.5 + np.random.normal(0, 0.3)),
                    'process_count': 100 + int(np.random.normal(0, 20))
                }
                
                historical_data.append(data_point)
                current_time += timedelta(minutes=5)  # 每5分钟一个数据点
            
            return historical_data
            
        except Exception as e:
            logger.error(f"收集历史数据失败: {e}")
            return []

    async def train_anomaly_detector(self, historical_data: List[Dict[str, Any]]):
        """训练异常检测模型"""
        try:
            if not historical_data:
                logger.warning("没有历史数据用于训练")
                return False
            
            # 准备训练数据
            df = pd.DataFrame(historical_data)
            features = ['cpu_percent', 'memory_percent', 'disk_percent', 
                       'network_bytes', 'load_1min', 'process_count']
            
            X = df[features].values
            
            # 标准化数据
            X_scaled = self.scaler.fit_transform(X)
            
            # 训练异常检测模型
            self.anomaly_detector.fit(X_scaled)
            
            # 分析数据模式
            await self.analyze_patterns(historical_data)
            
            self.is_trained = True
            logger.info("异常检测模型训练完成")
            return True
            
        except Exception as e:
            logger.error(f"训练异常检测模型失败: {e}")
            return False

    async def analyze_patterns(self, data: List[Dict[str, Any]]):
        """分析数据模式"""
        try:
            df = pd.DataFrame(data)
            
            # 时间模式分析
            df['hour'] = df['timestamp'].dt.hour
            df['day_of_week'] = df['timestamp'].dt.dayofweek
            
            # 按小时分析CPU使用模式
            hourly_cpu = df.groupby('hour')['cpu_percent'].agg(['mean', 'std']).reset_index()
            self.patterns['hourly_cpu'] = {
                'mean': hourly_cpu['mean'].tolist(),
                'std': hourly_cpu['std'].tolist()
            }
            
            # 按星期几分析内存使用模式
            daily_memory = df.groupby('day_of_week')['memory_percent'].agg(['mean', 'std']).reset_index()
            self.patterns['daily_memory'] = {
                'mean': daily_memory['mean'].tolist(),
                'std': daily_memory['std'].tolist()
            }
            
            # 异常值检测
            await self.detect_historical_anomalies(df)
            
            logger.info("数据模式分析完成")
            
        except Exception as e:
            logger.error(f"分析数据模式失败: {e}")

    async def detect_historical_anomalies(self, df: pd.DataFrame):
        """检测历史数据中的异常"""
        try:
            features = ['cpu_percent', 'memory_percent', 'disk_percent', 
                       'network_bytes', 'load_1min', 'process_count']
            
            X = df[features].values
            X_scaled = self.scaler.transform(X)
            
            # 检测异常
            anomalies = self.anomaly_detector.predict(X_scaled)
            anomaly_scores = self.anomaly_detector.decision_function(X_scaled)
            
            # 记录异常模式
            anomaly_indices = np.where(anomalies == -1)[0]
            if len(anomaly_indices) > 0:
                logger.info(f"检测到 {len(anomaly_indices)} 个历史异常点")
                
                # 分析异常特征
                anomaly_features = X[anomaly_indices]
                self.patterns['anomaly_features'] = {
                    'cpu_percent': np.mean(anomaly_features[:, 0]),
                    'memory_percent': np.mean(anomaly_features[:, 1]),
                    'disk_percent': np.mean(anomaly_features[:, 2]),
                    'network_bytes': np.mean(anomaly_features[:, 3]),
                    'load_1min': np.mean(anomaly_features[:, 4]),
                    'process_count': np.mean(anomaly_features[:, 5])
                }
            
        except Exception as e:
            logger.error(f"检测历史异常失败: {e}")

    async def detect_anomaly(self, current_metrics: Dict[str, Any]) -> Tuple[bool, float, Dict[str, Any]]:
        """检测当前指标是否异常"""
        try:
            if not self.is_trained:
                return False, 0.0, {}
            
            # 准备当前数据
            features = ['cpu_percent', 'memory_percent', 'disk_percent', 
                       'network_bytes', 'load_1min', 'process_count']
            
            current_data = np.array([
                current_metrics.get('cpu', {}).get('percent', 0),
                current_metrics.get('memory', {}).get('percent', 0),
                current_metrics.get('disk', {}).get('percent', 0),
                current_metrics.get('network', {}).get('bytes_sent', 0) + 
                current_metrics.get('network', {}).get('bytes_recv', 0),
                current_metrics.get('cpu', {}).get('load_1min', 0),
                current_metrics.get('processes', {}).get('count', 0)
            ]).reshape(1, -1)
            
            # 标准化
            current_scaled = self.scaler.transform(current_data)
            
            # 异常检测
            is_anomaly = self.anomaly_detector.predict(current_scaled)[0] == -1
            anomaly_score = self.anomaly_detector.decision_function(current_scaled)[0]
            
            # 分析异常类型
            anomaly_analysis = {}
            if is_anomaly:
                anomaly_analysis = await self.analyze_anomaly_type(current_metrics)
            
            return is_anomaly, anomaly_score, anomaly_analysis
            
        except Exception as e:
            logger.error(f"检测异常失败: {e}")
            return False, 0.0, {}

    async def analyze_anomaly_type(self, metrics: Dict[str, Any]) -> Dict[str, Any]:
        """分析异常类型"""
        try:
            analysis = {
                'type': 'unknown',
                'severity': 'medium',
                'description': '',
                'recommendations': []
            }
            
            cpu_percent = metrics.get('cpu', {}).get('percent', 0)
            memory_percent = metrics.get('memory', {}).get('percent', 0)
            disk_percent = metrics.get('disk', {}).get('percent', 0)
            load_1min = metrics.get('cpu', {}).get('load_1min', 0)
            
            # CPU异常分析
            if cpu_percent > 90:
                analysis['type'] = 'cpu_exhaustion'
                analysis['severity'] = 'high'
                analysis['description'] = f'CPU使用率异常高: {cpu_percent:.1f}%'
                analysis['recommendations'] = [
                    '检查CPU密集型进程',
                    '考虑增加CPU资源',
                    '优化应用程序性能'
                ]
            elif cpu_percent < 5:
                analysis['type'] = 'cpu_idle'
                analysis['severity'] = 'low'
                analysis['description'] = f'CPU使用率异常低: {cpu_percent:.1f}%'
                analysis['recommendations'] = [
                    '检查服务是否正常运行',
                    '验证监控数据准确性'
                ]
            
            # 内存异常分析
            elif memory_percent > 95:
                analysis['type'] = 'memory_exhaustion'
                analysis['severity'] = 'critical'
                analysis['description'] = f'内存使用率异常高: {memory_percent:.1f}%'
                analysis['recommendations'] = [
                    '立即检查内存泄漏',
                    '重启高内存消耗服务',
                    '增加内存资源'
                ]
            
            # 磁盘异常分析
            elif disk_percent > 95:
                analysis['type'] = 'disk_full'
                analysis['severity'] = 'critical'
                analysis['description'] = f'磁盘空间不足: {disk_percent:.1f}%'
                analysis['recommendations'] = [
                    '清理临时文件',
                    '删除旧日志文件',
                    '增加磁盘空间'
                ]
            
            # 负载异常分析
            elif load_1min > 10:
                analysis['type'] = 'high_load'
                analysis['severity'] = 'high'
                analysis['description'] = f'系统负载异常高: {load_1min:.2f}'
                analysis['recommendations'] = [
                    '检查系统负载',
                    '优化进程调度',
                    '考虑负载均衡'
                ]
            
            # 复合异常分析
            else:
                analysis['type'] = 'complex_anomaly'
                analysis['severity'] = 'medium'
                analysis['description'] = '检测到复合异常模式'
                analysis['recommendations'] = [
                    '综合分析系统状态',
                    '检查多个指标变化',
                    '联系系统管理员'
                ]
            
            return analysis
            
        except Exception as e:
            logger.error(f"分析异常类型失败: {e}")
            return {'type': 'unknown', 'severity': 'medium', 'description': '异常分析失败'}

    async def create_intelligent_alert(self, metrics: Dict[str, Any], 
                                     anomaly_score: float, 
                                     analysis: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """创建智能告警"""
        try:
            # 根据异常分析创建告警
            alert_data = {
                'title': f"智能检测: {analysis.get('description', '系统异常')}",
                'message': f"异常评分: {anomaly_score:.3f}\n类型: {analysis.get('type', 'unknown')}\n严重程度: {analysis.get('severity', 'medium')}",
                'severity': analysis.get('severity', 'medium'),
                'status': 'active',
                'triggered_at': datetime.now(),
                'last_triggered': datetime.now(),
                'trigger_count': 1,
                'metric_value': anomaly_score,
                'threshold_value': -0.1,  # 异常检测阈值
                'metadata': {
                    'anomaly_score': anomaly_score,
                    'anomaly_type': analysis.get('type'),
                    'recommendations': analysis.get('recommendations', []),
                    'detection_method': 'machine_learning'
                }
            }
            
            return alert_data
            
        except Exception as e:
            logger.error(f"创建智能告警失败: {e}")
            return None

    async def get_anomaly_statistics(self) -> Dict[str, Any]:
        """获取异常统计信息"""
        try:
            if not self.patterns:
                return {}
            
            stats = {
                'model_trained': self.is_trained,
                'patterns_analyzed': len(self.patterns),
                'hourly_cpu_pattern': self.patterns.get('hourly_cpu', {}),
                'daily_memory_pattern': self.patterns.get('daily_memory', {}),
                'anomaly_features': self.patterns.get('anomaly_features', {}),
                'last_training': datetime.now().isoformat()
            }
            
            return stats
            
        except Exception as e:
            logger.error(f"获取异常统计失败: {e}")
            return {}

    async def retrain_model(self, days: int = 30) -> bool:
        """重新训练模型"""
        try:
            logger.info("开始重新训练异常检测模型...")
            
            # 收集新的历史数据
            historical_data = await self.collect_historical_data(days)
            
            if not historical_data:
                logger.warning("没有足够的历史数据用于重新训练")
                return False
            
            # 重新训练模型
            success = await self.train_anomaly_detector(historical_data)
            
            if success:
                logger.info("模型重新训练完成")
            else:
                logger.error("模型重新训练失败")
            
            return success
            
        except Exception as e:
            logger.error(f"重新训练模型失败: {e}")
            return False
