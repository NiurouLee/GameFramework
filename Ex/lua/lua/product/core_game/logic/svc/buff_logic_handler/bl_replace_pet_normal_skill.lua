_class("BuffLogicReplacePetNormalSkill", BuffLogicBase)
---@class BuffLogicReplacePetNormalSkill:BuffLogicBase
BuffLogicReplacePetNormalSkill = BuffLogicReplacePetNormalSkill

function BuffLogicReplacePetNormalSkill:Constructor(buffInstance, logicParam)
    self._skillList = logicParam.skillList
    self._layerType = logicParam.layerType or self._buffInstance:GetBuffEffectType()
end

function BuffLogicReplacePetNormalSkill:DoLogic()
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

    ---@type SkillInfoComponent
    local skillInfoComponent = self._entity:SkillInfo()
    skillInfoComponent:SetNormalSkillID(skillID)
end
