require("base_ins_r")
---@class PlayCasterRefreshBuffViewInstruction: BaseInstruction
_class("PlayCasterRefreshBuffViewInstruction", BaseInstruction)
PlayCasterRefreshBuffViewInstruction = PlayCasterRefreshBuffViewInstruction

function PlayCasterRefreshBuffViewInstruction:Constructor(paramList)
    self._buffID = tonumber(paramList["buffID"]) or 0
    self._buffEffectType = tonumber(paramList["buffEffectType"]) or 0
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCasterRefreshBuffViewInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PlayBuffService
    local playBuffService = world:GetService("PlayBuff")

    ---@type BuffViewComponent
    local buffViewComponent = casterEntity:BuffView()
    if buffViewComponent then
        local viewIns = buffViewComponent:GetBuffViewInstanceArray()
        for _, inst in ipairs(viewIns) do
            local buffID = inst:BuffID()
            local buffEffectType = inst:GetBuffEffectType()
            if self._buffID == buffID or self._buffEffectType == buffEffectType then
                playBuffService:PlayAddBuff(TT, inst, casterEntity:GetID())
            end
        end
    end
end
