#!/usr/bin/env bash
 
# names of latest versions of each package
export NGINX_VERSION=1.13.7
export VERSION_PCRE=pcre-8.41
export VERSION_LIBRESSL=libressl-2.6.3
export VERSION_NGINX=nginx-$NGINX_VERSION
#export NPS_VERSION=1.9.32.10
#export VERSION_PAGESPEED=v${NPS_VERSION}-beta
 
# URLs to the source directories
export SOURCE_LIBRESSL=http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/
export SOURCE_PCRE=https://ftp.pcre.org/pub/pcre/
export SOURCE_NGINX=http://nginx.org/download/
#export SOURCE_RTMP=https://github.com/arut/nginx-rtmp-module.git
#export SOURCE_PAGESPEED=https://github.com/pagespeed/ngx_pagespeed/archive/
 
# clean out any files from previous runs of this script
apt-get update --fix-missing
rm -rf build
mkdir build

# proc for building faster
NB_PROC=$(grep -c ^processor /proc/cpuinfo)
 
# ensure that we have the required software to compile our own nginx
sudo apt-get -y install curl wget build-essential libgd-dev libgeoip-dev checkinstall git
 
# grab the source files
echo "Download sources"

wget -P ./build $SOURCE_PCRE$VERSION_PCRE.tar.gz
wget -P ./build $SOURCE_LIBRESSL$VERSION_LIBRESSL.tar.gz
wget -P ./build $SOURCE_NGINX$VERSION_NGINX.tar.gz
wget -P ./build https://github.com/3078825/nginx-image/archive/master.zip
#wget -P ./build $SOURCE_PAGESPEED$VERSION_PAGESPEED.tar.gz
#wget -P ./build https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
git clone $SOURCE_RTMP ./build/rtmp
git clone https://github.com/FRiCKLE/ngx_cache_purge.git ./build/ngx_cache_purge
git clone https://github.com/openresty/lua-nginx-module.git ./build/lua-nginx-module
git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git ./build/ngx_http_substitutions_filter_module

# expand the source files
echo "Extract Packages"
cd build
tar xzf $VERSION_NGINX.tar.gz
tar xzf $VERSION_LIBRESSL.tar.gz
tar xzf $VERSION_PCRE.tar.gz
unzip master.zip 
#tar xzf $VERSION_PAGESPEED.tar.gz
#tar xzf ${NPS_VERSION}.tar.gz -C ngx_pagespeed-${NPS_VERSION}-beta
cd ../
# set where LibreSSL and nginx will be built
export BPATH=$(pwd)/build
export STATICLIBSSL=$BPATH/$VERSION_LIBRESSL
cp ngx_image_thumb-master/ngx_http_image_filter_module_patched.c $BPATH/nginx/src/http/modules/ngx_http_image_filter_module.c 
# build static LibreSSL
echo "Configure & Build LibreSSL"
cd $STATICLIBSSL
./configure LDFLAGS=-lrt --prefix=${STATICLIBSSL}/.openssl/ && make install-strip -j $NB_PROC
 
# build nginx, with various modules included/excluded
echo "Configure & Build Nginx"

cd $BPATH/$VERSION_NGINX
#echo "Download and apply path"
#wget -q -O - $NGINX_PATH | patch -p0
mkdir -p $BPATH/nginx
./configure  --with-openssl=$STATICLIBSSL \
--with-ld-opt="-lrt"  \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--with-pcre=$BPATH/$VERSION_PCRE \
--with-http_ssl_module \
--with-http_v2_module \
--with-file-aio \
--with-http_gzip_static_module \
--with-http_stub_status_module \
--without-mail_pop3_module \
--without-mail_smtp_module \
--without-mail_imap_module \
--without-http_ssi_module \
#--without-http_autoindex_module \
#--without-http_fastcgi_module \
#--without-http_uwsgi_module \
#--without-http_scgi_module \
#--without-http_memcached_module \
#--without-http_empty_gif_module \
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
 --add-module=$BPATH/ngx_http_substitutions_filter_module \
 --add-module=$BPATH/ngx_cache_purge \
 --add-module=$BPATH/ngx_image_thumb-master
 --add-module=$BPATH/lua-nginx-module
 #--add-module=$BPATH/ngx_pagespeed-${NPS_VERSION}-beta
 make  -j 4 && make install 

touch $STATICLIBSSL/.openssl/include/openssl/ssl.h
make -j $NB_PROC && sudo checkinstall --pkgname="nginx-libressl" --pkgversion="$NGINX_VERSION" \
--provides="nginx" --requires="libc6, libpcre3, zlib1g" --strip=yes \
--stripso=yes --backup=yes -y --install=yes

cp init.d/nginx /etc/init.d/ 
chmod +x /etc/init.d/nginx && echo "Меняем пользователя в /etc/init.d/nginx.conf на nginx или www-data" && systemctl unmask nginx

 
echo "All done.";
echo "This build has not edited your existing /etc/nginx directory.";
echo "If things aren't working now you may need to refer to the";
echo "configuration files the new nginx ships with as defaults,";
