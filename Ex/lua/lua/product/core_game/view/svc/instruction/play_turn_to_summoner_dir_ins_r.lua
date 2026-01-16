require("base_ins_r")
---面向到召唤者的朝向
---@class PlayTurnToSummonerDirInstruction: BaseInstruction
_class("PlayTurnToSummonerDirInstruction", BaseInstruction)
PlayTurnToSummonerDirInstruction = PlayTurnToSummonerDirInstruction

function PlayTurnToSummonerDirInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTurnToSummonerDirInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type Entity
    local ownerSummonerEntity = casterEntity:GetSummonerEntity()
    if not ownerSummonerEntity then
        return
    end

    local dir = ownerSummonerEntity:GetGridDirection():Clone()

    casterEntity:SetDirection(dir)
end
