###### open .
 + 将当前目录在finder打开

###### find
 + 根据文件的属性查找文件，如文件名、文件大小、所有者、所有组、是否为空、访问时间、修改时间等
 + 基本格式：find path expression

###### grep
 + 根据文件内容进行查找，会对文件的每一行按照给定的模式进行匹配查找
 + 基本格式：grep [options]
 + 例子：假设您正在’/usr/src/Linux/Doc’目录下搜索带字符 串’magic’的文件，就使用：grep magic /usr/src/Linux/Doc/*
 + 参考博客：http://www.cnblogs.com/end/archive/2012/02/21/2360965.html

###### ps -ef | grep
 + ps：命令将某个进程显示出来
 + grep：命令是查找
 + |：是通道命令，是指ps命令和grep命令同时执行
 + 例如执行：ps -ef | grep java，会显示如下内容：
UID   PID     PPID     C   STIME    TTY      TIME        CMD

zzw   14124   13991    0   00:38    pts/0    00:00:00    grep --color=auto dae

 + 字段解释：
UID：程序被该 UID 所拥有
PID：就是这个程序的 ID 
PPID：则是其上级父程序的ID
C：CPU使用的资源百分比
STIME：系统启动时间
TTY：登入者的终端机位置
TIME：使用掉的CPU时间。
CMD：所下达的是什么指令
