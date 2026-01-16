---@class TrapType
TrapType = {
    None = 0,
    Obstacle = 1, --障碍物，阻挡技能，不可走入
    GroudTrigger = 2, --地面触发型机关
    BlockGrid = 4, --可以阻挡部分弹道的障碍物 对应位置不生成格子 不可走入
    ObstacleMove = 5, --障碍物，不阻挡技能，不可走入
    Protected = 6, --玩家要保护的 会被怪物攻击 玩家不可攻击 不可走入，有血条
    Conveyor = 7, --传送带
    Eddy = 8, ---传送漩涡
    BombByHitBack = 9, ---炸弹：允许被击飞 被击飞会爆炸的炸弹
    TrapSummoner = 10, ---会召唤其他机关的机关
    TerrainAbyss = 11, ---深渊地形,在棋盘出现前就出场
    CurseTower = 12, ---舒摩尔魔物，诅咒塔
    BadGrid = 13, --坏格子
    TerrainAbyss2 = 14, ---祭剑座使用的特殊深渊地形
    TrapExtendSkillScope = 15, ---可以扩展技能范围的机关
    TrapFeatureDead = 16, --会消亡的机关
    BlackGrid = 17, -- 黑格子
    Auras = 18, --光环型机关，会根据配置技能显示边框，相同类型的框要合并
    MirageTrap = 19, --幻境子弹机关
    GapTileTrap = 20, --镂空地板机关，阻挡除飞行怪外的其他所有，阻挡机关生成
    ---PopStarTrapType_Begin
    PopStar_Prop = 61,   ---消灭星星：道具
    PopStar_Super = 62, ---消灭星星：强化格子
    PopStar_Lock = 63, ---消灭星星：锁格子
    PopStar_Rune = 64, ---消灭星星：符文
    ---PopStarTrapType_End
    MAX = 99 --
}
_enum("TrapType", TrapType)

----打开光环还是关闭光环
---@class TrapAurasState
local TrapAurasState = {
    Close = 0,
    Open = 1,
}
_enum("TrapAurasState", TrapAurasState)
