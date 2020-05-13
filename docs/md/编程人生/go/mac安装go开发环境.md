# Mac安装go语言开发环境

1. 利用brew安装

```shell
# 搜索go语言版本
brew info go

# 安装
brew install go

# 查看go的环境
# GOROOT：就是go的安装环境
# GOPATH：作为编译后二进制的存放目的地和import包时的搜索路径。其实说通俗点就是你的go项目工作目录。通常情况下GOPATH包含三个目录：bin、pkg、src。
go env
```