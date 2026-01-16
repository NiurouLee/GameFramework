--[[
    LogicFeatureComponent : 存放feature公共逻辑数据
]]

require("match_message")

_class( "LogicFeatureComponent", Object )
---@class LogicFeatureComponent: Object
LogicFeatureComponent = LogicFeatureComponent
---
function LogicFeatureComponent:Constructor()
    self._featureDataDic = {}

    self._dayNightData = {}
    self._sanModifyTimes = 0--san值修改次数（每次调用增减都计数，变动为0也计入）
    self._personaInfo = {}
    self._cardInfo = {}
    self._featureSkillCommon = FeatureSkillCommonData:New()
    self._drawCardRecord = {}--本局抽牌记录
    self._autoFightFirstRoundDrawCardEnough = {}--自动战斗 第一回合抽到牌库有3张相同，本回合就不做抽牌 记录
    self._drawCardWeight = {}--随机抽牌时的权重，初始全是5，抽到某张后，该卡牌的权重重置为5，另外两种权重加1,

    --region 阿克希亚-扫描模块数据
    ---@type number
    self._summonTrapSkillID = nil
    ---@type number
    self._forceMovementSkillID = nil
    ---@type number
    self._summonScanTrapSkillID = nil

    ---@type SkillConfigData|nil
    self._skillConfigData = nil
    ---@type ScanFeatureActiveSkillType|nil
    self._scanActiveSkillType = nil
    ---@type number|nil
    self._scanTrapID = nil
    --endregion
end

---增加模块信息
---@param featureType FeatureType
function LogicFeatureComponent:AddFeatureData(featureType,featureData)
    self._featureDataDic[featureType] = featureData
end
---查询模块信息
function LogicFeatureComponent:GetFeatureData(featureType)
    return self._featureDataDic[featureType]
end
---查询模块类型列表
function LogicFeatureComponent:GetFeatureTypeList()
    local typeList = {}
    for k,v in pairs(self._featureDataDic) do
        table.insert(typeList,k)
    end
    return typeList
end
--------------------------------San---------------------------------------
---San修改计数
function LogicFeatureComponent:RecordModifySanTimes()
    self._sanModifyTimes = self._sanModifyTimes + 1
    return self._sanModifyTimes
end
function LogicFeatureComponent:GetModifySanTimes()
    return self._sanModifyTimes
end
--------------------------------San End-----------------------------------

--------------------------------昼夜-------------------------------------------
function LogicFeatureComponent:SetDayNightData(state,restRound)
    self._dayNightData.state = state
    self._dayNightData.restRound = restRound
end
function LogicFeatureComponent:GetDayNightData()
    return self._dayNightData.state,self._dayNightData.restRound
end
function LogicFeatureComponent:SetDayNightIgnoreFirstRoundCheck(bIgnore)
    self._dayNightData.ignoreFirstRoundCheck = bIgnore
end
function LogicFeatureComponent:GetDayNightIgnoreFirstRoundCheck()
    return self._dayNightData.ignoreFirstRoundCheck
end
--------------------------------昼夜 End-------------------------------------------
--------------------------------P5-------------------------------------------
function LogicFeatureComponent:SetPersonaPetCount(petCount)
    self._personaInfo.petCount = petCount
end
function LogicFeatureComponent:GetPersonaPetCount()
    return self._personaInfo.petCount
end
--------------------------------P5 End-------------------------------------------

--------------------------------选牌-------------------------------------------
function LogicFeatureComponent:SetCardSkillDic(skillDic)
    self._cardInfo.skillDic = skillDic
end
function LogicFeatureComponent:GetCardSkillDic()
    return self._cardInfo.SkillDic
end
function LogicFeatureComponent:GetCardSkillID(index)
    return self._cardInfo.SkillDic[index]
end
function LogicFeatureComponent:ClearCards()
    self._cardInfo.Cards = {}
end
function LogicFeatureComponent:SetCardMax(maxCount)
    self._cardInfo.MaxCount = maxCount or 0
end
function LogicFeatureComponent:GetCardMax()
    return self._cardInfo.MaxCount
