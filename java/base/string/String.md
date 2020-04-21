# String 源码分析

## 特点

+ 基于Java 8
+ String的本质是用 char 类型的数组存储字符串中的每个字符
+ 一旦一个String对象被创建, 包含在这个对象中的字符序列是不可改变的, 包括该类后续的所有方法都是不能修改该对象的，直至该对象被销毁，这是我们需要特别注意的（该类的一些方法看似改变了字符串，其实内部都是创建一个新的字符串，下面讲解方法时会介绍）

## 属性

```java
    1     /** The value is used for character storage. */
    2     //
    3     private final char value[];
    4 
    5     /** Cache the hash code for the string */
    6     private int hash; // Default to 0
    7 
    8     /** use serialVersionUID from JDK 1.0.2 for interoperability */
    9     private static final long serialVersionUID = -6849794470754667710L;
   10 
   11     /**
   12      * Class String is special cased within the Serialization Stream Protocol.
   13      *
   14      * A String instance is written into an ObjectOutputStream according to
   15      * <a href="{@docRoot}/../platform/serialization/spec/output.html">
   16      * Object Serialization Specification, Section 6.2, "Stream Elements"</a>
   17      */
   18      // 暂时没有发现用处
   19     private static final ObjectStreamField[] serialPersistentFields =
   20         new ObjectStreamField[0];
```

## 核心方法

### equals(Object anObject) 方法

+ String 类重写了 equals 方法，比较的是组成字符串的每一个字符是否相同，如果都相同则返回true，否则返回false。

```java
    1     /**
    2      * Compares this string to the specified object.  The result is {@code
    3      * true} if and only if the argument is not {@code null} and is a {@code
    4      * String} object that represents the same sequence of characters as this
    5      * object.
    6      *
    7      * @param  anObject
    8      *         The object to compare this {@code String} against
    9      *
   10      * @return  {@code true} if the given object represents a {@code String}
   11      *          equivalent to this string, {@code false} otherwise
   12      *
   13      * @see  #compareTo(String)
   14      * @see  #equalsIgnoreCase(String)
   15      */
   16     public boolean equals(Object anObject) {
   17         // 比较内存地址是否相同
   18         if (this == anObject) {
   19             return true;
   20         }
   21         // 判断是否是String类型
   22         if (anObject instanceof String) {
   23             String anotherString = (String)anObject;
   24             int n = value.length;
   25             // 比较长度
   26             if (n == anotherString.value.length) {
   27                 char v1[] = value;
   28                 char v2[] = anotherString.value;
   29                 int i = 0;
   30                 // 循环比较每个字符
   31                 while (n-- != 0) {
   32                     if (v1[i] != v2[i])
   33                         return false;
   34                     i++;
   35                 }
   36                 return true;
   37             }
   38         }
   39         return false;
   40     }
```

### hashCode() 方法

+ String 类的 hashCode 算法很简单，主要就是中间的 for 循环，计算公式如下：
	> s[0]*31^(n-1) + s[1]*31^(n-2) + ... + s[n-1]
   + s：数组即源码中的 val 数组，也就是构成字符串的字符数组。
   + [这里有个数字 31 ，为什么选择31作为乘积因子，而且没有用一个常量来声明？主要原因有两个](./hashcode_choose_31_reason.md)：
      + 31是一个不大不小的质数，是作为 hashCode 乘子的优选质数之一。
      + 31可以被 JVM 优化，31 * i = (i << 5) - i。因为移位运算比乘法运行更快更省性能。

```java
    1     /**
    2      * Returns a hash code for this string. The hash code for a
    3      * {@code String} object is computed as
    4      * <blockquote><pre>
    5      * s[0]*31^(n-1) + s[1]*31^(n-2) + ... + s[n-1]
    6      * </pre></blockquote>
    7      * using {@code int} arithmetic, where {@code s[i]} is the
    8      * <i>i</i>th character of the string, {@code n} is the length of
    9      * the string, and {@code ^} indicates exponentiation.
   10      * (The hash value of the empty string is zero.)
   11      *
   12      * @return  a hash code value for this object.
   13      */
   14     public int hashCode() {
   15         int h = hash;
   16         if (h == 0 && value.length > 0) {
   17             char val[] = value;
   18 
   19             for (int i = 0; i < value.length; i++) {
   20                 h = 31 * h + val[i];
   21             }
   22             hash = h;
   23         }
   24         return h;
   25     }
```

### charAt(int index) 方法

