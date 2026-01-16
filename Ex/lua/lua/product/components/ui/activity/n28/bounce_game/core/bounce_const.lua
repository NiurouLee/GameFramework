--阵营
---@class BounceCamp
local BounceCamp = {
    Player = 0,--玩家角色
    Monster = 1,--怪物
}
_enum("BounceCamp", BounceCamp)

--移动方向
---@class BounceMoveDirection
local BounceMoveDirection = {
    ToLeft = 0,--向左移动
    ToRight = 1,--向右移动
}
_enum("BounceMoveDirection", BounceMoveDirection)


--游戏对象状态
---@class BounceObjState
local BounceObjState = {
    Alive = 0,--正常状态
    Deading = 1,--死亡动画播放中
    Deaded = 2,--已死亡
    Transformation = 3-- 变形中
}
_enum("BounceObjState", BounceObjState)


--常量定义
---@class BounceConst : Object
_class("BounceConst", Object)
BounceConst = BounceConst

BounceConst.CanvasMinX = -1300  --画布水平最小值
BounceConst.CanvasMaxX = 1500   --画布水平最大值

--怪物动作命名规范
BounceConst.MonsterBeAttackedAniName = "beAttacked" --被击动作名称
BounceConst.MonsterAttackAniName = "attack" -- 攻击动作名称
BounceConst.MonsterDeadAniName = "dead" --死亡动作名称
BounceConst.MonsterWalkName = "walk" --行走动作名称


--怪物音效类别
BounceConst.MonsterAudioTypeDead = 1 --死亡类别音效
BounceConst.MonsterAudioTypeBeAttacked = 2 --被攻击音效

BounceConst.GuideFirst = 118008
BounceConst.GuideSecond = 118009
BounceConst.GuideBoss1 = 118010 --产生boss
BounceConst.GuideBoss2 = 118011 --子弹运行距离
BounceConst.GuideBoss3 = 118012 --子弹杀死怪物

BounceConst.GuideBoss2_BulletPos1 = 400 --子弹运行距离
BounceConst.GuideBoss2_BulletPosKey1 = "guide1180111" --子弹运行距离
BounceConst.GuideBoss3_BulletPosKey1 = "guide1180121" --子弹攻击到怪物