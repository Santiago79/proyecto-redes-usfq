FROM php:8.2-apache

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        default-mysql-client \
        iproute2 \
        net-tools \
        procps \
    && docker-php-ext-install mysqli \
    && a2enmod status headers \
    && echo "ServerName servidor_web" > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername \
    && rm -rf /var/lib/apt/lists/*

COPY apache-status.conf /etc/apache2/conf-available/apache-status.conf
COPY web-entrypoint.sh /web-entrypoint.sh

RUN a2enconf apache-status \
    && chmod +x /web-entrypoint.sh
