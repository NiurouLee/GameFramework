--[[----------------------------------------------------------
    SkillPickUpGridTogetherInstructionSystem_Render 指令化的PickUPSystem
]] ------------------------------------------------------------
---@class SkillPickUpGridTogetherInstructionSystem_Render:ReactiveSystem
_class("SkillPickUpGridTogetherInstructionSystem_Render", ReactiveSystem)
SkillPickUpGridTogetherInstructionSystem_Render = SkillPickUpGridTogetherInstructionSystem_Render

---@param world World
function SkillPickUpGridTogetherInstructionSystem_Render:Constructor(world)
    self._world = world
end

---@param world World
function SkillPickUpGridTogetherInstructionSystem_Render:GetTrigger(world)
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
function SkillPickUpGridTogetherInstructionSystem_Render:Filter(entity)
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()
    local skillHandleType = pickUpTargetCmpt:GetPickUpTargetType()
    if skillHandleType == SkillPickUpType.PickUpGridTogether then
        return true
    end
    return false
end

function SkillPickUpGridTogetherInstructionSystem_Render:ExecuteEntities(entities)
    ---@type PreviewActiveSkillService
    local previewActiveSkill = self._world:GetService("PreviewActiveSkill")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local petEntityId = utilDataSvc:GetEntityIDByPstID(pickUpTargetCmpt:GetPetPstid())

    local petEntity = self._world:GetEntityByID(petEntityId)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, petEntity)
    local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()

    local petPstID = pickUpTargetCmpt:GetPetPstid()
    ---@type Vector2[]
    local validGirdList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpValidScopeList, petEntity)
    ---@type Vector2[]
    local invalidGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, petEntity)

    ---可点选的数量
    local pickUpNum = tonumber(skillConfigData._pickUpParam[1])


    if not petEntity:HasPreviewPickUpComponent() then
        petEntity:AddPreviewPickUpComponent()
    end
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
    ---@type Vector2[]
    local alreadyPickUpGrid =  previewPickUpComponent:GetAllValidPickUpGridPos()

    ---@type GuideServiceRender
    local guideService = self._world:GetService("Guide")
    if guideService then
        if guideService:IsValidGuidePiecePos(pickUpGridPos.x, pickUpGridPos.y) then
            self._world:EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Piece)
        else
            return
        end
    end
    ---点选有效范围
    if table.icontains(validGirdList, pickUpGridPos) then
        ---重复点选
        if #alreadyPickUpGrid>0 then
            if pickUpNum==1 then
                if table.Vector2Include(alreadyPickUpGrid,pickUpGridPos) then
                    Log.debug("只可点选一次,重复点选，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
                    previewPickUpComponent:RemoveGridPos(pickUpGridPos)
                    self._world:EventDispatcher():Dispatch(GameEventType.RefreshPickUpNum, 1)
                    GameGlobal.TaskManager():CoreGameStartTask(
                            self._DoPickUpInstruction,
                            self,
                            PickUpInstructionType.Empty,
                            skillConfigData,
                            petEntity,
                            pickUpGridPos
                    )
                else
                    Log.debug("只可点选一次，换坐标，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
                    self._world:EventDispatcher():Dispatch(GameEventType.RefreshPickUpNum, 0)
                    previewPickUpComponent:ClearGridPos()
                    previewPickUpComponent:AddGridPos(pickUpGridPos)
                    GameGlobal.TaskManager():CoreGameStartTask(
                            self._DoPickUpInstruction,
                            self,
                            PickUpInstructionType.Valid,
                            skillConfigData,
                            petEntity,
                            pickUpGridPos
                    )

                end

                self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, true)
                self._world:EventDispatcher():Dispatch(GameEventType.ChangePickUpText, SkillPickUpTextStateType.Normal)
            else
                if table.Vector2Include(alreadyPickUpGrid,pickUpGridPos) then
                    if #alreadyPickUpGrid ==1  then
                        Log.debug("点选两次，同一个格子点选第二次，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
                        previewPickUpComponent:AddGridPos(pickUpGridPos)
                    else
                        Log.debug("点选两次，同一个格子点选奇数次，换坐标，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
                        previewPickUpComponent:RemoveGridPos(pickUpGridPos)
                    end
                    self._world:EventDispatcher():Dispatch(GameEventType.RefreshPickUpNum, 0)
                    self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, true)
                    self._world:EventDispatcher():Dispatch(GameEventType.ChangePickUpText, SkillPickUpTextStateType.ColOrRow)
                    GameGlobal.TaskManager():CoreGameStartTask(
                            self._DoPickUpInstruction,
                            self,
                            PickUpInstructionType.Valid,
                            skillConfigData,
                            petEntity,
                            pickUpGridPos
                    )
                else
                    Log.debug("点选两次，已经点选格子情况下点选新格子，换坐标，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
                    local alreadyPickUpCount =previewPickUpComponent:GetAllValidPickUpGridPosCount()
                    previewPickUpComponent:ClearGridPos()
                    if alreadyPickUpCount == 1 then
                        previewPickUpComponent:AddGridPos(pickUpGridPos)
                    elseif alreadyPickUpCount == 2 then
                        previewPickUpComponent:AddGridPos(pickUpGridPos)
                        previewPickUpComponent:AddGridPos(pickUpGridPos)
                    end

                    self._world:EventDispatcher():Dispatch(GameEventType.RefreshPickUpNum, 0)
                    self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, true)
                    self._world:EventDispatcher():Dispatch(GameEventType.ChangePickUpText, SkillPickUpTextStateType.ColOrRow)
                    --previewActiveSkill:UpdateUI(pickUpNum,pickUpNum, previewPickUpComponent)
                    GameGlobal.TaskManager():CoreGameStartTask(
                            self._DoPickUpInstruction,
                            self,
                            PickUpInstructionType.Valid,
                            skillConfigData,
                            petEntity,
                            pickUpGridPos
                    )
                end
            end
        else
            Log.debug("第一次点选，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
            previewPickUpComponent:AddGridPos(pickUpGridPos)
            utilScopeSvc:ChangeGameFSMState2PickUp()
            self._world:EventDispatcher():Dispatch(GameEventType.RefreshPickUpNum, 0)
            self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, true)
            if pickUpNum==1 then
                self._world:EventDispatcher():Dispatch(GameEventType.ChangePickUpText, SkillPickUpTextStateType.Normal)
            else
                self._world:EventDispatcher():Dispatch(GameEventType.ChangePickUpText, SkillPickUpTextStateType.ColOrRow)
            end
            --previewActiveSkill:UpdateUI(pickUpNum,pickUpNum, previewPickUpComponent)
            GameGlobal.TaskManager():CoreGameStartTask(
                    self._DoPickUpInstruction,
                    self,
                    PickUpInstructionType.Valid,
                    skillConfigData,
                    petEntity,
                    pickUpGridPos
            )
        end
    else
        if table.Vector2Include(invalidGridList,pickUpGridPos) then
            GameGlobal.TaskManager():CoreGameStartTask(
                    self._DoPickUpInstruction,
                    self,
                    PickUpInstructionType.Invalid,
                    skillConfigData,
                    petEntity,
                    pickUpGridPos
            )
        else
            previewActiveSkill:PickUpInvalidGridCancelPreview(activeSkillID, pickUpTargetCmpt:GetPetPstid())
        end
    end
end

---@param pickUpGirdPos Vector2
function SkillPickUpGridTogetherInstructionSystem_Render:_DoPickUpInstruction(
        TT,
        type,
        skillConfigData,
        casterEntity,
        pickUpGirdPos)
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
function SkillPickUpGridTogetherInstructionSystem_Render:_GetInstructSet(type, skillPreviewConfigData)
    if type == PickUpInstructionType.Repeat then
        return skillPreviewConfigData:GetOnSelectCancelInstructionSet()
    end

    if type == PickUpInstructionType.Invalid then
        return skillPreviewConfigData:GetOnSelectInvalidInstructionSet()
    end
    if type == PickUpInstructionType.Repeat then
        return skillPreviewConfigData:GetOnSelectEmptyInstructionSet()
    end
    if type == PickUpInstructionType.Valid then
        return skillPreviewConfigData:GetOnSelectValidInstructionSet()
    end
    if type == PickUpInstructionType.Empty then
        return skillPreviewConfigData:GetOnSelectEmptyInstructionSet()
    end
    return nil
end

function SkillPickUpGridTogetherInstructionSystem_Render:_GetPreviewContext(
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
