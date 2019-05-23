### source、sh、bash、./执行脚本的区别

1. source
 + 用法：source FileName
 + 作用：在当前bash环境下读取并执行FileName中的命令。**该文件可以不需要"执行权限"**
 + 可以使用”.“代替

2. sh和bash
 + 用法：sh FileName、bash FileName
 + 作用：打开一个subshell，读取并执行FileName中的命令。**该文件可以不需要"执行权限"**

3. ./
 + ./FileName
 + 作用：打开一个子shell来读取并执行FileName中命令。**文件需要权限**
 + 可以使用chmodm命令添加权限
