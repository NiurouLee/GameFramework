---胜利条件枚举
---目前是波次胜利条件，关卡胜利条件枚举都在这里
---@class CompleteConditionType
CompleteConditionType = {
    None = 0,
    AllMonsterDead = 1, --全部怪物死亡（波次结束时使用）
    CollectItems = 2, --拾取指定物品
    WaveEnd = 3, --通过全部波次
    RuneDisappear = 4, --符文消失
    AllBossNotSurvival = 5, --参数里的怪物都未存活，要求必须是最后一波
    MonsterEscape = 6, ---怪物逃跑了, 参数是“逃跑的怪物数量阈值”
    RoundCountLimit = 7, ---限制的回合数， 参数是“回合数阈值”   =   nCur > nMax
    ArriveAtPos = 8, ---到达指定位置
    MonsterDead = 9, ---参数怪物死亡
    AllRefreshMonsterDead = 10, --全部刷新的怪物死亡（波次结束时使用） 参数为非0时，左侧游戏目标显示守护XXX；参数为0时不显示
    AllRefreshMonsterDeadOrRoundCountLimit = 11, --10 or 7
    CheckFlagBuffCount = 12, --计数buff累加到一定次数
    AssignWaveAndRandomNextWave = 13, --指定波次结束关卡并且概率出现下一波次，结算结果按照指定波次计算
    KillAnyMonsterCount = 14, ---击杀任意怪物达到xxx个
    UpHoldAndKillAllInternalRefreshMonster = 15, ---杀死xxx波怪 显示上显示还剩多少波怪
    AllMonsterNotSurvival = 16, ---参数里的怪物都未存活
    RemotePlayerDead = 17, ---敌方队伍死亡
    AllConfigMonsterDead = 18, --參數配置怪物都死亡，每个"|"表示And ，每个","表示OR,可以支持变身会换MonsterID的怪物
    AllConfigMonsterHPLock = 19, -- 在场的指定怪物们同时处于锁血状态（有锁血buff且当前生命值符合要求）
    CombinedCompleteCondition = 20, -- MSG37736 复数胜利条件：同时判断两个条件，可以配置AND/OR
    TrapTypeDeadAndAllMonsterDead = 21, ---参数中的机关类型的机关全部死亡，并且全部怪物死亡
    RoundCountLimitAndCheckMonsterEscape = 22, ---RoundCountLimit和MonsterEscape的组合 存回回合数N且逃跑的怪物数量小于M 参数：N,M
    ChessEscape = 23, ---棋子怪物逃跑，参数1是指定数量，参数2是指定ChessMonsterID
    SelectChessEscape = 24, ---指定棋子怪物逃跑，参数1是指定数量，参数2是指定ChessMonsterID
    CompareMonsterNumber = 25, ---怪物剩余数量达到配置条件
    OnlySpecifiedMonsterSurvival = 26, ---只有配置参数内的怪物存活
    AllMonsterNotSurvivaldifferent = 27, ---参数里的怪物都未存活，和16逻辑一样，文本不同“消灭全部精英敌人”
    ComparePopStarNumber = 28, ---达到消除格子数
    Max = 99
}
_enum("CompleteConditionType", CompleteConditionType)
