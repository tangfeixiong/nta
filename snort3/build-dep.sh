#!/bin/bash

# Inspired
# - https://github.com/kubernetes/ingress-nginx/blob/master/images/nginx/build.sh

set -o errexit
set -o nounset
set -o pipefail

export DAQ_VERSION=v3.0.0
export DNET_VERSION=libdnet-1.14
export HWLOC_VERSION=hwloc-2.3.0
export LUAJIT_VERSION=v2.1-20201027
export OPENSSL_VERSION=OpenSSL_1_1_1h
export PCAP_VERSION=libpcap-1.9.1
# Snort3 aren’t using pcre2 because hyperscan isn’t compatable with that version
export PCRE_VERSION=pcre-8.44
export ZLIB_VERSION=v1.2.11
### Optional
export SAFECLIB_VERSION=v02092020
export GPERFTOOLS_VERSION=gperftools-2.8
export RAGEL_VERSION=ragel-7.0.1
export BOOST_VERSION=boost_1_74_0
export HYPERSCAN_VERSION=v5.3.0
export FLATBUFFERS_VERSION=v1.12.0

export SNORT_VERSION=3.1.0.0
export SNORT_RULES_SNAPSHOT=3000

### Nginx and ModSecurity
export NGINX_VERSION=1.19.4
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

