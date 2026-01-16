--[[@see: https://wiki.h3d.com.cn/pages/viewpage.action?pageId=77138576]]
require("match_message")

_class("ScanFeatureComponent", Object)
---@class ScanFeatureComponent : Object
ScanFeatureComponent = ScanFeatureComponent

function ScanFeatureComponent:Constructor(summonTrapSkillID, forceMovementSkillID)
    ---@type number
    self._summonTrapTemplateSkillID = summonTrapSkillID
    ---@type number
    self._forceMovementTemplateSkillID = forceMovementSkillID
    ---@type SkillConfigData|nil
    self._skillConfigData = nil
    ---@type ScanFeatureActiveSkillType|nil
    self._scanActiveSkillType = nil
    ---@type number|nil
    self._scanTrapID = nil
end

function ScanFeatureComponent:GetSummonTrapTemplateSkillID()
    return self._summonTrapTemplateSkillID
end

function ScanFeatureComponent:GetForceMovementTemplateSkillID()
    return self._forceMovementTemplateSkillID
end

function ScanFeatureComponent:ClearLastScan()
    self._skillConfigData = nil
    self._scanActiveSkillType = nil
    self._scanTrapID = nil
end

---@param data SkillConfigData
function ScanFeatureComponent:SetActiveSkillConfigData(data)
    self._skillConfigData = data
end

---@param skillType ScanFeatureActiveSkillType
---@param trapID number
function ScanFeatureComponent:SetScanResult(skillType, trapID)
    self._scanActiveSkillType = skillType
    self._scanTrapID = trapID
end

function ScanFeatureComponent:GetScanActiveSkillType()
    return self._scanActiveSkillType
end

function ScanFeatureComponent:GetScanTrapID()
    return self._scanTrapID
end

--region Entity plugins
---@return ScanFeatureComponent
function Entity:ScanFeature()
    return self:GetComponent(self.WEComponentsEnum.ScanFeature)
end

function Entity:HasScanFeature()
    return self:HasComponent(self.WEComponentsEnum.ScanFeature)
end

function Entity:AddScanFeature()
    local index = self.WEComponentsEnum.ScanFeature
    local component = ScanFeatureComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceScanFeature()
    local index = self.WEComponentsEnum.ScanFeature
    local component = ScanFeatureComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveScanFeature()
    if self:HasScanFeature() then
        self:RemoveComponent(self.WEComponentsEnum.ScanFeature)
    end
end

--endregion