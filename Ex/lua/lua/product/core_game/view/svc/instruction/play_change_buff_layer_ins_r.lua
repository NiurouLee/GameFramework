require("base_ins_r")
---@class PlayChangeBuffLayerInstruction: BaseInstruction
_class("PlayChangeBuffLayerInstruction", BaseInstruction)
PlayChangeBuffLayerInstruction = PlayChangeBuffLayerInstruction

function PlayChangeBuffLayerInstruction:Constructor(paramList)
    self._stageIndex = tonumber(paramList["stageIndex"]) or 1
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayChangeBuffLayerInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    ---@type SkillEffectResultChangeBuffLayer[]
    local buffResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.ChangeBuffLayer, self._stageIndex)
    if not buffResultArray or table.count(buffResultArray) == 0 then
        return
    end

    ---@type PlayBuffService
    local playBuffService = world:GetService("PlayBuff")

    for _, result in ipairs(buffResultArray) do
        local entityID = result:GetEntityID()
        local entity = world:GetEntityByID(entityID)
        local buffEffectType = result:GetTargetBuffEffectType()
        local layerCount = result:GetLayer()
        local buffseq = result:GetTargetBuffSeq()

        ---@type BuffViewComponent
        local buffView = entity:BuffView()
        local viewInstance = buffView:GetBuffViewInstance(buffseq)

        if viewInstance then
            viewInstance:SetLayerCount(TT, layerCount)

            --星灵被动层数
            if entity:HasPetPstID() then
                GameGlobal.EventDispatcher():Dispatch(
                    GameEventType.SetAccumulateNum,
                    entity:PetPstID():GetPstID(),
                    layerCount
                )
            end
        end
    end

    --所有结果 通知一次血条就可以
    world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)
end
