--[[------------------------------------------------------------------------------------------
    PreviewActiveSkillSystem_Render : 预览主动技能范围系统
]]
--------------------------------------------------------------------------------------------
---@class PreviewActiveSkillSystem_Render: ReactiveSystem
_class("PreviewActiveSkillSystem_Render", ReactiveSystem)
PreviewActiveSkillSystem_Render = PreviewActiveSkillSystem_Render

---@field self.world MainWorld
function PreviewActiveSkillSystem_Render:Constructor(world)
    self._world = world
    ---@type ConfigService
    self._configService = world:GetService("Config")

    self._previewInstructionSetDic={}
    ---来自cfg_preview_instruction
	self._previewInstructionSetDic[SkillPreviewType.ConvertElement] = 110
    self._previewInstructionSetDic[SkillPreviewType.Scope] = 111
    self._previewInstructionSetDic[SkillPreviewType.ActorDamage] = 112
    self._previewInstructionSetDic[SkillPreviewType.SupportAddBuff] = 113
    self._previewInstructionSetDic[SkillPreviewType.SupportAddBuffWithCastCheck] = 120
end

function PreviewActiveSkillSystem_Render:Dispose()
end

---@param world MainWorld
function PreviewActiveSkillSystem_Render:GetTrigger(world)
    local group = world:GetGroup(world.BW_WEMatchers.PreviewActiveSkill)
    local c = Collector:New({group}, {"AddedOrRemoved"})
    return c
end

---@param entity Entity
function PreviewActiveSkillSystem_Render:Filter(entity)
    return true
end

function PreviewActiveSkillSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        local actorEntity = entities[i]
        local hasPreviewCmpt = actorEntity:HasPreviewActiveSkill()
        if hasPreviewCmpt then
            --Log.fatal("hasPreviewCmpt true")
            local previewIndex = self:_GetPreviewIndex()
            GameGlobal.TaskManager():CoreGameStartTask(self._NewPreviewRoutine, self, actorEntity, previewIndex)
        end
    end
end

function PreviewActiveSkillSystem_Render:_NewPreviewRoutine(TT, actorEntity, previewIndex)
    self:_HideLastPreview(actorEntity)
    YIELD(TT)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local curStateID = utilDataSvc:GetCurMainStateID()

    if curStateID ~= GameStateID.PreviewActiveSkill then
        Log.fatal("PreviewActiveSkill not in preview state,cur state is :", curStateID)
    end

    local curPreviewIndex = self:_GetPreviewIndex()
    if curPreviewIndex ~= previewIndex then
        --Log.fatal("_NewPreviewRoutine preview index not match,func index",previewIndex," curPreviewIndex",curPreviewIndex)
        return
    end

    ---新的预览索引
    self:_NewPreviewIndex()
    self:_ShowPreview(TT, actorEntity)
end

function PreviewActiveSkillSystem_Render:_ShowPreview(TT, actorEntity)
    ---@type EventListenerServiceRender
    local eventListenerService = self._world:GetService("EventListener")
    local preClickHeadSkillID = eventListenerService:GetPreClickHeadSkillID()

    --新的预览过程，预览索引递增
    ---@type PreviewActiveSkillComponent
    local previewActiveSkillCmpt = actorEntity:PreviewActiveSkill()
    local activeSkillID = previewActiveSkillCmpt:GetActiveSKillID()

    if preClickHeadSkillID ~= activeSkillID then
        Log.fatal("preview active skill not match", preClickHeadSkillID, activeSkillID)
        return
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.HideCanMoveArrow)

    ---计算出技能结果
    ---@type ConfigService
    local configService = self._configService
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, actorEntity)
    --这里的意思是需要从表里取出技能ID的预览类型，根据预览类型，挂不同组件，驱动不同的system执行预览
    local previewType = skillConfigData:GetSkillPreviewType()

    if previewType == SkillPreviewType.Instruction then
        self:_DoPreviewInstruction(TT, activeSkillID, actorEntity)
    elseif previewType == SkillPreviewType.ConvertElement or
            previewType == SkillPreviewType.Scope or
            previewType == SkillPreviewType.ActorDamage or
            previewType == SkillPreviewType.SupportAddBuff or
            previewType == SkillPreviewType.SupportAddBuffWithCastCheck
        then
        self:_DoOtherPreviewInstruction(TT,activeSkillID, actorEntity,previewType)
    elseif previewType == SkillPreviewType.TrapActiveSkill then
        self:_DoPreviewInstruction(TT, activeSkillID, actorEntity)
    else
        Log.fatal("other preview type is ", previewType)
    end
end





