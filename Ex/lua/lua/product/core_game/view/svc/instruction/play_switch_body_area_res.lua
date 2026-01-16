require("base_ins_r")
---@class PlaySwitchBodyAreaResultInstruction: BaseInstruction
_class("PlaySwitchBodyAreaResultInstruction", BaseInstruction)
PlaySwitchBodyAreaResultInstruction = PlaySwitchBodyAreaResultInstruction

function PlaySwitchBodyAreaResultInstruction:Constructor(paramList)
end

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlaySwitchBodyAreaResultInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectSwitchBodyAreaByTargetPosResult
    local switchBodyAreaResult = routineComponent:GetEffectResultByArray(SkillEffectType.SwitchBodyAreaByTargetPos)

    if not switchBodyAreaResult then
        return
    end
    ---@type SwitchBodyAreaDirType
    local dirType = switchBodyAreaResult:GetSwitchDirType()
    local oldBodyAreaPos = switchBodyAreaResult:GetOldBodyAreaPos()
    local newDir = switchBodyAreaResult:GetNewDir()
    local newBodyArea = switchBodyAreaResult:GetNewBodyArea()
    self._world = casterEntity:GetOwnerWorld()
    --Log.fatal("Anim:",playAnim,"DirType:",dirType)
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    renderEntityService:DestroyMonsterAreaOutLineEntity(casterEntity)
    renderEntityService:CreateMonsterAreaOutlineEntity(casterEntity)
    local casterPos = casterEntity:GetRenderGridPosition()
    local newBodyAreaPos = casterPos + newBodyArea[1]
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    casterEntity:SetDirection(newDir)
    pieceService:SetPieceAnimUp(oldBodyAreaPos)
    pieceService:SetPieceAnimDown(newBodyAreaPos)
end
