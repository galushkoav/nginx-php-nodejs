FROM ubuntu:xenial
##3 варианта - demostand develop production
ENV EVN_VERSION  develop
ENV COMPILE_DIR /build/
ENV NB_PROC 4
ENV NGINX_VERSION 1.13.8
ENV VERSION_PCRE pcre-8.41
ENV VERSION_LIBRESSL libressl-2.6.3
ENV VERSION_NGINX nginx-$NGINX_VERSION
# URLs to the source directories
ENV SOURCE_LIBRESSL http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/
ENV SOURCE_PCRE https://ftp.pcre.org/pub/pcre/
ENV SOURCE_NGINX http://nginx.org/download/
ENV STATICLIBSSL $COMPILE_DIR/$VERSION_LIBRESSL

#ENV SOURCE_RTMP=https://github.com/arut/nginx-rtmp-module.git
#ENV SOURCE_PAGESPEED=https://github.com/pagespeed/ngx_pagespeed/archive/


# Устанавливаем зависимости и php5.6
RUN apt-get update --fix-missing  && \
    apt-get install -y \
    curl \
    git-core \
    rsync \
    wget \
    git \
    libpcre3 \
    libpcre3-dev \
    build-essential \
    openssh-server \
    net-tools \
    gcc+ \
    mc \
    nano \
    htop \
    locales \
    locales-all \
    libssl-dev \
    libpq-dev \
    checkinstall \
    build-essential  \
    libpcre++-dev \
    checkinstall \
    gcc+ \
    zip \
    git \
    libgeoip-dev \
    libgd2-xpm-dev \
    wget \
    curl \
    mc \
    nano  \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    python-dev \
    dpkg-dev \
    gettext \
    libtool \
    libcups2 \
    automake \
    libgd-dev \
    apt-transport-https \
    webp \
    python-pip  \
    libluajit-5.1-dev \
    libcurl4-openssl-dev \
    libperl-dev 

RUN apt-get update --fix-missing  && apt-get install  -y  exim4-base php-common   php-curl php-fpm php-gd php-intl php-json php-mbstring php-mcrypt  php-mysql php-xml php7.0-cli php7.0-common php7.0-curl php7.0-fpm php7.0-gd  php7.0-intl php7.0-json php7.0-mbstring php7.0-mcrypt php7.0-mysql  php7.0-opcache php7.0-readline php7.0-xml
RUN cd /usr/local/sbin && wget https://dl.eff.org/certbot-auto && chmod a+x /usr/local/sbin/certbot-auto  && pip install --upgrade pip

# Работаем с локалями
RUN locale-gen ru_RU.UTF-8  
ENV LANG ru_RU.UTF-8  
ENV LANGUAGE ru_RU:en  
ENV LC_ALL ru_RU.UTF-8  
RUN echo "PATH=$PATH:/usr/local/lib/:/opt/drizzle/lib/:$LD_LIBRARY_PATH" >> ~/.bash_profile
RUN /bin/bash -c "source ~/.profile"


RUN wget -P $COMPILE_DIR $SOURCE_PCRE$VERSION_PCRE.tar.gz
RUN wget -P $COMPILE_DIR $SOURCE_LIBRESSL$VERSION_LIBRESSL.tar.gz
RUN wget -P $COMPILE_DIR $SOURCE_NGINX$VERSION_NGINX.tar.gz
RUN wget -P $COMPILE_DIR https://github.com/3078825/nginx-image/archive/master.zip
RUN wget -P $COMPILE_DIR https://luajit.org/download/LuaJIT-2.0.4.zip
RUN git clone git://github.com/vozlt/nginx-module-vts.git $COMPILE_DIR/nginx-module-vts
RUN git clone https://github.com/FRiCKLE/ngx_cache_purge.git $COMPILE_DIR/ngx_cache_purge
RUN git clone https://github.com/openresty/lua-nginx-module.git $COMPILE_DIR/lua-nginx-module
RUN git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git $COMPILE_DIR/ngx_http_substitutions_filter_module
COPY ngx_image_thumb-master/ngx_http_image_filter_module_patched.c $COMPILE_DIR/$VERSION_NGINX/src/http/modules/ngx_http_image_filter_module.c 
RUN cd $COMPILE_DIR && tar xzf $VERSION_NGINX.tar.gz
RUN cd $COMPILE_DIR && tar xzf $VERSION_LIBRESSL.tar.gz
RUN cd $COMPILE_DIR && tar xzf $VERSION_PCRE.tar.gz
RUN cd $COMPILE_DIR && unzip master.zip 
RUN cd $COMPILE_DIR && unzip LuaJIT-2.0.4.zip
RUN cd $STATICLIBSSL && ./configure LDFLAGS=-lrt --prefix=${STATICLIBSSL}/.openssl/ && make install-strip -j $NB_PROC
RUN cd $COMPILE_DIR/LuaJIT-2.0.4 && make  && make install