# Usage: <fn> <url> <branch or tag>
git_src() {
    local url=$1
    local branch=${2:-"master"}
	local dest=${url#http*://}
	dest=${dest%.git}    
	local src="${BUILD_PATH}/${dest}"

    echo "Fetching ${url}"
    git clone --depth 1 --branch $branch $url $src
	echo $src
}

# Usage: <fn> <url> <branch or tag>
build_with_git()
{
    local url=$1
	local ver=${2:-"master"}

	local dest=${url#http*://}
	dest=${dest%.git}    
	local src="${BUILD_PATH}/${dest}"
    
    git clone --depth=1 -b $ver ${url} ${src}

	cd ${src}
	local tag=$(git describe --tags --abbrev=0)
    
	if [! -e "configure"]; then
	    if [ -e "authgen.sh" ]; then 
			./autogen.sh
        fi
	fi
    ./configure
    make
    make install
    
    make clean
    cd $BUILD_PATH
    rm -rf $src
    
	echo "
	  $(basename $url) build completed
		source: ${src} 
		version: ${ver}
		git url: ${url}
		git tag: ${tag}
"    
}


init_builds()
{
  apt-get update
  apt-get autoclean
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
	asciidoc \
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
	liblzma-dev \
	libmnl-dev \
	libnetfilter-queue-dev \
	`# libnet1-dev` \
	libsqlite3-dev \
    libunwind-dev \
    uuid-dev \
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
	echo "To build Zlib..."
	
	local url="https://github.com/madler/zlib"
	local src="${BUILD_PATH}/zlib"
	local ver=${ZLIB_VERSION}
    
	git clone --depth 1 --branch ${ver} ${url} ${src}

	cd ${src}
	local tag=$(git describe --tags --abbrev=0)

	./configure
	make 
    make install

	make clean	
    cd $BUILD_PATH
    rm -rf $src

	echo "
      $(basename ${url}) build completed
	    source: ${src}
        version: ${ver}
        git url: ${url}
        git tag: ${tag}
"
}

### openssl === https://www.openssl.org/source/
build_openssl()
{
	echo "To build OpenSSL..."
	
	local url="https://github.com/openssl/openssl"
	local src="${BUILD_PATH}/openssl"
	local ver=${OPENSSL_VERSION}
    
	git clone --branch ${ver} --depth 1 ${url} ${src}

	cd ${src}
	local tag=$(git describe --tags --abbrev=0)
	
	./Configure linux-x86_64
	make
    make install

	make clean	
    cd $BUILD_PATH
    rm -rf $src

	echo "
      $(basename ${url}) build completed
	    source: ${src}
        version: ${ver}
        git url: ${url}
        git tag: ${tag}
"
}

# libsafec
build_safeclib()
{
	echo "To build Safeclib..."
	
	local url="https://github.com/rurban/safeclib"
	local dest=${url#http*://}
	dest=${dest%.git}
	local src="${BUILD_PATH}/${dest}"
	local ver=${SAFECLIB_VERSION}
    
	# src=$(git_src "https://github.com/rurban/safeclib" $SAFECLIB_VERSION)
	git clone --branch ${ver} --depth 1 ${url} ${src}

	cd ${src}
	local tag=$(git describe --tags --abbrev=0)

    ./build-aux/autogen.sh
	./configure --disable-doc
	make
	make install

	make clean
    cd $BUILD_PATH
    rm -rf $src

	echo "
      $(basename ${url}) build completed
		source: ${src}
		version: ${ver}
		git url: ${url}
		git tag: ${tag}
"
}

### pcre === http://www.pcre.org/
build_pcre()
{   
	echo "To build PCRE..."
	
	local url="https://ftp.pcre.org/pub/pcre/${PCRE_VERSION}.tar.gz"
	local far=$(basename "$url")
    local src="${BUILD_PATH}/pcre"
	local ver=${PCRE_VERSION}

	cd ${BUILD_PATH}
	curl -SL ${url} -o ${far}

	local tgt="https://ftp.pcre.org/pub/pcre/${PCRE_VERSION}.tar.gz.sig"
	local sig=$(basename "$tgt")
	curl -SL ${tgt} -o ${sig}    
	curl -sSL https://ftp.pcre.org/pub/pcre/Public-Key | gpg --import -
	gpg --verify $sig $far
    
    mkdir -p $src
    tar -C $src --strip-components=1 -zxf $far
	cd ${src}
	
	./configure --enable-pcre16 --enable-pcre32 --enable-jit --enable-utf8 --enable-unicode-properties 
	make
    make install

	make clean	
    cd $BUILD_PATH
    rm -rf ${src} ${far} ${sig}
	
	echo "
      $(basename ${url} ".tar.gz") build completed
		source: ${src}
		version: ${ver}
		url: ${url}
"
}

build_gperftools()
{
	echo "To build Gperftools..."
	
	local url="https://github.com/gperftools/gperftools"
	local dest=${url#http*://}
	dest=${dest%.git}
	local src="${BUILD_PATH}/${dest}"
	local ver=${GPERFTOOLS_VERSION}
    
	# src=$(git_src $url $SAFECLIB_VERSION)
	git clone --branch ${ver} --depth 1 ${url} ${src}

	cd ${src}
	local tag=$(git describe --tags --abbrev=0)

    ./autogen.sh
	./configure
	make
	make install

	make clean
    cd $BUILD_PATH
    rm -rf $src

	echo "
      $(basename ${url}) build completed
		source: ${src}
		version: ${ver}
		git url: ${url}
		git tag: ${tag}
"
}

# colm
# - http://www.colm.net/open-source/colm/
# - https://github.com/adrian-thurston/colm
build_colm()
{
	echo "To build Colm..."
	
	local ver="colm-0.14.2"
    local url="http://www.colm.net/files/colm/${ver}.tar.gz"
	local far=$(basename "$url")
    local src="${BUILD_PATH}/colm"

	cd ${BUILD_PATH}
	curl -SL ${url} -o ${far}
	
	local tgt="http://www.colm.net/files/colm/${ver}.tar.gz.asc"
	local sig=$(basename "$tgt")
	curl -SL ${tgt} -o ${sig}
	curl -sSL http://www.colm.net/files/thurston.asc | gpg --import -
	gpg --verify $sig $far
    
    mkdir -p $src
    tar -C $src --strip-components=1 -zxf $far
	cd ${src}
	
	./configure --disable-debug --disable-manual
	make
    make install
	
	ldconfig
	
	make clean
    cd $BUILD_PATH
    rm -rf ${src} ${far} ${sig}

	echo "
      $(basename $url ".tar.gz") build completed
		source: ${src}
		version: ${ver}
		url: ${url}
"	
}

# ragel
# - http://www.colm.net/open-source/ragel/
# - https://github.com/adrian-thurston/ragel
build_ragel()
{
    build_colm
	
	echo "To build Ragel..."
	
	local ver=${RAGEL_VERSION}
    local url="http://www.colm.net/files/ragel/ragel-7.0.1.tar.gz"
	local far=$(basename "$url")
    local src="${BUILD_PATH}/ragel"

	cd ${BUILD_PATH}
	curl -SL ${url} -o ${far}
	
	local tgt="http://www.colm.net/files/ragel/ragel-7.0.1.tar.gz.asc"
	local sig=$(basename "$tgt")
	curl -SL ${tgt} -o ${sig}
	curl -sSL http://www.colm.net/files/thurston.asc | gpg --import -
	gpg --verify $sig $far
    
    mkdir -p $src
    tar -C $src --strip-components=1 -zxf $far
	cd ${src}
	
	./configure --disable-debug --disable-manual --with-colm=/usr/local/
	make
    make install
	
	ldconfig
	
	make clean
    cd $BUILD_PATH
    rm -rf ${src} ${far} ${sig}

	echo "
      $(basename $url ".tar.gz") build completed
		source: ${src}
		version: ${ver}
		url: ${url}
"
}

fetch_boost()
{
	local url="https://dl.bintray.com/boostorg/release/1.74.0/source/boost_1_74_0.tar.gz"
	local far=$(basename $url)
	local src="$BUILD_PATH/boost"
	local hash="afff36d392885120bcac079148c177d1f6f7730ec3d47233aa51b0afa4db94a5"

	cd ${BUILD_PATH}
	curl -SL ${url} -o ${far}
    echo "$hash $far" | sha256sum -c -   
	
	mkdir $src
	tar -C $src --strip-components=1 -zxf $far
	
	rm -f $far
	
	echo "$src"
}

# hyperscan
# - http://intel.github.io/hyperscan/dev-reference/getting_started.html#very-quick-start
build_hyperscan()
{
	echo "To build Hyperscan..."
	
	local url="https://github.com/intel/hyperscan"
	local dest=${url#http*://}
	dest=${dest%.git}
	local src="${BUILD_PATH}/${dest}"
	local ver=${HYPERSCAN_VERSION}
    
	git clone --branch ${ver} --depth 1 ${url} ${src}

	cd ${src}
	local tag=$(git describe --tags --abbrev=0)
	
	tgt=$(fetch_boost)
	echo "Download boost into $tgt"
	
	mkdir build
	cd build
	cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBOOST_ROOT=${BUILD_PATH}/boost/ ${src}
	
	make
    make install

	make clean	
    cd $BUILD_PATH
    rm -rf $src, ${BUILD_PATH}/boost
	
	echo "
      $(basename $url) build completed
		source: ${src}
		version: ${ver}
		git url: ${url}
		git tag: ${tag}
"
}

build_hyperscan_with_deps()
{
	build_safeclib
	build_pcre
	build_gperftools
	build_ragel
	# build_libpcap
	build_hyperscan
}

### luajit === http://luajit.org/download.html
build_luajit()
{
	echo "To build Luajit..."
	
    # Install luajit from openresty fork
    export LUAJIT_LIB=/usr/local/lib
    export LUA_LIB_DIR="$LUAJIT_LIB/lua"
    export LUAJIT_INC=/usr/local/include/luajit-2.1
	
	local url="https://github.com/openresty/luajit2"
	local dest=${url#http*://}
	dest=${dest%.git}
	local src="${BUILD_PATH}/luajit2"
	local ver=${LUAJIT_VERSION}
    
	git clone --branch ${ver} --depth 1 ${url} ${src}

	cd ${src}
	local tag=$(git describe --tags --abbrev=0)
	
	make CCDEBUG=-g
    make install
	ln -s /usr/local/bin/luajit /usr/local/bin/lua
	
	make clean
    cd $BUILD_PATH
    rm -rf $src

	echo "
      $(basename ${url}) build completed
		source: ${src}
		version: ${ver}
		git url: ${url}
		git tag: ${tag}
"
}


### ModeSecurity === https://github.com/SpiderLabs/ModSecurity/wiki/Compilation-recipes-for-v3.x#ubuntu-1504
build_libmodsecurity()
{
	echo "To build ModSecurity..."
	
	local url="https://github.com/SpiderLabs/ModSecurity"
	local dest=${url#http*://}
	dest=${dest%.git}
	local src="${BUILD_PATH}/${dest}"
	local ver=${MODSECURITY_LIB_VERSION}

	git clone --depth=1 -b $MODSECURITY_LIB_VERSION ${url} ${src}

	cd ${src}
	local tag=$(git describe --tags --abbrev=0)
	git submodule init
    git submodule update

    sh build.sh
    ./configure --disable-doxygen-doc --disable-doxygen-html \
	            --disable-examples
	make
    make install
    
    mkdir -p /etc/nginx/modsecurity
    cp modsecurity.conf-recommended /etc/nginx/modsecurity/modsecurity.conf
    cp unicode.mapping /etc/nginx/modsecurity/unicode.mapping

    # Replace serial logging with concurrent
    sed -i 's|SecAuditLogType Serial|SecAuditLogType Concurrent|g' /etc/nginx/modsecurity/modsecurity.conf

    # Concurrent logging implies the log is stored in several files
    echo "SecAuditLogStorageDir /var/log/audit/" >> /etc/nginx/modsecurity/modsecurity.conf
	
    fetch_owasp_crs

	make clean
    cd $BUILD_PATH
    rm -rf $src
    
	echo "
      $(basename ${url}) build completed
	    source: ${src}
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
	echo "To build libpcap..."
	
	local url="https://github.com/the-tcpdump-group/libpcap"
	local src="${BUILD_PATH}/libpcap"
	local ver=${PCAP_VERSION}
    
	git clone --branch ${ver} --depth 1 ${url} ${src}

	cd ${src}
	tag=$(git describe --tags --abbrev=0)
	
	./configure
	make
    make install

	make clean	
    cd $BUILD_PATH
    rm -rf $src

	echo "
      $(basename ${url}) build completed
		source: ${src}
		version: ${ver}
		git source: ${url}
		git tag: ${tag}
"
}

### libdnet === https://github.com/ofalk/libdnet
build_libdnet()
{
	echo "To build libdnet..."
	
	local url="https://github.com/ofalk/libdnet"
	local src="${BUILD_PATH}/libdnet"
	local ver=${DNET_VERSION}
    
	git clone --branch $ver --depth 1 $url $src

	cd $src
	tag=$(git describe --tags --abbrev=0)
	
	./configure
	make
	make install

	make clean	
    cd $BUILD_PATH
    rm -rf $src    

	echo "
      $(basename $url) build completed
		source: ${src}
		version: ${ver}
		git source: ${url}
		git tag: ${tag}
"
}

### hwloc === https://www.open-mpi.org/software/hwloc/v2.3/
build_hwloc()
{
	echo "To build hwloc..."
	
	local url="https://github.com/open-mpi/hwloc"
	local src="${BUILD_PATH}/hwloc"
	local ver=${HWLOC_VERSION}
    
	git clone --branch ${ver} --depth 1 ${url} ${src}

	cd ${src}
	local tag=$(git describe --tags --abbrev=0)
	
	./autogen.sh
	./configure --prefix=/usr/local --disable-doxygen
	make
	make install

	make clean    
    cd $BUILD_PATH
    rm -rf $src    

	echo "
      $(basename ${url}) build completed
		source: ${src}
		version: ${ver}
		git url: ${url}
		git tag: ${tag}
"
}

# flatbuffers
# - https://google.github.io/flatbuffers/flatbuffers_guide_building.html
build_flatbuffers()
{
	echo "To build flatbuffers..."
	
	local url="https://github.com/google/flatbuffers"
	local dest=${url#http*://}
	dest=${dest%.git}
	local src="${BUILD_PATH}/${dest}"
	local ver=${FLATBUFFERS_VERSION}
    
	git clone --branch ${ver} --depth 1 ${url} ${src}
	
	cd ${src}
	local tag=$(git describe --tags --abbrev=0)
	
	mkdir build
	cd build
	cmake ${src}	
	make
    make install
	
	make clean
    cd $BUILD_PATH
    rm -rf $src
	
	echo "
      $(basename $url) build completed
		source: ${src}
		version: ${ver}
		git url: ${url}
		git tag: ${tag}
"
}

### libdaq === https://github.com/snort3/libdaq
build_libdaq()
{
	echo "To build libdaq..."
	
	local url="https://github.com/snort3/libdaq" 
	local src="${BUILD_PATH}/libdaq"
	local ver=${DAQ_VERSION}
    
    git clone --branch $ver --depth 1 $url $src
	
    cd $src
	tag=$(git describe --tags --abbrev=0)
	
    ./bootstrap
	./configure --with-libpcap-libraries=/usr/local/lib --with-libpcap-includes=/usr/local/include
	make
	make install

# This will break once Snort leaves beta because I've prepended the 
# downloaded file with the word -beta. 
    ldconfig 

	make clean    
    cd $BUILD_PATH
    rm -rf $src

	echo "
      $(basename $url) build completed
		source: ${src}
		version: ${ver}
		git url: ${url}
		git tag: ${tag}
"
}

build_snort2()
{
	build_libpcap
	build_libdnet
	build_hwloc
	build_libdaq
	build_luajit
}

build_deps_and_opts_with_hyperscan()
{
	build_luajit
	build_libpcap
    build_hyperscan_with_deps		
	build_libdnet
	build_hwloc
	build_flatbuffers	
	build_libdaq
}

build_snort3()
{
    ldconfig

	echo "To build Snort3..."
	
    local MY_PATH=/usr/local/snort
 	# cp -f /tmp/libdnet/include/dnet/sctp.h /usr/local/include/dnet/
    
    local url="https://github.com/snort3/snort3"
	local dest=${url#http*://}
	dest=${dest%.git}
	local src="${BUILD_PATH}/${dest}"
	local ver=${SNORT_VERSION}
    
    git clone -b $ver --depth 1 $url $src

    cd $src
	local tag=$(git describe --tags --abbrev=0)
	
    ./configure_cmake.sh --prefix=${MY_PATH} --disable-docs --enable-tcmalloc
    cd build
    make -j $(nproc)
	make install

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

    export LUA_PATH=${MY_PATH}/include/snort/lua/\?.lua\;\;
    export SNORT_LUA_PATH=${MY_PATH}/etc/snort

    fetch_snort3_community_rules
    
    # Validate an installation
    if [ -e "/etc/snort/snort3-community-rules/snort3-community.rules" ]; then
        ${MY_PATH}/bin/snort -c /etc/snort/snort.lua -R /etc/snort/snort3-community-rules/snort3-community.rules
    else
        ${MY_PATH}/bin/snort -c /etc/snort/snort.lua --warn-all
    fi
    
	make clean
    cd $BUILD_PATH
    rm -rf $src *.tar.gz

	echo "
      $(basename ${url}) build completed
	    source: ${src}
		version: ${ver}
		git source: ${url}
		git tag: ${tag}
"
}

fetch_snort3_community_rules()
{
	local url="https://www.snort.org/downloads/community/snort3-community-rules.tar.gz"
	local src=$(basename "$url")

    cd $BUILD_PATH

	curl -SL ${url} -o ${src}    
    # local hash="b60ad5d3fd64c39a0ffd5ce7a289b2ae"
    # echo "$hash $src" | md5sum -c -   
    curl -sSL https://www.snort.org/downloads/community/md5s | grep $src | md5sum -c -
    tar xzvf $src
    
    dest="/etc/snort/snort3-community-rules"
    if [ ! -e "$dest" ]; then 
        mkdir -p ${dest}
    fi
    # tar --directory=$dest --strip-components=1 -xzvf $src
    mv snort3-community-rules/snort3-community.rules $dest 
}

clean_builds()
{
    apt-get clean
    rm -rf /var/lib/apt/lists/*
	
    # remove .a files
    find /usr/local -name "*.a" -print | xargs /bin/rm
}

if [ ! -d "$BUILD_PATH" ]; then
  mkdir --verbose -p "$BUILD_PATH"
fi

cd "$BUILD_PATH"

# improve compilation times
CORES=$(($(grep -c ^processor /proc/cpuinfo) - 0))

export MAKEFLAGS=-j${CORES}
export CTEST_BUILD_FLAGS=${MAKEFLAGS}
export HUNTER_JOBS_NUMBER=${CORES}
export HUNTER_USE_CACHE_SERVERS=true

cmds=${1-"help"}

case $cmds in
    init)
	    init_builds
	    ;;
    clean)
	    clean_builds
	    ;;
		
    deps-and-opts-with-hyperscan)
		build_deps_and_opts_with_hyperscan
		;;

    snort3|snort)
        build_snort3
        ;;

    all)
	    init_builds
	    
	    build_deps_and_opts_with_hyperscan
	    
	    build_snort3
	    
	    clean_builds
	    ;;
		
    luajit2|luajit) build_luajit;;
	safeclib) build_safeclib;;
	pcre) build_pcre;;
	gperftools) build_gperftools;;
	ragel) build_ragel;;
	libpcap) build_libpcap;;
	hyperscan) build_hyperscan;;
	libdnet) build_libdnet;;
	hwloc) build_hwloc;;
    flatbuffers) build_flatbuffers;;	
	libdaq) build_libdaq;;

  *)
    echo "Execute: $(basename $0) <command>
      Commands: deps-and-opts-with-hyperscan, snort3, all
" >> /dev/stderr
	exit 1
    ;;
esac
