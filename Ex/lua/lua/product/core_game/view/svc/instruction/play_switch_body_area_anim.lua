require('switch_body_area_dir_type')

require("base_ins_r")
---@class PlaySwitchBodyAreaInstruction: BaseInstruction
_class("PlaySwitchBodyAreaInstruction", BaseInstruction)
PlaySwitchBodyAreaInstruction = PlaySwitchBodyAreaInstruction

function PlaySwitchBodyAreaInstruction:Constructor(paramList)
    ---头不动屁股向右，整体方向向左
    self._leftAnim = paramList.leftAnim
    ---头不动屁股向左，整体方向向右
    self._rightAnim =paramList.rightAnim
    ---头不动屁股180°，方向掉转
    self._turnAnim = paramList.turnAnim
    self._leftAnimLen = tonumber(paramList.leftAnimLen)
    self._rightAnimLen = tonumber(paramList.rightAnimLen)
    self._turnAnimLen = tonumber(paramList.turnAnimLen)
end

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlaySwitchBodyAreaInstruction:DoInstruction(TT, casterEntity, phaseContext)
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
    local playAnim,animLen
    if dirType == SwitchBodyAreaDirType.Right then
        playAnim = self._rightAnim
        animLen = self._rightAnimLen
    elseif dirType == SwitchBodyAreaDirType.Left then
        playAnim = self._leftAnim
        animLen = self._leftAnimLen
    elseif dirType == SwitchBodyAreaDirType.Turn then
        playAnim = self._turnAnim
        animLen = self._turnAnimLen
    end
    self._world = casterEntity:GetOwnerWorld()
    if playAnim then
        casterEntity:SetAnimatorControllerTriggers({playAnim})
    end
    local oneFrameTime= 0

    if animLen then        
        YIELD(TT,animLen)        
    end
    casterEntity:SetAnimatorControllerTriggers({"Idle"})
    --Log.fatal("Anim:",playAnim,"DirType:",dirType)
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    renderEntityService:DestroyMonsterAreaOutLineEntity(casterEntity)
    --renderEntityService:CreateMonsterAreaOutlineEntity(casterEntity)
    local casterPos = casterEntity:GetRenderGridPosition()
    local newBodyAreaPos = casterPos + newBodyArea[1]
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    casterEntity:SetDirection(newDir)
    pieceService:SetPieceAnimUp(oldBodyAreaPos)
    pieceService:SetPieceAnimDown(newBodyAreaPos)
    end
