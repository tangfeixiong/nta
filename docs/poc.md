# POC

## Technology

### Service Discovery

应用， 往往由前端的Web Server， 中间件如Redis， AMQP， ESB等， 数据库如MySQL等不同的服务组成

Web Server是HTTP服务器， 如Tomcat, Nignx

Redis, AMQP则是TCP或UDP服务。 ESB如Weblogic, Tomcat, 或RPC服务器, 既有L7, 也可能是L4

MySQL等数据库是TCP服务器

__服务地址与服务发现的区别__

服务可以使用internet协议规范的ip地址和TCP/UDP端口来唯一标识。 当一个应用或服务交付部署后， 其ip地址和端口就确定了。

如果一个应用和服务进行迁移， 进行迭代升级， 其标识就发生了改变， 如新的ip地址

在高可用， 弹性扩展， 尤其微服务， 云计算环境中，为了解决人为操作的复杂性和不确定性。 在DevOps领域中发展了服务发现技术

1. 传统的DNS

    使用DNS可以实现服务发现， 每一个服务都有对应的域名， 因此， 无论应用和服务的ip地址改变与否， 不影响服务之间, 应用和服务之间通过域名访问 
    
    传统的dns需要数据中心管理员进行手动配置
    
2. 负载均衡

    负载均衡器也提供服务的发现， 在高可用场景下， 每个服务有很多个实例组成， 即每个实例有各自的ip地址和端口。
    
    通常由数据中心管理员使用反向代理技术， 使用VIP映射到多个实例上
    
3. 微服务框架

    为了保证产品的持续集成和持续交付， 在开发中发展出微服务框架， 以可编程的方式集成服务发现到应用中。 如spring cloud， netflix OSS， 技术上使用app name作为应用和服务之间的标识， 运行框架维护app name和服务地址的相关性
    
4. 云计算的编排

    由编排系统来实现服务的发现， 无论是什么样的应用和服务， 通过编排的DSL语言， 可以使应用和服务之间发现彼此的服务地址。 如AWS的cloud formation, Openstack的heat， kubernetes
    
5. DNS的服务化
    
    或云化， 在云计算中方便应用和服务弹性扩展， 而又符合组合习惯
    
    kubernetes提供kube-dns组件， 或者可选cncf的coredns组件，为Service， Endpoints资源提供内部域名
    
__为企业开发服务发现的必要性__
    
国家电网冀北电力在信息化项目可行性研究报告中指出: _现有传统工具在资源池环境中适应性不足， 具体表现为无法获取资源池全量以及无法理解资源位置等问题_

因此， 如果对应用和服务进行了服务统一发现管理， 就可以使后续的网络交通流量提供精细化管理


### Networking Resource Configuration Management

从IaaS的角度看， 网络资源包括 网络， 子网， 交换机， 安全组， 以及路由器等

从数据中心的角度， 网络接入网络和骨干网络之分， 有边缘路由， 和VLAN

从应用的历史遗留看， 网络既有基于硬件的， 也有基于软件的， 如KVM上用linux bridge虚拟交换机的virbr0, OpenVSwitch的ovsbr0等等

因公的服务端口在云计算中由安全组配置管理， 也可能直接由硬件防火墙， 或软件iptables配置管理

1. 网络设备

    即OSI模型的物理层。 现代计算机网络基本都是由交换机（物理的或虚拟的）和接口（interface）, 网卡（物理的或虚拟的）组成

    管理物理层资源， 对发现上层网络架构和网络拓扑是有意义的

2. Link层

    数据中心通常是基于VLAN的以太网络（Ethernet）

    管理链路层资源， 如MAC地址管理， 对发现数据帧(Frame)， 或发现网络（ARP）有一定的意义

3. Internet层

    即网络层。 该层是发现整个网络， 子网的拓扑的基础

    首先， 该层的网络配置往往是通过物理设备的配置工具管理， 如3层交换机， 路由器

    而在云计算环境中， 则由IaaS中的网络组件来管理， 如Openstack的Neutron， CNCF的cni等等

    在Internet层， 需要对ip协议， icmp协议的packet或datagram进行sniffer， 以发现网络交通状况

4. Transport层

    传输层。 在即大多数情况下， 是对TCP和UDP的数据报文的分组（Segment）进行嗅探和跟踪

    通过分组中报头的源地址和端口， 以及目标地址和端口， 发现应用和服务的网络交通

