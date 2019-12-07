# Network Traffic Lab under virtualization 

## Network Virtualization Env

### Physical Computer

笔记本计算机： Mac pro

网络

+ Wifi

  物理网络


    en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
    	ether ac:bc:32:7c:3c:37 
    	inet6 fe80::aebc:32ff:fe7c:3c37%en0 prefixlen 64 scopeid 0x4 
    	inet 192.168.0.106 netmask 0xffffff00 broadcast 192.168.0.255
    	nd6 options=1<PERFORMNUD>
    	media: autoselect
    	status: active

+ VirtualBox private network

  虚拟网络


    vboxnet1: flags=8943<UP,BROADCAST,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 1500
    	ether 0a:00:27:00:00:01 
    	inet 172.28.128.1 netmask 0xffffff00 broadcast 172.28.128.255

  南北向：NAT， 由VirtualBox的网络模块管理配置
  
  如Vagrantfile中
  

      ﻿# Docker unencrypted TCP listening port
    ﻿  config.vm.network "forwarded_port", guest: 2375, host: 2375

### VM

Ubuntu 18.04

网络

+ 虚拟机的网卡

  在vboxnet1


    vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta$ ip addr show enp0s8
    3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
        link/ether 08:00:27:e5:e2:33 brd ff:ff:ff:ff:ff:ff
        inet 172.28.128.4/24 brd 172.28.128.255 scope global enp0s8
           valid_lft forever preferred_lft forever
        inet6 fe80::a00:27ff:fee5:e233/64 scope link 
           valid_lft forever preferred_lft forever


+ docker0

  安装docker engine后
  

    vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta$ ip addr show docker0
    4: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
        link/ether 02:42:76:1a:54:c0 brd ff:ff:ff:ff:ff:ff
        inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
           valid_lft forever preferred_lft forever
        inet6 fe80::42:76ff:fe1a:54c0/64 scope link 
           valid_lft forever preferred_lft forever

  North-South flow：由docker的network管理配置
  
  如下docker命令中的`-p80:80`， 前一个80指明虚拟机的任何ip地址的80端口，后一个80是容器的ip地址
  
  
    ﻿vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/google/gopacket/examples$ docker run -d -p80:80 --name mynginx1 nginx

  路由表
  
  
    vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta$ sudo iptables -L -n -t nat
    Chain PREROUTING (policy ACCEPT)
    target     prot opt source               destination         
    DOCKER     all  --  0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL
    
    Chain INPUT (policy ACCEPT)
    target     prot opt source               destination         
    
    Chain OUTPUT (policy ACCEPT)
    target     prot opt source               destination         
    DOCKER     all  --  0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL
    
    Chain POSTROUTING (policy ACCEPT)
    target     prot opt source               destination         
    MASQUERADE  all  --  172.17.0.0/16        0.0.0.0/0           
    MASQUERADE  tcp  --  172.17.0.2           172.17.0.2           tcp dpt:80
    MASQUERADE  tcp  --  172.17.0.3           172.17.0.3           tcp dpt:48080
    
    Chain DOCKER (2 references)
    target     prot opt source               destination         
    RETURN     all  --  0.0.0.0/0            0.0.0.0/0           
    DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:80 to:172.17.0.2:80
    DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:48080 to:172.17.0.3:48080

### Docker Networking West-East flow

可为每个项目配置各自的Bridge（>=v1.10）


    vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta$ docker network create --driver=bridge --subnet=172.29.0.0/24 lnmp 
    e65c6afeff2fdf8360909302bad479510758bbc70a61f1974155a35b0cb6d2d9

那么，加上前述缺省的legacy bridge


    vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta$ docker network ls -f driver=bridge
    NETWORK ID          NAME                DRIVER              SCOPE
    04558f242dd9        bridge              bridge              local
    e65c6afeff2f        lnmp                bridge              local

内置的DNS：在127.0.0.11

之前的docker0的机制与该自定义有不同

配置2个bridge上的container实现通信，使用虚接口，如

    
    ip link add veth0 type veth peer name veth1
    ifconfig veth0 up
    ifconfig veth1 up
    brctl addif br0 veth0
    brctl addif br1 veth1

使用`docker network connect/disconnect`命令为容器分配多个网络
    
## 网络窥视

### Docker网络

可以发现Docker的Bridge

可以检查Bridge之间的虚接口

逆向呈现： 还原docker engine中bridge和容器之间的拓扑图