```java
    1     /**
    2      * 提取字符串中指定位置的字符
    3      */
    4     public char charAt(int index) {
    5         if ((index < 0) || (index >= value.length)) {
    6             throw new StringIndexOutOfBoundsException(index);
    7         }
    8         return value[index];
    9     }
```

### compareTo(String anotherString)

+ 该方法是按字母顺序比较两个字符串，是基于字符串中每个字符的 Unicode 值。当两个字符串某个位置的字符不同时，返回的是这一位置的字符 Unicode 值之差，当两个字符串都相同时，返回两个字符串长度之差。

```java
    1     /**
    2      * Compares two strings lexicographically.
    3      * The comparison is based on the Unicode value of each character in
    4      * the strings. The character sequence represented by this
    5      * {@code String} object is compared lexicographically to the
    6      * character sequence represented by the argument string. The result is
    7      * a negative integer if this {@code String} object
    8      * lexicographically precedes the argument string. The result is a
    9      * positive integer if this {@code String} object lexicographically
   10      * follows the argument string. The result is zero if the strings
   11      * are equal; {@code compareTo} returns {@code 0} exactly when
   12      * the {@link #equals(Object)} method would return {@code true}.
   13      * <p>
   14      * This is the definition of lexicographic ordering. If two strings are
   15      * different, then either they have different characters at some index
   16      * that is a valid index for both strings, or their lengths are different,
   17      * or both. If they have different characters at one or more index
   18      * positions, let <i>k</i> be the smallest such index; then the string
   19      * whose character at position <i>k</i> has the smaller value, as
   20      * determined by using the &lt; operator, lexicographically precedes the
   21      * other string. In this case, {@code compareTo} returns the
   22      * difference of the two character values at position {@code k} in
   23      * the two string -- that is, the value:
   24      * <blockquote><pre>
   25      * this.charAt(k)-anotherString.charAt(k)
   26      * </pre></blockquote>
   27      * If there is no index position at which they differ, then the shorter
   28      * string lexicographically precedes the longer string. In this case,
   29      * {@code compareTo} returns the difference of the lengths of the
   30      * strings -- that is, the value:
   31      * <blockquote><pre>
   32      * this.length()-anotherString.length()
   33      * </pre></blockquote>
   34      *
   35      * @param   anotherString   the {@code String} to be compared.
   36      * @return  the value {@code 0} if the argument string is equal to
   37      *          this string; a value less than {@code 0} if this string
   38      *          is lexicographically less than the string argument; and a
   39      *          value greater than {@code 0} if this string is
   40      *          lexicographically greater than the string argument.
   41      */
   42     public int compareTo(String anotherString) {
   43         // 获取字符串长度
   44         int len1 = value.length;
   45         int len2 = anotherString.value.length;
   46         // 获取两个字符串间最小的长度
   47         int lim = Math.min(len1, len2);
   48         // 转换成char数组
   49         char v1[] = value;
   50         char v2[] = anotherString.value;
   51 
   52         int k = 0;
   53         // 开始循环，直到大于lim(两个字符串间最小的长度)
   54         // 如果在最小长度之内发现有char不相等，则返回当前位置两个char的ASCII码的差值
   55         // 最小长度之内没有发现不相等，则返回两个字符串长度的差值
   56         while (k < lim) {
   57             char c1 = v1[k];
   58             char c2 = v2[k];
   59             if (c1 != c2) {
   60                 return c1 - c2;
   61             }
   62             k++;
   63         }
   64         return len1 - len2;
   65     }
```

### compareToIgnoreCase(String str) 方法

+ compareToIgnoreCase() 方法在 compareTo 方法的基础上忽略大小写，我们知道大写字母是比小写字母的Unicode值小32的，底层实现是先都转换成大写比较，然后都转换成小写进行比较。

