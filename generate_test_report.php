<?php
/**
 * 测试报告生成器
 */

echo "=== 生成综合测试报告 ===\n\n";

// 检查测试结果文件
$testResultFiles = [
    'test_results/test_report.json',
    'test_results/web_test_report.json',
    'test_results/integration_test_report.json'
];

$allReports = [];
$totalTests = 0;
$totalPassed = 0;
$totalFailed = 0;

foreach ($testResultFiles as $file) {
    if (file_exists($file)) {
        $report = json_decode(file_get_contents($file), true);
        if ($report) {
            $allReports[] = $report;
            $totalTests += $report['total_tests'];
            $totalPassed += $report['passed_tests'];
            $totalFailed += $report['failed_tests'];
        }
    }
}

if (empty($allReports)) {
    echo "❌ 没有找到测试结果文件\n";
    exit(1);
}

// 生成HTML报告
$htmlReport = generateHtmlReport($allReports, $totalTests, $totalPassed, $totalFailed);

if (file_put_contents('test_results/comprehensive_test_report.html', $htmlReport)) {
    echo "✅ 综合测试报告已生成: test_results/comprehensive_test_report.html\n";
} else {
    echo "❌ 综合测试报告生成失败\n";
}

// 生成Markdown报告
$markdownReport = generateMarkdownReport($allReports, $totalTests, $totalPassed, $totalFailed);

if (file_put_contents('test_results/comprehensive_test_report.md', $markdownReport)) {
    echo "✅ Markdown测试报告已生成: test_results/comprehensive_test_report.md\n";
} else {
    echo "❌ Markdown测试报告生成失败\n";
}

// 生成JSON报告
$jsonReport = [
    'summary' => [
        'timestamp' => date('Y-m-d H:i:s'),
        'total_tests' => $totalTests,
        'total_passed' => $totalPassed,
        'total_failed' => $totalFailed,
        'overall_success_rate' => round(($totalPassed / $totalTests) * 100, 2)
    ],
    'detailed_reports' => $allReports
];

if (file_put_contents('test_results/comprehensive_test_report.json', json_encode($jsonReport, JSON_PRETTY_PRINT))) {
    echo "✅ JSON测试报告已生成: test_results/comprehensive_test_report.json\n";
} else {
    echo "❌ JSON测试报告生成失败\n";
}

echo "\n=== 测试报告生成完成 ===\n";
echo "总测试数: {$totalTests}\n";
echo "通过: {$totalPassed}\n";
echo "失败: {$totalFailed}\n";
echo "总体成功率: " . round(($totalPassed / $totalTests) * 100, 2) . "%\n\n";

/**
 * 生成HTML报告
 */
