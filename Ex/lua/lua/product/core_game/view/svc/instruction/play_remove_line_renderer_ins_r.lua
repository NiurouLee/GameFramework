require("base_ins_r")
---@class PlayRemoveLineRendererInstruction: BaseInstruction
_class("PlayRemoveLineRendererInstruction", BaseInstruction)
PlayRemoveLineRendererInstruction = PlayRemoveLineRendererInstruction

function PlayRemoveLineRendererInstruction:Constructor(paramList)
end

---@param casterEntity Entity
function PlayRemoveLineRendererInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()

    ---@type EffectLineRendererComponent
    local effectLineRenderer = casterEntity:EffectLineRenderer()

    if effectLineRenderer then
        casterEntity:RemoveEffectLineRenderer()
    end

    local monsterGroup = world:GetGroup(world.BW_WEMatchers.MonsterID)
    for i, entity in ipairs(monsterGroup:GetEntities()) do
        ---@type EffectLineRendererComponent
        local effectLineRenderer = entity:EffectLineRenderer()

        if effectLineRenderer then
            entity:RemoveEffectLineRenderer()
        end
    end
end