---清理上一次预览的信息
function PreviewActiveSkillSystem_Render:_HideLastPreview(actorEntity)
    -----恢复所有转色信息
    --local group = self._world:GetGroup(self._world.BW_WEMatchers.PreviewActiveSkill)
    --local targetEntity = nil
    --for _,entity in ipairs(group:GetEntities()) do
    --    self:_RecoverOriginalElementType(entity)
    --end
    ---@type PreviewActiveSkill
    local previewActiveSkill = self._world:GetService("PreviewActiveSkill")
    --清理格子明暗色
    previewActiveSkill:_RevertBright()

    GameGlobal.EventDispatcher():Dispatch(GameEventType.PetHidePreviewArrow)
end

function PreviewActiveSkillSystem_Render:_NewPreviewIndex(enablePrview)
    local previewEntity = self._world:GetPreviewEntity()
    if previewEntity ~= nil then
        ---@type RenderStateComponent
        local renderState = previewEntity:RenderState()
        renderState:NewPreviewRoutine()
    end
end

function PreviewActiveSkillSystem_Render:ResetPreview()
    local previewEntity = self._world:GetPreviewEntity()
    if previewEntity ~= nil then
        ---@type RenderStateComponent
        local renderState = previewEntity:RenderState()
        renderState:ResetPreviewRoutine()
    end
end

function PreviewActiveSkillSystem_Render:_GetPreviewIndex()
    local previewEntity = self._world:GetPreviewEntity()
    if previewEntity ~= nil then
        ---@type RenderStateComponent
        local renderState = previewEntity:RenderState()
        return renderState:GetPreviewRoutineIndex()
    end

    return 0
end

function PreviewActiveSkillSystem_Render:_DoOtherPreviewInstruction(TT, activeSkillID, casterEntity,previewType)
	local taskIDList = {}
	---@type SkillConfigData
	local skillConfigData = self._configService:GetSkillConfigData(activeSkillID, casterEntity)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
	----@type PreviewActiveSkillService
	local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")

    local skillPreviewParamInstruction = SkillPreviewParamInstruction:New({})
    local instructionSetID = self._previewInstructionSetDic[previewType]
    if not instructionSetID then
        Log.exception("SkillID:",activeSkillID,"PreviewType :",previewType,"Invalid ")
        return
    end
    local instructionSet               = skillPreviewParamInstruction:_ParseInstructionSet(instructionSetID)
    local previewContext = SkillPreviewContext:New(self._world, casterEntity)
    local skillEffectArray = skillConfigData:GetSkillSourceEffectTable() -- svcCfgDeco:GetLatestEffectParamArray(casterEntity:GetID(), activeSkillID)
    previewContext:SetEffectList(skillEffectArray) --设置效果列表，即为技能表的效果列表

    ---技能范围
    local targetType = skillConfigData:GetSkillTargetType()
    local targetTypeParam = skillConfigData:GetSkillTargetTypeParam()
    local scopeParam =
    SkillPreviewScopeParam:New(
            {
                TargetType = targetType,
                ScopeType = skillConfigData:GetSkillScopeType(),
                ScopeCenterType = skillConfigData:GetSkillScopeCenterType(),
                TargetTypeParam = targetTypeParam
            }
    )
    scopeParam:SetScopeParamData(skillConfigData:GetSkillScopeParam())
    local scopeResult = utilScopeSvc:CalcScopeResult(scopeParam, casterEntity)
    previewContext:SetScopeResult(scopeResult:GetAttackRange())
    previewContext:SetScopeType(scopeResult:GetScopeType())
    ---目标
    local targetIDList = utilScopeSvc:SelectSkillTarget(casterEntity, targetType, scopeResult,activeSkillID,targetTypeParam)
    previewContext:SetTargetEntityIDList(targetIDList)
    if instructionSet then
        local taskID         = GameGlobal.TaskManager():CoreGameStartTask(
                previewActiveSkillService.DoPreviewInstruction,
                previewActiveSkillService,
                instructionSet,
                casterEntity,
                previewContext
        )
        table.insert(taskIDList, taskID)
    end


	while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
		YIELD(TT)
	end
end

function PreviewActiveSkillSystem_Render:_DoPreviewInstruction(TT, activeSkillID, casterEntity)
    local taskIDList = {}
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID, casterEntity)
    ----@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    for _, v in ipairs(skillConfigData._previewParamList) do
        if v:GetPreviewType() == SkillPreviewType.Instruction then
            ---@type SkillPreviewParamInstruction
            local instructionParam = v
            for _, skillPreviewConfigData in pairs(instructionParam._previewList) do
                local instructionSet = skillPreviewConfigData:GetOnStartInstructionSet()
                if instructionSet then
                    local previewContext =
                        previewActiveSkillService:CreatePreviewContext(skillPreviewConfigData, casterEntity)
                    local taskID =
                        GameGlobal.TaskManager():CoreGameStartTask(
                        previewActiveSkillService.DoPreviewInstruction,
                        previewActiveSkillService,
                        instructionSet,
                        casterEntity,
                        previewContext
                    )
                    table.insert(taskIDList, taskID)
                end
            end
        end
    end
    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end
end
