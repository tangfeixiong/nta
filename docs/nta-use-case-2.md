# 需求分析 - 操作系统实例和服务实例  
  
## Use Case  
  
网络用网卡 (Eth或vEth) 把计算 (物理机/虚拟机, 甚至Docker容器) 连在一起， 当然也把本来都是孤立的操作系统连在了一起  
  
操作系统通过网卡驱动和网络栈（Link Layer和Internet Layer）使Packet(报文)在vEth之间流动， 提供Socket, Connection, Dial等开发库使流动的数据分组（Segment，如根据TCP和UDP协议）， 并正确发到那个Eth/vEth，只接收该接收的 (Transport Layer)。 而具体对传输API进行编程的是应用程序所使用的框架: 如Tomcat, PHP内建的Server, Nginx等等。 而只有RPC应用开发者才需要直接对传输层提供的API进行编程。  
  
Eth/vEth和OS系统自然是多对一的关系， 因为虚拟机和容器可以有多个网卡  
  
### 操作系统实例  
  
1. 如Mac系统  
  
可以通过`ifconfig`工具查看Eth, 和虚拟交换机vSwitch  
```  
fanhonglingdeMacBook-Pro:ctf-java fanhongling$ ifconfig  
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384  
 options=3<RXCSUM,TXCSUM> inet6 ::1 prefixlen 128   inet 127.0.0.1 netmask 0xff000000   
   inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1   
   nd6 options=1<PERFORMNUD>  
gif0: flags=8010<POINTOPOINT,MULTICAST> mtu 1280  
stf0: flags=0<> mtu 1280  
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500  
 ether ac:bc:32:7c:3c:37   inet6 fe80::aebc:32ff:fe7c:3c37%en0 prefixlen 64 scopeid 0x4   
   inet 192.168.1.87 netmask 0xffffff00 broadcast 192.168.1.255  
 nd6 options=1<PERFORMNUD> media: autoselect status: activeen1: flags=8963<UP,BROADCAST,SMART,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 1500  
 options=60<TSO4,TSO6> ether 4a:00:02:5b:e4:80   media: autoselect <full-duplex>  
 status: inactiveen2: flags=8963<UP,BROADCAST,SMART,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 1500  
 options=60<TSO4,TSO6> ether 4a:00:02:5b:e4:81   media: autoselect <full-duplex>  
 status: inactivep2p0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> mtu 2304  
 ether 0e:bc:32:7c:3c:37   media: autoselect  
 status: inactiveawdl0: flags=8943<UP,BROADCAST,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 1452  
 ether 32:65:1e:31:9f:7f   inet6 fe80::3065:1eff:fe31:9f7f%awdl0 prefixlen 64 scopeid 0x8   
   nd6 options=1<PERFORMNUD>  
 media: autoselect status: activebridge0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500  
 options=63<RXCSUM,TXCSUM,TSO4,TSO6> ether ae:bc:32:c7:f4:00   Configuration:  
 id 0:0:0:0:0:0 priority 0 hellotime 0 fwddelay 0 maxage 0 holdcnt 0 proto stp maxaddr 100 timeout 1200 root id 0:0:0:0:0:0 priority 0 ifcost 0 port 0 ipfilter disabled flags 0x2 member: en1 flags=3<LEARNING,DISCOVER> ifmaxaddr 0 port 5 priority 0 path cost 0 member: en2 flags=3<LEARNING,DISCOVER> ifmaxaddr 0 port 6 priority 0 path cost 0 nd6 options=1<PERFORMNUD> media: <unknown type> status: inactivevboxnet0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> mtu 1500  
 ether 0a:00:27:00:00:00   inet 172.17.4.1 netmask 0xffffff00 broadcast 172.17.4.255  
vboxnet1: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> mtu 1500  
 ether 0a:00:27:00:00:01   inet 172.28.128.1 netmask 0xffffff00 broadcast 172.28.128.255  
```  
  
1. 如Linux上  
  
还可以通过IP Route2工具分别查看Link Layer， Internet Layer更广泛的信息  
```  
TBD  
```  
  
而Linux工具brctl可以查看内核中存在的vEth和vSwitch  
```  
TBD  
```  
  
当然也可以使用其它工具, 如docker cli专门查看Docker所使用的虚拟交换机vSwitch  
```  
TBD  
```  
  
如ovsctl专门查看OpenVSwitch所使用的虚拟交换机vSwitch  
```  
TBD  
```  
  
### 服务实例  
  
操作系统上需要安装服务， 如MySQL， 如Tomcat等等， 使基础设施用到生产中去。  
  
在云计算中， 理想情况是每个虚拟机， 每个容器只运行一个服务  
  
1. 但是技术人员会安装多个服务到虚拟机  
  
为了远程shell登录， 一般都会安装sshd服务  
  
_TBD_  
  
为了远程登录操作系统的图形界面， 一般都换安装VNC服务   
  
_TBD_  
  
或者RDP服务  
  
_TBD_  
  
1. Packet中以Port来鉴别数据报属于哪个服务  
  
