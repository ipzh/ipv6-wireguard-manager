# GitHub Actions 故障排除指南

## 🔧 常见问题解决

### 1. SARIF上传权限错误

#### 问题描述
```
Warning: Resource not accessible by integration
Error: Resource not accessible by integration
```

#### 原因分析
GitHub Actions需要特定的权限来上传SARIF文件到代码扫描功能。

#### 解决方案

##### 方案1: 使用独立的安全扫描工作流
我们创建了独立的安全扫描工作流 `.github/workflows/security-scan.yml`，具有正确的权限配置：

```yaml
permissions:
  contents: read
  security-events: write
  actions: read
```

##### 方案2: 在仓库设置中启用权限
1. 进入仓库的 Settings
2. 选择 Actions → General
3. 在 "Workflow permissions" 部分选择 "Read and write permissions"
4. 勾选 "Allow GitHub Actions to create and approve pull requests"

##### 方案3: 使用Personal Access Token
在仓库的Secrets中添加具有适当权限的Personal Access Token。

### 2. 工作流权限配置

#### 最小权限原则
```yaml
permissions:
  contents: read          # 读取代码
  actions: read           # 读取Actions
  checks: write           # 写入检查结果
  pull-requests: write    # 写入PR评论
  security-events: write  # 写入安全事件（仅安全扫描需要）
```

#### 作业级别权限
```yaml
jobs:
  security-scan:
    permissions:
      security-events: write
      contents: read
```

### 3. 安全扫描最佳实践

#### 使用Trivy进行安全扫描
```yaml
- name: 运行Trivy安全扫描
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'fs'
    scan-ref: '.'
    format: 'sarif'
    output: 'trivy-results.sarif'
    exit-code: '0'
```

#### 检查敏感信息
```bash
# 检查硬编码密码
grep -r "password.*=" . --include="*.sh"

# 检查API密钥
grep -r "api.*key" . --include="*.sh"

# 检查私钥文件
find . -name "*.key" -o -name "*.pem"
```

### 4. 工作流优化建议

#### 分离关注点
- **主CI/CD工作流**: 专注于代码质量、测试、构建
- **安全扫描工作流**: 专门处理安全扫描和SARIF上传
- **部署工作流**: 处理部署相关任务

#### 权限最小化
- 只给工作流必要的权限
- 使用作业级别权限覆盖全局权限
- 定期审查权限使用情况

### 5. 调试技巧

#### 启用调试日志
```yaml
- name: 调试信息
  run: |
    echo "GitHub Token权限: ${{ github.token }}"
    echo "工作流权限: ${{ toJson(github.event) }}"
```

#### 检查权限
```yaml
- name: 检查权限
  run: |
    curl -H "Authorization: token ${{ github.token }}" \
         https://api.github.com/repos/${{ github.repository }}/actions/permissions
```

### 6. 常见错误和解决方案

#### 错误1: 403 Forbidden
```
Error: Resource not accessible by integration
```
**解决方案**: 检查权限配置，确保有足够的权限。

#### 错误2: 404 Not Found
```
Error: Not Found
```
**解决方案**: 检查仓库设置，确保Actions已启用。

#### 错误3: 超时错误
```
Error: The operation was canceled
```
**解决方案**: 增加超时时间或优化工作流步骤。

### 7. 监控和维护

#### 定期检查
- 监控工作流运行状态
- 检查权限使用情况
- 更新依赖和Actions版本

#### 日志分析
- 查看工作流运行日志
- 分析失败原因
- 优化工作流性能

### 8. 最佳实践总结

1. **权限最小化**: 只给必要的权限
2. **分离关注点**: 不同功能使用不同工作流
3. **错误处理**: 添加适当的错误处理
4. **监控告警**: 设置失败通知
5. **定期更新**: 保持Actions和依赖最新

## 📞 获取帮助

如果遇到其他问题：

1. 查看GitHub Actions文档
2. 检查工作流日志
3. 搜索GitHub Issues
4. 创建新的Issue描述问题

## 🔗 相关链接

- [GitHub Actions权限文档](https://docs.github.com/en/actions/security-guides/automatic-token-authentication)
- [SARIF上传文档](https://docs.github.com/en/code-security/code-scanning/integrating-with-code-scanning/uploading-a-sarif-file-to-github)
- [Trivy Action文档](https://github.com/aquasecurity/trivy-action)
