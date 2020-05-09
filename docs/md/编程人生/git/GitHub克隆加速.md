# GitHub克隆加速

1. 设置git的代理
```shell
# 1086是根据自己电脑查出来的
git config --global http.proxy 'socks5://127.0.0.1:1086'
git config --global https.proxy 'socks5://127.0.0.1:1086'
```
2. 完成上述步骤之后clone的速度就会变快了，但只限于GitHub
3. 关闭git代理
```shell
git config --global --unset http.proxy
git config --global --unset https.proxy
```