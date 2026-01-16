require("base_ins_r")

---@class PlayChessKnightTeleportInstruction: BaseInstruction
_class("PlayChessKnightTeleportInstruction", BaseInstruction)
PlayChessKnightTeleportInstruction = PlayChessKnightTeleportInstruction

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayChessKnightTeleportInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Teleport
    local teleportResult = routineComponent:GetEffectResultByArray(SkillEffectType.Teleport, self._stageIndex)

    if not teleportResult then
        return
    end

    local v2 = teleportResult:GetPosNew()
    casterEntity:SetPosition(v2)
    local go = casterEntity:View():GetGameObject()
    local tfRoot = GameObjectHelper.FindChild(go.transform, "Root")
    if tfRoot then
        tfRoot.localPosition = Vector3.zero
    end
end
