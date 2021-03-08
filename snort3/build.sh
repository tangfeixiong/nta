#!/bin/bash

# Inspired
# - https://github.com/kubernetes/ingress-nginx/blob/master/images/nginx/build.sh

set -o errexit
set -o nounset
set -o pipefail

export SAFECLIB_VERSION=02092020
# v08112019 v31082020
SAFECLIB_GIT_TAG=v02092020
# Snort3 aren’t using pcre2 because hyperscan isn’t compatable with that version
export PCRE_VERSION=pcre-8.44
export GPERFTOOLS_VERSION=2.8.1
# 2.8
GPERFTOOLS_GIT_TAG=gperftools-2.8.1
export FLATBUFFERS_VERSION=v1.12.0
FLATBUFFERS_GIT_TAG=v1.12.0
export COLM_VERSION=colm-0.14.7
# 0.14.2
COLM_GIT_TAG=0.14.7
export RAGEL_VERSION=ragel-7.0.4
# 7.0.1
RAGEL_GIT_TAG=7.0.4
export BOOST_VERSION=1.75.0
# 1.74.0    afff36d392885120bcac079148c177d1f6f7730ec3d47233aa51b0afa4db94a5
BOOST_HASH="aeb26f80e80945e82ee93e5939baebdca47b9dee80a07d3144be1e1a6a66dd6a"
export HYPERSCAN_VERSION=v5.4.0
# v5.3.0
HYPERSCAN_GIT_TAG=v5.4.0
export DAQ_VERSION=v3.0.0
# v3.0.0-beta2
DAQ_GIT_TAG=v3.0.0
export SNORT_VERSION=3.1.1.0
# 3.0.3-4 3.0.3-5 3.1.0.0
SNORT_GIT_TAG=3.1.1.0
export SNORT_RULES_SNAPSHOT=3000

### Optional
export DNET_VERSION=libdnet-1.14
export HWLOC_VERSION=hwloc-2.3.0
export LUAJIT_VERSION=v2.1-20201027
export PCAP_VERSION=libpcap-1.9.1
export OPENSSL_VERSION=OpenSSL_1_1_1h
export ZLIB_VERSION=v1.2.11

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

init_builds()
{
	while (( "$#" )); do 
	    case "$1" in 
		--apt-mirror | --apt-repository )
			if [[ "$#" > 1 ]]; then
			    sed -i "s%http://archive.ubuntu.com/%$2%g" /etc/apt/sources.list
				shift
			else 
			    echo "The mirror or repository of APT-GET must specified!"
				exit 11
			fi
			;;
		* )
		    echo "Unknown init options: $1"
			;;
		esac
		shift
	done
	
  apt-get update
  apt-get install -y --no-install-recommends \
	apt-transport-https git gnupg \
    curl ca-certificates \
    \
    `# ethtool netcat tcpdump` \
	`# iproute2 net-tools` \
    `# bridge-utils ifupdown wget` \
	\
	`# libdnet-dev` \
	`# libnet1-dev` \
	`# libpcre3-dev` \
	iptables-dev \
	libdumbnet-dev \
	libhwloc-dev \
	libluajit-5.1-dev \
	liblzma-dev \
	libmnl-dev libnetfilter-queue-dev \
	libpcap-dev \
	libsqlite3-dev \
	libssl-dev \
    libunwind-dev \
    uuid-dev \
	zlib1g-dev \
	\
	bison flex \
	libyajl-dev libgeoip-dev libcurl4-gnutls-dev libpcre++-dev libxml2-dev \
	`# python-setuptools python-pip` \
	`# python-dev` \
	\
    autotools-dev \
	build-essential \
	cmake \
	dh-autoreconf \
	g++ \
    libtool \
	pkg-config \
	asciidoc dblatex source-highlight w3m \
	doxygen \
	\
	iptables tcpdump ethtool iputils-ping iproute2 vim
}

clean_builds()
{
    apt-get clean
	#rm -rf /var/lib/apt/lists/*
	
    #rm -rf $BUILD_PATH

    # remove .a files
    find /usr/local -name "*.a" -print | xargs /bin/rm
}

