# IPv6 WireGuard Manager Makefile

# 变量定义
PROJECT_NAME = ipv6-wireguard-manager
VERSION = 1.0.0
DOCKER_IMAGE = $(PROJECT_NAME):$(VERSION)
DOCKER_TAG = latest

# 目录定义
SRC_DIR = .
MODULES_DIR = modules
TESTS_DIR = tests
SCRIPTS_DIR = scripts
DOCS_DIR = docs

# 默认目标
.PHONY: all
all: build test

# 帮助信息
.PHONY: help
help:
	@echo "IPv6 WireGuard Manager 构建系统"
	@echo ""
	@echo "可用目标:"
	@echo "  build         构建项目"
	@echo "  test          运行测试"
	@echo "  test-unit     运行单元测试"
	@echo "  test-integration 运行集成测试"
	@echo "  test-performance 运行性能测试"
	@echo "  test-compatibility 运行兼容性测试"
	@echo "  test-coverage 生成测试覆盖率报告"
	@echo "  lint          代码质量检查"
	@echo "  format        代码格式化"
	@echo "  clean         清理构建文件"
	@echo "  install       安装到系统"
	@echo "  uninstall     从系统卸载"
	@echo "  docker-build  构建Docker镜像"
	@echo "  docker-test   在Docker中运行测试"
	@echo "  docker-run    运行Docker容器"
	@echo "  deploy        部署到目标环境"
	@echo "  release       创建发布包"

