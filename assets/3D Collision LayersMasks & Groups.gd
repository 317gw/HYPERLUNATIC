"""
extends BigChili

【Godot教程】规划3D物理层名称
仅我的例子供参考，不全面请见谅

olddddddddddddddd
Layer 1 	player				玩家
Layer 2 	Wall				墙
Layer 3 	Enemy				敌人
Layer 4 	Bullet				通常的枪里发射的物理子弹
Layer 5 	Sign				告示牌
Layer 6 	RigidBody3D			刚体
Layer 7 	PlayerRigidBody		研发阶段的模拟玩家碰撞 无用
Layer 8 	Debris				带碰撞的碎片
Layer 9 	Explode				爆炸物
Layer 10	Water				水
Layer 11	Probe				探针 球球
Layer 12	Danmaku				弹幕
Layer 13	StandOnHead			踩头的板子


之后↓↓↓↓↓
1 Environment		2(Wall) + 5(Sign)								静态环境物体			所有对象交互
2 Player			1(player)										玩家角色及附属物理体	环境、敌人、物理对象、液体交互
3 Enemy				3(Enemy)										敌人及其碰撞			玩家、环境、投射物交互 
4 Projectiles		4(Bullet) + 12(Danmaku) + 9(Explode)			所有飞行物/爆炸物		环境、敌人交互
5 PhysicsObjects	6(RigidBody3D) + 7(PlayerRigidBody) + 8(Debris)	可互动物体			环境、玩家、敌人交互
6 Liquid			10(Water)										液体区域				仅与玩家交互
7 Interaction		11(Probe) + 13(StandOnHead)						交互检测区域			无物理碰撞（纯分组检测）


Groups
Sign（原Layer5）：交互提示标识（通过_on_area_entered检测分组）
Probe（原Layer11）：探测器（可通过分组过滤）
StandOnHead（原Layer13）：头部站立检测（更适合用射线检测+分组）

"""
