--[[
    DrawCard = 166, --抽卡 （光灵杰诺）
]]
---@class SkillEffectCalc_DrawCard: Object
_class("SkillEffectCalc_DrawCard", Object)
SkillEffectCalc_DrawCard = SkillEffectCalc_DrawCard

function SkillEffectCalc_DrawCard:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DrawCard:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamDrawCard
    local skillEffectParam = skillEffectCalcParam.skillEffectParam
    ---@type FeatureServiceLogic
    local lsvcFeature = self._world:GetService("FeatureLogic")
    if not lsvcFeature:HasFeatureType(FeatureType.Card) then
        return
    end
    if not lsvcFeature:CanAddCard() then
        return
    end
    local cardType = nil
    local fixedCard = lsvcFeature:GetNextDrawFixedCard()
    if fixedCard then
        cardType = fixedCard
    else
        local weightTb = {5,5,5}
        local teamEntity = self._world:Player():GetCurrentTeamEntity()
        if teamEntity then
            local teamEntityID = teamEntity:GetID()
            weightTb = lsvcFeature:GetRandomDrawCardWeight(teamEntityID)
        end
        if not weightTb then
            weightTb = {5,5,5}
        end
        local totalWeight = 0
        for weightCard,weight in ipairs(weightTb) do
            totalWeight = totalWeight + weight
        end
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        local randNum = randomSvc:LogicRand(1, totalWeight)
        local sumWeight = 0
        local findCardType = FeatureCardType.A
        for weightCard,weight in ipairs(weightTb) do
            sumWeight = sumWeight + weight
            if randNum <= sumWeight then
                findCardType = weightCard
                break
            end
        end
        cardType = findCardType
        ---产生随机数
        --cardType = randomSvc:LogicRand(FeatureCardType.MIN, FeatureCardType.MAX)--固定三种
    end
    ---@type SkillEffectResultDrawCard
    local result = SkillEffectResultDrawCard:New(cardType)
    return result
end
