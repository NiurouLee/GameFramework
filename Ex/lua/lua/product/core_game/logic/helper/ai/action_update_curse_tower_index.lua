--[[-------------------------------------------
    ActionUpdateCurseTowerIndex 设置AI状态
--]] -------------------------------------------
require "ai_node_new"

----------------------------------------------------------------
---@class ActionUpdateCurseTowerIndex : AINewNode
_class("ActionUpdateCurseTowerIndex", AINewNode)
ActionUpdateCurseTowerIndex = ActionUpdateCurseTowerIndex

function ActionUpdateCurseTowerIndex:OnBegin()
    ---@type CurseTowerComponent
    local curseTowerCmpt = self.m_entityOwn:CurseTower()
    if not curseTowerCmpt then 
        self:PrintLog('user is not curse tower!')
        return AINewNodeStatus.Failure
    end

    ---自己的状态可以设置为点亮了
    curseTowerCmpt:SetTowerState(CurseTowerState.Active)

    ---更新全局的索引
    local myTowerIndex = curseTowerCmpt:GetTowerIndex()

    local nextTowerIndex = myTowerIndex + 1
    if nextTowerIndex > 4 then 
        nextTowerIndex = 1
    end

    ---当前回合数
    local levelRound = self._world:BattleStat():GetLevelTotalRoundCount()

    local nextCurseRound = levelRound + 1

    ---@type BattleFlagsComponent
    local battleFlagsCmpt = self._world:BattleFlags()
    battleFlagsCmpt:SetCurrentCurseTowerIndex(nextTowerIndex)
    battleFlagsCmpt:SetCurrentCurseTowerRound(nextCurseRound)

    self:PrintLog('nextTowerIndex=',nextTowerIndex)
end
----------------------------------------------------------------