end
function LogicFeatureComponent:GetCurCardCount()
    local total = 0
    if self._cardInfo.Cards then
        for k,v in pairs(self._cardInfo.Cards) do
            total = total + v
        end
    end
    return total
end
function LogicFeatureComponent:CanAddCard()
    local canDraw = self:GetCurCardCount() < self:GetCardMax()
    return canDraw
end
function LogicFeatureComponent:AddCard(cardType)
    if not self._cardInfo.Cards then
        self._cardInfo.Cards = {}
    end
    if not self:CanAddCard() then
        return
    end
    if not self._cardInfo.Cards[cardType] then
        self._cardInfo.Cards[cardType] = 0
    end
    self._cardInfo.Cards[cardType] = self._cardInfo.Cards[cardType] + 1
end
function LogicFeatureComponent:GetCards()
    if not self._cardInfo.Cards then
        self._cardInfo.Cards = {}
    end
    return self._cardInfo.Cards
end
function LogicFeatureComponent:CostCard(useCards)
    if not self._cardInfo.Cards then
        self._cardInfo.Cards = {}
    end
    if useCards and #useCards > 0 then
        for i,v in ipairs(useCards) do
            local old = self._cardInfo.Cards[v]
            local cur = old - 1
            if cur < 0 then
                cur = 0
            end
            self._cardInfo.Cards[v] = cur
        end
    end
end
function LogicFeatureComponent:RecordDrawCard(teamEntityID,curRound,cardType)
    if self._drawCardRecord then
        if not self._drawCardRecord[teamEntityID] then
            self._drawCardRecord[teamEntityID] = {}
        end
        local teamRecord = self._drawCardRecord[teamEntityID]
        if not teamRecord[curRound] then
            teamRecord[curRound] = {}
        end
        local defaultWeightNum = 5
        local weightIncreaseNum = 1
        ---@type FeatureEffectParamCard
        local featureData = self:GetFeatureData(FeatureType.Card)
        if featureData then
            defaultWeightNum = featureData:GetDefaultWeightNum()
            weightIncreaseNum = featureData:GetWeightIncreaseNum()
        end
        local roundRecord = teamRecord[curRound]
        table.insert(roundRecord,cardType)
        if self._drawCardWeight then
            if not self._drawCardWeight[teamEntityID] then
                self._drawCardWeight[teamEntityID] = {defaultWeightNum,defaultWeightNum,defaultWeightNum}--初始权重
            end
            local weightTb = self._drawCardWeight[teamEntityID]
            for weightCard,weight in ipairs(weightTb) do
                if cardType == weightCard then
                    weightTb[weightCard] = defaultWeightNum--重置为5
                else
                    weightTb[weightCard] = weight + weightIncreaseNum
                end
            end
        end
    end
end
function LogicFeatureComponent:GetDrawCardTimes(teamEntityID,round)
    if not teamEntityID then
        return
    end
    if round then
        local teamRecord = self._drawCardRecord[teamEntityID]
        if teamRecord then
            local roundRecord = teamRecord[round]
            if roundRecord then
                return #roundRecord
            end
        end
    else
        --所有回合加起来
        local teamRecord = self._drawCardRecord[teamEntityID]
        if teamRecord then
            local totalTimes = 0
            for round,records in pairs(teamRecord) do --pairs 遍历统计
                totalTimes = totalTimes + #records
            end
            return totalTimes
        end
    end
    return 0
end
function LogicFeatureComponent:SetAutoFightFirstRoundDrawCardEnough(teamEntityID,bEnough)
    self._autoFightFirstRoundDrawCardEnough[teamEntityID] = bEnough
end
function LogicFeatureComponent:GetAutoFightFirstRoundDrawCardEnough(teamEntityID)
    return self._autoFightFirstRoundDrawCardEnough[teamEntityID]
