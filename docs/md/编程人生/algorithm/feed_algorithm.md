
- [什么是Feed算法](#什么是Feed算法)
- [常见的Feed设计方案](#常见的Feed设计方案)
- [参考博客](#参考博客)

# 什么是Feed算法

Feed中文翻译为：喂食。

Feed是一个互联网早起概念，本意是RSS(Really Simple Syndication--简易信息聚合)中用来接收信息来源更新的接口。

英文解释：
>a web feed (or news feed) is a data format used for providing users with frequently updated content. Content distributors syndicate a web feed, thereby allowing users to subscribe to it

即Feed实际上是一种数据格式，给用户持续提供更新的内容。我们刷微博、朋友圈、知乎、各大门户媒体，我们所看到的内容，都是一种Feed流，我们获取的内容好不夸张的说，是被这些Feed流所控制了。**内容分发机制能够控制用户在合适的时间看到“规定”的内容。**

**内容分发机制**包含两个核心问题：

1. 给用户分发（展示）哪些内容；
2. 对分发的内容进行怎样的排序；

# 常见的Feed设计方案

1. Timeline（时间线）

最原始、、最基本也是最直观的展示形式，展示内容按照时间先后排序展示。例如：微信朋友圈，早期的微博。

	其实微信朋友圈、早期的微博很好的回答了feed流设计两大核心问题：
	1. 给用户分发（展示）哪些内容：微博是关注的用户、微信是相互专注的好友
	2. 对分发的内容怎么进行排序：按照时间的先后顺序，最新的内容越靠前

优点：利于用户对呈现的内容进行理解，时间的先后顺序嘛，另外由于是按照时间顺序，每次更新都能最大化的保证用户能够看到更新的内容。

弱点：内容呈现的效率极为底下，甚至可能会出现大量的垃圾内容。需要内容提供方十分克制，也需要用户对这些内容足够关注。

2. 重力排序法

3. 智能排序法


# 参考博客

 + https://www.jianshu.com/p/d2be205adaa2?from=timeline
 + https://www.jianshu.com/p/4b51126fe930