# 查看并设置 mysql 数据库连接数、并发数相关信息

### show status like 'Threads%';

```sql
+-------------------+-------+
| Variable_name     | Value |
+-------------------+-------+
| Threads_cached    | 58    |
| Threads_connected | 57    |   ### 这个数值指的是打开的连接数
| Threads_created   | 3676  |
| Threads_running   | 4     |   ### 这个数值指的是激活的连接数，这个数值一般远低于connected数值
+-------------------+-------+
 
# Threads_connected 跟show processlist结果相同，表示当前连接数。准确的来说，Threads_running是代表当前并发数
```

### show variables like '%connect%';

```sql
+--------------------------+-------------------+
| Variable_name            | Value             |
+--------------------------+-------------------+
| character_set_connection | latin1            | 
| collation_connection     | latin1_swedish_ci | 
| connect_timeout          | 10                | 
| init_connect             |                   | 
| max_connect_errors       | 10                | 
| max_connections          | 4000              | 
| max_user_connections     | 0                 | 
+--------------------------+-------------------+
```

### show variables like '%max_connections%';

+ 这是是查询数据库当前设置的最大连接数

```sql
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| max_connections | 1000  |    ### max_connections 参数可以用于控制数据库的最大连接数：
+-----------------+-------+
```

### show global status like 'Max_used_connections';

+ 服务器响应的最大连接数

```sql
+----------------------+-------+
| Variable_name    | Value |
+----------------------+-------+
| Max_used_connections | 2   |
+----------------------+-------+
1 row in set (0.00 sec)
```

### 容易出现的问题

1. ”MySQL: ERROR 1040: Too many connections”
   + 造成这种情况的一种原因是访问量过高，MySQL服务器抗不住，这个时候就要考虑增加从服务器分散读压力；
   + 另一种原因就是MySQL配置文件中 max_connections 值过小
      + Max_used_connections / max_connections * 100% 的值应当保持在10%左右
         + 对于mysql服务器最大连接数值的设置范围比较理想的是：服务器响应的最大连接数值占服务器上限连接数值的比例值在10%以上，如果在10%以下，说明mysql服务器最大连接上限值设置过高。
   + 设置 max_connections （两种方法）
      + 第一种：set GLOBAL max_connections=需要设置的数字;
      + 第二种：修改 mysql 配置文件 my.cnf，在 mysqld 段中添加或修改 max_connections 值

