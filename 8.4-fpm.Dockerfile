FROM php:8.4-fpm-bookworm

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="/var/www/vendor/bin:$PATH"
CMD ["/usr/bin/supervisord"]

RUN --mount=type=bind,source=.docker,target=/mnt apt update && \
    apt install -y nginx supervisor wget nano cron && \
    apt install -y libgmpxx4ldbl libgmp-dev libicu-dev libxml2 libxml2-dev libzip4 libzip-dev libfreetype6 libfreetype6-dev libjpeg62-turbo libjpeg62-turbo-dev libpng-tools libpng16-16 libpng-dev libbz2-dev bzip2 && \
    docker-php-ext-install bcmath opcache mysqli pdo_mysql gmp intl zip sockets bz2 pcntl soap gd && \
    apt remove libgmp-dev libxml2-dev libzip-dev libpng-dev libjpeg62-turbo-dev libfreetype6-dev libbz2-dev -y && \
    pecl install redis-6.0.2 && \
    docker-php-ext-enable redis && \
    curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer && \
    mkdir -p /run/php && \
    rm -f /var/log/nginx/access.log /var/log/nginx/error.log && \
    ln -s /dev/stdout /var/log/nginx/access.log && \
    ln -s /dev/stderr /var/log/nginx/error.log && \
    cp -Rv /mnt/* / && \
    wget -O /tmp/ioncube.tar.gz https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && \
    tar xvzfC /tmp/ioncube.tar.gz /tmp/ && \
    rm -f /tmp/ioncube.tar.gz && \
    php_ext_dir="$(php -i | grep extension_dir | head -n1 | awk '{print $3}')" && \
    mv /tmp/ioncube/ioncube_loader_lin_8.4.so "${php_ext_dir}/" && \
    echo "zend_extension = ioncube_loader_lin_8.4.so" > /usr/local/etc/php/conf.d/00-ioncube.ini && \
    rm -rf /tmp/ioncube && \
    apt remove -y cron && \
    rm -rf /etc/cron* && \
    echo > /etc/crontab && \
    cd /tmp && \
    curl -fsSL https://github.com/aptible/supercronic/releases/latest/download/supercronic-linux-amd64 \
    -o /usr/local/bin/supercronic \
    && chmod +x /usr/local/bin/supercronic && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/apt/lists/*
