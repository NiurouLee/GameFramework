--[[-------------------------------------
    ActionNightKingCanTailFlick 判断N15的敌方棋子是否能连线移动
--]] -------------------------------------
require "ai_node_new"
---@class ActionNightKingCanTailFlick : AINewNode
_class("ActionNightKingCanTailFlick", AINewNode)
ActionNightKingCanTailFlick = ActionNightKingCanTailFlick
----------------------------------------------------------------
function ActionNightKingCanTailFlick:Constructor()
end
function ActionNightKingCanTailFlick:OnUpdate()
    ---@type Entity
    local ownEntity =self.m_entityOwn
    ---@type Vector2
    local myPos = ownEntity:GetGridPosition()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local newDir,newBodyArea =utilScopeSvc:GetTailFlickSwitchBodyArea(ownEntity,teamEntity)
    for i=2 ,#newBodyArea do
        local area = newBodyArea[i]
        local newPos = area+myPos
        if utilScopeSvc:IsPosBlock(newPos,BlockFlag.MonsterLand) then
            return AINewNodeStatus.Failure
        end
    end
    return AINewNodeStatus.Success
end
