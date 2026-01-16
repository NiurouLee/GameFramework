require("cutscene_base_ins_r")
---@class CutsceneMonsterDeadAnimationInstruction: CutsceneBaseInstruction
_class("CutsceneMonsterDeadAnimationInstruction", CutsceneBaseInstruction)
CutsceneMonsterDeadAnimationInstruction = CutsceneMonsterDeadAnimationInstruction

function CutsceneMonsterDeadAnimationInstruction:Constructor(paramList)
    self._name = paramList["name"]
    self._monsterDeadType = tonumber(paramList["monsterDeadType"])
end

---@param phaseContext CutscenePhaseContext
function CutsceneMonsterDeadAnimationInstruction:DoInstruction(TT, phaseContext)
    local world = phaseContext:GetCutsceneWorld()
    ---@type CutsceneServiceRender
    local cutsceneServiceRender = world:GetService("Cutscene")

    for i, entity in ipairs(cutsceneServiceRender:GetCutsceneMonsterGroupEntity()) do
        ---@type CutsceneMonsterComponent
        local cutsceneMonsterComponent = entity:CutsceneMonster()
        if cutsceneMonsterComponent:GetCutsceneMonsterName() == self._name then
            cutsceneServiceRender:PlayCutsceneMonsterDead(TT, entity, self._monsterDeadType)
        end
    end
end
