# NTA项目中的产品分析-1

## Use Case

通常， Data Centre的生产环境如下图
![Image result for data center](https://9to5mac.files.wordpress.com/2017/11/data-center.jpg?quality=82&strip=all&w=1500)

但施工时， 是下图的样子：
![Related image](http://www.datacenterknowledge.com/sites/datacenterknowledge.com/files/styles/article_featured_standard/public/server%20cable%20data%20center%20generic%20getty_0.jpg?itok=xskb_KT1)

*去你公司的小机房看看有个近距离接触*

但无论如何， 负责机房管理的技术人员可以分辨出一个应用，甚至多个应用的网络连接：

1. 最简单的应用部署
一个web server和一个db server
![Image result for web server and database server](https://assets.digitalocean.com/articles/HAProxy/web_server.png)

3. 继续上例   
实际上有经验的技术人员不会把db server与web server放在同一个LAN中， 否则db就会被攻击， 因此web server需要2个LAN, db server在private LAN上:
![Image result for web server and database server](https://assets.digitalocean.com/articles/architecture/separate_database.png)

4. 当然大企业不会这么简单
因为这样的部署架构存在SPOF,  即单点故障. 而更多地会采用HA模式， 例如下， 由于web被LB如nginx代理， 所以web并没有public LAN: 
![Image result for web server and database server](http://www.patriceguay.com/wp-content/uploads/2010/03/web_cluster_and_mysql_db_cluster.png)

5. 总之组网会越来越庞大
尤其互联网系统, 会使用缓存, 消息队列等来解决IO的瓶颈， 如redis， rabbitmq等等， 如下:
![Image result for web server  redis database](https://i.stack.imgur.com/4JQ3s.png)

### 然而在云计算下

IaaS是将上述计算(compute), 网络(networking), 存储(storage)这些DC的基础设施资源进行了虚拟化:

1. 技术人员肉眼无法分辨网络的连接
2. 技术人员看不到某个应用的计算服务器的具体位置

甚至, 如果发生了故障， 可能虚拟机恢复到另一宿主机(Linux Host)上了: 
![Image result for openstack vm](http://blog.zhaw.ch/icclab/files/2014/09/migration.jpg)

## Product

### 至少能让技术人员通过web UI了解云里的一些结构

如: 虚拟网络的连接示意, 虚拟设备, 虚拟机。 在canvas上
![Image result for openstack network topology](https://ask.openstack.org/upfiles/13938656635969549.png)

使用不同的js框架就会有不同的示意图风格
![Image result for openstack network topology](https://elastx.se/sites/default/files/inline-images/network-topology_1.png)

## Technology

### 在Kubernetes上

Kubernetes是CaaS工业上的事实标准，尽管其发布才2年多， 在2017年后已成为了首选的云交付平台, 相信将迎来K8s的黄金10年. K8s采用CNI网络模型. 其中基于VxLan和UDP的Overlay结构如下: 
![Related image](https://cdn-images-1.medium.com/max/1488/1*Cix7J5w0PjhT_FknVVpkTw.png)

事实上CNI支持多种网络架构
![Image result for kubernetes cni](https://cdn-images-1.medium.com/max/1600/1*ErMHOdRWlfmqgupiHswSBw.png)

### 在OpenStack上

OpenStack是国内广泛使用的开源IaaS. 要得到上述UI背后的虚拟网络和虚拟机状态数据， 需要学习OpenStack API, 它是Restful API, 即HTTP Server。

OpenStack的网络项目是neutron，通过networking service编程访问

如下图是OpenStack Liberty版本后的架构之一, 大部分OpenStack网络也采用Overlay技术
![Related image](http://cfile2.uf.tistory.com/image/27643F45564BC2550C58CA)

而之前一直提倡的是独立网络节点的架构
![Image result for openstack neutron](https://ilearnstack.files.wordpress.com/2013/10/neutron-physnet-diagram1.png)

### 在vSphere上

VMware公司的vSphere是业界久负盛名的私有云平台, 其网络架构如下: 
![Image result for vsphere networking](https://i1.wp.com/www.myvirtualjourney.com/wp-content/uploads/2017/04/Troubleshooting-vSphere-Distributed-Switch.png?resize=558%2C367&ssl=1)

### 虚拟机和Docker容器

虚拟机和Docker容器在网络上没有本质区别， 即都是通过vEth(虚拟以太网卡)连接到交换机(vSwitch， 或直连到物理Switch)

* 虚拟机实际上与物理机在操作上没有区别, 因为vm先有操作系统, 然后需要在vm上去部署应用系统， 如tomcat， redis， mysql等服务， 当然，在云计算环境下， 一般会使用3台vm分别部署。显然， 从资源上来看是浪费的， 因为每台虚拟机需要不少cpu和内存。
* 但Docker容器则明显改变了这种传统手段， 同样， 我们也使用3个容器, 服务在制作镜像阶段时就放置好了。因此Docker技术使微服务(Micro-Services)软件开发架构迅速发展。


----------


> Written with [StackEdit](https://stackedit.io/).
<!--stackedit_data:
eyJoaXN0b3J5IjpbNzI3NTg1OTY3XX0=
-->