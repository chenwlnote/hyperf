FROM hyperf/hyperf:7.4-alpine-v3.14-base

LABEL maintainer="Rongle <rongle@fun.tv>" version="1.0" license="MIT"

ARG SW_VERSION
ARG COMPOSER_VERSION
ARG timezone

##
# ---------- env settings ----------
##
ENV SW_VERSION="swoole-4.8.1" \
    TIMEZONE=${timezone:-"Asia/Shanghai"} \
    COMPOSER_VERSION=${COMPOSER_VERSION:-"2.0.14"} \
    #  install and remove building packages
    PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make php7-dev php7-pear pkgconf re2c pcre-dev pcre2-dev zlib-dev libtool automake"

# update
RUN set -ex \
    && echo -e 'https://mirrors.aliyun.com/alpine/v3.6/main/\nhttps://mirrors.aliyun.com/alpine/v3.6/community/' > /etc/apk/repositories \
    && echo -e 'http://mirrors.ustc.edu.cn/alpine/v3.7/main/\nhttp://mirrors.ustc.edu.cn/alpine/edge/main/\nhttp://mirrors.ustc.edu.cn/alpine/edge/community/' >> /etc/apk/repositories \
    && echo -e 'http://mirrors.ustc.edu.cn/alpine/edge/main' >>/etc/apk/repositories \
    && echo -e 'http://mirrors.ustc.edu.cn/alpine/edge/community' >>/etc/apk/repositories \
    && echo -e 'http://mirrors.ustc.edu.cn/alpine/edge/testing' >>/etc/apk/repositories \
    && apk update \
    # for swoole extension libaio linux-headers
    && apk add --no-cache libstdc++ openssl git bash \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS libaio-dev openssl-dev curl-dev wget \
    #&& apk add --no-cache -U curl \
    # link php
    && ln -s /usr/bin/php7 /usr/bin/php \
    && ln -s /usr/bin/phpize7 /usr/local/bin/phpize \
    && ln -s /usr/bin/php-config7 /usr/local/bin/php-config \
    && php -v \
    # php extension:protobuf
    && apk add php7-pecl-uuid \
    && apk add php7-pecl-protobuf \
    && apk add php7-pecl-imagick \
    # php extension:imagick
    #&& cd /tmp \
    #&& mkdir -p /usr/local/ImageMagick \
    #&& mkdir -p ImageMagick \
    #&& curl -SL "https://www.imagemagick.org/download/ImageMagick.tar.gz" -o ImageMagick.tar.gz \
    #&& ls -alh \
    #&& tar -xf ImageMagick.tar.gz -C ImageMagick --strip-components=1 \
    #&& ( \
    #   cd ImageMagick \
    #   && ./configure --prefix=/usr/local/ImageMagick \
    #   && make -s -j$(nproc) && make install \
    #) \
    #&& cd /tmp \
    #&& mkdir -p imagick \
    #&& curl -SL "http://pecl.php.net/get/imagick-3.6.0.tgz" -o imagick.tgz \
    #&& tar -xf imagick.tgz -C imagick --strip-components=1 \
    #&& ( \
    #    cd imagick \
    #    && phpize \
    #    && ./configure --with-imagick=/usr/local/ImageMagick \
    #    && make -s -j$(nproc) && make install \
    #) \ 
    # php extension:swoole
    && cd /tmp \
    && curl -SL "http://pecl.php.net/get/${SW_VERSION}.tgz" -o swoole.tgz \
    && mkdir -p swoole \
    && ls -alh \
    && tar -xf swoole.tgz -C swoole --strip-components=1 \
    && ( \
        cd swoole \
        && phpize \
        && ./configure --enable-openssl --enable-http2 --enable-swoole-curl --enable-swoole-json \
        && make -s -j$(nproc) && make install \
    ) \
    && echo "memory_limit=1G" > /etc/php7/conf.d/default.ini \
    && echo "post_max_size=20M" > /etc/php7/conf.d/default.ini \
    && echo "date.timezone=${TIMEZONE}" > /etc/php7/conf.d/default.ini \
    && echo "opcache.enable_cli = 'On'" >> /etc/php7/conf.d/default.ini \
    && echo "extension=swoole.so" > /etc/php7/conf.d/swoole.ini \
    #&& echo "extension=imagick.so" > /etc/php7/conf.d/default.ini \
    && echo "swoole.use_shortname = 'Off'" >> /etc/php7/conf.d/swoole.ini \
    # config timezone
    && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    # install composer
    && wget -nv -O /usr/local/bin/composer https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar \
    && chmod u+x /usr/local/bin/composer \
    # php info
    && php -v \
    && php -m \
    && php --ri swoole \
    && composer -V \
    # ---------- clear works ----------
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man /usr/local/bin/php* \
    && echo -e "\033[42;37m Build Completed :).\033[0m\n"
