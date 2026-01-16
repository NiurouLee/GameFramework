--[[----------------------------------------------------------
    定制化的点选效果 针对 狗兄弟 的技能效果 定制化处理逻辑
]] ------------------------------------------------------------
---@class SkillPickUpPosAndRotateInstructionSystem_Render:ReactiveSystem
_class("SkillPickUpPosAndRotateInstructionSystem_Render", ReactiveSystem)
SkillPickUpPosAndRotateInstructionSystem_Render = SkillPickUpPosAndRotateInstructionSystem_Render

---@param world MainWorld
function SkillPickUpPosAndRotateInstructionSystem_Render:Constructor(world)
    self._world = world

    self._pickUpType = nil
end

---@param world World
function SkillPickUpPosAndRotateInstructionSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.PickUpTarget)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function SkillPickUpPosAndRotateInstructionSystem_Render:Filter(entity)
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()
    local skillHandleType = pickUpTargetCmpt:GetPickUpTargetType()
    if skillHandleType == SkillPickUpType.PickOnePosAndRotate then
        return true
    end
    return false
end

function SkillPickUpPosAndRotateInstructionSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:DoPickUp(entities[i])
    end
end

function SkillPickUpPosAndRotateInstructionSystem_Render:DoPickUp(entity)
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()
    self._pickUpType = pickUpTargetCmpt:GetPickUpTargetType()

    ---@type PreviewActiveSkillService
    self._previewActiveSkill = self._world:GetService("PreviewActiveSkill")

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
    local petEntityId = utilDataSvc:GetEntityIDByPstID(pickUpTargetCmpt:GetPetPstid())

    local petEntity = self._world:GetEntityByID(petEntityId)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, petEntity)

    local petPstID = pickUpTargetCmpt:GetPetPstid()
    if not petEntity:HasPreviewPickUpComponent() then
        petEntity:AddPreviewPickUpComponent()
    end

    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()
    local alreadyPickUpCount = previewPickUpComponent:GetAllValidPickUpGridPosCount()

    ---技能表配置的点选有效范
    ---@type Vector2[]
    local validGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpValidScopeList, petEntity)
    --不可以点的范围
    ---@type Vector2[]
    local invalidGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, petEntity)

    for _, pos in ipairs(invalidGridList) do
        if table.intable(validGridList, pos) then
            table.removev(validGridList, pos)
        end
    end

    ---点选无效范围取消点选
    if not table.Vector2Include(validGridList, pickUpGridPos) then
        self._previewActiveSkill:PickUpInvalidGridCancelPreview(activeSkillID, petPstID)
        if AutoPickCheckHelperRender.IsAutoFightRunning() then--自动战斗下点选异常上报
            AutoPickCheckHelperRender.ReportAutoFightPickError(
                ActivePickSkillCheckErrorStep.PickPosAndRotateInsInvalid,ActivePickSkillCheckErrorType.None,
                activeSkillID,pickUpGridPos)
        end
        return
    end

    utilScopeSvc:ChangeGameFSMState2PickUp()

    -- 如果已经点了0个点  本次是基础点
    if alreadyPickUpCount == 0 then
        previewPickUpComponent:AddGridPos(pickUpGridPos)
        ---准备选择方向状态的显示，有效点击1个点
        self:_OnPickOnePos(petEntity, skillConfigData, pickUpGridPos)
    else
        --上一次点击的点
        local lastPickUpPos = previewPickUpComponent:GetLastPickUpGridPos()
        --本次点击的点是上一次点击的点
        if pickUpGridPos == lastPickUpPos then
            self:_OnRotate(petEntity, skillConfigData, pickUpGridPos)
        else --重新选点
            previewPickUpComponent:ClearGridPos()
            previewPickUpComponent:AddGridPos(pickUpGridPos)
            previewPickUpComponent:SetReflectDir(ReflectDirectionType.Heng)
            self:_OnPickOnePos(petEntity, skillConfigData, pickUpGridPos)
        end
    end
end

