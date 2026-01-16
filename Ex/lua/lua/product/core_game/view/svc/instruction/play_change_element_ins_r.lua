--[[
    变身的逻辑与表现
]]
---@class PlayChangeElementInstruction:BaseInstruction
_class("PlayChangeElementInstruction", BaseInstruction)
PlayChangeElementInstruction = PlayChangeElementInstruction

function PlayChangeElementInstruction:Constructor(paramList)
end

function PlayChangeElementInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.ChangeElement)

    if #resultArray == 0 then
        return
    end

    ---@type SkillEffectResultChangeElement
    local result = resultArray[1]

    local target = world:GetEntityByID(result:GetTarget())
    local elementType = result:GetElementType()
    if not target then
        Log.fatal("没有施法者，变身失败")
        return
    end

    --血条 元素
    local sliderEntityID = target:HP():GetHPSliderEntityID()
    local sliderEntity = world:GetEntityByID(sliderEntityID)
    TaskManager:GetInstance():CoreGameStartTask(
        InnerGameHelperRender:GetInstance().SetHpSliderElementIcon,
        InnerGameHelperRender:GetInstance(),
        sliderEntity,
        elementType
    )

    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossElement, elementType, target:GetID())

    --YIELD(TT)
end
