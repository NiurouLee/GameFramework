---@class TrapDestroyType
TrapDestroyType = {
    DestroyByRound = 1, --回合数销毁
    NotDestroy = 2, --不能销毁
    DestoryByWave = 3, --波次销毁
    DestroyAtRoundResult = 4, ---回合结束时销毁，非黑拳赛生效（黑拳赛全局统一）
}
_enum("TrapDestroyType", TrapDestroyType)

