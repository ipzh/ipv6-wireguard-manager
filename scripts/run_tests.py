#!/usr/bin/env python3
"""
测试运行脚本
执行单元测试、集成测试和性能测试
"""

import os
import sys
import subprocess
import argparse
import time
from pathlib import Path

def run_command(command, description):
    """运行命令并显示结果"""
    print(f"\n{'='*60}")
    print(f"🚀 {description}")
    print(f"{'='*60}")
    print(f"执行命令: {command}")
    print()
    
    start_time = time.time()
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    end_time = time.time()
    
    print(f"执行时间: {end_time - start_time:.2f}秒")
    print(f"退出码: {result.returncode}")
    
    if result.stdout:
        print("\n📤 标准输出:")
        print(result.stdout)
    
    if result.stderr:
        print("\n❌ 错误输出:")
        print(result.stderr)
    
    return result.returncode == 0

def run_unit_tests():
    """运行单元测试"""
    command = "python -m pytest tests/test_unit.py -v --tb=short"
    return run_command(command, "运行单元测试")

def run_integration_tests():
    """运行集成测试"""
    command = "python -m pytest tests/test_integration.py -v --tb=short"
    return run_command(command, "运行集成测试")

def run_performance_tests():
    """运行性能测试"""
    command = "python -m pytest tests/test_performance.py -v --tb=short -s"
    return run_command(command, "运行性能测试")

def run_all_tests():
    """运行所有测试"""
    command = "python -m pytest tests/ -v --tb=short"
    return run_command(command, "运行所有测试")

def run_coverage_tests():
    """运行覆盖率测试"""
    command = "python -m pytest tests/ --cov=backend --cov-report=html --cov-report=term"
    return run_command(command, "运行覆盖率测试")

def run_lint_checks():
    """运行代码检查"""
    commands = [
        "python -m flake8 backend/ --max-line-length=100 --ignore=E203,W503",
        "python -m black --check backend/",
        "python -m isort --check-only backend/"
    ]
    
    all_passed = True
    for command in commands:
        if not run_command(command, f"代码检查: {command.split()[2]}"):
            all_passed = False
    
    return all_passed

def generate_test_report():
    """生成测试报告"""
    command = "python -m pytest tests/ --html=reports/test_report.html --self-contained-html"
    return run_command(command, "生成测试报告")

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="测试运行脚本")
    parser.add_argument("--unit", action="store_true", help="运行单元测试")
    parser.add_argument("--integration", action="store_true", help="运行集成测试")
    parser.add_argument("--performance", action="store_true", help="运行性能测试")
    parser.add_argument("--all", action="store_true", help="运行所有测试")
    parser.add_argument("--coverage", action="store_true", help="运行覆盖率测试")
    parser.add_argument("--lint", action="store_true", help="运行代码检查")
    parser.add_argument("--report", action="store_true", help="生成测试报告")
    
    args = parser.parse_args()
    
    # 创建报告目录
    os.makedirs("reports", exist_ok=True)
    
    print("🧪 IPv6 WireGuard Manager 测试套件")
    print("=" * 60)
    
    results = {}
    
    if args.unit or args.all:
        results["单元测试"] = run_unit_tests()
    
    if args.integration or args.all:
        results["集成测试"] = run_integration_tests()
    
    if args.performance or args.all:
        results["性能测试"] = run_performance_tests()
    
    if args.coverage or args.all:
        results["覆盖率测试"] = run_coverage_tests()
    
    if args.lint or args.all:
        results["代码检查"] = run_lint_checks()
    
    if args.report or args.all:
        results["测试报告"] = generate_test_report()
    
    # 如果没有指定任何参数，运行所有测试
    if not any([args.unit, args.integration, args.performance, args.all, args.coverage, args.lint, args.report]):
        results["所有测试"] = run_all_tests()
    
    # 显示结果摘要
    print(f"\n{'='*60}")
    print("📊 测试结果摘要")
    print(f"{'='*60}")
    
    passed = 0
    total = len(results)
    
    for test_name, success in results.items():
        status = "✅ 通过" if success else "❌ 失败"
        print(f"{test_name}: {status}")
        if success:
            passed += 1
    
    print(f"\n总计: {passed}/{total} 测试通过")
    
    if passed == total:
        print("🎉 所有测试通过！")
        return 0
    else:
        print("⚠️ 部分测试失败，请检查上述输出")
        return 1

if __name__ == "__main__":
    sys.exit(main())
