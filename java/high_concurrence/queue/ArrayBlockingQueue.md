# ArrayBlockingQueue

## 内部类



## 属性

```java
    // 存储队列元素的数组(环形数组)
    final Object[] items;

    // 拿数据的索引，用于take，poll，peek，remove方法
    int takeIndex;

    // 放数据的索引，用于put，offer，add方法
    int putIndex;

    // 元素个数
    int count;

    // 可重入锁
    final ReentrantLock lock;
    // notEmpty条件对象，由lock创建
    private final Condition notEmpty;
    // notFull条件对象，由lock创建
    private final Condition notFull;

```

## 构造函数

```java
    /**
     * Creates an {@code ArrayBlockingQueue} with the given (fixed)
     * capacity and default access policy.
     *
     * @param capacity the capacity of this queue
     * @throws IllegalArgumentException if {@code capacity < 1}
     */
    public ArrayBlockingQueue(int capacity) {
        // 默认构造非公平锁的阻塞队列
        this(capacity, false);
    }

    /**
     * Creates an {@code ArrayBlockingQueue} with the given (fixed)
     * capacity and the specified access policy.
     *
     * @param capacity the capacity of this queue
     * @param fair if {@code true} then queue accesses for threads blocked
     *        on insertion or removal, are processed in FIFO order;
     *        if {@code false} the access order is unspecified.
     * @throws IllegalArgumentException if {@code capacity < 1}
     */
    public ArrayBlockingQueue(int capacity, boolean fair) {
        if (capacity <= 0)
            throw new IllegalArgumentException();
        this.items = new Object[capacity];
        // 初始化ReentrantLock重入锁，出队入队拥有这同一个锁 
        // fair表示公平锁（true）或非公平锁（false）
        lock = new ReentrantLock(fair);
        // 初始化非空等待队列
        notEmpty = lock.newCondition();
        // 初始化非满等待队列
        notFull =  lock.newCondition();
    }

    /**
     * Creates an {@code ArrayBlockingQueue} with the given (fixed)
     * capacity, the specified access policy and initially containing the
     * elements of the given collection,
     * added in traversal order of the collection's iterator.
     *
     * @param capacity the capacity of this queue
     * @param fair if {@code true} then queue accesses for threads blocked
     *        on insertion or removal, are processed in FIFO order;
     *        if {@code false} the access order is unspecified.
     * @param c the collection of elements to initially contain
     * @throws IllegalArgumentException if {@code capacity} is less than
     *         {@code c.size()}, or less than 1.
     * @throws NullPointerException if the specified collection or any
     *         of its elements are null
     */
    public ArrayBlockingQueue(int capacity, boolean fair,
                              Collection<? extends E> c) {
        this(capacity, fair);

        final ReentrantLock lock = this.lock;
        lock.lock(); // Lock only for visibility, not mutual exclusion
        try {
            int i = 0;
            try {
                // 判断是否包含空元素
                for (E e : c) {
                    checkNotNull(e);
                    items[i++] = e;
                }
            } catch (ArrayIndexOutOfBoundsException ex) {
                throw new IllegalArgumentException();
            }
            count = i;
            putIndex = (i == capacity) ? 0 : i;
        } finally {
            lock.unlock();
        }
    }
```

## 核心方法

### 入队（关键方法enqueue(E x)）

入队	| add(e)	| offer(e)	| offer(e, time, unit)	| put(e)
:-: | :-: | :-: | :-: | :-:
返回值	 |  队列未满时，返回true；队列满则抛出IllegalStateException(“Queue full”)异常——AbstractQueue  	|  队列未满时，返回true；队列满时返回false。非阻塞立即返回。	 |  设定等待的时间，如果在指定时间内还不能往队列中插入数据则返回false，插入成功返回true。 |  	队列未满时，直接插入没有返回值；队列满时会阻塞等待，一直等到队列未满时再插入。

+  add(E e)

