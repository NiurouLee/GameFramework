--[[------------------------------------------------------------------------------------------
    PreviewTrapActionSystem_Render : 预览机关攻击范围
]]
--------------------------------------------------------------------------------------------
---@class PreviewTrapActionSystem_Render: ReactiveSystem
_class("PreviewTrapActionSystem_Render", ReactiveSystem)
PreviewTrapActionSystem_Render = PreviewTrapActionSystem_Render

function PreviewTrapActionSystem_Render:Constructor(world)
    self._world = world

    ---@type ConfigService
    self._configService = world:GetService("Config")
end

function PreviewTrapActionSystem_Render:GetTrigger(world)
    local group = world:GetGroup(world.BW_WEMatchers.PreviewTrapAction)
    local c = Collector:New({group}, {"AddedOrRemoved"})
    return c
end

---@param entity Entity
function PreviewTrapActionSystem_Render:Filter(entity)
    return true
end

function PreviewTrapActionSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        local boardEntity = entities[i]
        if boardEntity:HasPreviewTrapAction() then
            ---@type PreviewTrapActionComponent
            local previewCmpt = boardEntity:PreviewTrapAction()
            local isShow = previewCmpt:IsShowTrapAction()
            if isShow then
                local listTrapID = previewCmpt:GetTrapEntityList()
                for i = 1, #listTrapID do
                    self:_ShowTrapAction(listTrapID[i])
                end
            else
                --隐藏改成同步了
            end
        else
            Log.debug("[Preview] 预览机关攻击范围： 时机不到")
        end
    end
end

function PreviewTrapActionSystem_Render:_ShowTrapAction(trapEntityID)
    ---@type Entity
    local trapEntity = self._world:GetEntityByID(trapEntityID)

    ---@type TrapRenderComponent
    local trapRenderCmpt = trapEntity:TrapRender()
    if #trapRenderCmpt:GetActiveSkillID() > 0 then
        --可以选择释放主动技 先打开UI界面  在界面中选择预览
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UITrapSkillVisible, true, trapEntityID)
    else
        ---@type ConfigService
        local configService = self._configService
        ---@type TrapConfigData
        local trapConfigData = configService:GetTrapConfigData()
        ---@type string
        local desc = trapConfigData:GetTrapInnerDesc(trapRenderCmpt:GetTrapID())
        ---@type string
        local name = trapConfigData:GetTrapName(trapRenderCmpt:GetTrapID())
        ---@type UtilDataServiceShare
        local utilSvc = self._world:GetService("UtilData")
        local skillID = utilSvc:GetTrapPreviewSkillID(trapEntity)
        ---@type PreviewActiveSkillService
        local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
        if 0 == skillID then
            if trapConfigData:IsShowDescTips(trapRenderCmpt:GetTrapID()) then
                previewActiveSkillService:_ShowDescTips(name, desc)
            end
            --Log.fatal("[Preview]，机关技能预览时发现技能编号非法： trapEntityID = " .. trapEntityID)
            return
        else
            ---@type SkillConfigData 主动技配置数据
            local skillConfigData = configService:GetSkillConfigData(skillID, trapEntity)
            ---下回合可攻击范围
            ---@type SkillPreviewType
            local skillPreviewType = skillConfigData:GetSkillPreviewType()
            if SkillPreviewType.Scope == skillPreviewType then
                self:_ShowSkillRange(trapEntity, skillConfigData)
            elseif SkillPreviewType.Tips == skillPreviewType then
                previewActiveSkillService:_ShowSkillTips(skillConfigData)
            elseif SkillPreviewType.ScopeAndTips == skillPreviewType then
                self:_ShowSkillRange(trapEntity, skillConfigData)
                previewActiveSkillService:_ShowSkillTips(skillConfigData)
            elseif SkillPreviewType.TrapDesc == skillPreviewType then
                previewActiveSkillService:_ShowDescTips(name, desc)
            elseif SkillPreviewType.TrapScopeAndTips == skillPreviewType then
                self:_ShowSkillRange(trapEntity, skillConfigData)
                previewActiveSkillService:_ShowDescTips(name, desc)
            elseif SkillPreviewType.PetTrapMoveArrow == skillPreviewType then
                self:_ShowSkillEffectMove(trapEntity, skillConfigData)
                previewActiveSkillService:_ShowDescTips(name, desc)
            end
        end
    end
end

---@param skillConfigData SkillConfigData
function PreviewTrapActionSystem_Render:_ShowSkillRange(trapEntity, skillConfigData)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")

    local trapBasePos = trapEntity:GridLocation().Position

    ---@type SkillScopeResult
    local rangResult = utilScopeSvc:CalcSkillScope(skillConfigData, trapBasePos, trapEntity)

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    local skillRangeGridList = rangResult:GetWholeGridRange()
    local skillAttackRange = {}
    for _, gridPos in ipairs(skillRangeGridList) do
        local bPosInBoard = utilDataSvc:IsValidPiecePos(gridPos)
        if bPosInBoard then
            local alreadyInRange = table.icontains(skillAttackRange, gridPos)
            if false == alreadyInRange then
                skillAttackRange[#skillAttackRange + 1] = gridPos
            end
        end
    end
    renderEntityService:CreatePreviewAreaOutlineEntity(skillAttackRange, EntityConfigIDRender.MoveRange)
    Log.debug("[Preview] 预览机关攻击范围： 标示技能范围<" .. skillConfigData:GetSkillName() .. ">")
end

---@param skillConfigData SkillConfigData
function PreviewTrapActionSystem_Render:_ShowSkillEffectMove(trapEntity, skillConfigData)
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    ---@type EntityPoolServiceRender
    local entityPoolServiceRender = self._world:GetService("EntityPool")

    local csterID = trapEntity:GetID()
    local skillID = skillConfigData:GetID()

    ---@type SkillEffectResultPetTrapMove[]
    local skillResultList = utilCalcSvc:CalcSkillTargetEffect(csterID, skillID, SkillEffectType.PetTrapMove)

    local skillAttackRange = {}
    for index, result in ipairs(skillResultList) do
        local posNew = result:GetPosNew()
        local dirNew = result:GetDirNew()
        local previewRange = result:GetPreviewRange()
        local moveType = result:GetMoveType()

        if moveType == PetTrapMoveType.FixedPos or moveType == PetTrapMoveType.FixedPos then
            --怪物移动的箭头是反的
            renderEntityService:CreateMoveRangeArrowEntity(posNew, -dirNew, EntityConfigIDRender.MoveRangeArrow)
        else
            for _, pos in ipairs(previewRange) do
                if not table.intable(skillAttackRange, pos) then
                    table.insert(skillAttackRange, pos)
                end
            end
        end
    end

    for _, pos in ipairs(skillAttackRange) do
        local dirNew = pos - skillResultList[1]:GetPosOld()
        --怪物移动的箭头是反的
        renderEntityService:CreateMoveRangeArrowEntity(pos, -dirNew, EntityConfigIDRender.MoveRangeArrow)
    end
end
