# Hands-on: making ModSecurity-nginx as dynamic module

## Table of contents

- Prerequisites
- Build
- Setup this WAF
- Issue

### Reference

[Compiling and Installing ModSecurity for NGINX Open Source – Download the NGINX Connector for ModSecurity and Compile It as a Dynamic Module](https://www.nginx.com/blog/compiling-and-installing-modsecurity-for-open-source-nginx/#4&nbsp;%E2%80%93-Download-the-NGINX-Connector-for-ModSecurity-and-Compile-It-as-a-Dynamic-Module)

https://github.com/SpiderLabs/ModSecurity-nginx/issues/159

https://github.com/SpiderLabs/ModSecurity-nginx/issues/117#issuecomment-495350465

https://gorails.com/blog/how-to-compile-dynamic-nginx-modules

https://www.evanmiller.org/nginx-modules-guide.html

https://www.nginx.com/blog/nginx-dynamic-modules-how-they-work/

https://subscription.packtpub.com/book/networking_and_servers/9781786466174/1/01lvl1sec12/enabling-modules

[ModSecurity：一款优秀的开源WAF](https://www.freebuf.com/sectool/211354.html)


## Prerequisites

Make and install `libmodsecurity` first. Link (./hands-on-delivery-libmodsecurity.md)[./hands-on-delivery-libmodsecurity.md]

Dependency for `ModSecurity-nginx` project
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules$ export MODSECURITY_INC=/usr/local/modsecurity/include/modsecurity

vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules$ ls /usr/local/modsecurity/lib/
libmodsecurity.a         libmodsecurity.la        libmodsecurity.so        libmodsecurity.so.3      libmodsecurity.so.3.0.3  pkgconfig/

vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules$ export MODSECURITY_LIB=/usr/local/modsecurity/lib/

vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules$ printenv | grep MODSECURITY
MODSECURITY_LIB=/usr/local/modsecurity/lib/
MODSECURITY_INC=/usr/local/modsecurity/include

```

Repository of `ModSecurity-nginx` project
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/SpiderLabs$ git clone https://github.com/SpiderLabs/ModSecurity-nginx ModSecurity-nginx
Cloning into 'ModSecurity-nginx'...
remote: Enumerating objects: 25, done.
remote: Counting objects: 100% (25/25), done.
remote: Compressing objects: 100% (15/15), done.
remote: Total 788 (delta 12), reused 15 (delta 10), pack-reused 763
Receiving objects: 100% (788/788), 227.50 KiB | 104.00 KiB/s, done.
Resolving deltas: 100% (554/554), done.
```

### Nginx

Ubuntu distribution. Link [./nginx-modules-config](./nginx-modules-config)

Nginx source
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules$ nginx -v
nginx version: nginx/1.14.0 (Ubuntu)

vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules$ curl -jkSL http://nginx.org/download/nginx-1.14.0.tar.gz -O
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  992k  100  992k    0     0  10550      0  0:01:36  0:01:36 --:--:-- 95540

vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules$ curl -jkSL http://nginx.org/download/nginx-1.14.0.tar.gz.asc -O
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   455  100   455    0     0    147      0  0:00:03  0:00:03 --:--:--   147

$ gpg --recv-key 251A28DE2685AED

vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules$ gpg --verify nginx-1.14.0.tar.gz.asc 
gpg: assuming signed data in 'nginx-1.14.0.tar.gz'
gpg: Signature made Tue Apr 17 15:32:48 2018 UTC
gpg:                using RSA key 520A9993A1C052F8
gpg: Good signature from "Maxim Dounin <mdounin@mdounin.ru>" [unknown]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: B0F4 2533 73F8 F6F5 10D4  2178 520A 9993 A1C0 52F8

```

Extract

    vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules$ tar zxf nginx-1.14.0.tar.gz 



## Build

Compiler arguments

    vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules$ nginx -V
    nginx version: nginx/1.14.0 (Ubuntu)
    built with OpenSSL 1.1.1  11 Sep 2018
    TLS SNI support enabled
    configure arguments: --with-cc-opt='-g -O2 -fdebug-prefix-map=/build/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC' --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --modules-path=/usr/lib/nginx/modules --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-debug --with-pcre-jit --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_auth_request_module --with-http_v2_module --with-http_dav_module --with-http_slice_module --with-threads --with-http_addition_module --with-http_geoip_module=dynamic --with-http_gunzip_module --with-http_gzip_static_module --with-http_image_filter_module=dynamic --with-http_sub_module --with-http_xslt_module=dynamic --with-stream=dynamic --with-stream_ssl_module --with-mail=dynamic --with-mail_ssl_module



Optional cleanning legacy compiled objects

    vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ make clean
    rm -rf Makefile objs



Configure to output Makefile with modified `debug-prefix-map` and added `add-dynamic-module` content

    vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ ./configure --with-cc-opt='-g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC' --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --modules-path=/usr/lib/nginx/modules --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-debug --with-pcre-jit --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_auth_request_module --with-http_v2_module --with-http_dav_module --with-http_slice_module --with-threads --with-http_addition_module --with-http_geoip_module=dynamic --with-http_gunzip_module --with-http_gzip_static_module --with-http_image_filter_module=dynamic --with-http_sub_module --with-http_xslt_module=dynamic --with-stream=dynamic --with-stream_ssl_module --with-mail=dynamic --with-mail_ssl_module --add-dynamic-module=../../../../SpiderLabs/ModSecurity-nginx

Detailed output in building, link [./build-screen-ngx-http-modsecurity-module.txt](./build-screen-ngx-http-modsecurity-module.txt)



Compile to generate shared module

    vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ make modules
    
Also detailed link [./build-screen-ngx-http-modsecurity-module.txt](./build-screen-ngx-http-modsecurity-module.txt)   



The results

    vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ ls objs/*.so
    objs/ngx_http_geoip_module.so         objs/ngx_http_modsecurity_module.so  objs/ngx_mail_module.so
    objs/ngx_http_image_filter_module.so  objs/ngx_http_xslt_filter_module.so  objs/ngx_stream_module.so



## Setup

Modify `/etc/nginx/nginx.conf` for loading `ngx_http_modsecurity_module.so` then writeout its configuration

    include /etc/nginx/modules-enabled/*.conf;

    # This is investigating line
    load_module /Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0/objs/ngx_http_modsecurity_module.so; 
    # And next line is for released (should install copy at objs directory)
    # load_module /usr/lib/nginx/modules/ngx_http_geoip2_module.so;

More looking upon [Reference](#Reference)



Verify config

    vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ sudo nginx -t
    nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /etc/nginx/nginx.conf test is successful



Current time

    vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ date
    Fri Dec 13 19:21:37 UTC 2019



Command to nginx service

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ sudo systemctl reload nginx.service

vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ sudo systemctl status --no-pager -l nginx.service
● nginx.service - A high performance web server and a reverse proxy server
   Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
   Active: active (running) (Result: exit-code) since Thu 2019-12-12 06:15:52 UTC; 1 day 13h ago
     Docs: man:nginx(8)
  Process: 28368 ExecReload=/usr/sbin/nginx -g daemon on; master_process on; -s reload (code=exited, status=0/SUCCESS)
 Main PID: 4394 (nginx)
    Tasks: 2 (limit: 2361)
   CGroup: /system.slice/nginx.service
           ├─ 4394 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
           └─31944 nginx: worker process

Dec 13 08:53:40 ubuntu-bionic systemd[1]: Reloading A high performance web server and a reverse proxy server.
Dec 13 08:53:40 ubuntu-bionic systemd[1]: Reloaded A high performance web server and a reverse proxy server.
Dec 13 09:42:17 ubuntu-bionic systemd[1]: Reloading A high performance web server and a reverse proxy server.
Dec 13 09:42:17 ubuntu-bionic systemd[1]: Reloaded A high performance web server and a reverse proxy server.
Dec 13 09:57:47 ubuntu-bionic systemd[1]: Reloading A high performance web server and a reverse proxy server.
Dec 13 09:57:47 ubuntu-bionic nginx[21261]: nginx: [emerg] module "/usr/local/nginx/modules/ngx_http_geoip2_module.so" is not binary compatible in /etc/nginx/nginx.conf:6
Dec 13 09:57:47 ubuntu-bionic systemd[1]: nginx.service: Control process exited, code=exited status=1
Dec 13 09:57:47 ubuntu-bionic systemd[1]: Reload failed for A high performance web server and a reverse proxy server.
Dec 13 19:22:39 ubuntu-bionic systemd[1]: Reloading A high performance web server and a reverse proxy server.
Dec 13 19:22:39 ubuntu-bionic systemd[1]: Reloaded A high performance web server and a reverse proxy server.
```




## Issue

Link detailed [./failure-building-modsecurity-nginx.txt](./failure-building-modsecurity-nginx.txt)

### Compile error

Step to configure

- ./configure: error: ngx_http_modsecurity_module requires the ModSecurity library and MODSECURITY_LIB ...
- ./configure: error: SSL modules require the OpenSSL library.
- ./configure: error: the HTTP XSLT module requires the libxml2/libxslt
- ./configure: error: the HTTP image filter module requires the GD library.
- ./configure: error: the GeoIP module requires the GeoIP library.

Step to make

- make[1]: *** [objs/src/core/ngx_murmurhash.o] Error 1
- make[1]: *** [objs/addon/src/ngx_http_modsecurity_rewrite.o] Error 1
- make[1]: *** [objs/ngx_http_modsecurity_module.so] Error 1


### Runtime error

Like belowing

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ sudo tail /var/log/nginx/error.log
2019/12/13 09:57:47 [emerg] 21261#21261: module "/usr/local/nginx/modules/ngx_http_geoip2_module.so" is not binary compatible in /etc/nginx/nginx.conf:6
2019/12/13 09:57:55 [emerg] 21264#21264: module "/usr/local/nginx/modules/ngx_http_geoip2_module.so" is not binary compatible in /etc/nginx/nginx.conf:6
2019/12/13 19:20:21 [emerg] 28332#28332: module "/usr/local/nginx/modules/ngx_http_geoip2_module.so" is not binary compatible in /etc/nginx/nginx.conf:6
2019/12/13 19:21:24 [notice] 28363#28363: ModSecurity-nginx v1.0.0 (rules loaded inline/local/remote: 1/898/0)
2019/12/13 19:22:39 [notice] 28368#28368: ModSecurity-nginx v1.0.0 (rules loaded inline/local/remote: 1/898/0)
2019/12/13 19:22:39 [notice] 28368#28368: signal process started
2019/12/13 19:22:39 [emerg] 4394#4394: "modsecurity_rules_file" directive Rules error. File: /etc/nginx/modsec/owasp-modsecurity-crs/rules/REQUEST-910-IP-REPUTATION.conf. Line: 73. Column: 22. This version of ModSecurity was not compiled with GeoIP or MaxMind support.  in /etc/nginx/nginx.conf:111
2019/12/13 19:28:49 [notice] 28476#28476: ModSecurity-nginx v1.0.0 (rules loaded inline/local/remote: 1/898/0)
2019/12/13 19:28:49 [notice] 28476#28476: signal process started
2019/12/13 19:28:49 [emerg] 4394#4394: "modsecurity_rules_file" directive Rules error. File: /etc/nginx/modsec/owasp-modsecurity-crs/rules/REQUEST-910-IP-REPUTATION.conf. Line: 73. Column: 22. This version of ModSecurity was not compiled with GeoIP or MaxMind support.  in /etc/nginx/nginx.conf:111
```

Module "ngx_http_geoip2_module.so" is not binary compatible

- When executing `./configure ...`, its arguments is leaking or unmatching with already running `/usr/sbin/nginx`
- The service enter failure when wanting to reload 


This version of ModSecurity was not compiled with GeoIP or MaxMind support

- This development lib should not be ignored when configure making


### Successfully demo

Build 2 moudles. The ngx_geoip2_module refer to [../nginx-modules-lab/ngx-http-geoip2-module.txt](../nginx-modules-lab/ngx-http-geoip2-module.txt)

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ make clean
rm -rf Makefile objs
```

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ ./configure --with-cc-opt='-g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC' --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --modules-path=/usr/lib/nginx/modules --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-debug --with-pcre-jit --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_auth_request_module --with-http_v2_module --with-http_dav_module --with-http_slice_module --with-threads --with-http_addition_module --with-http_geoip_module=dynamic --with-http_gunzip_module --with-http_gzip_static_module --with-http_image_filter_module=dynamic --with-http_sub_module --with-http_xslt_module=dynamic --with-stream=dynamic --with-stream_ssl_module --with-mail=dynamic --with-mail_ssl_module --add-dynamic-module=../../../../SpiderLabs/ModSecurity-nginx  --add-dynamic-module=../ngx_http_geoip2_module-3.3
checking for OS
 + Linux 4.15.0-72-generic x86_64
checking for C compiler ... found
 + using GNU C compiler
 + gcc version: 7.4.0 (Ubuntu 7.4.0-1ubuntu1~18.04.1) 
checking for gcc -pipe switch ... found
checking for --with-ld-opt="-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC" ... found
checking for -Wl,-E switch ... found
checking for gcc builtin atomic operations ... found
checking for C99 variadic macros ... found
checking for gcc variadic macros ... found
checking for gcc builtin 64 bit byteswap ... found
checking for unistd.h ... found
checking for inttypes.h ... found
checking for limits.h ... found
checking for sys/filio.h ... not found
checking for sys/param.h ... found
checking for sys/mount.h ... found
checking for sys/statvfs.h ... found
checking for crypt.h ... found
checking for Linux specific features
checking for epoll ... found
checking for EPOLLRDHUP ... found
checking for EPOLLEXCLUSIVE ... found
checking for O_PATH ... found
checking for sendfile() ... found
checking for sendfile64() ... found
checking for sys/prctl.h ... found
checking for prctl(PR_SET_DUMPABLE) ... found
checking for prctl(PR_SET_KEEPCAPS) ... found
checking for capabilities ... found
checking for crypt_r() ... found
checking for sys/vfs.h ... found
checking for nobody group ... not found
checking for nogroup group ... found
checking for poll() ... found
checking for /dev/poll ... not found
checking for kqueue ... not found
checking for crypt() ... not found
checking for crypt() in libcrypt ... found
checking for F_READAHEAD ... not found
checking for posix_fadvise() ... found
checking for O_DIRECT ... found
checking for F_NOCACHE ... not found
checking for directio() ... not found
checking for statfs() ... found
checking for statvfs() ... found
checking for dlopen() ... not found
checking for dlopen() in libdl ... found
checking for sched_yield() ... found
checking for sched_setaffinity() ... found
checking for SO_SETFIB ... not found
checking for SO_REUSEPORT ... found
checking for SO_ACCEPTFILTER ... not found
checking for SO_BINDANY ... not found
checking for IP_TRANSPARENT ... found
checking for IP_BINDANY ... not found
checking for IP_BIND_ADDRESS_NO_PORT ... found
checking for IP_RECVDSTADDR ... not found
checking for IP_SENDSRCADDR ... not found
checking for IP_PKTINFO ... found
checking for IPV6_RECVPKTINFO ... found
checking for TCP_DEFER_ACCEPT ... found
checking for TCP_KEEPIDLE ... found
checking for TCP_FASTOPEN ... found
checking for TCP_INFO ... found
checking for accept4() ... found
checking for eventfd() ... found
checking for int size ... 4 bytes
checking for long size ... 8 bytes
checking for long long size ... 8 bytes
checking for void * size ... 8 bytes
checking for uint32_t ... found
checking for uint64_t ... found
checking for sig_atomic_t ... found
checking for sig_atomic_t size ... 4 bytes
checking for socklen_t ... found
checking for in_addr_t ... found
checking for in_port_t ... found
checking for rlim_t ... found
checking for uintptr_t ... uintptr_t found
checking for system byte ordering ... little endian
checking for size_t size ... 8 bytes
checking for off_t size ... 8 bytes
checking for time_t size ... 8 bytes
checking for AF_INET6 ... found
checking for setproctitle() ... not found
checking for pread() ... found
checking for pwrite() ... found
checking for pwritev() ... found
checking for sys_nerr ... found
checking for localtime_r() ... found
checking for clock_gettime(CLOCK_MONOTONIC) ... found
checking for posix_memalign() ... found
checking for memalign() ... found
checking for mmap(MAP_ANON|MAP_SHARED) ... found
checking for mmap("/dev/zero", MAP_SHARED) ... found
checking for System V shared memory ... found
checking for POSIX semaphores ... not found
checking for POSIX semaphores in libpthread ... found
checking for struct msghdr.msg_control ... found
checking for ioctl(FIONBIO) ... found
checking for struct tm.tm_gmtoff ... found
checking for struct dirent.d_namlen ... not found
checking for struct dirent.d_type ... found
checking for sysconf(_SC_NPROCESSORS_ONLN) ... found
checking for sysconf(_SC_LEVEL1_DCACHE_LINESIZE) ... found
checking for openat(), fstatat() ... found
checking for getaddrinfo() ... found
configuring additional dynamic modules
adding module in ../../../../SpiderLabs/ModSecurity-nginx
checking for ModSecurity library in "/usr/local/modsecurity/lib/" and "/usr/local/modsecurity/include" (specified by the MODSECURITY_LIB and MODSECURITY_INC env) ... found
 + ngx_http_modsecurity_module was configured
adding module in ../ngx_http_geoip2_module-3.3
checking for MaxmindDB library ... found
 + ngx_geoip2_module was configured
checking for PCRE library ... found
checking for PCRE JIT support ... found
checking for OpenSSL library ... found
checking for zlib library ... found
checking for libxslt ... found
checking for libexslt ... found
checking for GD library ... found
checking for GD WebP support ... found
checking for GeoIP library ... found
checking for GeoIP IPv6 support ... found
creating objs/Makefile

Configuration summary
  + using threads
  + using system PCRE library
  + using system OpenSSL library
  + using system zlib library

  nginx path prefix: "/usr/share/nginx"
  nginx binary file: "/usr/share/nginx/sbin/nginx"
  nginx modules path: "/usr/lib/nginx/modules"
  nginx configuration prefix: "/etc/nginx"
  nginx configuration file: "/etc/nginx/nginx.conf"
  nginx pid file: "/run/nginx.pid"
  nginx error log file: "/var/log/nginx/error.log"
  nginx http access log file: "/var/log/nginx/access.log"
  nginx http client request body temporary files: "/var/lib/nginx/body"
  nginx http proxy temporary files: "/var/lib/nginx/proxy"
  nginx http fastcgi temporary files: "/var/lib/nginx/fastcgi"
  nginx http uwsgi temporary files: "/var/lib/nginx/uwsgi"
  nginx http scgi temporary files: "/var/lib/nginx/scgi"
```

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ make modules
make -f objs/Makefile modules
make[1]: Entering directory '/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0'
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/http/modules/ngx_http_xslt_filter_module.o \
	src/http/modules/ngx_http_xslt_filter_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/ngx_http_xslt_filter_module_modules.o \
	objs/ngx_http_xslt_filter_module_modules.c
cc -o objs/ngx_http_xslt_filter_module.so \
objs/src/http/modules/ngx_http_xslt_filter_module.o \
objs/ngx_http_xslt_filter_module_modules.o \
-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC -lxml2 -lxslt -lexslt \
-shared
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/http/modules/ngx_http_image_filter_module.o \
	src/http/modules/ngx_http_image_filter_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/ngx_http_image_filter_module_modules.o \
	objs/ngx_http_image_filter_module_modules.c
cc -o objs/ngx_http_image_filter_module.so \
objs/src/http/modules/ngx_http_image_filter_module.o \
objs/ngx_http_image_filter_module_modules.o \
-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC -lgd \
-shared
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/http/modules/ngx_http_geoip_module.o \
	src/http/modules/ngx_http_geoip_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/ngx_http_geoip_module_modules.o \
	objs/ngx_http_geoip_module_modules.c
cc -o objs/ngx_http_geoip_module.so \
objs/src/http/modules/ngx_http_geoip_module.o \
objs/ngx_http_geoip_module_modules.o \
-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC -lGeoIP \
-shared
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/addon/src/ngx_http_modsecurity_module.o \
	../../../../SpiderLabs/ModSecurity-nginx/src/ngx_http_modsecurity_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/addon/src/ngx_http_modsecurity_pre_access.o \
	../../../../SpiderLabs/ModSecurity-nginx/src/ngx_http_modsecurity_pre_access.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/addon/src/ngx_http_modsecurity_header_filter.o \
	../../../../SpiderLabs/ModSecurity-nginx/src/ngx_http_modsecurity_header_filter.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/addon/src/ngx_http_modsecurity_body_filter.o \
	../../../../SpiderLabs/ModSecurity-nginx/src/ngx_http_modsecurity_body_filter.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/addon/src/ngx_http_modsecurity_log.o \
	../../../../SpiderLabs/ModSecurity-nginx/src/ngx_http_modsecurity_log.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/addon/src/ngx_http_modsecurity_rewrite.o \
	../../../../SpiderLabs/ModSecurity-nginx/src/ngx_http_modsecurity_rewrite.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/ngx_http_modsecurity_module_modules.o \
	objs/ngx_http_modsecurity_module_modules.c
cc -o objs/ngx_http_modsecurity_module.so \
objs/addon/src/ngx_http_modsecurity_module.o \
objs/addon/src/ngx_http_modsecurity_pre_access.o \
objs/addon/src/ngx_http_modsecurity_header_filter.o \
objs/addon/src/ngx_http_modsecurity_body_filter.o \
objs/addon/src/ngx_http_modsecurity_log.o \
objs/addon/src/ngx_http_modsecurity_rewrite.o \
objs/ngx_http_modsecurity_module_modules.o \
-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC -Wl,-rpath,/usr/local/modsecurity/lib/ -L/usr/local/modsecurity/lib/ -lmodsecurity \
-shared
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/addon/ngx_http_geoip2_module-3.3/ngx_http_geoip2_module.o \
	../ngx_http_geoip2_module-3.3/ngx_http_geoip2_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/ngx_http_geoip2_module_modules.o \
	objs/ngx_http_geoip2_module_modules.c
cc -o objs/ngx_http_geoip2_module.so \
objs/addon/ngx_http_geoip2_module-3.3/ngx_http_geoip2_module.o \
objs/ngx_http_geoip2_module_modules.o \
-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC -lmaxminddb \
-shared
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/addon/ngx_http_geoip2_module-3.3/ngx_stream_geoip2_module.o \
	../ngx_http_geoip2_module-3.3/ngx_stream_geoip2_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/ngx_stream_geoip2_module_modules.o \
	objs/ngx_stream_geoip2_module_modules.c
cc -o objs/ngx_stream_geoip2_module.so \
objs/addon/ngx_http_geoip2_module-3.3/ngx_stream_geoip2_module.o \
objs/ngx_stream_geoip2_module_modules.o \
-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC -lmaxminddb \
-shared
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/mail/ngx_mail.o \
	src/mail/ngx_mail.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/mail/ngx_mail_core_module.o \
	src/mail/ngx_mail_core_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/mail/ngx_mail_handler.o \
	src/mail/ngx_mail_handler.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/mail/ngx_mail_parse.o \
	src/mail/ngx_mail_parse.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/mail/ngx_mail_ssl_module.o \
	src/mail/ngx_mail_ssl_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/mail/ngx_mail_pop3_module.o \
	src/mail/ngx_mail_pop3_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/mail/ngx_mail_pop3_handler.o \
	src/mail/ngx_mail_pop3_handler.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/mail/ngx_mail_imap_module.o \
	src/mail/ngx_mail_imap_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/mail/ngx_mail_imap_handler.o \
	src/mail/ngx_mail_imap_handler.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/mail/ngx_mail_smtp_module.o \
	src/mail/ngx_mail_smtp_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/mail/ngx_mail_smtp_handler.o \
	src/mail/ngx_mail_smtp_handler.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/mail/ngx_mail_auth_http_module.o \
	src/mail/ngx_mail_auth_http_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/mail/ngx_mail_proxy_module.o \
	src/mail/ngx_mail_proxy_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/ngx_mail_module_modules.o \
	objs/ngx_mail_module_modules.c
cc -o objs/ngx_mail_module.so \
objs/src/mail/ngx_mail.o \
objs/src/mail/ngx_mail_core_module.o \
objs/src/mail/ngx_mail_handler.o \
objs/src/mail/ngx_mail_parse.o \
objs/src/mail/ngx_mail_ssl_module.o \
objs/src/mail/ngx_mail_pop3_module.o \
objs/src/mail/ngx_mail_pop3_handler.o \
objs/src/mail/ngx_mail_imap_module.o \
objs/src/mail/ngx_mail_imap_handler.o \
objs/src/mail/ngx_mail_smtp_module.o \
objs/src/mail/ngx_mail_smtp_handler.o \
objs/src/mail/ngx_mail_auth_http_module.o \
objs/src/mail/ngx_mail_proxy_module.o \
objs/ngx_mail_module_modules.o \
-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC \
-shared
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream.o \
	src/stream/ngx_stream.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_variables.o \
	src/stream/ngx_stream_variables.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_script.o \
	src/stream/ngx_stream_script.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_handler.o \
	src/stream/ngx_stream_handler.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_core_module.o \
	src/stream/ngx_stream_core_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_log_module.o \
	src/stream/ngx_stream_log_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_proxy_module.o \
	src/stream/ngx_stream_proxy_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_upstream.o \
	src/stream/ngx_stream_upstream.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_upstream_round_robin.o \
	src/stream/ngx_stream_upstream_round_robin.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_write_filter_module.o \
	src/stream/ngx_stream_write_filter_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_ssl_module.o \
	src/stream/ngx_stream_ssl_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_limit_conn_module.o \
	src/stream/ngx_stream_limit_conn_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_access_module.o \
	src/stream/ngx_stream_access_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_geo_module.o \
	src/stream/ngx_stream_geo_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_map_module.o \
	src/stream/ngx_stream_map_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_split_clients_module.o \
	src/stream/ngx_stream_split_clients_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_return_module.o \
	src/stream/ngx_stream_return_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_upstream_hash_module.o \
	src/stream/ngx_stream_upstream_hash_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_upstream_least_conn_module.o \
	src/stream/ngx_stream_upstream_least_conn_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/src/stream/ngx_stream_upstream_zone_module.o \
	src/stream/ngx_stream_upstream_zone_module.c
cc -c -fPIC -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g -g -O2 -fdebug-prefix-map=/tmp/nginx-DUghaW/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2 -I src/core -I src/event -I src/event/modules -I src/os/unix -I /usr/local/modsecurity/include -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I src/mail -I src/stream \
	-o objs/ngx_stream_module_modules.o \
	objs/ngx_stream_module_modules.c
cc -o objs/ngx_stream_module.so \
objs/src/stream/ngx_stream.o \
objs/src/stream/ngx_stream_variables.o \
objs/src/stream/ngx_stream_script.o \
objs/src/stream/ngx_stream_handler.o \
objs/src/stream/ngx_stream_core_module.o \
objs/src/stream/ngx_stream_log_module.o \
objs/src/stream/ngx_stream_proxy_module.o \
objs/src/stream/ngx_stream_upstream.o \
objs/src/stream/ngx_stream_upstream_round_robin.o \
objs/src/stream/ngx_stream_write_filter_module.o \
objs/src/stream/ngx_stream_ssl_module.o \
objs/src/stream/ngx_stream_limit_conn_module.o \
objs/src/stream/ngx_stream_access_module.o \
objs/src/stream/ngx_stream_geo_module.o \
objs/src/stream/ngx_stream_map_module.o \
objs/src/stream/ngx_stream_split_clients_module.o \
objs/src/stream/ngx_stream_return_module.o \
objs/src/stream/ngx_stream_upstream_hash_module.o \
objs/src/stream/ngx_stream_upstream_least_conn_module.o \
objs/src/stream/ngx_stream_upstream_zone_module.o \
objs/ngx_stream_module_modules.o \
-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC \
-shared
make[1]: Leaving directory '/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0'
```


```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ sudo systemctl restart nginx.service
```


Working expected

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ curl http://localhost
Thank you for requesting /


vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ curl -H "User-Agent: Nikto" http://localhost
<html>
<head><title>403 Forbidden</title></head>
<body bgcolor="white">
<center><h1>403 Forbidden</h1></center>
<hr><center>nginx/1.14.0 (Ubuntu)</center>
</body>
</html>
```

Well logged

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ sudo tail /var/log/nginx/error.log
2019/12/13 19:36:23 [notice] 32120#32120: ModSecurity-nginx v1.0.0 (rules loaded inline/local/remote: 1/898/0)
2019/12/13 19:36:23 [notice] 32120#32120: signal process started
2019/12/13 19:36:24 [emerg] 4394#4394: "modsecurity_rules_file" directive Rules error. File: /etc/nginx/modsec/owasp-modsecurity-crs/rules/REQUEST-910-IP-REPUTATION.conf. Line: 73. Column: 22. This version of ModSecurity was not compiled with GeoIP or MaxMind support.  in /etc/nginx/nginx.conf:111
2019/12/13 19:39:41 [notice] 32248#32248: ModSecurity-nginx v1.0.0 (rules loaded inline/local/remote: 1/898/0)
2019/12/13 19:39:52 [notice] 32252#32252: ModSecurity-nginx v1.0.0 (rules loaded inline/local/remote: 1/898/0)
2019/12/13 19:39:52 [notice] 32252#32252: signal process started
2019/12/13 19:39:52 [emerg] 4394#4394: "modsecurity_rules_file" directive Rules error. File: /etc/nginx/modsec/owasp-modsecurity-crs/rules/REQUEST-910-IP-REPUTATION.conf. Line: 73. Column: 22. This version of ModSecurity was not compiled with GeoIP or MaxMind support.  in /etc/nginx/nginx.conf:111
2019/12/13 19:40:14 [notice] 32260#32260: ModSecurity-nginx v1.0.0 (rules loaded inline/local/remote: 1/898/0)
2019/12/13 19:40:14 [notice] 32272#32272: ModSecurity-nginx v1.0.0 (rules loaded inline/local/remote: 1/898/0)
2019/12/13 19:40:19 [error] 32279#32279: *1 [client 127.0.0.1] ModSecurity: Access denied with code 403 (phase 2). Matched "Operator `Ge' with parameter `5' against variable `TX:ANOMALY_SCORE' (Value: `5' ) [file "/etc/nginx/modsec/owasp-modsecurity-crs/rules/REQUEST-949-BLOCKING-EVALUATION.conf"] [line "79"] [id "949110"] [rev ""] [msg "Inbound Anomaly Score Exceeded (Total Score: 5)"] [data ""] [severity "2"] [ver ""] [maturity "0"] [accuracy "0"] [tag "application-multi"] [tag "language-multi"] [tag "platform-multi"] [tag "attack-generic"] [hostname "127.0.0.1"] [uri "/"] [unique_id "default-016aaf73fdf793da4f01cf8f8eceb9da"] [ref ""], client: 127.0.0.1, server: localhost, request: "GET / HTTP/1.1", host: "localhost"


vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/nginx-modules/nginx-1.14.0$ sudo tail /var/log/nginx/access.log
127.0.0.1 - - [13/Dec/2019:08:54:14 +0000] "GET / HTTP/1.1" 200 27 "-" "Nikto"
127.0.0.1 - - [13/Dec/2019:08:54:23 +0000] "GET / HTTP/1.1" 200 27 "-" "curl/7.58.0"
127.0.0.1 - - [13/Dec/2019:08:54:59 +0000] "GET / HTTP/1.1" 200 27 "-" "curl/7.58.0"
127.0.0.1 - - [13/Dec/2019:09:42:35 +0000] "GET / HTTP/1.1" 200 27 "-" "Nikto"
127.0.0.1 - - [13/Dec/2019:19:25:23 +0000] "GET / HTTP/1.1" 200 27 "-" "Nikto"
127.0.0.1 - - [13/Dec/2019:19:29:04 +0000] "GET / HTTP/1.1" 200 27 "-" "Nikto"
127.0.0.1 - - [13/Dec/2019:19:36:29 +0000] "GET / HTTP/1.1" 200 27 "-" "Nikto"
127.0.0.1 - - [13/Dec/2019:19:40:04 +0000] "GET / HTTP/1.1" 200 27 "-" "Nikto"
127.0.0.1 - - [13/Dec/2019:19:40:19 +0000] "GET / HTTP/1.1" 403 178 "-" "Nikto"
127.0.0.1 - - [13/Dec/2019:19:45:13 +0000] "GET / HTTP/1.1" 200 27 "-" "curl/7.58.0"
```