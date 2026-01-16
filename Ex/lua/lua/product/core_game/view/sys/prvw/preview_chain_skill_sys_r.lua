--[[------------------------------------------------------------------------------------------
    PreviewChainSkillSystem_Render : 预览连锁技系统
]]
---@class PreviewChainSkillSystem_Render: ReactiveSystem
_class("PreviewChainSkillSystem_Render", ReactiveSystem)
PreviewChainSkillSystem_Render = PreviewChainSkillSystem_Render

function PreviewChainSkillSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type ConfigService
    self._sConfig = world:GetService("Config")
    self._carouselIdx = 0 --轮播索引
    self._taskId = 0
end

---@param world MainWorld
function PreviewChainSkillSystem_Render:GetTrigger(world)
    local group = world:GetGroup(world.BW_WEMatchers.PreviewChainSkill)
    local c = Collector:New({group}, {"AddedOrRemoved"})
    return c
end

---@param entity Entity
function PreviewChainSkillSystem_Render:Filter(entity)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local curMainStateID = utilDataSvc:GetCurMainStateID()

    return entity:HasPreviewChainSkill() and curMainStateID == GameStateID.PickUpChainSkillTarget
end

function PreviewChainSkillSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:ExecuteEntity(entities[i])
    end
end

---@param e Entity
function PreviewChainSkillSystem_Render:ExecuteEntity(e)
    GameGlobal.TaskManager():KillTask(self._taskId)
    ---@type PreviewActiveSkillService
    local sPreviewSkill = self._world:GetService("PreviewActiveSkill")
    local cPreviewChainSkill = e:PreviewChainSkill()
    local petIds = cPreviewChainSkill:GetPetIds()
    local skillIds = cPreviewChainSkill:GetSkillIds()
    local posPickUpSafe = cPreviewChainSkill:GetPosPickUpSafe()
    if not petIds or table.count(petIds) <= 0 then
        self._carouselIdx = 0
        local clearTaskID = GameGlobal.TaskManager():CoreGameStartTask(sPreviewSkill.StopPreviewChainSkill, sPreviewSkill)

        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        ---@type RenderBoardComponent
        local renderBoardCmpt = renderBoardEntity:RenderBoard()
        renderBoardCmpt:SetDimensionClearPreviewTaskID(clearTaskID)
   	    ---@type PieceServiceRender
	    local pieceService = self._world:GetService("Piece")
	    pieceService:RefreshPieceAnim()

        return
    end
    local len = table.count(petIds)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    --准备数据
    local skillPreviewParamInstruction = SkillPreviewParamInstruction:New({})
    local instructionSet =
        skillPreviewParamInstruction:_ParseInstructionSet(BattleConst.DimensionPreviewInstructionSetIdChain)
    local entityList = {}
    local instructionSetList = {}
    local previewContextList = {}

    for i, id in ipairs(petIds) do
        local skillId = skillIds[i]
        table.insert(instructionSetList, instructionSet)
        local e = self._world:GetEntityByID(id)
        table.insert(entityList, e)
        local previewContext = SkillPreviewContext:New(self._world, e)
        local skillConfigData = self._sConfig:GetSkillConfigData(skillId, e)
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        local skillEffectArray = utilData:GetLatestEffectParamArray(e:GetID(), skillId)
        previewContext:SetEffectList(skillEffectArray) --设置效果列表，即为技能表的效果列表
        ---技能范围
        local targetType = skillConfigData:GetSkillTargetType()
        local scopeType = skillConfigData:GetSkillScopeType()
        local scopeParam =
            SkillPreviewScopeParam:New(
            {
                TargetType = targetType,
                ScopeType = scopeType,
                ScopeCenterType = SkillScopeCenterType.ChainSkillPickUpGridPos,
                OnlyCanMove = false
            }
        )
        scopeParam:SetScopeParamData(skillConfigData:GetSkillScopeParam())
        local scopeResult = utilScopeSvc:CalcScopeResult(scopeParam, e)
        previewContext:SetScopeResult(scopeResult:GetAttackRange())
        previewContext:SetScopeType(scopeResult:GetScopeType())
        --设置拾取点
        previewContext:SetPickUpPos(posPickUpSafe)
        ---目标
        local targetIDList = utilScopeSvc:SelectSkillTarget(e, targetType, scopeResult)
        previewContext:SetTargetEntityIDList(targetIDList)
        table.insert(previewContextList, previewContext)

        local pstID = e:PetPstID():GetPstID()
        self._world:EventDispatcher():Dispatch(GameEventType.UpdateBuffLayerActiveSkillEnergyPreview, {
            pstID = pstID,
            index = e:SkillInfo():GetChainSkillLevel(skillId)
        })
    end
    ---轮播
    self._carouselIdx = 1
    self._taskId =
        GameGlobal.TaskManager():CoreGameStartTask(
        self.PlayChainSkillCarousel,
        self,
        entityList,
        instructionSetList,
        previewContextList
    )
end

function PreviewChainSkillSystem_Render:PlayChainSkillCarousel(TT, entityList, instructionSetList, previewContextList)
    ---@type PreviewActiveSkillService
    local sPreviewActiveSkill = self._world:GetService("PreviewActiveSkill")
    ---@type PreviewActiveSkillService
    local sPreviewSkill = self._world:GetService("PreviewActiveSkill")
    ---@type LinkageRenderService
    local linkrsvc = self._world:GetService("LinkageRender")
    local len = table.count(entityList)
    if len > 1 then
        while self._carouselIdx > 0 do
            sPreviewSkill:StopPreviewChainSkill(TT) --每次轮播需要重置
            YIELD(TT)
            local e = entityList[self._carouselIdx]
            local instructionSet = instructionSetList[self._carouselIdx]
            local previewContext = previewContextList[self._carouselIdx]
            sPreviewActiveSkill:DoPreviewInstruction(TT, instructionSet, e, previewContext)

            linkrsvc:ShowChainSkillIcon(e:GetID())

            YIELD(TT, BattleConst.DimensionPreviewCarouselDuration) --轮播间隔2秒
            if self._carouselIdx == table.count(entityList) then
                self._carouselIdx = 1
            else
                self._carouselIdx = self._carouselIdx + 1
            end
        end
    else
        sPreviewSkill:StopPreviewChainSkill(TT) --每次轮播需要重置
        local e = entityList[self._carouselIdx]
        local instructionSet = instructionSetList[self._carouselIdx]
        local previewContext = previewContextList[self._carouselIdx]
        sPreviewActiveSkill:DoPreviewInstruction(TT, instructionSet, e, previewContext)
        linkrsvc:HideChainSkillIcon()
    end
end
