--[[
    修改极光时刻所需连锁数（针对队伍）
]]
_class("BuffLogicChangeSuperChainCount", BuffLogicBase)
---@class BuffLogicChangeSuperChainCount:BuffLogicBase
BuffLogicChangeSuperChainCount = BuffLogicChangeSuperChainCount

function BuffLogicChangeSuperChainCount:Constructor(buffInstance, logicParam)
    self._addValue = logicParam.addValue or 0
end

function BuffLogicChangeSuperChainCount:DoLogic(notify)
    ---@type Entity
    local teamEntity = nil
    if self._entity:HasTeam() then
        teamEntity = self._entity
    elseif self._entity:HasPet() then
        teamEntity = self._entity:Pet():GetOwnerTeamEntity()
    end
    if teamEntity then
        ---@type AttributesComponent
        local cpt = teamEntity:Attributes()
        local modifyID = self._buffInstance:BuffSeq()
        cpt:Modify("SuperChainCountAddValue", self._addValue,modifyID)
    end
end

--------------------------------------------------------------------------------

--[[
    恢复修改
]]
_class("BuffLogicRemoveChangeSuperChainCount", BuffLogicBase)
---@class BuffLogicRemoveChangeSuperChainCount:BuffLogicBase
BuffLogicRemoveChangeSuperChainCount = BuffLogicRemoveChangeSuperChainCount

function BuffLogicRemoveChangeSuperChainCount:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveChangeSuperChainCount:DoLogic(notify)
    ---@type Entity
    local teamEntity = nil
    if self._entity:HasTeam() then
        teamEntity = self._entity
    elseif self._entity:HasPet() then
        teamEntity = self._entity:Pet():GetOwnerTeamEntity()
    end
    if teamEntity then
        ---@type AttributesComponent
        local cpt = teamEntity:Attributes()
        local modifyID = self._buffInstance:BuffSeq()
        cpt:RemoveModify("SuperChainCountAddValue", modifyID)
    end
end
