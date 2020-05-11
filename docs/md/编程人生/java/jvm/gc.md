# 垃圾回收

## 安全点

在设置 JVM 参数时，本着多多益善的原则，我们可能会加上如下的配置

```java
-XX:+PrintGCApplicationStoppedTime
-XX:+PrintGCApplicationConcurrentTime
-XX:+PrintGCDetails
```

这样会在 gc 日志中产生大量的内容，例如：

```java
2018-08-21T13:40:39.636+0800: 328.169: Application time: 0.0000533 seconds
2018-08-21T13:40:39.636+0800: 328.169: Total time for which application threads were stopped: 0.0001573 seconds, Stopping threads took: 0.0000241 seconds
2018-08-21T13:40:39.636+0800: 328.169: Application time: 0.0000910 seconds
2018-08-21T13:40:39.636+0800: 328.170: Total time for which application threads were stopped: 0.0001603 seconds, Stopping threads took: 0.0000223 seconds
```

这些内容的上下也许看不到任何和 GC 相关的日志，那么这些日志是什么呢？

从参数名字上来看，会觉得上述参数是和 GC 相关的，其实不然。这里前两个参数的打开实际上是负责记录所有的安全点，而不只是 GC 暂停；第三个参数确和 GC 有关。如果非要和 GC 扯上关系的话，那么 GC 日志前会有Appliction time: xxx seconds，而后面会有Total time for which ...，也就是说，这两条语句把 GC 打的日志包裹了起来，这些有助于帮助分析 GC 日志，例如下面：

```java
2018-08-21T13:40:43.501+0800: 332.034: Application time: 0.5838027 seconds
{Heap before GC invocations=3 (full 1):
 par new generation   total 2184576K, used 1795001K [0x0000000680000000, 0x0000000720000000, 0x0000000720000000)
  eden space 1747712K, 100% used [0x0000000680000000, 0x00000006eaac0000, 0x00000006eaac0000)
  from space 436864K,  10% used [0x0000000705560000, 0x000000070838e5b0, 0x0000000720000000)
  to   space 436864K,   0% used [0x00000006eaac0000, 0x00000006eaac0000, 0x0000000705560000)
 concurrent mark-sweep generation total 2621440K, used 165820K [0x0000000720000000, 0x00000007c0000000, 0x00000007c0000000)
 Metaspace       used 67048K, capacity 68642K, committed 68736K, reserved 1110016K
  class space    used 8241K, capacity 8546K, committed 8576K, reserved 1048576K
2018-08-21T13:40:43.502+0800: 332.036: [GC (Allocation Failure) 332.036: [ParNew
Desired survivor size 223674368 bytes, new threshold 15 (max 15)
- age   1:   63634632 bytes,   63634632 total
- age   2:    1064928 bytes,   64699560 total
- age   3:   24489776 bytes,   89189336 total
: 1795001K->92332K(2184576K), 0.1389036 secs] 1960821K->258153K(4806016K), 0.1390975 secs] [Times: user=0.37 sys=0.16, real=0.14 secs]
Heap after GC invocations=4 (full 1):
 par new generation   total 2184576K, used 92332K [0x0000000680000000, 0x0000000720000000, 0x0000000720000000)
  eden space 1747712K,   0% used [0x0000000680000000, 0x0000000680000000, 0x00000006eaac0000)
  from space 436864K,  21% used [0x00000006eaac0000, 0x00000006f04eb3f0, 0x0000000705560000)
  to   space 436864K,   0% used [0x0000000705560000, 0x0000000705560000, 0x0000000720000000)
 concurrent mark-sweep generation total 2621440K, used 165820K [0x0000000720000000, 0x00000007c0000000, 0x00000007c0000000)
 Metaspace       used 67048K, capacity 68642K, committed 68736K, reserved 1110016K
  class space    used 8241K, capacity 8546K, committed 8576K, reserved 1048576K
}
2018-08-21T13:40:43.642+0800: 332.175: Total time for which application threads were stopped: 0.1406530 seconds, Stopping threads took: 0.0008240 seconds
```

从上段日志可以得知，应用程序在前 0.5838027秒是在处理实际工作的，然后所有应用线程暂停了 0.1406530秒，其中等待所有应用线程到达安全点用了 0.0008240秒。而暂停这 0.1406530秒，实际上用在了GC上，可以看到 GC 花费的时间 real=0.14 secs，和应用线程暂停的时间相对应。这样看来，似乎这些日志用处不是很大。然而，作为这一小节的主角，它还是有一些用处的，那就是分析安全点。