end
function LogicFeatureComponent:GetRandomDrawCardWeight(teamEntityID)
    local defaultWeightNum = 5
    ---@type FeatureEffectParamCard
    local featureData = self:GetFeatureData(FeatureType.Card)
    if featureData then
        defaultWeightNum = featureData:GetDefaultWeightNum()
    end
    if self._drawCardWeight then
        if not self._drawCardWeight[teamEntityID] then
            self._drawCardWeight[teamEntityID] = {defaultWeightNum,defaultWeightNum,defaultWeightNum}--初始权重
        end
        return self._drawCardWeight[teamEntityID]
    end
    return {defaultWeightNum,defaultWeightNum,defaultWeightNum}--初始权重
end
--------------------------------选牌 end-------------------------------------------
--------------------------------空裔技能-------------------------------------------
--------------------------------空裔技能 end-------------------------------------------
--region-----------------------------------ScanFeature-----------------------------------
--[[@see: https://wiki.h3d.com.cn/pages/viewpage.action?pageId=77138576]]
function LogicFeatureComponent:InitScanFeature(summonTrapSkillID, forceMovementSkillID, summonScanTrapSkillID, emptySkillID)
    self._summonTrapSkillID = summonTrapSkillID
    self._forceMovementSkillID = forceMovementSkillID
    self._summonScanTrapSkillID = summonScanTrapSkillID
    self._emptySkillID = emptySkillID

    self._scanActiveSkillType = ScanFeatureActiveSkillType.SummonTrap
end

function LogicFeatureComponent:GetScanSummonTrapSkillID()
    return self._summonTrapSkillID
end

function LogicFeatureComponent:GetScanForceMovementSkillID()
    return self._forceMovementSkillID
end

function LogicFeatureComponent:GetScanSummonScanTrapSkillID()
    return self._summonScanTrapSkillID
end

function LogicFeatureComponent:GetScanEmptySkillID()
    return self._summonScanTrapSkillID
end

function LogicFeatureComponent:ClearLastScan()
    self._skillConfigData = nil
    self._scanActiveSkillType = nil
    self._scanTrapID = nil
end

---@param data SkillConfigData
function LogicFeatureComponent:SetActiveSkillConfigData(data)
    self._skillConfigData = data
end

function LogicFeatureComponent:GetActiveSkillConfigData()
    return self._skillConfigData
end

---@param skillType ScanFeatureActiveSkillType
---@param trapID number
function LogicFeatureComponent:SetScanResult(skillType, trapID)
    self._scanActiveSkillType = skillType
    self._scanTrapID = trapID
end

function LogicFeatureComponent:GetScanActiveSkillType()
    return self._scanActiveSkillType
end

function LogicFeatureComponent:GetScanTrapID()
    return self._scanTrapID
end
--endregion--------------------------------ScanFeature-----------------------------------
-----------------------------------技能通用-------------------------------------------
_class("FeatureSkillCommonData", Object)
---@class FeatureSkillCommonData: Object
FeatureSkillCommonData = FeatureSkillCommonData
function FeatureSkillCommonData:Constructor()
    self.featureSkillID = {}--key:featureType value:skillID
    self.skillHolderDic = {}--key:featureType value:holderID
    self.powerInfo = {}--key featureType value:FeatureSkillCommonPowerData
    self.lastRoundInfo = {}--key:featureType value:round
    self.featureSkillCdOff = 0 --调整模块技能cd
    self.specificFeatureSkillCdOff = {}--额外调整指定模块技能cd
end
_class("FeatureSkillCommonPowerData", Object)
---@class FeatureSkillCommonPowerData: Object
FeatureSkillCommonPowerData = FeatureSkillCommonPowerData
function FeatureSkillCommonPowerData:Constructor()
    self.power = 0
    self.ready = 0
    self.delayModifyPowerValue = 0--延迟修改cd
    self.featureType = 0--给buff修改cd用
end
function LogicFeatureComponent:SetFeatureSkillID(featureType,skillID)
    self._featureSkillCommon.featureSkillID[featureType] = skillID
end
function LogicFeatureComponent:GetFeatureSkillID(featureType)
    return self._featureSkillCommon.featureSkillID[featureType]
end
function LogicFeatureComponent:SetFeatureSkillHolderID(featureType,holderID)
    self._featureSkillCommon.skillHolderDic[featureType] = holderID
end
function LogicFeatureComponent:GetFeatureSkillHolderID(featureType)
    return self._featureSkillCommon.skillHolderDic[featureType]
end
function LogicFeatureComponent:SetFeatureSkillCurPower(featureType,power,ready)
    if not self._featureSkillCommon.powerInfo[featureType] then
        self._featureSkillCommon.powerInfo[featureType] = FeatureSkillCommonPowerData:New()
    end
    local featurePower = self._featureSkillCommon.powerInfo[featureType]
    featurePower.power = power
    if ready then
        featurePower.ready = ready
    end
end
function LogicFeatureComponent:GetFeatureSkillCurPower(featureType)
    if self._featureSkillCommon.powerInfo then
        local featurePower = self._featureSkillCommon.powerInfo[featureType]
        if featurePower then
            return featurePower.power,featurePower.ready
        end
    end
    return 5,0
end
function LogicFeatureComponent:SetFeatureSkillDelayModifyPower(featureType,delayModifyPower)
    if not self._featureSkillCommon.powerInfo[featureType] then
        self._featureSkillCommon.powerInfo[featureType] = FeatureSkillCommonPowerData:New()
    end
    local featurePower = self._featureSkillCommon.powerInfo[featureType]
    featurePower.delayModifyPowerValue = delayModifyPower
end
function LogicFeatureComponent:GetFeatureSkillDelayModifyPower(featureType)
    if self._featureSkillCommon.powerInfo then
        local featurePower = self._featureSkillCommon.powerInfo[featureType]
        if featurePower then
            return featurePower.delayModifyPowerValue
        end
    end
    return 0
end
function LogicFeatureComponent:GetLastDoFeatureSkillRound(featureType)
    if not self._featureSkillCommon.lastRoundInfo then
        self._featureSkillCommon.lastRoundInfo = {}
    end
    return self._featureSkillCommon.lastRoundInfo[featureType]
end

function LogicFeatureComponent:SetLastDoFeatureSkillRound(featureType,round)
    if not self._featureSkillCommon.lastRoundInfo then
        self._featureSkillCommon.lastRoundInfo = {}
    end
    self._featureSkillCommon.lastRoundInfo[featureType] = round
end
function LogicFeatureComponent:SetAllFeatureSkillCdOff(cdOff)
    self._featureSkillCommon.featureSkillCdOff = cdOff
end
function LogicFeatureComponent:GetAllFeatureSkillCdOff()
    return self._featureSkillCommon.featureSkillCdOff
end
function LogicFeatureComponent:SetSpecificFeatureSkillCdOff(featureType,cdOff)
    self._featureSkillCommon.specificFeatureSkillCdOff[featureType] = cdOff
end
function LogicFeatureComponent:GetSpecificFeatureSkillCdOff(featureType)
    if self._featureSkillCommon.specificFeatureSkillCdOff[featureType] then
        return self._featureSkillCommon.specificFeatureSkillCdOff[featureType]
    end
    return 0
end
--------------------------------技能通用 end-------------------------------------------
---@param owner Entity
function LogicFeatureComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end
---
function LogicFeatureComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end



--[[
    Entity Extensions
]]
---@return LogicFeatureComponent
function Entity:LogicFeature()
    return self:GetComponent(self.WEComponentsEnum.LogicFeature)
end

---
function Entity:HasLogicFeature()
    return self:HasComponent(self.WEComponentsEnum.LogicFeature)
end

---
function Entity:AddLogicFeature()
    local index = self.WEComponentsEnum.LogicFeature;
    local component = LogicFeatureComponent:New()
    self:AddComponent(index, component)
end

---
function Entity:ReplaceLogicFeature()
    local index = self.WEComponentsEnum.LogicFeature;
    local component = LogicFeatureComponent:New()
    self:ReplaceComponent(index, component)
end

---
function Entity:RemoveLogicFeature()
    if self:HasLogicFeature() then
        self:RemoveComponent(self.WEComponentsEnum.LogicFeature)
    end
end