```java
     /**
      * Inserts the specified element at the tail of this queue if it is
      * possible to do so immediately without exceeding the queue's capacity,
      * returning {@code true} upon success and throwing an
      * {@code IllegalStateException} if this queue is full.
      *
      * @param e the element to add
      * @return {@code true} (as specified by {@link Collection#add})
      * @throws IllegalStateException if this queue is full
      * @throws NullPointerException if the specified element is null
      */
     public boolean add(E e) {
         // 调用父类 AbstractQueue 的 add 方法
         return super.add(e);
     }
     
     /**
      * AbstractQueue.java
      * 这是一个模板方法，只定义add入队算法骨架，成功时返回true，
      * 失败时抛出IllegalStateException异常，具体offer实现交给子类实现。
      */
     public boolean add(E e) {
         // 走ArrayBlockingQueue的 offer() 具体实现
         if (offer(e))
             return true;
         else
             throw new IllegalStateException("Queue full");
     }
```

+ offer(E e)

```java
    /**
     * 在队尾插入一个元素，
     * 如果队列没满，立即返回true；
     * 如果队列满了，立即返回false
     * 注意：该方法通常优于add(),因为add()失败直接抛异常
     *
     * @throws NullPointerException if the specified element is null
     */
    public boolean offer(E e) {
        checkNotNull(e);
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            // 判断队列是否已满
            if (count == items.length)
                return false;
            else {
                enqueue(e);
                return true;
            }
        } finally {
            lock.unlock();
        }
    }
```

+ offer(E e, long timeout, TimeUnit unit)

```java
    /**
     * 阻塞提交，超时返回false
     */
    public boolean offer(E e, long timeout, TimeUnit unit)
        throws InterruptedException {

        checkNotNull(e);
        long nanos = unit.toNanos(timeout);
        final ReentrantLock lock = this.lock;
        lock.lockInterruptibly();
        try {
            while (count == items.length) {
                if (nanos <= 0)
                    return false;
                // 这里是使用同步队列器的超时机制，在nanos的时间范围内，方法会在这里堵塞，
                // 超过这个时间段nanos的值会被赋值为负数，方法继续，
                // 然后在下一个循环返回false。这个标志是未满标志，队列里面未满就可以放进元素嘛。然后判断成功就是一个入队列操作
                nanos = notFull.awaitNanos(nanos);
            }
            enqueue(e);
            return true;
        } finally {
            lock.unlock();
        }
    }
```

+ put(E e)
```java
    /**
     * 队列未满时，直接插入没有返回值；
     * 队列满时会阻塞等待，一直等到队列未满时再插入。
     *
     */
    public void put(E e) throws InterruptedException {
        checkNotNull(e);
        final ReentrantLock lock = this.lock;
        lock.lockInterruptibly();
        try {
            // 一直阻塞，直到可以入队
            while (count == items.length)
                notFull.await();
            enqueue(e);
        } finally {
            lock.unlock();
        }
    }
```

+ enqueue(E x)

```java
    /**
    * 入队列操作，因为putIndex已经是当前该放入元素的下标了，放入元素之后，
    * 需要将putIndex+1，并且元素数量加1。然后直接调用非空标志通知等待中的消费者
    * 质疑：如果我没有等待中的消费者，那也要通知，那不是浪费么？
    * 解释：下端代码是signal的实现
    * public final void signal() {
    *             if (!isHeldExclusively())
    *                 throw new IllegalMonitorStateException();
    *                 Node first = firstWaiter;
    *                     if (first != null)
    *                         doSignal(first)
    * }
    * signal方法已经在里面已经对队列的首元素判断空，不通知了，
    * 这个引起我的一个思考，确实在函数里面就应该对这些条件做判断要比外面判断更好一些，一个是更健壮，一个是更友好，但是这个最小作用模块还是功能模块，别一个调用链做了多次的这种条件的判断，这就让阅读者难受了。
    */
    private void enqueue(E x) {
        final Object[] items = this.items;
        // 把当前元素插入到数组中去
        items[putIndex] = x;
        // 从这里可以判度出items是环形数组
        if (++putIndex == items.length)
            putIndex = 0;
        count++;
        // 唤醒在notEmpty条件上等待的线程 
        notEmpty.signal();
    }
```