其实，程序进入安全点不只是在 GC 的时候，不同的 JIT 活动，偏向锁擦除，特定的 JVMTI 操作，这些都会导致程序暂停进入安全点。所以会发现这些安全点的日志特别多，而打印安全点日志就是为了发现触发安全点是否存在异常和优化的空间，尽管可能只花费了几十毫秒，但是如今大量并发的时代，这几十毫秒意味着很大的性能浪费与不友好。

加上如下这组 JVM 参数：

```java
-XX:+PrintSafepointStatistics
-XX:+PrintSafepointStatisticsCount=1
```

该配置会将额外的信息输出到日志中，类似下面这样：

```java
5.141: RevokeBias [ 13  0  2 ]  [ 0  0  0  0  0 ]  0 
Total time for which application threads were stopped: 0.0000782 seconds, Stopping threads took: 0.0000269 seconds
```

这里可以看到，多了上面一行日志，那分别都表示什么呢？

+ JVM 启动后所经历的毫秒数（5.141）
+ 触发这次 STW 的操作名是 RevokeBias，如果看到是 no vm operation，就说明这是一个“保证安全点”。JVM 默认会每秒触发一次安全点来处理那些非紧急的排队操作。
+ 停在安全点的线程数量（13）
+ 在安全点开始时仍在运行的线程数量（0）
+ 虚拟机操作开始执行前仍处于阻塞状态的线程数量（2）
+ 到达安全点时各个阶段以及执行操作所花的时间（0）

> -XX:GuaranteedSafepointInterval=0 可以关闭第二点提到的保证安全点；-XX:GuaranteedSafepointInterval=1000 则表示 1秒触发一次

> 第二个括号里很多个 0，网上找了一段解释：This part is the most interesting. It tells us how long (in milliseconds) the VM spun waiting for threads to reach the safepoint. Second, it lists how long it waited for threads to block. The third number is the total time waiting for threads to reach the safepoint (spin + block + some other time). Fourth, is the time spent in internal VM cleanup activities. Fifth, is the time spent in the operation itself.

> DEBUGGING JVM SAFEPOINT PAUSES

> 而最后一个 0，说是 page_trap_count，暂时还不清楚是什么意思

最后，推荐知乎上讲解 SafePoint 的帖子，用于帮助排查 STW 时间过长的问题，总结起来，就是分析 safepoint 的四个阶段：Spin，Block，Cleanup，VM Operation 陈亮的回答

至此，安全点分析告一段落。

## gc打印控制参数

```java
-verbose:gc
-XX:+PrintGC
-XX:+PrintGCDetails
-XX:+PrintGCDateStamps
-XX:+PrintGCTimeStamps
-XX:+PringHeapAtGC
-XX:+PrintTenuringDistribution
```

大体上列出了这么多和打印 gc 日志相关的东西，这些是工作中常用的。

### -XX:+PrintGC

一般要打印出 gc 日志，需要基本的配置：``` -verbose:gc ```和 ``` -XX:+PrintGC ```，这两个没有什么区别，一般采用后者。形式如下：

```java
[GC 246656K->243120K(376320K), 0.0929090 secs]
[Full GC 243120K->241951K(629760K), 1.5589690 secs]
```

前面是类型，分为 ``` GC ``` 和 ``` Full GC ```，以及堆大小的变化，耗费的时间。可以看到，这里并看不出是用的什么垃圾回收器，也不了解 ``` Young 区 ```和 ``` Old 区 ```的内存情况，更不能判断垃圾回收器是否将一些对象从 ``` Young 区 ```转到了 ``` Old 区 ```。

### -XX:+PrintGCDetails

相比于 ``` PrintGC ``` 选项，这个会打印出更详细的日志。在这个选项的模式下，日志的格式和使用的算法相关。例如

```java
[GC [PSYoungGen: 142816K->10752K(142848K)] 246648K->243136K(375296K), 0.0935090 secs]
[Times: user=0.55 sys=0.10, real=0.09 secs]
```
从日志中可以看到所用的垃圾回收器，以及 ``` Young GC ``` 的作用，整个 ``` Young 区 ```的大小，回收后缩到了多少，整个堆的空间大小，以及变化情况，也能推出 ``` Old 区 ```的大小，甚至可以推出有多少对象从 ``` Young 区 ```转移到 ``` Old 区 ```。同时，从 Times 中可以得知在垃圾收集线程和操作系统调用和等待系统事件所使用的时间（所有线程所花时间的总和），以及真实的时间，进而得知是否使用了多线程做了垃圾回收，这里可以看到，真实时间是远小于前两者的，实际上用了 8个线程。

