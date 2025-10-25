# API响应压缩模块

import gzip
import zlib
import brotli
import json
from typing import Any, Dict, List, Optional, Union
from fastapi import Request, Response
from fastapi.responses import JSONResponse
import time
import logging
from enum import Enum

class CompressionType(Enum):
    """压缩类型"""
    GZIP = "gzip"
    DEFLATE = "deflate"
    BROTLI = "br"
    NONE = "identity"

class CompressionConfig:
    """压缩配置"""
    def __init__(
        self,
        min_size: int = 1024,  # 最小压缩大小
        max_size: int = 10 * 1024 * 1024,  # 最大压缩大小
        compression_level: int = 6,  # 压缩级别
        enabled_types: List[CompressionType] = None,
        exclude_content_types: List[str] = None
    ):
        self.min_size = min_size
        self.max_size = max_size
        self.compression_level = compression_level
        self.enabled_types = enabled_types or [CompressionType.GZIP, CompressionType.BROTLI]
        self.exclude_content_types = exclude_content_types or [
            "image/", "video/", "audio/", "application/zip", "application/gzip"
        ]

class ResponseCompressor:
    """响应压缩器"""
    
    def __init__(self, config: CompressionConfig):
        self.config = config
        self.logger = logging.getLogger(__name__)
        self.compression_stats = {
            "total_requests": 0,
            "compressed_requests": 0,
            "bytes_saved": 0,
            "compression_ratio": 0.0
        }
    
    def should_compress(self, content: bytes, content_type: str, 
                       accept_encoding: str) -> Tuple[bool, CompressionType]:
        """判断是否应该压缩"""
        # 检查内容大小
        if len(content) < self.config.min_size:
            return False, CompressionType.NONE
        
        if len(content) > self.config.max_size:
            return False, CompressionType.NONE
        
        # 检查内容类型
        for exclude_type in self.config.exclude_content_types:
            if content_type.startswith(exclude_type):
                return False, CompressionType.NONE
        
        # 检查客户端支持的压缩类型
        compression_type = self._get_best_compression_type(accept_encoding)
        if compression_type == CompressionType.NONE:
            return False, CompressionType.NONE
        
        return True, compression_type
    
    def _get_best_compression_type(self, accept_encoding: str) -> CompressionType:
        """获取最佳压缩类型"""
        accept_encoding = accept_encoding.lower()
        
        # 按优先级选择压缩类型
        if CompressionType.BROTLI in self.config.enabled_types and "br" in accept_encoding:
            return CompressionType.BROTLI
        elif CompressionType.GZIP in self.config.enabled_types and "gzip" in accept_encoding:
            return CompressionType.GZIP
        elif CompressionType.DEFLATE in self.config.enabled_types and "deflate" in accept_encoding:
            return CompressionType.DEFLATE
        
        return CompressionType.NONE
    
    def compress_content(self, content: bytes, compression_type: CompressionType) -> bytes:
        """压缩内容"""
        try:
            if compression_type == CompressionType.GZIP:
                return gzip.compress(content, compresslevel=self.config.compression_level)
            elif compression_type == CompressionType.DEFLATE:
                return zlib.compress(content, level=self.config.compression_level)
            elif compression_type == CompressionType.BROTLI:
                return brotli.compress(content, quality=self.config.compression_level)
            else:
                return content
        except Exception as e:
            self.logger.error(f"压缩失败: {e}")
            return content
    
    def compress_response(self, response: Response, content: bytes, 
                         content_type: str, accept_encoding: str) -> Response:
        """压缩响应"""
        should_compress, compression_type = self.should_compress(
            content, content_type, accept_encoding
        )
        
        if not should_compress:
            response.body = content
            return response
        
        # 压缩内容
        compressed_content = self.compress_content(content, compression_type)
        
        # 更新响应
        response.body = compressed_content
        response.headers["Content-Encoding"] = compression_type.value
        response.headers["Content-Length"] = str(len(compressed_content))
        
        # 更新统计
        self._update_stats(len(content), len(compressed_content))
        
        return response
    
    def _update_stats(self, original_size: int, compressed_size: int):
        """更新压缩统计"""
        self.compression_stats["total_requests"] += 1
        self.compression_stats["compressed_requests"] += 1
        self.compression_stats["bytes_saved"] += original_size - compressed_size
        
        if self.compression_stats["total_requests"] > 0:
            self.compression_stats["compression_ratio"] = (
                self.compression_stats["bytes_saved"] / 
                (self.compression_stats["total_requests"] * original_size)
            )
    
    def get_stats(self) -> Dict[str, Any]:
        """获取压缩统计"""
        return self.compression_stats.copy()

