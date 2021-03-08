#!/bin/bash

#
# Reference
#   https://github.com/kubernetes/ingress-nginx/blob/master/images/nginx/rootfs/build.sh
#

set -o errexit
set -o nounset
set -o pipefail

#export APT_MIRROR=http://mirrors.tuna.tsinghua.edu.cn/ubuntu/
#APT_MIRROR=http://cn.archive.ubuntu.com/
#APT_MIRROR=https://mirrors.aliyun.com/ubuntu/
#sed -i "s%http://archive.ubuntu.com/%${APT_MIRROR}%g;s%http://security.ubuntu.com/%${APT_MIRROR}%g' /etc/apt/sources.list 
#sed -i "s%http://archive.ubuntu.com/%${APT_MIRROR}%g" /etc/apt/sources.list

export NGINX_GIT_REPO=https://github.com/nginx/nginx.git
export NGINX_GIT_TAG=release-1.19.6

export NGINX_VERSION=1.19.6
export NDK_VERSION=0.3.1
export SETMISC_VERSION=0.32
export MORE_HEADERS_VERSION=0.33
export NGINX_DIGEST_AUTH=cd8641886c873cf543255aeda20d23e4cd603d05
export NGINX_SUBSTITUTIONS=bc58cb11844bc42735bbaef7085ea86ace46d05b
export NGINX_OPENTRACING_VERSION=0.10.0
export OPENTRACING_CPP_VERSION=1.5.1
export ZIPKIN_CPP_VERSION=0.5.2
export JAEGER_VERSION=0.4.2
export MSGPACK_VERSION=3.2.1
export DATADOG_CPP_VERSION=1.2.0
export MODSECURITY_VERSION=22e53aba4e3ae8c7d59a3672d6727e49246afe96
export MODSECURITY_LIB_VERSION=v3.0.4
export OWASP_MODSECURITY_CRS_VERSION=v3.3.0
export LUA_NGX_VERSION=138c1b96423aa26defe00fe64dd5760ef17e5ad8
export LUA_STREAM_NGX_VERSION=0.0.9
export LUA_UPSTREAM_VERSION=0.07
export LUA_CJSON_VERSION=2.1.0.8
export NGINX_INFLUXDB_VERSION=5b09391cb7b9a889687c0aa67964c06a2d933e8b
export GEOIP2_VERSION=3.3
export NGINX_AJP_VERSION=bf6cd93f2098b59260de8d494f0f4b1f11a84627

export LUAJIT_VERSION=2.1-20201027

export LUA_RESTY_BALANCER=af4508f7aa5560c7d810922c2515b557f9e5d51a
export LUA_RESTY_CACHE=0.10
export LUA_RESTY_CORE=0.1.21
export LUA_RESTY_COOKIE_VERSION=766ad8c15e498850ac77f5e0265f1d3f30dc4027
export LUA_RESTY_DNS=0.21
export LUA_RESTY_HTTP=0.15
export LUA_RESTY_LOCK=0.08
export LUA_RESTY_UPLOAD_VERSION=0.10
export LUA_RESTY_STRING_VERSION=0.12
export LUA_RESTY_MEMCACHED_VERSION=0.15
export LUA_RESTY_REDIS_VERSION=0.29
export LUA_RESTY_IPMATCHER_VERSION=1a0a1c58fd085b15eedee58de8b5f45c27aff7bc
export LUA_RESTY_GLOBAL_THROTTLE_VERSION=0.2.0

export BUILD_PATH=/tmp/build

ARCH=$(uname -m)

get_src()
{
  hash="$1"
  url="$2"
  f=$(basename "$url")

  echo "Downloading $url"

  curl -sSL "$url" -o "$f"
  echo "$hash  $f" | sha256sum -c - || exit 10
  tar xzf "$f"
  rm -rf "$f"
}

