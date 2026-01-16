--[[
    调整所有（使用cd的）模块技能的cd配置
]]
require("buff_logic_base")

---@class ModifyAllFeatureSkillCdOffType
local ModifyAllFeatureSkillCdOffType = {
    Add = 1, ---累加
    Set = 2,---设置
}
_enum("ModifyAllFeatureSkillCdOffType",ModifyAllFeatureSkillCdOffType)

_class("BuffLogicChangeAllFeatureSkillCdOff", BuffLogicBase)
---@class BuffLogicChangeAllFeatureSkillCdOff: BuffLogicBase
BuffLogicChangeAllFeatureSkillCdOff = BuffLogicChangeAllFeatureSkillCdOff

function BuffLogicChangeAllFeatureSkillCdOff:Constructor(buffInstance, logicParam)
    self._modifyValue = logicParam.modValue or 1
    self._modifyType = logicParam.modType or ModifyAllFeatureSkillCdOffType.Add
    self._featureList = logicParam.featureList --如果有，则只影响这几种模块的cd
end

function BuffLogicChangeAllFeatureSkillCdOff:DoLogic(notify)
    ---@type FeatureServiceLogic
    local lsvcFeature = self._world:GetService("FeatureLogic")
    if self._featureList then
        for _, featureType in ipairs(self._featureList) do
            local oldCdOff = lsvcFeature:GetSpecificFeatureSkillCdOff(featureType)
            local curCdOff = oldCdOff
            if self._modifyType == ModifyAllFeatureSkillCdOffType.Add then
                curCdOff = oldCdOff + self._modifyValue
            elseif self._modifyType == ModifyAllFeatureSkillCdOffType.Set then
                curCdOff = self._modifyValue
            end
            lsvcFeature:SetSpecificFeatureSkillCdOff(featureType,curCdOff)
        end
    else
        local oldCdOff = lsvcFeature:GetAllFeatureSkillCdOff()
        local curCdOff = oldCdOff
        if self._modifyType == ModifyAllFeatureSkillCdOffType.Add then
            curCdOff = oldCdOff + self._modifyValue
        elseif self._modifyType == ModifyAllFeatureSkillCdOffType.Set then
            curCdOff = self._modifyValue
        end
        lsvcFeature:SetAllFeatureSkillCdOff(curCdOff)
    end
    
end
