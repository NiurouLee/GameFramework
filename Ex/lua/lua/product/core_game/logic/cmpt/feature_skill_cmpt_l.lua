--[[------------------------------------------------------------------------------------------
    FeatureSkillComponent : 模块技属性组件，驱动模块技的施法，逻辑组件
]] --------------------------------------------------------------------------------------------

_class("FeatureSkillComponent", Object)
---@class FeatureSkillComponent: Object
FeatureSkillComponent = FeatureSkillComponent

function FeatureSkillComponent:Constructor()
    self._featureType = -1
    self._featureSkillID = -1
    self._casterEntityID = -1
end

function FeatureSkillComponent:SetFeatureSkillID(featureType,featureSkillID, casterEntityID)
    self._featureType = featureType
    self._featureSkillID = featureSkillID
    self._casterEntityID = casterEntityID
end
function FeatureSkillComponent:GetFeatureType()
    return self._featureType
end
function FeatureSkillComponent:GetFeatureSkillID()
    return self._featureSkillID
end

function FeatureSkillComponent:GetFeatureSkillCasterEntityID()
    return self._casterEntityID
end

function FeatureSkillComponent:ResetFeatureSkillCmpt()
    self._featureSkillID = -1
    self._casterEntityID = -1
end
--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
function Entity:FeatureSkill()
    return self:GetComponent(self.WEComponentsEnum.FeatureSkill)
end

function Entity:HasFeatureSkill()
    return self:HasComponent(self.WEComponentsEnum.FeatureSkill)
end

function Entity:AddFeatureSkill()
    local index = self.WEComponentsEnum.FeatureSkill
    local component = FeatureSkillComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceFeatureSkill()
    local index = self.WEComponentsEnum.FeatureSkill
    local component = FeatureSkillComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveFeatureSkill()
    if self:HasFeatureSkill() then
        self:RemoveComponent(self.WEComponentsEnum.FeatureSkill)
    end
end