再看一下 Full GC 的日志：

```java
[Full GC[PSYoungGen: 10752K->9707K(142848K)][ParOldGen: 232384K->232244K(485888K)] 243136K->241951K(628736K)[PSPermGen: 3162K->3161K(21504K)], 1.5265450 secs]
```

这里可以看到 Young 和 Old 回收器，以及 ``` Young 区 ```和 ``` Old 区 ```的大小以及变化，同时还可以看到永久代的大小以及变化，这是 1.7 以下的 JDK 版本。后续的时间没有列出，和上面贴出的 Young GC 日志类似，同样可以看到那三个参数。

同时，Full GC 可以显式的触发，可以通过应用程序或者其他命令，这种日志的开头会是Full GC(System),

### -XX:+PrintGCTimeStamps & -XX:+PrintGCDateStamps

使用这两个可以将时间和日期加到 GC 日志中。

```java
2018-08-21T13:40:41.916+0800: 330.450: Total time for which application threads were stopped: 0.0013163 seconds, Stopping threads took: 0.0000636 seconds
2018-08-21T13:40:42.917+0800: 331.450: Application time: 1.0001349 seconds
```

还是这个例子，``` 2018-08-21T13:40:41.916+0800: ``` 是通过 PrintGCDateStamps 加入的，而 330.450 是通过 PrintGCTimeStamps 加入的，前者负责打印当前的时间，后者表示 JVM 启动至今所经过的时间

### -XX:+PrintHeapAtGC

如果我们设置了参数 -server -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:+PrintHeapAtGC -XX:+PrintTenuringDistribution 参数，这里可以看到使用了 ParNew 作为 ``` Young 区 ```的收集器，使用 CMS 作为 Old 区的收集器，同时启用了 PrintHeapAtGC 参数。打印出了如下的日志：

```java
{Heap before GC invocations=3 (full 1):
 par new generation   total 2184576K, used 1795001K [0x0000000680000000, 0x0000000720000000, 0x0000000720000000)
  eden space 1747712K, 100% used [0x0000000680000000, 0x00000006eaac0000, 0x00000006eaac0000)
  from space 436864K,  10% used [0x0000000705560000, 0x000000070838e5b0, 0x0000000720000000)
  to   space 436864K,   0% used [0x00000006eaac0000, 0x00000006eaac0000, 0x0000000705560000)
 concurrent mark-sweep generation total 2621440K, used 165820K [0x0000000720000000, 0x00000007c0000000, 0x00000007c0000000)
 Metaspace       used 67048K, capacity 68642K, committed 68736K, reserved 1110016K
  class space    used 8241K, capacity 8546K, committed 8576K, reserved 1048576K

// 这部分不属于 PrintHeapAtGC 打印的，稍后再讲  
 
2018-08-21T13:40:43.502+0800: 332.036: [GC (Allocation Failure) 332.036: [ParNew
Desired survivor size 223674368 bytes, new threshold 15 (max 15)
- age   1:   63634632 bytes,   63634632 total
- age   2:    1064928 bytes,   64699560 total
- age   3:   24489776 bytes,   89189336 total
: 1795001K->92332K(2184576K), 0.1389036 secs] 1960821K->258153K(4806016K), 0.1390975 secs] [Times: user=0.37 sys=0.16, real=0.14 secs]


Heap after GC invocations=4 (full 1):
 par new generation   total 2184576K, used 92332K [0x0000000680000000, 0x0000000720000000, 0x0000000720000000)
  eden space 1747712K,   0% used [0x0000000680000000, 0x0000000680000000, 0x00000006eaac0000)
  from space 436864K,  21% used [0x00000006eaac0000, 0x00000006f04eb3f0, 0x0000000705560000)
  to   space 436864K,   0% used [0x0000000705560000, 0x0000000705560000, 0x0000000720000000)
 concurrent mark-sweep generation total 2621440K, used 165820K [0x0000000720000000, 0x00000007c0000000, 0x00000007c0000000)
 Metaspace       used 67048K, capacity 68642K, committed 68736K, reserved 1110016K
  class space    used 8241K, capacity 8546K, committed 8576K, reserved 1048576K
}
```