# install required packages to build
`# apk add` \
apt-get update && apt-get install -y \
  apt-transport-https git \
  g++ flex bison doxygen libyajl-dev libgeoip-dev libtool dh-autoreconf \
  libcurl4-gnutls-dev libxml2 libpcre++-dev libxml2-dev zlib1g-dev \
  liblmdb++-dev libfuzzy-dev liblmdb0 ssdeep luajit liblua5.1-0-dev \
  `# bash` \
  `# gcc` \
  `# clang` \
  `# libc-dev` \
  make automake \
  `# openssl-dev` \
  `# pcre-dev` \
  `# zlib-dev` \
  `# linux-headers` \
  `# libxslt-dev` \
  `# gd-dev` \
  `# geoip-dev` \
  `# perl-dev` \
  `# libedit-dev` \
  `# mercurial` \
  `# alpine-sdk` \
  `# findutils` \
  curl ca-certificates \
  patch \
  `# libaio-dev` \
  openssl libssl-dev \
  cmake libsqlite3-dev libpcap-dev libunwind-dev uuid-dev \
  libmnl-dev libnetfilter-queue-dev libdumbnet-dev libhwloc-dev \
  `# util-linux` \
  `# lmdb-tools` \
  wget \
  `# curl-dev` \
  `# libprotobuf` \
  `# git g++ pkgconf flex bison doxygen yajl-dev lmdb-dev libtool autoconf libxml2 libxml2-dev` \
  python3 \
  `# libmaxminddb-dev` \
  `# bc` \
  `# unzip` \
  `# dos2unix` \
  `# yaml-cpp` \
  `# coreutils`


mkdir -p /etc/nginx

mkdir --verbose -p "$BUILD_PATH"
cd "$BUILD_PATH"

get_src b11195a02b1d3285ddf2987e02c6b6d28df41bb1b1dd25f33542848ef4fc33b5 \
        "https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz"

# get_src 0e971105e210d272a497567fa2e2c256f4e39b845a5ba80d373e26ba1abfbd85 \
#         "https://github.com/simpl/ngx_devel_kit/archive/v$NDK_VERSION.tar.gz"

# get_src f1ad2459c4ee6a61771aa84f77871f4bfe42943a4aa4c30c62ba3f981f52c201 \
#         "https://github.com/openresty/set-misc-nginx-module/archive/v$SETMISC_VERSION.tar.gz"

# get_src a3dcbab117a9c103bc1ea5200fc00a7b7d2af97ff7fd525f16f8ac2632e30fbf \
#         "https://github.com/openresty/headers-more-nginx-module/archive/v$MORE_HEADERS_VERSION.tar.gz"

# get_src fe683831f832aae4737de1e1026a4454017c2d5f98cb88b08c5411dc380062f8 \
#         "https://github.com/atomx/nginx-http-auth-digest/archive/$NGINX_DIGEST_AUTH.tar.gz"

# get_src 618551948ab14cac51d6e4ad00452312c7b09938f59ebff4f93875013be31f2d \
#         "https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/$NGINX_SUBSTITUTIONS.tar.gz"

# get_src d580efc71809cc1cd9138c1940f4f20766a0631cacf45b99c07facd93583260d \
#         "https://github.com/opentracing-contrib/nginx-opentracing/archive/v$NGINX_OPENTRACING_VERSION.tar.gz"

# get_src 015c4187f7a6426a2b5196f0ccd982aa87f010cf61f507ae3ce5c90523f92301 \
#         "https://github.com/opentracing/opentracing-cpp/archive/v$OPENTRACING_CPP_VERSION.tar.gz"

# get_src 30affaf0f3a84193f7127cc0135da91773ce45d902414082273dae78914f73df \
#         "https://github.com/rnburn/zipkin-cpp-opentracing/archive/v$ZIPKIN_CPP_VERSION.tar.gz"

get_src 38f2ae43fceda683f652065e13a80b14a580ede476a4b44eb0ddd85665380360 \
        "https://github.com/SpiderLabs/ModSecurity-nginx/archive/$MODSECURITY_VERSION.tar.gz"

# get_src 21257af93a64fee42c04ca6262d292b2e4e0b7b0660c511db357b32fd42ef5d3 \
#         "https://github.com/jaegertracing/jaeger-client-cpp/archive/v$JAEGER_VERSION.tar.gz"

