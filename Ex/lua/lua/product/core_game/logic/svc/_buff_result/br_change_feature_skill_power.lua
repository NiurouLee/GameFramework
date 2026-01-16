_class("BuffResultChangeFeatureSkillPower", BuffResultBase)
---@class BuffResultChangeFeatureSkillPower : BuffResultBase
BuffResultChangeFeatureSkillPower = BuffResultChangeFeatureSkillPower
---@param featureSkillPowerDataList FeatureSkillCommonPowerData[]
function BuffResultChangeFeatureSkillPower:Constructor(featureSkillPowerDataList)
    self._featureSkillPowerDataList = featureSkillPowerDataList
end

function BuffResultChangeFeatureSkillPower:GetFeatureSkillPowerDataList() 
    return self._featureSkillPowerDataList
end
