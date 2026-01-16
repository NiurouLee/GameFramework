--[[
    ActionCheckTowerIndex 检测诅咒塔的索引号是否可以施法
--]] 
require "action_is_base"
_class("ActionCheckCurseTowerIndex", ActionIsBase)
---@class ActionCheckCurseTowerIndex:ActionIsBase
ActionCheckCurseTowerIndex = ActionCheckCurseTowerIndex


function ActionCheckCurseTowerIndex:OnUpdate()
    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()

    ---@type CurseTowerComponent
    local curseTowerCmpt = self.m_entityOwn:CurseTower()
    if not curseTowerCmpt then 
        return AINewNodeStatus.Failure
    end

    local myTowerIndex = curseTowerCmpt:GetTowerIndex()

    ---当前回合数
    local levelRound = self._world:BattleStat():GetLevelTotalRoundCount()

    ---@type BattleFlagsComponent
    local battleFlagsCmpt = self._world:BattleFlags()
    local currentTowerIndex = battleFlagsCmpt:GetCurrentCurseTowerIndex()
    local canCurseRound = battleFlagsCmpt:GetCurrentCurseTowerRound()

    if canCurseRound ~= levelRound then 
        return AINewNodeStatus.Failure
    end

    if currentTowerIndex ~= myTowerIndex then 
        return AINewNodeStatus.Failure
    end

    return AINewNodeStatus.Success
end
