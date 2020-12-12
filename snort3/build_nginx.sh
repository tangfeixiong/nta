#!/bin/bash

# Inspired
# - https://github.com/kubernetes/ingress-nginx/blob/master/images/nginx/build.sh

set -o errexit
set -o nounset
set -o pipefail

export DAQ_VERSION=v3.0.0-beta2
export DNET_VERSION=libdnet-1.14
export GPERFTOOLS_VERSION=gperftools-2.8
export HWLOC_VERSION=hwloc-2.3.0
export LUAJIT_VERSION=v2.1-20201027
export OPENSSL_VERSION=OpenSSL_1_1_1h
export PCAP_VERSION=libpcap-1.9.1
export PCRE_VERSION=pcre2-10.35
export ZLIB_VERSION=v1.2.11
export SNORT_VERSION=3.0.3-5
export SNORT_RULES_SNAPSHOT=3000
export MODSECURITY_LIB_VERSION=v3.0.4
export OWASP_MODSECURITY_CRS_VERSION=v3.3.0

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

git_src() {
    url=$1
    branch=$2
    dirname=$3
    echo "Fetching ${url}"
    git clone --depth=1 -b $branch $url $dirname
}

init_builds()
{
  apt-get update
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
	git \
    `# netcat` \
    `# wget` \
	`# net-tools` \
	\
    autotools-dev \
	build-essential \
	cmake \
	dh-autoreconf \
	doxygen \
	g++ \
    libtool \
	\
	`# libdnet-dev` \
	libdumbnet-dev \
	`# libhwloc-dev` \
	`# libluajit-5.1-dev` \
	`# libpcap-dev` \
	`# libpcre3-dev` \
	libssl-dev \
	pkg-config \
	zlib1g-dev \
	\
	iptables-dev \
	libmnl-dev \
	libnetfilter-queue-dev \
	`# libnet1-dev` \
	`# libsqlite3-dev` \
	\
	bison \
	flex \
	libyajl-dev libgeoip-dev libcurl4-gnutls-dev libpcre++-dev libxml2-dev \
	`# python-setuptools` \
	`# python-pip` \
	`# python-dev`
}

### zlib === http://www.zlib.net/
build_zlib()
{
	local url="https://github.com/madler/zlib"
	local tgt="${BUILD_PATH}/zlib"
	local ver=${ZLIB_VERSION}
    
	git clone --depth 1 --branch ${ver} ${url} ${tgt}
	cd ${tgt}
	local tag=$(git describe --tags --abbrev=0)

	./configure
	make 
    make install
	make clean
	
    cd $BUILD_PATH
    rm -rf $tgt
	echo "
      $(basename ${tgt}) build completed
          version: ${ver}
          git source: ${url}
          git tag: ${tag}
"
}

### openssl === https://www.openssl.org/source/
build_openssl()
{
	local url="https://github.com/openssl/openssl"
	local tgt="${BUILD_PATH}/openssl"
	local ver=${OPENSSL_VERSION}
    
	git clone --branch ${ver} --depth 1 ${url} ${tgt}
	cd ${tgt}
	local tag=$(git describe --tags --abbrev=0)
	
	./Configure linux-x86_64
	make
    make install
	make clean
	
    cd $BUILD_PATH
    rm -rf $tgt
	echo "
      $(basename ${tgt}) build completed
          version: ${ver}
          git source: ${url}
          git tag: ${tag}
"
}

### pcre === http://www.pcre.org/
build_pcre()
{   
	local url="https://ftp.pcre.org/pub/pcre/${PCRE_VERSION}.tar.gz"
    local tgt="${BUILD_PATH}/pcre"
	local ver=${PCRE_VERSION}

	cd ${BUILD_PATH}
	local src=$(basename "$url")
	curl -SL ${url} -o ${src}
	url="https://ftp.pcre.org/pub/pcre/${PCRE_VERSION}.tar.gz.sig"
	local sig=$(basename "$url")
	curl -SL ${url} -o ${sig}
    
	curl -sSL https://ftp.pcre.org/pub/pcre/Public-Key | gpg --import -
	gpg --verify $sig $src
    mkdir -p $tgt
    tar -C $tgt --strip-components=1 -zxf $src
	cd ${tgt}
	
	./configure
	make
    make install
	make clean
	
    cd $BUILD_PATH
    rm -rf ${tgt} ${src} ${sig}
	echo "
      $(basename ${tgt}) build completed
		  version: ${ver}
"
}

### luajit === http://luajit.org/download.html
build_luajit()
{
	local url="https://github.com/openresty/luajit2"
	local tgt="${BUILD_PATH}/luajit2"
	local ver=${LUAJIT_VERSION}
    
	git clone --branch ${ver} --depth 1 ${url} ${tgt}
	cd ${tgt}
	local tag=$(git describe --tags --abbrev=0)
	
	make CCDEBUG=-g
    make install
	make clean
	ln -s /usr/local/bin/luajit /usr/local/bin/lua
	
    cd $BUILD_PATH
    rm -rf $tgt
	echo "
      $(basename ${tgt}) build completed
		  version: ${ver}
		  git source: ${url}
		  git tag: ${tag}
"
}

