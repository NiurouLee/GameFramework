--[[-------------------------------------
    ActionNightKingCanCounterAttack 判断N15的敌方棋子是否能连线移动
--]] -------------------------------------
require "ai_node_new"
---@class ActionNightKingCanCounterAttack : AINewNode
_class("ActionNightKingCanCounterAttack", AINewNode)
ActionNightKingCanCounterAttack = ActionNightKingCanCounterAttack
----------------------------------------------------------------
function ActionNightKingCanCounterAttack:Constructor()
end

function ActionNightKingCanCounterAttack:OnUpdate()
    ---@type Entity
    local ownEntity =self.m_entityOwn
    ---@type Vector2
    local myPos = ownEntity:GetGridPosition()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    if not utilScopeSvc:IsNightKingCanCounterAttack(ownEntity,teamEntity) then
        Log.fatal("NightKingCanCounterAttack Failure")
        return AINewNodeStatus.Failure
    end
    local newDir,newBodyArea =utilScopeSvc:GetCounterAttackSwitchBodyArea(ownEntity,teamEntity)
    for i=2 ,#newBodyArea do
        local area = newBodyArea[i]
        local newPos = area+myPos
        if utilScopeSvc:IsPosBlock(newPos,BlockFlag.MonsterLand) then
            Log.fatal("NightKingCanCounterAttack Failure")
            return AINewNodeStatus.Failure
        end
    end
    Log.fatal("NightKingCanCounterAttack Success")
    return AINewNodeStatus.Success
end