```java
    1     /**
    2      * Compares two strings lexicographically, ignoring case
    3      * differences. This method returns an integer whose sign is that of
    4      * calling {@code compareTo} with normalized versions of the strings
    5      * where case differences have been eliminated by calling
    6      * {@code Character.toLowerCase(Character.toUpperCase(character))} on
    7      * each character.
    8      * <p>
    9      * Note that this method does <em>not</em> take locale into account,
   10      * and will result in an unsatisfactory ordering for certain locales.
   11      * The java.text package provides <em>collators</em> to allow
   12      * locale-sensitive ordering.
   13      *
   14      * @param   str   the {@code String} to be compared.
   15      * @return  a negative integer, zero, or a positive integer as the
   16      *          specified String is greater than, equal to, or less
   17      *          than this String, ignoring case considerations.
   18      * @see     java.text.Collator#compare(String, String)
   19      * @since   1.2
   20      */
   21     public int compareToIgnoreCase(String str) {
   22         return CASE_INSENSITIVE_ORDER.compare(this, str);
   23     }
   24     
   25     /**
   26      * A Comparator that orders {@code String} objects as by
   27      * {@code compareToIgnoreCase}. This comparator is serializable.
   28      * <p>
   29      * Note that this Comparator does <em>not</em> take locale into account,
   30      * and will result in an unsatisfactory ordering for certain locales.
   31      * The java.text package provides <em>Collators</em> to allow
   32      * locale-sensitive ordering.
   33      *
   34      * @see     java.text.Collator#compare(String, String)
   35      * @since   1.2
   36      */
   37     public static final Comparator<String> CASE_INSENSITIVE_ORDER
   38                                          = new CaseInsensitiveComparator();
   39     private static class CaseInsensitiveComparator
   40             implements Comparator<String>, java.io.Serializable {
   41         // use serialVersionUID from JDK 1.2.2 for interoperability
   42         private static final long serialVersionUID = 8575799808933029326L;
   43 
   44         public int compare(String s1, String s2) {
   45             int n1 = s1.length();
   46             int n2 = s2.length();
   47             int min = Math.min(n1, n2);
   48             for (int i = 0; i < min; i++) {
   49                 char c1 = s1.charAt(i);
   50                 char c2 = s2.charAt(i);
   51                 if (c1 != c2) {
   52                     c1 = Character.toUpperCase(c1);
   53                     c2 = Character.toUpperCase(c2);
   54                     if (c1 != c2) {
   55                         c1 = Character.toLowerCase(c1);
   56                         c2 = Character.toLowerCase(c2);
   57                         if (c1 != c2) {
   58                             // No overflow because of numeric promotion
   59                             return c1 - c2;
   60                         }
   61                     }
   62                 }
   63             }
   64             return n1 - n2;
   65         }
   66 
   67         /** Replaces the de-serialized object. */
   68         private Object readResolve() { return CASE_INSENSITIVE_ORDER; }
   69     }
```

### concat(String str) 方法

```java
    1     /**
    2      * Concatenates the specified string to the end of this string.
    3      * <p>
    4      * If the length of the argument string is {@code 0}, then this
    5      * {@code String} object is returned. Otherwise, a
    6      * {@code String} object is returned that represents a character
    7      * sequence that is the concatenation of the character sequence
    8      * represented by this {@code String} object and the character
    9      * sequence represented by the argument string.<p>
   10      * Examples:
   11      * <blockquote><pre>
   12      * "cares".concat("s") returns "caress"
   13      * "to".concat("get").concat("her") returns "together"
   14      * </pre></blockquote>
   15      *
   16      * @param   str   the {@code String} that is concatenated to the end
   17      *                of this {@code String}.
   18      * @return  a string that represents the concatenation of this object's
   19      *          characters followed by the string argument's characters.
   20      */
   21     public String concat(String str) {
   22         int otherLen = str.length();
   23         if (otherLen == 0) {
   24             return this;
   25         }
   26         int len = value.length;
   27         char buf[] = Arrays.copyOf(value, len + otherLen);
   28         str.getChars(buf, len);
   29         // 通过new新建对象，原字符串不变(一个String对象被创建, 包含在这个对象中的字符序列是不可改变的)
   30         return new String(buf, true);
   31     }
```

### indexOf(int ch) 和 indexOf(int ch, int fromIndex) 方法 