class JSONCompressor:
    """JSON压缩器"""
    
    def __init__(self, config: CompressionConfig):
        self.config = config
        self.compressor = ResponseCompressor(config)
    
    def compress_json_response(self, data: Any, accept_encoding: str) -> JSONResponse:
        """压缩JSON响应"""
        # 序列化JSON
        json_content = json.dumps(data, separators=(',', ':'), ensure_ascii=False)
        content_bytes = json_content.encode('utf-8')
        
        # 创建响应
        response = JSONResponse(content=data)
        
        # 压缩响应
        compressed_response = self.compressor.compress_response(
            response, content_bytes, "application/json", accept_encoding
        )
        
        return compressed_response

class StreamingCompressor:
    """流式压缩器"""
    
    def __init__(self, config: CompressionConfig):
        self.config = config
        self.compressor = ResponseCompressor(config)
    
    def compress_stream(self, data_stream, compression_type: CompressionType):
        """压缩数据流"""
        if compression_type == CompressionType.GZIP:
            compressor = gzip.GzipFile(mode='wb', compresslevel=self.config.compression_level)
        elif compression_type == CompressionType.DEFLATE:
            compressor = zlib.compressobj(level=self.config.compression_level)
        elif compression_type == CompressionType.BROTLI:
            compressor = brotli.Compressor(quality=self.config.compression_level)
        else:
            yield from data_stream
            return
        
        try:
            for chunk in data_stream:
                if compression_type == CompressionType.GZIP:
                    compressed_chunk = compressor.compress(chunk)
                elif compression_type == CompressionType.DEFLATE:
                    compressed_chunk = compressor.compress(chunk)
                elif compression_type == CompressionType.BROTLI:
                    compressed_chunk = compressor.compress(chunk)
                
                if compressed_chunk:
                    yield compressed_chunk
            
            # 完成压缩
            if compression_type == CompressionType.GZIP:
                final_chunk = compressor.close()
            elif compression_type == CompressionType.DEFLATE:
                final_chunk = compressor.flush()
            elif compression_type == CompressionType.BROTLI:
                final_chunk = compressor.finish()
            
            if final_chunk:
                yield final_chunk
                
        finally:
            if hasattr(compressor, 'close'):
                compressor.close()

class CompressionMiddleware:
    """压缩中间件"""
    
    def __init__(self, config: CompressionConfig):
        self.config = config
        self.compressor = ResponseCompressor(config)
        self.json_compressor = JSONCompressor(config)
    
    async def __call__(self, request: Request, call_next):
        """中间件处理"""
        start_time = time.time()
        
        # 处理请求
        response = await call_next(request)
        
        # 获取Accept-Encoding头
        accept_encoding = request.headers.get("Accept-Encoding", "")
        
        # 检查响应类型
        content_type = response.headers.get("Content-Type", "")
        
        # 获取响应内容
        if hasattr(response, 'body'):
            content = response.body
        else:
            content = b""
        
        # 压缩响应
        if content and len(content) > 0:
            compressed_response = self.compressor.compress_response(
                response, content, content_type, accept_encoding
            )
            
            # 更新处理时间
            process_time = time.time() - start_time
            compressed_response.headers["X-Process-Time"] = str(process_time)
            
            return compressed_response
        
        return response

