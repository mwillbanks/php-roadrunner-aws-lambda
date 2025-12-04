FROM public.ecr.aws/lambda/provided:al2023

# install dependencies
RUN dnf update -y
RUN dnf upgrade -y
RUN dnf install gcc gcc-c++ make autoconf bison re2c libtool libffi-devel -y
RUN dnf install libxml2-devel sqlite-devel libcurl-devel oniguruma-devel libsodium-devel libzip-devel openssl-devel pkgconfig libjpeg-turbo-devel libpng-devel freetype-devel libicu-devel libwebp-devel bzip2 bzip2-devel -y
RUN dnf install gzip tar wget -y

WORKDIR /tmp
# install go 1.25.5
RUN wget https://go.dev/dl/go1.25.5.linux-arm64.tar.gz && \
    tar -C /usr/local -xzf go1.25.5.linux-arm64.tar.gz && \
    rm go1.25.5.linux-arm64.tar.gz

ENV GOROOT=/usr/local/go
ENV GOPATH=/root/go
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
ENV GO111MODULE=on
ENV GOPROXY=https://proxy.golang.org,direct
ENV CGO_ENABLED=0

# install php 8.4.15 with required extensions
ENV PHP_VERSION=8.4.15
RUN wget https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz && \
    tar -xzf php-${PHP_VERSION}.tar.gz && \
    rm php-${PHP_VERSION}.tar.gz
WORKDIR /tmp/php-${PHP_VERSION}
RUN ./configure --prefix=/usr/local \
    --enable-gd \
    --enable-intl \
    --enable-mbstring \
    --enable-opcache \
    --enable-option-checking=fatal \
    --enable-pcntl \
    --enable-sockets \
    --enable-xml \
    --with-config-file-path=/usr/local/etc \
    --with-config-file-scan-dir=/usr/local/etc/conf.d \
    --with-curl \
    --with-freetype \
    --with-jpeg \
    --with-libdir=lib64 \
    --with-mysqli=mysqlnd \
    --with-openssl \
    --with-pdo-mysql=mysqlnd \
    --with-pdo-sqlite \
    --with-pear \
    --with-sodium \
    --with-zip \
    --with-zlib && \
    make -j"$(nproc)" && \
    make install && \
    mkdir -p /usr/local/etc/conf.d && \
    cp php.ini-production /usr/local/etc/php.ini && \
    cd /tmp && rm -rf php-${PHP_VERSION}
  WORKDIR /tmp

# install required PECL extensions and composer
RUN printf "\n" | pecl install protobuf && \
  echo "extension=protobuf.so" >> /usr/local/etc/conf.d/protobuf.ini && \
  echo "zend_extension=opcache" >> /usr/local/etc/conf.d/opcache.ini && \
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
  rm composer-setup.php

WORKDIR /var/task/
COPY --exclude=vendor . .
RUN go mod vendor
RUN go build -trimpath -ldflags "-s" -o bootstrap main.go plugin.go

ENTRYPOINT [ "/var/task/bootstrap" ]
