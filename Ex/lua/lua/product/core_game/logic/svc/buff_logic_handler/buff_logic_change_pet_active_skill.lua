--[[
    改变星灵主动技能
]]
_class("BuffLogicChangePetActiveSkill", BuffLogicBase)
---@class BuffLogicChangePetActiveSkill:BuffLogicBase
BuffLogicChangePetActiveSkill = BuffLogicChangePetActiveSkill

---
function BuffLogicChangePetActiveSkill:Constructor(buffInstance, logicParam)
    self._skillList = logicParam.skillList
    self._layerType = logicParam.layerType or self._buffInstance:GetBuffEffectType()
    self._replaceOriSkillID = logicParam.replaceOriSkillID--配这个，则表示需要当前技能id是该id时才进行替换
    self._refreshMaxPower = logicParam.refreshMaxPower--在新技能的cd和原技能不同时，刷新MaxPower属性
end

---
function BuffLogicChangePetActiveSkill:DoLogic()
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
    local curSkillID = skillInfoComponent:GetActiveSkillID()
    if skillID == curSkillID then
        ---替换的技能ID与当前技能ID一致，则直接返回
        return
    end
    if self._replaceOriSkillID then
        if curSkillID ~= self._replaceOriSkillID then
            return
        end
    end
    skillInfoComponent:SetActiveSkillID(skillID)
    if self._refreshMaxPower then
        ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---@type SkillConfigData
        local activeSkillConfigData = configService:GetSkillConfigData(skillID)
        if activeSkillConfigData then
            local skillTriggerType = activeSkillConfigData:GetSkillTriggerType()
            if skillTriggerType == SkillTriggerType.Energy then
                local skillTriggerParam = activeSkillConfigData:GetSkillTriggerParam()
                ---@type UtilDataServiceShare
                local utilData = self._world:GetService("UtilData")
                utilData:SetPetMaxPowerAttr(self._entity,skillTriggerParam,skillID)
            end
        end
    end
    --将计算结果设置到result中
    local buffResult = BuffResultChangePetActiveSkill:New(curMarkLayer, skillID)
    return buffResult
end
