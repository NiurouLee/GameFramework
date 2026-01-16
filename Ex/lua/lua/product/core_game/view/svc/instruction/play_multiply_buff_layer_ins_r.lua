require("base_ins_r")

---@class PlayMultiplyBuffLayerInstruction: BaseInstruction
_class("PlayMultiplyBuffLayerInstruction", BaseInstruction)
PlayMultiplyBuffLayerInstruction = PlayMultiplyBuffLayerInstruction

function PlayMultiplyBuffLayerInstruction:Constructor(paramList)

end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayMultiplyBuffLayerInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_MultiplyBuffLayer[]
    local tResults = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.MultiplyBuffLayer)
    if not tResults or table.count(tResults) == 0 then
        return
    end

    for _, result in ipairs(tResults) do
        self:_RefreshBuffLayerByResult(TT, world, result)
    end
end

---@param world MainWorld
---@param result SkillEffectResult_MultiplyBuffLayer
function PlayMultiplyBuffLayerInstruction:_RefreshBuffLayerByResult(TT, world, result)
    if not result:GetFinalLayerCount() then
        return
    end

    local targetID = result:GetTargetID()
    local eTarget = world:GetEntityByID(targetID)
    local buffSeq = result:GetLayerBuffSeq()
    local finalLayerCount = result:GetFinalLayerCount()

    ---@type BuffViewComponent
    local buffView = eTarget:BuffView()
    local viewInstance = buffView:GetBuffViewInstance(buffSeq)

    if not viewInstance then
        return
    end

    viewInstance:SetLayerCount(TT, finalLayerCount)
    world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)

    --星灵被动层数
    if eTarget:HasPetPstID() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.SetAccumulateNum, eTarget:PetPstID():GetPstID(), finalLayerCount)
    end
end