尽管多个服务在使用同一个块Eth或vEth， 但是每个数据包都可以正确地交给属于其服务去处理， 因为有如TCP/IP协议， 或UDP/IP协议， 没个packet的报头都有port，索引到具体的一个服务  
```  
--- Layer 1 ---  
Ethernet   {Contents=[..14..] Payload=[..46..] SrcMAC=00:19:5b:27:b6:9e DstMAC=ac:bc:32:7c:3c:37 EthernetType=IPv4 Length=0}  
00000000  ac bc 32 7c 3c 37 00 19  5b 27 b6 9e 08 00        |..2|<7..['....|  
--- Layer 2 ---  
IPv4   {Contents=[..20..] Payload=[..20..] Version=4 IHL=5 TOS=0 Length=40 Id=40146 Flags= FragOffset=0 TTL=48 Protocol=TCP Checksum=37619 SrcIP=143.202.10.144 DstIP=192.168.0.8 Options=[] Padding=[]}  
00000000  45 00 00 28 9c d2 00 00  30 06 92 f3 8f ca 0a 90  |E..(....0.......|  
00000010  c0 a8 00 08                                       |....|  
--- Layer 3 ---  
TCP    {Contents=[..20..] Payload=[] SrcPort=54779 DstPort=22(ssh) Seq=3722285333 Ack=0 DataOffset=5 FIN=false SYN=true RST=false PSH=false ACK=false URG=false ECE=false CWR=false NS=false Window=50122 Checksum=19464 Urgent=0 Options=[] Padding=[]}  
00000000  d5 fb 00 16 dd dd 91 15  00 00 00 00 50 02 c3 ca  |............P...|  
00000010  4c 08 00 00                                       |L...|  
```  
  
因此， 一个port不能分属多个服务  
  
1. 但是多个port可以只属一个服务  
  
如redis服务， 它同时使用port 6379， 16379， 26379  
  
### 多个服务实例形成一个服务集群

服务的高可用已经十分普及

1. MySQL Galera

这是多主模式 (active-active)下的3个MariaDB， 没个示例是一台物理机/vm， 甚至Docker容器
![Related image](https://3.bp.blogspot.com/-KRzgcGQ3RNM/Vt02mx-2mtI/AAAAAAAAN8c/sICHppGqG1E/s1600/mariadb-europe-roadshow-2015-galera-cluster-40-new-features-3-638.jpg)

当然， 有可能会给它加一个VIP

![Image result for mariadb galera](https://blog.cloudandheat.com/wp-content/uploads/2016/09/galera_haproxy_vrrp.png)

1. Redis Sentinel

Redis Sentinel是多主的Sentinel和主从模式(active-standby)的集群

![Image result for redis sentinel](https://i.stack.imgur.com/CHHzq.png)

同样， 如果愿意， 也可以加Load Balancer

1. RabbitMQ

例如

![Image result for rabbitmq clustering](https://cdn.levvel.io/blog_content/Message-Simulator-Cluster-Node-Failure.png)

1. 其它基于一致性算法的集群

如[RAFT](https://raft.github.io/#implementations)

1. 还有

如[Zookeeper](https://cwiki.apache.org/confluence/display/ZOOKEEPER/Zab+vs.+Paxos)

如ElasticSearch等等

### 同样Web Server也可以组成集群

如使用Nginx反向代理

![Image result for nginx load balancing](https://udaraliyanage.files.wordpress.com/2014/06/15062014.jpg)

或多个Nginx用VRRP做HA

当然LB可以使用硬件F5

## Product resolving

如果使用了VM/Docker Container， 那么这些服务究竟是属于哪个应用呢

1. 以博客系统wordpress为例

简单地， 能否让技术人员形象地看到LB， web， db和FS的服务之间的关系

![Image result for wordpress deployment](https://assets.digitalocean.com/articles/automate_wp_cluster/wp-cluster.png)

## Technology 

1. 服务发现

如果使用了Kubernetes编排， 或Spring-Cloud-Netflix 微服务架构， 可以通过访问Service Registry API发现服务

![Image result for service discovery](https://image.slidesharecdn.com/servicediscoveryopensourcemeetupapril162016-160417092151/95/service-discovery-using-etcd-consul-and-kubernetes-6-638.jpg?cb=1460885346)


### 应用管理

应用由多个服务组成， 如tomcat 和 mariadb， 如lnmp中的nginx和mysql

应用中的Web Server会有多个服务示例， 同样DB Server也会有多个实例

大多数情况下， 应用中的Web Server部署时会使用Load Balancer服务， 或者说Reverse Proxy服务

> Written with [StackEdit](https://stackedit.io/).
<!--stackedit_data:
eyJoaXN0b3J5IjpbMTkyODM1NTUxLC0yMDQ1NDk4NzYxLDE2Mz
UyMjE0MjAsLTE5OTIzNzcxNzMsLTExMjE3ODA0NTAsMzgyNjMy
NTQ2LDE5MjgzODg5MDEsLTk0NDc4MDIwNSwxODM0NzQyODA4XX
0=
-->