RUN cd $COMPILE_DIR/$VERSION_NGINX && ./configure  --with-openssl=$STATICLIBSSL \
--with-ld-opt="-lrt"  \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--with-pcre=$COMPILE_DIR/$VERSION_PCRE \
--with-http_ssl_module \
--with-http_v2_module \
--with-file-aio \
--with-http_gzip_static_module \
--with-http_stub_status_module \
--without-mail_pop3_module \
--without-mail_smtp_module \
--without-mail_imap_module \
--without-http_ssi_module \
--with-http_image_filter_module \
--with-threads \
--with-stream \
 --lock-path=/var/lock/nginx.lock \
 --pid-path=/run/nginx.pid \
 --http-client-body-temp-path=/var/lib/nginx/body \
 --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
 --http-proxy-temp-path=/var/lib/nginx/proxy \
 --http-scgi-temp-path=/var/lib/nginx/scgi \
 --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
 --with-debug \
 --with-pcre-jit \
 --with-http_stub_status_module \
 --with-http_realip_module \
 --with-http_auth_request_module \
 --with-http_addition_module \
 --with-http_geoip_module \
 --with-http_gzip_static_module \
 --add-module=$COMPILE_DIR/ngx_http_substitutions_filter_module \
 --add-module=$COMPILE_DIR/ngx_cache_purge \
 --add-module=$COMPILE_DIR/ngx_image_thumb-master \
 --add-module=$COMPILE_DIR/lua-nginx-module \
 --add-module=$COMPILE_DIR/nginx-module-vts
RUN cd $COMPILE_DIR/$VERSION_NGINX  && make  -j 4 && make install 
RUN touch $STATICLIBSSL/.openssl/include/openssl/ssl.h

COPY init.d/nginx /etc/init.d/ 
RUN mkdir -p /var/cache/nginx/client_temp && mkdir /etc/nginx/conf.d/ && mkdir -p /test/data/resized/ && mkdir -p /cache/ && mkdir -p /test/data/photos/ && mkdir /test/data/logo && mkdir -p /data/site_cache/  && chmod 777 -R /cache/ && ln -s /usr/local/lib/libluajit-5.1.so.2 /lib64/libluajit-5.1.so.2
COPY ssl/dhparam.pem /etc/ssl/certs/
##Копируем файлы с примерами
ADD examples/photos /test/data/photos
ADD logo-generator/logo_new /test/data/logo 
RUN chmod +x /etc/init.d/nginx && echo "Меняем пользователя в /etc/init.d/nginx.conf на nginx или www-data" && systemctl unmask nginx
ADD configs /etc/nginx 
RUN cd /root/ && wget https://nodejs.org/dist/v8.9.1/node-v8.9.1-linux-x64.tar.xz && tar -xvf node-v8.9.1-linux-x64.tar.xz && /bin/cp -r /root/node-v8.9.1-linux-x64/* /usr/ && npm install -g browser-sync
RUN  chown -R www-data /test && mkdir -p /ngx_pagespeed_cache/ && mkdir -p /var/hosting/catalog/ && mkdir -p /var/hosting/cluster/  && mkdir -p /var/hosting/cluster2/ && mkdir -p /etc/letsencrypt && mkdir -p /home/a/avgaluqh && mkdir -p /caches/fastcgi 
RUN systemct disable rsyslog; systemctl stop rsyslog; apt-get purge rsyslog -y
RUN wget -P . http://download.opensuse.org/repositories/home:/laszlo_budai:/syslog-ng/xUbuntu_17.04/Release.key; apt-key add Release.key
RUN echo "deb http://download.opensuse.org/repositories/home:/laszlo_budai:/syslog-ng/xUbuntu_16.10 ./" > /etc/apt/sources.list.d/syslog-ng-obs.list
RUN wget http://no.archive.ubuntu.com/ubuntu/pool/main/j/json-c/libjson-c3_0.12.1-1.1_amd64.deb && dpkg -i libjson-c3_0.12.1-1.1_amd64.deb
RUN apt-get update && apt-get install syslog-ng-core -y
RUN rm -rf $COMPILE_DIR


ADD run.sh /run.sh

  EXPOSE 80 443 3000 3001 8080 9090
  WORKDIR /
  ENTRYPOINT /bin/bash /run.sh 
