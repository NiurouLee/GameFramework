---@class SkillTriggerType
---@field BuffLayer number
SkillTriggerType = SkillTriggerType

_enum(
    "SkillTriggerType",
    {
        SkillTriggerTypeStart = 1,
        None = 1, --直接释放
        Chain = 2, --连锁数
        Energy = 3, --能量值
        LegendEnergy = 4, --传说光灵的能量
        San = 5, --San值系统：在CD的基础上增加San值消耗
        BuffLayer = 6, --光灵身上指定buff的层数，用来实现特定操作计数产生的主动技消耗能量
        SkillTriggerTypeEnd = 2147483647 ---------
    }
)


---@class SkillTriggerTypeExtraParam
SkillTriggerTypeExtraParam = {
    None = 0,
    Default = 1,
    PickPosNoCfgTrap = 2, --点选位置没有指定的机关 罗伊，主动技 点机关和空格子消耗能量不同
    TrapID = 3, --主动技释放需要存在的机关ID 清瞳:主动技子技能释放需要机关存在且不被怪物或玩家覆盖
    SanValue = 4, --固定san值
    SanByScopeGridCounts = 5, -- 根据格子数量扣san
    DecreaseHPPercentAsSan = 6, -- san值不够时用生命值百分比抵san
    HPValPercent = 7, --最大生命值百分比+剩余当前生命值百分比--不再执行扣血，只用于判断，扣血用技能效果85
    SanNotFull = 8, --San不能为满值
    FeatureType = 9, --模块技能对应的模块
    SanChangeByRoundCastTimes = 10, --San 根据该回合释放过的次数递增
    CardNotFull = 11, --抽牌 卡牌不能为满
    CardCost = 12, --模块 卡牌消耗 对应FeatureCardCompositionType
    CardTarPetNotHasBuff = 13, --目标光灵（队长、队尾。。）不能有指定buff
    CostByForceMoveStep = 14, --仲胥，能量消耗需要根据位移步数（回合内累加）计算
}
_enum("SkillTriggerTypeExtraParam", SkillTriggerTypeExtraParam)
