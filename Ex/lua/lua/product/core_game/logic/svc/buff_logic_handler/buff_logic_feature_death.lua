--[[
    消亡
]]
_class("BuffLogicFeatureDeath", BuffLogicBase)
---@class BuffLogicFeatureDeath:BuffLogicBase
BuffLogicFeatureDeath = BuffLogicFeatureDeath
---
function BuffLogicFeatureDeath:Constructor(buffInstance, logicParam)
end
---
function BuffLogicFeatureDeath:DoLogic(notify)
    if self._entity:HasDeadMark() then
        return
    end

    ---@type SkillLogicService
    local skillLogic = self._world:GetService("SkillLogic")
    local curHp = self._entity:Attributes():GetCurrentHP()

    ---修改逻辑血量
    self._entity:Attributes():Modify("HP", 0)
    -- Log.debug("BuffLogicFeatureDeath ModifyHP =", endHP, " defender=", self._entity:GetID())

    if self._entity:HasMonsterID() then
        ---@type MonsterShowLogicService
        local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")

        self._entity:AddDeadMark()
        sMonsterShowLogic:DoLogicFeatureDead(self._entity)
    elseif self._entity:HasTrapID() then
        ---@type TrapServiceLogic
        local trapServiceLogic = self._world:GetService("TrapLogic")
        trapServiceLogic:DoTrapFeatureDead(self._entity)
    else
        return
    end

    local buffResult = BuffResultFeatureDeath:New(self._entity:GetID())
    return buffResult
end
