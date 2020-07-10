队列 | 有界性	| 锁	| 数据结构
:-: | :-: | :-: | :-: 
[ArrayBlockingQueue](./ArrayBlockingQueue.md)	| bounded(有界)	| 加锁	| arrayList
LinkedBlockingQueue	| optionally-bounded	| 加锁	| linkedList
[PriorityBlockingQueue](./PriorityBlockingQueue.md)	| unbounded	| 加锁	| heap
DelayQueue	| unbounded	| 加锁 |	heap
SynchronousQueue	| bounded	| 加锁 |	无
LinkedTransferQueue	| unbounded	| 加锁	| heap
LinkedBlockingDeque	| unbounded	| 无锁	| heap


+ BlockingQueue 代码

```java
public interface BlockingQueue<E> extends Queue<E> {

    //将给定元素设置到队列中，如果设置成功返回true, 否则返回false。如果是往限定了长度的队列中设置值，推荐使用offer()方法。
    boolean add(E e);

    //将给定的元素设置到队列中，如果设置成功返回true, 否则返回false。e的值不能为空，否则抛出空指针异常。
    boolean offer(E e);

    //将元素设置到队列中，如果队列中没有多余的空间，该方法会一直阻塞，直到队列中有多余的空间。
    void put(E e) throws InterruptedException;

    //将给定元素在给定的时间内设置到队列中，如果设置成功返回true, 否则返回false.
    boolean offer(E e, long timeout, TimeUnit unit)
        throws InterruptedException;

    //从队列中获取值，如果队列中没有值，线程会一直阻塞，直到队列中有值，并且该方法取得了该值。
    E take() throws InterruptedException;

    //在给定的时间里，从队列中获取值，时间到了直接调用普通的poll方法，为null则直接返回null。
    E poll(long timeout, TimeUnit unit)
        throws InterruptedException;

    //获取队列中剩余的空间。
    int remainingCapacity();

    //从队列中移除指定的值。
    boolean remove(Object o);

    //判断队列中是否拥有该值。
    public boolean contains(Object o);

    //将队列中值，全部移除，并发设置到给定的集合中。
    int drainTo(Collection<? super E> c);

    //指定最多数量限制将队列中值，全部移除，并发设置到给定的集合中。
    int drainTo(Collection<? super E> c, int maxElements);
}
```