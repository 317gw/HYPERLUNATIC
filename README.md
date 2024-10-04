# HYPERLUNATIC

![太阳景色](/forREADME/godot.windows.opt.tools.64_GtXq4hUzeo.jpg)
![弹幕](/forREADME/godot.windows.opt.tools.64_bKXhlvlfwd.jpg)
![水下](/forREADME/godot.windows.opt.tools.64_WjNpwygEvz.jpg)

HYPERLUNATIC游戏项目备份存档开源学习文件和文件夹，由317gw制作，Godot Engine 4.3.stable开发。


#### 介绍：

这是一款开源的3D游戏，融合动作、射击、平台跳跃、弹幕躲避等元素。

2077年，玩家扮演的Karole Kate因休假，回到了乡下的老家，在整理老电脑的过程中，发现以前的玩一款超级老的游戏的服务器还在运行，于是在一通硬件软件升级整理打MOD之后，她进入了这个2000年的服务器。

地图设计。使用区域来进行场景风格和玩法上大的区分，区域内部采用关卡制，明确化比如空气墙、应该游玩的区域、场景判断等。地图背景处，如果它是模型，则完整而且可以到达。关卡和区域之间有不明显的连接，可以使用诸如掉出地图、寻找刻意的传送点等方式来切换。

游戏流程。除了完成关卡地图，还包含明确的带有规则限制的挑战任务，成就系统，和与关卡、区域、挑战、成就交织在一起的解密部分。

画面。采用低分辨率贴图，根据物体性质的选择性PBR材质，必要而简约的光照效果，较重要的着色器，总体制造一个给古老的游戏进行现代视觉优化之后的效果。

玩法主要参考：
ULTRAKILL
Celeste
Mirror’s Edge
Garry's Mod
Half-Life 2
Touhou Project
Minecraft
Touhou Luna Nights
沙雕之路
Antimatter Dimensions
NGU IDLE
……等好玩的游戏。

还有，以上构想均在制作中


#### 目前的进度：

* 基本的移动系统
* 奔跑
* 冲刺，冲刺跳
* 康威生命游戏的地图模块
* 飞鱼
* 简单的射击实现
* 自瞄
* 可以爆炸的油桶
* 根据伤害变化的爆炸效果
* 以不正常方式实现的单方面玩家物理碰撞
* 基于射线检测的边缘攀爬系统
* 一个非常简单测试地图
* 低速模式与静步
* 性能较差的浮力水
* V键飞行
* 一些“生活质量”操作优化
* 一些场景装饰


#### 接下来要做的：

* 杂项：
  * 完善Github仓库，添加更多的说明和信息。
  * 关卡管理系统
  * 特效管理系统

* 视觉效果：
  * 优化水物理效果和性能
  * 进出水特效
  * 制作更好的水着色器
  * 吃水线效果
  * 添加玩家的手和脚

* 地图：
  * 一个能玩的高塔

* 玩法：
  * 动作：
    * 起源引擎的旋转跳和滑翔
    * 凌波微步
    * 调整跳跃、跑步等数值
    * 跳墙
    * 站在敌人头顶、弹幕上
    * 飞踢
    * 优化边缘静步不掉落判断
  * 武器：
    * 钓鱼竿（mc同款）
    * MTs-3 Rekord（无后座高精度手枪）
    * 重炮狙击枪（超级大狙？）
    * 片短剑（插墙上可以站着）
  * 交互:
    * gmod的C键调出可鼠标操作的gui
    * 显示所有RigidBody3D信息的gui
    * 按钮
    * 门
  * 生活质量：
    * 起源和gmod的提示气泡
    * 起源引擎的对话与提示信息字幕
    * mc的声音文字提示


#### Q&A：

* 如何参与开发？
  * 参与贡献可以有很多方式，比如提交代码、报告Bug、提供建议、翻译文档等。

* 多语言支持？
  * 简体中文、繁体中文、英文。目前没有实力支持其他语言。

* 登录平台？
  * 仅目前，PC端，Steam、itch.io

* 要开发多久？
  * 我想要全职开发，但是会有困难，总之comeing s∞n in 2077

* 为什么是2077？
  * 因为好多赛博朋克或者未来风格作品都有提到2077年

* 游戏玩法是啥啊？缝合这么多游戏？
  * 主要玩法是Celeste的平台跳跃地图和ULTRAKILL快节奏操作，其他都是添头。

* 我好像没看到有什么角色？
  * 游戏流程以玩家为中心，故事性较弱，大概会有我小说、车卡、RimWorld中的角色，且大概都是女的，因为Touhou Project。

* Antimatter Dimensions和NGU IDLE是挂机、点击、idle游戏，和这游戏有啥关系？
  * 这俩游戏的流程设计非常好，其中的一些解谜部分非常有趣，偷了。


#### 注意事项：

项目根目录下，目前只有assets文件夹能确保为项目作者制作的主要原创部分。
assets文件夹下的部分代码和资源文件、图像、音频来自网络，对其进行了修改，并尽可能的表明了出处。

根目录下的其他并非由Godot Engine或其addon生成文件和文件夹，为临时的流动文件，其来源为其他开源项目或互联网，用于测试、开发等。
如有对其他开源项目、addon、互联网资源的使用许可或许可证的异议，可能为项目作者的疏忽，请联系项目作者。

addons文件夹下存放着Godot Engine的插件。
插件的原作者并非项目作者，部分代码已根据项目需求进行了修改。


> 欢迎加入QQ讨论群：705304831

![远景](/forREADME/godot.windows.opt.tools.64_vnLDbKccJK.jpg)
![水](/forREADME/godot.windows.opt.tools.64_8xybG45lHn.jpg)
![海泡沫1](/forREADME/godot.windows.opt.tools.64_PwjpRzcOVt.jpg)
![海泡沫2](/forREADME/godot.windows.opt.tools.64_d1uX4mJ7kA.jpg)
![弹幕发射器1](/forREADME/godot.windows.opt.tools.64_W5910U7S1b.jpg)
![弹幕发射器2](/forREADME/godot.windows.opt.tools.64_q3VD1p4X4Q.jpg)
![弹幕发射器3](/forREADME/godot.windows.opt.tools.64_fJoZthogYL.jpg)
![弹幕发射器4](/forREADME/godot.windows.opt.tools.64_KAdiUCbcte.jpg)
![弹幕发射器5](/forREADME/godot.windows.opt.tools.64_zS6zkwZ24w.jpg)
![弹幕发射器6](/forREADME/godot.windows.opt.tools.64_2IJ8CeczTi.jpg)
![制作组logo](/logo/logo暗处变亮.png)

---