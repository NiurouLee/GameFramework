---怪物刷新类型
---@class MonsterRefreshPosType
local MonsterRefreshPosType = {
    None = 0,
    Position = 1, --固定位置刷新
    Random = 2, --随机刷新
    PositionTable = 3, --位置集合随机刷新
    PositionHitBack = 4, --固定位置（强制击退）
    PositionAndOffSet = 5, --固定位置加玩家坐标偏移
    SelectFirstCanUse = 6, --选择第一个可以使用的位置
    FarFormPlayerAndInterval = 7, --远离玩家并互相有间隔
    PlayerCentered = 8, --以玩家为中心N圈内不阻挡怪物行走格子上随机位置刷新[不支持黑拳赛]
    MonsterCentered = 9, --以特定MonsterID的怪物为中心N圈内不阻挡怪物行走格子上随机位置刷新[没考虑黑拳赛]
    PositionAndOffSetMultiBoard = 10, --5的多面棋盘版本
    PositionOnExtraBoard = 11, --可以刷在棋盘扩展位置上
    MAX = 99
}
_enum("MonsterRefreshPosType", MonsterRefreshPosType)

---怪物刷新方式
---（N25扩展:不配置指定怪物，默认为全场所有怪物）
---@class MonsterWaveInternalRefreshType
local MonsterWaveInternalRefreshType = {
    None = 0,
    AfterMonsterDead = 1, --列表怪物死亡后刷新怪物
    EveryRoundCount = 2, --每N回合刷新怪物
    WatchTarget = 3, --指定怪物数量少于N个时刷新,除怪物回合外
    AllMonsterDead = 4, --怪物全部死亡
    TargetRound = 5, --指定回合刷新怪物
    RoundResultWatchTarget = 6, --指定怪物数量少于N个时刷新,除主动技阶段和怪物回合
    RoundResultCheckMonsterCount = 7, --回合结算时怪物数量少于N个时刷新
    CompareMonsterNumber = 8, ---怪物剩余数量达到配置条件
    OnlySpecifiedMonsterSurvival = 9, ---只有配置参数内的怪物存活
    --PlayerCenteredAtTargetRound = 7, --在指定回合，以玩家为中心N圈内不阻挡怪物行走格子上随机位置刷新
    --MonsterCenteredAtTargetRound = 8, --在指定回合，以特定MonsterID的怪物为中心N圈内不阻挡怪物行走格子上随机位置刷新（有多个符合条件的中心怪物时，会一起刷新）
    AssignRefreshTypeAndTime = 100, --指定刷新类型和刷新时机（需配置MonsterWaveInternalRefreshType和MonsterWaveInternalTime）
}
_enum("MonsterWaveInternalRefreshType", MonsterWaveInternalRefreshType)

---怪物刷新时机
---@class MonsterWaveInternalTime
local MonsterWaveInternalTime = {
    None = 0,
    ActiveSkill = 1, -- 玩家主动技后
    MonsterTurn = 2, --怪物行动回合一开始   在机关回合前
    RoundResult = 3, --回合结算
    ChainAttack = 4 --连锁技攻击后 极光时刻前
}
_enum("MonsterWaveInternalTime", MonsterWaveInternalTime)

---@class MonsterRefreshExceptionType
local MonsterRefreshExceptionType = {
    None = 0,
    Random = 1, ---随机
    ValidRing = 2, ---有效圈
    BackupTable = 3 ---备选集合中随机一个
}
_enum("MonsterRefreshExceptionType", MonsterRefreshExceptionType)

---@class MonsterPosType
local MonsterPosType = {
    None = 0,
    Position = 1,
    OffSet = 2
}
_enum("MonsterPosType", MonsterPosType)

---@class WaveRefreshModeType
local WaveRefreshModeType = {
    Cumulate = -1 --累计次数刷新，到达配置的次数，就触发
}
_enum("WaveRefreshModeType", WaveRefreshModeType)

--刷新指定波次以外的额外波次参数说明
--特殊处理说明：若BaseRefreshProb数值为WaveRefreshModeType.Cumulate（-1），则代表走累计次数刷新，不走概率刷新，下一个参数RefreshUpProb表示为配置的次数
--- @class LevelCompleteAssignWaveParamExp
local LevelCompleteAssignWaveParamExp = {
    AssignWaveEnd = 1, -- 指定结束波次
    BaseRefreshProb = 2, -- 基础刷新概率A
    RefreshUpProb = 3, -- 每次没有刷新波次增加的概率B
    RoundNum = 4, -- 额外波次刷新回合数
    BaseLevelCompleteCond = 5, -- 基础胜利条件 可填除13与3以外的胜利条件
    BaseCondParam = 6 -- 之后的就是基础胜利条件的参数
}
_enum("LevelCompleteAssignWaveParamExp", LevelCompleteAssignWaveParamExp)

---条件的比较方式
--- @class ConditionCompareType
local ConditionCompareType = {
    Equal = 1, --等于
    NotEqual = 2, --不等于
    Greater = 3, --大于
    NotLess = 4, --大于等于
    Less = 5, --小于
    NotGreater = 6 --小于等于
}
_enum("ConditionCompareType", ConditionCompareType)

--判断A和B的关系
---@param type ConditionCompareType
function CompareFunByType(type, a, b)
    if type == ConditionCompareType.Equal then
        return a == b
    elseif type == ConditionCompareType.NotEqual then
        return a ~= b
    elseif type == ConditionCompareType.Greater then
        return a > b
    elseif type == ConditionCompareType.NotLess then
        return a >= b
    elseif type == ConditionCompareType.Less then
        return a < b
    elseif type == ConditionCompareType.NotGreater then
        return a <= b
    end

    return false
end
