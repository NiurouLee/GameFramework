--[[----------------------------------------------------------
    SkillPickUpInstructionSystem_Render 指令化的PickUPSystem
]] ------------------------------------------------------------
---@class SkillPickUpInstructionSystem_Render:ReactiveSystem
_class("SkillPickUpInstructionSystem_Render", ReactiveSystem)
SkillPickUpInstructionSystem_Render = SkillPickUpInstructionSystem_Render

---@param world MainWorld
function SkillPickUpInstructionSystem_Render:Constructor(world)
    self._world = world
    self._isGuide = false
    self._pickUpType = nil

    self._IsRepeatPickupFunc = {}
    self._IsRepeatPickupFunc[SkillPickUpType.Instruction] = self.IsRepeatPickUP_PickGrid
    self._IsRepeatPickupFunc[SkillPickUpType.ColorInstruction] = self.IsRepeatPickUP_PickColor

    self._ProgressInvalidFunc = {}
    self._ProgressInvalidFunc[SkillPickUpType.Instruction] = self.ProgressInvalidGridList_PickGrid
    self._ProgressInvalidFunc[SkillPickUpType.ColorInstruction] = self.ProgressInvalidGridList_PickColor

    self._RemovePickUpGridPos = {}
    self._RemovePickUpGridPos[SkillPickUpType.Instruction] = self.RemovePickUpGridPos_PickGrid
    self._RemovePickUpGridPos[SkillPickUpType.ColorInstruction] = self.RemovePickUpGridPos_PickColor
end

---@param world World
function SkillPickUpInstructionSystem_Render:GetTrigger(world)
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
function SkillPickUpInstructionSystem_Render:Filter(entity)
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()
    local skillHandleType = pickUpTargetCmpt:GetPickUpTargetType()
    if skillHandleType == SkillPickUpType.Instruction or skillHandleType == SkillPickUpType.ColorInstruction then
        return true
    end
    return false
end

function SkillPickUpInstructionSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:DoPickUp(entities[i])
    end
end