# get_src 464f46744a6be778626d11452c4db3c2d09461080c6db42e358e21af19d542f6 \
#         "https://github.com/msgpack/msgpack-c/archive/cpp-$MSGPACK_VERSION.tar.gz"

# get_src 7dc05df3d1824b02c6958ff37f9e682b73c1737dcfee93212ca3f6c5bfae08f3 \
#         "https://github.com/openresty/lua-nginx-module/archive/$LUA_NGX_VERSION.tar.gz"

# get_src 6fcf7054f412a19c23c1ac3c0663f42f40bccc907d98c5d1657ae5cab9973ee9 \
#         "https://github.com/openresty/stream-lua-nginx-module/archive/v$LUA_STREAM_NGX_VERSION.tar.gz"

# get_src 2a69815e4ae01aa8b170941a8e1a10b6f6a9aab699dee485d58f021dd933829a \
#         "https://github.com/openresty/lua-upstream-nginx-module/archive/v$LUA_UPSTREAM_VERSION.tar.gz"

get_src f74a0821b079ea1fd63dd8659064356fc3f421ff4b35c17877140d2b2841cc3b \
        "https://github.com/openresty/luajit2/archive/v$LUAJIT_VERSION.tar.gz"

# get_src 3e6fe45f467d653870985cc52a1c2cf81a8a2c7a7bcf7ffcfedfd305a47a1eca \
#         "https://github.com/DataDog/dd-opentracing-cpp/archive/v$DATADOG_CPP_VERSION.tar.gz"

# get_src 1af5a5632dc8b00ae103d51b7bf225de3a7f0df82f5c6a401996c080106e600e \
#         "https://github.com/influxdata/nginx-influxdb-module/archive/$NGINX_INFLUXDB_VERSION.tar.gz"

# get_src 41378438c833e313a18869d0c4a72704b4835c30acaf7fd68013ab6732ff78a7 \
#         "https://github.com/leev/ngx_http_geoip2_module/archive/$GEOIP2_VERSION.tar.gz"

# get_src 5f629a50ba22347c441421091da70fdc2ac14586619934534e5a0f8a1390a950 \
#         "https://github.com/yaoweibin/nginx_ajp_module/archive/$NGINX_AJP_VERSION.tar.gz"

# get_src 5d16e623d17d4f42cc64ea9cfb69ca960d313e12f5d828f785dd227cc483fcbd \
#         "https://github.com/openresty/lua-resty-upload/archive/v$LUA_RESTY_UPLOAD_VERSION.tar.gz"

# get_src bfd8c4b6c90aa9dcbe047ac798593a41a3f21edcb71904d50d8ac0e8c77d1132 \
#         "https://github.com/openresty/lua-resty-string/archive/v$LUA_RESTY_STRING_VERSION.tar.gz"

# get_src a21ec0d78a5dc5856df2374890a8a58e51de866b3d5978aceb0109a094367630 \
#         "https://github.com/openresty/lua-resty-balancer/archive/$LUA_RESTY_BALANCER.tar.gz"

# get_src a377fbce78ba10f3ed3a8b5173ea318f8cf8da9d2ab127bb1e1f263078bf7da0 \
#         "https://github.com/openresty/lua-resty-core/archive/v$LUA_RESTY_CORE.tar.gz"

# get_src bd6bee4ccc6cf3307ab6ca0eea693a921fab9b067ba40ae12a652636da588ff7 \
#         "https://github.com/openresty/lua-cjson/archive/$LUA_CJSON_VERSION.tar.gz"

# get_src f818b5cef0881e5987606f2acda0e491531a0cb0c126d8dca02e2343edf641ef \
#         "https://github.com/cloudflare/lua-resty-cookie/archive/$LUA_RESTY_COOKIE_VERSION.tar.gz"

# get_src dae9fb572f04e7df0dabc228f21cdd8bbfa1ff88e682e983ef558585bc899de0 \
#         "https://github.com/openresty/lua-resty-lrucache/archive/v$LUA_RESTY_CACHE.tar.gz"

