# 普通安装

+ 下载安装包：https://redis.io/download

# docker安装

## 基础搭建

```shell
    # 拉取镜像
    $ docker pull redis

    # 新建需要挂载的文件夹或文件
    cd /usr/local
    mkdir redis
    cd redis
    mkdir data

    # 设置端口映射
    $ vi /etc/sysconfig/iptables
    # 添加3306端口
    -A INPUT -p tcp --dport 6379 -j ACCEPT
    # 重启iptables
    $ systemctl restart iptables.service


    # 启动redis
    docker run --name myRedis -p 6379:6379 --restart=on-failure:3 -v /usr/local/redis/data:/data -d redis redis-server --appendonly yes

    # 以后启动
    $ docker start CONTAINER_ID
```

## 集群搭建

### 基于redis cluster方式（官方推出，但是不推荐在生产中使用）

```shell
    # 创建自定义network
    $ docker network create net2 --subnet=172.19.0.1/24 --gateway=172.19.0.1

    # 在/usr/local下创建文件夹redis-cluster
    $ mkdir redis-cluster

    # 创建模版配置文件
    $ touch redis-cluster.tmpl

    # 添加以下内容

    masterauth 123456
    requirepass 123456
    protected-mode no
    port ${PORT}
    daemonize no
    appendonly yes
    cluster-enabled yes
    cluster-config-file nodes.conf
    cluster-node-timeout 15000
    cluster-announce-port ${PORT}
    cluster-announce-bus-port 1${PORT}

    # 参数解释
    (1）port（端口号）
    (2）masterauth（设置集群节点间访问密码，跟下面一致）
    (3）requirepass（设置redis访问密码）
    (4）cluster-enabled yes（启动集群模式）
    (5）cluster-config-file nodes.conf（集群节点信息文件）
    (6）cluster-node-timeout 5000（redis节点宕机被发现的时间）
    (7）cluster-announce-ip（集群节点的汇报ip，防止nat，预先填写为网关ip后续需要手动修改配置文件）
    (8）cluster-announce-port（集群节点的汇报port，防止nat）
    (9）cluster-announce-bus-port（集群节点的汇报bus-port，防止nat

    # 生成6个文件夹，分别是6个redis服务的conf和data的挂载文件，对应端口从7010-7015
    for port in `seq 7010 7015`; do \
    mkdir -p ./${port}/conf \
    && PORT=${port} envsubst < ./redis-cluster.tmpl > ./${port}/conf/redis.conf \
    && mkdir -p ./${port}/data; \
    done

    # 创建6个redis的容器，网络使用docker的host模式，执行完成之后redis容器与宿主机共享相同IP
    for port in `seq 7010 7015`; do \
        docker run -d -p ${port}:${port} -p 1${port}:1${port} \
        -v /usr/local/redis-cluster/${port}/conf/redis.conf:/usr/local/etc/redis/redis.conf \
        -v /usr/local/redis-cluster/${port}/data:/data \
        --restart always --name redis-${port} --net host \
        redis redis-server /usr/local/etc/redis/redis.conf;
    done

    # 配置集群（进入其中任意一个redis容器内，执行以下命令）
    redis-cli --cluster create 宿主机IP:7010 宿主机IP:7011 宿主机IP:7012 宿主机IP:7013 宿主机IP:7014 宿主机IP:7015 --cluster-replicas 1 -a 123456

    # 验证集群，如果提示需要输入密码则：auth userpassword
    redis-cli -c -a 123456 -h 宿主机IP -p 对应端口

    # 开放端口供外部链接,删除filter表中所有的规则，暂时使用这个方法，相当于关闭防火墙
    $ sudo iptables -F
```