function SkillPickUpInstructionSystem_Render:DoPickUp(entity)
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()
    self._pickUpType = pickUpTargetCmpt:GetPickUpTargetType()

    ---@type PreviewActiveSkillService
    local previewActiveSkill = self._world:GetService("PreviewActiveSkill")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
    local entityID = 0
    --光灵主动技/机关主动技 按照不同的方式取
    if skillConfigData:GetSkillType() == SkillType.Active then
        entityID = utilDataSvc:GetEntityIDByPstID(pickUpTargetCmpt:GetPetPstid())
        local entity = self._world:GetEntityByID(entityID)
        skillConfigData = configService:GetSkillConfigData(activeSkillID, entity) -- 施法者为光灵时，技能可能被替换
    elseif skillConfigData:GetSkillType() == SkillType.TrapSkill then
        entityID = pickUpTargetCmpt:GetEntityID()
    elseif skillConfigData:GetSkillType() == SkillType.FeatureSkill then
        entityID = pickUpTargetCmpt:GetEntityID()
    end

    local petEntity = self._world:GetEntityByID(entityID)
    if not petEntity:HasPreviewPickUpComponent() then
        petEntity:AddPreviewPickUpComponent()
    end

    ---@type Vector2[]
    local validGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpValidScopeList, petEntity)
    ---@type Vector2[]
    local invalidGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, petEntity)

    --[[
		点选有效范围内的无效格子为明确禁止格
		点选有效范围外的任何格子为取消点选格
	]]
    ----这里有个逻辑 去掉有效范围里的无效格子 ----
    validGridList = self:ProcessInvalidGridList(validGridList, invalidGridList)

    ---可点选的数量
    local pickUpNum = tonumber(skillConfigData._pickUpParam[1])
    local musPickUpNum = nil
    if skillConfigData._pickUpParam[2] then
        musPickUpNum = tonumber(skillConfigData._pickUpParam[2])
    end
    local isPickFirstRepeatRemoveAll = false
    if skillConfigData._pickUpParam[3] then
        local param3 = tonumber(skillConfigData._pickUpParam[3])
        isPickFirstRepeatRemoveAll = (param3 == 1)
    end
    local secondPickInvalidToChangeFirst = false
    if skillConfigData._pickUpParam[4] then
        local param4 = tonumber(skillConfigData._pickUpParam[4])
        secondPickInvalidToChangeFirst = (param4 == 1)
    end

    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()

    ---重复点选
    if self:IsRepeatPickUP(previewPickUpComponent:GetAllValidPickUpGridPos(), pickUpGridPos) then
        -- ---@type GuideServiceRender
        -- local guideService = self._world:GetService("Guide")
        -- if guideService then
        --     local isValid = guideService:IsValidGuidePiecePos(pickUpGridPos.x, pickUpGridPos.y)
        --     if isValid and self._isGuide then
        --         return
        --     end
        -- end
        if self._isGuide then
            return
        end
        Log.debug("本次重复点选生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
        if AutoPickCheckHelperRender.IsAutoFightRunning() then--自动战斗下点选异常上报
            AutoPickCheckHelperRender.ReportAutoFightPickError(
                ActivePickSkillCheckErrorStep.PickInsRepeat,ActivePickSkillCheckErrorType.None,
                activeSkillID,pickUpGridPos)
        end
        if isPickFirstRepeatRemoveAll then --重复的点是第一个点则清除所有点击的点
            local firstPickPos = previewPickUpComponent:GetFirstValidPickUpGridPos()
            if firstPickPos and firstPickPos == pickUpGridPos then
                previewPickUpComponent:ClearGridPos()
            else
                self:RemoveRepeatPickUpGrid(previewPickUpComponent, pickUpGridPos)
            end
        else
            self:RemoveRepeatPickUpGrid(previewPickUpComponent, pickUpGridPos)
        end
        ---用来判断是服务端还是客户端运行
        if previewActiveSkill then
            previewActiveSkill:ResetPreview()
            previewActiveSkill:_RevertAllConvertElement()

            if previewPickUpComponent:GetAllValidPickUpGridPosCount() == 0 then
                GameGlobal.TaskManager():CoreGameStartTask(
                    self._DoPickUpInstruction,
                    self,
                    PickUpInstructionType.Empty,
                    skillConfigData,
                    petEntity,
                    pickUpGridPos
                )
            else
                GameGlobal.TaskManager():CoreGameStartTask(
                    self._DoPickUpInstruction,
                    self,
                    PickUpInstructionType.Repeat,
                    skillConfigData,
                    petEntity,
                    pickUpGridPos
                )
            end
        end
        previewActiveSkill:UpdateUI(pickUpNum, musPickUpNum, previewPickUpComponent)
        return
    end
    --第二个点 点在不合法范围时相当于重新点第一个点 希诺普
    if secondPickInvalidToChangeFirst then
        if previewPickUpComponent:GetAllValidPickUpGridPosCount() == 1 then
            if not table.icontains(validGridList, pickUpGridPos) then
                ---@type UtilDataServiceShare
                local utilDataSvc = self._world:GetService("UtilData")
                if utilDataSvc:IsValidPiecePos(pickUpGridPos) then --点到没有格子的地方 不应该取消之前的点击
                    previewPickUpComponent:ClearGridPos()
                    --希诺普 有效范围随点击数量变化
                    ---@type Vector2[]
                    validGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpValidScopeList, petEntity)
                    ---@type Vector2[]
                    invalidGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, petEntity)
                    validGridList = self:ProcessInvalidGridList(validGridList, invalidGridList)
                end
            end
        end
    end
    ---点选有效范围
    if table.icontains(validGridList, pickUpGridPos) then
        ---点选无效范围
        ---@type GuideServiceRender
        local guideService = self._world:GetService("Guide")
        ---只能点选一个格子的点选其余格子就执行取消
        if pickUpNum == 1 and previewPickUpComponent:GetAllValidPickUpGridPosCount() == 1 then
            ---引导---
            local isValid, isGuide = guideService:IsValidGuidePiecePos(pickUpGridPos.x, pickUpGridPos.y)
            if isValid then
                if isGuide then
                    self._world:EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Piece)
                end
                self._isGuide = isGuide
            else
                return
            end

            ---引导---
            Log.debug("本次点选其他格子生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
            previewPickUpComponent:ClearGridPos()
            previewPickUpComponent:AddGridPos(pickUpGridPos)

            ---用来判断是服务端还是客户端运行
            if previewActiveSkill then
                previewActiveSkill:ResetPreview()
                previewActiveSkill:_RevertAllConvertElement()
                GameGlobal.TaskManager():CoreGameStartTask(
                    function(TT)
                        self:_DoPickUpInstruction(
                            TT,
                            PickUpInstructionType.Empty,
                            skillConfigData,
                            petEntity,
                            pickUpGridPos
                        )
                        previewActiveSkill:_RevertAllConvertElement()
                        self:_DoPickUpInstruction(
                            TT,
                            PickUpInstructionType.Valid,
                            skillConfigData,
                            petEntity,
                            pickUpGridPos
                        )
                    end
                )
            end
            return
        elseif pickUpNum > previewPickUpComponent:GetAllValidPickUpGridPosCount() then
            ---引导---
            local isValid, isGuide = guideService:IsValidGuidePiecePos(pickUpGridPos.x, pickUpGridPos.y)
            if isValid then
                if isGuide then
                    self._world:EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Piece)
                end
                self._isGuide = isGuide
            else
                return
            end
            ---引导---

            Log.debug("本次点选生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
            previewPickUpComponent:AddGridPos(pickUpGridPos)

            utilScopeSvc:ChangeGameFSMState2PickUp()
            ---用来判断是服务端还是客户端运行
            if previewActiveSkill then
                previewActiveSkill:ResetPreview()
                GameGlobal.TaskManager():CoreGameStartTask(
                    self._DoPickUpInstruction,
                    self,
                    PickUpInstructionType.Valid,
                    skillConfigData,
                    petEntity,
                    pickUpGridPos
                )
            end
            previewActiveSkill:UpdateUI(pickUpNum, musPickUpNum, previewPickUpComponent)
            return
        end
    else
        local guideService = self._world:GetService("Guide")
        ---引导---
        local isValid, isGuide = guideService:IsValidGuidePiecePos(pickUpGridPos.x, pickUpGridPos.y)
        if not isValid then
            return
        end
        if AutoPickCheckHelperRender.IsAutoFightRunning() then--自动战斗下点选异常上报
            AutoPickCheckHelperRender.ReportAutoFightPickError(
                ActivePickSkillCheckErrorStep.PickInsInvalid,ActivePickSkillCheckErrorType.None,
                activeSkillID,pickUpGridPos)
        end
        if table.icontains(invalidGridList, pickUpGridPos) then
            Log.debug("本次点选无效目标生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
            ---用来判断是服务端还是客户端运行
            if previewActiveSkill then
                GameGlobal.TaskManager():CoreGameStartTask(
                    self._DoPickUpInstruction,
                    self,
                    PickUpInstructionType.Invalid,
                    skillConfigData,
                    petEntity,
                    pickUpGridPos
                )
            end
        else
            if previewActiveSkill then
                previewActiveSkill:PickUpInvalidGridCancelPreview(activeSkillID, pickUpTargetCmpt:GetPetPstid())
            end
        end
    end
end

---@param pickUpGridPos Vector2
function SkillPickUpInstructionSystem_Render:_DoPickUpInstruction(TT, type, skillConfigData, casterEntity, pickUpGirdPos)
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
function SkillPickUpInstructionSystem_Render:_GetInstructSet(type, skillPreviewConfigData)
    if type == PickUpInstructionType.Repeat then
        return skillPreviewConfigData:GetOnSelectCancelInstructionSet()
    end

    if type == PickUpInstructionType.Invalid then
        return skillPreviewConfigData:GetOnSelectInvalidInstructionSet()
    end

    if type == PickUpInstructionType.Valid then
        return skillPreviewConfigData:GetOnSelectValidInstructionSet()
    end
    if type == PickUpInstructionType.Empty then
        return skillPreviewConfigData:GetOnSelectEmptyInstructionSet()
    end
    return nil
end

function SkillPickUpInstructionSystem_Render:_GetPreviewContext(
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

function SkillPickUpInstructionSystem_Render:ProcessInvalidGridList(validGridList, invalidGridList)
    local fun = self._ProgressInvalidFunc[self._pickUpType]
    return fun(self, validGridList, invalidGridList)
end

function SkillPickUpInstructionSystem_Render:ProgressInvalidGridList_PickGrid(validGridList, invalidGridList)
    local tv2FilteredInvalidGridList = {}
    for _, v2 in ipairs(invalidGridList) do
        if table.icontains(validGridList, v2) then
            table.insert(tv2FilteredInvalidGridList, v2)
        end
    end

    local tv2FilteredValidGridList = {}
    for _, v2 in ipairs(validGridList) do
        if not table.icontains(tv2FilteredInvalidGridList, v2) then
            table.insert(tv2FilteredValidGridList, v2)
        end
    end

    validGridList = tv2FilteredValidGridList
    return tv2FilteredValidGridList
end

function SkillPickUpInstructionSystem_Render:ProgressInvalidGridList_PickColor(validGridList, invalidGridList)
    return validGridList
end
---@param allPickUpPos Vector2[]
---@param pickUpGridPos Vector2
function SkillPickUpInstructionSystem_Render:IsRepeatPickUP(allPickUpPos, pickUpGridPos)
    return self._IsRepeatPickupFunc[self._pickUpType](self, allPickUpPos, pickUpGridPos)
end

----@param allPickUpPos Vector2[]
---@param pickUpGridPos Vector2
function SkillPickUpInstructionSystem_Render:IsRepeatPickUP_PickGrid(allPickUpPos, pickUpGridPos)
    return table.icontains(allPickUpPos, pickUpGridPos)
end

----@param allPickUpPos Vector2[]
---@param pickUpGridPos Vector2
function SkillPickUpInstructionSystem_Render:IsRepeatPickUP_PickColor(allPickUpPos, pickUpGridPos)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    if table.count(allPickUpPos) > 0 then
        local pickPieceType = utilDataSvc:GetPieceType(pickUpGridPos)
        for _, pos in pairs(allPickUpPos) do
            local alreadyPieceType = utilDataSvc:GetPieceType(pos)
            if pickPieceType == alreadyPieceType then
                return true
            end
        end
        return false
    else
        return false
    end
end

function SkillPickUpInstructionSystem_Render:RemovePickUpGridPos_PickGrid(previewPickUpComponent, pickGridPos)
    previewPickUpComponent:RemoveGridPos(pickGridPos)
end
---@param previewPickUpComponent PreviewPickUpComponent
function SkillPickUpInstructionSystem_Render:RemovePickUpGridPos_PickColor(previewPickUpComponent, pickGridPos)
    previewPickUpComponent:ClearGridPos()
end

function SkillPickUpInstructionSystem_Render:RemoveRepeatPickUpGrid(previewPickUpComponent, pickGridPos)
    self._RemovePickUpGridPos[self._pickUpType](self, previewPickUpComponent, pickGridPos)
end