5. Application层

    或OSI模型的传输层以上， 是应用和服务软件实现的网络规则。 也是数据中心管理中最重要的环节。

    如在IaaS， 由Security Group来管理虚拟的防火墙， 唯一指定服务可被访问的具体网络， 或具体应用

    在有些场景中， 则由数据中心管理人员人为操作操作系统的防火墙软件， 如iptables。 或第三方工具。

    在历史遗留环境中， 则是通过硬件防火墙设备

__为企业提供网络资源配置管理的必要性__
    
国家电网冀北电力在信息化项目可行性研究报告中指出: _冀北公司现在没有相关系统对资源池整体网络进行运维， 只能通过人工手动操作完成复杂操作_

因此， 如果对网络资源进行必要的配置管理， 有助于为用户在实际生产环境中， 对网络的分析提供确实可行的支撑


### Traffic Analysis

分析网络交通， 一般需要通过调用操作系统的开发接口库

如Linux下， 提供的开发库是libpcap， 而基于该开发库的工具软件是tcpdump

在windows下， 有图形化工具软件wireshark

#### 子网内的packet sniffer

假如一个应用由web, redis, mariadb组成。 web把session保存到redis， 把mariadb数据缓存到redis

上述应用使用3个linux服务器，如centos。 数据中心管理员使用一个3层交换机，为该应用划分了一个VLAN， 为linux分配了IP地址

由于3个服务器在同一个link layer， 所以， 在任一linux上， 如web服务器上， tcpdump可以在该子网上嗅探到web对redis， web对mariadb的交通数据

这是所谓的东西向流量

1. 嗅探子网和嗅探交换机

    在物理交换机上， 由于VLAN的配置， 上述因为只嗅探到子网， 所以并没有能够管理交换机上的全部交通状况
    
    但在IaaS中，交换机是虚拟机的， 并不存在设备工艺而成本的考虑， 而设计成强大的配置管理
    
### 网络之间的packet sniffer

假如上述应用需要与ESB交换数据， 而ESB作为多个应用的服务总线， 在一个独立的网络和子网里。

或者， 用户浏览器访问上述应用的web， 通过外网到边缘路由器， 再经过反向代理， 负载均衡等一系列设备， 到web的外网端口

由于上述数据所处与子网内不在同一Internet layer, 或者说这方面的交通数据不是应用组件之间（web, redis, mariadb）的交通， 而是不同应用之间 （用户的浏览器， web， 和企业的esb）的交通。 嗅探这种网络交通即所谓南北流量

1. 复杂性

    由于数据中心的设备， 管理， 人的技术行为差异等等， 每个系统环境的网络之间的sniffer以及后续的分析是十分复杂的， 对软件开发的挑战很高
    
### Traffic flow

总体上就是networking IO的速率， 以bps（每秒比特数）

不同的网络上看到的IO涵义是不一样的。 在一个子网内， 自然是该应用如从web到db的交通状况。 而在一个如IaaS的租户下， 其边缘路由器上的流量是外部网络到内部多个应用的访问流量

物理交换机上往往提供交通流量的采集接口

IaaS上， 专门有组件来提供流量的采集分析， 如Openstack的ceilometer。 CNCF的prometheus等等

要想对交通进行回溯分析， 就必须对交通数据进行历史记录。 由于网络交通是实时信息， 尤其访问和通信频率越高的应用系统。 在目前云计算时代， 使用大数据平台， 使用NoSQL数据库是交通数据存储的首选

1. Hadoop

    Hadoop HDFS是PB级分布式存储， 是主流的大数据基础设施

    HBase是建立在Hadoop之上的wide column 数据库（CAP）

    Hive是面向Hadoop的数据仓库技术

### Networking Security

应用的安全首先是网络的安全， 这往往是通过在Application Layer部署防火墙来保障

在IaaS中， 应用安全由Security Group组件来实现

应用在网络上映射为地址和端口， 因此通过packet的sniffer， 可以掌握异常使用的行为

同时， 也可以用来鉴别防火墙设置的正确与否（以分析人为操作的疏忽或错误）

### Dashboard

有关monitoring， metering的内容， 往往可以展示为time series, 图表（直方图， 折线图）

如果有相应的管理业务逻辑， 可以设置触发告警（warn）的条件， 以声， 光， 电（手机， 短信， 邮件）的方式及时通知


