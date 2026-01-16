require("base_ins_r")
---@class PlaySkillAttackRangeInstruction: BaseInstruction
_class("PlaySkillAttackRangeInstruction", BaseInstruction)
PlaySkillAttackRangeInstruction = PlaySkillAttackRangeInstruction

function PlaySkillAttackRangeInstruction:Constructor(paramList)
    self._showTime = 0
    if paramList["showTime"] then
        self._showTime = tonumber(paramList["showTime"])
    end
    self._isEffectRange = 1
    if paramList["isEffectRange"] then
        self._isEffectRange = tonumber(paramList["isEffectRange"])
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlaySkillAttackRangeInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local curDamageResultStageIndex = phaseContext:GetCurDamageResultStageIndex()
    local damageResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, curDamageResultStageIndex)
    if damageResultArray == nil then
        return
    end
    --获取效果的范围
    local gridList = {}
    if self._isEffectRange == 1 then
        for _, result in pairs(damageResultArray) do
            ---@type SkillScopeResult
            local scopeResult = result:GetSkillEffectScopeResult()
            if scopeResult then
                local array = scopeResult:GetAttackRange()
                for _, v in pairs(array) do
                    if not self:_IsContainPos(gridList, v) then
                        table.insert(gridList, v)
                    end
                end
            end
        end
    else
        ---@type SkillScopeResult
        local scopeResult = skillEffectResultContainer:GetScopeResult()
        if scopeResult then
            local array = scopeResult:GetAttackRange()
            for _, v in pairs(array) do
                if not self:_IsContainPos(gridList, v) then
                    table.insert(gridList, v)
                end
            end
        end
    end
    local playerPos = casterEntity:GridLocation().Position
    if not self:_IsContainPos(gridList, playerPos) then
        table.insert(gridList, playerPos)
    end
    --显示范围
    local world = casterEntity:GetOwnerWorld()
    ---@type RenderEntityService
    local renderEntityService = world:GetService("RenderEntity")

    local realCaster = casterEntity
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() then
        realCaster = casterEntity:GetSuperEntity()
    end

    ---@type UtilDataServiceShare
    local utilSvc = world:GetService("UtilData")
    local pieceType = utilSvc:GetEntityElementType(realCaster)

    local outlineEntityList =
        renderEntityService:CreateAreaOutlineEntity(gridList, nil, nil, pieceType)
    YIELD(TT, self._showTime)
    --销毁格子
    renderEntityService:DestroyAreaOutlineEntity(outlineEntityList,EntityConfigIDRender.SkillRangeOutline)
    --for i = 1, #outlineEntityList do
    --    world:DestroyEntity(outlineEntityList[i])
    --end
end

function PlaySkillAttackRangeInstruction:_IsContainPos(posArr, pos)
    for _, p in pairs(posArr) do
        if pos.x == p.x and pos.y == p.y then
            return true
        end
    end
    return false
end