# get_src 2b4683f9abe73e18ca00345c65010c9056777970907a311d6e1699f753141de2 \
#         "https://github.com/openresty/lua-resty-lock/archive/v$LUA_RESTY_LOCK.tar.gz"

# get_src 4aca34f324d543754968359672dcf5f856234574ee4da360ce02c778d244572a \
#         "https://github.com/openresty/lua-resty-dns/archive/v$LUA_RESTY_DNS.tar.gz"

# get_src 987d5754a366d3ccbf745d2765f82595dcff5b94ba6c755eeb6d310447996f32 \
#         "https://github.com/ledgetech/lua-resty-http/archive/v$LUA_RESTY_HTTP.tar.gz"

# get_src 8257e8fbf78eb2cc2cf2fdca2fda3c2e755f7d3222e7d15cc322111a0f720f9c \
#         "https://github.com/openresty/lua-resty-memcached/archive/v$LUA_RESTY_MEMCACHED_VERSION.tar.gz"

# get_src 3f602af507aacd1f7aaeddfe7b77627fcde095fe9f115cb9d6ad8de2a52520e1 \
#         "https://github.com/openresty/lua-resty-redis/archive/v$LUA_RESTY_REDIS_VERSION.tar.gz"

# get_src d0eacda122ab36585936256cb222ea9147bc5ad1fc3f24fd3748475653dd27ad \
#         "https://github.com/api7/lua-resty-ipmatcher/archive/$LUA_RESTY_IPMATCHER_VERSION.tar.gz"

# get_src 0fb790e394510e73fdba1492e576aaec0b8ee9ef08e3e821ce253a07719cf7ea \
#         "https://github.com/ElvinEfendi/lua-resty-global-throttle/archive/v$LUA_RESTY_GLOBAL_THROTTLE_VERSION.tar.gz"

# improve compilation times
CORES=$(($(grep -c ^processor /proc/cpuinfo) - 1))

if [[ $CORES==0 ]]; then
    CORES=1
fi

export MAKEFLAGS=-j${CORES}
export CTEST_BUILD_FLAGS=${MAKEFLAGS}
export HUNTER_JOBS_NUMBER=${CORES}
export HUNTER_USE_CACHE_SERVERS=true

# Install luajit from openresty fork
export LUAJIT_LIB=/usr/local/lib
export LUA_LIB_DIR="$LUAJIT_LIB/lua"
export LUAJIT_INC=/usr/local/include/luajit-2.1

cd "$BUILD_PATH/luajit2-$LUAJIT_VERSION"
make CCDEBUG=-g
make install

ln -s /usr/local/bin/luajit /usr/local/bin/lua

cd "$BUILD_PATH"

# Git tuning
git config --global --add core.compression -1

#
#
#

# build modsecurity library
cd "$BUILD_PATH"
git clone --depth=1 -b $MODSECURITY_LIB_VERSION https://github.com/SpiderLabs/ModSecurity
cd ModSecurity/
git submodule init
git submodule update

sh build.sh

# https://github.com/SpiderLabs/ModSecurity/issues/1909#issuecomment-465926762
#sed -i '115i LUA_CFLAGS="${LUA_CFLAGS} -DWITH_LUA_JIT_2_1"' build/lua.m4
#sed -i '117i AC_SUBST(LUA_CFLAGS)' build/lua.m4

./configure \
  --disable-doxygen-doc \
  --disable-doxygen-html \
  --disable-examples

make
make install

mkdir -p /etc/nginx/modsecurity
cp modsecurity.conf-recommended /etc/nginx/modsecurity/modsecurity.conf
cp unicode.mapping /etc/nginx/modsecurity/unicode.mapping

# sed -i 's|SecRuleEngine DetectionOnly|SecRuleEngine On|g' /etc/nginx/modsecurity/modsecurity.conf
# sed -i 's|SecAuditEngine RelevantOnly|SecAuditEngine On|g' /etc/nginx/modsecurity/modsecurity.conf

