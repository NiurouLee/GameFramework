--[[
    格挡来自敌方队伍中队员的伤害
]]
require "buff_logic_base"
_class("BuffLogicGuardDamageFromTeamMember", BuffLogicBase)
---@class BuffLogicGuardDamageFromTeamMember:BuffLogicBase
BuffLogicGuardDamageFromTeamMember = BuffLogicGuardDamageFromTeamMember

function BuffLogicGuardDamageFromTeamMember:Constructor(buffInstance, logicParam)
end

function BuffLogicGuardDamageFromTeamMember:DoLogic(notify)
    if not self._entity:HasMonsterID() then
        return
    end
    ---@type AttributesComponent
    local cpt = self._buffInstance:Entity():Attributes()
    cpt:SetSimpleAttribute("BuffGuardDamageFromTeamMember",1)
end

-------------------------------------------------------------------------------------------

--[[
    移除 格挡来自敌方队伍中队员的伤害
]]
_class("BuffLogicRemoveGuardDamageFromTeamMember", BuffLogicBase)
BuffLogicRemoveGuardDamageFromTeamMember = BuffLogicRemoveGuardDamageFromTeamMember

function BuffLogicRemoveGuardDamageFromTeamMember:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveGuardDamageFromTeamMember:DoLogic(notify)
    ---@type AttributesComponent
    local cpt = self._buffInstance:Entity():Attributes()
    cpt:RemoveSimpleAttribute("BuffGuardDamageFromTeamMember")
end
