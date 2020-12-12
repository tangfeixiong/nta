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

## Snort3

Build
```
$ docker build --force-rm --rm -t tangfeixiong/snort3 -f Dockerfile.Ubuntu1804-bionic.dev ./
```

```
[cloud@develop3 snort3]$ docker images tangfeixiong/snort3
REPOSITORY            TAG                   IMAGE ID            CREATED             SIZE
tangfeixiong/snort3   3.0.3-5-ubuntu18.04   1d6bd4db13af        2 minutes ago       794MB
```

### Multistage-build

Build
```
$ docker build --force-rm --rm -t tangfeixiong/snort:3.0.3-5-ubuntu18.04 -f Dockerfile.Ubuntu18_04-bionic.multistage-build ./
```

```
[cloud@develop3 snort3]$ docker images tangfeixiong/snort
REPOSITORY            TAG                   IMAGE ID            CREATED             SIZE
tangfeixiong/snort3   3.0.3-5-ubuntu18.04   1d6bd4db13af        2 minutes ago       794MB
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

docker run --log-driver=fluentd --log-opt fluentd-address=localhost:24224 -ti --net=container:gofileserver -v $PWD/snort.lua:/etc/snort/snort.lua -v $PWD/rules/tut.rules:/usr/local/etc/snort/rules/local.rules -v $PWD/log:/var/log/snort -v /run/systemd/journal/syslog:/dev/log --privileged --rm --name=snort3 tangfeixiong/snort:3.0.3-5-ubuntu18.04 snort -d -e -i eth0 -c /etc/snort/snort.lua --rule-path /usr/local/etc/snort/rules -l /var/log/snort --alert-before-pass --treat-drop-as-alert --process-all-events -v -k none