如果设置了 ``` PrintHeapAtGC ``` 参数，则 HotSpot 在 GC 前后都会将 GC 堆的概要信息输出出来。Heap before GC 和 Heap after GC 分别表示 GC 前后堆的信息的开始，invocations 表示 GC 的次数，可以看到 后面跟了个 invocations，这里 invocations 表示总的 GC 次数，可以发现在 after 之后，invocations 自增了，而 full 表示第几次 Full GC。 invocations 会随着系统运行一直自增下去，通过这些信息可以很轻松的统计出一段时间的 GC 次数。再看下面的日志，可以看到年轻代和老年代所使用的垃圾回收器，以及各自的情况。其中新生代 par new generation 表示使用 ParNew 作为垃圾回收器，一共 2184576 K 大小，使用了 1795001 K 大小。其中 eden 区已经满了，from survivor 用了 10%，to survivor 用了 0%，每个后面都跟了内存地址，头一个表示起始地址，第二个表示当前用到的最大地址，第三个表示终止地址。观察 before 和 after，细心点可以观察到 from 和 to 的地址对调了，可以看到回收一次后 from 从 10% 涨到了 21%。紧跟着 par new generation 后面的是 concurrent mark-sweep generation，总共的量，使用的量，地址可以清楚的看到，后面跟着的三个参数同样是起止地址，而第二个和第三个是相同的。此外还给出了 Metaspace 的使用情况，以及 class space 的使用情况。这两个值初始会比较小，在使用过程中会容量会逐步扩大。

### -XX:+PrintTenuringDistribution

这个参数是负责打印新生代到老年代晋升的情况。我们需要知道，我们是可以通过 MaxTenuringThreshold 参数控制对象从新生代晋升到老年代经过 GC 次数的最大值，这个默认值是 15，而最大值也是 15，因为对象头里给了 4个 bit 存放，只能表示 15 以内的整数。这个参数并非能达到绝对控制，比如晋升失败会导致对象原地不动，如果 survival 区不够大，可能直接放到老年代。再看它所输出的信息：

```java
2018-08-21T13:40:43.502+0800: 332.036: [GC (Allocation Failure) 332.036: [ParNew
Desired survivor size 223674368 bytes, new threshold 15 (max 15)
- age   1:   63634632 bytes,   63634632 total
- age   2:    1064928 bytes,   64699560 total
- age   3:   24489776 bytes,   89189336 total
: 1795001K->92332K(2184576K), 0.1389036 secs] 1960821K->258153K(4806016K), 0.1390975 secs] [Times: user=0.37 sys=0.16, real=0.14 secs]
```

好吧，接着看，GC 的触发条件给出了， Allocation Failure，也就是分配内存失败了，这时候 survivor 所期待的大小是 223674368 字节，最大的年代数是 15，当前 age1 有 63634632 字节，age2 有 1064928 字节，age3 有 24489776 字节，total 是当前加起来的总和。后续跟的和 PrintGCDetail 类似，有各个区的内存变化，以及所用的时间，这里不再多做解释。

```java
2013-10-19T19:46:30.244+0800: 169797.045: [GC2013-10-19T19:46:30.244+0800:
169797.045: [ParNew
Desired survivor size 87359488 bytes, new threshold 4 (max 4)
- age   1:   10532656 bytes,   10532656 total
- age   2:   14082976 bytes,   24615632 total
- age   3:   15155296 bytes,   39770928 total
- age   4:   13938272 bytes,   53709200 total
: 758515K->76697K(853376K), 0.0748620 secs] 4693076K->4021899K(6120832K),
0.0756370 secs] [Times: user=0.42 sys=0.00, real=0.07 secs]
2013-10-19T19:47:10.909+0800: 169837.710: [GC2013-10-19T19:47:10.909+0800:
169837.711: [ParNew
Desired survivor size 87359488 bytes, new threshold 4 (max 4)
- age   1:    9167144 bytes,    9167144 total
- age   2:    9178824 bytes,   18345968 total
- age   3:   16101552 bytes,   34447520 total
- age   4:   21369776 bytes,   55817296 total
: 759449K->63442K(853376K), 0.0776450 secs] 4704651K->4020310K(6120832K),
0.0783500 secs] [Times: user=0.43 sys=0.00, real=0.07 secs]
```

