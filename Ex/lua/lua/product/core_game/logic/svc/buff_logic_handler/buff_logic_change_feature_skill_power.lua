--[[
    改变模块技能CD
]]
--------------------------------
---@class EnumChangeFeatureSkillPower
EnumChangeFeatureSkillPower = {
    AllFeatureType = 1, ---所有（使用cd的）模块技能
    SpecificFeatureType = 2, ---指定模块类型
}
_enum("EnumChangeFeatureSkillPower", EnumChangeFeatureSkillPower)
--------------------------------
_class("BuffLogicChangeFeatureSkillPower", BuffLogicBase)
---@class BuffLogicChangeFeatureSkillPower:BuffLogicBase
BuffLogicChangeFeatureSkillPower = BuffLogicChangeFeatureSkillPower

function BuffLogicChangeFeatureSkillPower:Constructor(buffInstance, logicParam)
    self._modifyValue = logicParam.modifyValue or 0
    self._modifyType = logicParam.modifyType or EnumChangeFeatureSkillPower.AllFeatureType
    self._featureTypeList = logicParam.featureTypeList
end

function BuffLogicChangeFeatureSkillPower:DoLogic()
    local featureSkillPowerStateList = {}
    ---@type MainWorld
    local world = self._buffInstance:World()
    local teamEntity = world:Player():GetLocalTeamEntity()
    if self._entity:HasTeam() then
        teamEntity = self._entity
    elseif self._entity:HasPet() then
        teamEntity = self._entity:Pet():GetOwnerTeamEntity()
    end
    ---@type FeatureServiceLogic
    local lsvcFeature = self._world:GetService("FeatureLogic")
    if lsvcFeature then
        local featureTypeList = {}

        if self._modifyType == EnumChangeFeatureSkillPower.AllFeatureType then
            featureTypeList = lsvcFeature:GetFeatureTypeList()
        elseif self._modifyType == EnumChangeFeatureSkillPower.SpecificFeatureType then
            featureTypeList = self._featureTypeList
        end
        for _, featureType in ipairs(featureTypeList) do
            
            local resultFeatureType,curPower,curReady = lsvcFeature:BuffChangeFeatureSkillPower(featureType,self._modifyValue)
            if resultFeatureType then
                local data = FeatureSkillCommonPowerData:New()
                data.power = curPower
                data.ready = curReady
                data.featureType = resultFeatureType
                table.insert(featureSkillPowerStateList,data)
            end
        end
    end

    --成功了才通知
    if #featureSkillPowerStateList > 0 then
        local buffResult = BuffResultChangeFeatureSkillPower:New(featureSkillPowerStateList)
        return buffResult
    end
end
