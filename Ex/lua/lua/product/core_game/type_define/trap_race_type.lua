---@class TrapRaceType
TrapRaceType = {
    Team = 1, --队伍
    Pet = 2, --星灵
    Monster = 3, --怪物
    All = 4, --全体
    FilterByBuff = 5, --通过buff筛选
    FriendTeam = 6,
    EnemyTeam = 7,
    AllTeam = 8, --黑拳赛里两个team都能触发
    ChessPet = 9, --棋子
    None = 10 ,---不会触发
    MAX = 99
}

---
PvpTrapRaceType = {
    [TrapRaceType.Team] = TrapRaceType.FriendTeam,
    [TrapRaceType.Pet] = TrapRaceType.FriendTeam,
    [TrapRaceType.Monster] = TrapRaceType.EnemyTeam
}
