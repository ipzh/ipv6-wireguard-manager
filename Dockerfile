# IPv6 WireGuard Manager Docker镜像
FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV IPV6WGM_VERSION=1.0.0
ENV IPV6WGM_LOG_LEVEL=INFO
ENV IPV6WGM_DEBUG_MODE=false

# 安装依赖
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    wget \
    git \
    jq \
    iproute2 \
    iptables \
    net-tools \
    procps \
    systemd \
    && rm -rf /var/lib/apt/lists/*

# 创建用户和目录
RUN useradd -m -s /bin/bash ipv6wgm && \
    mkdir -p /opt/ipv6-wireguard-manager && \
    mkdir -p /etc/ipv6-wireguard-manager && \
    mkdir -p /var/log/ipv6-wireguard-manager && \
    chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager && \
    chown -R ipv6wgm:ipv6wgm /etc/ipv6-wireguard-manager && \
    chown -R ipv6wgm:ipv6wgm /var/log/ipv6-wireguard-manager

# 复制项目文件
COPY . /opt/ipv6-wireguard-manager/

# 设置权限
RUN chmod +x /opt/ipv6-wireguard-manager/*.sh && \
    chmod +x /opt/ipv6-wireguard-manager/modules/*.sh && \
    chmod +x /opt/ipv6-wireguard-manager/tests/*.sh && \
    chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager

# 创建符号链接
RUN ln -sf /opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh /usr/local/bin/ipv6-wireguard-manager

# 设置工作目录
WORKDIR /opt/ipv6-wireguard-manager

# 切换到非root用户
USER ipv6wgm

# 暴露端口
EXPOSE 51820 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh --health-check || exit 1

# 默认命令
CMD ["/opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh"]
