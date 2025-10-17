<?php
/**
 * 主测试运行脚本 - 运行所有测试并生成报告
 */

echo "=== IPv6 WireGuard Manager 全面测试套件 ===\n\n";

// 检查测试环境
if (!file_exists('setup_test_env.php')) {
    echo "❌ 测试环境设置脚本不存在\n";
    exit(1);
}

// 运行测试环境设置
echo "1. 设置测试环境...\n";
$output = [];
$returnCode = 0;
exec('php setup_test_env.php 2>&1', $output, $returnCode);

if ($returnCode !== 0) {
    echo "❌ 测试环境设置失败\n";
    echo implode("\n", $output) . "\n";
    exit(1);
}
echo "✅ 测试环境设置完成\n\n";

// 运行基础测试
echo "2. 运行基础功能测试...\n";
$output = [];
$returnCode = 0;
exec('php run_tests.php 2>&1', $output, $returnCode);

if ($returnCode !== 0) {
    echo "⚠️  基础测试有失败项\n";
} else {
    echo "✅ 基础测试全部通过\n";
}
echo "\n";

// 运行Web界面测试
echo "3. 运行Web界面测试...\n";
$output = [];
$returnCode = 0;
exec('php test_web_interface.php 2>&1', $output, $returnCode);

if ($returnCode !== 0) {
    echo "⚠️  Web界面测试有失败项\n";
} else {
    echo "✅ Web界面测试全部通过\n";
}
echo "\n";

// 运行集成测试
echo "4. 运行集成测试...\n";
$output = [];
$returnCode = 0;
exec('php integration_test.php 2>&1', $output, $returnCode);

if ($returnCode !== 0) {
    echo "⚠️  集成测试有失败项\n";
} else {
    echo "✅ 集成测试全部通过\n";
}
echo "\n";

// 生成综合测试报告
echo "5. 生成综合测试报告...\n";
$output = [];
$returnCode = 0;
exec('php generate_test_report.php 2>&1', $output, $returnCode);

if ($returnCode !== 0) {
    echo "❌ 测试报告生成失败\n";
    echo implode("\n", $output) . "\n";
    exit(1);
}
echo "✅ 综合测试报告生成完成\n\n";

// 显示测试结果摘要
echo "=== 测试结果摘要 ===\n";

// 读取测试报告
$reportFile = 'test_results/comprehensive_test_report.json';
if (file_exists($reportFile)) {
    $report = json_decode(file_get_contents($reportFile), true);
    if ($report && isset($report['summary'])) {
        $summary = $report['summary'];
        echo "总测试数: {$summary['total_tests']}\n";
        echo "通过: {$summary['total_passed']}\n";
        echo "失败: {$summary['total_failed']}\n";
        echo "成功率: {$summary['overall_success_rate']}%\n\n";
        
        if ($summary['total_failed'] === 0) {
            echo "🎉 所有测试通过！系统准备就绪。\n\n";
        } else {
            echo "⚠️  有 {$summary['total_failed']} 个测试失败，请查看详细报告。\n\n";
        }
    }
}

// 显示报告文件位置
echo "=== 测试报告文件 ===\n";
echo "HTML报告: test_results/comprehensive_test_report.html\n";
echo "Markdown报告: test_results/comprehensive_test_report.md\n";
echo "JSON报告: test_results/comprehensive_test_report.json\n\n";

// 显示下一步操作
echo "=== 下一步操作 ===\n";
echo "1. 查看测试报告: 打开 test_results/comprehensive_test_report.html\n";
echo "2. 启动测试服务器: php start_test_server.php\n";
echo "3. 访问测试界面: http://localhost:8080\n";
echo "4. 查看错误日志: http://localhost:8080/error/logs\n\n";

// 检查是否有失败的测试
if (isset($summary) && $summary['total_failed'] > 0) {
    echo "⚠️  建议在启动服务器前修复失败的测试项。\n";
    exit(1);
} else {
    echo "✅ 系统测试完成，可以启动服务器进行实际测试。\n";
    exit(0);
}
?>
