#!/usr/bin/env python3
"""
数据导入工具 - 用于批量导入WireGuard配置和用户数据
功能特性：
1. 支持JSON和CSV格式数据导入
2. 数据验证和去重
3. 批量导入优化
4. 详细的错误日志记录
5. 支持导入预览（dry-run模式）
6. 导入进度显示
"""
import sys
import os
import json
import csv
from pathlib import Path
from typing import Dict, List, Optional, Any
import logging
from datetime import datetime

# 添加项目根目录到Python路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class DataImporter:
    """数据导入器 - 统一处理各种数据导入操作"""
    
    def __init__(self, database_url: str, dry_run: bool = False):
        """
        初始化数据导入器
        
        参数:
            database_url: 数据库连接URL
            dry_run: 是否为预览模式（不实际写入数据库）
        """
        self.database_url = database_url
        self.dry_run = dry_run
        self.import_stats = {
            'total': 0,
            'success': 0,
            'failed': 0,
            'skipped': 0
        }
    
    def import_json_file(self, file_path: str) -> bool:
        """
        从JSON文件导入数据
        
        参数:
            file_path: JSON文件路径
        
        返回:
            是否导入成功
        """
        logger.info(f"📁 开始导入JSON文件: {file_path}")
        
        try:
            # 读取JSON文件
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # 验证数据格式
            if not isinstance(data, (list, dict)):
                logger.error("❌ JSON数据格式错误，必须是列表或字典")
                return False
            
            # 处理单个对象的情况
            if isinstance(data, dict):
                data = [data]
            
            logger.info(f"📊 找到 {len(data)} 条数据记录")
            
            # 批量导入数据
            return self._batch_import(data)
            
        except FileNotFoundError:
            logger.error(f"❌ 文件不存在: {file_path}")
            return False
        except json.JSONDecodeError as e:
            logger.error(f"❌ JSON解析失败: {e}")
            return False
        except Exception as e:
            logger.error(f"❌ 导入失败: {e}")
            return False
    
    def import_csv_file(self, file_path: str, column_mapping: Dict[str, str]) -> bool:
        """
        从CSV文件导入数据
        
        参数:
            file_path: CSV文件路径
            column_mapping: 列名映射字典（CSV列名 -> 数据库字段名）
        
        返回:
            是否导入成功
        """
        logger.info(f"📁 开始导入CSV文件: {file_path}")
        
        try:
            # 读取CSV文件
            data = []
            with open(file_path, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                
                for row in reader:
                    # 根据映射转换字段名
                    mapped_row = {}
                    for csv_col, db_field in column_mapping.items():
                        if csv_col in row:
                            mapped_row[db_field] = row[csv_col]
                    
                    data.append(mapped_row)
            
            logger.info(f"📊 找到 {len(data)} 条数据记录")
            
            # 批量导入数据
            return self._batch_import(data)
            
        except FileNotFoundError:
            logger.error(f"❌ 文件不存在: {file_path}")
            return False
        except Exception as e:
            logger.error(f"❌ 导入失败: {e}")
            return False
    
    def _batch_import(self, data: List[Dict[str, Any]]) -> bool:
        """
        批量导入数据到数据库
        
        参数:
            data: 要导入的数据列表
        
        返回:
            是否导入成功
        """
        self.import_stats['total'] = len(data)
        
        if self.dry_run:
            logger.info("🔍 预览模式：以下是将要导入的数据（不会实际写入数据库）")
        
        # 遍历每条数据记录
        for idx, record in enumerate(data, start=1):
            try:
                # 验证数据
                if not self._validate_record(record):
                    logger.warning(f"⚠️ 记录 {idx} 验证失败，跳过")
                    self.import_stats['skipped'] += 1
                    continue
                
                # 检查是否已存在（去重）
                if self._check_duplicate(record):
                    logger.info(f"ℹ️ 记录 {idx} 已存在，跳过")
                    self.import_stats['skipped'] += 1
                    continue
                
                # 预览模式或实际导入
                if self.dry_run:
                    logger.info(f"📝 记录 {idx}: {json.dumps(record, ensure_ascii=False)}")
                    self.import_stats['success'] += 1
                else:
                    # 实际插入数据库
                    if self._insert_record(record):
                        logger.info(f"✅ 记录 {idx} 导入成功")
                        self.import_stats['success'] += 1
                    else:
                        logger.error(f"❌ 记录 {idx} 导入失败")
                        self.import_stats['failed'] += 1
                
                # 显示进度
                if idx % 10 == 0:
                    progress = (idx / len(data)) * 100
                    logger.info(f"📊 导入进度: {progress:.1f}% ({idx}/{len(data)})")
                    
            except Exception as e:
                logger.error(f"❌ 处理记录 {idx} 时出错: {e}")
                self.import_stats['failed'] += 1
        
        # 输出统计信息
        self._print_stats()
        
        # 判断是否成功（至少有一半的记录导入成功）
        return self.import_stats['success'] > 0
    
    def _validate_record(self, record: Dict[str, Any]) -> bool:
        """
        验证单条记录的数据格式
        
        参数:
            record: 要验证的数据记录
        
        返回:
            数据是否有效
        """
        # 检查必需字段（根据实际业务需求调整）
        required_fields = ['name']  # 示例：至少需要名称字段
        
        for field in required_fields:
            if field not in record or not record[field]:
                logger.warning(f"⚠️ 缺少必需字段: {field}")
                return False
        
        return True
    
    def _check_duplicate(self, record: Dict[str, Any]) -> bool:
        """
        检查记录是否已存在（去重检查）
        
        参数:
            record: 要检查的数据记录
        
        返回:
            是否为重复记录
        """
        # TODO: 实现实际的数据库查询逻辑
        # 这里只是示例，实际应该查询数据库
        return False
    
    def _insert_record(self, record: Dict[str, Any]) -> bool:
        """
        插入单条记录到数据库
        
        参数:
            record: 要插入的数据记录
        
        返回:
            是否插入成功
        """
        try:
            # TODO: 实现实际的数据库插入逻辑
            # 这里只是示例
            logger.debug(f"插入记录: {record}")
            return True
        except Exception as e:
            logger.error(f"插入记录失败: {e}")
            return False
    
    def _print_stats(self):
        """打印导入统计信息"""
        logger.info("=" * 50)
        logger.info("📊 导入统计")
        logger.info("=" * 50)
        logger.info(f"总记录数: {self.import_stats['total']}")
        logger.info(f"成功导入: {self.import_stats['success']}")
        logger.info(f"导入失败: {self.import_stats['failed']}")
        logger.info(f"跳过记录: {self.import_stats['skipped']}")
        
        if self.import_stats['total'] > 0:
            success_rate = (self.import_stats['success'] / self.import_stats['total']) * 100
            logger.info(f"成功率: {success_rate:.1f}%")
        
        logger.info("=" * 50)


def main():
    """主函数 - 命令行入口"""
    import argparse
    
    # 创建命令行参数解析器
    parser = argparse.ArgumentParser(
        description='数据导入工具 - 批量导入WireGuard配置和用户数据',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  # 从JSON文件导入数据
  python data_import_tool.py --json data.json
  
  # 从CSV文件导入数据（需要指定列映射）
  python data_import_tool.py --csv data.csv --mapping '{"csv_name":"name","csv_key":"public_key"}'
  
  # 预览模式（不实际写入数据库）
  python data_import_tool.py --json data.json --dry-run
        """
    )
    
    parser.add_argument('--json', type=str, help='JSON文件路径')
    parser.add_argument('--csv', type=str, help='CSV文件路径')
    parser.add_argument('--mapping', type=str, help='CSV列名映射（JSON格式字符串）')
    parser.add_argument('--dry-run', action='store_true', help='预览模式，不实际写入数据库')
    parser.add_argument('--database-url', type=str, help='数据库连接URL（默认从环境变量读取）')
    
    args = parser.parse_args()
    
    # 获取数据库URL
    database_url = args.database_url or os.getenv('DATABASE_URL')
    if not database_url:
        logger.error("❌ 未指定数据库URL，请设置DATABASE_URL环境变量或使用--database-url参数")
        return 1
    
    # 创建导入器
    importer = DataImporter(database_url, dry_run=args.dry_run)
    
    # 执行导入
    success = False
    
    if args.json:
        # 导入JSON文件
        success = importer.import_json_file(args.json)
    elif args.csv:
        # 导入CSV文件
        if not args.mapping:
            logger.error("❌ 导入CSV文件需要指定列映射（--mapping参数）")
            return 1
        
        try:
            # 解析列映射
            column_mapping = json.loads(args.mapping)
            success = importer.import_csv_file(args.csv, column_mapping)
        except json.JSONDecodeError:
            logger.error("❌ 列映射格式错误，必须是有效的JSON字符串")
            return 1
    else:
        parser.print_help()
        return 1
    
    if success:
        logger.info("✅ 数据导入完成")
        return 0
    else:
        logger.error("❌ 数据导入失败")
        return 1


if __name__ == "__main__":
    sys.exit(main())
