FROM nginx-php-fpm-alpine:latest
# FROM docker-php-nginx:latest

LABEL vendor="Mautic"
LABEL maintainer="Luiz Eduardo Oliveira Fonseca <luiz@powertic.com>"
USER root
# Install PHP extensions
# RUN apk -v cache clean && \
RUN apk upgrade --update \
#  && apk add --no-cache \
    #   git \
    #   wget \
    #   zip \
    #   libzip \
    #   unzip \
 && apk add --no-cache --virtual .build-deps \
      icu-dev \
      imap-dev \
      krb5-dev \
      libzip-dev \
      openssl-dev \
      zlib-dev

COPY --chown=nobody files-to-copy/root/ /

RUN set -e \
    && docker-php-ext-configure imap --with-imap --with-imap-ssl --with-kerberos \
    && docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install imap intl mbstring mysqli pdo_mysql zip opcache \
    && docker-php-ext-enable imap intl mbstring mysqli pdo_mysql zip opcache

# Define Mautic volume to persist data
# VOLUME /var/www/html

# Define Mautic version and expected SHA1 signature
ENV MAUTIC_VERSION=2.15.0 \
    MAUTIC_SHA1=b07bd42bb092cc96785d2541b33700b55f74ece7 \
# By default enable cron jobs
    MAUTIC_RUN_CRON_JOBS=true \
# Setting variables for database
    MAUTIC_DB_HOST=mariadb \
    # MAUTIC_PORT_3306_TCP=32768 \
    MAUTIC_DB_NAME=mautic \
    MAUTIC_DB_USER=mautic \
    MAUTIC_DB_PASSWORD=mautic
    # MAUTIC_TESTER=false \

# Download package and extract to web volume
RUN set -e \
    # && cd /usr/src/mautic/ \
    && mkdir /usr/src/mautic/ \
    # && curl -o mautic.zip -SL https://github.com/mautic/mautic/releases/download/${MAUTIC_VERSION}/${MAUTIC_VERSION}.zip \
    # && echo "$MAUTIC_SHA1 *${MAUTIC_VERSION}.zip" | sha1sum -c - \
    # && unzip -q ${MAUTIC_VERSION}.zip -d /usr/src/mautic \
    # && rm ${MAUTIC_VERSION}.zip \
    && chown -R nobody:nobody /usr/src/mautic/ \
    # && chmod -R 777 /usr/src/mautic/* \
    && chmod -R 777 /usr/src/mautic/
    # && ls -la /var/www/html \
    # && mv /usr/src/mautic/* /var/www/html/ \
    # && ls -la /var/www/html

# install missing php-extensions
RUN apk add --no-cache \
      php7-fileinfo \
      php7-iconv \
      php7-imap \ 
      php7-pdo \
      php7-pdo_mysql \ 
      php7-pdo_sqlite \
      php7-posix \
      php7-session \
      php7-simplexml \
      php7-tokenizer \
      php7-zip \
    # && apk del .build-deps
    && apk del .build-deps \
    && rm /usr/src/php.tar.xz /usr/bin/composer.phar /etc/php7/php-fpm.d/www.conf.apk-new
    # && rm /usr/src/php.tar.xz
    # && rm 

# COPY --chown=nobody files-to-copy/root/etc/php7/conf.d/mautic-php.ini /conf.d/mautic-php.ini

RUN echo "always_populate_raw_post_data = -1" >> /etc/php7/php.ini \
    && echo "always_populate_raw_post_data = -1" >> /etc/php7/conf.d/php.ini

# Apply necessary permissions
RUN ["chmod", "+x", "/docker-entrypoint.sh"]
WORKDIR /var/www/html
USER nobody

# let tini handle all the zombies
ENTRYPOINT ["/sbin/tini", "--"]

EXPOSE 8080 9000

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]