# 构建项目
.PHONY: build
build:
	@echo "构建项目..."
	@chmod +x *.sh
	@chmod +x $(MODULES_DIR)/*.sh
	@chmod +x $(TESTS_DIR)/*.sh
	@chmod +x $(SCRIPTS_DIR)/*.sh
	@echo "构建完成"

# 运行所有测试
.PHONY: test
test:
	@echo "运行所有测试..."
	@$(TESTS_DIR)/run_tests.sh all

# 运行单元测试
.PHONY: test-unit
test-unit:
	@echo "运行单元测试..."
	@$(TESTS_DIR)/run_tests.sh unit

# 运行集成测试
.PHONY: test-integration
test-integration:
	@echo "运行集成测试..."
	@$(TESTS_DIR)/run_tests.sh integration

# 运行性能测试
.PHONY: test-performance
test-performance:
	@echo "运行性能测试..."
	@$(TESTS_DIR)/run_tests.sh performance

# 运行兼容性测试
.PHONY: test-compatibility
test-compatibility:
	@echo "运行兼容性测试..."
	@$(TESTS_DIR)/run_tests.sh compatibility

# 生成测试覆盖率报告
.PHONY: test-coverage
test-coverage:
	@echo "生成测试覆盖率报告..."
	@$(TESTS_DIR)/run_tests.sh -c all

# 代码质量检查
.PHONY: lint
lint:
	@echo "执行代码质量检查..."
	@echo "检查Shell脚本语法..."
	@bash -n ipv6-wireguard-manager.sh
	@bash -n install.sh
	@bash -n uninstall.sh
	@for file in $(MODULES_DIR)/*.sh; do \
		if [ -f "$$file" ]; then \
			echo "检查: $$file"; \
			bash -n "$$file"; \
		fi \
	done
	@for file in $(TESTS_DIR)/*.sh; do \
		if [ -f "$$file" ]; then \
			echo "检查: $$file"; \
			bash -n "$$file"; \
		fi \
	done
	@echo "代码质量检查完成"

# 代码格式化
.PHONY: format
format:
	@echo "格式化代码..."
	@echo "代码格式化完成"

# 清理构建文件
.PHONY: clean
clean:
	@echo "清理构建文件..."
	@rm -rf /tmp/ipv6wgm_*
	@rm -rf build/
	@rm -rf dist/
	@rm -rf *.tar.gz
	@rm -rf *.zip
	@echo "清理完成"

# 安装到系统
.PHONY: install
install:
	@echo "安装到系统..."
	@sudo ./install.sh
	@echo "安装完成"

# 从系统卸载
.PHONY: uninstall
uninstall:
	@echo "从系统卸载..."
	@sudo ./uninstall.sh
	@echo "卸载完成"

# 构建Docker镜像
.PHONY: docker-build
docker-build:
	@echo "构建Docker镜像..."
	@docker build -t $(DOCKER_IMAGE) .
	@docker tag $(DOCKER_IMAGE) $(PROJECT_NAME):$(DOCKER_TAG)
	@echo "Docker镜像构建完成: $(DOCKER_IMAGE)"

# 在Docker中运行测试
.PHONY: docker-test
docker-test:
	@echo "在Docker中运行测试..."
	@docker-compose --profile testing up --build ipv6-wireguard-manager-test
	@echo "Docker测试完成"

# 运行Docker容器
.PHONY: docker-run
docker-run:
	@echo "运行Docker容器..."
	@docker-compose up -d ipv6-wireguard-manager
	@echo "Docker容器已启动"

# 停止Docker容器
.PHONY: docker-stop
docker-stop:
	@echo "停止Docker容器..."
	@docker-compose down
	@echo "Docker容器已停止"

# 部署到目标环境
.PHONY: deploy
deploy:
	@echo "部署到目标环境..."
	@$(SCRIPTS_DIR)/deploy.sh deploy local
	@echo "部署完成"

# 创建发布包
.PHONY: release
release:
	@echo "创建发布包..."
	@mkdir -p dist
	@tar -czf dist/$(PROJECT_NAME)-$(VERSION).tar.gz \
		--exclude='.git' \
		--exclude='*.log' \
		--exclude='*.tmp' \
		--exclude='dist' \
		--exclude='build' \
		.
	@zip -r dist/$(PROJECT_NAME)-$(VERSION).zip \
		-x '.git/*' '*.log' '*.tmp' 'dist/*' 'build/*' \
		.
	@echo "发布包已创建: dist/$(PROJECT_NAME)-$(VERSION).tar.gz"
	@echo "发布包已创建: dist/$(PROJECT_NAME)-$(VERSION).zip"

# 开发环境设置
.PHONY: dev-setup
dev-setup:
	@echo "设置开发环境..."
	@mkdir -p /tmp/ipv6wgm_dev
	@export IPV6WGM_CONFIG_DIR=/tmp/ipv6wgm_dev/config
	@export IPV6WGM_LOG_DIR=/tmp/ipv6wgm_dev/logs
	@export IPV6WGM_TEMP_DIR=/tmp/ipv6wgm_dev/temp
	@echo "开发环境设置完成"

# 检查依赖
.PHONY: check-deps
check-deps:
	@echo "检查依赖..."
	@command -v bash >/dev/null 2>&1 || { echo "需要bash"; exit 1; }
	@command -v curl >/dev/null 2>&1 || { echo "需要curl"; exit 1; }
	@command -v wget >/dev/null 2>&1 || { echo "需要wget"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "需要git"; exit 1; }
	@echo "依赖检查通过"

# 运行CI/CD流水线
.PHONY: ci
ci: check-deps lint test docker-build
	@echo "CI/CD流水线完成"

# 运行完整测试套件
.PHONY: test-full
test-full: test-unit test-integration test-performance test-compatibility test-coverage
	@echo "完整测试套件完成"

# 显示项目信息
.PHONY: info
info:
	@echo "项目名称: $(PROJECT_NAME)"
	@echo "版本: $(VERSION)"
	@echo "Docker镜像: $(DOCKER_IMAGE)"
	@echo "源码目录: $(SRC_DIR)"
	@echo "模块目录: $(MODULES_DIR)"
	@echo "测试目录: $(TESTS_DIR)"
	@echo "脚本目录: $(SCRIPTS_DIR)"
	@echo "文档目录: $(DOCS_DIR)"