这是他粘贴的日志，可以看到第二次 GC 后，原先的 age 1 从 10532656 降到了 age 2 的 91788824，这是可以理解的，因为一部分可能只存活了一代就销毁了。而关于 age 2 晋升到 age 3 就很奇怪了，因为它涨了。给出的解释是：在把对象拷贝到 survivor 区或者 ``` Old 区 ```时，一些线程会竞争，而每个线程在竞争时就会增加一代，这是一个 bug。。。不知道有没有最终被修复。

### -Xloggc

缺省的 GC 日志是输出到终端的，使用 -Xloggc 可以输出到指定文件，

### 可管理的 JVM 参数

在 JVM 运行时，一些参数是可以动态的去修改的，用于打印出来更详细的参数。所有以 PrintGC 开头的都是可管理的参数。这样在任何时候都可以开启和关闭 GC 日志。比如我们可以用 JDK 自带的 jinfo 工具来设置这些参数，或者是通过 JMX 客户端调用 HotSpotDiagnostic MXBean 的 setVMOptions 方法来设置这些参数。

### 查看 JVM 参数

jinfo -flag <参数名> PID

例如：jinfo -flag MaxMetaspaceSize 18348

### 调整 JVM 参数

布尔类型：jinfo -flag [+|-]<参数名> PID
数字、字符串类型：jinfo -flag <参数名>=<值> PID

### 查看所有支持动态修改的 JVM 参数

java -XX:+PrintFlagsInitial | grep manageable

## 垃圾回收器日志解读
前面介绍了基本的 gc 日志打印配置项以及日志内容，根据上述内容相信可以看懂大部分的 gc 日志了。然而，不同的 GC 算法所打印的日志也有一定区别，尤其是 CMS 的日志内容（这里没有对 G1 做分析，因为还没有实际使用过 G1）相对来说更为难懂，涉及到的配置参数也很多。所以这里暂不对其他的垃圾回收器的日志做详细介绍，而是直接看 CMS 的日志。如果想要了解，可以看以下几个示例：

SerialGC 垃圾回收器的日志解读
ParNewGC 垃圾回收器的日志解读
垃圾收集器日志格式的基本介绍
CMS 日志解读

下面贴出了 CMS 一次垃圾回收的日志，这里只 grep 了 CMS 相关的日志，其余的没有展示。

```java
// 初始标记（STW）
2018-08-21T13:35:33.467+0800: 22.000: [GC (CMS Initial Mark) [1 CMS-initial-mark: 165823K(2621440K)] 213112K(4806016K), 0.0150297 secs] [Times: user=0.04 sys=0.00, real=0.01 secs]

// 并发标记
2018-08-21T13:35:33.482+0800: 22.015: [CMS-concurrent-mark-start]
2018-08-21T13:35:33.509+0800: 22.042: [CMS-concurrent-mark: 0.027/0.027 secs] [Times: user=0.21 sys=0.00, real=0.03 secs]

// 并发预清理
2018-08-21T13:35:33.509+0800: 22.042: [CMS-concurrent-preclean-start]
2018-08-21T13:35:33.517+0800: 22.050: [CMS-concurrent-preclean: 0.009/0.009 secs] [Times: user=0.01 sys=0.00, real=0.01 secs]
2018-08-21T13:35:33.517+0800: 22.050: [CMS-concurrent-abortable-preclean-start]
 CMS: abort preclean due to time 2018-08-21T13:35:38.914+0800: 27.447: [CMS-concurrent-abortable-preclean: 4.213/5.397 secs] [Times: user=4.42 sys=0.09, real=5.40 secs]

// 重新标记（STW）
2018-08-21T13:35:38.915+0800: 27.448: [GC (CMS Final Remark) [YG occupancy: 106747 K (2184576 K)]27.448: [Rescan (parallel) , 0.0186754 secs]27.467: [weak refs processing, 0.0379073 secs]27.505: [class unloading, 0.0410018 secs]27.546: [scrub symbol table, 0.0120421 secs]27.558: [scrub string table, 0.0015368 secs][1 CMS-remark: 165823K(2621440K)] 272571K(4806016K), 0.1168714 secs] [Times: user=0.12 sys=0.05, real=0.11 secs]

// 并发清除
2018-08-21T13:35:39.032+0800: 27.565: [CMS-concurrent-sweep-start]
2018-08-21T13:35:39.175+0800: 27.708: [CMS-concurrent-sweep: 0.143/0.143 secs] [Times: user=0.10 sys=0.23, real=0.15 secs]

// 并发重置
2018-08-21T13:35:39.175+0800: 27.708: [CMS-concurrent-reset-start]
2018-08-21T13:35:39.220+0800: 27.753: [CMS-concurrent-reset: 0.045/0.045 secs] [Times: user=0.06 sys=0.08, real=0.04 secs]
```

