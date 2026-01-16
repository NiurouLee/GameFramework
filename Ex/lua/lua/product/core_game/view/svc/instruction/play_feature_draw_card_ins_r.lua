require("base_ins_r")
---杰诺 抽牌
---@class PlayFeatureDrawCardInstruction: BaseInstruction
_class("PlayFeatureDrawCardInstruction", BaseInstruction)
PlayFeatureDrawCardInstruction = PlayFeatureDrawCardInstruction

function PlayFeatureDrawCardInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayFeatureDrawCardInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type FeatureServiceRender
    local rsvcFeature = world:GetService("FeatureRender")
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResultDrawCard[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.DrawCard)
    if not resultArray then
        return
    end
    for _, result in ipairs(resultArray) do
        local cardType = result:GetCardType()
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FeatureUIPlayDrawCard,
            cardType
        )
    end
    
end
