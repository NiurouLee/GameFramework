---@class BattleFailedType
BattleFailedType = {
    GMNotAllowed = 0,---不允许执行GM命令
    ActiveSkillCDError = 1, --主动技能CD错误
    MovePathNoPoint = 2, --连线队列为空
    StartPathPosInvalid = 3, --第一个位置不合法
    PositionElementNoMatch = 4, --元素不匹配
    ChainPathPickUpGridPosInvalid= 5, --任意门点选格子不合法
    ActivePickUpInvalid = 6, --主动技点选不合法
    ChainPathConnectInvalid =7,--连线连通性非法
    WavePassInvalid =8, --波次通过非法
    SingleDamageTooLarge =9, --单次伤害过高
    TotalDamageTooLarge =10, --总伤害过高
    HeboBaseActiveSkillCannotCastAsTeamLeader = 11, --赫柏主动技专属逻辑：自己是队长时不能释放青春版主动技
    NotEnoughSan = 12, --理智值不够或抵扣理智值的生命值不够
    NotEnoughHP = 13, --需要扣除生命值的技能，没有足够生命值
    CardFull = 14, --杰诺主动技，卡牌已满不能抽牌
    CardNotEnough = 15, --杰诺模块技能，卡牌数量不足
    CardTarPetHasBuff = 16, ---
}
BattleFailedType = BattleFailedType
_enum("BattleFailedType", BattleFailedType)
