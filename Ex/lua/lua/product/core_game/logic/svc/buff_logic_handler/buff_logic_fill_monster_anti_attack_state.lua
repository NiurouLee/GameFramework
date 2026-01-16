--[[
    反制主动技参数
]]
--------------------------------

--------------------------------
_class("BuffLogicFillMonsterAntiAttackState", BuffLogicBase)
---@class BuffLogicFillMonsterAntiAttackState:BuffLogicBase
BuffLogicFillMonsterAntiAttackState = BuffLogicFillMonsterAntiAttackState

function BuffLogicFillMonsterAntiAttackState:Constructor(buffInstance, logicParam)
end

function BuffLogicFillMonsterAntiAttackState:DoLogic()
    local entity = self._buffInstance:Entity()
    if not entity then
        return
    end

    ---@type AttributesComponent
    local attributeCmpt = entity:Attributes()

    local roundCount = "MaxAntiSkillCountPerRound"
    local curValue = attributeCmpt:GetAttribute(roundCount)
    local newValue = curValue - 1
    if newValue < 0 then
        newValue = 0
    end

    attributeCmpt:Modify(roundCount, newValue)

    --放完主动技当前CD回复到最大CD
    local curAntiCount = attributeCmpt:GetAttribute("WaitActiveSkillCount")
    if curAntiCount == 0 then
        local originalAntiCount = attributeCmpt:GetAttribute("OriginalWaitActiveSkillCount")
        attributeCmpt:Modify("WaitActiveSkillCount", originalAntiCount)
    end

    local buffResult = BuffResultFillMonsterAntiAttackState:New(entity:GetID())
    return buffResult
end
