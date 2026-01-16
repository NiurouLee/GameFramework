---@class TalentType
TalentType = {
    None = 0,
    Buff = 1, --Buff
    MasterSkill = 2, --激活空裔技能模块
    AddRoundCount = 3, --增加回合数
    AddChangeTeamLeaderCount = 4, --增加更换队长次数
    ChooseRelic = 5, --开局选圣物
    MAX = 99 --
}
_enum("TalentType", TalentType)
