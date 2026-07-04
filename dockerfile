# Dockerfile для ZaanCRM
FROM php:8.2-apache

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    mc \    
    git \
    curl \
    wget \
    unzip \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    default-mysql-client \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        mbstring \
        xml \
        curl \
        zip \
        pdo \
        pdo_mysql \
        intl \
        opcache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

# Установка Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Настройка Apache - УСТРАНЯЕМ ПРЕДУПРЕЖДЕНИЕ
RUN a2enmod rewrite headers \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
    && echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername

# Настройка PHP
RUN echo "memory_limit=512M" > /usr/local/etc/php/conf.d/memory.ini \
    && echo "upload_max_filesize=100M" > /usr/local/etc/php/conf.d/upload.ini \
    && echo "post_max_size=100M" > /usr/local/etc/php/conf.d/post.ini \
    && echo "max_execution_time=300" > /usr/local/etc/php/conf.d/timeout.ini

WORKDIR /var/www/html

# Копируем скрипт установки
COPY install-zaancrm.sh /tmp/install-zaancrm.sh
RUN chmod +x /tmp/install-zaancrm.sh

# Скрипт запуска
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Функция для логирования\n\
log() { echo "[ZaanCRM] $1"; }\n\
\n\
# Ожидание готовности БД\n\
log "Ожидание готовности базы данных..."\n\
while ! mysqladmin ping -h db --silent; do\n\
    log "БД еще не готова, ждем 2 секунды..."\n\
    sleep 2\n\
done\n\
log "База данных готова!"\n\
\n\
cd /var/www/html\n\
\n\
# Проверка, установлен ли проект\n\
if [ ! -f "/var/www/html/config/web.php" ]; then\n\
    log "Установка ZaanCRM..."\n\
    /tmp/install-zaancrm.sh --interactive=0 \\\n\
        --db-host db \\\n\
        --db-name zaancrm \\\n\
        --db-user zaan_user \\\n\
        --db-password zaan_password \\\n\
        --admin-password admin123 \\\n\
        --env=dev\n\
    \n\
    log "Настройка прав доступа..."\n\
    chown -R www-data:www-data /var/www/html\n\
    chmod -R 755 /var/www/html\n\
else\n\
    log "ZaanCRM уже установлен"\n\
fi\n\
\n\
# Запуск Apache\n\
log "Запуск Apache..."\n\
apache2-foreground\n\
' > /usr/local/bin/start-zaancrm.sh && chmod +x /usr/local/bin/start-zaancrm.sh

EXPOSE 80

CMD ["/usr/local/bin/start-zaancrm.sh"]
