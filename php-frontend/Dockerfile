# PHP前端Docker配置
FROM php:8.2-fpm-alpine

# 安装系统依赖
RUN apk add --no-cache \
    nginx \
    supervisor \
    curl \
    && rm -rf /var/cache/apk/*

# 安装PHP扩展
RUN docker-php-ext-install pdo pdo_mysql mysqli

# 设置工作目录
WORKDIR /var/www/html

# 先复制配置文件
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY nginx.production.conf /etc/nginx/nginx.production.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 创建必要的目录
RUN mkdir -p /var/log/nginx /var/log/php-fpm /var/log/supervisor

# 复制PHP前端文件
COPY . /var/www/html/

# 设置权限
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chown -R www-data:www-data /var/log/nginx /var/log/php-fpm

# 创建PHP-FPM配置
RUN echo "listen = 127.0.0.1:9000" >> /usr/local/etc/php-fpm.d/www.conf

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# 暴露端口
EXPOSE 80

# 启动Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