### ModeSecurity === https://github.com/SpiderLabs/ModSecurity/wiki/Compilation-recipes-for-v3.x#ubuntu-1504
build_libmodsecurity()
{
	local url="https://github.com/SpiderLabs/ModSecurity"
	local dest=${url#http*://}
	dest=${dest%.git}
	local tgt="${BUILD_PATH}/${dest}"
	local ver=${MODSECURITY_LIB_VERSION}
	git clone --depth=1 -b $MODSECURITY_LIB_VERSION ${url} ${tgt}
	cd ${tgt}
	tag=$(git describe --tags --abbrev=0)
	git submodule init
    git submodule update

    sh build.sh
    ./configure --disable-doxygen-doc --disable-doxygen-html \
	            --disable-examples
	make
    make install
	make clean
    
    mkdir -p /etc/nginx/modsecurity
    cp modsecurity.conf-recommended /etc/nginx/modsecurity/modsecurity.conf
    cp unicode.mapping /etc/nginx/modsecurity/unicode.mapping

    # Replace serial logging with concurrent
    sed -i 's|SecAuditLogType Serial|SecAuditLogType Concurrent|g' /etc/nginx/modsecurity/modsecurity.conf

    # Concurrent logging implies the log is stored in several files
    echo "SecAuditLogStorageDir /var/log/audit/" >> /etc/nginx/modsecurity/modsecurity.conf
	
    fetch_owasp_crs
    
    cd $BUILD_PATH
    rm -rf $tgt
	echo "
      $(basename ${tgt}) build completed
		  version: ${ver}
		  git source: ${url}
		  git tag: ${tag}
"
}

### OWASP ModSecurity Core Rule Set (CRS) === https://github.com/coreruleset/coreruleset
fetch_owasp_crs()
{
    cd /etc/nginx/
    # Download owasp modsecurity crs
    git clone -b $OWASP_MODSECURITY_CRS_VERSION https://github.com/coreruleset/coreruleset
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
}

### libpcap == https://www.tcpdump.org/index.html#latest-releases
build_libpcap()
{
	local url="https://github.com/the-tcpdump-group/libpcap"
	local tgt="${BUILD_PATH}/libpcap"
	local ver=${PCAP_VERSION}
    
	git clone --branch ${ver} --depth 1 ${url} ${tgt}
	cd ${tgt}
	tag=$(git describe --tags --abbrev=0)
	
	./configure
	make
    make install
	make clean
	
    cd $BUILD_PATH
    rm -rf $tgt
	echo "
      $(basename ${tgt}) build completed
		  version: ${ver}
		  git source: ${url}
		  git tag: ${tag}
"
}

### libdaq === https://github.com/snort3/libdaq
build_libdaq()
{
	local url="https://github.com/snort3/libdaq" 
	local tgt="${BUILD_PATH}/libdaq"
	local ver=${DAQ_VERSION}
    
    git clone --branch $ver --depth 1 $url $tgt
    cd $tgt
	tag=$(git describe --tags --abbrev=0)
	
    ./bootstrap
	./configure --with-libpcap-libraries=/usr/local/lib --with-libpcap-includes=/usr/local/include
	make
	make install
	make clean
    
    cd $BUILD_PATH
    rm -rf $tgt
	echo "
      $(basename $tgt) build completed
		  version: ${ver}
		  git source: ${url}
    	  git tag: ${tag}
"
}

### libdnet === https://github.com/ofalk/libdnet
build_libdnet()
{
	local url="https://github.com/ofalk/libdnet"
	local tgt="${BUILD_PATH}/libdnet"
	local ver=${DNET_VERSION}
    
	git clone --branch $ver --depth 1 $url $tgt
	cd $tgt
	tag=$(git describe --tags --abbrev=0)
	
	./configure
	make
	make install
	make clean
	
    cd $BUILD_PATH
    rm -rf $tgt    
	echo "
      $(basename $tgt) build completed
		  version: ${ver}
          git source: ${url}
    	  git tag: ${tag}
"
}

### hwloc === https://www.open-mpi.org/software/hwloc/v2.3/
build_hwloc()
{
	local url="https://github.com/open-mpi/hwloc"
	local tgt="${BUILD_PATH}/hwloc"
	local ver=${HWLOC_VERSION}
    
	git clone --branch ${ver} --depth 1 ${url} ${tgt}
	cd ${tgt}
	local tag=$(git describe --tags --abbrev=0)
	
	./autogen.sh
	./configure --prefix=/usr/local
	make
	make install
	make clean
	
    
    cd $BUILD_PATH
    rm -rf $tgt    
	echo "
      $(basename ${tgt}) build completed
		  version: ${ver}
		  git source: ${url}
		  git tag: ${tag}
"
}

build_snort3()
{
# This will break once Snort leaves beta because I've prepended the 
# downloaded file with the word -beta. 
    ldconfig 

    local MY_PATH=/usr/local/snort
 	# cp -f /tmp/libdnet/include/dnet/sctp.h /usr/local/include/dnet/
    
    local url="https://github.com/snort3/snort3"
	local dest=${url#http*://}
	dest=${dest%.git}
	local tgt="${BUILD_PATH}/${dest}"
	local ver=${SNORT_VERSION}
    
    git clone -b $ver --depth 1 $url $tgt
    cd $tgt
	local tag=$(git describe --tags --abbrev=0)
	
    ./configure_cmake.sh --prefix=${MY_PATH} --disable-docs
    cd build
    make -j $(nproc)
	make install
	make clean
    
    ldconfig

    mkdir -p /var/log/snort
    mkdir -p /usr/local/lib/snort_dynamicrules
    mkdir -p /etc/snort
    mkdir -p /etc/snort/rules
    mkdir -p /etc/snort/preproc_rules
	cp -r ${MY_PATH}/etc/snort /etc/

# For this to work you MUST have downloaded the snort3 subscribers ruleset.
# This has to be located in the directory we are currently in.

    # curl -SL https://www.snort.org/downloads/???/snortrules-snapshot-${SNORT_RULES_SNAPSHOT}.tar.gz | curl -C /opt --strip-components=1 -zxv
    # mkdir -p /etc/snort/etc
    # cp -r /opt/rules /etc/snort
    # cp -r /opt/preproc_rules /etc/snort
    # cp -r /opt/etc /etc/snort
    
    touch /etc/snort/rules/local.rules
    touch /etc/snort/rules/white_list.rules /etc/snort/rules/black_list.rules
	
    cd $BUILD_PATH
	local loc="https://www.snort.org/downloads/community/snort3-community-rules.tar.gz"
	local src=$(basename "$loc")
	curl -SL ${loc} -o ${src}    
    
	# local hash="b60ad5d3fd64c39a0ffd5ce7a289b2ae"
    # echo "$hash $src" | md5sum -c -   
    curl -sSL https://www.snort.org/downloads/community/md5s | grep $src | md5sum -c -
    
    dest="/etc/snort/snort3-community-rules"
    if [ ! -e "$dest" ]; then 
        mkdir -p ${dest}
    fi
    tar --directory=$dest --strip-components=1 -xzvf $src

    export LUA_PATH=${MY_PATH}/include/snort/lua/\?.lua\;\;
    export SNORT_LUA_PATH=${MY_PATH}/etc/snort

    # Validate an installation
    ${MY_PATH}/bin/snort -c /etc/snort/snort.lua -R /etc/snort/snort3-community-rules/snort3-community.rules
    
    rm -rf $tgt *.tar.gz
	echo "
      $(basename ${tgt}) build completed
		  version: ${ver}
		  git source: ${url}
		  git tag: ${tag}
"
}

clean_builds()
{
    apt-get clean

    # remove .a files
    find /usr/local -name "*.a" -print | xargs /bin/rm
}

if [ ! -e "$BUILD_PATH" ]; then
  mkdir --verbose -p "$BUILD_PATH"
fi

cd "$BUILD_PATH"

# improve compilation times
CORES=$(($(grep -c ^processor /proc/cpuinfo) - 0))

export MAKEFLAGS=-j${CORES}
export CTEST_BUILD_FLAGS=${MAKEFLAGS}
export HUNTER_JOBS_NUMBER=${CORES}
export HUNTER_USE_CACHE_SERVERS=true

cmds=${1-"all"}

case $cmds in
    init)
        init_builds
        ;;
    
    clean)
        clean_builds
        ;;
    
  pcre|pcre2)
    build_pcre
    ;;
    
  luajit|luajit2)
    
    # Install luajit from openresty fork
    export LUAJIT_LIB=/usr/local/lib
    export LUA_LIB_DIR="$LUAJIT_LIB/lua"
    export LUAJIT_INC=/usr/local/include/luajit-2.1

    build_luajit
    ;;
    
  pcap|libpcap)
    build_libpcap
    ;;
    
  daq|libdaq)
    build_libdaq
    ;;
    
  dnet|libdnet)
    build_libdnet
    ;;

  hwloc)
    build_hwloc
    ;;

  snort3|snort)
    build_snort3
    ;;

  all)
    init_builds
    
    build_pcre
    
    # Install luajit from openresty fork
    export LUAJIT_LIB=/usr/local/lib
    export LUA_LIB_DIR="$LUAJIT_LIB/lua"
    export LUAJIT_INC=/usr/local/include/luajit-2.1
    
    build_luajit
    
    build_libpcap
    
    build_libdaq
    
    build_libdnet
    
    build_hwloc
    
    build_snort3
    
    clean_builds
    ;;

  *)
    echo "Execute: $(basename $0) <command>
        Commands: pcre, luajit, pcap, daq, dnet, hwloc, snort3
    " >> /dev/stderr
    ;;
esac


