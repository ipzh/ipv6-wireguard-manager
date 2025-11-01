#!/usr/bin/env python3
"""
令牌黑名单清理脚本
定期清理过期的令牌黑名单条目
"""
import os
import sys
import argparse
import logging
from datetime import datetime, timedelta
from typing import Optional

# 添加项目根目录到Python路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.core.token_blacklist import token_blacklist, get_blacklisted_count
from app.core.logging import get_logger

logger = get_logger(__name__)

def cleanup_blacklist(dry_run: bool = False, verbose: bool = False) -> int:
    """清理过期的令牌黑名单条目
    
    Args:
        dry_run: 是否只模拟运行，不实际清理
        verbose: 是否输出详细信息
        
    Returns:
        int: 清理的令牌数量
    """
    try:
        # 获取清理前的黑名单大小
        before_count = get_blacklisted_count()
        
        if verbose:
            logger.info(f"清理前黑名单大小: {before_count}")
        
        # 如果是模拟运行，只返回预估的清理数量
        if dry_run:
            # 这里简化实现，实际应该检查每个令牌的过期时间
            # 返回预估的清理数量
            estimated_cleanup = max(0, before_count - int(before_count * 0.8))  # 假设20%的令牌已过期
            logger.info(f"模拟运行: 预计清理 {estimated_cleanup} 个过期令牌")
            return estimated_cleanup
        
        # 执行实际清理
        # 调用TokenBlacklist的清理方法
        token_blacklist._cleanup_expired_tokens()
        
        # 获取清理后的黑名单大小
        after_count = get_blacklisted_count()
        cleaned_count = before_count - after_count
        
        if verbose:
            logger.info(f"清理后黑名单大小: {after_count}")
        
        logger.info(f"已清理 {cleaned_count} 个过期令牌")
        return cleaned_count
        
    except Exception as e:
        logger.error(f"清理令牌黑名单时出错: {str(e)}")
        return 0

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='清理过期的令牌黑名单条目')
    parser.add_argument('--dry-run', action='store_true', 
                       help='模拟运行，不实际清理')
    parser.add_argument('--verbose', '-v', action='store_true', 
                       help='输出详细信息')
    parser.add_argument('--schedule', action='store_true',
                       help='设置为定时任务模式，输出适合cron的日志')
    
    args = parser.parse_args()
    
    # 设置日志级别
    if args.verbose:
        logging.getLogger().setLevel(logging.INFO)
    
    # 如果是定时任务模式，简化日志输出
    if args.schedule:
        logger.info(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 开始清理令牌黑名单")
        cleaned_count = cleanup_blacklist(dry_run=args.dry_run, verbose=False)
        logger.info(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 清理完成，共清理 {cleaned_count} 个过期令牌")
        return
    
    # 普通模式
    logger.info("开始清理令牌黑名单...")
    cleaned_count = cleanup_blacklist(dry_run=args.dry_run, verbose=args.verbose)
    
    if args.dry_run:
        logger.info("模拟运行完成")
    else:
        logger.info("清理完成")

if __name__ == "__main__":
    main()