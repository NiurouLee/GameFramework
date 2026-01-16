--[[
    UILogicPetHelper : ui用光灵相关helper类
]]

---@class UILogicPetHelper: Object
_class( "UILogicPetHelper", Object )
UILogicPetHelper = UILogicPetHelper

function UILogicPetHelper:Constructor()
end

---@return boolean
---@param skillTriggerType number SkillTriggerType
---对应触发类型的主动技是否显示冷却时间
function UILogicPetHelper.ShowSkillEnergy(skillTriggerType)
    return skillTriggerType ~= SkillTriggerType.LegendEnergy and skillTriggerType ~= SkillTriggerType.BuffLayer
end