---@class AILogicPeriodType
local AILogicPeriodType = {
    Main = 1, ---主AI逻辑：在怪物回合内调用
    Prev = 2, ---前置AI：
    Anti = 3, ---反制
    BeforeMain = 5, ---怪物阶段，主AI之前执行
    AfterMain = 6, ---怪物阶段，主AI之后执行
    RoundResult = 7, ---回合结算
    RoundEnterBeforePlayer = 8 ---玩家行动前
}
_enum("AILogicPeriodType", AILogicPeriodType)
AILogicPeriodType = AILogicPeriodType

---@class AILogicOrderType
local AILogicOrderType = {
    BaseOrder = 1000 ---全部通用的同时移动普攻AI次序
}
_enum("AILogicOrderType", AILogicOrderType)
----------------------------------------------------------------

---@class AINewNodeStatus
AINewNodeStatus = {
    Ready = 0, --起始状态
    Running = 1, --运行
    Success = 2, --成功
    Failure = 3, --失败
    Other = 10 --其他状态
}
_enum("AINewNodeStatus", AINewNodeStatus)
----------------------------------------------------------------

---@class AITargetType
AITargetType = {
    Normal = 0, --常规，有玩家打玩家，有守护机关在，优先打守护机关。
    Team = 1 --玩家队伍，无视守护机关
}
_enum("AITargetType", AITargetType)
----------------------------------------------------------------

---@class AIEndReasonType
AIEndReasonType = {
    NoMobility = 1, --行动力不足
    SelfDead = 2, --自身死亡
    TargetDead = 3, --目标死亡
    SkipTurn = 4, --跳过（被晕）
    RoundEnd = 5 --回合结束
}
_enum("AIEndReasonType", AIEndReasonType)
----------------------------------------------------------------

---@class AIRideStateType
AIRideStateType = {
    NoRide = 1, --未骑乘（在格子上）
    RideOnTrap = 2, --在机关上
    RideOnMonster = 3, --在怪物上
    BeRide = 4, --被骑乘
    NoRideInRange = 5, --未骑乘在指定范围内的机关或怪物上
}
_enum("AIRideStateType", AIRideStateType)
----------------------------------------------------------------

---@class AIEntityInTargetRangeType
AIEntityInTargetRangeType = {
    NoRideInRange = 1, --目标范围内有机关，但未骑乘在指定范围内的机关或怪物上
    RideOnTrapInRange = 2, --目标范围内有机关且在机关上
    RideOnMonsterInRange = 3, --目标范围内有机关且在怪物上
    NotInRange = 4, --目标范围内无机关
}
_enum("AIEntityInTargetRangeType", AIEntityInTargetRangeType)
----------------------------------------------------------------

---@class AIAlphaRoundCount
AIAlphaRoundCount = {
    First = 1, --第一回合
    Second = 2, --第二回合
    Third = 3, --第三回合
}
_enum("AIAlphaRoundCount", AIAlphaRoundCount)
----------------------------------------------------------------
