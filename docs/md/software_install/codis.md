# 安装go

 + 查看go版本：[https://golang.org/dl/](https://golang.org/dl/)
```shell
# 下载安装包
$ wget https://storage.googleapis.com/golang/go1.13.1.linux-amd64.tar.gz

# 解压安装包
$ tar -zxvf go1.13.1.linux-amd64.tar.gz

# 配置环境变量
$ vim /etc/profile

export GOROOT=/usr/local/go   #设置为go安装的路径
export GOPATH=/usr/local/gopath  #默认安装包的路径
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

$ source /etc/profile

# 验证是否安装成功
$ go version

$ vim hello.go

package main
    import "fmt"

    func main(){
        fmt.Printf("hello,world\n")
    }

$ go run hello.go
```

# 安装java

参考：[Centos 最小安装后 需要的操作](https://blog.csdn.net/Carty090616/article/details/99732934)

# 安装zookeeper

 + 查看版本：[http://archive.apache.org/dist/zookeeper/](http://archive.apache.org/dist/zookeeper/)
```shell
# 下载安装包
$ wget http://archive.apache.org/dist/zookeeper/zookeeper-3.5.6/apache-zookeeper-3.5.6-bin.tar.gz

# 解压
tar -zxvf apache-zookeeper-3.5.6-bin.tar.gz

# 重命名

# 拷贝配置文件
cp zoo_sample.cfg zoo.cfg

vim zoo.cfg
```

# 安装codis

https://github.com/CodisLabs/codis.git