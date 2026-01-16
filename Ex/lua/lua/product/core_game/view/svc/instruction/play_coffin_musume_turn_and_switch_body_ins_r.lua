require('switch_body_area_dir_type')

_class("PlayCoffinMusumeTurnAndSwitchBodyInstruction", BaseInstruction)
---@class PlayCoffinMusumeTurnAndSwitchBodyInstruction : BaseInstruction
PlayCoffinMusumeTurnAndSwitchBodyInstruction = PlayCoffinMusumeTurnAndSwitchBodyInstruction

function PlayCoffinMusumeTurnAndSwitchBodyInstruction:Constructor(paramList)
    self._up = tonumber(paramList.isUp) == 1
end

local animNameByDirType = {
    [SwitchBodyAreaDirType.None] = 'Skill01Up',
    [SwitchBodyAreaDirType.Left] = 'Skill01Left',
    [SwitchBodyAreaDirType.Turn] = 'Skill01Down',
    [SwitchBodyAreaDirType.Right] = 'Skill01Right',
}

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCoffinMusumeTurnAndSwitchBodyInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectSwitchBodyAreaByTargetPosResult
    local switchBodyAreaResult = routineComponent:GetEffectResultByArray(SkillEffectType.SwitchBodyAreaByTargetPos)

    if not switchBodyAreaResult then
        return
    end

    ---@type RenderEntityService
    local renderEntityService = world:GetService("RenderEntity")
    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")

    local dirType = switchBodyAreaResult:GetSwitchDirType()

    if self._up then
        local animName = animNameByDirType[dirType] or 'Skill01Up'
        casterEntity:SetAnimatorControllerTriggers({animName})
        --casterEntity:SetDirection(casterEntity:GetDirection())

        renderEntityService:DestroyMonsterAreaOutLineEntity(casterEntity)
        local centerPos = switchBodyAreaResult:GetOldBodyAreaPos()
        local oldBodyArea = switchBodyAreaResult:GetOldBodyArea()
        for _, body in ipairs(oldBodyArea) do
            pieceService:SetPieceAnimUp(centerPos + body)
        end
    else
        local centerPos = casterEntity:GetGridPosition()
        casterEntity:SetAnimatorControllerTriggers({'turnFinished'})

        casterEntity:SetDirection(switchBodyAreaResult:GetNewDir())
        renderEntityService:CreateMonsterAreaOutlineEntity(casterEntity)
        local bodyArea = switchBodyAreaResult:GetNewBodyArea()
        for _, body in ipairs(bodyArea) do
            pieceService:SetPieceAnimDown(centerPos + body)
        end
    end
end