# Replace serial logging with concurrent
sed -i 's|SecAuditLogType Serial|SecAuditLogType Concurrent|g' /etc/nginx/modsecurity/modsecurity.conf

# Concurrent logging implies the log is stored in several files
echo "SecAuditLogStorageDir /var/log/audit/" >> /etc/nginx/modsecurity/modsecurity.conf

# Download owasp modsecurity crs
cd /etc/nginx/

git clone -b $OWASP_MODSECURITY_CRS_VERSION --depth 1 https://github.com/coreruleset/coreruleset
mv coreruleset owasp-modsecurity-crs
cd owasp-modsecurity-crs

mv crs-setup.conf.example crs-setup.conf
mv rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
mv rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
cd ..

# OWASP CRS v3 rules
echo "
Include /etc/nginx/owasp-modsecurity-crs/crs-setup.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-901-INITIALIZATION.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-903.9001-DRUPAL-EXCLUSION-RULES.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-903.9002-WORDPRESS-EXCLUSION-RULES.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-905-COMMON-EXCEPTIONS.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-910-IP-REPUTATION.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-911-METHOD-ENFORCEMENT.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-912-DOS-PROTECTION.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-913-SCANNER-DETECTION.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-921-PROTOCOL-ATTACK.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-930-APPLICATION-ATTACK-LFI.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-931-APPLICATION-ATTACK-RFI.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-932-APPLICATION-ATTACK-RCE.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-933-APPLICATION-ATTACK-PHP.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-934-APPLICATION-ATTACK-NODEJS.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-941-APPLICATION-ATTACK-XSS.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-942-APPLICATION-ATTACK-SQLI.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-944-APPLICATION-ATTACK-JAVA.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-949-BLOCKING-EVALUATION.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-950-DATA-LEAKAGES.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-951-DATA-LEAKAGES-SQL.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-952-DATA-LEAKAGES-JAVA.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-953-DATA-LEAKAGES-PHP.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-954-DATA-LEAKAGES-IIS.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-959-BLOCKING-EVALUATION.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-980-CORRELATION.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
" > /etc/nginx/owasp-modsecurity-crs/nginx-modsecurity.conf

# build nginx
cd "$BUILD_PATH/nginx-$NGINX_VERSION"

# apply nginx patches
#for PATCH in `ls /patches`;do
#  echo "Patch: $PATCH"
#  patch -p1 < /patches/$PATCH
#done

WITH_FLAGS="--with-debug \
  --with-compat \
  --with-pcre-jit \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_realip_module \
  --with-http_auth_request_module \
  --with-http_addition_module \
  --with-http_geoip_module \
  --with-http_gzip_static_module \
  --with-http_sub_module \
  --with-http_v2_module \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_realip_module \
  --with-stream_ssl_preread_module \
  --with-threads \
  --with-http_secure_link_module \
  --with-http_gunzip_module"

# "Combining -flto with -g is currently experimental and expected to produce unexpected results."
# https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
#CC_OPT="-g -Og -fPIE -fstack-protector-strong \
#  -Wformat \
#  -Werror=format-security \
#  -Wno-deprecated-declarations \
#  -fno-strict-aliasing \
#  -D_FORTIFY_SOURCE=2 \
#  --param=ssp-buffer-size=4 \
#  -DTCP_FASTOPEN=23 \
#  -fPIC \
#  -I$HUNTER_INSTALL_DIR/include \
#  -Wno-cast-function-type"
CC_OPT="-g -Og -fPIE -fstack-protector-strong \
  -Wformat \
  -Werror=format-security \
  -Wno-deprecated-declarations \
  -fno-strict-aliasing \
  -D_FORTIFY_SOURCE=2 \
  --param=ssp-buffer-size=4 \
  -DTCP_FASTOPEN=23 \
  -fPIC \
  -Wno-cast-function-type"

#LD_OPT="-fPIE -fPIC -pie -Wl,-z,relro -Wl,-z,now -L$HUNTER_INSTALL_DIR/lib"
LD_OPT="-fPIE -fPIC -pie -Wl,-z,relro -Wl,-z,now"

