--[[
    自动战斗：技能释放条件检查
]]
require("auto_fight_service")

function AutoFightService:_CheckCondition_PetJiero()
    --例：CheckJiero<5
    local keyValue = 9999 --让判断不通过
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local curRound = battleStatCmpt:GetLevelTotalRoundCount()
    local isFirstRound = battleStatCmpt:IsFirstRound()
    ---@type FeatureServiceLogic
    local lsvcFeature = self._world:GetService("FeatureLogic")

    if lsvcFeature then
        if lsvcFeature:CanAddCard() then --首先 卡牌满了不能放
            if isFirstRound then
                --牌库有3张相同的卡牌为止
                local checkCount = 3
                local firstRoundEnough = false
                local teamEntity = self._world:Player():GetCurrentTeamEntity()
                if teamEntity then
                    local teamEntityID = teamEntity:GetID()
                    firstRoundEnough = lsvcFeature:GetAutoFightFirstRoundDrawCardEnough(teamEntityID)
                end
                local bEnough = lsvcFeature:HasEnoughSameCard(checkCount)
                if firstRoundEnough or bEnough then
                    keyValue = 9999 --让判断不通过
                    local teamEntity = self._world:Player():GetCurrentTeamEntity()
                    if teamEntity then
                        local teamEntityID = teamEntity:GetID()
                        lsvcFeature:SetAutoFightFirstRoundDrawCardEnough(teamEntityID, true)
                    end
                else
                    keyValue = -1 --让判断通过
                end
            else
                --该回合抽n次
                local teamEntity = self._world:Player():GetCurrentTeamEntity()
                if teamEntity then
                    local teamEntityID = teamEntity:GetID()
                    local curRoundTimes = lsvcFeature:GetDrawCardTimes(teamEntityID, curRound)
                    if curRoundTimes then
                        keyValue = curRoundTimes
                    end
                end
            end
        end
    end

    return keyValue
end

---零恩释放技能的可行性检查：当觉醒主动技二技能后，若热量大于配置，则优先释放一技能，否则优先释放二技能
---@param caster Entity
---@param skillID number
function AutoFightService:_CheckCondition_PetLingEn(caster, skillID)
    --例：CheckLingEn<1
    local keyValue = 9999 --让判断不通过
    local isMulti, index = self:_CheckIsMultiActiveSkill(caster, skillID)

    ---没有觉醒其他主动技时，不检查热量，直接返回可释放
    if isMulti == false then
        return 0
    end

    local otherSkillIndex = 0
    if index == 1 then
        otherSkillIndex = 2
    elseif index == 2 then
        otherSkillIndex = 1
    else
        ---技能Index错误，不可释放
        return keyValue
    end

    ---@type SkillInfoComponent
    local skillInfoCmpt = caster:SkillInfo()
    local otherSkillID = skillInfoCmpt:GetSkillIDByIndex(otherSkillIndex)

    ---检查其他主动技是否可以释放
    local ready = self._utilSvc:GetPetSkillReadyAttr(caster, otherSkillID)
    if ready ~= 1 then
        return 0
    end

    local curLayerCount = 0
    local cfgLayerCount = 0
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID)
    local policyParam = skillConfigData:GetAutoFightPickPosPolicyParam()
    if policyParam then
        local layerType = policyParam.layerType
        ---@type BuffLogicService
        local svc = self._world:GetService("BuffLogic")
        curLayerCount = svc:GetBuffLayer(caster, layerType)

        cfgLayerCount = policyParam.layerCountSkill
    end

    if index == 1 and curLayerCount >= cfgLayerCount then
        ---当前层数大于配置，一技能优先
        keyValue = 0
    elseif index == 2 and curLayerCount < cfgLayerCount then
        ---当前层数小于配置，二技能优先
        keyValue = 0
    end

    return keyValue
end

---检查施法者的传说光灵能量
---@param caster Entity
---@param skillID number
function AutoFightService:_CheckCondition_LegendEnergy(caster)
    --例：CheckLegendEnergy>10
    local keyValue = 0 --让判断不通过

    ---获取传说光灵能量
    ---@type AttributesComponent
    local attributesCmpt = caster:Attributes()
    if attributesCmpt then
        keyValue = attributesCmpt:GetAttribute("LegendPower")
    end
    return keyValue
end
