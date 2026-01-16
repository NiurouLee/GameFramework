---主状态枚举
---@class GameStateID
GameStateID = {
    Invalid = 0,
    Loading = 1, --加载
    BattleEnter = 2, --进入战场
    PlayerShow = 3, --创建玩家
    WaveEnter = 4, --初始化波次
    WaitInput = 5, --等待输入
    RoleTurn = 6, --【普攻】
    RoleTurnResult = 7, --普攻结算
    MonsterTurn = 8, --怪物阶段
    MonsterTurnResult = 9, --怪物结算
    PieceRefresh = 10, --刷格子
    RoundResult = 11, --回合结算
    BattleResult = 12, --战斗结算
    BattleExit = 13, --退局
    ActiveSkill = 14, --【大招】
    ChainAttack = 15, --【连锁技】
    MonsterBuffCalc = 16,
    PlayerBuffCalc = 17,
    PreviewActiveSkill = 18, --大招预览
    WaveResult = 19, --波次结算
    WaveSwitch = 20, --波次切换
    BoardShow = 21, --棋盘展示
    PickUpActiveSkillTarget = 22, --拾取主动技目标
    WaitInputChain = 25, --连锁预览
    PickUpChainSkillTarget = 26, --拾取连锁目标
    PreChain = 27, --连锁前
    RoundEnter = 28, --回合开始
    FirstWaveEnter = 29, --开场
    PreviewChessPet = 30, ---预览棋子光灵
    PickUpChessPet = 31, ---点选棋子光灵
    ChessPetMove = 32,
    ChessPetAttack = 33,
    ChessPetMoveAndAttack = 34,
    ChessPetResult = 35,
    RoleChangeTeamLeader = 36, --玩家换队长
    PersonaSkill = 37, --P5合击技
    WaveResultAward = 38, --波次结束奖励（小秘境）
    WaveResultAwardApply = 39, --波次结束奖励应用（小秘境）
    MirageEnter = 40, --幻境进入
    MirageWaitInput = 41, --幻境等待输入
    MirageRoleTurn = 42, --幻境玩家回合
    MirageMonsterTurn = 43, --幻境怪物回合
    MirageEnd = 44, --幻境结束
    
    --region 消灭星星
    PopStarLoading = 1001,
    PopStarBattleEnter = 1002,
    PopStarWaveEnter = 1003,
    PopStarRoundEnter = 1004,
    PopStarPieceRefresh = 1005,
    PopStarTrapTurn = 1006,
    PopStarRoundResult = 1007,
    PopStarWaveResult = 1008,
    PopStarBattleResult = 1009,
    --endregion
}
_enum("GameStateID", GameStateID)
