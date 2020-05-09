# 线性表

## LinkedList（链式存储）

经典的双链表结构, 适用于乱序插入, 删除. 指定序列操作则性能不如ArrayList, 这也是其数据结构决定的.

+ add

![1](./pic/20190517095614423.gif)

+ remove

![2](./pic/20190517095632120.gif)

+ get

![3](./pic/20190517095645372.gif)

## ArrayList（顺序存储）

+ add

![4](./pic/20190517095707349.gif)

+ remove

![5](./pic/20190517095720646.gif)

+ 扩容

![6](./pic/20190517095734755.gif)

# 栈

## Stack

+ push

![7](./pic/2019051709580974.gif)

+ pop

![8](./pic/2019051709582698.gif)

# 队列

## ArrayBlockingQueue

+ put

![9](./pic/20190517095841432.gif)

![10](./pic/20190517095854120.gif)

+ take

![11](./pic/20190517095906151.gif)

# 哈希表

## HashMap

+ put（元素hash值不相同）

![12](./pic/20190517095919639.gif)

+ put（hash值相同）

![13](./pic/20190517095933669.gif)

+ resize 动态扩容

![14](./pic/20190517095946579.gif)

## LinkedHashMap

+ put

![15](./pic/20190517095959996.gif)

+ get

![16](./pic/20190517100013605.gif)

+ removeEldestEntry（删除最古老的元素）

![17](./pic/20190517100030678.gif)

# 参考博客
+ 动画来源：https://www.cnblogs.com/xdecode/p/9321848.html