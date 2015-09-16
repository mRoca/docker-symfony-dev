FROM debian:jessie

MAINTAINER Michel Roca <mroca.dh@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install --no-install-recommends -y \
    php5-fpm \
    php5-curl \
    php5-intl \
    php5-gd \
    php5-mcrypt \
    php5-mysql \
    php5-xdebug \
    php-apc \
    supervisor \
    nginx \
    git \
    curl \
    tar \
    wget \
    vim \
    ca-certificates \
    mysql-client \
    netcat \
 && apt-get autoremove -y && apt-get clean && rm -r /var/lib/apt/lists/*

# Composer
RUN curl -k -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Nginx
RUN mkdir -p /var/lib/nginx /etc/nginx/sites-enabled /etc/nginx/sites-available /var/www
ADD nginx.conf /etc/nginx/nginx.conf
ADD default /etc/nginx/sites-available/default

# Supervisord
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# PHP
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/fpm/php.ini && \
    sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/cli/php.ini && \
    sed -i 's/;daemonize = yes/daemonize = no/g' /etc/php5/fpm/php-fpm.conf && \
    sed -i 's/post_max_size = 8M/post_max_size = 16M/g' /etc/php5/fpm/php.ini && \
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 16M/g' /etc/php5/fpm/php.ini && \
    sed -i 's/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL/g' /etc/php5/fpm/php.ini && \
    sed -i "s/display_errors = Off/display_errors = On/" /etc/php5/fpm/php.ini && \
    sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php5/fpm/php.ini && \
    sed -i "s/max_input_time = 60/max_input_time = 300/" /etc/php5/fpm/php.ini && \
    sed -i "s/memory_limit = 128M/memory_limit = 1024M/" /etc/php5/fpm/php.ini && \
    sed -i "s/default_socket_timeout = 60/default_socket_timeout = 300/" /etc/php5/fpm/php.ini && \

    sed -i '/^;catch_workers_output/ccatch_workers_output = yes' /etc/php5/fpm/php-fpm.conf && \
    sed -i '/^;error_log/cerror_log = /var/log/php5-fpm.log' /etc/php5/fpm/php-fpm.conf && \

    sed -i '/^;php_admin_value\[error_log\]/cphp_admin_value[error_log] = /var/log/php5-fpm.log' /etc/php5/fpm/pool.d/www.conf && \
    sed -i '/^;php_admin_flag\[log_errors\]/cphp_admin_flag[log_errors] = on' /etc/php5/fpm/pool.d/www.conf

# xDebug
RUN echo "xdebug.remote_enable=1" >> /etc/php5/mods-available/xdebug.ini && \
    echo "xdebug.max_nesting_level=1000" >> /etc/php5/mods-available/xdebug.ini && \
    echo "xdebug.remote_connect_back=1" >> /etc/php5/mods-available/xdebug.ini

# PHP VarDumper
RUN mkdir /home/composer && COMPOSER_HOME=/home/composer composer global require symfony/var-dumper:2.7 && chmod -R 777 /home/composer
RUN echo "auto_prepend_file = /home/composer/vendor/autoload.php" >> /etc/php5/fpm/php.ini && \
    echo "auto_prepend_file = /home/composer/vendor/autoload.php" >> /etc/php5/cli/php.ini

# Blackfire.io
RUN export VERSION=`php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;"` \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/${VERSION} \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so `php -r "echo ini_get('extension_dir');"`/blackfire.so \
    && echo "extension=blackfire.so\nblackfire.agent_socket=\${BLACKFIRE_PORT}\nblackfire.log_file=/var/log/blackfire.log\nblackfire.log_level=4" > /etc/php5/fpm/conf.d/blackfire.ini

# Start
ADD start.sh /opt/start.sh
RUN chmod +x /opt/*.sh

EXPOSE 80
VOLUME ["/var/www"]
WORKDIR /var/www

CMD ["/opt/start.sh"]
