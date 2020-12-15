# Dockerized Snort3

Reference
+ https://github.com/mosesrenegade/snort3-docker/blob/master/Dockerfile
+ https://github.com/jhunt/docker-snort3/blob/master/Dockerfile
+ https://hub.docker.com/r/ciscotalos/snort3
+ https://hub.docker.com/r/xiche/alpine-snort3-dev/
+ https://github.com/Xiche/alpine-snort3-dev/tree/master
+ https://github.com/traceflight/snort3-with-openappid-docker
- https://www.snort.org/documents/snort-3-on-ubuntu-18-19
- https://github.com/kubernetes/ingress-nginx/blob/master/images/nginx/rootfs/Dockerfile
- https://docs.docker.com/develop/develop-images/multistage-build/
+ https://www.ntop.org/guides/pf_ring/thirdparty/snort-daq-zc.html

## Build

__dev__
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker build --force-rm --rm -t tangfeixiong/snort3 -f Dockerfile.Ubuntu1804-bionic.dev ./
```

```
$ docker images tangfeixiong/snort3
REPOSITORY            TAG                   IMAGE ID            CREATED             SIZE
tangfeixiong/snort3   latest                1d6bd4db13af        2 minutes ago       794MB
```

__multistage build__
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker build --force-rm --rm -t tangfeixiong/snort:3.0.3-5-ubuntu18.04 -f Dockerfile.Ubuntu18_04-bionic.multistage-build ./
```

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker images tangfeixiong/snort
REPOSITORY           TAG                   IMAGE ID            CREATED              SIZE
tangfeixiong/snort   3.0.3-5-ubuntu18.04   dd796bbc6d8c        About a minute ago   1.14GB
```

### hands-on

Reference https://httpbin.org/
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker run -d --rm --name httpbin --expose 80 --privileged kennethreitz/httpbin
d77466ab124a1f397c7775b216037f49381f4f887154fa0edd01316f950c1393
```

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker inspect httpbin --format '{{.NetworkSettings.IPAddress}}'
172.17.0.3
```

inline
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker run -t --rm --name=snort3 --net=container:httpbin -v $PWD/snort.lua:/usr/local/etc/snort/snort.lua -v $PWD/tut.rules:/usr/local/etc/rules/local.rules -v $PWD/log:/var/log/snort -v /run/systemd/journal/syslog:/dev/log --privileged --cap-add NET_ADMIN --workdir /usr/local/etc/snort tangfeixiong/snort:3.0.3-5-ubuntu18.04 snort -d -e -c /usr/local/etc/snort/snort.lua --rule-path /usr/local/etc/rules -l /var/log/snort -v -k none -Q
```

Log
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker run --log-driver=fluentd --log-opt fluentd-address=localhost:24224 -ti --net=container:httpbin -v $PWD/snort.lua:/usr/local/etc/snort/snort.lua -v $PWD/tut.rules:/usr/local/etc/rules/local.rules -v $PWD/log:/var/log/snort -v /run/systemd/journal/syslog:/dev/log --privileged --rm --name=snort3 tangfeixiong/snort:3.0.3-5-ubuntu18.04 snort -d -e -i eth0 -c /usr/local/etc/snort/snort.lua --rule-path /usr/local/etc/rules -l /var/log/snort --alert-before-pass --treat-drop-as-alert --process-all-events -v -k none
```


### Snort3 with ModSecurity

Build
```
$ docker build --force-rm --rm -t tangfeixiong/snort3-plus-modsecurity-ubuntu1804 -f Dockerfile.Snort3-with-ModSecurity.Ubuntu_18_04-bionic ./
```

```
$ docker images tangfeixiong/snort3-plus-modsecurity-ubuntu1804
REPOSITORY                                        TAG                 IMAGE ID            CREATED             SIZE
tangfeixiong/snort3-plus-modsecurity-ubuntu1804   latest              7f3e3a5b55e4        2 minutes ago       1.29GB
```