class CompressionAnalyzer:
    """压缩分析器"""
    
    def __init__(self):
        self.analysis_data = {
            "content_types": {},
            "compression_ratios": {},
            "performance_metrics": {}
        }
    
    def analyze_compression(self, content_type: str, original_size: int, 
                          compressed_size: int, compression_type: str):
        """分析压缩效果"""
        if content_type not in self.analysis_data["content_types"]:
            self.analysis_data["content_types"][content_type] = {
                "count": 0,
                "total_original_size": 0,
                "total_compressed_size": 0,
                "avg_ratio": 0.0
            }
        
        data = self.analysis_data["content_types"][content_type]
        data["count"] += 1
        data["total_original_size"] += original_size
        data["total_compressed_size"] += compressed_size
        data["avg_ratio"] = (
            data["total_compressed_size"] / data["total_original_size"]
            if data["total_original_size"] > 0 else 0
        )
        
        # 记录压缩类型效果
        if compression_type not in self.analysis_data["compression_ratios"]:
            self.analysis_data["compression_ratios"][compression_type] = []
        
        ratio = compressed_size / original_size if original_size > 0 else 0
        self.analysis_data["compression_ratios"][compression_type].append(ratio)
    
    def get_analysis_report(self) -> Dict[str, Any]:
        """获取分析报告"""
        report = {
            "content_type_analysis": {},
            "compression_type_analysis": {},
            "recommendations": []
        }
        
        # 分析内容类型
        for content_type, data in self.analysis_data["content_types"].items():
            report["content_type_analysis"][content_type] = {
                "count": data["count"],
                "avg_compression_ratio": data["avg_ratio"],
                "total_bytes_saved": data["total_original_size"] - data["total_compressed_size"]
            }
        
        # 分析压缩类型
        for compression_type, ratios in self.analysis_data["compression_ratios"].items():
            if ratios:
                report["compression_type_analysis"][compression_type] = {
                    "avg_ratio": sum(ratios) / len(ratios),
                    "min_ratio": min(ratios),
                    "max_ratio": max(ratios),
                    "count": len(ratios)
                }
        
        # 生成建议
        report["recommendations"] = self._generate_recommendations()
        
        return report
    
    def _generate_recommendations(self) -> List[str]:
        """生成优化建议"""
        recommendations = []
        
        # 分析压缩效果
        for content_type, data in self.analysis_data["content_types"].items():
            if data["avg_ratio"] > 0.8:  # 压缩率低于20%
                recommendations.append(f"内容类型 {content_type} 压缩效果不佳，考虑调整压缩策略")
        
        # 分析压缩类型
        for compression_type, ratios in self.analysis_data["compression_ratios"].items():
            if ratios and sum(ratios) / len(ratios) > 0.9:  # 平均压缩率低于10%
                recommendations.append(f"压缩类型 {compression_type} 效果不佳，考虑使用其他压缩算法")
        
        return recommendations

# 默认压缩配置
DEFAULT_COMPRESSION_CONFIG = CompressionConfig(
    min_size=1024,
    max_size=10 * 1024 * 1024,
    compression_level=6,
    enabled_types=[CompressionType.GZIP, CompressionType.BROTLI],
    exclude_content_types=[
        "image/", "video/", "audio/", 
        "application/zip", "application/gzip",
        "application/pdf"
    ]
)

# 高性能压缩配置
HIGH_PERFORMANCE_CONFIG = CompressionConfig(
    min_size=512,
    max_size=5 * 1024 * 1024,
    compression_level=4,
    enabled_types=[CompressionType.GZIP],
    exclude_content_types=[
        "image/", "video/", "audio/"
    ]
)

# 最大压缩配置
MAX_COMPRESSION_CONFIG = CompressionConfig(
    min_size=256,
    max_size=20 * 1024 * 1024,
    compression_level=9,
    enabled_types=[CompressionType.BROTLI, CompressionType.GZIP],
    exclude_content_types=[
        "image/", "video/", "audio/"
    ]
)
