
-- 保留注释，方便根据MatchType搜到这里，避免新加模式时遗漏
-- MatchType2GameMode = {
--     [MatchType.MT_Mission] = GameModeType.NormalBattleMode, ---主线
--     [MatchType.MT_ResDungeon] = GameModeType.NormalBattleMode, ---资源本
--     [MatchType.MT_ExtMission] = GameModeType.NormalBattleMode, ---番外
--     [MatchType.MT_Tower] = GameModeType.NormalBattleMode, ---爬塔
--     [MatchType.MT_Maze] = GameModeType.MazeBattleMode, ---迷宫秘境
--     [MatchType.MT_TalePet] = GameModeType.NormalBattleMode, ---传说光灵
--     [MatchType.MT_LostArea] = GameModeType.NormalBattleMode, ---迷失之地
--     [MatchType.MT_Campaign] = GameModeType.NormalBattleMode, ---活动
--     [MatchType.MT_Conquest] = GameModeType.NormalBattleMode, ---无双关
--     [MatchType.MT_BlackFist] = GameModeType.NormalBattleMode, ---黑拳赛
--     [MatchType.MT_WorldBoss] = GameModeType.NormalBattleMode, ---世界Boss
--     [MatchType.MT_Chess] = GameModeType.ChessBattleMode, ---战棋
--     [MatchType.MT_DifficultyMission] = GameModeType.NormalBattleMode, ---困难关卡
--     [MatchType.MT_SailingMission] = GameModeType.NormalBattleMode, ---大航海关卡
--     [MatchType.MT_MiniMaze] = GameModeType.NormalBattleMode, ---小秘境关卡
--     [MatchType.MT_PopStar] = GameModeType.PopStarMode, ---消灭星星玩法
--     [MatchType.MT_Season] = GameModeType.NormalBattleMode, ---赛季
-- }

---@class MatchType2GameMode: Object
_class("MatchType2GameMode", Object)
MatchType2GameMode = MatchType2GameMode
function MatchType2GameMode.GetGameModeByMatchType(matchType)
    if MatchType.MT_Maze and MatchType.MT_Maze == matchType then
        return GameModeType.MazeBattleMode
    elseif MatchType.MT_Chess and MatchType.MT_Chess == matchType then
        return GameModeType.ChessBattleMode
    elseif MatchType.MT_PopStar and MatchType.MT_PopStar == matchType then
        return GameModeType.PopStarMode
    else
        return GameModeType.NormalBattleMode
    end
end