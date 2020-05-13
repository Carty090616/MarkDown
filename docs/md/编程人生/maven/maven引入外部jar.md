# Maven引入外部jar的方式

1. dependency 本地jar包

```java
    <dependency>
        <groupId>com.im</groupId>  <!--自定义-->
        <artifactId>sdk</artifactId>    <!--自定义-->
        <version>1.0</version> <!--自定义-->
        <scope>system</scope> <!--system，类似provided，需要显式提供依赖的jar以后，Maven就不会在Repository中查找它-->
        <systemPath>${basedir}/lib/sdk-1.0.jar</systemPath> <!--项目根目录下的lib文件夹下-->
    </dependency> 
```

2. 编译阶段指定外部lib

```java
     <plugin>
     <artifactId>maven-compiler-plugin</artifactId>
     <version>2.3.2</version>
     <configuration>
     <source>1.8</source>
     <target>1.8</target>
     <encoding>UTF-8</encoding>
     <compilerArguments>
     <extdirs>lib</extdirs><!--指定外部lib-->
     </compilerArguments>
     </configuration>
     </plugin>
```

3. 将外部jar打入本地maven仓库

```java
mvn install:install-file -Dfile=sdk-1.0.jar -DgroupId=com.im -DartifactId=sdk -Dversion=1.0 -Dpackaging=jar
```

4. 引入jar包

```java
    <dependency>
            <groupId>com.im</groupId>
            <artifactId>sdk</artifactId>
            <version>1.0</version>
    </dependency>
```