### 出队（核心方法dequeue()）

出队	|   remove(Object o)	|   poll()	|   take()	|   poll(long timeout, TimeUnit unit)
:-: | :-: | :-: | :-: | :-:
返回值	|   如果队列包含指定元素并删除后则返回true	|   返回特殊值（如果队列为空则返回null，否则返回出队的元素本身）	|   一直阻塞（一直阻塞到取出元素为止）	|   超时退出（在指定时间内阻塞取出元素，超时返回null）

+ remove(Object o)

```java
    /**
     * 
     * 如果队列包含指定元素并删除后则返回true
     * 
     */
    public boolean remove(Object o) {
        if (o == null) return false;
        //获取数组数据
        final Object[] items = this.items;
        final ReentrantLock lock = this.lock;
        lock.lock();//加锁
        try {
            //如果此时队列不为null，这里是为了防止并发情况
            if (count > 0) {
                //获取下一个要添加元素时的索引
                final int putIndex = this.putIndex;
                //获取当前要被删除元素的索引
                int i = takeIndex;
                //执行循环查找要删除的元素
                do {
                    //找到要删除的元素
                    if (o.equals(items[i])) {
                        removeAt(i);//执行删除
                        return true;//删除成功返回true
                    }
                    //当前删除索引执行加1后判断是否与数组长度相等
                    //若为true，说明索引已到数组尽头，将i设置为0
                    if (++i == items.length)
                        i = 0; 
                } while (i != putIndex);//继承查找
            }
            return false;
        } finally {
            lock.unlock();
        }
    }
```

+ poll()

```java
    /**
     * 
     * 返回特殊值（如果队列为空则返回null，否则返回出队的元素本身）
     * 
     */
    public E poll() {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            return (count == 0) ? null : dequeue();
        } finally {
            lock.unlock();
        }
    }
```

+ take()

```java
    /**
     * 
     * 一直阻塞到取出元素为止
     * 
     */
    public E take() throws InterruptedException {
        final ReentrantLock lock = this.lock;
        lock.lockInterruptibly();
        try {
            while (count == 0)
                notEmpty.await();
            return dequeue();
        } finally {
            lock.unlock();
        }
    }
```

+ poll(long timeout, TimeUnit unit)

```java
   /**
    * 
    * 超时退出（在指定时间内阻塞取出元素，超时返回null）
    *
    */
    public E poll(long timeout, TimeUnit unit) throws InterruptedException {
        long nanos = unit.toNanos(timeout);
        final ReentrantLock lock = this.lock;
        lock.lockInterruptibly();
        try {
            while (count == 0) {
                if (nanos <= 0)
                    return null;
                nanos = notEmpty.awaitNanos(nanos);
            }
            return dequeue();
        } finally {
            lock.unlock();
        }
    }
```

+ dequeue()

```java
    /**
     * 出队列操作，跟入队列操作正好是相反的，多了一个清理操作
     */
    private E dequeue() {
        // assert lock.getHoldCount() == 1;
        // assert items[takeIndex] != null;
        final Object[] items = this.items;
        @SuppressWarnings("unchecked")
        E x = (E) items[takeIndex];
        items[takeIndex] = null;
        if (++takeIndex == items.length)
            takeIndex = 0;
        count--;
        if (itrs != null)
            // 因为元素的出队列所以清理和这个元素相关联的迭代器
            itrs.elementDequeued();
        notFull.signal();
        return x;
    }
```

## 参考博客

- https://www.cnblogs.com/WangHaiMing/p/8798709.html
- https://blog.csdn.net/wx_vampire/article/details/79585794