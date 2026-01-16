--[[https://wiki.h3d.com.cn/pages/viewpage.action?pageId=77138576]]

--region Cfg.cfg_trap_scan annotation
---@class CfgTrapScan
---@field ID number
---@field Name string
---@field Desc string
---@field SortOrder number
---@field Icon string|nil
---@field PetID number|nil
---@field Energy number
---@field PickUpScopeType table|nil
---@field PickUpInvalidScopeList table|nil
---@field GlobalMaxCount number|nil
---@field Buff table|nil
---@field PreviewList table|nil
--endregion

require("command_base_handler")
require("match_message")
require("scan_feature_command")

_class("ScanFeatureCommandHandler", CommandBaseHandler)
---@class ScanFeatureCommandHandler: CommandBaseHandler
ScanFeatureCommandHandler = ScanFeatureCommandHandler

---@param cmd ScanFeatureCommand
function ScanFeatureCommandHandler:DoHandleCommand(cmd)
    local scanSkillType = cmd:GetActiveSkillType()
    local trapID = cmd:GetScanTrapID()
    --扫描模块是阿克希亚光灵的专属逻辑，下面代码没有考虑到有多个携带扫描模块的光灵同时出现
    local globalLogicFeatureEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.LogicFeature)
    local e = globalLogicFeatureEntities[1]

    if not e then
        Log.exception("ScanFeatureCommandHandler: no LogicFeatureComponent found. ")
        return
    end

    if not self._world:GetService("FeatureLogic"):HasFeatureType(FeatureType.Scan) then
        Log.exception("ScanFeatureCommandHandler: no FeatureType.Scan in current match. ")
        return
    end

    local cLogicFeature = e:LogicFeature()
    cLogicFeature:SetScanResult(scanSkillType, trapID)

    local activeSkillID = cLogicFeature:GetScanSummonTrapSkillID()

    ---@type SkillConfigData
    local skillConfigData

    ---@type Entity[]
    local globalMatchPetGroup = self._world:GetGroupEntities(self._world.BW_WEMatchers.MatchPet)
    for _, petEntity in ipairs(globalMatchPetGroup) do
        local matchPet = petEntity:MatchPet():GetMatchPet()
        local featureList = matchPet:GetFeatureList() or {feature = {}}
        if featureList.feature[FeatureType.Scan] then
            if scanSkillType == ScanFeatureActiveSkillType.SummonTrap then
                -- 使用自带的召唤，没有那么复杂，直接用配置的技能执行就好
                activeSkillID = cLogicFeature:GetScanSummonTrapSkillID()
                skillConfigData = self._world:GetService("Config"):GetSkillConfigData(activeSkillID)
            elseif scanSkillType == ScanFeatureActiveSkillType.ForceMovement then
                -- 强制位移没有那么复杂，直接用配置的技能执行就好
                activeSkillID = cLogicFeature:GetScanForceMovementSkillID()
                skillConfigData = self._world:GetService("Config"):GetSkillConfigData(activeSkillID)
            elseif scanSkillType == ScanFeatureActiveSkillType.SummonScanTrap then
                activeSkillID = cLogicFeature:GetScanSummonScanTrapSkillID()
                -- 最复杂的情况：召唤不同的机关时，技能的能量消耗、点选范围、技能描述都是不同的，这里的实现是构造一个新的SkillConfigData
                ---@type CfgTrapScan
                local cfgTrapScan = Cfg.cfg_trap_scan[trapID]
                if not cfgTrapScan then
                    Log.exception("ScanFeatureCommandHandler: invalid trapID: ", tostring(trapID))
                    return
                end
                local templateSkillConfigData = self._world:GetService("Config"):GetSkillConfigData(activeSkillID, petEntity, true)
                local tmpSkillConfig = {
                    PickUpScopeType = cfgTrapScan.PickUpScopeType,
                    PickUpInvalidScopeList = cfgTrapScan.PickUpInvalidScopeList,
                    PreviewList = cfgTrapScan.PreviewList or templateSkillConfigData.PreviewList
                }
                ---@type ConfigDecorationService
                local cfgDecoSvc = self._world:GetService("ConfigDecoration")
                skillConfigData = cfgDecoSvc:GenerateSkillConfigData(activeSkillID, {
                    _skillDesc = cfgTrapScan.Desc,
                    _triggerParam = cfgTrapScan.Energy
                })
                skillConfigData:ParsePreview(tmpSkillConfig)
            else
                Log.exception("ScanFeatureCommandHandler: invalid active skill type: ", tostring(scanSkillType))
                return
            end

            petEntity:SkillInfo():SetActiveSkillID(skillConfigData:GetID())
            --把新的SkillConfigData写在身上，在主动技的执行部分，这将替换掉默认取出的SkillConfigData
            cLogicFeature:SetActiveSkillConfigData(skillConfigData)

            local matchPet = petEntity:MatchPet():GetMatchPet()
            local featureList = matchPet:GetFeatureList() or {feature = {}}
            if featureList.feature[FeatureType.Scan] then
                petEntity:SkillInfo():SetActiveSkillID(skillConfigData:GetID())
            end
            local requiredEnergy = skillConfigData:GetSkillTriggerParam()
            local currentEnergy = petEntity:Attributes():GetAttribute("LegendPower")
            local isReady = currentEnergy >= requiredEnergy and 1 or 0
            ---@type BuffLogicService
            local blsvc = self._world:GetService("BuffLogic")
            blsvc:ChangePetActiveSkillReady(petEntity, isReady)

            --MSG65914/MSG65915
            local oldActiveSkillConfig = cLogicFeature:GetActiveSkillConfigData()
            if not oldActiveSkillConfig then
                oldActiveSkillConfig = self._world:GetService("Config"):GetSkillConfigData(petEntity:SkillInfo():GetActiveSkillID())
            end
            local previouslyReady = oldActiveSkillConfig:GetSkillTriggerParam() >= requiredEnergy

            if self._world:RunAtClient() then
                local pstID = petEntity:PetPstID():GetPstID()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.ScanFeatureReplaceUIActiveSkillID, pstID, skillConfigData:GetID(), isReady, previouslyReady)
            end

            break -- 约定只有一个光灵使用该模块
        end
    end
end