Docker network的数据类型： JSON


    vagrant@ubuntu-bionic:/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta$ docker network inspect bridge lnmp
    [
        {
            "Name": "bridge",
            "Id": "04558f242dd96f2febbfb78f5377f11e675a48952da1270a737f6cdc7b16fe27",
            "Created": "2019-12-07T13:04:33.571369357Z",
            "Scope": "local",
            "Driver": "bridge",
            "EnableIPv6": false,
            "IPAM": {
                "Driver": "default",
                "Options": null,
                "Config": [
                    {
                        "Subnet": "172.17.0.0/16"
                    }
                ]
            },
            "Internal": false,
            "Attachable": false,
            "Ingress": false,
            "ConfigFrom": {
                "Network": ""
            },
            "ConfigOnly": false,
            "Containers": {
                "4d0e46ce2bfd9cfcdee1ba2ff914a083c092123ff1ad3620e7505d8e2310e9a1": {
                    "Name": "gofileserver",
                    "EndpointID": "728fbf1f4f04cef0d70570f5d605dd272dbb63336adfe5605ae16feb448d39d5",
                    "MacAddress": "02:42:ac:11:00:03",
                    "IPv4Address": "172.17.0.3/16",
                    "IPv6Address": ""
                },
                "ba104ce9f4e85b02529da07c393da3a2c38f8324529f98280d35328a4faad222": {
                    "Name": "mynginx1",
                    "EndpointID": "6012de9b6e2867ba1142b38c59671026039ef03e93904c1af749e00bd7d6b34e",
                    "MacAddress": "02:42:ac:11:00:02",
                    "IPv4Address": "172.17.0.2/16",
                    "IPv6Address": ""
                }
            },
            "Options": {
                "com.docker.network.bridge.default_bridge": "true",
                "com.docker.network.bridge.enable_icc": "true",
                "com.docker.network.bridge.enable_ip_masquerade": "true",
                "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
                "com.docker.network.bridge.name": "docker0",
                "com.docker.network.driver.mtu": "1500"
            },
            "Labels": {}
        },
        {
            "Name": "lnmp",
            "Id": "e65c6afeff2fdf8360909302bad479510758bbc70a61f1974155a35b0cb6d2d9",
            "Created": "2019-12-07T17:15:34.98211425Z",
            "Scope": "local",
            "Driver": "bridge",
            "EnableIPv6": false,
            "IPAM": {
                "Driver": "default",
                "Options": {},
                "Config": [
                    {
                        "Subnet": "172.29.0.0/24"
                    }
                ]
            },
            "Internal": false,
            "Attachable": false,
            "Ingress": false,
            "ConfigFrom": {
                "Network": ""
            },
            "ConfigOnly": false,
            "Containers": {},
            "Options": {},
            "Labels": {}
        }
    ]
    
### Linux Bridge

基于Libvirt的hypervisor使用Linux Bridge，可参考

  https://wiki.libvirt.org/page/Networking
  
逆向呈现： 还原Linux Host中Linux Bridge和VM之间的拓扑图

数据类型，Libvirt采用XML

### Open vSwitch

TBD

### 研发路线图

__Docker网络__

语言： Golang

Reference Manual： https://github.com/moby/moby/tree/master/api/types

__Linux Bridge__

语言： Golang

Reference Manual：

- https://github.com/libvirt/libvirt-go
- https://github.com/libvirt/libvirt-go-xml
- 或 https://github.com/digitalocean/go-libvirt
- 和 https://github.com/digitalocean/go-qemu

__OpenVSwitch__

Golang

- https://github.com/digitalocean/go-openvswitch
- https://github.com/weaveworks/go-odp

__Linux Kernel net__

语言： Golang

Reference Manual：
- Golang SDK：https://github.com/golang/go/tree/master/src/net
- and https://github.com/golang/net

## 网络嗅探

在南北向各Gateway的dummy接口上偷窥网络数据报

主流开发库：
- libpcap：https://www.tcpdump.org/
- PF_RING：https://www.ntop.org/guides/pf_ring/

开发语言：Golang

参考手册：
- https://github.com/google/gopacket
- Netlink： https://github.com/mdlayher/netlink
- Netfilter： https://github.com/ti-mo/netfilter

### 实验数据

Docker示例环境

[docker-network.md.txt](../docker-network.md.txt)


使用Pcap从Linux kernel抓包

实验选择在docker0， 或容器的veth，或VM的网卡上进行

[gopacket.md.txt](../gopacket.md.txt)

1. 使用AF_PACKET接口以zero-copy的方式从socket上读取数据报 － http://man7.org/linux/man-pages/man7/packet.7.html
2. ARP解析ip地址到mac地址 － https://www.veracode.com/security/arp-spoofing
3. 使用pcap抓包 － https://github.com/sofwerx/pcas/wiki/PCAS-Project-Pcap-File-Analysis-Guide
4. 使用pfring抓包 - https://www.ntop.org/guides/pf_ring/
