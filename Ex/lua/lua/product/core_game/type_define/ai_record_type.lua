---@class AIRecordType
AIRecordType = {
    PreWalk         = 1, ---前置
    BeforeCaster    = 2, ---行走前
    NormalAttack    = 3, ---普攻
    ActionSpell     = 4, ---施法
    AfterCaster     = 5, ---行走后
    AntiAttack      = 6, ---反制
    RoundResult     = 7, ---回合结算
}
_enum("AIRecordType", AIRecordType)
