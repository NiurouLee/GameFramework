require("sp_base_inst")
---多目标牵引预览
_class("SkillPreviewPlayMultiTractionInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayMultiTractionInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayMultiTractionInstruction = SkillPreviewPlayMultiTractionInstruction
function SkillPreviewPlayMultiTractionInstruction:Constructor(params)
	self._transCenter = tonumber(params.transCenter)
end
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayMultiTractionInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type MainWorld
    local world = previewContext:GetWorld()

    ---@type SkillPreviewEffectCalcService
    local previewEffectCalcService = world:GetService("PreviewCalcEffect")
    ---@type Vector2[]
    local scopeGridList = previewContext:GetScopeResult()
    local effect = previewContext:GetEffect(SkillEffectType.MultiTraction)
    local effectParam = previewEffectCalcService:CreateSkillEffectParam(SkillEffectType.MultiTraction, effect)
    local transContextCenter = (self._transCenter and (self._transCenter == 1))
    ---@type SkillEffectMultiTractionResult
    local result = previewEffectCalcService:CalcMultiTraction(casterEntity, previewContext, effectParam,transContextCenter)

    self:_DoPresentation(TT, world, result)
end

---@param result SkillEffectMultiTractionResult
-- 与击退不同，牵引不是严格(0+45°*x)的八方向，所以没有直接使用击退的方法
function SkillPreviewPlayMultiTractionInstruction:_DoPresentation(TT, world, result)
    local taskIDs = {}
    if result then
        local array = result:GetResultArray()
        for _, info in ipairs(array) do
            local entity = world:GetEntityByID(info.entityID)
            local startPos = entity:GetGridPosition()
            local endPos = info.finalPos
            if (startPos ~= endPos) then
                table.insert(taskIDs, self:_DoSingleTarget(TT, world, info, entity))
            end
        end
    end
    
    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDs) do
        YIELD(TT)
    end

    return InstructionConst.PhaseEnd
end

---@param info Internal_SkillEffectMultiTractionResult_PathInfo
function SkillPreviewPlayMultiTractionInstruction:_DoSingleTarget(TT, world, info, entity)
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local entitySvc = world:GetService("RenderEntity")

    -- local v3RenderPos = entity:GetPosition()
    -- local cGridLocation = entity:GridLocation()
    -- local v2Offset = cGridLocation.Offset
    -- v3RenderPos.x = v3RenderPos.x - v2Offset.x
    -- v3RenderPos.y = v3RenderPos.y - v2Offset.y
    -- local gridPos = boardServiceRender:BoardRenderPos2GridPos(v3RenderPos)

    -- 上面那段太绕了
    local gridPos = entity:GetGridPosition()
    local ghostEntity = entitySvc:CreateGhost(gridPos, entity)

    ghostEntity:AddGridMove(BattleConst.TractionSpeed, info.finalPos, gridPos)
    -- 使用GridMove实现表现，但需要等待所有牵引结束，需要启动监工协程
    -- GridMove有独立的系统负责计算实际的位移，所以没有计算时间
    return GameGlobal.TaskManager():CoreGameStartTask(self._IsMoveFinished, self, ghostEntity)
end

function SkillPreviewPlayMultiTractionInstruction:_IsMoveFinished(TT, entity)
    return not entity:HasGridMove()
end
