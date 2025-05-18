<div align="center">

# HYPERLUNATIC

[![English](https://img.shields.io/badge/English-blue)](README_en.md) [![简体中文](https://img.shields.io/badge/简体中文-red)](README.md)


![Godot v4.4](https://img.shields.io/badge/Godot-v4.4-478cbf?logo=godot-engine&logoColor=white) [![GitHub license](https://img.shields.io/github/license/317gw/HYPERLUNATIC)](LICENSE) [![GitHub stars](https://img.shields.io/github/stars/317gw/HYPERLUNATIC)](https://github.com/317gw/HYPERLUNATIC/stargazers) [![GitHub issues](https://img.shields.io/github/issues/317gw/HYPERLUNATIC)](https://github.com/317gw/HYPERLUNATIC/issues) [![GitHub forks](https://img.shields.io/github/forks/317gw/HYPERLUNATIC)](https://github.com/317gw/HYPERLUNATIC/network)

<!-- # # 📝说明： -->
HYPERLUNATIC 游戏项目备份存档开源学习文件和文件夹，由 白色蜂鸟(AlbedoHummingbird / 317gw) 制作，使用 Godot Engine 开发

<!-- # # 🏷️Wiki： -->
早期项目Wiki可见 [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/317gw/HYPERLUNATIC) 此Wiki由语言模型生成，生成来源主要来自项目内文档，因未依据代码所以多数内容不准确，请以项目代码为准。此外网站可以直接对项目咨询语言模型。

</div>


![高塔](/forREADME/godot.windows.opt.tools.64_iuGFJwCi3z.jpg)
![50m](/forREADME/godot.windows.opt.tools.64_7GSDSlLmNj.jpg)
![太阳景色](/forREADME/godot.windows.opt.tools.64_GtXq4hUzeo.jpg)
![弹幕](/forREADME/godot.windows.opt.tools.64_bKXhlvlfwd.jpg)
![水下](/forREADME/godot.windows.opt.tools.64_WjNpwygEvz.jpg)


## 🚀开始
引擎版本会激进跟随最新稳定版 —— Godot_4.4-stable

现阶段导出游戏意义不大。请从上面<font color = green> <>Code▽</font>下载源码ZIP压缩包，自行下载安装 [Godot Engine](https://godotengine.org/)，并导入项目文件，然后自由发挥:)
极个别情况，你要是碰见什么安装错误、没有依赖，那我也不知道 摆手✋

所有设计都在施工中，看看概率论与统计，保不齐后续会发生什么

嘿！你现在就可以参与进来！地图设计 彩蛋 小游戏 ARG 之类……

## 🪪介绍：
这是一款开源的\*头部视角\*3D游戏，包含 平台跳跃、冒险解谜、动作射击、弹幕躲避 等元素，你可以去地图中找找有什么是需要完成的。

> 或者去看看你身处的世界……

#### 📜剧情
2077年，Karole Kate休假回到了老家。在整理老电脑的过程中，她发现以前玩的一款\*超级老\*的游戏的其中一个服务器还在线上。于是在一通硬件、软件、升级、整理、打MOD之后，她进入了这个——2000年便在计划的服务器。

#### 🗺地图设计&游戏流程
地球🌏 向 太阳☀️ 的宇宙之旅！或是 但丁的神曲？

使用区域来进行场景风格和玩法上的区分，如天空、月球、水星。
你会在游戏服务器（实际离线）中游玩，内部采用线路关卡制。明确化 如空气墙、游玩区域、判定盒等场景构件。
场景的背景模型是完整而且可以到达的。
游戏服务器之间有不明显的连接，可以使用诸如掉出地图、寻找刻意的传送点等方式来完成切换。
兼容主菜单列表选关，被包装成游戏服务器列表。

除了完成主线流程外，还包含带有明确的规则限制的挑战任务。成就进度就是流程进度。与关卡、服务器、挑战、成就交织在一起的解密。不必要的ARG(未施工)。

#### 🖼画面
老游戏服务器的房间，打mod后的氛围。

采用低分辨率贴图和低面数模型，根据物体性质的选择性使用PBR材质，简约的光照效果，尽可能酷炫的着色器后处理。

你可以看到你的身子！(未施工抱歉)

#### 玩法主要参考(推荐去试一下)
ULTRAKILL、
Celeste、
Mirror's Edge、
Garry's Mod、
Half-Life 2、
Neon White、
VOIN、
Touhou Project、
Minecraft、
Touhou Luna Nights、
沙雕之路、
Deadlock、
DEATH STRANDING DIRECTOR'S CUT、
Antimatter Dimensions、
NGU IDLE
…… 等好玩的游戏。

还有，以上构想均在制作中

PS: 风格灵感来自起源引擎(主要是gmod)和mc的服务器

## 🛠️核心机制
*条目施工中
HYPERLUNATIC的核心机制，可以基本了解游戏设计。

#### 玩家移动
虽然参考了起源引擎，但玩家基本的被动受力和移动并不完全仿照刚体，代码上没有使用简洁的物理模拟。

玩家的运动系统设计的很复杂，代码上是根据玩家所处环境和玩家状态分别处理的。

#### 物理交互
只对于各类物体，尽可能还原物理效果，不涉及过多物理视觉效果，如风、水波纹、树叶/草。

#### 弹幕地狱
参考Touhou Project弹幕作重新设计的，2d弹幕游戏的弹幕设计不适用于3d游戏。

#### 选关界面
使用游戏服务器界面包装选关界面。

#### 流程控制
由起点、检查点、终点的标识 和 场景组件 组成的 线路 为一个关卡。
游戏服务器 有大有小，一个游戏服务器为一整个关卡场景，有单个或复数个关卡。
区域 由玩法风格和视觉风格区分，它只说明风格，不是实际游玩场景的区分，多数游戏服务器只属于一个区域。


## 🎮目前的进度 & 接下来要做的：
* 游戏系统：
  - [ ] 弹幕系统 *正在做 70%
  - [x] 起点终点 90%?
  - [ ] Buff系统
  - [ ] 受伤事件记录 用来代替玩家生命值
  - [ ] 成就系统
  - [ ] 关卡管理系统
  - [ ] 特效管理系统 *做了归类，但还不是自动管理系统 20%
  - [ ] 声效管理系统 1%

* 游戏场景(基本是游玩顺序↓)：
  * 服务器功能地图(目前不涉及联机内容)
    - [ ] 购物中心 Mall #  服务器大厅 10%
    - [ ] 公寓 Apartment # 参考传送门2开头
    - [ ] 街区 Street # 上述地图连接
  * 天空 Sky
    - [ ] 天空高塔 Sky Tower # 飞鱼、拿花妖精。不是巴别塔😡 20%
    - [ ] 雨弓工厂🌈 Rain Bow Factory # 机器狗、鹿颈长。水、颜料、沥水槽
  * 月球 Moon
    - [ ] 坑 # 白模、障目天使雕像
  * 水星 Mercury
    - [ ] 水银海浅滩 Mercury Sea Shoal # 长线水平高速图，下雪，满地水银，高速时可短距离在水银面打水漂无伤
    - [ ] *温差潮汐图
  * 金星 Venus
    - [ ] 铜门大断桥 Copper Gate Broken Bridge # 冷清
  * 太阳 Sun
    - [ ]
  * 地球 Earth
    - [ ] 电影院 Cinema
  * 其他 else
    - [x] 一个非常简单测试地图 99.99%
    - [ ] 其他万物的殿堂 The Palace of Everything Else # 太阳马
    - [ ] 血宫 Blood Palace # 无限打架图，就鬼泣那个
  * 具体的部分关卡设计
    - [ ] 康威下落 #  康威生命游戏作为地图块，变化越来越快，需要找到规律防止掉下。按照阶段对地图块缩放。

* 场景组件&交互：
  - [x] 玩家对其他物体的物理碰撞 90%
  - [x] 康威生命游戏的地图模块 50%
  - [x] 可以爆炸的油桶，根据伤害变化的爆炸效果 70%
  - [x] 性能较差的浮力水 99%
  - [x] 性能稍好的浮力水 99%
  - [x] 天空极限 # 规定了天空高度，单面阻挡弹射物，可能在整个场景的中间
  - [x] 锁链 # 无遮挡时源头为天空极限
  - [x] 冰面
  - [x] 明显空气墙
  - [x] 根据表面应用摩擦力
  - [ ] 翻牌显示器
  - [ ] 蜡烛数量触发器 # 烛火是数字，红色的是敌人，蓝色的是场景组件破坏，归零触发门和机关 50%
  - [ ] 门
  - [ ] 按钮
  - [ ] 压力板
  - [ ] 椰子和椰子树 # 某种保龄球
  - [ ] 跳舞气球人
  - [ ] 弹幕障碍高尔夫
  - [ ] 小黄鸭
  - [ ] 镜子
  - [ ] 弹射墙面

* 视觉效果：
  - [x] 太阳 90%
  - [x] 径向模糊 80%
  - [ ] 优化水物理效果和性能
  - [ ] 进出水特效
  - [ ] 更好的水着色器
  - [ ] 脸上的吃水线
  - [ ] 添加玩家的手和脚

* 玩家动作：
  - [x] 基本的移动系统 100%
  - [x] 奔跑 95%
  - [x] 冲刺，冲刺跳 90%
  - [x] 基于射线检测的边缘攀爬系统 90%
  - [x] 磕头加速跳 90%
  - [x] 低速模式与静步 90%
  - [x] V键飞行 100%
  - [x] 空中加速 *手感极差 50%
  - [ ] 斜坡滑翔 70%
  - [ ] 凌波微步
  - [ ] 调整跳跃、跑步等数值
  - [ ] 跳墙
  - [x] 站在敌人头顶、弹幕上 80%
  - [ ] 飞踢
  - [ ] 优化边缘静步不掉落判断

* 武器：
  - [x] 简单的射击实现 100%
  - [x] 武器切换 90%
  - [x] 自瞄 95%
  - [x] 简单的步枪 # 测试用 100%
  - [x] 钓鱼竿 # mc同款 60%
  - [ ] 小镰刀 # 并非
  * 实装武器：
    - [ ] 棒球棍 BBB # 弹反，打飞任何东西
    - [ ] 片短剑 Slice Sword # 挥舞，近战攻击，插墙上可以站着
    - [ ] 手 Hand # 两个物品栏
    - [ ] MTs-3 Rekord # 无后座高精度手枪 10%
    - [ ] 圣水钓竿 Holy Fisher # 钩、拉、抡死鬼魂
    - [ ] 重型狙击枪 Heavy Rifle # 弹射子弹，超级大狙，猎象枪
    - [ ] 微型导弹发射器 Micro Missiles Launcher # 连发密集爆炸导弹
    - [ ] 管理员之枪 opGun # 红色沙漠之鹰

* 敌人：
分级参考Doom、ULTRAKILL
  * 轻型
    - [x] 飞鱼 Flying Fish # 基于鱼群模拟，充当滑翔跳板 50%
    - [ ] 机器狗 Robot dog # 群体协作，翻倒停机或爆炸死亡
    - [ ] 火箭史莱姆 Rocket Slime # 跳、飞、无限自爆
  * 中型
    - [ ] 拿花妖精 Take Flower Yousei # 弹幕专员
    - [ ] 信使雕像 Messenger Statue # 追踪创你
    - [ ] 白模 White Model # 负责搭配各种武器，初始佩戴或捡拾 10%
    * 白模装备
      - [ ] 空手 # 远离你
      - [ ] 弓箭手 # 抛物线
      - [ ] 蓝盾牌 # 锁你头，正面120°无敌，绕过击杀
  * 重型
    - [ ] 鬼魂 Ghost # 附身到特定物体：场景组件、雕像类
    - [ ] 障目天使雕像 Blind Angel Statue # 雕像在你视线内高速滑动并无敌，视线外静止、可以挨打了。血量归零后看到才发光碎裂死亡  模型20%
    - [ ] 屏障水晶 Barrier Crystal # 上属蜂鸟雕像，对于玩家射向敌人的攻击或敌人即将受到的攻击，瞬移到中间并抵挡伤害，贼肉，受击计数大于10双倍受伤，受击计数每秒减1，高频伤害可快速摧毁
  * 超重型
    - [ ] 鹿颈长 Effarig # 柱形搭路机
    - [ ] 蜂鸟雕像 Hummingbird Statue # 召唤并维持一个屏障水晶，被鬼魂附身后高空飞行，死亡时摧毁所属的屏障水晶
  * Boss
    - [ ] 大拿花妖精 Big Take Flower Yousei # 不知道叫啥名
    - [ ] 以鸟飞行的弓手 The Archer who Flies with Bird # 魔王的箭雨
    - [ ] 太阳马 Sun Mare # 教程
  * 生成
    - [ ] 地面法阵 # 敌人生成时可被上或斜上方向攻击顺势打飞，敌人生成时施加上方向冲击力
    - [ ] 刷怪笼
    - [ ] 吊线下落

* NPC：
  - [ ]

* UI：
  - [ ] 游戏主菜单 *完成了一半 49%
  - [x] 暂停菜单 92%
  - [x] gmod的C键调出可鼠标操作的ui 90%
  - [x] 显示RigidBody3D信息的ui 00%
  - [ ] mc的对话窗口
  - [ ] 起源引擎的对话与提示信息字幕
  - [ ] 起源和gmod的提示气泡
  - [ ] mc的声音文字提示

* 生活质量：
  - [ ] 修bug 777%
  - [x] F3 Debug菜单 50%
  - [x] panku_console 的Debug命令行+菜单 90% x这玩意暂且取消
  - [ ] 内置鼠标连发器
  - [ ] 内置按键宏

* 杂项：
  - [ ] 完善Github仓库，添加更多的说明和信息。 omg%


## Q&A：
* 为什么选择使用Godot开发3D游戏？
  * Godot本身足够轻量级，磁盘、内存占用低，软件开关迅速，电脑负担小，开发方便。其他引擎的高新技术尚不考虑。

* 参与开发可以干什么？
  * 很多方式，比如提交代码、报告Bug、提供建议、翻译文档等。

* 我想提供帮助？
  * 你可以使用这个Github仓库，或在下方↓的联系方式留言讨论。

* 多语言支持？
  * 简体中文、繁体中文、英文。目前没有实力支持其他语言。如你想制作其他语言翻译，我非常乐意，直接联系我。

* 登录平台？
  * 仅目前，PC端，Steam、itch.io

* 要开发多久？
  * 我想要全职开发，但是会有困难，总之comeing s∞n in 2077

* 为什么是2077？
  * 因为好多赛博朋克或者未来风格作品都有出现这个年份。

* 游戏玩法是啥啊？缝合这么多游戏？
  * 主要玩法参考Celeste的平台跳跃，ULTRAKILL的快节奏操作，地图设计参考Celeste、Neon White。感觉和印象是更重要的，实际上并没有搭配毫不相干的游戏机制。
  * 四处逛逛。

* 我好像没看到有什么角色？
  * 游戏流程以玩家为中心，故事性较弱，大概会有我小说、车卡、RimWorld中的角色，且大概都是女的，因为Touhou Project。

* 中文译名是啥啊？
  * ~~亢奋的疯子~~ ~~超月狂~~ ~~超级月亮人~~ 没有合适的中文译名，HYPERLUNATIC作为唯一名称就很合适，如果你有合适的中文译名，欢迎告诉我。

* Antimatter Dimensions和NGU IDLE是挂机、点击、idle游戏，和这游戏有啥关系？
  * 这俩游戏的流程设计非常好，其中的一些解谜部分非常有趣，所以偷了。

* ？：
  * 答应我，好好睡觉。

## 📌注意事项：
本项目为开源项目，采用 GPL-3.0 开源协议 - 查看 [LICENSE](LICENSE) 文件了解详情。对于GPL-3.0的传染性我很抱歉，我很高兴看到你去参考和使用我的代码。

欢迎参与贡献，但请遵守以下规定：
1. 不要删除或修改文件中的版权声明。
2. 不要在项目中使用任何未经授权的素材或代码。
3. 用于商业用途时，仅代码可用，不要使用 美术/声效/模型/文本 等资源，不要使用 HYPERLUNATIC/FireKami/白色蜂鸟/AlbedoHummingbird/317gw 等字样用于宣传或主要内容(包括其大小写形式)。

项目根目录下，目前只有assets文件夹能确保为项目作者制作的主要原创部分，assets文件夹为核心资产。
assets文件夹下的部分代码和资源文件、图像、音频来自网络，对其进行了修改，遵守其协议，并尽可能的表明了出处，如发现问题请联系项目作者。
目前并未整理非代码资源的许可，不要擅自使用。

根目录下的其他并非由Godot Engine或其addon生成文件和文件夹，为临时的流动文件，其来源为其他开源项目或互联网，用于测试、开发等。

addons文件夹下存放着Godot Engine的插件。
插件的原作者并非项目作者，部分代码已根据项目需求进行了修改，遵守其协议，因嫌麻烦并未列出许可证，如有问题请联系项目作者。

如有对其他开源项目、addon、互联网资源的使用许可或许可证的异议，为项目作者的疏忽，请联系项目作者。

> 作者邮箱：<wo3178216379@outlook.com>
>
> INDIENOVA主页 -> [HYPERLUNATIC](https://indienova.com/g/hyperlunatic)
>
> itch.io主页 -> [HYPERLUNATIC](https://albedohummingbird.itch.io/hyperlunatic)
>
> bilibili -> [白色蜂鸟的个人空间](https://space.bilibili.com/32704272)
>
> 爱发电赞助: -> [白色蜂鸟主页](https://ifdian.net/a/AlbedoHummingbird)
>
> QQ讨论群 -> [白色蜂鸟&FireKami讨论](https://qm.qq.com/q/zh3svlXTBm) 705304831
>
> Discord聊天室 -> [FireKami Game&Fiction](https://discord.gg/c9v67xuuQR)
>
> /tp [github开源地址](https://github.com/317gw/HYPERLUNATIC)

![Alt text](/forREADME/godot.windows.opt.tools.64_1721bm5eGd.jpg)
![Alt text](/forREADME/godot.windows.opt.tools.64_6GGmSkblFN.jpg)
![Alt text](/forREADME/godot.windows.opt.tools.64_OmOsZfQeu6.png)
![远景](/forREADME/godot.windows.opt.tools.64_vnLDbKccJK.jpg)
![水](/forREADME/godot.windows.opt.tools.64_8xybG45lHn.jpg)
![海泡沫1](/forREADME/godot.windows.opt.tools.64_PwjpRzcOVt.jpg)
![海泡沫2](/forREADME/godot.windows.opt.tools.64_d1uX4mJ7kA.jpg)
![弹幕发射器2](/forREADME/godot.windows.opt.tools.64_q3VD1p4X4Q.jpg)
![弹幕发射器4](/forREADME/godot.windows.opt.tools.64_KAdiUCbcte.jpg)
![弹幕发射器5](/forREADME/godot.windows.opt.tools.64_zS6zkwZ24w.jpg)
![制作组logo](/logo/logo暗处变亮.png)

> 现实的荒野

---