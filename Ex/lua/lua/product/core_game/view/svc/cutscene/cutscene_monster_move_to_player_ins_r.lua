require("cutscene_base_ins_r")
---@class CutsceneMonsterMoveToPlayerInstruction: CutsceneBaseInstruction
_class("CutsceneMonsterMoveToPlayerInstruction", CutsceneBaseInstruction)
CutsceneMonsterMoveToPlayerInstruction = CutsceneMonsterMoveToPlayerInstruction

function CutsceneMonsterMoveToPlayerInstruction:Constructor(paramList)
    self._monsterName = paramList["monsterName"]
    self._moveSpeed = tonumber(paramList["moveSpeed"]) or 2
    self._moveGridCount = tonumber(paramList["moveGridCount"]) or 1
end

---@param phaseContext CutscenePhaseContext
function CutsceneMonsterMoveToPlayerInstruction:DoInstruction(TT, phaseContext)
    local world = phaseContext:GetCutsceneWorld()
    ---@type CutsceneServiceRender
    local cutsceneServiceRender = world:GetService("Cutscene")

    cutsceneServiceRender:PlayCutsceneMonsterMoveToPlayer(TT, self._monsterName, self._moveGridCount, self._moveSpeed)
end