---初始状态的显示，有效点击0个点，什么都没有
function SkillPickUpPosAndRotateInstructionSystem_Render:_OnInitialize(petEntity, skillConfigData, pickUpGridPos)
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()

    self._previewActiveSkill:ResetPreview()

    GameGlobal.TaskManager():CoreGameStartTask(
        self._DoPickUpInstruction,
        self,
        PickUpInstructionType.Empty,
        skillConfigData,
        petEntity,
        pickUpGridPos
    )

    self:UpdateUI(previewPickUpComponent)
end

---准备选择方向状态的显示，有效点击1个点
function SkillPickUpPosAndRotateInstructionSystem_Render:_OnPickOnePos(petEntity, skillConfigData, pickUpGridPos)
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()

    GameGlobal.TaskManager():CoreGameStartTask(
        self._DoPickUpInstruction,
        self,
        PickUpInstructionType.Valid,
        skillConfigData,
        petEntity,
        pickUpGridPos
    )

    self:UpdateUI(previewPickUpComponent)
end

--旋转点选位置ghost的方向
function SkillPickUpPosAndRotateInstructionSystem_Render:_OnRotate(petEntity, skillConfigData, pickUpGridPos)
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()

    GameGlobal.TaskManager():CoreGameStartTask(
        self._DoPickUpInstruction,
        self,
        PickUpInstructionType.Repeat,
        skillConfigData,
        petEntity,
        pickUpGridPos
    )

    self:UpdateUI(previewPickUpComponent)
end

---@param previewPickUpComponent PreviewPickUpComponent
function SkillPickUpPosAndRotateInstructionSystem_Render:UpdateUI(previewPickUpComponent)
    local pickUpCount = previewPickUpComponent:GetAllValidPickUpGridPosCount()

    local canCast = false
    local uiTextState = SkillPickUpTextStateType.Normal

    if pickUpCount >= 1 then
        uiTextState = SkillPickUpTextStateType.Rotate
        canCast = true
    end

    self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, canCast)
    self._world:EventDispatcher():Dispatch(GameEventType.ChangePickUpText, uiTextState)
end

function SkillPickUpPosAndRotateInstructionSystem_Render:_DoPickUpInstruction(
    TT,
    type,
    skillConfigData,
    casterEntity,
    pickUpGirdPos,
    pickPosNum)
    ---@type number[]
    local taskIDList = {}
    ----@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    for i, v in ipairs(skillConfigData._previewParamList) do
        if v:GetPreviewType() == SkillPreviewType.Instruction then
            ---@type SkillPreviewParamInstruction
            local instructionParam = v
            for _, skillPreviewConfigData in ipairs(instructionParam._previewList) do
                local instructionSet = self:_GetInstructSet(type, skillPreviewConfigData)
                if instructionSet then
                    ---@type SkillPreviewContext
                    local previewContext =
                        self:_GetPreviewContext(
                        type,
                        skillPreviewConfigData,
                        casterEntity,
                        skillPreviewConfigData:GetID(),
                        pickUpGirdPos
                    )
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

---@param skillPreviewConfigData SkillPreviewConfigData
function SkillPickUpPosAndRotateInstructionSystem_Render:_GetInstructSet(type, skillPreviewConfigData)
    if type == PickUpInstructionType.Invalid then
        return skillPreviewConfigData:GetOnSelectInvalidInstructionSet()
    end
    if type == PickUpInstructionType.Repeat then
        return skillPreviewConfigData:GetOnSelectCancelInstructionSet()
    end
    if type == PickUpInstructionType.Valid then
        return skillPreviewConfigData:GetOnSelectValidInstructionSet()
    end
    if type == PickUpInstructionType.Empty then
        return skillPreviewConfigData:GetOnSelectEmptyInstructionSet()
    end
    return nil
end

function SkillPickUpPosAndRotateInstructionSystem_Render:_GetPreviewContext(
    type,
    skillPreviewConfigData,
    casterEntity,
    id,
    pickUpGridPos)
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
    local context = previewPickUpComponent:GetPreviewContext(id)
    if not context then
        if type == PickUpInstructionType.Invalid then
            context =
                previewActiveSkillService:CreatePreviewContext(
                skillPreviewConfigData,
                casterEntity,
                pickUpGridPos,
                {pickUpGridPos}
            )
        else
            context =
                previewActiveSkillService:CreatePreviewContext(skillPreviewConfigData, casterEntity, pickUpGridPos)
        end
    end
    return context
end