```java
    1     /**
    2      * Returns the index within this string of the first occurrence of
    3      * the specified character. If a character with value
    4      * {@code ch} occurs in the character sequence represented by
    5      * this {@code String} object, then the index (in Unicode
    6      * code units) of the first such occurrence is returned. For
    7      * values of {@code ch} in the range from 0 to 0xFFFF
    8      * (inclusive), this is the smallest value <i>k</i> such that:
    9      * <blockquote><pre>
   10      * this.charAt(<i>k</i>) == ch
   11      * </pre></blockquote>
   12      * is true. For other values of {@code ch}, it is the
   13      * smallest value <i>k</i> such that:
   14      * <blockquote><pre>
   15      * this.codePointAt(<i>k</i>) == ch
   16      * </pre></blockquote>
   17      * is true. In either case, if no such character occurs in this
   18      * string, then {@code -1} is returned.
   19      *
   20      * @param   ch   a character (Unicode code point).
   21      * @return  the index of the first occurrence of the character in the
   22      *          character sequence represented by this object, or
   23      *          {@code -1} if the character does not occur.
   24      */
   25     public int indexOf(int ch) {
   26         return indexOf(ch, 0);
   27     }
   28 
   29     /**
   30      * Returns the index within this string of the first occurrence of the
   31      * specified character, starting the search at the specified index.
   32      * <p>
   33      * If a character with value {@code ch} occurs in the
   34      * character sequence represented by this {@code String}
   35      * object at an index no smaller than {@code fromIndex}, then
   36      * the index of the first such occurrence is returned. For values
   37      * of {@code ch} in the range from 0 to 0xFFFF (inclusive),
   38      * this is the smallest value <i>k</i> such that:
   39      * <blockquote><pre>
   40      * (this.charAt(<i>k</i>) == ch) {@code &&} (<i>k</i> &gt;= fromIndex)
   41      * </pre></blockquote>
   42      * is true. For other values of {@code ch}, it is the
   43      * smallest value <i>k</i> such that:
   44      * <blockquote><pre>
   45      * (this.codePointAt(<i>k</i>) == ch) {@code &&} (<i>k</i> &gt;= fromIndex)
   46      * </pre></blockquote>
   47      * is true. In either case, if no such character occurs in this
   48      * string at or after position {@code fromIndex}, then
   49      * {@code -1} is returned.
   50      *
   51      * <p>
   52      * There is no restriction on the value of {@code fromIndex}. If it
   53      * is negative, it has the same effect as if it were zero: this entire
   54      * string may be searched. If it is greater than the length of this
   55      * string, it has the same effect as if it were equal to the length of
   56      * this string: {@code -1} is returned.
   57      *
   58      * <p>All indices are specified in {@code char} values
   59      * (Unicode code units).
   60      *
   61      * @param   ch          a character (Unicode code point).
   62      * @param   fromIndex   the index to start the search from.
   63      * @return  the index of the first occurrence of the character in the
   64      *          character sequence represented by this object that is greater
   65      *          than or equal to {@code fromIndex}, or {@code -1}
   66      *          if the character does not occur.
   67      */
   68     public int indexOf(int ch, int fromIndex) {
   69         // 输入的字符 (ch) 会被自动转换成Unicode code point
   70         // 字符串的长度
   71         final int max = value.length;
   72         // 指定开始查找的索引不能小于0
   73         if (fromIndex < 0) {
   74             fromIndex = 0;
   75         } else if (fromIndex >= max) {
   76             // 查找位置不能大于字符串长度
   77             return -1;
   78         }
   79 
   80         // 一个char占用两个字节，MIN_SUPPLEMENTARY_CODE_POINT表示(2的16次方（65536）绝大多数字符都在此范围内)
   81         if (ch < Character.MIN_SUPPLEMENTARY_CODE_POINT) {
   82             // handle most cases here (ch is a BMP code point or a
   83             // negative value (invalid code point))
   84             final char[] value = this.value;
   85             for (int i = fromIndex; i < max; i++) {
   86                 if (value[i] == ch) {
   87                     return i;
   88                 }
   89             }
   90             return -1;
   91         } else {
   92             // 当字符大于 65536时，处理的少数情况，该方法会首先判断是否是有效字符，然后依次进行比较
   93             return indexOfSupplementary(ch, fromIndex);
   94         }
   95     }
```

### substring(int beginIndex) 和 substring(int beginIndex, int endIndex) 方法

