# PriorityBlockingQueue

## 概述

+ 排序时机分为两次
   + 插入 - put/add/offer 对应使用 siftUpComparable 排序方法；
	   + 每当加入一个元素 , 与当前队列队首元素compareTo比较 , 根据返回值决定是否排到队首（只能保证队首的元素是最小的或是最大的，根据自定义的compareTo()方法的返回值）
   + 弹出 - poll(remove)/take 对应使用 siftDownComparable 排序方法；
	   + 调用 dequeue 方法直接弹出队首元素 , 由于插入时保证队首永远为 compareTo 为1 的元素即符合判断顺序的元素 , siftDownComparable 方法使用建立最小堆的算法做元素重排序 （保证队首的元素是最小的或是最大的，根据自定义的compareTo()方法的返回值）
+ 因为是无界队列（可以一直入列，不存在队列满负荷的现象），所以不需要阻塞

## 构造方法

```java
    /**
     * Creates a {@code PriorityBlockingQueue} with the default
     * initial capacity (11) that orders its elements according to
     * their {@linkplain Comparable natural ordering}.
     */
    public PriorityBlockingQueue() {
        this(DEFAULT_INITIAL_CAPACITY, null);
    }

    /**
     * Creates a {@code PriorityBlockingQueue} with the specified
     * initial capacity that orders its elements according to their
     * {@linkplain Comparable natural ordering}.
     *
     * @param initialCapacity the initial capacity for this priority queue
     * @throws IllegalArgumentException if {@code initialCapacity} is less
     *         than 1
     */
    public PriorityBlockingQueue(int initialCapacity) {
        this(initialCapacity, null);
    }

    /**
     * 可以传入自定义的比较器Comparator
     */
    public PriorityBlockingQueue(int initialCapacity,
                                 Comparator<? super E> comparator) {
        if (initialCapacity < 1)
            throw new IllegalArgumentException();
        this.lock = new ReentrantLock();
        this.notEmpty = lock.newCondition();
        this.comparator = comparator;
        this.queue = new Object[initialCapacity];
    }

    /**
     * 创建一个{@code PriorityBlockingQueue}，其中包含指定集合中的元素。
     * 如果指定的集合是{@link SortedSet}或{@link PriorityQueue}，这个优先级队列将按照相同的顺序排序。
     * 否则，这个优先队列将根据其元素的{@linkplain Comparable natural ordered}排序。
     *
     * @param  c the collection whose elements are to be placed
     *         into this priority queue
     * @throws ClassCastException if elements of the specified collection
     *         cannot be compared to one another according to the priority
     *         queue's ordering
     * @throws NullPointerException if the specified collection or any
     *         of its elements are null
     */
    public PriorityBlockingQueue(Collection<? extends E> c) {
        this.lock = new ReentrantLock();
        this.notEmpty = lock.newCondition();
        boolean heapify = true; // true if not known to be in heap order
        boolean screen = true;  // true if must screen for nulls
        if (c instanceof SortedSet<?>) {
            SortedSet<? extends E> ss = (SortedSet<? extends E>) c;
            this.comparator = (Comparator<? super E>) ss.comparator();
            heapify = false;
        }
        else if (c instanceof PriorityBlockingQueue<?>) {
            PriorityBlockingQueue<? extends E> pq =
                (PriorityBlockingQueue<? extends E>) c;
            this.comparator = (Comparator<? super E>) pq.comparator();
            screen = false;
            if (pq.getClass() == PriorityBlockingQueue.class) // exact match
                heapify = false;
        }
        Object[] a = c.toArray();
        int n = a.length;
        // If c.toArray incorrectly doesn't return Object[], copy it.
        if (a.getClass() != Object[].class)
            a = Arrays.copyOf(a, n, Object[].class);
        if (screen && (n == 1 || this.comparator != null)) {
            for (int i = 0; i < n; ++i)
                if (a[i] == null)
                    throw new NullPointerException();
        }
        this.queue = a;
        this.size = n;
        if (heapify)
            heapify();
    }
```

## 核心方法

### 入队

+ 底层采用二叉堆
+ 提供了add(E e)、put(E e)、offer(E e)、offer(E e, long timeout, TimeUnit unit)（unit参数未被使用），但是最终调用的都是offer(E e)方法，不阻塞
+ offer(E e)
```java
    /**
     * Inserts the specified element into this priority queue.
     * As the queue is unbounded, this method will never return {@code false}.
     *
     * @param e the element to add
     * @return {@code true} (as specified by {@link Queue#offer})
     * @throws ClassCastException if the specified element cannot be compared
     *         with elements currently in the priority queue according to the
     *         priority queue's ordering
     * @throws NullPointerException if the specified element is null
     */
    public boolean offer(E e) {
        // 判断是否为null
        if (e == null)
            throw new NullPointerException();
        // 获取重入锁
        final ReentrantLock lock = this.lock;
        lock.lock();
        int n, cap;
        Object[] array;
        // 判断是否需要扩容
        while ((n = size) >= (cap = (array = queue).length))
            tryGrow(array, cap);
        try {
            Comparator<? super E> cmp = comparator;
            // 根据比较器是否为null，做不同的处理
            if (cmp == null)
                // 调用被插入对象内部自定义的 compareTo() 方法
                siftUpComparable(n, e, array);
            else
                // 调用在新建队列时出入的比较器
                siftUpUsingComparator(n, e, array, cmp);
            size = n + 1;
            // 唤醒正在等待的消费者线程
            notEmpty.signal();
        } finally {
            lock.unlock();
        }
        return true;
    }
    
    /**
     * 调用被插入对象内部自定义的 compareTo() 方法
     *
     * @param k the position to fill
     * @param x the item to insert
     * @param array the heap array
     */
    private static <T> void siftUpComparable(int k, T x, Object[] array) {
        Comparable<? super T> key = (Comparable<? super T>) x;
        // 二叉堆"上冒"的过程，k = 0 表示根节点
        while (k > 0) {
            // 获取父节点，因为底层采用二叉堆
            // 父节点的节点位置在n处，那么其左孩子节点为：2 * n + 1 ，其右孩子节点为2 * (n + 1)，其父节点为（n - 1） / 2 处
            int parent = (k - 1) >>> 1;
            Object e = array[parent];
            // 调用被插入对象内部自定义的 compareTo() 方法
            if (key.compareTo((T) e) >= 0)
                break;
            array[k] = e;
            k = parent;
        }
        array[k] = key;
    }
    
    /**
     * 调用在新建队列时出入的比较器
     *
     * 
     */
    private static <T> void siftUpUsingComparator(int k, T x, Object[] array,
                                       Comparator<? super T> cmp) {
        // 二叉堆"上冒"的过程，k = 0 表示根节点
        while (k > 0) {
            int parent = (k - 1) >>> 1;
            Object e = array[parent];
            if (cmp.compare(x, (T) e) >= 0)
                break;
            array[k] = e;
            k = parent;
        }
        array[k] = x;
    }
```

