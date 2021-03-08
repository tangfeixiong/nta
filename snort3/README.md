# Dockerized Snort3

Reference
+ https://github.com/mosesrenegade/snort3-docker/blob/master/Dockerfile
+ https://github.com/jhunt/docker-snort3/blob/master/Dockerfile
+ https://hub.docker.com/r/ciscotalos/snort3
+ https://hub.docker.com/r/xiche/alpine-snort3-dev/
+ https://github.com/Xiche/alpine-snort3-dev/tree/master
+ https://github.com/traceflight/snort3-with-openappid-docker
- https://www.snort.org/documents/snort-3-on-ubuntu-18-19
- http://sublimerobots.com/tag/snort/
- https://github.com/kubernetes/ingress-nginx/blob/master/images/nginx/rootfs/Dockerfile
- https://docs.docker.com/develop/develop-images/multistage-build/
+ https://www.ntop.org/guides/pf_ring/thirdparty/snort-daq-zc.html
- [https://sublimerobots.com/tag/nips/](Snort IPS With NFQ (nfqueue) Routing on Ubuntu)
+ https://docs.mirantis.com/mcp/q4-18/mcp-security-best-practices/cloud-security-solutions.html

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
docker build --force-rm --rm -t tangfeixiong/snort:3.1-ubuntu18.04 -f Dockerfile.Ubuntu18_04-bionic.multistage-build ./
```

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker images tangfeixiong/snort
REPOSITORY           TAG                   IMAGE ID            CREATED              SIZE
tangfeixiong/snort   3.0.3-5-ubuntu18.04   dd796bbc6d8c        About a minute ago   1.14GB
```

## NFQueue

Reference https://httpbin.org/
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker run -d --rm --name httpbin --cpus 0.5 --memory 512M --expose 80 --privileged kennethreitz/httpbin
d77466ab124a1f397c7775b216037f49381f4f887154fa0edd01316f950c1393
```

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker inspect httpbin --format '{{.NetworkSettings.IPAddress}}'
172.17.0.3
```

__Working on Host namespace__

NFQueue
```
root@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3# \
iptables -I INPUT -j NFQUEUE --queue-num 1 --queue-bypass
```

Snort IPS
```
root@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3# \
docker run -t --rm --name=snort3 --net=host -v $PWD/snort.lua:/usr/local/etc/snort/snort.lua -v $PWD/tut.rules:/usr/local/etc/rules/local.rules -v $PWD/vol-mnt/log:/var/log/snort -v /run/systemd/journal/syslog:/tmp/syslog --cap-add SYS_ADMIN --cap-add NET_ADMIN --privileged tangfeixiong/snort snort -c /usr/local/etc/snort/snort.lua --rule-path /usr/local/etc/rules -l /var/log/snort -v -k none -Q -d -e
```

### Working on Container namespace__

1. Httpbin
2. Nginx
3. MySQL/MariaDB

__Httpbin__ 
```
root@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3# PID=$(docker inspect httpbin -f '{{.State.Pid}}')
root@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3# sudo nsenter --target $PID --net
root@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3# iptables -I INPUT -j NFQUEUE --queue-num 1 --queue-bypass
root@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3# ethtool -K eth0 gro off
root@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3# exit
```

Snort IPS
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker run -t --rm --name=snort3 --net=container:httpbin -v $PWD/snort.lua:/usr/local/etc/snort/snort.lua -v $PWD/tut.rules:/usr/local/etc/rules/local.rules -v $PWD/vol-mnt/log:/var/log/snort -v /run/systemd/journal/syslog:/tmp/syslog --privileged --cap-add SYS_ADMIN --cap-add NET_ADMIN tangfeixiong/snort:3.0.3-5-ubuntu18.04 snort -c /usr/local/etc/snort/snort.lua --rule-path /usr/local/etc/rules -l /var/log/snort -v -k none -Q -d -e 
```

```
docker run -t --rm --name=snort3 --net=container:httpbin -v $PWD/snort.lua:/usr/local/etc/snort/snort.lua -v $PWD/tut.rules:/usr/local/etc/rules/local.rules -v $PWD/vol-mnt/log:/var/log/snort -v /run/systemd/journal/syslog:/tmp/syslog -v $PWD/vol-mnt/snort3-community-effective.rules:/usr/local/etc/rules/snort3-community.rules --privileged --cap-add SYS_ADMIN --cap-add NET_ADMIN tangfeixiong/snort snort -c /usr/local/etc/snort/snort.lua --rule-path /usr/local/etc/rules  -l /var/log/snort -v -k none -Q -d -e --warn-rules --daq nfq --daq-mode inline --daq-var queue-maxlen=65535 -i 1
```

```
docker run -t --rm --name=snort3 --net=host -v $PWD/snort.lua:/usr/local/etc/snort/snort.lua -v $PWD/tut.rules:/usr/local/etc/rules/local.rules -v $PWD/vol-mnt/log:/var/log/snort -v /run/systemd/journal/syslog:/tmp/syslog --privileged --env LD_LIBRARY_PATH=/usr/local/modsecurity/lib tangfeixiong/snort snort -c /usr/local/etc/snort/snort.lua --rule-path /usr/local/etc/rules -l /var/log/snort -v -k none --warn-rules -Q --daq nfq --daq-mode inline --daq-var queue-maxlen=65535 -i 1
```

__Nginx__
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ docker run -d --rm --name nginx --expose 80 --cap-add NET_ADMIN -v $PWD/vol-mnt/etc/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf nginx:1.19.6 

```

Snort IPS
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker run -t --rm --name=snort3 --net=container:nginx -v $PWD/snort.lua:/usr/local/etc/snort/snort.lua -v $PWD/tut.rules:/usr/local/etc/rules/local.rules -v $PWD/vol-mnt/log:/var/log/snort -v /run/systemd/journal/syslog:/dev/log --privileged --cap-add SYS_ADMIN --cap-add NET_ADMIN tangfeixiong/snort snort -c /usr/local/etc/snort/snort.lua --rule-path /usr/local/etc/rules -l /var/log/snort -v -k none -Q -d -e 
```

__MySQL__
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker run -d --rm --name mysql --expose 3306 --cap-add NET_ADMIN --env MYSQL_ROOT_PASSWORD=ROOT_PASS --env MYSQL_DATABASE=testdb --env MYSQL_USER=testuser --env MYSQL_PASSWORD=TEST_PASS -v $PWD/vol-mnt/var/lib/mysql/docker-entrypoint-initdb.d:/docker-entrypoint-initdb.d mysql:5.7
```

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ docker inspect mysql -f '{{.State.Pid}}'
17399
```

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ sudo nsenter --target 17399 --net
```

```
root@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfexiong/nta/snort3# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
61: eth0@if62: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:ac:11:00:04 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.4/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
```

```
root@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3# ethtool -k eth0 | grep receive-offload
generic-receive-offload: on
large-receive-offload: off [fixed]
```

```
root@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3# ethtool -K eth0 gro off  
```

```
root@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3# iptables -A INPUT -j NFQUEUE --queue-num 1 --queue-bypass
```

```
root@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3# tcpdump -vv -x -X -s 1500 -i eth0
tcpdump: listening on eth0, link-type EN10MB (Ethernet), capture size 1500 bytes
```

```
root@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3# exit
logout
```

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ sudo ufw allow 3306/tcp comment mysql
Rule added
Rule added (v6)
```

Snort3
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker run -t --rm --name=snort3 --net=container:mysql -v $PWD/snort.lua:/usr/local/etc/snort/snort.lua -v $PWD/vol-mnt/etc/rules/mysql.rules:/usr/local/etc/rules/local.rules -v $PWD/vol-mnt/log:/var/log/snort -v /run/systemd/journal/syslog:/tmp/syslog --privileged --cap-add SYS_ADMIN --cap-add NET_ADMIN tangfeixiong/snort:3.1-ubuntu18.04 snort -c /usr/local/etc/snort/snort.lua --rule-path /usr/local/etc/rules -l /var/log/snort -v -k none -Q -d -e
```

client
```
docker run --rm -ti --name mysql-cli --link mysql:mysql mysql:5.6 mysql --host=mysql --ssl-mode=disabled -u root -p
```


__Redis__
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker run -d --rm --name my-redis --expose 6379 --cap-add NET_ADMIN redis:6.0
```

```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker inspect my-redis -f '{{.State.Pid}}'
29536
```


client
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ docker run --rm -ti --name redis-cli --link my-redis:my-redis redis:6.0 redis-cli -h my-redis
my-redis:6379> 
```


__Log__

Using Docker logger 
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker run --log-driver=fluentd --log-opt fluentd-address=localhost:24224 -ti --net=container:httpbin -v $PWD/snort.lua:/usr/local/etc/snort/snort.lua -v $PWD/tut.rules:/usr/local/etc/rules/local.rules -v $PWD/log:/var/log/snort -v /run/systemd/journal/syslog:/dev/log --privileged --rm --name=snort3 tangfeixiong/snort:3.0.3-5-ubuntu18.04 snort -d -e -i eth0 -c /usr/local/etc/snort/snort.lua --rule-path /usr/local/etc/rules -l /var/log/snort --alert-before-pass --treat-drop-as-alert --process-all-events -v -k none
```

With Syslog forward Fluent-bit 
```
vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/snort3$ \
docker run -t --rm --name=snort3 --net=container:httpbin -v $PWD/snort.lua:/usr/local/etc/snort/snort.lua -v $PWD/tut.rules:/usr/local/etc/rules/local.rules -v $PWD/vol-mnt/log:/var/log/snort -v /run/systemd/journal/syslog:/tmp/syslog --privileged --cap-add SYS_ADMIN --cap-add NET_ADMIN tangfeixiong/snort:3.0.3-5-ubuntu18.04 snort -c /usr/local/etc/snort/snort.lua --rule-path /usr/local/etc/rules -l /var/log/snort -v -k none -Q -d -e 
```



### IPS+WAF

Build
```
$ docker build --force-rm --rm -t tangfeixiong/snort3-plus-modsecurity-ubuntu1804 -f Dockerfile.Snort3-with-ModSecurity.Ubuntu_18_04-bionic ./
```

```
$ docker images tangfeixiong/snort3-plus-modsecurity-ubuntu1804
REPOSITORY                                        TAG                 IMAGE ID            CREATED             SIZE
tangfeixiong/snort3-plus-modsecurity-ubuntu1804   latest              7f3e3a5b55e4        2 minutes ago       1.29GB
```
