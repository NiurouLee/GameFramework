--[[
    根据机关能量改变机关主动技
]]
--------------------------------

--------------------------------
_class("BuffLogicChangeTrapActiveSkillByPower", BuffLogicBase)
---@class BuffLogicChangeTrapActiveSkillByPower:BuffLogicBase
BuffLogicChangeTrapActiveSkillByPower = BuffLogicChangeTrapActiveSkillByPower

function BuffLogicChangeTrapActiveSkillByPower:Constructor(buffInstance, logicParam)
    self._changeSkillList = logicParam.changeSkillList or 0
end

function BuffLogicChangeTrapActiveSkillByPower:DoLogic()
    local trapEntity = self._buffInstance:Entity()
    if not trapEntity then
        return
    end

    ---@type AttributesComponent
    local curAttributeCmpt = trapEntity:Attributes()
    local curPower = curAttributeCmpt:GetAttribute("TrapPower")

    ---@type TrapComponent
    local trapCmpt = trapEntity:Trap()
    local activeSkillID = trapCmpt:GetActiveSkillID()

    for i = 1, #activeSkillID do
        local skillID = activeSkillID[i]
        if table.intable(self._changeSkillList, skillID) then
            local newSkillIndex = math.max(math.min(curPower, #self._changeSkillList), 1)
            local newSkillID = self._changeSkillList[newSkillIndex]
            activeSkillID[i] = newSkillID
            break
        end
    end

    trapCmpt:SetActiveSkillID(activeSkillID)
end