### 出队

+ 提供了poll()、take()、poll(long timeout, TimeUnit unit)等方法，最终调用 dequeue() 进行出队，永远都是第一个元素
```java
    /**
     * Mechanics for poll().  Call only while holding lock.
     */
    private E dequeue() {
        int n = size - 1;
        if (n < 0)
            // 没有元素时则返回null
            return null;
        else {
            Object[] array = queue;
            // 出队元素
            E result = (E) array[0];
            E x = (E) array[n];
            array[n] = null;
            Comparator<? super E> cmp = comparator;
            // 堆顶的最小值被弹出了，堆顶变成了空节点，用数组最后的节点填充到堆顶，然后依次与左右节点中最小值进行对比，判断是否需要“下沉”
            if (cmp == null)
                // 调用被插入对象内部自定义的 compareTo() 方法
                siftDownComparable(0, x, array, n);
            else
                // 调用在新建队列时出入的比较器
                siftDownUsingComparator(0, x, array, n, cmp);
            size = n;
            return result;
        }
    }
    
    /**
     * Inserts item x at position k, maintaining heap invariant by
     * demoting x down the tree repeatedly until it is less than or
     * equal to its children or is a leaf.
     *
     * @param k the position to fill
     * @param x the item to insert
     * @param array the heap array
     * @param n heap size
     */
    private static <T> void siftDownComparable(int k, T x, Object[] array,
                                               int n) {
        if (n > 0) {
            Comparable<? super T> key = (Comparable<? super T>)x;
            // half最后一个有子节点的父节点下标
            int half = n >>> 1;           // loop while a non-leaf
            while (k < half) {
                int child = (k << 1) + 1; // assume left child is least
                Object c = array[child];
                int right = child + 1;
                if (right < n &&
                    ((Comparable<? super T>) c).compareTo((T) array[right]) > 0)
                    // 比较出左右子节点更小的那个子节点
                    c = array[child = right];
                // 如果左右子节点的最小值大于数组末尾的值，那么数组末尾的值直接放到父节点，空节点下沉结束
                if (key.compareTo((T) c) <= 0)
                    break;
                // 如果子节点最小值小于数据末尾的值，子节点上浮到父空节点
                array[k] = c;
                // 空节点下滑到最小子节点的位置
                k = child;
            }
            // 最后空节点填充数组最后的值
            array[k] = key;
        }
    }
```

### 扩容

```java
    /**
     * Tries to grow array to accommodate at least one more element
     * (but normally expand by about 50%), giving up (allowing retry)
     * on contention (which we expect to be rare). Call only while
     * holding lock.
     *
     * @param array the heap array
     * @param oldCap the length of the array
     */
    // 尝试扩展数组以容纳至少一个元素(但通常扩展约50%)
    private void tryGrow(Object[] array, int oldCap) {
        // 扩容操作使用自旋，不需要锁主锁，释放
        lock.unlock(); // must release and then re-acquire main lock
        Object[] newArray = null;
        if (allocationSpinLock == 0 &&
            UNSAFE.compareAndSwapInt(this, allocationSpinLockOffset,
                                     0, 1)) {
            try {
                int newCap = oldCap + ((oldCap < 64) ?
                                       (oldCap + 2) : // grow faster if small
                                       (oldCap >> 1));
                if (newCap - MAX_ARRAY_SIZE > 0) {    // possible overflow
                    int minCap = oldCap + 1;
                    if (minCap < 0 || minCap > MAX_ARRAY_SIZE)
                        throw new OutOfMemoryError();
                    newCap = MAX_ARRAY_SIZE;
                }
                if (newCap > oldCap && queue == array)
                    newArray = new Object[newCap];
            } finally {
                // 扩容后allocationSpinLock = 0 代表释放了自旋锁
                allocationSpinLock = 0;
            }
        }
        // 到这里如果是本线程扩容newArray肯定是不为null，为null就是其他线程在处理扩容，那就让给别的线程处理
        if (newArray == null) // back off if another thread is allocating
            Thread.yield();
        // 主锁获取锁
        lock.lock();
        // 数组复制
        if (newArray != null && queue == array) {
            queue = newArray;
            System.arraycopy(array, 0, newArray, 0, oldCap);
        }
    }
```