function generateHtmlReport($reports, $totalTests, $totalPassed, $totalFailed) {
    $successRate = round(($totalPassed / $totalTests) * 100, 2);
    $statusClass = $totalFailed === 0 ? 'success' : 'warning';
    $statusIcon = $totalFailed === 0 ? '✅' : '⚠️';
    
    $html = '<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager 测试报告</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .summary { background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
        .summary.success { background: #d4edda; border: 1px solid #c3e6cb; }
        .summary.warning { background: #fff3cd; border: 1px solid #ffeaa7; }
        .stats { display: flex; justify-content: space-around; margin: 20px 0; }
        .stat { text-align: center; }
        .stat-number { font-size: 2em; font-weight: bold; }
        .stat-label { color: #666; }
        .report-section { margin-bottom: 30px; }
        .report-header { background: #007bff; color: white; padding: 10px 15px; border-radius: 5px 5px 0 0; }
        .report-content { border: 1px solid #ddd; border-top: none; padding: 15px; }
        .test-item { margin: 10px 0; padding: 10px; background: #f8f9fa; border-radius: 5px; }
        .test-item.passed { background: #d4edda; }
        .test-item.failed { background: #f8d7da; }
        .error-list { background: #f8d7da; padding: 15px; border-radius: 5px; margin-top: 10px; }
        .error-item { margin: 5px 0; padding: 5px; background: white; border-radius: 3px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f8f9fa; }
        .timestamp { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>IPv6 WireGuard Manager 测试报告</h1>
            <p class="timestamp">生成时间: ' . date('Y-m-d H:i:s') . '</p>
        </div>
        
        <div class="summary ' . $statusClass . '">
            <h2>' . $statusIcon . ' 测试总结</h2>
            <div class="stats">
                <div class="stat">
                    <div class="stat-number">' . $totalTests . '</div>
                    <div class="stat-label">总测试数</div>
                </div>
                <div class="stat">
                    <div class="stat-number" style="color: #28a745;">' . $totalPassed . '</div>
                    <div class="stat-label">通过</div>
                </div>
                <div class="stat">
                    <div class="stat-number" style="color: #dc3545;">' . $totalFailed . '</div>
                    <div class="stat-label">失败</div>
                </div>
                <div class="stat">
                    <div class="stat-number">' . $successRate . '%</div>
                    <div class="stat-label">成功率</div>
                </div>
            </div>
        </div>';

    foreach ($reports as $report) {
        $testType = $report['test_type'] ?? 'basic';
        $testTypeName = getTestTypeName($testType);
        
        $html .= '
        <div class="report-section">
            <div class="report-header">
                <h3>' . $testTypeName . ' 测试结果</h3>
            </div>
            <div class="report-content">
                <p><strong>测试时间:</strong> ' . $report['timestamp'] . '</p>
                <p><strong>测试数量:</strong> ' . $report['total_tests'] . '</p>
                <p><strong>通过数量:</strong> ' . $report['passed_tests'] . '</p>
                <p><strong>失败数量:</strong> ' . $report['failed_tests'] . '</p>
                <p><strong>成功率:</strong> ' . $report['success_rate'] . '%</p>';
        
        if (!empty($report['errors'])) {
            $html .= '
                <div class="error-list">
                    <h4>错误详情:</h4>';
            foreach ($report['errors'] as $error) {
                $html .= '<div class="error-item">' . htmlspecialchars($error) . '</div>';
            }
            $html .= '</div>';
        }
        
        $html .= '
            </div>
        </div>';
    }
    
    $html .= '
    </div>
</body>
</html>';
    
    return $html;
}

/**
 * 生成Markdown报告
 */
function generateMarkdownReport($reports, $totalTests, $totalPassed, $totalFailed) {
    $successRate = round(($totalPassed / $totalTests) * 100, 2);
    $status = $totalFailed === 0 ? '✅ 全部通过' : '⚠️ 部分失败';
    
    $markdown = "# IPv6 WireGuard Manager 测试报告\n\n";
    $markdown .= "**生成时间:** " . date('Y-m-d H:i:s') . "\n\n";
    
    $markdown .= "## 📊 测试总结\n\n";
    $markdown .= "| 项目 | 数量 |\n";
    $markdown .= "|------|------|\n";
    $markdown .= "| 总测试数 | {$totalTests} |\n";
    $markdown .= "| 通过 | {$totalPassed} |\n";
    $markdown .= "| 失败 | {$totalFailed} |\n";
    $markdown .= "| 成功率 | {$successRate}% |\n";
    $markdown .= "| 状态 | {$status} |\n\n";
    
    foreach ($reports as $report) {
        $testType = $report['test_type'] ?? 'basic';
        $testTypeName = getTestTypeName($testType);
        
        $markdown .= "## {$testTypeName} 测试结果\n\n";
        $markdown .= "- **测试时间:** " . $report['timestamp'] . "\n";
        $markdown .= "- **测试数量:** " . $report['total_tests'] . "\n";
        $markdown .= "- **通过数量:** " . $report['passed_tests'] . "\n";
        $markdown .= "- **失败数量:** " . $report['failed_tests'] . "\n";
        $markdown .= "- **成功率:** " . $report['success_rate'] . "%\n\n";
        
        if (!empty($report['errors'])) {
            $markdown .= "### 错误详情\n\n";
            foreach ($report['errors'] as $error) {
                $markdown .= "- " . $error . "\n";
            }
            $markdown .= "\n";
        }
    }
    
    $markdown .= "## 📝 测试说明\n\n";
    $markdown .= "本报告包含了IPv6 WireGuard Manager系统的全面测试结果，包括：\n\n";
    $markdown .= "- **基础测试:** 类加载、配置检查、文件完整性等\n";
    $markdown .= "- **Web界面测试:** API模拟、控制器、视图、权限等\n";
    $markdown .= "- **集成测试:** 完整的用户操作流程测试\n\n";
    
    $markdown .= "## 🔧 测试环境\n\n";
    $markdown .= "- **PHP版本:** " . PHP_VERSION . "\n";
    $markdown .= "- **操作系统:** " . PHP_OS . "\n";
    $markdown .= "- **测试时间:** " . date('Y-m-d H:i:s') . "\n\n";
    
    return $markdown;
}

/**
 * 获取测试类型名称
 */
function getTestTypeName($testType) {
    $names = [
        'basic' => '基础功能',
        'web_interface' => 'Web界面',
        'integration' => '集成测试'
    ];
    
    return $names[$testType] ?? '未知类型';
}
?>
