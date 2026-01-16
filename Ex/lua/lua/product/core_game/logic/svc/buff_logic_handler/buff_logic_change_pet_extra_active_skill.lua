--[[
    改变星灵 附加主动技
]]
_class("BuffLogicChangePetExtraActiveSkill", BuffLogicBase)
---@class BuffLogicChangePetExtraActiveSkill:BuffLogicBase
BuffLogicChangePetExtraActiveSkill = BuffLogicChangePetExtraActiveSkill

---
function BuffLogicChangePetExtraActiveSkill:Constructor(buffInstance, logicParam)
    self._oriSkillID = logicParam.oriSkillID
    self._skillList = logicParam.skillList
    self._layerType = logicParam.layerType or self._buffInstance:GetBuffEffectType()
end

---
function BuffLogicChangePetExtraActiveSkill:DoLogic()
    local skillID
    local curMarkLayer = self._buffLogicService:GetBuffLayer(self._entity, self._layerType) or 1

    if table.count(self._skillList) == 1 then
        --如果技能列表只有一个，表示直接替换
        skillID = self._skillList[1]
    else
        --技能列表存在多个，根据层数替换

        if curMarkLayer > #self._skillList then
            curMarkLayer = #self._skillList
        end
        skillID = self._skillList[curMarkLayer]
    end

    if not skillID then
        return
    end

    ---@type SkillInfoComponent
    local skillInfoComponent = self._entity:SkillInfo()
    local oriSkillList = skillInfoComponent:GetExtraActiveSkillIDList()
    local newSkillList = {}
    local hasOriSkill = false
    for index, oriSkillID in ipairs(oriSkillList) do
        if oriSkillID == self._oriSkillID then
            hasOriSkill = true
            table.insert(newSkillList,skillID)
        else
            table.insert(newSkillList,oriSkillID)
        end
    end
    if not hasOriSkill then
        return
    end
    skillInfoComponent:SetExtraActiveSkillIDList(newSkillList)

    --将计算结果设置到result中
    local buffResult = BuffResultChangePetExtraActiveSkill:New(self._oriSkillID, skillID)
    return buffResult
end