```java
    1     /**
    2      * Returns a string that is a substring of this string. The
    3      * substring begins with the character at the specified index and
    4      * extends to the end of this string. <p>
    5      * Examples:
    6      * <blockquote><pre>
    7      * "unhappy".substring(2) returns "happy"
    8      * "Harbison".substring(3) returns "bison"
    9      * "emptiness".substring(9) returns "" (an empty string)
   10      * </pre></blockquote>
   11      *
   12      * @param      beginIndex   the beginning index, inclusive.
   13      * @return     the specified substring.
   14      * @exception  IndexOutOfBoundsException  if
   15      *             {@code beginIndex} is negative or larger than the
   16      *             length of this {@code String} object.
   17      */
   18     public String substring(int beginIndex) {
   19         if (beginIndex < 0) {
   20             throw new StringIndexOutOfBoundsException(beginIndex);
   21         }
   22         int subLen = value.length - beginIndex;
   23         if (subLen < 0) {
   24             throw new StringIndexOutOfBoundsException(subLen);
   25         }
   26         // 如果截取位置的索引为0就返回字符串本身，否则通过new新建一个对象
   27         return (beginIndex == 0) ? this : new String(value, beginIndex, subLen);
   28     }
   29 
   30     /**
   31      * Returns a string that is a substring of this string. The
   32      * substring begins at the specified {@code beginIndex} and
   33      * extends to the character at index {@code endIndex - 1}.
   34      * Thus the length of the substring is {@code endIndex-beginIndex}.
   35      * <p>
   36      * Examples:
   37      * <blockquote><pre>
   38      * "hamburger".substring(4, 8) returns "urge"
   39      * "smiles".substring(1, 5) returns "mile"
   40      * </pre></blockquote>
   41      *
   42      * @param      beginIndex   the beginning index, inclusive.
   43      * @param      endIndex     the ending index, exclusive.
   44      * @return     the specified substring.
   45      * @exception  IndexOutOfBoundsException  if the
   46      *             {@code beginIndex} is negative, or
   47      *             {@code endIndex} is larger than the length of
   48      *             this {@code String} object, or
   49      *             {@code beginIndex} is larger than
   50      *             {@code endIndex}.
   51      */
   52     public String substring(int beginIndex, int endIndex) {
   53         if (beginIndex < 0) {
   54             throw new StringIndexOutOfBoundsException(beginIndex);
   55         }
   56         if (endIndex > value.length) {
   57             throw new StringIndexOutOfBoundsException(endIndex);
   58         }
   59         int subLen = endIndex - beginIndex;
   60         if (subLen < 0) {
   61             throw new StringIndexOutOfBoundsException(subLen);
   62         }
   63         // 如果截取位置的索引为0并且结束为止等于字符串长度就返回字符串本身，否则通过new新建一个对象
   64         return ((beginIndex == 0) && (endIndex == value.length)) ? this
   65                 : new String(value, beginIndex, subLen);
   66     }
```

### Intern()

```java
		    1     /**
		    2      * Returns a canonical representation for the string object.
		    3      * <p>
		    4      * A pool of strings, initially empty, is maintained privately by the
		    5      * class {@code String}.
		    6      * <p>
		    7      * When the intern method is invoked, if the pool already contains a
		    8      * string equal to this {@code String} object as determined by
		    9      * the {@link #equals(Object)} method, then the string from the pool is
		   10      * returned. Otherwise, this {@code String} object is added to the
		   11      * pool and a reference to this {@code String} object is returned.
		   12      * <p>
		   13      * It follows that for any two strings {@code s} and {@code t},
		   14      * {@code s.intern() == t.intern()} is {@code true}
		   15      * if and only if {@code s.equals(t)} is {@code true}.
		   16      * <p>
		   17      * All literal strings and string-valued constant expressions are
		   18      * interned. String literals are defined in section 3.10.5 of the
		   19      * <cite>The Java&trade; Language Specification</cite>.
		   20      *
		   21      * @return  a string that has the same contents as this string, but is
		   22      *          guaranteed to be from a pool of unique strings.
		   23      */
		   24      // 当调用intern方法时，如果池中已经包含一个与该String确定的字符串相同equals(Object)的字符串，则返回该字符串。否则，将此String对象添加到池中，并返回此对象的引用
		   25     public native String intern();
```

+ 测试方法
```java
			    1 String str1 = "hello";//字面量 只会在常量池中创建对象
			    2 String str2 = str1.intern();
			    3 System.out.println(str1==str2);//true
			    4 
			    5 String str3 = new String("world");//new 关键字只会在堆中创建对象
			    6 String str4 = str3.intern();
			    7 System.out.println(str3 == str4);//false
			    8 
			    9 String str5 = str1 + str2;//变量拼接的字符串，会在常量池中和堆中都创建对象
			   10 String str6 = str5.intern();//这里由于池中已经有对象了，直接返回的是对象本身，也就是堆中的对象
			   11 System.out.println(str5 == str6);//true
			   12 
			   13 String str7 = "hello1" + "world1";//常量拼接的字符串，只会在常量池中创建对象
			   14 String str8 = str7.intern();
			   15 System.out.println(str7 == str8);//true
```