build_safeclib()
{
	local url="https://github.com/rurban/safeclib"
	#url="https://github.com/rurban/safeclib/releases/download/v02092020/libsafec-02092020.tar.gz"
	local tgt=${url#http*://}
	tgt=${tgt%.git}
	local src="${BUILD_PATH}/${tgt}"
	local ver=${SAFECLIB_GIT_TAG}

    cd $BUILD_PATH
    if [[ -d "$src" ]]; then  rm -rf $src; fi	

	#get_src fd8ae46814c8eeb401de1ac63423b213e34daa9c7a1bad64d1bf04c037cfc02f $url
	git clone --depth=1 -b $ver $url $src
	cd ${src}
	echo "$src tag=$(git describe --tags --abbrev=0)"

    ./build-aux/autogen.sh
	./configure --disable-doc
	make
	make install
	make clean
}

### pcre === http://www.pcre.org/
build_pcre()
{   
    cd ${BUILD_PATH}
	
    local url="https://ftp.pcre.org/pub/pcre/Public-Key"
	curl -sSL ${url} | gpg --import -

	url="https://ftp.pcre.org/pub/pcre/${PCRE_VERSION}.tar.gz.sig"
	local sig=$(basename "$url")
	curl -SL ${url} -o ${sig}

	local url="https://ftp.pcre.org/pub/pcre/${PCRE_VERSION}.tar.gz"
    local tgt=${url#http*://}
	local src="${BUILD_PATH}/$(dirname $tgt)/${PCRE_VERSION}"
	local ver=${PCRE_VERSION}

	mkdir -p $src
    tgt=$(basename $tgt)
	curl -SL ${url} -o $tgt
	gpg --verify $sig $tgt
    tar -C $src --strip-components=1 -zxf $tgt
    rm -rf ${tgt} ${sig}
	
	cd ${src}
	
	./configure --enable-utf8 --enable-unicode-properties
	make
    make install
	make clean
}

build_gperftools()
{	
	local url="https://github.com/gperftools/gperftools"
	#url="https://github.com/gperftools/gperftools/releases/download/gperftools-2.8.1/gperftools-2.8.1.tar.gz"
	local tgt=${url#http*://}
	tgt=${tgt%.git}
	local src="${BUILD_PATH}/${tgt}"
	local ver=${GPERFTOOLS_GIT_TAG}

    cd $BUILD_PATH
    if [[ -d "$src" ]]; then  rm -rf $src; fi	
    
	git clone --depth=1 -b $ver $url $src
	cd ${src}
	echo "$src tag=$(git describe --tags --abbrev=0)"

    ./autogen.sh
	./configure --disable-debugalloc --enable-minimal --enable-libunwind
	make
	make install
	make clean
}

build_flatbuffers()
{
	local url="https://github.com/google/flatbuffers"
	local tgt=${url#http*://}
	tgt=${tgt%.git}
	local src="${BUILD_PATH}/${tgt}"
	local ver=${FLATBUFFERS_VERSION}

    cd $BUILD_PATH
    if [[ -d "$src" ]]; then rm -rf $src; fi
    
	git clone --depth=1 -b $ver $url $src
	cd ${src}
	echo "$src tag=$(git describe --tags --abbrev=0)"
	
	cmake -DCMAKE_BUILD_TYPE=Release
	make
    make install
	make clean
}

### colm === https://github.com/adrian-thurston/colm
build_colm()
{
    cd ${BUILD_PATH}
	
    local url="http://www.colm.net/files/thurston.asc"
	curl -sSL ${url} | gpg --import -

	url="http://www.colm.net/files/colm/${COLM_VERSION}.tar.gz.asc"
	local sig=$(basename "$url")
	curl -SL ${url} -o ${sig}

	local url="http://www.colm.net/files/colm/${COLM_VERSION}.tar.gz"
    local tgt=${url#http*://}
	local src="${BUILD_PATH}/$(dirname $tgt)/${COLM_VERSION}"
	local ver=${COLM_VERSION}

	mkdir -p $src
    tgt=$(basename $tgt)
	curl -SL ${url} -o $tgt
	gpg --verify $sig $tgt
    tar -C $src --strip-components=1 -zxf $tgt
    rm -rf ${tgt} ${sig}
	
	cd ${src}
	
	./configure --disable-debug --disable-manual
	make
    make install
	ldconfig
	make clean
}

### ragel === https://github.com/adrian-thurston/ragel
build_ragel()
{
    build_colm

    cd ${BUILD_PATH}
	
    local url="http://www.colm.net/files/thurston.asc"
	#curl -sSL ${url} | gpg --import -
	
	url="http://www.colm.net/files/ragel/${RAGEL_VERSION}.tar.gz.asc"
	local sig=$(basename "$url")
	curl -SL ${url} -o ${sig}

	local url="http://www.colm.net/files/ragel/${RAGEL_VERSION}.tar.gz"
    local tgt=${url#http*://}
	local src="${BUILD_PATH}/$(dirname $tgt)/${RAGEL_VERSION}"
	local ver=${RAGEL_VERSION}
	
	mkdir -p $src
    tgt=$(basename $tgt)
	curl -SL ${url} -o $tgt
	gpg --verify $sig $tgt
    tar -C $src --strip-components=1 -zxf $tgt
    rm -rf ${tgt} ${sig}

	cd ${src}
	
	./configure --with-colm=/usr/local/  --disable-manual
	make
    make install
	ldconfig
	make clean
}

fetch_boost()
{
    cd ${BUILD_PATH}

	local url="https://dl.bintray.com/boostorg/release/1.74.0/source/boost_1_74_0.tar.gz"
	url="https://dl.bintray.com/boostorg/release/1.75.0/source/boost_1_75_0.tar.gz"
	local tgt=${url#http*://}
	local src="$BUILD_PATH/$(dirname $tgt)/${BOOST_VERSION}"
	src="${BUILD_PATH}/www.boost.org/users/download/${BOOST_VERSION}"
	local hash="afff36d392885120bcac079148c177d1f6f7730ec3d47233aa51b0afa4db94a5"
	hash="aeb26f80e80945e82ee93e5939baebdca47b9dee80a07d3144be1e1a6a66dd6a"

	mkdir -p $src
	tgt=$(basename $tgt)
	curl -SL ${url} -o $tgt
    echo "$hash $tgt" | sha256sum -c -   	
	tar -C $src --strip-components=1 -zxf $tgt
	rm -f $tgt
	echo "$src"
}

build_hyperscan()
{
	local boost_root=$(fetch_boost)
	boost_root="${BUILD_PATH}/www.boost.org/users/download/${BOOST_VERSION}"
	echo "Boost is fetched into ${boost_root}"
	local url="https://github.com/intel/hyperscan"
	local tgt=${url#http*://}
	tgt=${tgt%.git}
	local src="${BUILD_PATH}/${tgt}"
	local ver=${HYPERSCAN_VERSION}

    cd $BUILD_PATH
    if [[ -d "$src" ]]; then rm -rf $src; fi
    
	git clone --depth=1 -b $ver $url $src
	cd ${src}
	echo "$src tag=$(git describe --tags --abbrev=0)"
	
	local opt	
	if [[ -n "$(lscpu | egrep 'sse4_2|popcnt')" ]]; then
	    opt='-DFAT_RUNTIME=false -DCMAKE_C_FLAGS="-march=corei7" -DCMAKE_CXX_FLAGS="-march=corei7"'
	elif [[ -n "$(lscpu | egrep 'sse3')" ]]; then
	    opt='-DFAT_RUNTIME=false -DCMAKE_C_FLAGS="-march=core2" -DCMAKE_CXX_FLAGS="-march=core2"'
	elif [[ -n "$(lscpu | egrep 'avx512vbmi')" ]]; then
	    opt='-DFAT_RUNTIME=false -DBUILD_AVX512VBMI=on -DCMAKE_C_FLAGS="-march=icelake-server" -DCMAKE_CXX_FLAGS="-march=icelake-server"'
	elif [[ -n "$(lscpu | egrep 'avx512bw')" ]]; then
	    opt='-DFAT_RUNTIME=false -DBUILD_AVX512=on -DCMAKE_C_FLAGS="-march=skylake-avx512" -DCMAKE_CXX_FLAGS="-march=skylake-avx512"'
	elif [[ -n "$(lscpu | egrep 'avx2')" ]]; then
	    opt='-DFAT_RUNTIME=false -DCMAKE_C_FLAGS="-march=core-avx2" -DCMAKE_CXX_FLAGS="-march=core-avx2"'
	else 
	    opt=""
	fi
	
	if [[ "$#" != "0" ]]; then 
	    opt="$@"
	fi
	
	if [[ $opt == "" ]]; then
	    opt="-DCMAKE_BUILD_TYPE=MinSizeRel"
	else 
	    opt+=" -DCMAKE_BUILD_TYPE=Release -DBUILD_STATIC_AND_SHARED=on"
	fi
	
	mkdir build
	cd build
	
	cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBOOST_ROOT=${boost_root} $opt ${src}
	make
    make install
	make clean	
}

hyperscan_prebuilds()
{
	build_ragel
	# build_libpcap
	build_hyperscan
}

### libdaq === https://github.com/snort3/libdaq
build_libdaq()
{
	local url="https://github.com/snort3/libdaq" 
	local tgt=${url#http*://}
	tgt=${tgt%.git}
	local src="${BUILD_PATH}/${tgt}"
	local ver=${DAQ_VERSION}

    cd $BUILD_PATH
    if [[ -d "$src" ]]; then rm -rf $src; fi
    
    git clone --depth=1 -b $ver $url $src
    cd $src
	echo "$src tag=$(git describe --tags --abbrev=0)"
	
    ./bootstrap
	#./configure --with-libpcap-libraries=/usr/local/lib --with-libpcap-includes=/usr/local/include
	./configure
	make
	make install
# This will break once Snort leaves beta because I've prepended the 
# downloaded file with the word -beta. 
    ldconfig 
	make clean    
}

build_libs_including_hyperscan()
{
	build_safeclib
	build_pcre
	build_gperftools
	#build_luajit
	#build_libpcap
    hyperscan_prebuilds		
	#build_libdnet
	#build_hwloc
	build_flatbuffers	
	build_libdaq
}

build_libs_excluding_hyperscan()
{
	build_safeclib
	build_pcre
	build_gperftools
	build_flatbuffers	
	build_libdaq
}

build_snort3()
{
    # local MY_PATH=/usr/local/snort
 	# cp -f /tmp/libdnet/include/dnet/sctp.h /usr/local/include/dnet/
    
    local url="https://github.com/snort3/snort3"
	local tgt=${url#http*://}
	tgt=${tgt%.git}
	local src="${BUILD_PATH}/${tgt}"
	local ver=${SNORT_VERSION}
    
    git clone -b $ver --depth 1 $url $src
    cd $src
	echo "$src tag=$(git describe --tags --abbrev=0)"
	
    # ./configure_cmake.sh --prefix=${MY_PATH} --disable-docs
    ./configure_cmake.sh --prefix=${MY_PATH} --disable-docs --enable-tcmalloc \
	    --build-type=Release --with-pcre-includes=/usr/local/include \
		--with-pcre-libraries=/usr/local/lib
    cd build

    make -j $(nproc)
	make install
    config_snort3	
	make clean
}

config_snort3()
(
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

fetch_snort3_community_rules()
{
	local url="https://www.snort.org/downloads/community/snort3-community-rules.tar.gz"
	local src=$(basename "$url")

    cd $BUILD_PATH

	curl -SL ${url} -o ${src}    
    # local hash="b60ad5d3fd64c39a0ffd5ce7a289b2ae"
    # echo "$hash $src" | md5sum -c -   
    curl -sSL https://www.snort.org/downloads/community/md5s | grep $src | md5sum -c -
    
    dst=${1-"/usr/local/etc/snort3-community-rules"}
    if [ ! -e "$dst" ]; then 
        mkdir -p ${dst}
    fi
    tar --directory=$dst --strip-components=1 -xzvf $src
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
' > ${f}
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


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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

export MY_PATH=/usr/local/snort

cmds=${1-"help"}

case $cmds in
    init)
	    shift
        init_builds "$@"
        ;;
    clean)
        clean_builds
        ;;
	all)
	    build_libs_including_hyperscan
		#build_libs_excluding_hyperscan
	    
		#build_libpcap
	    #build_libdnet	    
	    #build_hwloc
	    		
		#build_luajit
	    
	    build_snort3
	    ;;
		
    libs-including-hyperscan)
		build_libs_including_hyperscan
		;;
	libs-excluding-hyperscan)
	    build_libs_excluding_hyperscan
		;;

	snort3|snort)
		build_snort3
		;;

	config-snort3)
		config_snort3
		;;

	safeclib)
	    build_safeclib
	    ;;
    pcre) 
	    build_pcre
        ;;   		
    daq|libdaq) 
	    build_libdaq
        ;;
    flatbuffers) 
	    build_flatbuffers
	    ;;	
	gperftools)
	    build_gperftools
	    ;;
	ragel) build_ragel
	    ;;    
    hyperscan) build_hyperscan
        ;;    
    pcap|libpcap) build_libpcap
        ;;
    libdumpnet) build_libdnet
        ;;
    hwloc) build_hwloc
        ;;    

    luajit | luajit2)
        # Install luajit from openresty fork
        export LUAJIT_LIB=/usr/local/lib
        export LUA_LIB_DIR="$LUAJIT_LIB/lua"
        export LUAJIT_INC=/usr/local/include/luajit-2.1		
        build_luajit
        ;;
		
	boost)
	    echo $(fetch_boost)
        ;;
  *)
    echo "Execute: $(basename $0) <command>
        Commands: safeclib, pcre, daq, snort3, hyperscan, gperftools, flatbuffers...
    " >> /dev/stderr
	exit 10
    ;;
esac