1. 初始标记：多线程，user 和 real 可以看出。老年代容量 2621440K，已经占用 165823K，整个堆的大小 4806016K，使用了 213112K。暂停应用线程，睡了 0.01秒
2. 并发标记，7个线程
3. 并发预清理，至到Eden区占用量达到 ``` CMSScheduleRemarkEdenPenetration ``` (默认50%)，或达到5秒钟。但是如果ygc在这个阶段中没有发生的话，是达不到理想效果的。此时可以指定CMSMaxAbortablePrecleanTime，但是，等待一般都不是什么好的策略，可以采用 ``` CMSScavengeBeforeRemark ```，使remark之前发生一次ygc，从而减少remark阶段暂停的时间。
4. 重新标记，STW 时间最长的阶段，可以看到和之前初始标记结果一样
5. 并发清除，只看时间
6. 并发重置，为下次 CMS 做准备，只看时间

## JVM 配置示例

```java
除了要看懂 gc 日志，还有另一个方面需要了解，进而分析内容，那就是 JVM 配置。配置一般可分为：内存划分；垃圾收集器配置；日志打印；jvm 其他相关配置。在这里给出一个 JVM 配置示例。

// 1. 内存大小分配
// - 堆大小
-XX:InitialHeapSize=5368709120
-XX:MaxHeapSize=5368709120
// - 新生代大小
-XX:NewSize=2684354560
-XX:MaxNewSize=2684354560
// -- survivor 大小
-XX:SurvivorRatio=4
// - 方法区大小
-XX:MetaspaceSize=134217728
-XX:MaxMetaspaceSize=268435456

// 2. 垃圾回收器
// - 新生代
-XX:+UseParNewGC
// - 老年代
-XX:+UseConcMarkSweepGC
// -- 允许并发标记，降低标记过程的停顿
-XX:+CMSParallelRemarkEnabled
// -- 并发线程数
-XX:ConcGCThreads=8
// -- 预留空间，超过这个比例就会触发 Full GC，设置过大可能导致 Concurrent Mode Failure，进而触发 Serial Old GC，记得那张图吗？CMS 是可以和 Serial Old 联合使用的，后者作为备选方案
-XX:CMSInitiatingOccupancyFraction=80
// -- 上述情况不触发 GC，而是开启内存碎片整理，合并过程无法并发，时间比较长
-XX:+UseCMSCompactAtFullCollection
// -- 与上面配合使用，执行多少次不压缩的 Full GC 后来一次压缩整理，如果为 0 则表示每次都不压缩
-XX:CMSFullGCsBeforeCompaction=0
// -- 让 CMS 对永久代进行回收
-XX:+CMSClassUnloadingEnabled
// -- 允许触发 Full GC，与 CMS 联合使用（一些 NIO 框架会使用对外内存，显式的调用 System.gc，进而影响服务性能，如果禁用，那么堆外内存就一直无法回收，开启的话，影响性能，于是提供了这个参数和 CMS 配合使用，使得 Full GC 性能更快）
-XX:+ExplicitGCInvokesConcurrent
// 疑问，听说过 TLAB，没听过 PLAB，PLAB 是晋升本地分配缓冲，是垃圾回收清理数据时基于线程分配的分区，应更是用于提升 CMS 效率的一个参数，进阶调优知识
-XX:OldPLABSize=16

// 3. 打印控制
// - 基本控制
-XX:+PrintGCDetails
-XX:+PrintGCDateStamps
-XX:+PrintGCTimeStamps
// - 堆信息（before after）
-XX:+PrintHeapAtGC
// - 年代分布
-XX:+PrintTenuringDistribution
// - 安全点
-XX:+PrintGCApplicationConcurrentTime
-XX:+PrintGCApplicationStoppedTime

// 4. 其他
// - 压缩类指针
-XX:+UseCompressedClassPointers
// - 压缩对象
-XX:+UseCompressedOops
```