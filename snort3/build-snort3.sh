#!/bin/bash

# Inspired
# - https://github.com/kubernetes/ingress-nginx/blob/master/images/nginx/build.sh

set -o errexit
set -o nounset
set -o pipefail

export DAQ_VERSION=v3.0.0-beta2
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

export SNORT_VERSION=3.0.3-5
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

    # local MY_PATH=/usr/local/snort
 	# cp -f /tmp/libdnet/include/dnet/sctp.h /usr/local/include/dnet/
    
    local url="https://github.com/snort3/snort3"
	local tgt=${url#http*://}
	tgt=${tgt%.git}
	local src="${BUILD_PATH}/${tgt}"
	local ver=${SNORT_VERSION}
    
    git clone -b $ver --depth 1 $url $src
    cd $src
	local tag=$(git describe --tags --abbrev=0)
	
    # ./configure_cmake.sh --prefix=${MY_PATH} --disable-docs
    ./configure_cmake.sh --prefix=${MY_PATH} --disable-docs --enable-tcmalloc
    cd build
    make -j $(nproc)
	make install
    # config_snort3
	
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

fetch_snort3_community_rules()
{
	echo "Downloading snort3 community rules..."
	
	local url="https://www.snort.org/downloads/community/snort3-community-rules.tar.gz"
	local src=$(basename "$url")

    cd $BUILD_PATH

	curl -SL ${url} -o ${src}    
    # local hash="b60ad5d3fd64c39a0ffd5ce7a289b2ae"
    # echo "$hash $src" | md5sum -c -   
    curl -sSL https://www.snort.org/downloads/community/md5s | grep $src | md5sum -c -
    
    dest=${1-"/usr/local/etc/snort3-community-rules"}
    if [ ! -e "$dest" ]; then 
        mkdir -p ${dest}
    fi
    tar --directory=$dest --strip-components=1 -xzvf $src
	rm -f *.tar.gz
}

create_validation_rules()
{
    d=${1-"/usr/local/etc/rules"}
	mkdir -p $d
	cd $d
	local f="local.rules"
	touch $f

    echo '
# Reference https://www.snort.org/documents/snort-3-on-ubuntu-18-19#Installing+OpenAppID

# alert tcp any any -> any any ( msg:"Facebook Detected"; appids:"Facebook";sid:10000001; )

alert icmp any any -> any any (msg:"ICMP Traffic Detected";sid:10000002;)	
' >> ${f}
}

config_snort3()
(
    ldconfig

    mkdir -p /var/log/snort

# For this to work you MUST have downloaded the snort3 subscribers ruleset.
# This has to be located in the directory we are currently in.

    # curl -SL https://www.snort.org/downloads/???/snortrules-snapshot-${SNORT_RULES_SNAPSHOT}.tar.gz | curl -C /opt --strip-components=1 -zxv
    # mkdir -p /etc/snort
    # mkdir -p /etc/snort/etc
    # mkdir -p /etc/snort/rules
    # mkdir -p /usr/local/lib/snort_dynamicrules
    # mkdir -p /etc/snort/preproc_rules
    # cp -r /opt/rules /etc/snort
    # cp -r /opt/preproc_rules /etc/snort
    # cp -r /opt/etc /etc/snort

	cp -r ${MY_PATH}/etc/snort /usr/local/etc/
	# Reference https://www.snort.org/documents/snort-3-on-ubuntu-18-19#Installing+Snort+Rulesets
    mkdir -p /usr/local/etc/rules
	mkdir -p /usr/local/etc/builtin_rules
	mkdir -p /usr/local/etc/so_rules
	mkdir -p /usr/local/etc/lists
    
    touch /usr/local/etc/rules/local.rules
    touch /usr/local/etc/lists/white_list.rules /usr/local/etc/lists/black_list.rules

    export LUA_PATH=${MY_PATH}/include/snort/lua/\?.lua\;\;
    export SNORT_LUA_PATH=${MY_PATH}/etc/snort

    fetch_snort3_community_rules /usr/local/etc/snort3-community-rules
	create_validation_rules /usr/local/etc/rules
    
    # Validate an installation
    if [ -f "/usr/local/etc/snort3-community-rules/snort3-community.rules" ]; then
        ${MY_PATH}/bin/snort -c /usr/local/etc/snort/snort.lua -R /usr/local/etc/snort3-community-rules/snort3-community.rules
    elif [ -d "/usr/local/etc/rules" ]; then
        ${MY_PATH}/bin/snort -c /usr/local/etc/snort/snort.lua --rule-path /usr/local/etc/rules --warn-all
    else 
	    ${MY_PATH}/bin/snort -c /usr/local/etc/snort/snort.lua
    fi
)

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

export MY_PATH=/usr/local/snort

cmds=${1-"help"}

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