if [[ ${ARCH} != "aarch64" ]]; then
  WITH_FLAGS+=" --with-file-aio"
fi

if [[ ${ARCH} == "x86_64" ]]; then
  CC_OPT+=' -m64 -mtune=native'
fi

#WITH_MODULES=" \
#  --add-module=$BUILD_PATH/ngx_devel_kit-$NDK_VERSION \
#  --add-module=$BUILD_PATH/set-misc-nginx-module-$SETMISC_VERSION \
#  --add-module=$BUILD_PATH/headers-more-nginx-module-$MORE_HEADERS_VERSION \
#  --add-module=$BUILD_PATH/ngx_http_substitutions_filter_module-$NGINX_SUBSTITUTIONS \
#  --add-module=$BUILD_PATH/lua-nginx-module-$LUA_NGX_VERSION \
#  --add-module=$BUILD_PATH/stream-lua-nginx-module-$LUA_STREAM_NGX_VERSION \
#  --add-module=$BUILD_PATH/lua-upstream-nginx-module-$LUA_UPSTREAM_VERSION \
#  --add-module=$BUILD_PATH/nginx_ajp_module-${NGINX_AJP_VERSION} \
#  --add-dynamic-module=$BUILD_PATH/nginx-http-auth-digest-$NGINX_DIGEST_AUTH \
#  --add-dynamic-module=$BUILD_PATH/nginx-influxdb-module-$NGINX_INFLUXDB_VERSION \
#  --add-dynamic-module=$BUILD_PATH/nginx-opentracing-$NGINX_OPENTRACING_VERSION/opentracing \
#  --add-dynamic-module=$BUILD_PATH/ModSecurity-nginx-$MODSECURITY_VERSION \
#  --add-dynamic-module=$BUILD_PATH/ngx_http_geoip2_module-${GEOIP2_VERSION} \
#  --add-dynamic-module=$BUILD_PATH/ngx_brotli"
WITH_MODULES=" \
  --add-dynamic-module=$BUILD_PATH/ModSecurity-nginx-$MODSECURITY_VERSION"

./configure \
  --prefix=/usr/local/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --modules-path=/etc/nginx/modules \
  --http-log-path=/var/log/nginx/access.log \
  --error-log-path=/var/log/nginx/error.log \
  --lock-path=/var/lock/nginx.lock \
  --pid-path=/run/nginx.pid \
  --http-client-body-temp-path=/var/lib/nginx/body \
  --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
  --http-proxy-temp-path=/var/lib/nginx/proxy \
  --http-scgi-temp-path=/var/lib/nginx/scgi \
  --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
  ${WITH_FLAGS} \
  --without-mail_pop3_module \
  --without-mail_smtp_module \
  --without-mail_imap_module \
  --without-http_uwsgi_module \
  --without-http_scgi_module \
  --with-cc-opt="${CC_OPT}" \
  --with-ld-opt="${LD_OPT}" \
  --user=www-data \
  --group=www-data \
  ${WITH_MODULES}

make
make modules
make install

export LUA_INCLUDE_DIR=/usr/local/include/luajit-2.1
ln -s $LUA_INCLUDE_DIR /usr/include/lua5.1

# update image permissions
writeDirs=( \
  /etc/nginx \
  /usr/local/nginx \
  /opt/modsecurity/var/log \
  /opt/modsecurity/var/upload \
  /opt/modsecurity/var/audit \
  /var/log/audit \
  /var/log/nginx \
    /var/lib/nginx \
    /var/lib/nginx/body \
    /var/lib/nginx/fastcgi \
    /var/lib/nginx/proxy \
    /var/lib/nginx/scgi \
    /var/lib/nginx/uwsgi \
);

for dir in "${writeDirs[@]}"; do
  mkdir -p ${dir};
  chown -R www-data.www-data ${dir};
done

rm -rf /etc/nginx/owasp-modsecurity-crs/.git
# rm -rf /etc/nginx/owasp-modsecurity-crs/util/regression-tests

# remove .a files
find /usr/local -name "*.a" -print | xargs /bin/rm
