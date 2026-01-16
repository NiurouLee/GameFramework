require("sp_base_inst")

_class("SkillPreviewXingshanStrikeInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewXingshanStrikeInstruction: SkillPreviewBaseInstruction
SkillPreviewXingshanStrikeInstruction = SkillPreviewXingshanStrikeInstruction

function SkillPreviewXingshanStrikeInstruction:Constructor(param)
    self._teleportScopeCfg = {
        TargetType = tonumber(param.teleportScopeTargetType),
        ScopeType = tonumber(param.teleportScopeType),
        ScopeParam = {tonumber(param.teleportScopeParam)}, -- TODO: 传进来的是一个字符串，如果换范围要想一下
        ScopeCenterType = tonumber(param.teleportScopeCenterType),
    }

    self._damageScopeCfg = {
        TargetType = tonumber(param.damageScopeTargetType),
        ScopeType = tonumber(param.damageScopeType),
        ScopeParam = {tonumber(param.damageScopeParam)}, -- TODO: 传进来的是一个字符串，如果换范围要想一下
        ScopeCenterType = tonumber(param.damageScopeCenterType),
    }
end

function SkillPreviewXingshanStrikeInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type MainWorld
    local world = previewContext:GetWorld()

    local configSvc = world:GetService("Config")
    ---@type SkillConfigHelper
    local helper = configSvc._skillConfigHelper
    ---@type SkillScopeParamParser
    local parser = helper._scopeParamParser

    local previewTeleportScopeParam = SkillPreviewScopeParam:New(self._teleportScopeCfg)
    local teleportSParam = parser:ParseScopeParam(self._teleportScopeCfg.ScopeType, self._teleportScopeCfg.ScopeParam)
    previewTeleportScopeParam:SetScopeParamData(teleportSParam)

    local previewDamageScopeParam = SkillPreviewScopeParam:New(self._damageScopeCfg)
    local damageSParam = parser:ParseScopeParam(self._damageScopeCfg.ScopeType, self._damageScopeCfg.ScopeParam)
    previewDamageScopeParam:SetScopeParamData(damageSParam)

    -- 先用点选计算第一个范围，然后以同样的方式选定位置，创建虚影，然后计算伤害范围
    ---@type PreviewPickUpComponent
	local previewPickUpComponent = casterEntity:PreviewPickUpComponent()

    local tv2Pick = previewPickUpComponent:GetAllValidPickUpGridPos()
    local v2Pickup = tv2Pick[1] or casterEntity:GetGridPosition()

    ---@type PreviewActiveSkillService
    local previewActiveSkillService = world:GetService("PreviewActiveSkill")

    local dirNew = v2Pickup - casterEntity:GetGridPosition()
    if dirNew.x > 0 then
        dirNew.x = 1
    elseif dirNew.x < 0 then
        dirNew.x = -1
    end

    if dirNew.y > 0 then
        dirNew.y = 1
    elseif dirNew.y < 0 then
        dirNew.y = -1
    end

    casterEntity:SetDirection(dirNew)

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = world:GetService("UtilScopeCalc")

    -- 这里好孩子不要学，醒山是技能效果与逻辑面向相关，不能使用当前的局内方向
    local casterBodyArea = casterEntity:BodyArea():GetArea()
    ---@type SkillScopeResult
    local teleportScopeResult = utilScopeSvc._skillScopeCalc:CalcSkillPreviewScope(
        casterEntity:GetGridPosition(),
        dirNew,
        casterBodyArea,
        previewTeleportScopeParam,
        casterEntity
    )

    local teleportPos = self:_FindTeleportPos_Comparer(
        casterEntity,
        casterEntity:GetGridPosition(),
        teleportScopeResult:GetAttackRange()
    )

    if not teleportPos then
        teleportPos = casterEntity:GetGridPosition()
    end

    -- 这里好孩子不要学，醒山是技能效果与逻辑面向相关，不能使用当前的局内方向
    ---@type SkillScopeResult
    local damageScopeResult = utilScopeSvc._skillScopeCalc:CalcSkillPreviewScope(
        teleportPos,
        dirNew,
        casterBodyArea,
        previewDamageScopeParam,
        casterEntity
    )

    if teleportPos ~= casterEntity:GetGridPosition() then
        ---@type RenderEntityService
        local entitySvc = world:GetService("RenderEntity")
        entitySvc:CreateGhost(teleportPos, casterEntity,"AtkUltPreview")
    end

    previewActiveSkillService:AllPieceDoConvert("Dark")
    previewActiveSkillService:DoAnim(damageScopeResult:GetAttackRange(), "Silver")

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = world:GetService("UtilScopeCalc")
    local targetIDList = utilScopeSvc:SelectSkillTarget(casterEntity, previewDamageScopeParam:GetScopeTargetType(), damageScopeResult)
    targetIDList = table.unique(targetIDList)
    for _, id in pairs(targetIDList) do
        local entity = world:GetEntityByID(id)
        if entity and entity:HasTeam() then
            entity = entity:GetTeamLeaderPetEntity()
        end
        if (
            entity and
            entity:HasMaterialAnimationComponent() and
            not entity:BuffView():HasBuffEffect(BuffEffectType.NotPlayMaterialAnimation)
        ) then
            entity:NewEnableFlashAlpha()
        end
    end
end

---SkillEffectCalc_Teleport:_FindTeleportPos_Comparer的删减版
function SkillPreviewXingshanStrikeInstruction:_FindTeleportPos_Comparer(
    entityCaster,
    posCenter,
    skillRangePos)
    ---@type MainWorld
    local world = entityCaster:GetOwnerWorld()
    if nil == skillRangePos then
        return posCenter
    end
    local listRangeInPlan = skillRangePos
    ---@type Entity
    local entityMain = world:Player():GetPreviewTeamEntity()
    local posMain = entityMain:GetGridPosition()

    ---@type BoardServiceLogic
    local boardServiceLogic = world:GetService("BoardLogic")
    ---@type SortedArray    注意这里的排序函数，不同需求应当不同
    local sortPosList = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByFar)
    sortPosList:AllowDuplicate()
    for i = 1, #skillRangePos do
        AINewNode.InsertSortedArray(sortPosList, posMain, skillRangePos[i], i)
    end

    local bodyArea = entityCaster:BodyArea():GetArea()

    local skillEffectCalcService = world:GetService("SkillEffectCalc")
    ---@type BlockFlag
    local nBlockRaceType = BlockFlag.LinkLine
    for i = 1, sortPosList:Size() do
        ---@type AiSortByDistance
        local sortPosData = sortPosList:GetAt(i)
        local posWork = sortPosData.data
        ---@type Vector2
        local bPosBlock = boardServiceLogic:IsPosBlockByArea(posWork, nBlockRaceType, bodyArea, entityCaster)
        if not bPosBlock then
            return posWork
        end
    end
    return posCenter
end
