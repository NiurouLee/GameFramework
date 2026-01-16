require("base_ins_r")
---@class PlayRefreshRoundCountInstruction: BaseInstruction
_class("PlayRefreshRoundCountInstruction", BaseInstruction)
PlayRefreshRoundCountInstruction = PlayRefreshRoundCountInstruction

function PlayRefreshRoundCountInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayRefreshRoundCountInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type UtilDataServiceShare
    local utilDataSvc = world:GetService("UtilData")
    local roundCount = utilDataSvc:GetLightCount()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateRoundCount, roundCount)
end
