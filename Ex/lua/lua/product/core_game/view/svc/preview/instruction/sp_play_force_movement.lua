--[[
    强制位移效果的预览逻辑
]]
require("sp_base_inst")

_class("SkillPreviewPlayForceMovementInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayForceMovementInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayForceMovementInstruction = SkillPreviewPlayForceMovementInstruction

---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayForceMovementInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type MainWorld
    local world = previewContext:GetWorld()

    ---@type SkillPreviewEffectCalcService
    local previewEffectCalcService = world:GetService("PreviewCalcEffect")
    ---@type Vector2[]
    local scopeGridList = previewContext:GetScopeResult()
    local effect = previewContext:GetEffect(SkillEffectType.ForceMovement)
    local effectParam = previewEffectCalcService:CreateSkillEffectParam(SkillEffectType.ForceMovement, effect)

    ---@type SkillEffectResult_ForceMovement
    local result = previewEffectCalcService:CalcForceMovement(casterEntity, previewContext, effectParam)

    self:_DoPresentation(TT, world, result)
end

---@param result SkillEffectResult_ForceMovement
function SkillPreviewPlayForceMovementInstruction:_DoPresentation(TT, world, result)
    local taskIDs = {}
    local array = result:GetMoveResult()
    for _, info in ipairs(array) do
        local entity = world:GetEntityByID(info.targetID)
        if (info.isMoved) then
            local tid = self:_DoSingleTarget(TT, world, info, entity)
            if tid then
                table.insert(taskIDs, tid)
            end
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDs) do
        YIELD(TT)
    end
end

---@param info SkillEffectResult_ForceMovement_MoveResult
function SkillPreviewPlayForceMovementInstruction:_DoSingleTarget(TT, world, info, entity)
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local entitySvc = world:GetService("RenderEntity")

    local ghostEntity = entitySvc:CreateGhost(info.v2OldPos, entity,"AtkUltPreview")

    ghostEntity:AddGridMove(BattleConst.ForceMovementPreviewSpeed, info.v2NewPos, info.v2OldPos)
    -- 使用GridMove实现表现，但需要等待所有牵引结束，需要启动监工协程
    -- GridMove有独立的系统负责计算实际的位移，所以没有计算时间
    return GameGlobal.TaskManager():CoreGameStartTask(self._IsMoveFinished, self, ghostEntity)
end

function SkillPreviewPlayForceMovementInstruction:_IsMoveFinished(TT, entity)
    return not entity:HasGridMove()
end
