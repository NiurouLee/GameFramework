require("sp_base_inst")
---播放预览击退效果
_class("SkillPreviewPlayTargetHitBackInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayTargetHitBackInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayTargetHitBackInstruction = SkillPreviewPlayTargetHitBackInstruction

function SkillPreviewPlayTargetHitBackInstruction:Constructor(params)
    self._casterPosBlock = params.casterPosBlock
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayTargetHitBackInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type MainWorld
    self._world = previewContext:GetWorld()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type Vector2[]
    local scopeGridList = previewContext:GetScopeResult()
    ---@type SkillPreviewEffectCalcService
    local previewEffectCalcService = self._world:GetService("PreviewCalcEffect")
    local effect = previewContext:GetEffect(SkillEffectType.HitBack)
    local targetIDList = table.unique(previewContext:GetTargetEntityIDList())
    local previewIndex = previewActiveSkillService:GetPreviewIndex()
    local hitBackDirType = previewContext:GetHitBackDirType()

    ----@type SkillHitBackEffectParam
    local effectParam = previewEffectCalcService:CreateSkillEffectParam(SkillEffectType.HitBack, effect)
    ---@type SkillHitBackEffectParam
    local enableByPickNum = effectParam:GetEnableByPickNum()
    if enableByPickNum then
        local checkNum = tonumber(enableByPickNum)
        ---@type Entity
        local attacker = casterEntity
        ---@type PreviewPickUpComponent
        local component = attacker:PreviewPickUpComponent()
        if component then
            local curPickNum = component:GetAllValidPickUpGridPosCount()
            if curPickNum ~= checkNum then
                return
            end
        end
    end

    if not hitBackDirType then
        hitBackDirType = effectParam:GetDirType()
    end

    local posPickup = previewContext:GetPickUpPos()
    if posPickup then
        if effectParam:GetForceUseCasterPos() then
        else
            previewContext:SetCasterPos(posPickup)
        end
    end
    local casterPos = previewContext:GetCasterPos()
    --目标按击退方向排序
    utilScopeSvc:SortHitbackTargetByDirType(targetIDList, hitBackDirType, casterPos)

    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    if self._casterPosBlock then
        env:DelEntityBlockFlag(casterEntity, casterEntity:GridLocation():GetGridPos())
    end

    for _, targetID in ipairs(targetIDList) do
        local result =
            previewEffectCalcService:CalcHitBack(casterEntity, scopeGridList, targetID, previewContext, effectParam)
        self:_DoHitBack(result, previewIndex, targetID)
    end
end
---@param result SkillHitBackEffectResult
function SkillPreviewPlayTargetHitBackInstruction:_DoHitBack(result, previewIndex, targetID)
    if not result then
        return
    end
    if not result:GetHitDir() then
        return
    end
    local enemyEntity = self._world:GetEntityByID(targetID)
    -- if not enemyEntity:MonsterID() and not enemyEntity:HasTrapID() then
    --     return
    -- end

    ---@type RenderEntityService
    local entitySvc = self._world:GetService("RenderEntity")
    local ghostEntity = entitySvc:CreateGhost(enemyEntity:GridLocation().Position, enemyEntity)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local startPos = boardServiceRender:GetRealEntityGridPos(enemyEntity)
    local targetPos = result:GetGridPos()
    ---修改ghost逻辑坐标到击退位置
    ghostEntity:SetGridPosition(targetPos)
    ghostEntity:AddHitback(startPos, BattleConst.HitbackSpeed, targetPos, result:GetHitDir())

    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    if enemyEntity:HasPet() then
        enemyEntity = enemyEntity:Pet():GetOwnerTeamEntity()
    end
    --将Ghost击退后的位置阻挡中的LinkLine移除
    local ghostBlock = env:GetEntityBlockFlag(enemyEntity)
    for _, area in ipairs(enemyEntity:BodyArea():GetArea()) do
        local blockData = env:GetPosBlockData(targetPos + area)
        blockData:AddBlock(enemyEntity:GetID(), (~BlockFlag.LinkLine) & ghostBlock)
    end
end
